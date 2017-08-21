Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface ISampleStationReporter : Inherits IReporter
        Sub AddSampleStationCoverageContextData(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                endDate As DateTime, dateBreakdown As ReportBreakdown, dalReport As SqlDalReport)
        Sub AddSampleStationRatioContextData()
    End Interface
End Namespace