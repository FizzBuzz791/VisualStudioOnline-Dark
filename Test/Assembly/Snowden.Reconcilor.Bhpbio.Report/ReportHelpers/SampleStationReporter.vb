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

            For Each coverageRow As DataRow In sampleStationReportData.Rows
                AddContextRowAsNonFactorRow(coverageRow, masterTable, String.Empty, coverageRow.AsDbl("Assayed"),
                                            coverageRow.AsString("SampleStation"), "SampleCoverage", "SampleCoverage",
                                            coverageRow.AsString("SampleStation"), coverageRow.AsString("SampleStation"))
            Next

            AddUnsampledRows(sampleStationReportData.AsEnumerable, masterTable)
            AddPercentageSampledLabel(masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "SampleCoverage"))
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
                AddContextRowAsNonFactorRow(representativeRow, masterTable, "#1E7BFC", ratio, Math.Round(ratio, 0).ToString(),
                                            "SampleRatio", "SampleRatio", Math.Round(ratio, 0).ToString(),
                                            representativeRow.AsString("SampleStation"))
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

        Private Sub AddUnsampledRows(coverageRows As IEnumerable(Of DataRow), ByRef masterTable As DataTable)
            ' Group by period (month/quarter) to find the total unsampled for that "stack".
            For Each periodGroup In coverageRows.GroupBy(Function(r) $"{r.AsDate("DateFrom")}-{r.AsInt("Grade_Id")}")
                Dim totalUnsampled = periodGroup.Sum(Function(r) r.AsDbl("Unassayed"))
                ' Add a new row for each grade to show the unsampled
                Dim representativeRow = periodGroup.FirstOrDefault()
                AddContextRowAsNonFactorRow(representativeRow, masterTable, "#C0C0C0", totalUnsampled, "Unsampled",
                                            "SampleCoverage", "SampleCoverage", "Unsampled",
                                            representativeRow.AsString("SampleStation"))
            Next
        End Sub

        Private Shared Sub AddPercentageSampledLabel(dataRows As IEnumerable(Of DataRow))
            Dim sampleGroups = dataRows.GroupBy(Function(r) $"{r.AsString("Attribute")}-{r.AsDate("DateFrom"):yyyy-MM-dd}")
            ' Group by period (month/quarter) to find the total moved for that "stack".
            For Each sampleGroup In sampleGroups
                Dim totalTonnesMoved = sampleGroup.Sum(Function(r) r.AsDbl("Tonnes"))
                Dim totalTonnesSampled = sampleGroup.Where(Function(r) r.AsString("ContextGrouping") <> "Unsampled").Sum(Function(r) r.AsDbl("Tonnes"))
                Dim percentageSampled = Math.Round((totalTonnesSampled / totalTonnesMoved) * 100, 1)

                ' Add a new row with a transparent color to show the label.
                Dim labelRow = sampleGroup.First.CloneFactorRow(addToTable:=True)
                labelRow("Tonnes") = totalTonnesMoved * 0.1
                labelRow("FactorTonnesBottom") = totalTonnesMoved * 0.1

                labelRow("ContextGroupingLabel") = $"{percentageSampled}% Sampled"
                labelRow("ContextGrouping") = "SampledPercentage"
                labelRow("PresentationColor") = "Transparent"
            Next
        End Sub
    End Class
End Namespace