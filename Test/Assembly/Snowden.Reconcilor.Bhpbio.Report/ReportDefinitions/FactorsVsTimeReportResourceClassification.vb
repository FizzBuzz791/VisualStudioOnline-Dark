Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

Namespace ReportDefinitions
    Public Class FactorsVsTimeReportResourceClassification

        Public Const INVALID_RC = "INVALID_RC"
        Friend Shared Function GetData(session As ReportSession, locationId As Integer, locationGroupId As Integer?, dateBreakdown As ReportBreakdown, dateFrom As DateTime, dateTo As DateTime, factor As String, attributeList() As String, resourceClassifications() As String) As DataTable

            Dim factorList = (New String() {factor}).ToList

            If locationGroupId.HasValue AndAlso locationGroupId > 0 Then
                session.LocationGroupId = locationGroupId.Value
            End If

            session.IncludeProductSizeBreakdown = False
            session.IncludeResourceClassification = True
            session.CalculationParameters(dateFrom, dateTo, locationId, True)

            Dim tableOptions = New DataTableOptions With {
                .DateBreakdown = dateBreakdown,
                .IncludeSourceCalculations = True,
                .GroupByLocationId = False
            }

            'Need to add Geology Model and Grade Control for use in the graphs
            factorList.Add(Calc.ModelGeology.CalculationId)
            Dim calcSet = Types.CalculationSet.CreateForCalculations(session, factorList.ToArray)

            Data.ReportColour.AddPresentationColour(session, calcSet)
            Data.DateBreakdown.AddDateText(dateBreakdown, calcSet)
            Dim table = calcSet.ToDataTable(session, tableOptions)

            ' normalize the table
            table.AsEnumerable.SetFieldIfNull("LocationId", locationId)
            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(table)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)
            AddCalculationColors(session, table)

            ' we want to keep the factor, and the two top level componenets, delete everything else
            Dim calculationsRequiredList = New List(Of String)(factorList)
            table.AsEnumerable.Where(Function(r) Not calculationsRequiredList.Contains(r.AsString("ReportTagId"))).DeleteRows()

            ' set some default fields that will be needed when adding context information
            table.AsEnumerable.SetFieldIfNull("ResourceClassification", "ResourceClassificationTotal")
            F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)
            F1F2F3ReportEngine.AddResourceClassificationColor(table, columnName:="ResclassColor")

            AddShortFactorDescriptions(table)

            'Recalculate Factors. Need to do it before unpivotting the data
            'F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)

            ' Invert density for display
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "Density", False)

            ' these models should no longer be added to the dataset, but just in case we delete them here, so the report
            ' doesn't break
            table.AsEnumerable.Where(Function(r) r.AsString("CalcId") = Calc.ModelGradeControl.CalculationId).DeleteRows()
            table.AsEnumerable.Where(Function(r) r.AsString("CalcId") = Calc.ModelMining.CalculationId).DeleteRows()
            table.AcceptChanges()

            ' unpivot and add standard attribute flags
            F1F2F3ReportEngine.UnpivotDataTable(table, maintainTonnes:=True)
            AddGeologyModelTonnesToUnpivoted(table)


            ' We need Tonnes even if it is not selected as it is shown on the first chart
            Dim attributeListWithTonnes = attributeList.ToList
            If Not attributeListWithTonnes.Contains("Tonnes") Then
                attributeListWithTonnes.Add("Tonnes")
            End If

            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeListWithTonnes.ToArray)
            F1F2F3ReportEngine.AddAttributeIds(table)
            F1F2F3ReportEngine.AddAttributeValueFormat(table)
            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)
            Data.GradeProperties.AddGradeColourToNormalizedTable(session, table)

            ' for the actual factor we are interested in (F0, F0.5 or F1) we need to keep the Total Resclass (to generate the
            ' tonnes context bars), but we want to filter out an Resclass types that the user didn't select with the checkboxes.
            '
            ' Note that the resource classification filtering is done by description, not by id
            table.AsEnumerable.
                Where(Function(r) r.AsString("CalcId") = factor).
                Where(Function(r) Not r.AsString("ResourceClassification").EndsWith("Total")).
                Where(Function(r) Not resourceClassifications.Contains(r.AsString("ResourceClassificationDescription"))).
                DeleteRows()

            table.AcceptChanges()

            Return table

        End Function

        Public Shared Sub AddGeologyModelTonnesToUnpivoted(ByRef table As DataTable)
            If Not table.IsUnpivotedTable Then Throw New Exception("This method is only valid on unpivoted tables")
            If Not table.Columns.Contains("Tonnes") Then Throw New Exception("This method requires the Tonnes field on the table. Run 'AddTonnesValuesToUnpivotedTable'")

            Dim gradeControlRows = table.AsEnumerable.Where(Function(r) r.AsString("CalcId") = "GeologyModel").ToList

            If Not table.Columns.Contains("GradeControlTonnes") Then
                table.Columns.Add("GradeControlTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                Dim gc = gradeControlRows.AsEnumerable.
                    GetCorrespondingRowsForGroupUnpivoted(row).
                    FirstOrDefault(Function(r) r.AsString("Attribute") = row.AsString("Attribute"))

                If gc IsNot Nothing AndAlso gc.HasValue("AttributeValue") AndAlso gc.HasValue("Tonnes") Then
                    Dim attributeName = gc.AsString("Attribute")
                    Dim gradePct = gc.AsDbl("AttributeValue") / 100.0

                    ' tonnes are tonnes, don't need to times by the gade value
                    If attributeName.Contains("Tonnes") Or attributeName = "Volume" Or attributeName = "Density" Then
                        gradePct = 1.0
                    End If

                    row("GradeControlTonnes") = gc.AsDbl("Tonnes") * gradePct
                Else
                    row("GradeControlTonnes") = 0.0
                End If
            Next
        End Sub


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

        Public Shared Function AddShortFactorDescriptions(table As DataTable) As DataTable
            table.Columns.AddIfNeeded("ShortDescription", GetType(String))

            For Each row As DataRow In table.Rows
                Select Case row.AsString("CalcId")
                    Case "F0Factor" : row("ShortDescription") = "F0.0"
                    Case "F05Factor" : row("ShortDescription") = "F0.5"
                    Case "F1Factor" : row("ShortDescription") = "F1"
                    Case Else : row("ShortDescription") = row("Description")
                End Select

            Next

            Return table
        End Function
    End Class
End Namespace