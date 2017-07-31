Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IReport
        Inherits Core.Database.DalBaseObjects.IReport

        Function GetBhpbioPortBalance(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
         ByVal locationId As Int32) As DataTable

        Function GetBhpbioPortBlending(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
         ByVal locationId As Int32) As DataTable

        Function GetBhpbioShippingNomination(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
         ByVal locationId As Int32) As DataTable

        Function GetBhpbioWeightometerMovementSummaryForMonth(ByVal month As DateTime) As DataTable

    End Interface
End Namespace
