Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
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
                        r.AsIntN(ColumnNames.WEATHERING) IsNot Nothing
                ' ReSharper restore RedundantParentheses
            End Function).ToList()

            ' Data is fixed, now add in the weathering context rows.
            For Each weatheringRow In weatheringRows
                AddContextRowAsNonFactorRow(weatheringRow, masterTable, String.Empty, weatheringRow.AsDbl("Tonnes"),
                                            weatheringRow.AsString(ColumnNames.WEATHERING), "Weathering", "Weathering",
                                            weatheringRow.AsString(ColumnNames.WEATHERING), 
                                            weatheringRow.AsString(ColumnNames.WEATHERING))
            Next
        End Sub

        Public Sub AddWeatheringContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, 
                                                     startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown) _
                                                     Implements IWeatheringReporter.AddWeatheringContextDataForF2OrF3
            Throw New NotImplementedException
        End Sub
    End Class
End NameSpace