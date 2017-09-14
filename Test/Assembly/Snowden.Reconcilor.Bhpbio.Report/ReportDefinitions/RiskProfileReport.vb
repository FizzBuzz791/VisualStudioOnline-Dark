Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.WebService
Imports System.Linq
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace ReportDefinitions

    Public Class RiskProfilereport

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal locationId As Int32,
            ByVal asAtDate As DateTime, ByVal reportingLocationType As String, ByVal factorType As String) As DataTable

            session.OverrideModelDataLocationTypeBreakdown = reportingLocationType
            session.UseHistorical = False

            Dim factorCalculationId As String = Nothing
            If (factorType = "F1") Then
                factorCalculationId = "F1Factor"
            ElseIf (factorType = "F15") Then
                factorCalculationId = "F15Factor"
            Else
                Throw New ArgumentException("Unknown factor type specified for reporting", "factorType")
            End If

            session.CalculationParameters(asAtDate, asAtDate, ReportBreakdown.None, locationId, True)
            Dim resultTable = GetForwardData(session, factorCalculationId)

            session.IncludeResourceClassification = False
            session.ForwardModelFactorCalculation = False

            ' get the production for the last 12 months
            session.CalculationParameters(asAtDate.AddMonths(-12), asAtDate.AddDays(-1), ReportBreakdown.Monthly, locationId, True)
            session.ClearCacheBlockModel()

            ' Calculate for the historic data (annual production)
            Dim actualCalcs = Types.CalculationSet.CreateForCalculations(session, New String() {"GradeControlModel"})
            Dim actualTableLast12Months = actualCalcs.ToDataTable(session, New DataTableOptions With {.GroupByLocationId = True, .DateBreakdown = ReportBreakdown.None})
            Dim actualTableByMonth = actualCalcs.ToDataTable(session, New DataTableOptions With {.GroupByLocationId = True, .DateBreakdown = ReportBreakdown.Monthly})

            ' Iterate for each factor row with empty resource classification
            For Each row As DataRow In resultTable.AsEnumerable.Where(Function(r) _
                                                                      r("ReportTagId").ToString() = factorCalculationId _
                                                                      AndAlso (r("ReportTagId") Is DBNull.Value _
                                                                        OrElse String.IsNullOrEmpty(r("ResourceClassification").ToString())) _
                                                                      AndAlso (r("ProductSize") Is DBNull.Value _
                                                                        OrElse String.IsNullOrEmpty(r("ProductSize").ToString()) _
                                                                        OrElse r("ProductSize").ToString() = "TOTAL")) _
                                                                        .ToList()

                '   find the matching grade control row in the result table
                Dim resultModel1Row = resultTable.AsEnumerable.GetCorrespondingRowWithReportTagId("F1GradeControlModel", row)

                If resultModel1Row IsNot Nothing AndAlso resultModel1Row.HasValue("Tonnes") Then
                    '   Copy the tonnes value to the factor row
                    row("TonnesValue") = resultModel1Row.AsDbl("Tonnes")
                End If

                '   Find the grade control tonnes row in the actual set
                Dim actualModel1RowLast12Months = actualTableLast12Months.AsEnumerable.GetCorrespondingRowWithReportTagId("GradeControlModel", row, ignoreDateFrom:=True)

                If actualModel1RowLast12Months IsNot Nothing AndAlso actualModel1RowLast12Months.HasValue("Tonnes") Then
                    '   Calculate average production and assign to the factor row
                    row("AverageMonthlyProductionTonnes") = actualModel1RowLast12Months.AsDbl("Tonnes") / 12.0
                End If

                Dim actualModel1RowLastMonth = actualTableByMonth.AsEnumerable.GetCorrespondingRowWithReportTagId("GradeControlModel", row, ignoreDateFrom:=False, overrideDateFromToMatch:=asAtDate.AddMonths(-1))

                If actualModel1RowLastMonth IsNot Nothing AndAlso actualModel1RowLastMonth.HasValue("Tonnes") Then
                    '   assign to the factor row
                    row("LastMonthProductionTonnes") = actualModel1RowLastMonth.AsDbl("Tonnes")
                End If

                Dim rcRows = resultTable.AsEnumerable.GetCorrespondingRowsForResourceClassifications(resultModel1Row)

                If rcRows IsNot Nothing Then
                    For Each dr As DataRow In rcRows
                        If dr.HasValue("Tonnes") Then
                            row(dr.AsString("ResourceClassification")) = dr.AsDbl("Tonnes")
                        End If
                    Next
                End If
            Next

            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(resultTable)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(resultTable)
            F1F2F3ReportEngine.FilterTableByFactors(resultTable, New String() {factorCalculationId})

            ' get rid of rows not related to a specific location
            resultTable.AsEnumerable.Where(Function(r) r.IsNull("LocationId") OrElse Not r.IsNull("ResourceClassification")).DeleteRows()

            ' add locaation information, and get rid of rows with no location name resolved.. this must not 
            ' belong to the hieararchy at the specified date
            AddLocationInformationToResults(session, asAtDate, locationId, reportingLocationType, resultTable)
            resultTable.AsEnumerable.Where(Function(r) r.IsNull("LocationName")).DeleteRows()

            SetMaximumTonnes(resultTable)
            ZeroNullFields(resultTable)

            Return resultTable.SortBy("LocationName")
        End Function

        Private Shared Function GetForwardData(session As ReportSession, factorCalculationId As String) As DataTable
            session.IncludeResourceClassification = True
            session.ForwardModelFactorCalculation = True

            Dim calcIds = New List(Of String)

            If (factorCalculationId = "F1Factor") Then
                calcIds.Add("F1Factor")
            ElseIf (factorCalculationId = "F15Factor") Then
                calcIds.Add("F1Factor")
                calcIds.Add("F15Factor")
            Else
                Throw New ArgumentException("Unknown factor type specified for reporting", "factorType")
            End If

            ' table storing results
            Dim holdingData = Types.CalculationSet.CreateForCalculations(session, calcIds.ToArray)
            Dim table = holdingData.ToDataTable(True, False, True, False, ReportBreakdown.None, session, False)

            ' add extra columns that will be needed for the average production etc
            If Not table.Columns.Contains("AverageMonthlyProductionTonnes") Then
                table.Columns.Add("AverageMonthlyProductionTonnes", GetType(Double))
            End If

            If Not table.Columns.Contains("LastMonthProductionTonnes") Then
                table.Columns.Add("LastMonthProductionTonnes", GetType(Double))
            End If

            ' column for storing the maximum dataset tonnes value across any row
            If Not table.Columns.Contains("MaximumDataSetTonnes") Then
                table.Columns.Add("MaximumDataSetTonnes", GetType(Double))
            End If

            If Not table.Columns.Contains("TonnesValue") Then
                table.Columns.Add("TonnesValue", GetType(Double))
            End If

            For Each columnName In ResourceContributionReports.ResourceClassificationFieldNames
                If Not table.Columns.Contains(columnName) Then
                    table.Columns.Add(columnName, GetType(Double))
                End If
            Next

            Return table
        End Function


        Private Shared Sub SetMaximumTonnes(table As DataTable)
            Dim maxTonnage As Double = 0

            For Each row As DataRow In table.AsEnumerable
                If row.HasValue("AverageMonthlyProductionTonnes") AndAlso row.AsDbl("AverageMonthlyProductionTonnes") > maxTonnage Then
                    maxTonnage = row.AsDbl("AverageMonthlyProductionTonnes")
                End If

                If row.HasValue("LastMonthProductionTonnes") AndAlso row.AsDbl("LastMonthProductionTonnes") > maxTonnage Then
                    maxTonnage = row.AsDbl("LastMonthProductionTonnes")
                End If

                If row.HasValue("TonnesValue") AndAlso row.AsDbl("TonnesValue") > maxTonnage Then
                    maxTonnage = row.AsDbl("TonnesValue")
                End If
            Next

            ' Fill the maximum tonnage across the dataset into a column for every row (used for chart scaling on the report itself)
            table.AsEnumerable.SetField("MaximumDataSetTonnes", maxTonnage)
        End Sub

        Private Shared Sub ZeroNullFields(table As DataTable)
            Dim extraFieldsToZero = New String() {
                "AverageMonthlyProductionTonnes",
                "LastMonthProductionTonnes",
                "TonnesValue",
                "H2ODifference"
            }

            Dim fieldsToZero = extraFieldsToZero.ToList()
            fieldsToZero.AddRange(ResourceContributionReports.ResourceClassificationFieldNames)

            ' Ensure all rows have resource classification values (replace nulls with 0s)

            For Each row As DataRow In table.AsEnumerable
                For Each columnName In fieldsToZero
                    If Not row.HasValue(columnName) Then
                        row(columnName) = 0
                    End If
                Next
            Next
        End Sub

        Private Shared Sub AddLocationInformationToResults(session As ReportSession, asAtDate As DateTime, locationId As Integer, toLocationType As String, resultTable As DataTable)
            ' Make a dictionary of location names
            Dim locationNamesById As New Dictionary(Of Integer, String)
            Dim locationHierarchy As DataTable = session.DalUtility.GetBhpbioLocationParentHeirarchyWithOverride(locationId, asAtDate)
            Dim locationDataRow = locationHierarchy.AsEnumerable().Last()
            Dim locationName = locationDataRow("Name").ToString()
            Dim locationType = locationDataRow("Location_Type_Description").ToString()
            locationNamesById.Add(locationId, locationName)

            ' and fill out the dictionary recursively with child locations as approproate
            AddChildLocationsToDictionaryUntilLocationType(locationNamesById, session, asAtDate, locationId, locationName, locationType, locationType, toLocationType)

            ' iterate through the result table and add location 
            If Not resultTable.Columns.Contains("LocationName") Then
                resultTable.Columns.Add("LocationName", GetType(String))
            End If

            For Each row As DataRow In resultTable.AsEnumerable
                If (Not row("LocationId") Is DBNull.Value) Then

                    Dim name As String = Nothing

                    If locationNamesById.TryGetValue(row.AsInt("LocationId"), name) Then
                        row("LocationName") = name
                    End If
                End If
            Next
        End Sub

        Private Shared Sub AddChildLocationsToDictionaryUntilLocationType(ByRef locationNamesById As Dictionary(Of Integer, String), session As ReportSession, asAtDate As DateTime, locationId As Integer, locationName As String, topLevelLocationType As String, locationType As String, toLocationType As String)

            If locationType.ToUpper = toLocationType.ToUpper Then
                ' already at the required location type
                Return
            End If

            Dim locations As DataTable = session.DalUtility.GetBhpbioLocationChildrenNameWithOverride(locationId, asAtDate, asAtDate)

            For Each row As DataRow In locations.AsEnumerable
                Dim rowLocationId As Integer = row.AsInt("Location_Id")
                Dim rowLocationName As String = row("Name").ToString()
                Dim rowLocationType As String = row("Location_Type_Description").ToString()

                If rowLocationType.ToUpper = "PIT" AndAlso Not (topLevelLocationType.ToUpper = "SITE") Then
                    rowLocationName = String.Format("{0} - {1}", locationName, rowLocationName) ' prefix the pit name with the site name when reporting multiple sites
                End If

                locationNamesById.Add(rowLocationId, rowLocationName)

                If Not rowLocationType.ToUpper = toLocationType.ToUpper Then
                    AddChildLocationsToDictionaryUntilLocationType(locationNamesById, session, asAtDate, rowLocationId, rowLocationName, topLevelLocationType, rowLocationType, toLocationType)
                End If
            Next

        End Sub
    End Class

End Namespace