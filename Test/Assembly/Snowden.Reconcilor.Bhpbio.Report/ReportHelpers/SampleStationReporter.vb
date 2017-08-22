Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class SampleStationReporter : Inherits Reporter : Implements ISampleStationReporter
        Private ReadOnly Property DalReport As ISqlDalReport

        Public Sub New(dalReport As ISqlDalReport)
            Me.DalReport = dalReport
        End Sub

        Public Sub AddSampleStationCoverageContextData(ByRef masterTable As DataTable, locationId As Integer,
                                                       startDate As DateTime, endDate As DateTime,
                                                       dateBreakdown As ReportBreakdown) _
                                                       Implements ISampleStationReporter.AddSampleStationCoverageContextData

            Dim sampleStationReportData = DalReport.GetBhpbioSampleStationReportData(locationId, startDate, endDate,
                                                                                     dateBreakdown.ToParameterString())

            CombineSmallSamplesIntoOtherCategory(sampleStationReportData.AsEnumerable)

            For Each coverageRow As DataRow In sampleStationReportData.Rows
                AddSampleStationRowAsNonFactorRow(coverageRow, masterTable, String.Empty, coverageRow.AsDbl("Assayed"),
                                                  coverageRow.AsString("SampleStation"), "SampleCoverage", "SampleCoverage")
            Next

            AddUnsampledRows(sampleStationReportData.AsEnumerable, masterTable)

            SeedLegend(masterTable.AsEnumerable.ToList())

            masterTable.Columns.AddIfNeeded("ContextGroupingOrder", GetType(Integer)).SetDefault(0)

            Dim coverageRows = masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "SampleCoverage")
            coverageRows.AsEnumerable.SetField("ContextGroupingOrder", Function(r) GetContextGroupingOrder(r))
        End Sub

        Public Sub AddSampleStationRatioContextData(ByRef masterTable As DataTable, locationId As Integer,
                                                    startDate As DateTime, endDate As DateTime,
                                                    dateBreakdown As ReportBreakdown) _
                                                    Implements ISampleStationReporter.AddSampleStationRatioContextData

            Dim sampleStationReportData = DalReport.GetBhpbioSampleStationReportData(locationId, startDate, endDate,
                                                                                     dateBreakdown.ToParameterString())

            For Each ratioGroup In sampleStationReportData.AsEnumerable.GroupBy(Function(r) $"{r.AsDate("DateFrom")}-{r.AsString("Grade_Id")}")
                Dim ratio = 0.0

                Dim sampleCount = ratioGroup.Sum(Function(r) r.AsInt("Sample_Count"))
                If sampleCount > 0 Then
                    ratio = ratioGroup.Sum(Function(r) r.AsDbl("Assayed") + r.AsDbl("Unassayed")) / sampleCount
                End If

                Dim representativeRow = ratioGroup.FirstOrDefault()
                AddSampleStationRowAsNonFactorRow(representativeRow, masterTable, String.Empty, ratio,
                                                  Math.Round(ratio, 0).ToString(), "SampleRatio", "SampleRatio")
            Next
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
                AddSampleStationRowAsNonFactorRow(representativeRow, masterTable, "#C0C0C0", totalUnsampled, "Unsampled", "SampleCoverage", "SampleCoverage")
            Next
        End Sub

        ''' <summary>
        ''' Convert a coverage row to a factor row (a.k.a. standard row) and add to the master table.
        ''' </summary>
        ''' <param name="dataRow">Row to convert.</param>
        ''' <param name="masterTable">Table to add converted row to.</param>
        ''' <param name="presentationColor">Color to display on the report. If null or empty, LocationName will be converted to
        '''                                 a color.</param>
        ''' <param name="tonnes">Tonnes to display on the report.</param>
        ''' <param name="contextGrouping">Field to group the context on.</param>
        ''' <param name="locationType">Location Type to assign.</param>
        ''' <param name="contextCategory">Category of the context.</param>
        Private Shared Sub AddSampleStationRowAsNonFactorRow(dataRow As DataRow, ByRef masterTable As DataTable,
                                                             presentationColor As String, tonnes As Double,
                                                             contextGrouping As String, locationType As String,
                                                             contextCategory As String)
            ' If *only* Coverage has been chosen, these rows won't exist in the master table.
            masterTable.Columns.AddIfNeeded("LocationName", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationType", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationColor", GetType(String)).SetDefault(String.Empty)

            Dim row = masterTable.AsEnumerable.First.CloneFactorRow(addToTable:=False)

            row("CalendarDate") = dataRow("DateFrom")
            row("DateFrom") = dataRow("DateFrom")
            row("DateTo") = dataRow("DateTo")
            row("DateText") = CType(dataRow("DateFrom"), DateTime).ToString("MMMM-yy") ' .AsDate breaks Re# *only* here. NFI why.

            row("LocationId") = dataRow("LocationId")
            row("LocationName") = dataRow("SampleStation")
            row("LocationType") = locationType

            row("ContextCategory") = contextCategory
            row("ContextGrouping") = contextGrouping
            row("ContextGroupingLabel") = contextGrouping
            row("PresentationColor") = IIf(String.IsNullOrEmpty(presentationColor), row.AsString("LocationName").AsColor, presentationColor)
            row("LocationColor") = DBNull.Value

            row("Attribute") = dataRow("Grade_Name")
            row("AttributeValue") = 0.0

            row("Type") = 1 ' this means a non-factor row
            row("Tonnes") = tonnes
            row("FactorGradeValueBottom") = dataRow("Grade_Value")
            row("FactorTonnesBottom") = tonnes

            masterTable.Rows.Add(row)
        End Sub
    End Class
End Namespace