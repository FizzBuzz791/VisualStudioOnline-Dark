Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Interface ISqlDalReport : Inherits IReport
        Function GetBhpbioSampleStationReportData(locationId As Integer, startDate As Date, endDate As Date,
                                                  dateBreakdown As String) As DataTable
        Function GetBhpbioHaulageMovementsToCrusher(locationId As Integer, startDate As DateTime, endDate As DateTime,
                                                    dateBreakdown As String) As DataTable
    End Interface
End Namespace