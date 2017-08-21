Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class SampleStationReporter : Inherits Reporter : Implements ISampleStationReporter
        Public Sub New()
        End Sub

        Public Sub AddSampleStationCoverageContextData(ByRef masterTable As DataTable, locationId As Integer,
                                                       startDate As DateTime, endDate As DateTime,
                                                       dateBreakdown As ReportBreakdown, dalReport As SqlDalReport) _
                                                       Implements ISampleStationReporter.AddSampleStationCoverageContextData

            Dim coverage = dalReport.GetBhpbioSampleStationReportData(locationId, startDate, endDate,
                                                                    dateBreakdown.ToParameterString())

            CombineSmallSamplesIntoOtherCategory(coverage.AsEnumerable)

            For Each coverageRow As DataRow In coverage.Rows
                AddCoverageRowAsFactorRow(coverageRow, masterTable, String.Empty, coverageRow.AsDbl("Assayed"), coverageRow.AsString("SampleStation"))
            Next

            AddUnsampledRows(coverage.AsEnumerable, masterTable)

            SeedLegend(masterTable.AsEnumerable.ToList())

            masterTable.Columns.AddIfNeeded("ContextGroupingOrder", GetType(Integer)).SetDefault(0)

            Dim coverageRows = masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "SampleCoverage")
            coverageRows.AsEnumerable.SetField("ContextGroupingOrder", Function(r) GetContextGroupingOrder(r))
        End Sub

        Public Sub AddSampleStationRatioContextData() Implements ISampleStationReporter.AddSampleStationRatioContextData
            Throw New NotImplementedException
        End Sub

        ' There is a problem with the SSRS legend that requires each series to appear in the first category on the chart.
        ' This method finds all groups and creates a row in the first section with zero tonnes to 'seed' the legend
        ' so that the colors will be rendered properly.
        Private Shared Sub SeedLegend(allRows As IList(Of DataRow))
            Dim haulageRows = allRows.Where(Function(r) r.AsString("ContextCategory") = "HaulageContext" And r.AsString("ContextGrouping") <> "StockpileContext").ToList
            If haulageRows.Any Then
                Dim coverageRows = allRows.Where(Function(r) r.AsString("ContextCategory") = "SampleCoverage")

                Dim firstMonth = haulageRows.Min(Function(r) r.AsDate("DateFrom"))
                Dim firstMonthRow = haulageRows.FirstOrDefault(Function(r) r.AsDate("DateFrom") = firstMonth)

                For Each periodGroup In coverageRows.GroupBy(Function(r) $"{r.AsString("ContextGrouping")}-{r.AsString("ContextGroupingLabel")}-{r.AsString("Attribute")}")
                    Dim firstCoverageRow = periodGroup.OrderBy(Function(r) r.AsDate("DateFrom")).FirstOrDefault()

                    Dim seedHaulageRow = firstMonthRow.CloneFactorRow(addToTable:=True)
                    seedHaulageRow("CalendarDate") = firstCoverageRow("CalendarDate")
                    seedHaulageRow("DateFrom") = firstCoverageRow("DateFrom")
                    seedHaulageRow("DateTo") = firstCoverageRow("DateTo")
                    seedHaulageRow("DateText") = firstCoverageRow("DateText")

                    seedHaulageRow("LocationId") = firstCoverageRow("LocationId")
                    seedHaulageRow("LocationName") = firstCoverageRow("LocationName")
                    seedHaulageRow("LocationType") = firstCoverageRow("LocationType")

                    seedHaulageRow("ContextGrouping") = firstCoverageRow("ContextGrouping")
                    seedHaulageRow("ContextGroupingLabel") = firstCoverageRow("ContextGroupingLabel")
                    seedHaulageRow("PresentationColor") = firstCoverageRow("PresentationColor")

                    seedHaulageRow("Attribute") = firstCoverageRow("Attribute")

                    seedHaulageRow("Tonnes") = 0
                    seedHaulageRow("FactorGradeValueBottom") = 100
                    seedHaulageRow("FactorTonnesBottom") = 0
                Next
            End If
        End Sub

        Private Shared Sub CombineSmallSamplesIntoOtherCategory(coverageRows As IEnumerable(Of DataRow))
            ' Group by period & grade to find the total tonnes (sampled + unsampled)
            For Each periodGroup In coverageRows.GroupBy(Function(r) $"{r.AsDate("DateFrom")}-{r.AsInt("Grade_Id")}").Reverse()
                Dim totalTonnesMoved = periodGroup.Sum(Function(r) r.AsDbl("Assayed") + r.AsDbl("Unassayed"))
                Dim periodThreshold = totalTonnesMoved * 0.05 ' 5%

                ' Loop through each row, marking as "Other" if <= 5%
                For Each row In periodGroup
                    Dim tonnesMoved = row.AsDbl("Assayed") + row.AsDbl("Unassayed")
                    If tonnesMoved <= periodThreshold Then
                        row("SampleStation") = "Other" ' This affects ContextGrouping & Context Grouping Label
                    End If
                Next
            Next
        End Sub

        Private Shared Sub AddUnsampledRows(coverageRows As IEnumerable(Of DataRow), ByRef masterTable As DataTable)
            ' Group by period (month/quarter) to find the total unsampled for that "stack".
            For Each periodGroup In coverageRows.GroupBy(Function(r) $"{r.AsDate("DateFrom")}-{r.AsInt("Grade_Id")}")
                Dim totalUnsampled = periodGroup.Sum(Function(r) r.AsDbl("Unassayed"))
                ' Add a new row for each grade to show the unsampled
                Dim representativeRow = periodGroup.FirstOrDefault()
                AddCoverageRowAsFactorRow(representativeRow, masterTable, "#C0C0C0", totalUnsampled, "Unsampled")
            Next
        End Sub

        ' TODO: Can/should this be made generic? (Consider HaulageContext needs to be refactored to this Reporter pattern)
        ''' <summary>
        ''' Convert a coverage row to a factor row (a.k.a. standard row) and add to the master table.
        ''' </summary>
        ''' <param name="coverageRow">Row to convert.</param>
        ''' <param name="masterTable">Table to add converted row to.</param>
        ''' <param name="presentationColor">Color to display on the report. If null or empty, will convert LocationName to a color.</param>
        ''' <param name="tonnes">Tonnes to display on the report.</param>
        ''' <param name="contextGrouping">Field to group the context on.</param>
        Private Shared Sub AddCoverageRowAsFactorRow(coverageRow As DataRow, ByRef masterTable As DataTable,
                                                     presentationColor As String, tonnes As Double, contextGrouping As String)
            ' If *only* Coverage has been chosen, these rows won't exist in the master table.
            masterTable.Columns.AddIfNeeded("LocationName", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationType", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationColor", GetType(String)).SetDefault(String.Empty)

            Dim row = masterTable.AsEnumerable.First.CloneFactorRow(addToTable:=False)

            row("CalendarDate") = coverageRow("DateFrom")
            row("DateFrom") = coverageRow("DateFrom")
            row("DateTo") = coverageRow("DateTo")
            row("DateText") = coverageRow.AsDate("DateFrom").ToString("MMMM-yy")

            row("LocationId") = coverageRow("LocationId")
            row("LocationName") = coverageRow("SampleStation")
            row("LocationType") = "SampleCoverage"

            row("ContextCategory") = "SampleCoverage"
            row("ContextGrouping") = contextGrouping
            row("ContextGroupingLabel") = contextGrouping
            row("PresentationColor") = IIf(String.IsNullOrEmpty(presentationColor), coverageRow.AsString("SampleStation").AsColor, presentationColor)
            row("LocationColor") = DBNull.Value

            row("Attribute") = coverageRow("Grade_Name")
            row("AttributeValue") = 0.0

            row("Type") = 1 ' this means a non-factor row
            row("Tonnes") = tonnes
            row("FactorGradeValueBottom") = coverageRow("Grade_Value")
            row("FactorTonnesBottom") = tonnes

            masterTable.Rows.Add(row)
        End Sub
    End Class
End Namespace