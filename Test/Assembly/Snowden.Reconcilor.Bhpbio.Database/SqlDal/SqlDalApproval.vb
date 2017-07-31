Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.SqlDataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalApproval
        Inherits SqlDalBase
        Implements IApproval

#Region " Constructors "
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(connectionString As String)
            MyBase.New(connectionString)
        End Sub

        Public Sub New(databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
        End Sub

        Public Sub New(dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        Private Const LONG_TIMEOUT_SECONDS As Int32 = 3600 ' override timeout used for long running operations

        Public Function GetBhpbioReportDataTags(tagGroupId As String, locationTypeId As Integer) As DataTable Implements IApproval.GetBhpbioReportDataTags
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportDataTags"
                With .ParameterCollection
                    .Clear()
                    .Add("@iTagGroupId", CommandDataType.VarChar, CommandDirection.Input, tagGroupId)
                    .Add("@iLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeId)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioReportDataTagsDetailed() As DataTable Implements IApproval.GetBhpbioReportDataTagsDetailed
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportDataTagsDetailed"
                With .ParameterCollection
                    .Clear()
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioApprovalDigblockList(locationId As Int32, filterMonth As Date, recordLimit As Int32) As DataTable _
            Implements IApproval.GetBhpbioApprovalDigblockList

            With DataAccess
                .CommandText = "dbo.GetBhpbioApprovalDigblockList"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iMonthFilter", CommandDataType.DateTime, CommandDirection.Input, filterMonth)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Sub ApproveBhpbioApprovalDigblock(digblockId As String, approvalMonth As Date, userId As Int32) _
            Implements IApproval.ApproveBhpbioApprovalDigblock

            With DataAccess
                .CommandText = "dbo.ApproveBhpbioApprovalDigblock"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@iApprovalMonth", CommandDataType.DateTime, CommandDirection.Input, approvalMonth)
                    .Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function IsBhpbioApprovalBlock(digblockId As String) As Boolean Implements IApproval.IsBhpbioApprovalBlock
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalBlock"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@oIsApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oIsApproved").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalBlockDate(digblockId As String, month As Date) As Boolean Implements IApproval.IsBhpbioApprovalBlockDate
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalBlockDate"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oIsApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oIsApproved").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalBlockLocationDate(locationId As Int32?, month As Date) As Boolean Implements IApproval.IsBhpbioApprovalBlockLocationDate
            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalBlockLocationDate"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oAllApproved").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalAllBlockLocationDate(locationId As Int32?, month As Date) As Boolean _
            Implements IApproval.IsBhpbioApprovalAllBlockLocationDate

            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalAllBlockLocationDate"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oAllApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oAllApproved").Value)
            End With
        End Function

        Public Function IsBhpbioAllF1Approved(locationId As Int32?, month As Date) As Boolean Implements IApproval.IsBhpbioAllF1Approved
            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioAllF1Approved"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oAllApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oAllApproved").Value)
            End With
        End Function

        Public Function IsBhpbioAllOtherMovementsApproved(locationId As Int32?, month As Date) As Boolean Implements IApproval.IsAllBhpbioOtherMovementsApproved
            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioAllOtherMovementsApproved"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oAllApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oAllApproved").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalPitMovedDate(locationId As Int32?, month As Date) As Boolean Implements IApproval.IsBhpbioApprovalPitMovedDate
            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalPitMovedDate"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oMovementsExist", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oMovementsExist").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalOtherMovementDate(locationId As Int32?, month As Date) As Boolean Implements IApproval.IsBhpbioApprovalOtherMovementDate
            Dim location As Int32
            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalOtherMovementDate"

                If locationId.HasValue Then
                    location = locationId.Value
                Else
                    location = DoNotSetValues.Int32
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@oMovementsExist", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oMovementsExist").Value)
            End With
        End Function

        Public Function IsBhpbioApprovalLocation(locationId As Int32, month As Date, tagId As String, tagGroupId As String) As Boolean _
            Implements IApproval.IsBhpbioApprovalLocation

            If tagId Is Nothing Then
                tagId = NullValues.String
            End If

            If tagGroupId Is Nothing Then
                tagGroupId = NullValues.String
            End If

            With DataAccess
                .CommandText = "dbo.IsBhpbioApprovalLocation"
                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, tagId)
                    .Add("@iTagGroupId", CommandDataType.VarChar, CommandDirection.Input, tagGroupId)
                    .Add("@oIsApproved", CommandDataType.Bit, CommandDirection.Output, -1)
                End With
                .ExecuteNonQuery()
                Return (Convert.ToBoolean(.ParameterCollection.Item("@oIsApproved").Value))
            End With
        End Function

        Public Function ResolveBhpbioLocationByName(locationName As String) As Integer? Implements IApproval.ResolveBhpbioLocationByName
            With DataAccess
                .CommandText = "dbo.ResolveBhpbioLocationByName"
                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationName", CommandDataType.VarChar, CommandDirection.Input, locationName)
                    .Add("@oLocationId", CommandDataType.Int, CommandDirection.Output, -1)
                End With
                .ExecuteNonQuery()
                If .ParameterCollection.Item("@oLocationId").Value Is DBNull.Value Then
                    Return Nothing
                Else
                    Return (Convert.ToInt32(.ParameterCollection.Item("@oLocationId").Value))
                End If
            End With
        End Function

        Public Sub UnapproveBhpbioApprovalDigblock(digblockId As String, approvalMonth As Date) Implements IApproval.UnapproveBhpbioApprovalDigblock
            With DataAccess
                .CommandText = "dbo.UnapproveBhpbioApprovalDigblock"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@iApprovalMonth", CommandDataType.DateTime, CommandDirection.Input, approvalMonth)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub ApproveBhpbioApprovalData(tagId As String, locationId As Int32, approvalMonth As Date, userId As Int32) _
            Implements IApproval.ApproveBhpbioApprovalData

            With DataAccess
                .CommandText = "dbo.ApproveBhpbioApprovalData"

                With .ParameterCollection
                    .Clear()

                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, 63, tagId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iApprovalMonth", CommandDataType.DateTime, CommandDirection.Input, approvalMonth)
                    .Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub UnapproveBhpbioApprovalData(tagId As String, locationId As Int32, approvalMonth As Date) Implements IApproval.UnapproveBhpbioApprovalData
            With DataAccess
                .CommandText = "dbo.UnapproveBhpbioApprovalData"

                With .ParameterCollection
                    .Clear()

                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, 63, tagId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iApprovalMonth", CommandDataType.DateTime, CommandDirection.Input, approvalMonth)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioApprovalData(filterMonth As Date) As DataSet Implements IApproval.GetBhpbioApprovalData
            With DataAccess
                .CommandText = "dbo.GetBhpbioApprovalData"

                With .ParameterCollection
                    .Clear()
                    .Add("@iMonthFilter", CommandDataType.DateTime, CommandDirection.Input, filterMonth)
                End With

                Dim ds As DataSet = .ExecuteDataSet

                If ds.Tables.Count > 0 Then
                    ds.Tables(0).TableName = "Approval"
                End If

                If ds.Tables.Count > 1 Then
                    ds.Tables(1).TableName = "SignOff"
                End If
                Return ds
            End With
        End Function

        Public Function GetBhpbioApprovalOtherMaterial(locationId As Integer, filterMonth As Date, includeChildren As Boolean) As DataTable _
            Implements IApproval.GetBhpbioApprovalOtherMaterial

            With DataAccess
                .CommandText = "dbo.GetBhpbioApprovalOtherMaterial"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iMonthFilter", CommandDataType.DateTime, CommandDirection.Input, filterMonth)
                    .Add("@iChildLocations", CommandDataType.Bit, CommandDirection.Input, includeChildren)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioApprovalDataRaw(filterMonth As Date, ignoreUsers As Boolean) As DataTable Implements IApproval.GetBhpbioApprovalDataRaw
            With DataAccess
                .CommandText = "dbo.GetBhpbioApprovalDataRaw"

                With .ParameterCollection
                    .Clear()
                    .Add("@iMonthFilter", CommandDataType.DateTime, CommandDirection.Input, filterMonth)
                    .Add("@iIgnoreUsers", CommandDataType.Bit, CommandDirection.Input, ignoreUsers)
                End With

                Return .ExecuteDataTable
            End With
        End Function

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
        Public Function GetBhpbioOutliersForLocation(analysisGroup As String, startDate As DateTime, endDate As DateTime, locationId As Integer,
            productSize As String, attribute As String, minimumDeviation As Decimal, includeDirectSubLocations As Boolean, includeAllSubLocations As Boolean,
            excludeTotalMaterialDuplicates As Boolean, Optional ByVal includeAllPoints As Boolean = False) As DataTable Implements IApproval.GetBhpbioOutliersForLocation

            With DataAccess
                .CommandText = "dbo.GetBhpbioOutliersForLocation"
                With .ParameterCollection
                    .Clear()

                    If (Not String.IsNullOrEmpty(analysisGroup)) Then
                        .Add("@iAnalysisGroup", CommandDataType.VarChar, CommandDirection.Input, analysisGroup)
                    End If

                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

                    If (Not String.IsNullOrEmpty(productSize)) Then
                        .Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, productSize)
                    End If

                    If (Not String.IsNullOrEmpty(attribute)) Then
                        .Add("@iAttribute", CommandDataType.VarChar, CommandDirection.Input, attribute)
                    End If

                    .Add("@iMinimumDeviation", CommandDataType.Float, CommandDirection.Input, minimumDeviation)
                    .Add("@iIncludeDirectSublocations", CommandDataType.Bit, CommandDirection.Input, includeDirectSubLocations)
                    .Add("@iIncludeAllSublocations", CommandDataType.Bit, CommandDirection.Input, includeAllSubLocations)
                    .Add("@iExcludeTotalMaterialDuplicates", CommandDataType.Bit, CommandDirection.Input, excludeTotalMaterialDuplicates)
                    .Add("@iIncludeAllPoints", CommandDataType.Bit, CommandDirection.Input, includeAllPoints)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        ''' <summary>
        ''' Get a a set of points for a series within a date range
        ''' </summary>
        ''' <param name="seriesId">Id of the series to return outlier information for</param>
        ''' <param name="dateFrom">start date from which points are to be returned</param>
        ''' <param name="dateTo">end date to which points are to be returend</param>
        ''' <returns>A datatable with series points</returns>
        Public Function GetBhpbioOutlierAnalysisPoints(seriesId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable _
            Implements IApproval.GetBhpbioOutlierAnalysisPoints

            With DataAccess
                .CommandText = "dbo.GetBhpbioOutlierAnalysisPoints"

                With .ParameterCollection
                    .Clear()
                    .Add("@iSeriesId", CommandDataType.VarChar, CommandDirection.Input, seriesId)
                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        ''' <summary>
        ''' Get attributes for the outlier series
        ''' </summary>
        ''' <param name="seriesId">Id of the series to return outlier attributes for</param>
        ''' <returns>A datatable with attributes</returns>
        Public Function GetBhpbioOutlierAnalysisSeriesAttributes(seriesId As Integer) As DataTable Implements IApproval.GetBhpbioOutlierAnalysisSeriesAttributes
            With DataAccess
                .CommandText = "dbo.GetBhpbioOutlierAnalysisSeriesAttributes"

                With .ParameterCollection
                    .Clear()
                    .Add("@iSeriesId", CommandDataType.VarChar, CommandDirection.Input, seriesId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

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
        Function GetBhpbioOutlierCountByAnalysisGroupForLocation(startDate As DateTime, endDate As DateTime, locationId As Integer, productSize As String,
            attribute As String, minimumDeviation As Decimal, includeDirectSubLocations As Boolean, includeAllSubLocations As Boolean) As DataTable _
            Implements IApproval.GetBhpbioOutlierCountByAnalysisGroupForLocation

            With DataAccess
                .CommandText = "dbo.GetBhpbioOutlierCountByAnalysisGroupForLocation"
                With .ParameterCollection
                    .Clear()
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

                    If (Not String.IsNullOrEmpty(productSize)) Then
                        .Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, productSize)
                    End If

                    If (Not String.IsNullOrEmpty(attribute)) Then
                        .Add("@iAttribute", CommandDataType.VarChar, CommandDirection.Input, attribute)
                    End If

                    .Add("@iMinimumDeviation", CommandDataType.Float, CommandDirection.Input, minimumDeviation)
                    .Add("@iIncludeDirectSublocations", CommandDataType.Bit, CommandDirection.Input, includeDirectSubLocations)
                    .Add("@iIncludeAllSublocations", CommandDataType.Bit, CommandDirection.Input, includeAllSubLocations)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Function EnqueueBhpbioBulkApproval(approval As Boolean, userId As Integer, locationId As Integer, monthFrom As DateTime, monthTo As DateTime,
            locationTypeFrom As Integer, locationTypeTo As Integer, isBulk As Boolean) As Integer Implements IApproval.EnqueueBhpbioBulkApproval

            With DataAccess
                .CommandText = "dbo.BhpbioEnqueueBulkApproval"
                With .ParameterCollection
                    .Clear()
                    .Add("@iApproval", CommandDataType.Bit, CommandDirection.Input, approval)
                    .Add("@iApprovalUserId", CommandDataType.Int, CommandDirection.Input, userId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iEarliestMonth", CommandDataType.DateTime, CommandDirection.Input, monthFrom)
                    .Add("@iLatestMonth", CommandDataType.DateTime, CommandDirection.Input, monthTo)
                    .Add("@iTopLevelLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeFrom)
                    .Add("@iLowestLevelLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeTo)
                    .Add("@iIsBulk", CommandDataType.Bit, CommandDirection.Input, isBulk)
                    .Add("@oApprovalId", CommandDataType.Int, CommandDirection.Output, -1)
                End With
                .ExecuteNonQuery()
                Return Convert.ToInt32(.ParameterCollection.Item("@oApprovalId").Value)
            End With
        End Function

        Function GetBhpbioQueuedBulkApproval() As DataTable Implements IApproval.GetBhpbioQueuedBulkApproval
            With DataAccess
                .CommandText = "dbo.BhpbioSelectEnqueuedBulkApproval"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Sub StartBhpbioBulkApproval(bulkApprovalId As Integer, operationType As Boolean, userId As Integer, locationId As Integer, monthFrom As DateTime,
            monthTo As DateTime, locationTypeFrom As Integer, locationTypeTo As Integer) Implements IApproval.StartBhpbioBulkApproval

            Dim originalTimeout As Int32 = DataAccess.CommandTimeout

            Try
                With DataAccess
                    originalTimeout = .CommandTimeout
                    .CommandText = "dbo.BhpbioStartBulkApproval"
                    .CommandTimeout = LONG_TIMEOUT_SECONDS

                    With .ParameterCollection
                        .Clear()
                    .Add("@iBulkApprovalId", CommandDataType.Int, CommandDirection.Input, bulkApprovalId)
                    .Add("@iOperationType", CommandDataType.Bit, CommandDirection.Input, operationType)
                    .Add("@iApprovalUserId", CommandDataType.Int, CommandDirection.Input, userId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iEarliestMonth", CommandDataType.DateTime, CommandDirection.Input, monthFrom)
                    .Add("@iLatestMonth", CommandDataType.DateTime, CommandDirection.Input, monthTo)
                    .Add("@iTopLevelLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeFrom)
                    .Add("@iLowestLevelLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeTo)
                End With
                .ExecuteNonQuery()
                End With

            Finally
                DataAccess.CommandTimeout = originalTimeout
            End Try

        End Sub

        Function GetLocationTypeId(description As String) As Integer Implements IApproval.GetLocationTypeId
            With DataAccess
                .CommandText = "dbo.GetLocationTypeId"
                With .ParameterCollection
                    .Clear()
                    .Add("@iDescription", CommandDataType.VarChar, CommandDirection.Input, description)
                    .Add("@oLocationTypeId", CommandDataType.Int, CommandDirection.Output, -1)
                End With
                .ExecuteNonQuery()
                Return Convert.ToInt32(.ParameterCollection.Item("@oLocationTypeId").Value)
            End With
        End Function

        Function GetBhpbioPendingApprovalId(userId As Integer, locationId As Integer) As Integer? Implements IApproval.GetBhpbioPendingApprovalId
            With DataAccess
                .CommandText = "dbo.BhpbioGetPendingApprovalId"
                With .ParameterCollection
                    .Clear()
                    .Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@oApprovalId", CommandDataType.Int, CommandDirection.Output, -1)
                End With
                .ExecuteNonQuery()
                Dim approvalId = .ParameterCollection.Item("@oApprovalId").Value.ToString
                If (approvalId = "") Then
                    Return Nothing
                Else
                    Return Int32.Parse(approvalId)
                End If
            End With
        End Function

        Function BhpbioGetApprovalProgress(approvalId As Integer) As DataTable Implements IApproval.BhpbioGetApprovalProgress
            With DataAccess
                .CommandText = "dbo.BhpbioGetApprovalProgress"
                With .ParameterCollection
                    .Clear()
                    .Add("@iApprovalId", CommandDataType.Int, approvalId)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioApprovalSummary(month As DateTime, Optional includeInactive As Boolean = False) As DataTable Implements IApproval.GetBhpbioApprovalSummary
            With DataAccess
                .CommandText = "dbo.GetBhpbioApprovalSummary"
                With .ParameterCollection
                    .Clear()
                    .Add("@iMonth", CommandDataType.DateTime, month)
                    .Add("@iIncludeInactive", CommandDataType.Bit, includeInactive)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioSiblingLocations(locationId As Integer, locationDate As Date) As DataTable Implements IApproval.GetBhpbioSiblingLocations
            With DataAccess
                .CommandText = "dbo.GetBhpbioSiblingLocations"
                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, locationId)
                    .Add("@iLocationDate", CommandDataType.DateTime, locationDate)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioLocationTypeAndApprovalStatus(locationId As Integer, month As DateTime) As DataTable _
            Implements IApproval.GetBhpbioLocationTypeAndApprovalStatus

            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationTypeAndApprovalStatus"
                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioUngroupedStockpileCount(locationId As Integer, month As DateTime) As Integer Implements IApproval.GetBhpbioUngroupedStockpileCount
            With DataAccess
                .CommandText = "dbo.GetBhpbioUngroupedStockpileCount"
                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@oCount", CommandDataType.Int, CommandDirection.Output, -1)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                End With
                .ExecuteNonQuery()
                Return Convert.ToInt32(.ParameterCollection.Item("@oCount").Value)
            End With
        End Function
    End Class
End Namespace