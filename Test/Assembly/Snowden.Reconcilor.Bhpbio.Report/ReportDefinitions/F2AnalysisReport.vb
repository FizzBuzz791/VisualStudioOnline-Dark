Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportHelpers

Namespace ReportDefinitions

    Public Class F2AnalysisReport
        Inherits ReportBase

        Public Shared Function GetData(session As ReportSession, locationId As Integer, dateBreakdown As ReportBreakdown, 
                                       dateFrom As DateTime, dateTo As DateTime, factorId As String, attributeList As String(),
                                       contextList As String()) As DataTable

            Dim table = PrepareTable(factorId, session, locationId, contextList, dateBreakdown, dateFrom, dateTo, attributeList)
            AddContextData(factorId, session, locationId, contextList, dateBreakdown, dateFrom, dateTo, table, attributeList)

            AddShortFactorDescriptions(table)
            NormalizeGroupingLabels(table)

            ' in some cases we can end up with incorrect date ranges on the RC data. Not sure the root causes of this,
            ' if we should just remove the data, or somehow fix it higher up the chain? But for now will just remove this
            ' data, as I can't reproduce it in the dev env to do a proper investigation
            table.AsEnumerable.Where(Function(r) r.AsDate("DateFrom") <> r.AsDate("CalendarDate")).DeleteRows()

            Return table
        End Function

        Public Shared Function PrepareTable(factorId As String, session As ReportSession, locationId As Integer, 
                                             contextList As String(), dateBreakdown As ReportBreakdown, dateFrom As Date, 
                                             dateTo As Date, attributeList As String()) As DataTable

            Dim factorList = (New String() {factorId}).ToList
            Dim locationTypeName = session.GetLocationTypeName(locationId).ToUpper()
            Dim canLoadSublocations As Boolean

            If locationTypeName = "COMPANY" Then
                canLoadSublocations = True
            ElseIf locationTypeName = "HUB" Then
                canLoadSublocations = (factorId = "F1Factor" OrElse factorId = "F15Factor" OrElse factorId = "F2Factor")
            ElseIf locationTypeName = "SITE" Then
                canLoadSublocations = (factorId = "F1Factor" OrElse factorId = "F15Factor")
            Else
                canLoadSublocations = False
            End If

            If contextList.Contains("ResourceClassification") AndAlso factorId <> "F1Factor" AndAlso factorId <> "F15Factor" Then
                factorList.Add("F1Factor")
            End If

            Dim tableOptions = New DataTableOptions With {
                .DateBreakdown = dateBreakdown,
                .IncludeSourceCalculations = True,
                .GroupByLocationId = False
            } 

            session.IncludeProductSizeBreakdown = False
            session.IncludeResourceClassification = contextList.Contains("ResourceClassification")
            session.CalculationParameters(dateFrom, dateTo, locationId, childLocations:=canLoadSublocations)

            Dim calcSet = CalculationSet.CreateForCalculations(session, factorList.ToArray)
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

            ' unpivot and add standard attribute flags
            F1F2F3ReportEngine.UnpivotDataTable(table, maintainTonnes:=True)
            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            F1F2F3ReportEngine.AddAttributeIds(table)
            F1F2F3ReportEngine.AddAttributeValueFormat(table)

            ' recalculate the factor grade and tonnes values from the factor
            AddBottomFactorTonnes(table)
            AddBottomFactorGradeValue(table)

            Return table
        End Function

        Private Shared Sub AddContextData(factorId As String, session As ReportSession, locationId As Integer, 
                                          contextList As String(), dateBreakdown As ReportBreakdown, dateFrom As Date, 
                                          dateTo As Date, table As DataTable, attributeList As String())

            ' set some default fields that will be needed when adding context information
            table.AsEnumerable.SetFieldIfNull("ResourceClassification", "ResourceClassificationTotal")
            table.Columns.AddIfNeeded("ContextCategory", GetType(String)).SetDefault("Factor")
            table.Columns.AddIfNeeded("ContextGrouping", GetType(String)).SetDefault("None")
            table.Columns.AddIfNeeded("ContextGroupingLabel", GetType(String)).SetDefault("-")

            If contextList.Contains("ResourceClassification") Then
                F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)
                F1F2F3ReportEngine.AddResourceClassificationColor(table, columnName:="ResclassColor")
                AddResourceClassificationContext(table)
            End If

            If contextList.Contains("HaulageContext") Then
                ReportColour.AddLocationColor(session, table)
                F1F2F3ReportEngine.AddLocationDataToTable(session, table, locationId)
                Dim haulageReporter As IHaulageReporter = New HaulageReporter(session.DalReport, session.DalUtility)
                haulageReporter.AddHaulageContextData(table, locationId, dateFrom, dateTo, dateBreakdown)
                'AddHaulageContextData(session, table, dateBreakdown)
                F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            End If

            If contextList.Contains("SampleCoverage") Or contextList.Contains("SampleRatio") Then
                table.Columns.AddIfNeeded("ContextCategory", GetType(String))
                table.Columns.AddIfNeeded("ContextGrouping", GetType(String))

                Dim sampleStationReporter As ISampleStationReporter = New SampleStationReporter(session.DalReport)

                If contextList.Contains("SampleCoverage") Then
                    ' WARNING: Don't use session.reportparameter as it could have been (read: will have been) modified.
                    sampleStationReporter.AddSampleStationCoverageContextData(table, locationId, dateFrom, dateTo,
                                                                              dateBreakdown)
                End If

                If contextList.Contains("SampleRatio") Then
                    sampleStationReporter.AddSampleStationRatioContextData(table, locationId, dateFrom, dateTo,
                                                                           dateBreakdown)
                End If

                F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            End If

            If session.LowestStratigraphyLevel > 0 Then
                Dim stratigraphyReporter AS IStratigraphyReporter = New StratigraphyReporter(session.LowestStratigraphyLevel)
                If factorId.StartsWith("F1", StringComparison.Ordinal) Then
                    stratigraphyReporter.AddStratigraphyContextDataForF1OrF15(table, locationId, dateFrom, dateTo, 
                                                                              dateBreakdown)
                Else 
                    stratigraphyReporter.AddStratigraphyContextDataForF2OrF3(table, locationId, dateFrom, dateTo,
                                                                             dateBreakdown, session.DalReport, False, 
                                                                             session.ShouldIncludeLiveData, 
                                                                             session.ShouldIncludeApprovedData, attributeList)
                End If
            End If

            If contextList.Contains("Weathering") Then
                Dim weatheringReporter AS IWeatheringReporter = New WeatheringReporter
                If factorId.StartsWith("F1", StringComparison.Ordinal) Then
                    weatheringReporter.AddWeatheringContextDataForF1OrF15(table, factorId, session, contextList, dateBreakdown, 
                                                                          dateFrom, dateTo, attributeList, locationId)
                Else                      
                    weatheringReporter.AddWeatheringContextDataForF2OrF3(table, locationId, dateFrom, dateTo, 
                                                                         dateBreakdown)
                End If
            End If
        End Sub

        Private Shared Sub AddResourceClassificationContext(table As DataTable)
            table.Columns.AddIfNeeded("ContextCategory", GetType(String))
            table.Columns.AddIfNeeded("ContextGrouping", GetType(String))

            For Each row As DataRow In table.Rows
                If row.HasValue("ResourceClassification") AndAlso row.AsString("ResourceClassification") <> "ResourceClassificationTotal" Then
                    row("ContextCategory") = "ResourceClassification"
                    row("ContextGrouping") = row.AsString("ResourceClassification")
                    row("PresentationColor") = row.AsString("ResclassColor")
                End If
            Next
        End Sub

        Private Shared Sub AddBottomFactorTonnes(table As DataTable)
            If Not table.Columns.Contains("AttributeDifference") Then
                AddAttributeDifference(table)
            End If

            table.Columns.AddIfNeeded("FactorTonnesBottom", GetType(Double))
            table.AsEnumerable.FactorRows.SetField("FactorTonnesBottom", Function(r) r.AsDblN("TonnesDifference") / (r.AsDblN("Tonnes") - 1))
        End Sub

        Private Shared Sub AddBottomFactorGradeValue(table As DataTable)
            If Not table.Columns.Contains("AttributeDifference") Then
                AddAttributeDifference(table)
            End If

            table.Columns.AddIfNeeded("FactorGradeValueBottom", GetType(Double))
            table.AsEnumerable.FactorRows.SetField("FactorGradeValueBottom", Function(r) ErrorContributionEngine.GetFactorGradeValue(r, r.AsString("Attribute")))
        End Sub

        Private Shared Sub AddAttributeDifference(table As DataTable)
            If Not table.IsUnpivotedTable Then
                Throw New ArgumentException("An unpivoted factor DataTable Is required", "table")
            End If

            table.Columns.AddIfNeeded("AttributeDifference", GetType(Double))

            For Each row As DataRow In table.Rows
                row("AttributeDifference") = row(row.AsString("Attribute") + "Difference")
            Next
        End Sub

        Private Shared Sub AddShortFactorDescriptions(table As DataTable)
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
        End Sub

        Private Shared Sub NormalizeGroupingLabels(table As DataTable)
            ' If the label is above a certain length, then we replace the spaces with line breaks so that it wraps properly
            For Each row As DataRow In table.Rows
                Dim contextGroupingLabel = row.AsString("ContextGroupingLabel")
                If contextGroupingLabel.Length > 8 Then
                    row("ContextGroupingLabel") = contextGroupingLabel.Replace(" ", vbCrLf)
                End If
            Next
        End Sub

        Private Shared Sub AddCalculationColors(session As ReportSession, table As DataTable)
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
        End Sub
    End Class
End Namespace