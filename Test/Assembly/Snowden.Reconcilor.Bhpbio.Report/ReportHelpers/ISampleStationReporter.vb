Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface ISampleStationReporter : Inherits IReporter
        Sub AddSampleStationCoverageContextData(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                endDate As DateTime, dateBreakdown As ReportBreakdown)
        Sub AddSampleStationRatioContextData(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                             endDate As DateTime, dateBreakdown As ReportBreakdown)
    End Interface
End Namespace