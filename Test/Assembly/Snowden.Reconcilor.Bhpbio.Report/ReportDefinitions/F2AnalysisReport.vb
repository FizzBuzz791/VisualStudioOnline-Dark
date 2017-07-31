Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace ReportDefinitions

    Public Class F2AnalysisReport
        Inherits ReportBase

        Public Shared Function GetData(session As ReportSession, locationId As Integer,
                                       dateBreakdown As ReportBreakdown, dateFrom As DateTime, dateTo As DateTime,
                                       factorId As String, attributeList As String(),
                                       contextList As String()) As DataTable

            Dim factorList = (New String() {factorId}).ToList
            Dim locationTypeName = session.GetLocationTypeName(locationId).ToUpper()
            Dim canLoadSublocations = False

            If locationTypeName = "COMPANY" Then
                canLoadSublocations = True
            ElseIf locationTypeName = "HUB" Then
                canLoadSublocations = (factorId = "F1Factor" OrElse factorId = "F15Factor" OrElse factorId = "F2Factor")
            ElseIf locationTypeName = "SITE" Then
                canLoadSublocations = (factorId = "F1Factor" OrElse factorId = "F15Factor")
            Else
                canLoadSublocations = False
            End If

            If contextList.Contains("ResourceClassification") Then
                If factorId <> "F1Factor" AndAlso factorId <> "F15Factor" Then
                    factorList.Add("F1Factor")
                End If
            End If

            Dim tableOptions = New DataTableOptions With {
                .DateBreakdown = dateBreakdown,
                .IncludeSourceCalculations = True,
                .GroupByLocationId = False
            }

            session.IncludeProductSizeBreakdown = False
            session.IncludeResourceClassification = contextList.Contains("ResourceClassification")
            session.CalculationParameters(dateFrom, dateTo, locationId, childLocations:=canLoadSublocations)

            Dim calcSet = Types.CalculationSet.CreateForCalculations(session, factorList.ToArray)
            Data.DateBreakdown.AddDateText(dateBreakdown, calcSet)
            Dim table = calcSet.ToDataTable(session, tableOptions)

            ' normalize the table
            table.AsEnumerable.SetFieldIfNull("LocationId", locationId)
            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(table)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)
            AddCalculationColors(session, table)

            ' we want to keep the factor, and the two top level componenets, delete everything else
            Dim calculationsRequiredList = New List(Of String)(factorList)
            Dim factorComponents = F1F2F3ReportEngine.GetFactorComponentList(useCalculationPrefixes:=False)
            Dim factorPrefix = factorId.Replace("Factor", "")
            calculationsRequiredList.AddRange(factorComponents(factorId).Select(Function(s) factorPrefix + s))
            table.AsEnumerable.Where(Function(r) Not calculationsRequiredList.Contains(r.AsString("ReportTagId"))).DeleteRows()

            ' set some default fields that will be needed when adding context information
            table.AsEnumerable.SetFieldIfNull("ResourceClassification", "ResourceClassificationTotal")
            table.Columns.AddIfNeeded("ContextCategory", GetType(String)).SetDefault("Factor")
            table.Columns.AddIfNeeded("ContextGrouping", GetType(String)).SetDefault("None")
            table.Columns.AddIfNeeded("ContextGroupingLabel", GetType(String)).SetDefault("-")

            ' add ResClass data
            If contextList.Contains("ResourceClassification") Then
                F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)
                F1F2F3ReportEngine.AddResourceClassificationColor(table, columnName:="ResclassColor")
                AddResourceClassificationContext(table)
            End If

            ' add haulage context information
            If contextList.Contains("DepletionContext") Then
                Dim locationTable = AddDepletionContextData(session, dateBreakdown, locationId, factorId, calcSet)
                table.Merge(locationTable)
            End If

            ' unpivot and add standard attribute flags
            F1F2F3ReportEngine.UnpivotDataTable(table, maintainTonnes:=True)
            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            F1F2F3ReportEngine.AddAttributeIds(table)
            F1F2F3ReportEngine.AddAttributeValueFormat(table)

            ' recalculate the factor grade and tonnes values from the factor
            AddBottomFactorTonnes(table)
            AddBottomFactorGradeValue(table)

            If contextList.Contains("HaulageContext") Then
                ReportColour.AddLocationColor(session, table)
                F1F2F3ReportEngine.AddLocationDataToTable(session, table, locationId)
                AddHaulageContextData(session, table, dateBreakdown)
                F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            End If

            AddShortFactorDescriptions(table)
            NormalizeGroupingLabels(table)

            ' in some cases we can end up with incorrect date ranges on the RC data. Not sure the root causes of this,
            ' if we should just remove the data, or somehow fix it higher up the chain? But for now will just remove this
            ' data, as I can't reproduce it in the dev env to do a proper investigation
            table.AsEnumerable.Where(Function(r) r.AsDate("DateFrom") <> r.AsDate("CalendarDate")).DeleteRows()

            Return table
        End Function

        Private Shared Function AddHaulageContextData(session As ReportSession, table As DataTable, dateBreakdown As ReportBreakdown) As DataTable
            Dim locationId = session.RequestParameter.LocationId
            Dim dateFrom = session.RequestParameter.StartDate
            Dim dateTo = session.RequestParameter.EndDate
            Dim haulage = session.DalReport.GetBhpbioHaulageMovementsToCrusher(locationId.Value, dateFrom, dateTo, dateBreakdown.ToParameterString)

            ' now we need to add this to the main table as haulage context data
            For Each haulageRow As DataRow In haulage.Rows
                Dim row = HaulageRowToFactorRow(haulageRow, table)
                table.Rows.Add(row)
            Next

            Dim haulageRows = table.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "HaulageContext")

            ' make sure the colors are there for the new locations
            ReportColour.AddLocationColor(session, haulageRows.Where(Function(r) r.AsString("LocationType") = "Pit"))
            haulageRows.Where(Function(r) r.HasValue("LocationColor")).SetField("PresentationColor", Function(r) r.AsString("LocationColor"))

            SetHaulageContextOtherCategory(haulageRows)
            NormalizeHaulageContextFirstMonth(haulageRows)

            table.Columns.AddIfNeeded("ContextGroupingOrder", GetType(Integer)).SetDefault(0)
            haulageRows.AsEnumerable.SetField("ContextGroupingOrder", Function(r) GetContextGroupingOrder(r))

            Return table
        End Function

        ' Take the haulage row returned by the 
        Private Shared Function HaulageRowToFactorRow(sourceRow As DataRow, destTable As DataTable) As DataRow
            Dim row = destTable.AsEnumerable.First.CloneFactorRow(addToTable:=False)

            row("CalendarDate") = sourceRow("DateFrom")
            row("DateFrom") = sourceRow("DateFrom")
            row("DateTo") = sourceRow("DateTo")
            row("DateText") = sourceRow.AsDate("DateFrom").ToString("MMMM-yy")

            row("LocationId") = sourceRow("LocationId")
            row("LocationName") = sourceRow("LocationName")
            row("LocationType") = sourceRow("LocationType")

            row("ContextCategory") = "HaulageContext"
            row("ContextGrouping") = sourceRow("LocationName")
            row("ContextGroupingLabel") = sourceRow.AsString("LocationName")
            row("PresentationColor") = sourceRow.AsString("LocationName").AsColor
            row("LocationColor") = DBNull.Value

            row("Attribute") = sourceRow("Grade_Name")
            row("AttributeValue") = 0.0

            row("Type") = 1 ' this means a non-factor row
            row("Tonnes") = sourceRow("TotalTonnes")
            row("FactorGradeValueBottom") = sourceRow("Grade_Value")
            row("FactorTonnesBottom") = sourceRow("TotalTonnes")

            If row.AsString("ContextGroupingLabel").Length > 5 Then
                Dim ln = 5
                Dim s = row.AsString("ContextGroupingLabel").Trim()
                Dim label = s.Substring(s.Length - ln, ln)

                If label.StartsWith("-") Or label.StartsWith("_") Then
                    label = label.Substring(1)
                End If

                row("ContextGroupingLabel") = label
            End If

            Return row
        End Function

        Private Shared Function GetContextGroupingOrder(row As DataRow) As Integer
            If row.AsString("ContextGrouping") = "Other" Then
                Return 3
            ElseIf row.AsString("ContextGrouping") = "StockpileContext" Then
                Return 4
            ElseIf row.AsString("LocationType") = "Pit" Then
                Return 1
            ElseIf row.AsString("LocationType") = "Stockpile" Then
                Return 2
            Else
                Return 50
            End If
        End Function

        ' There is a bug in SSRS that requires each series that appears in the legend to appear in the first
        ' category on the stacked bar chart. This method finds all those groups, and creates a row in the first
        ' section with zero tonnes to 'seed' the legend so that the colors will be rendered properly
        Private Shared Sub NormalizeHaulageContextFirstMonth(haulageRows As IEnumerable(Of DataRow))
            ' get every context grouping label in the data set, and make a copy of it in the first month of the dataset
            Dim haulageRowsFiltered = haulageRows.Where(Function(r) r.AsString("ContextGrouping") <> "StockpileContext")
            Dim contextLabels = haulageRowsFiltered.GroupBy(Function(r) r.AsString("ContextGrouping") + "-" + r.AsString("ContextGroupingLabel") + "-" + r.AsString("Attribute"))

            Dim firstMonth = haulageRowsFiltered.Min(Function(r) r.AsDate("DateFrom"))
            Dim firstMonthRow = haulageRowsFiltered.FirstOrDefault(Function(r) r.AsDate("DateFrom") = firstMonth)

            For Each labelGroup In contextLabels
                Dim firstRow = labelGroup.OrderBy(Function(r) r.AsDate("DateFrom")).FirstOrDefault()

                If firstRow.AsDate("DateFrom") = firstMonth Then
                    ' we already have this label for the first month of the period
                    Continue For
                End If

                Dim newRow = firstRow.CloneFactorRow(addToTable:=True)
                newRow("CalendarDate") = firstMonthRow("CalendarDate")
                newRow("DateFrom") = firstMonthRow("DateFrom")
                newRow("DateTo") = firstMonthRow("DateTo")
                newRow("DateText") = firstMonthRow("DateText")

                newRow("Tonnes") = 0
                newRow("FactorGradeValueBottom") = 100
                newRow("FactorTonnesBottom") = 0

            Next
        End Sub

        Private Shared Sub SetHaulageContextOtherCategory(haulageRows As IEnumerable(Of DataRow))
            Dim willAddTotalLabels = True
            Dim haulageGroups = haulageRows.GroupBy(Function(r) String.Format("{0}-{1}", r.AsString("Attribute"), r.AsDate("DateFrom").ToString("yyyy-MM-dd"))).ToList

            ' we are going to keep track of the total number of unique stockpiles that appear - if this number gets too
            ' big then the legend becomes broken, so after that we will just shove everything into the 'other' group
            Dim stockpileList = New Dictionary(Of String, String)
            Dim maximumStockpiles = 25

            ' reverse the list, so that if we hit the max number of stockpiles the ones that get pushed into the
            ' 'other' will be in the older months, so (hopefully) less relevant to the data
            haulageGroups.Reverse()

            ' we get the total tonnes in each group (for both stockpiles and pits), then loop through each stockpile
            ' in the group. If the % of the total tonnes is less than the threshold, or we went over the max number of
            ' pits, then we push it to 'other'
            For Each g In haulageGroups
                Dim totalTonnes = g.Sum(Function(r) r.AsDblN("Tonnes"))

                For Each row As DataRow In g.Where(Function(r) r.AsString("LocationType") = "Stockpile")
                    Dim stockpileName = row.AsString("ContextGrouping")

                    If row.AsDblN("Tonnes") / totalTonnes < 0.05 Or stockpileList.Keys.Count > maximumStockpiles Then
                        row("ContextGrouping") = "Other"
                        row("ContextGroupingLabel") = "Other SPs"
                        row("PresentationColor") = "#C0C0C0"
                    Else
                        If Not stockpileList.ContainsKey(stockpileName) Then
                            stockpileList.Add(stockpileName, stockpileName)
                        End If
                    End If
                Next

                If willAddTotalLabels Then
                    ' above the stockpile bars we want to show a label with the percent total stockpiles
                    Dim stockpileRecords = g.Where(Function(r) r.AsString("LocationType") = "Stockpile")
                    Dim stockpileTotalTonnes = stockpileRecords.Sum(Function(r) r.AsDblN("Tonnes"))
                    Dim stockpileProportion = stockpileTotalTonnes / totalTonnes

                    If stockpileRecords.Count > 0 Then
                        Dim labelRecord = stockpileRecords.FirstOrDefault().CloneFactorRow(addToTable:=True)
                        labelRecord("Tonnes") = totalTonnes * 0.05
                        labelRecord("FactorTonnesBottom") = totalTonnes * 0.05

                        labelRecord("ContextGroupingLabel") = (stockpileProportion.Value * 100).ToString("N1") + "% from SPs"
                        labelRecord("ContextGrouping") = "StockpileContext"
                        labelRecord("PresentationColor") = "Transparent"
                    End If
                End If

            Next

        End Sub

        Private Shared Function AddDepletionContextData(ByRef session As ReportSession, dateBreakdown As ReportBreakdown, locationId As Integer, factorId As String, calcSet As CalculationSet) As DataTable

            Dim tableOptions = New DataTableOptions With {
                .DateBreakdown = dateBreakdown,
                .IncludeSourceCalculations = True,
                .GroupByLocationId = True
            }

            Dim locationTable = calcSet.ToDataTable(session, tableOptions)

            If session.RequestParameter.ChildLocations Then
                locationTable.AsEnumerable.Where(Function(r) r.IsNull("LocationId")).DeleteRows()
                locationTable.AsEnumerable.Where(Function(r) r.AsInt("LocationId") = locationId).DeleteRows()
            Else
                locationTable.AsEnumerable.SetFieldIfNull("LocationId", locationId)
            End If

            locationTable.AsEnumerable.Where(Function(r) r.HasValue("ResourceClassification")).DeleteRows()
            locationTable.Columns.AddIfNeeded("ContextCategory", GetType(String)).SetDefault("DepletionContext")
            locationTable.Columns.AddIfNeeded("ContextGrouping", GetType(String)).SetDefault("-1")
            locationTable.Columns.AddIfNeeded("ContextGroupingLabel", GetType(String)).SetDefault("-")

            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(locationTable)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(locationTable)
            F1F2F3ReportEngine.FilterTableByFactors(locationTable, New String() {factorId})
            ReportColour.AddLocationColor(session, locationTable)
            F1F2F3ReportEngine.AddLocationDataToTable(session, locationTable, locationId)

            locationTable.Columns.AddIfNeeded("PresentationColor", GetType(String))
            locationTable.AsEnumerable.SetField("PresentationColor", Function(r) r.AsString("LocationColor"))
            locationTable.AsEnumerable.SetField("ContextGrouping", Function(r) r.AsInt("LocationId").ToString())
            locationTable.AsEnumerable.SetField("ContextGroupingLabel", Function(r) r.AsString("LocationName"))

            Return locationTable
        End Function

        Public Shared Function AddResourceClassificationContext(table As DataTable) As DataTable
            table.Columns.AddIfNeeded("ContextCategory", GetType(String))
            table.Columns.AddIfNeeded("ContextGrouping", GetType(String))

            For Each row As DataRow In table.Rows
                If row.HasValue("ResourceClassification") AndAlso row.AsString("ResourceClassification") <> "ResourceClassificationTotal" Then
                    row("ContextCategory") = "ResourceClassification"
                    row("ContextGrouping") = row.AsString("ResourceClassification")
                    row("PresentationColor") = row.AsString("ResclassColor")
                End If
            Next

            Return table
        End Function

        Public Shared Function AddBottomFactorTonnes(table As DataTable) As DataTable
            If Not table.Columns.Contains("AttributeDifference") Then
                AddAttributeDifference(table)
            End If

            table.Columns.AddIfNeeded("FactorTonnesBottom", GetType(Double))
            table.AsEnumerable.FactorRows.SetField("FactorTonnesBottom", Function(r) r.AsDblN("TonnesDifference") / (r.AsDblN("Tonnes") - 1))
            Return table
        End Function

        Public Shared Function AddBottomFactorGradeValue(table As DataTable) As DataTable
            If Not table.Columns.Contains("AttributeDifference") Then
                AddAttributeDifference(table)
            End If

            table.Columns.AddIfNeeded("FactorGradeValueBottom", GetType(Double))
            table.AsEnumerable.FactorRows.SetField("FactorGradeValueBottom", Function(r) ErrorContributionEngine.GetFactorGradeValue(r, r.AsString("Attribute")))
            Return table
        End Function

        Public Shared Function AddAttributeDifference(table As DataTable) As DataTable
            If Not table.IsUnpivotedTable Then
                Throw New ArgumentException("An unpivoted factor DataTable Is required", "table")
            End If

            table.Columns.AddIfNeeded("AttributeDifference", GetType(Double))

            For Each row As DataRow In table.Rows
                row("AttributeDifference") = row(row.AsString("Attribute") + "Difference")
            Next

            Return table
        End Function

        Public Shared Function AddShortFactorDescriptions(table As DataTable) As DataTable
            table.Columns.AddIfNeeded("ShortDescription", GetType(String))

            For Each row As DataRow In table.Rows
                Select Case row.AsString("CalcId")
                    Case "F1Factor" : row("ShortDescription") = "F1"
                    Case "F15Factor" : row("ShortDescription") = "F1.5"
                    Case "F2Factor" : row("ShortDescription") = "F2"
                    Case "F25Factor" : row("ShortDescription") = "F2.5"
                    Case "F3Factor" : row("ShortDescription") = "F3"
                    Case Else : row("ShortDescription") = row("Description")
                End Select

            Next

            Return table
        End Function

        ' if the label is above a certain length, then we replace the spaces with line breaks so that it wraps properly
        Public Shared Function NormalizeGroupingLabels(table As DataTable) As DataTable
            For Each row As DataRow In table.Rows
                Dim contextGroupingLabel = row.AsString("ContextGroupingLabel")
                If contextGroupingLabel.Length > 8 Then
                    row("ContextGroupingLabel") = contextGroupingLabel.Replace(" ", vbCrLf)
                End If
            Next

            Return table
        End Function


        Public Shared Function AddCalculationColors(session As ReportSession, table As DataTable) As DataTable
            Dim colourList = ReportColour.GetColourList(session)
            table.Columns.AddIfNeeded("PresentationColor", GetType(String))

            For Each row As DataRow In table.Rows
                Dim reportTagId = row.AsString("ReportTagId")
                Dim calcId = row.AsString("CalcId")

                If colourList.ContainsKey(reportTagId) Then
                    row("PresentationColor") = colourList(reportTagId)
                ElseIf colourList.ContainsKey(calcId) Then
                    row("PresentationColor") = colourList(calcId)
                Else
                    row("PresentationColor") = "Gray"
                End If
            Next

            Return table
        End Function
    End Class

    Module LocalExtensions
        <System.Runtime.CompilerServices.Extension()>
        Function RandomItem(rows As IEnumerable(Of DataRow)) As DataRow
            Return rows(Convert.ToInt32(Rnd() * rows.Count))
        End Function

    End Module

    'Module FactorTableExtensions

    '    <System.Runtime.CompilerServices.Extension()>
    '    Function ToCalcRow(row As DataRow) As CalcRow
    '        Return New CalcRow(row)
    '    End Function

    '    <System.Runtime.CompilerServices.Extension()>
    '    Function ToCalcRows(rows As IEnumerable(Of DataRow)) As List(Of CalcRow)
    '        Return rows.Select(Function(r) r.ToCalcRow).ToList
    '    End Function

    '    <System.Runtime.CompilerServices.Extension()>
    '    Function DateList(rows As IEnumerable(Of CalcRow)) As Date()
    '        Return rows.Select(Function(r) r.row.AsDate("DateFrom")).Distinct.ToArray
    '    End Function

    '    <System.Runtime.CompilerServices.Extension()>
    '    Function TotalTonnes(rows As IEnumerable(Of CalcRow)) As Double?
    '        Dim tonnesRows = rows
    '        Dim attributeCount = rows.Select(Function(r) r.row.AsString("Attribute")).Distinct.Count

    '        If attributeCount > 1 Then
    '            tonnesRows = rows.Where(Function(r) r.Attribute = "Tonnes")
    '        End If

    '        Return tonnesRows.Where(Function(r) Not r.row.IsFactorRow).Sum(Function(r) r.Tonnes)
    '    End Function

    '    '
    '    ' Assertion methods will throw an exception if the expected conditions are not met
    '    ' this saves hving to write / copy-paste the same if-throw logic every time
    '    '
    '    <System.Runtime.CompilerServices.Extension()>
    '    Sub AssertIsFactorRow(row As DataRow)
    '        If Not row.IsFactorRow Then
    '            Throw New Exception(String.Format("Factor Row required, but got '{0}'", row.AsString("ReportTagId")))
    '        End If
    '    End Sub
    'End Module

    ' some experimental classes for typed rows in the datatable that will allow easier operations 
    ' for totalling and grouping data
    'Class CalcRow
    '    Public ReadOnly Property row As DataRow

    '    Public Sub New(sourceRow As DataRow)
    '        Me.row = sourceRow
    '    End Sub

    '    Function Attribute() As String
    '        Return row.AsString("Attribute")
    '    End Function

    '    Function Tonnes() As Double?
    '        Return row.AsDblN("Tonnes")
    '    End Function

    '    Function FactorTonnes() As Double?
    '        row.AssertIsFactorRow
    '        Return row.AsDblN("TonnesDifference") / (row.AsDblN("Tonnes") - 1)
    '    End Function

    '    Function FactorGradeValue() As Double?
    '        row.AssertIsFactorRow
    '        Return ErrorContributionEngine.GetFactorGradeValue(row, row.AsString("Attribute"))
    '    End Function

    '    Function FactorGradeTonnes() As Double?
    '        row.AssertIsFactorRow
    '        Return FactorTonnes() * FactorGradeValue() / 100.0
    '    End Function

    '    ' Shortcuts to get the data directly from the row
    '    Function ReportTagId(row As DataRow) As String
    '        Return row.AsString("ReportTagId")
    '    End Function

    '    Function CalcId(row As DataRow) As String
    '        Return row.AsString("CalcId")
    '    End Function

    'End Class

End Namespace

