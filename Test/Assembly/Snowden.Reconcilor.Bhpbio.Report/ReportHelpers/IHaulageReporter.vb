Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface IHaulageReporter : Inherits IReporter
        Sub AddHaulageContextData(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                  endDate As DateTime, dateBreakdown As ReportBreakdown)
    End Interface
End Namespace