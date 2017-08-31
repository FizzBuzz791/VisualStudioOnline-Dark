Imports Snowden.Reconcilor.Core

' ReSharper disable once CheckNamespace
Namespace DalBaseObjects
    Public Interface IUtility
        Inherits Core.Database.DalBaseObjects.IUtility

        Function BhpbioGetBlockedDateForLocation(locationId As Integer, locationDate As DateTime) As DateTime?

        Function GetBhpbioCustomMessage(messageName As String) As DataTable

        Function GetBhpbioCustomMessages() As DataTable

        Sub DeleteBhpbioCustomMessage(name As String)

        Sub AddOrUpdateBhpbioCustomMessage(name As String, updateText As Int16, text As String,
                                           updateExpirationDate As Int16, expirationDate As DateTime,
                                           updateIsActive As Int16, isActive As Int16)

        Sub AddOrUpdateBhpbioReportColor(tagId As String, description As String,
                                         isVisible As Short, color As String, lineStyle As String, markerShape As String)

        Function GetBhpMaterialTypeList(isDigblockGroup As Int16,
         isStockpileGroup As Int16,
         locationId As Int32,
         materialCategoryId As String,
         parentMaterialTypeId As Int32) As DataTable

        Function GetBhpbioReportColorList(tagId As String, showVisible As Boolean) As DataTable

        Sub AddOrUpdateBhpbioReportThreshold(locationId As Int32, thresholdTypeId As String,
         fieldId As Int16, lowThreshold As Double, highThreshold As Double,
         absoluteThreshold As Boolean)

        Sub DeleteBhpbioReportThreshold(locationId As Int32, thresholdTypeId As String,
         fieldId As Int16)

        Function GetBhpbioReportThresholdList(locationId As Int32, thresholdTypeId As String,
         onlyInherited As Boolean, onlyLocation As Boolean) As DataTable

        Function GetBhpbioReportThresholdTypeList() As DataTable

        Sub GetBhpbioProductionEntity(siteLocationId As Int32, code As String, type As String,
         direction As String, transactionDate As DateTime,
         ByRef returnStockpileId As Int32, ByRef returnCrusherId As String, ByRef returnMillId As String)

        Sub GetBhpbioProductionWeightometer(sourceStockpileId As Int32, sourceCrusherId As String,
         sourceMillId As String, destinationStockpileId As Int32, destinationCrusherId As String,
         destinationMillId As String, transactionDate As DateTime, sourceType As String,
         destinationType As String, siteLocationId As Int32, ByRef returnWeightometerId As String,
         ByRef returnIsError As Boolean, ByRef returnErrorDescription As String)

        Function GetBhpbioMaterialLookup(materialCategoryId As String, locationTypeId As Int16) As DataTable

        Sub AddOrUpdateBhpbioAnalysisVariance(locationId As Int32, varianceType As String,
         percentage As Double, color As String)

        Sub DeleteBhpbioAnalysisVariance(locationId As Int32, varianceType As String)

        Function GetBhpbioAnalysisVarianceList(locationId As Int32, varianceType As String,
         onlyInherited As Boolean, onlyLocation As Boolean) As DataTable

        Function GetBhpbioAnalysisVarianceList(locationId As Int32,
         onlyInherited As Boolean, onlyLocation As Boolean) As DataTable

        Function AddBhpbioMetBalancing(siteCode As String, calendarDate As DateTime,
         startDate As DateTime, endDate As DateTime, plantName As String,
         streamName As String, weightometer As String, dryTonnes As Double,
         wetTonnes As Double, splitCycle As Double, splitPlant As Double,
         productSize As String) As Int32

        Sub UpdateBhpbioMetBalancing(bhpbioMetBalancingId As Int32,
            startDate As DateTime, endDate As DateTime,
            weightometer As String, dryTonnes As Double,
            wetTonnes As Double, splitCycle As Double,
            splitPlant As Double, productSize As String)

        Sub AddOrUpdateBhpbioMetBalancingGrade(bhpbioMetBalancingId As Int32, gradeId As Short, gradeValue As Double)

        Sub DeleteBhpbioMetBalancing(bhpbioMetBalancingId As Int32)

        Sub BhpbioDataExceptionStockpileGroupLocationMissing()

        Sub DeleteBhpbioMaterialTypeLocationAll(materialTypeId As Int32)

        Sub AddBhpbioMaterialTypeLocation(materialTypeId As Int32, locationId As Int32)

        Function GetBhpbioMaterialTypeLocationList(materialTypeId As Int32) As DataTable

        Function GetBhpbioDataExceptionList(dataExceptionTypeId As Int32,
         dataExceptionStatusId As String, locationId As Int32) As DataTable

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
        Function GetBhpbioDataExceptionFilteredList(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                        dateFrom As Date?, dateTo As Date?,
                                        dataExceptionTypeId As Integer?, descriptionContains As String,
                                        maxDataExceptions As Integer, locationId As Integer?) As DataTable


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
        Function UpdateBhpbioDataExceptionDismissAll(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                        dateFrom As Date?, dateTo As Date?,
                                        dataExceptionTypeId As Integer?, descriptionContains As String,
                                        maxDataExceptions As Integer, locationId As Integer?) As DataTable

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
        Function GetBhpbioDataExceptionTypeFilteredList(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                        dateFrom As Date?, dateTo As Date?,
                                        dataExceptionTypeId As Integer?, descriptionContains As String, locationId As Integer?) As DataTable


        Function GetBhpbioDataExceptionCount(locationId As Int32) As Int32

        Function GetBhpbioDataExceptionCount(locationId As Int32, month As DateTime) As Int32

        Function GetBhpbioLocationRoot() As Int32

        Sub CalcVirtualFlow()

        Sub AddOrUpdateBhpbioStockpileLocationConfiguration(locationId As Int32,
                                                    imageData As Byte(), promoteStockpiles As Boolean,
                                                    updateImageData As Boolean,
                                                    updatePromoteStockpiles As Boolean)


        Function GetBhpbioStockpileLocationConfiguration(locationId As Int32) As DataTable

        Function GetBhpbioLocationListWithOverride(locationId As Int32, getChildLocations As Int16, locationDate As Date) As DataTable

        Function GetBhpbioLocationParentHeirarchyWithOverride(locationId As Int32, locationDate As Date) As DataTable

        Function GetBhpbioLocationNameWithOverride(locationId As Int32,
            startDate As Date,
            endDate As Date) As DataTable

        Function GetBhpbioLocationChildrenNameWithOverride(locationId As Int32,
            startDate As Date,
            endDate As Date) As DataTable

        Function GetBhpbioImportLocationCodeList(importParameterId As Nullable(Of Int32), locationId As Nullable(Of Int32)) As DataTable

        Sub UpdateBhpbioLocationDate()

        Sub UpdateBhpbioStockpileLocationDate()

        Sub CorrectBhpbioProductionWeightometerAndDestinationAssignments()

        Function GetBhpbioDefaultLumpFinesList(locationId As Int32?,
            locationTypeId As Int32?) As DataTable

        Function GetBhpbioDefaultLumpFinesRecord(bhpbioDefaultLumpFinesId As Int32) As DataTable

        Function AddOrUpdateBhpbioLumpFinesRecord(bhpbioDefaultLumpFinesId As Integer?,
            locationId As Integer, startDate As Date,
            lumpPercent As Decimal, validateOnly As Boolean) As DataTable

        Sub DeleteBhpbioLumpFinesRecord(bhpbioDefaultLumpFinesId As Integer)

        Sub DeleteBhpbioProductTypeRecord(bhpbioDefaultProductTypeId As Integer)

        Function GetGradeObjectsList(gradeVisibility As Short, numericFormat As String) As Dictionary(Of String, Grade)

        Sub UpdateBhpbioMissingSampleDataException(dateFrom As Date, dateTo As Date)

        ''' <summary>
        ''' Log the receipt of a message
        ''' </summary>
        ''' <param name="receivedDateTime">date and time of receipt</param>
        ''' <param name="messageTimestamp">timestamp from the message</param>
        ''' <param name="messageBody">the content of the message</param>
        ''' <param name="messageType">the type of message</param>
        ''' <param name="dataKey">a key portion of data from the message</param>
        Sub LogMessage(receivedDateTime As Date, messageTimestamp As Nullable(Of Date), messageBody As String, messageType As String, dataKey As String)


        Function IsBhpbioStockpileGroupAdminEditable(stockpileGroupId As String) As Boolean

        Function CheckUpdateSiteMapList() As DataTable

        Function GetBhpbioProductTypeList() As DataTable

        Function GetBhpbioDepositList(bhpbioLocationId As Integer) As DataTable

        Function GetDepositPits(locationGroupId As Integer?, parentSiteId As Integer?) As DataSet

        Sub AddOrUpdateBhpbioLocationGroup(bhpbioDefaultDepositId As Integer?, siteId As Integer, name As String, pitList As String)

        Sub DeleteDeposit(depositId As Integer)


        Function GetBhpbioProductTypeLocation(bhpbioDefaultProductTypeId As Integer) As DataTable
        Function GetBhpbioProductTypesWithLocationIds() As DataTable

        Sub AddOrUpdateProductTypeRecord(bhpbioDefaultProductTypeId As Integer?,
           code As String, description As String, productSize As String,
           hubs As ArrayList)
        Function GetBhpbioAttributeProperties() As DataTable

        Sub UpdateBhpbioImportSyncRowFilterData(importJobId As Int32)

#Region "Sample Stations"
        Function GetBhpbioSampleStationList(locationId As Integer, productSize As String) As DataTable
        Sub DeleteBhpbioSampleStation(sampleStationId As Integer)
        Function GetWeightometerListWithLocations() As DataTable
        Sub AddOrUpdateBhpbioSampleStation(sampleStationId As Integer?, name As String, description As String, locationId As Integer, weightometerId As String, productSize As String)
        Function GetBhpbioSampleStation(sampleStationId As Integer) As DataTable
        Function GetBhpbioSampleStationTargetsForSampleStation(sampleStationId As Integer) As DataTable
        Sub AddOrUpdateBhpbioSampleStationTarget(targetId As Integer?, sampleStationId As Integer, startDate As Date, coverageTarget As Decimal, coverageWarning As Decimal, ratioTarget As Integer, ratioWarning As Integer)
        Function GetBhpbioSampleStationTarget(sampleStationTargetId As Integer) As DataTable
        Sub DeleteBhpbioSampleStationTarget(targetId As Integer)
#End Region

        Function GetWeatheringList() As DataTable
        
        Function GetBhpbioStratigraphyHierarchyList() As DataTable
        Function GetBhpbioStratigraphyHierarchyTypeList() As DataTable

        Function DoesStratNumExistInStratigraphyHierarchy(stratNum As String) As Boolean

    End Interface
End Namespace