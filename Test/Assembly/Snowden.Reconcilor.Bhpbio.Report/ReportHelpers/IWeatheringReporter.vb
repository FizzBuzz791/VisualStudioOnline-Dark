Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface IWeatheringReporter : Inherits IReporter
        Sub AddWeatheringContextDataForF1OrF15(ByRef masterTable As DataTable, factorId As String, session As ReportSession, 
                                               contextList As String(), dateBreakdown As ReportBreakdown, dateFrom As Date, 
                                               dateTo As Date, attributeList As String(), locationId As Integer)
        Sub AddWeatheringContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                endDate As DateTime, dateBreakdown As ReportBreakdown)
    End Interface
End NameSpace