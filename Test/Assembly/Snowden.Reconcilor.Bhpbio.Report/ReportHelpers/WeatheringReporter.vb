Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class WeatheringReporter : Inherits Reporter : Implements IWeatheringReporter
        Public Sub AddWeatheringContextDataForF1OrF15(ByRef masterTable As DataTable, factorId As String, 
                                                      session As ReportSession, contextList As String(), 
                                                      dateBreakdown As ReportBreakdown, dateFrom As Date, dateTo As Date,
                                                      attributeList As String(), locationId As Integer) _
                                                      Implements IWeatheringReporter.AddWeatheringContextDataForF1OrF15

            ' Bit of a dirty hack, but there's no "nice" way to do this (there's no "roll-up" like with Strat).
            session.IncludeWeathering = True
            session.LowestStratigraphyLevel = 0 ' Need this to be off if it isn't already, otherwise results can be multiplied by the strat breakdown.
            session.GetCacheBlockModel().ClearCache() ' Must clear the cache so we don't get the same data that we just pulled (which doesn't have weathering breakdowns).
            Dim table = F2AnalysisReport.PrepareTable(factorId, session, locationId, contextList, dateBreakdown, dateFrom, 
                                                      dateTo, attributeList)

            ' Get all the "concrete"/factor rows. These have the data we need.
            Dim weatheringRows = table.Rows.Cast(Of DataRow).Where(Function (r)
                ' ReSharper disable RedundantParentheses
                Return (r.AsString("CalcId") = ModelGradeControl.CalculationId Or 
                        r.AsString("CalcId") = ModelGradeControlSTGM.CalculationId) And 
                        r.AsString(ColumnNames.WEATHERING) IsNot Nothing
                ' ReSharper restore RedundantParentheses
            End Function).ToList()

            ' Data is fixed, now add in the weathering context rows.
            For Each weatheringRow In weatheringRows
                AddContextRowAsNonFactorRow(weatheringRow, masterTable, weatheringRow.AsString(ColumnNames.WEATHERING_COLOR), 
                                            weatheringRow.AsDbl("Tonnes"), weatheringRow.AsString(ColumnNames.WEATHERING), 
                                            "Weathering", "Weathering", weatheringRow.AsString(ColumnNames.WEATHERING), 
                                            weatheringRow.AsString(ColumnNames.WEATHERING))
            Next
        End Sub

        Public Sub AddWeatheringContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, 
                                                     startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown, 
                                                     dalReport As ISqlDalReport, includeChildLocations As Boolean, 
                                                     includeLiveData As Boolean, includeApprovedData As Boolean,
                                                     attributeList As String()) _
                                                     Implements IWeatheringReporter.AddWeatheringContextDataForF2OrF3
            
            ' x: Ex-pit Direct To Crusher
            Dim xWeatheringData = dalReport.GetBhpbioReportDataActualDirectFeed(startDate, endDate, 
                                                                                dateBreakdown.ToParameterString(), locationId, 
                                                                                includeChildLocations, includeLiveData, 
                                                                                includeApprovedData, 0, True)

            ' z: Stockpile To Crusher (makes up the remainder of the F2/F3)
            Dim zData = dalReport.GetBhpbioReportDataActualStockpileToCrusher(startDate, endDate, 
                                                                              dateBreakdown.ToParameterString(), locationId, 
                                                                              includeChildLocations, includeLiveData, 
                                                                              includeApprovedData)
            Const SP_TO_CRUSHER_COLOR = "#CCCCCC"
            Dim contextData As New DataTable

            Dim tonnesData = xWeatheringData.Tables(0)
            ' Update some rows to fit the expected data better. Avoids having to mess with the stored proc and anything that
            ' might rely on it.
            tonnesData.Columns.Add("Grade_Name", GetType(String)).SetDefault("Tonnes")
            tonnesData.Columns.Add("Grade_Value", GetType(Double)).SetDefault(100)

            Dim zTonnes = zData.Tables(0)
            ' Update some rows to fit the expected data better. Avoids having to mess with the stored proc and anything that
            ' might rely on it.
            zTonnes.Columns.Add("Grade_Name", GetType(String)).SetDefault("Tonnes")
            zTonnes.Columns.Add("Grade_Value", GetType(Double)).SetDefault(100)
            zTonnes.Columns.Add(ColumnNames.WEATHERING, GetType(String)).SetDefault("SP to Crusher")
            zTonnes.Columns.Add(ColumnNames.WEATHERING_COLOR, GetType(String)).SetDefault(SP_TO_CRUSHER_COLOR)
            tonnesData.Merge(zTonnes)
            contextData.Merge(tonnesData)

            Dim gradesData = xWeatheringData.Tables(1)
            gradesData.Columns.Item("GradeName").ColumnName = "Grade_Name"
            gradesData.Columns.Item("GradeValue").ColumnName = "Grade_Value"
            gradesData.Columns.Add("Tonnes", GetType(Double))
            gradesData.Columns.Add(ColumnNames.DATE_FROM, GetType(DateTime))
            gradesData.Columns.Add(ColumnNames.DATE_TO, GetType(DateTime))

            Dim zGrades = zData.Tables(1)
            zGrades.Columns.Item("GradeName").ColumnName = "Grade_Name"
            zGrades.Columns.Item("GradeValue").ColumnName = "Grade_Value"
            zGrades.Columns.Add("Tonnes", GetType(Double))
            zGrades.Columns.Add(ColumnNames.DATE_FROM, GetType(DateTime))
            zGrades.Columns.Add(ColumnNames.DATE_TO, GetType(DateTime))
            zGrades.Columns.Add(ColumnNames.WEATHERING, GetType(String)).SetDefault("SP to Crusher")
            zGrades.Columns.Add(ColumnNames.WEATHERING_COLOR, GetType(String)).SetDefault(SP_TO_CRUSHER_COLOR)
            gradesData.Merge(zGrades)

            ' Need to do a bit of data massaging to get the tonnes sorted without messing with the stored proc results directly.
            For Each row As DataRow In gradesData.Rows
                Dim referenceRow = tonnesData.Rows.Cast(Of DataRow).SingleOrDefault(Function (r)
                    Return r.AsDate(ColumnNames.DATE_CAL).Equals(row.AsDate(ColumnNames.DATE_CAL)) _
                        And r.AsString(ColumnNames.PRODUCT_SIZE) = row.AsString(ColumnNames.PRODUCT_SIZE) _
                        And r.AsString(ColumnNames.WEATHERING) = row.AsString(ColumnNames.WEATHERING)
                End Function)

                row("Tonnes") = referenceRow.AsDbl("Tonnes")
                row(ColumnNames.DATE_FROM) = referenceRow.AsDate(ColumnNames.DATE_FROM)
                row(ColumnNames.DATE_TO) = referenceRow.AsDate(ColumnNames.DATE_TO)
            Next
            contextData.Merge(gradesData)

            For Each row in contextData.Rows.Cast(Of DataRow).Where(
                Function (r)
                    Return attributeList.Contains(r.AsString("Grade_Name")) _
                        And r.AsString(ColumnNames.PRODUCT_SIZE) = CalculationConstants.PRODUCT_SIZE_TOTAL
                End Function)

                AddContextRowAsNonFactorRow(row, masterTable, row.AsString(ColumnNames.WEATHERING_COLOR), row.AsDbl("Tonnes"), 
                                            row.AsString(ColumnNames.WEATHERING), "Weathering", "Weathering",
                                            row.AsString(ColumnNames.WEATHERING), row.AsString(ColumnNames.WEATHERING))
            Next

            masterTable.Columns.AddIfNeeded("ContextGroupingOrder", GetType(Integer)).SetDefault(0)
            Dim stratRows = masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "Weathering")
            stratRows.AsEnumerable.SetField("ContextGroupingOrder", Function(r) GetContextGroupingOrder(r))
        End Sub
    End Class
End NameSpace