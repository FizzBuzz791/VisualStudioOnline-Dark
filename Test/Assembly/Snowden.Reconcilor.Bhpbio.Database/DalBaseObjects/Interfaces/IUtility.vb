Imports Snowden.Reconcilor.Core

Namespace DalBaseObjects
    Public Interface IUtility
        Inherits Core.Database.DalBaseObjects.IUtility

        Function BhpbioGetBlockedDateForLocation(locationId As Integer, locationDate As DateTime) As DateTime?

        Function GetBhpbioCustomMessage(ByVal messageName As String) As DataTable

        Function GetBhpbioCustomMessages() As DataTable

        Sub DeleteBhpbioCustomMessage(ByVal name As String)

        Sub AddOrUpdateBhpbioCustomMessage(ByVal name As String, ByVal updateText As Int16, ByVal text As String, 
                                           ByVal updateExpirationDate As Int16, ByVal expirationDate As DateTime, 
                                           ByVal updateIsActive As Int16, ByVal isActive As Int16)

        Sub AddOrUpdateBhpbioReportColor(ByVal tagId As String, ByVal description As String,
                                         ByVal isVisible As Short, ByVal color As String, ByVal lineStyle As String, ByVal markerShape As String)

        Function GetBhpMaterialTypeList(ByVal isDigblockGroup As Int16,
         ByVal isStockpileGroup As Int16,
         ByVal locationId As Int32,
         ByVal materialCategoryId As String,
         ByVal parentMaterialTypeId As Int32) As DataTable

        Function GetBhpbioReportColorList(ByVal tagId As String, ByVal showVisible As Boolean) As DataTable

        Sub AddOrUpdateBhpbioReportThreshold(ByVal locationId As Int32, ByVal thresholdTypeId As String,
         ByVal fieldId As Int16, ByVal lowThreshold As Double, ByVal highThreshold As Double,
         ByVal absoluteThreshold As Boolean)

        Sub DeleteBhpbioReportThreshold(ByVal locationId As Int32, ByVal thresholdTypeId As String,
         ByVal fieldId As Int16)

        Function GetBhpbioReportThresholdList(ByVal locationId As Int32, ByVal thresholdTypeId As String,
         ByVal onlyInherited As Boolean, ByVal onlyLocation As Boolean) As DataTable

        Function GetBhpbioReportThresholdTypeList() As DataTable

        Sub GetBhpbioProductionEntity(ByVal siteLocationId As Int32, ByVal code As String, ByVal type As String,
         ByVal Direction As String, ByVal TransactionDate As DateTime,
         ByRef returnStockpileId As Int32, ByRef returnCrusherId As String, ByRef returnMillId As String)

        Sub GetBhpbioProductionWeightometer(ByVal sourceStockpileId As Int32, ByVal sourceCrusherId As String,
         ByVal sourceMillId As String, ByVal destinationStockpileId As Int32, ByVal destinationCrusherId As String,
         ByVal destinationMillId As String, ByVal transactionDate As DateTime, ByVal sourceType As String,
         ByVal destinationType As String, ByVal siteLocationId As Int32, ByRef returnWeightometerId As String,
         ByRef returnIsError As Boolean, ByRef returnErrorDescription As String)

        Function GetBhpbioMaterialLookup(ByVal materialCategoryId As String, ByVal locationTypeId As Int16) As DataTable

        Sub AddOrUpdateBhpbioAnalysisVariance(ByVal locationId As Int32, ByVal varianceType As String,
         ByVal percentage As Double, ByVal color As String)

        Sub DeleteBhpbioAnalysisVariance(ByVal locationId As Int32, ByVal varianceType As String)

        Function GetBhpbioAnalysisVarianceList(ByVal locationId As Int32, ByVal varianceType As String,
         ByVal onlyInherited As Boolean, ByVal onlyLocation As Boolean) As DataTable

        Function GetBhpbioAnalysisVarianceList(ByVal locationId As Int32,
         ByVal onlyInherited As Boolean, ByVal onlyLocation As Boolean) As DataTable

        Function AddBhpbioMetBalancing(ByVal siteCode As String, ByVal calendarDate As DateTime,
         ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal plantName As String,
         ByVal streamName As String, ByVal weightometer As String, ByVal dryTonnes As Double,
         ByVal wetTonnes As Double, ByVal splitCycle As Double, ByVal splitPlant As Double,
         ByVal productSize As String) As Int32

        Sub UpdateBhpbioMetBalancing(ByVal bhpbioMetBalancingId As Int32,
            ByVal startDate As DateTime, ByVal endDate As DateTime,
            ByVal weightometer As String, ByVal dryTonnes As Double,
            ByVal wetTonnes As Double, ByVal splitCycle As Double,
            ByVal splitPlant As Double, ByVal productSize As String)

        Sub AddOrUpdateBhpbioMetBalancingGrade(ByVal bhpbioMetBalancingId As Int32, ByVal gradeId As Short, ByVal gradeValue As Double)

        Sub DeleteBhpbioMetBalancing(ByVal bhpbioMetBalancingId As Int32)

        Sub BhpbioDataExceptionStockpileGroupLocationMissing()

        Sub DeleteBhpbioMaterialTypeLocationAll(ByVal materialTypeId As Int32)

        Sub AddBhpbioMaterialTypeLocation(ByVal materialTypeId As Int32, ByVal LocationId As Int32)

        Function GetBhpbioMaterialTypeLocationList(ByVal materialTypeId As Int32) As DataTable

        Function GetBhpbioDataExceptionList(ByVal dataExceptionTypeId As Int32,
         ByVal dataExceptionStatusId As String, ByVal locationId As Int32) As DataTable

        ''' <summary>
        ''' Returns a list of data exceptions that match the specified filter conditions
        ''' </summary>
        ''' <param name="includeActive">If true, active data exceptions will be included in the filter</param>
        ''' <param name="includeDismissed">If true, dismissed data exceptions will be included in the filter</param>
        ''' <param name="includeResolved">If true, resolved data exceptions will be included in the filter</param>
        ''' <param name="dateFrom">If specified, only data exceptions with a date on or after this value will be returned</param>
        ''' <param name="dateTo">If specified, only data exceptions with a date on or prior to this value will be returned</param>
        ''' <param name="dataExceptionTypeId">If specified, only data exceptions with the type Id specified will match the filter</param>
        ''' <param name="descriptionContains">If specified, only data exceptions with a short or long description that contains the description text will match the filter</param>
        ''' <returns></returns>
        Function GetBhpbioDataExceptionFilteredList(ByVal includeActive As Boolean, ByVal includeDismissed As Boolean, ByVal includeResolved As Boolean,
                                        ByVal dateFrom As Nullable(Of DateTime), ByVal dateTo As Nullable(Of DateTime),
                                        ByVal dataExceptionTypeId As Nullable(Of Integer), ByVal descriptionContains As String,
                                        ByVal maxDataExceptions As Integer, ByVal LocationId As Nullable(Of Integer)) As DataTable


        ''' <summary>
        ''' Dismisses a list of data exceptions that match the specified filter conditions
        ''' </summary>
        ''' <param name="includeActive">If true, active data exceptions will be included in the filter</param>
        ''' <param name="includeDismissed">If true, dismissed data exceptions will be included in the filter</param>
        ''' <param name="includeResolved">If true, resolved data exceptions will be included in the filter</param>
        ''' <param name="dateFrom">If specified, only data exceptions with a date on or after this value will be returned</param>
        ''' <param name="dateTo">If specified, only data exceptions with a date on or prior to this value will be returned</param>
        ''' <param name="dataExceptionTypeId">If specified, only data exceptions with the type Id specified will match the filter</param>
        ''' <param name="descriptionContains">If specified, only data exceptions with a short or long description that contains the description text will match the filter</param>
        ''' <returns></returns>
        Function UpdateBhpbioDataExceptionDismissAll(ByVal includeActive As Boolean, ByVal includeDismissed As Boolean, ByVal includeResolved As Boolean,
                                        ByVal dateFrom As Nullable(Of DateTime), ByVal dateTo As Nullable(Of DateTime),
                                        ByVal dataExceptionTypeId As Nullable(Of Integer), ByVal descriptionContains As String,
                                        ByVal maxDataExceptions As Integer, ByVal LocationId As Nullable(Of Integer)) As DataTable

        ''' <summary>
        ''' Returns a list of  data exception types.
        ''' </summary>
        ''' <param name="includeActive">If true, active data exceptions will be included in the filter</param>
        ''' <param name="includeDismissed">If true, dismissed data exceptions will be included in the filter</param>
        ''' <param name="includeResolved">If true, resolved data exceptions will be included in the filter</param>
        ''' <param name="dateFrom">If specified, only data exceptions with a date on or after this value will be returned</param>
        ''' <param name="dateTo">If specified, only data exceptions with a date on or prior to this value will be returned</param>
        ''' <param name="dataExceptionTypeId">If specified, only data exceptions with the type Id specified will match the filter</param>
        ''' <param name="descriptionContains">If specified, only data exceptions with a short or long description that contains the description text will match the filter</param>
        ''' <returns></returns>
        Function GetBhpbioDataExceptionTypeFilteredList(ByVal includeActive As Boolean, ByVal includeDismissed As Boolean, ByVal includeResolved As Boolean,
                                        ByVal dateFrom As Nullable(Of DateTime), ByVal dateTo As Nullable(Of DateTime),
                                        ByVal dataExceptionTypeId As Nullable(Of Integer), ByVal descriptionContains As String, ByVal LocationId As Nullable(Of Integer)) As DataTable


        Function GetBhpbioDataExceptionCount(ByVal locationId As Int32) As Int32

        Function GetBhpbioDataExceptionCount(ByVal locationId As Int32, month As DateTime) As Int32

        Function GetBhpbioLocationRoot() As Int32

        Sub CalcVirtualFlow()

        Sub AddOrUpdateBhpbioStockpileLocationConfiguration(ByVal locationId As Int32,
                                                    ByVal imageData As Byte(), ByVal promoteStockpiles As Boolean,
                                                    ByVal updateImageData As Boolean,
                                                    ByVal updatePromoteStockpiles As Boolean)


        Function GetBhpbioStockpileLocationConfiguration(ByVal locationId As Int32) As DataTable

        Function GetBhpbioLocationListWithOverride(ByVal locationId As Int32, ByVal getChildLocations As Int16, ByVal locationDate As Date) As DataTable

        Function GetBhpbioLocationParentHeirarchyWithOverride(ByVal locationId As Int32, ByVal locationDate As Date) As DataTable

        Function GetBhpbioLocationNameWithOverride(ByVal locationId As Int32,
            ByVal startDate As Date,
            ByVal endDate As Date) As DataTable

        Function GetBhpbioLocationChildrenNameWithOverride(ByVal locationId As Int32,
            ByVal startDate As Date,
            ByVal endDate As Date) As DataTable

        Function GetBhpbioImportLocationCodeList(ByVal importParameterId As Nullable(Of Int32), ByVal locationId As Nullable(Of Int32)) As DataTable

        Sub UpdateBhpbioLocationDate()

        Sub UpdateBhpbioStockpileLocationDate()

        Sub CorrectBhpbioProductionWeightometerAndDestinationAssignments()

        Function GetBhpbioDefaultLumpFinesList(ByVal locationId As Int32?,
            ByVal locationTypeId As Int32?) As DataTable

        Function GetBhpbioDefaultLumpFinesRecord(ByVal bhpbioDefaultLumpFinesId As Int32) As DataTable

        Function AddOrUpdateBhpbioLumpFinesRecord(ByVal bhpbioDefaultLumpFinesId As Integer?,
            ByVal locationId As Integer, ByVal startDate As Date,
            ByVal lumpPercent As Decimal, ByVal validateOnly As Boolean) As DataTable

        Sub DeleteBhpbioLumpFinesRecord(ByVal bhpbioDefaultLumpFinesId As Integer)

        Sub DeleteBhpbioProductTypeRecord(ByVal BhpbioDefaultProductTypeId As Integer)

        Function GetGradeObjectsList(ByVal gradeVisibility As Short, ByVal numericFormat As String) As Dictionary(Of String, Grade)

        Sub UpdateBhpbioMissingSampleDataException(ByVal dateFrom As Date, ByVal dateTo As Date)

        ''' <summary>
        ''' Log the receipt of a message
        ''' </summary>
        ''' <param name="receivedDateTime">date and time of receipt</param>
        ''' <param name="messageTimestamp">timestamp from the message</param>
        ''' <param name="messageBody">the content of the message</param>
        ''' <param name="messageType">the type of message</param>
        ''' <param name="dataKey">a key portion of data from the message</param>
        Sub LogMessage(ByVal receivedDateTime As Date, ByVal messageTimestamp As Nullable(Of Date), ByVal messageBody As String, ByVal messageType As String, ByVal dataKey As String)


        Function IsBhpbioStockpileGroupAdminEditable(ByVal stockpileGroupId As String) As Boolean

        Function CheckUpdateSiteMapList() As DataTable

        Function GetBhpbioProductTypeList() As DataTable

        Function GetBhpbioDepositList(ByVal BhpbioLocationId As Integer) As DataTable

        Function GetDepositPits(ByVal locationGroupId As Integer?, ByVal parentSiteId As Integer?) As DataSet

        Sub AddOrUpdateBhpbioLocationGroup(ByVal BhpbioDefaultDepositId As Integer?, ByVal siteId As Integer, ByVal name As String, ByVal pitList As String)

        Sub DeleteDeposit(ByVal depositId As Integer)


        Function GetBhpbioProductTypeLocation(ByVal BhpbioDefaultProductTypeId As Integer) As DataTable
        Function GetBhpbioProductTypesWithLocationIds() As DataTable

        Sub AddOrUpdateProductTypeRecord(ByVal BhpbioDefaultProductTypeId As Integer?,
           ByVal Code As String, ByVal Description As String, ByVal ProductSize As String,
           ByVal Hubs As ArrayList)
        Function GetBhpbioAttributeProperties() As DataTable

        Sub UpdateBhpbioImportSyncRowFilterData(ByVal importJobId As Int32)

#Region "Sample Stations"
        Function GetBhpbioSampleStationList(locationId As Integer, productSize As String) As DataTable
        Sub DeleteBhpbioSampleStation(sampleStationId As Integer)
#End Region
    End Interface
End Namespace