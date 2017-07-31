Namespace DalBaseObjects
    Public Interface IApproval
        Inherits Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Sub ApproveBhpbioApprovalDigblock(ByVal digblockId As String, ByVal approvalMonth As Date, ByVal userId As Int32)

        Function GetBhpbioApprovalDigblockList(ByVal locationId As Int32, ByVal filterMonth As DateTime, ByVal recordLimit As Int32) As DataTable

        Function GetBhpbioReportDataTags(ByVal tagGroupId As String, ByVal locationTypeId As Integer) As DataTable

        Function GetBhpbioReportDataTagsDetailed() As DataTable

        Function IsBhpbioApprovalBlock(ByVal digblockId As String) As Boolean

        Function IsBhpbioApprovalBlockDate(ByVal digblockId As String, ByVal month As Date) As Boolean

        Function IsBhpbioApprovalLocation(ByVal locationId As Int32, ByVal month As Date, ByVal tagId As String, ByVal tagGroupId As String) As Boolean

        Function ResolveBhpbioLocationByName(ByVal locationName As String) As Integer?

        Sub UnapproveBhpbioApprovalDigblock(ByVal digblockId As String, ByVal approvalMonth As Date)

        Sub ApproveBhpbioApprovalData(ByVal tagId As String, ByVal locationId As Int32, ByVal approvalMonth As Date, ByVal userId As Int32)

        Sub UnapproveBhpbioApprovalData(ByVal tagId As String, ByVal locationId As Int32, ByVal approvalMonth As Date)

        Function GetBhpbioApprovalData(ByVal filterMonth As DateTime) As DataSet

        Function GetBhpbioApprovalDataRaw(ByVal filterMonth As DateTime, ByVal ignoreUsers As Boolean) As DataTable

        Function GetBhpbioApprovalOtherMaterial(ByVal locationId As Int32, ByVal filterMonth As DateTime, ByVal includeChildren As Boolean) As DataTable

        Function IsBhpbioApprovalBlockLocationDate(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        Function IsBhpbioApprovalAllBlockLocationDate(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        Function IsBhpbioApprovalPitMovedDate(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        Function IsBhpbioApprovalOtherMovementDate(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        Function IsBhpbioAllF1Approved(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        Function IsAllBhpbioOtherMovementsApproved(ByVal locationId As Int32?, ByVal month As Date) As Boolean

        ''' <summary>
        ''' Get a datatable of outliers for a set of criteria
        ''' </summary>
        ''' <param name="analysisGroup">An analysis group to be matched (if any)</param>
        ''' <param name="startDate">start date from which to find outliers</param>
        ''' <param name="endDate">end date up to which to find outliers</param>
        ''' <param name="locationId">location Id to find outliers for</param>
        ''' <param name="productSize">product size (or null for any) to find outliers for</param>
        ''' <param name="attribute">an attribute to be matched</param>
        ''' <param name="minimumDeviation">the minimum deviation in terms of standard deviations to filter outliers</param>
        ''' <param name="includeDirectSubLocations">if true, outliers on direct sub-locations will be included</param>
        ''' <param name="includeAllSubLocations">if true, outliers on all sub-locations will be included</param>
        ''' <param name="excludeTotalMaterialDuplicates">Exclude total material outliers that are effectively duplicates of material type specific outliers</param>
        ''' <returns>A datatable with outlier results</returns>
        Function GetBhpbioOutliersForLocation(ByVal analysisGroup As String, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal locationId As Integer, ByVal productSize As String, ByVal attribute As String, ByVal minimumDeviation As Decimal, ByVal includeDirectSubLocations As Boolean, ByVal includeAllSubLocations As Boolean, ByVal excludeTotalMaterialDuplicates As Boolean, Optional ByVal includeAllPoints As Boolean = False) As DataTable

        ''' <summary>
        ''' Get a count of outliers by analysis group for a given location 
        ''' </summary>
        ''' <param name="startDate">start date from which to find outliers</param>
        ''' <param name="endDate">end date up to which to find outliers</param>
        ''' <param name="locationId">location Id to find outliers for</param>
        ''' <param name="productSize">product size (or null for any) to find outliers for</param>
        ''' <param name="attribute">attribute representing (0 for tonnes, a grade Id, or Nothing for all)</param>
        ''' <param name="minimumDeviation">the minimum deviation in terms of standard deviations to filter outliers</param>
        ''' <param name="includeDirectSubLocations">if true, outliers on direct sub-locations will be included</param>
        ''' <param name="includeAllSubLocations">if true, outliers on all sub-locations will be included</param>
        ''' <returns>A DataTable returning a record for each analysis group along with a count of matched outliers</returns>
        Function GetBhpbioOutlierCountByAnalysisGroupForLocation(ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal locationId As Integer, ByVal productSize As String, ByVal attribute As String, ByVal minimumDeviation As Decimal, ByVal includeDirectSubLocations As Boolean, ByVal includeAllSubLocations As Boolean) As DataTable

        ''' <summary>
        ''' Get a a set of points for a series within a date range
        ''' </summary>
        ''' <param name="seriesId">Id of the series to return outlier information for</param>
        ''' <param name="dateFrom">start date from which points are to be returned</param>
        ''' <param name="dateTo">end date to which points are to be returend</param>
        ''' <returns>A datatable with series points</returns>
        Function GetBhpbioOutlierAnalysisPoints(ByVal seriesId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As DataTable

        ''' <summary>
        ''' Get attributes for the outlier series
        ''' </summary>
        ''' <param name="seriesId">Id of the series to return outlier attributes for</param>
        ''' <returns>A datatable with attributes</returns>
        Function GetBhpbioOutlierAnalysisSeriesAttributes(ByVal seriesId As Integer) As DataTable

        Function EnqueueBhpbioBulkApproval(approval As Boolean, userId As Integer, locationId As Integer, monthFrom As DateTime, monthTo As DateTime, locationTypeFrom As Integer, locationTypeTo As Integer, isBulk As Boolean) As Integer

        Function GetBhpbioQueuedBulkApproval() As DataTable

        Sub StartBhpbioBulkApproval(bulkApprovalId As Integer, operationType As Boolean, userId As Integer, locationId As Integer, monthFrom As DateTime, monthTo As DateTime, locationTypeFrom As Integer, locationTypeTo As Integer)

        Function GetLocationTypeId(description As String) As Integer

        Function GetBhpbioPendingApprovalId(userId As Integer, locationId As Integer) As Integer?

        Function BhpbioGetApprovalProgress(approvalId As Integer) As DataTable

        Function GetBhpbioApprovalSummary(month As DateTime, Optional includeInactive As Boolean = False) As DataTable

        Function GetBhpbioSiblingLocations(locationId As Integer, locationDate As Date) As DataTable

        Function GetBhpbioLocationTypeAndApprovalStatus(locationId As Integer, month As DateTime) As DataTable

        Function GetBhpbioUngroupedStockpileCount(locationId As Integer, month As DateTime) As Integer

    End Interface
End Namespace