Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IStockpile
        Inherits Core.Database.DalBaseObjects.IStockpile

        ''' <summary>
        ''' Returns a list of stockpile records.
        ''' </summary>
        ''' <param name="groupByStockpileGroups">The group by stockpile groups.</param>
        ''' <param name="stockpileGroupId">The stockpile group id. Max length of 31.</param>
        ''' <param name="stockpileName">Name of the stockpile. Max length of 31.</param>
        ''' <param name="isVisible">True or False.</param>
        ''' <param name="materialTypeId">The material type id.</param>
        ''' <param name="sortType">Type of the sort.</param>
        ''' <param name="includeGrades">True or False.</param>
        ''' <param name="startDate">Filter on Stockpile Build Start Date</param>
        ''' <param name="endDate">Filter on Stockpile Build Start Date</param>
        ''' <param name="gradeVisibility">Determines what grades to show, null for all, true for visible, false for invisible.</param>
        ''' <param name="transactionStartDate">Includes all transactions from this date</param>
        ''' <param name="transactionEndDate">Filters the stockpile list down to stockpiles with transactions before/including this date, and after transaction start date</param>
        ''' <returns></returns>
        Overloads Function GetStockpileList(ByVal groupByStockpileGroups As Int16, _
         ByVal stockpileGroupId As String, _
         ByVal stockpileName As String, _
         ByVal isVisible As Int16, _
         ByVal materialTypeId As Int32, _
         ByVal sortType As Int32, _
         ByVal includeGrades As Int16, _
         ByVal startDate As DateTime, _
         ByVal endDate As DateTime, _
         ByVal locationId As Int32, _
         ByVal recordLimit As Int32, _
         ByVal gradeVisibility As Int16, _
         ByVal transactionStartDate As DateTime, _
         ByVal transactionEndDate As DateTime) As DataTable

        Overloads Function GetStockpileListByGroups(ByVal groupByStockpileGroups As Int16, _
        ByVal stockpileGroupId As String, _
        ByVal stockpileName As String, _
        ByVal isVisible As Int16, _
        ByVal materialTypeId As Int32, _
        ByVal sortType As Int32, _
        ByVal includeGrades As Int16, _
        ByVal startDate As DateTime, _
        ByVal endDate As DateTime, _
        ByVal locationId As Int32, _
        ByVal recordLimit As Int32, _
        ByVal gradeVisibility As Int16, _
        ByVal transactionStartDate As DateTime, _
        ByVal transactionEndDate As DateTime, _
        ByVal stockpileGroupsXml As String, _
        ByVal includeLocationsBelow As Boolean) As DataTable

        Sub AddBhpbioStockpileDeletionState(ByVal stockpileName As String)

        Sub ClearBhpbioStockpileDeletionState(ByVal stockpileName As String, ByRef previousDeletionState As Boolean, ByRef matchingStockpileId As Integer)

    End Interface
End Namespace