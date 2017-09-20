Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Interface IStratigraphyReporter : Inherits IReporter
        Sub AddStratigraphyContextDataForF1OrF15(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                 endDate As DateTime, dateBreakdown As ReportBreakdown)
        Sub AddStratigraphyContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, startDate As DateTime,
                                                endDate As DateTime, dateBreakdown As ReportBreakdown, 
                                                dalReport As ISqlDalReport, includeChildLocations As Boolean, 
                                                includeLiveData As Boolean, includeApprovedData As Boolean, 
                                                attributeList As String())
    End Interface
End NameSpace