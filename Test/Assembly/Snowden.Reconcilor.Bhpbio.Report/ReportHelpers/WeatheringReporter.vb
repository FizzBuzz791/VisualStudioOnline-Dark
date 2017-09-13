Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class WeatheringReporter : Inherits Reporter : Implements IWeatheringReporter
        Public Sub AddWeatheringContextDataForF1OrF15(ByRef masterTable As DataTable, locationId As Integer, 
                                                      startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown) _
                                                      Implements IWeatheringReporter.AddWeatheringContextDataForF1OrF15
            Throw New NotImplementedException
        End Sub

        Public Sub AddWeatheringContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, 
                                                     startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown) _
                                                     Implements IWeatheringReporter.AddWeatheringContextDataForF2OrF3
            Throw New NotImplementedException
        End Sub
    End Class
End NameSpace