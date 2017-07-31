Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IHaulage
        Inherits Snowden.Reconcilor.Core.Database.DalBaseObjects.IHaulage

        Sub AddOrUpdateBhpbioHaulageLumpFinesGrade( _
            ByVal haulageRawId As Int32, _
            ByVal gradeId As Int16?, _
            ByVal lumpValue As Single?, _
            ByVal finesValue As Single?)

        Function GetBhpbioHaulageCorrectionListFilter(ByVal filterType As String, ByVal locationId As Int32) As DataTable

        Function GetBhpbioHaulageCorrectionList(ByVal filterSource As String, _
         ByVal filterDestination As String, _
         ByVal filterDescription As String, _
         ByVal top As Int16, _
         ByVal recordLimit As Int32, _
            ByVal locationId As Int32) As DataTable

        Function GetBhpbioHaulageErrorCount(ByVal locationId As Int32) As Int32

        Function GetBhpbioHaulageErrorCount(ByVal locationId As Int32, month As DateTime) As Int32

        Function GetBhpbioHaulageManagementListFilter(ByVal filterType As String, ByVal locationId As Int32) As DataTable

        Function GetBhpbioHaulageManagementList(ByVal locationId As Int32, ByVal filterStartDate As DateTime, _
         ByVal filterEndDate As DateTime, _
         ByVal filterStartShift As String, _
         ByVal filterEndShift As String, _
         ByVal filterSource As String, _
         ByVal filterDestination As String, _
         ByVal filterTruck As String, _
         ByVal showHaulageWithApprovedChild As Int16, _
         ByVal top As Int16, _
         ByRef countDestinationCrusher As Int32, _
         ByRef countDestinationMill As Int32, _
         ByRef countDestinationStockpile As Int32, _
         ByRef countRecords As Int32, _
         ByRef countSourceDigblock As Int32, _
         ByRef countSourceMill As Int32, _
         ByRef countSourceStockpile As Int32, _
         ByRef sumTonnes As Double, _
         ByRef recordLimit As Int32) As DataTable

    End Interface
End Namespace
