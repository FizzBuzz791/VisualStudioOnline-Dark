Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface IWeatheringReporter : Inherits IReporter
        Sub AddWeatheringContextDataForF1OrF15(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                 endDate As DateTime, dateBreakdown As ReportBreakdown)
        Sub AddWeatheringContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                endDate As DateTime, dateBreakdown As ReportBreakdown)
    End Interface
End NameSpace