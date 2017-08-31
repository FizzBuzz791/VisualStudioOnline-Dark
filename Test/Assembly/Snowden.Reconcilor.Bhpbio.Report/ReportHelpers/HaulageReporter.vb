Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class HaulageReporter : Inherits Reporter : Implements IHaulageReporter
        Private ReadOnly Property DalReport As ISqlDalReport
        Private ReadOnly Property DalUtility As IUtility

        Sub New(dalReport As ISqlDalReport, dalUtility As IUtility)
            Me.DalReport = dalReport
            Me.DalUtility = dalUtility
        End Sub

        Public Sub AddHaulageContextData(ByRef masterTable As DataTable, locationId As Integer, startDate As Date,
                                         endDate As Date, dateBreakdown As ReportBreakdown) _
                                         Implements IHaulageReporter.AddHaulageContextData

            Dim haulageData = DalReport.GetBhpbioHaulageMovementsToCrusher(locationId, startDate, endDate,
                                                                           dateBreakdown.ToParameterString())

            ' Add this to the main table as haulage context data
            For Each haulageRow As DataRow In haulageData.Rows
                AddContextRowAsNonFactorRow(haulageRow, masterTable, String.Empty, haulageRow.AsDbl("TotalTonnes"),
                                            haulageRow.AsString("LocationName"), haulageRow.AsString("LocationType"),
                                            "HaulageContext", haulageRow.AsString("LocationName"),
                                            haulageRow.AsString("LocationName"))
            Next

            Dim haulageRows = masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "HaulageContext")

            ' Make sure the colors are there for the new locations
            ReportColour.AddLocationColor(DalUtility, haulageRows.Where(Function(r) r.AsString("LocationType") = "Pit"))
            haulageRows.Where(Function(r) r.HasValue("LocationColor")).SetField("PresentationColor", Function(r) r.AsString("LocationColor"))

            CombineSmallSamplesIntoOtherCategory(haulageRows)
            SeedLegend(haulageRows)

            masterTable.Columns.AddIfNeeded("ContextGroupingOrder", GetType(Integer)).SetDefault(0)
            haulageRows.AsEnumerable.SetField("ContextGroupingOrder", Function(r) GetContextGroupingOrder(r))
        End Sub

        ' There is a problem with the SSRS legend that requires each series to appear in the first category on the chart.
        ' This method finds all groups and creates a row in the first section with zero tonnes to 'seed' the legend
        ' so that the colors will be rendered properly.
        Private Shared Sub SeedLegend(haulageRows As IEnumerable(Of DataRow))
            ' Get every context grouping label in the data set and make a copy of it in the first month of the dataset
            Dim haulageRowsFiltered = haulageRows.Where(Function(r) r.AsString("ContextGrouping") <> "StockpileContext").ToList()
            Dim contextLabels = haulageRowsFiltered.GroupBy(Function(r) $"{r.AsString("ContextGrouping")}-{r.AsString("ContextGroupingLabel")}-{r.AsString("Attribute")}")

            Dim firstMonth = haulageRowsFiltered.Min(Function(r) r.AsDate("DateFrom"))
            Dim firstMonthRow = haulageRowsFiltered.FirstOrDefault(Function(r) r.AsDate("DateFrom") = firstMonth)

            For Each labelGroup In contextLabels
                Dim firstRow = labelGroup.OrderBy(Function(r) r.AsDate("DateFrom")).FirstOrDefault()

                If firstRow.AsDate("DateFrom") = firstMonth Then
                    ' We already have this one
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

        Private Shared Sub CombineSmallSamplesIntoOtherCategory(haulageRows As IEnumerable(Of DataRow))
            Dim haulageGroups = haulageRows.GroupBy(Function(r) $"{r.AsString("Attribute")}-{r.AsDate("DateFrom"):yyyy-MM-dd}").ToList()

            ' Get the total tonnes in each group (stockpiles and pits), then loop through each stockpile in the group. Of the % 
            ' of the total tonnes is less than the threshold then we push it to other.
            For Each group In haulageGroups
                Dim totalTonnes = group.Sum(Function(r) r.AsDblN("Tonnes"))

                For Each row In group.Where(Function(r) r.AsString("LocationType") = "Stockpile")
                    If row.AsDblN("Tonnes") / totalTonnes < 0.05 Then
                        row("ContextGrouping") = "Other SPs <5%"
                        row("ContextGroupingLabel") = "Other SPs"
                        row("PresentationColor") = "#C0C0C0"
                    End If
                Next

                ' Above the stockpile bars, show a label with the percent total stockpiles
                Dim stockpileRecords = group.Where(Function(r) r.AsString("LocationType") = "Stockpile").ToList()
                Dim stockpileTotalTonnes = stockpileRecords.Sum(Function(r) r.AsDblN("Tonnes"))
                Dim stockpileProportion = stockpileTotalTonnes / totalTonnes

                If stockpileRecords.Any Then
                    Dim labelRecord = stockpileRecords.First.CloneFactorRow(addToTable:=True)
                    labelRecord("Tonnes") = totalTonnes * 0.05
                    labelRecord("FactorTonnesBottom") = totalTonnes * 0.05

                    labelRecord("ContextGroupingLabel") = $"{(stockpileProportion.Value * 100):N1}% from SPs"
                    labelRecord("ContextGrouping") = "StockpileContext"
                    labelRecord("PresentationColor") = "Transparent"
                End If
            Next
        End Sub
    End Class
End Namespace