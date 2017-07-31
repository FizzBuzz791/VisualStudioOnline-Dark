Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IPortImport
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Function AddBhpbioShippingNominationItem(ByVal nominationKey As Int32, ByVal itemNo As Int32, _
         ByVal officialFinishTime As DateTime, ByVal lastAuthorisedDate As DateTime, ByVal vesselName As String, _
         ByVal customerNo As Int32, ByVal customerName As String, ByVal shippedProduct As String, _
         ByVal shippedProductSize As String, ByVal coa As Nullable(Of DateTime), _
         ByVal undersize As Nullable(Of Double), ByVal oversize As Nullable(Of Double)) As Int32

        Sub UpdateBhpbioShippingNominationItem(ByVal bhpbioShippingNominationItemId As Int32, _
         ByVal nominationKey As Int32, ByVal itemNo As Int32, _
         ByVal officialFinishTime As DateTime, ByVal lastAuthorisedDate As DateTime, ByVal vesselName As String, _
         ByVal customerNo As Int32, ByVal customerName As String, ByVal shippedProduct As String, _
         ByVal shippedProductSize As String, ByVal coa As Nullable(Of DateTime), _
         ByVal undersize As Nullable(Of Double), ByVal oversize As Nullable(Of Double))

        Sub DeleteBhpbioShippingNominationItem(ByVal bhpbioShippingNominationItemId As Int32)

        Function AddBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemId As Int32, _
         ByVal hubLocationId As Int32, ByVal hubProduct As String, ByVal hubProductSize As String, _
         ByVal tonnes As Double) As Int32

        Sub UpdateBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemParcelId As Int32, _
         ByVal bhpbioShippingNominationItemId As Int32, ByVal hubLocationId As Int32, _
         ByVal hubProduct As String, ByVal hubProductSize As String, _
         ByVal tonnes As Double)

        Sub DeleteBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemParcelId As Int32)

        Sub AddOrUpdateBhpbioShippingNominationItemParcelGrade(ByVal bhpbioShippingNominationItemParcelId As Int32, _
         ByVal gradeId As Int16, ByVal gradeValue As Single)

        Function AddBhpbioPortBlending(ByVal sourceHubLocationId As Int32, ByVal destinationHubLocationId As Int32, _
            ByVal sourceProduct As String, ByVal sourceProductSize As String, ByVal destinationProduct As String, ByVal destinationProductSize As String, _
            ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal loadSiteLocationId As Int32, ByVal tonnes As Double) As Int32

        Sub AddUpdateDeleteBhpbioPortBlendingGrade(ByVal bhpbioPortBlendingId As Int32, _
         ByVal gradeId As Int16, ByVal gradeValue As Single)

        Sub UpdateBhpbioPortBlending(ByVal bhpbioPortBlendingId As Int32, ByVal sourceProductSize As String, _
            ByVal destinationProductSize As String, ByVal tonnes As Double)

        Sub DeleteBhpbioPortBlending(ByVal bhpbioPortBlendingId As Int32)

        Function AddBhpbioPortBalances(ByVal hubLocationId As Int32, _
            ByVal balanceDate As DateTime, ByVal tonnes As Double, ByVal product As String, ByVal productSize As String) As Int32

        Sub UpdateBhpbioPortBalances(ByVal bhpbioPortBalanceId As Int32, ByVal tonnes As Double, _
            ByVal product As String, ByVal productSize As String)

        Sub DeleteBhpbioPortBalances(ByVal bhpbioPortBalanceId As Int32)

        Sub AddOrUpdateBhpbioPortBalanceGrade(ByVal bhpbioPortBalanceId As Int32, ByVal gradeId As Int16, ByVal gradeValue As Double)

        Function GetBhpbioShippingNomination(ByVal nominationId As Int32) As DataTable
    End Interface
End Namespace
