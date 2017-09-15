Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Interface ISqlDalReport : Inherits IReport
        Function GetBhpbioSampleStationReportData(locationId As Integer, startDate As Date, endDate As Date,
                                                  dateBreakdown As String) As DataTable
        Function GetBhpbioHaulageMovementsToCrusher(locationId As Integer, startDate As DateTime, endDate As DateTime,
                                                    dateBreakdown As String) As DataTable
        Function GetBhpbioReportDataActualDirectFeed(startDate As Date, endDate As Date, dateBreakdown As String, 
                                                     locationId As Int32, childLocations As Boolean, 
                                                     includeLiveData As Boolean, includeApprovedData As Boolean,
                                                     Optional lowestStratLevel As Integer = 0) As DataSet
        Function GetBhpbioReportDataActualStockpileToCrusher(startDate As Date, endDate As Date, dateBreakdown As String, 
                                                             locationId As Int32, childLocations As Boolean, 
                                                             includeLiveData As Boolean, includeApprovedData As Boolean) _
                                                             As DataSet
    End Interface
End Namespace