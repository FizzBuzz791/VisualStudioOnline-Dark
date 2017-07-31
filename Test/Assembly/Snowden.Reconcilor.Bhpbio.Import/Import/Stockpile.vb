Imports System.IO
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Common.Import
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Core.Database
Imports Snowden.Common.Import.Data

'Imports Snowden.Reconcilor.Bhpbio.Import.StockpilesService

Friend NotInheritable Class Stockpile
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _defaultShift As String = "D"
    Private Const _stockpileAlgorithm As String = "Unknown"
    Private Const _defaultDate As String = "1 Jan 1900"

    Private Const _negativeValue As Int32 = -1
    Private Const _stockpileGradeRelationName As String = "FK_Stockpile_StockpileGrade"
    Private Const _normalMaterialCategoryId As String = "OreType"
    Private Const _miscategorisedMaterialCategoryId As String = "MiscategorisedStockpiles"
    Private Const _defaultAlgorithm As String = "Average"
    Private Const _defaultComponentId As Int32 = 1
    Private Const _defaultBuildId As Int32 = 1
    Private Const _stockpileTypeNotes As String = "StockpileType"
    Private Const _productSizeNotes As String = "ProductSize"
    Private Const _systemStartDateAllowedCachingMinutes As Integer = 60

    Private _settings As ConfigurationSettings
    Private _site As String
    Private _stockpileDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile
    Private _utilityDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
    Private _disposed As Boolean

    Private _cachedSystemStartDate As Date?
    Private _cachedSystemStartDateLoaded As Date?

    Protected ReadOnly Property Site() As String
        Get
            Return _site
        End Get
    End Property

    Public Sub New()
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Stockpile"
        SourceSchemaName = "Stockpile"
        CanGenerateSourceSchema = False
        _settings = ConfigurationSettings.GetConfigurationSettings()
    End Sub

    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If (Not _disposed) Then
                If (disposing) Then
                    If (Not _stockpileDal Is Nothing) Then
                        _stockpileDal.Dispose()
                        _stockpileDal = Nothing
                    End If

                    If (Not _utilityDal Is Nothing) Then
                        _utilityDal.Dispose()
                        _utilityDal = Nothing
                    End If
                End If
            End If

            _disposed = True
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        Dim validates As Boolean = True

        'check that all parameters exists
        If Not parameters.ContainsKey("Site") Then
            validates = False
            validationMessage.Append("Cannot find the Site parameter.")
        End If

        Return validates
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        If parameters("Site") = "" Then
            _site = Nothing
        Else
            _site = CodeTranslationHelper.SingleSiteCodeFromReconcilor(parameters("Site"), toShortCode:=True)
        End If
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Return (_site Is Nothing OrElse _site.ToUpper = Convert.ToString(keyRows("Mine")).ToUpper)
    End Function

    Protected Overrides Sub PostCompare()
        ' do nothing
    End Sub

    Protected Overrides Sub PreCompare()
        ' do nothing
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As Common.Import.Database.ImportSync)
        _utilityDal.BhpbioDataExceptionStockpileGroupLocationMissing()
        _utilityDal.UpdateBhpbioStockpileLocationDate()
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
    End Sub

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)

    End Sub

    Protected Overrides Sub SetupDataAccessObjects()
        _stockpileDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalStockpile
        _utilityDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility

        _stockpileDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection
        _utilityDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        ReferenceDataCachedHelper.UtilityDal = _utilityDal
        LocationDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Sub ProcessConflict(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal importSyncConflict As DataTable, _
     ByVal importSyncConflictField As DataTable, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)
        'no checks - stockpiles cannot be removed by reconcilor
    End Sub

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, _
     ByVal sourceRow As System.Data.DataRow, _
     ByVal destinationRow As System.Data.DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As System.Data.DataRow, _
     ByVal syncQueueChangedFields As System.Data.DataTable, _
     ByVal importSyncDal As ImportSync)

        ' deletes won't remove any records in this release
        Dim stockpileName As String

        stockpileName = Convert.ToString(sourceRow("StockpileName"))
        ' Insert a row into BhpbioStockpileDeletion Table
        _stockpileDal.AddBhpbioStockpileDeletionState(stockpileName)

    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim stockpileId As Int32 = NullValues.Int32
        Dim stockpileName As String
        Dim stockpileDescription As String
        Dim isInReports As Boolean
        Dim isVisible As Boolean
        Dim startDate As DateTime
        Dim startShift As String
        Dim endDate As DateTime
        Dim endShift As String
        Dim startTonnes As Double
        Dim stockpileStateId As String
        Dim materialTypeId As Int32?
        Dim destinationStockpileRow As DataRow
        Dim gradeId As Int16
        Dim stockpileAlgorithm As String
        Dim locationId As Int32
        Dim retrievedSystemStartDate As Date?
        Dim previousDeletionState As Boolean = False
        Dim is_Multi_Build As Boolean
        Dim is_Multi_Component As Boolean
        Dim max_Tonnes As Double = NullValues.Double
        Dim notes As String = NullValues.String
        Dim reclaim_Start_Date As DateTime = NullValues.DateTime
        Dim reclaim_Start_Shift As String = Nothing
        Dim completion_Description As String = NullValues.String

        AddTableColumn(destinationRow.Table, "StockpileId", GetType(String), Nothing)

        If dataTableName = "Stockpile" Then
            'set the Stockpile fields not in the source
            stockpileName = Convert.ToString(sourceRow("StockpileName"))
            isInReports = Convert.ToBoolean(IfDBNull(sourceRow("IsInReports"), False))
            isVisible = Convert.ToBoolean(sourceRow("IsVisible"))
            startDate = Convert.ToDateTime(sourceRow("StartDate"))
            endDate = Convert.ToDateTime(IfDBNull(sourceRow("EndDate"), DoNotSetValues.DateTime))

            startShift = Convert.ToChar(IfDBNull(sourceRow("StartShift"), DoNotSetValues.Char))
            If Not String.IsNullOrEmpty(startShift) Then
                startShift = startShift.Substring(0, 1)
            End If

            endShift = Convert.ToChar(IfDBNull(sourceRow("EndShift"), DoNotSetValues.Char))
            If Not String.IsNullOrEmpty(endShift) Then
                endShift = endShift.Substring(0, 1)
            End If

            startTonnes = Convert.ToDouble(IIf(sourceRow("StartTonnes") Is DBNull.Value, 0.0, sourceRow("StartTonnes")))

            'ensure the start date isn't before the start date of the system
            retrievedSystemStartDate = GetSystemStartDateFromCache()
            If retrievedSystemStartDate.HasValue AndAlso startDate < retrievedSystemStartDate Then
                startDate = retrievedSystemStartDate.Value
            End If

            'resolve the site
            locationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("Mine"))).Value

            'resolve an appropriate material type id
            materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_normalMaterialCategoryId, _
             Convert.ToString(sourceRow("MaterialType")), locationId)
            If Not materialTypeId.HasValue Then
                materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_miscategorisedMaterialCategoryId, _
                 Convert.ToString(sourceRow("MaterialType")), Nothing)
            End If

            'determine the algorithm
            stockpileAlgorithm = Convert.ToString(sourceRow("StockpileAlgorithm"))
            If Not DoesStockpileTypeExist(stockpileAlgorithm) Then
                stockpileAlgorithm = _defaultAlgorithm
            End If

            If Not sourceRow("Description") Is DBNull.Value Then
                stockpileDescription = Convert.ToString(sourceRow("Description"))
            Else
                stockpileDescription = Nothing
            End If

            'set up stockpile state id
            If sourceRow("EndDate") Is DBNull.Value Then
                stockpileStateId = "NORMAL"
            Else
                stockpileStateId = "CLOSED"
            End If

            ' If a row exists in BhpbioStockpileDeletion  
            ' Delete it...
            ' also it means this operation is an update and not an insert
            _stockpileDal.ClearBhpbioStockpileDeletionState(stockpileName, previousDeletionState, stockpileId)

            ' if there is no stockpile id for a stockpile with this name
            If (stockpileId = NullValues.Int32) Then
                'insert the stockpile record... it really is new
                stockpileId = _stockpileDal.AddStockpile(stockpileName, Convert.ToInt16(False), _
                 Convert.ToInt16(False), stockpileAlgorithm, materialTypeId.Value, stockpileStateId, _
                 stockpileDescription, startDate, startShift, Convert.ToInt16(isInReports), DoNotSetValues.Double, _
                 Convert.ToInt16(isVisible), Convert.ToInt16(False), DoNotSetValues.DateTime, DoNotSetValues.Char, endDate, _
                 endShift, DoNotSetValues.String, DoNotSetValues.String, startTonnes)

                _stockpileDal.AddOrUpdateStockpileLocation(stockpileId, NullValues.Int16, locationId)

                AddInitialGrades(stockpileId)

                'save the stockpile id
                destinationRow("StockpileId") = stockpileId.ToString

                'assign the stockpile group accordingly - however it is calculated!
                If Not (GetStockpileGroupMembership(Convert.ToString(sourceRow("StockpileType"))) Is Nothing) Then
                    _utilityDal.AddStockpileGroupStockpile(GetStockpileGroupMembership(Convert.ToString(sourceRow("StockpileType"))), stockpileId)
                End If
            Else
                ' otherwise the stockpile already exists...do an update
                Dim update_stockpile_Name As Boolean = False
                Dim update_Is_In_Reports As Boolean = True
                Dim update_Description As Boolean = True
                Dim update_Is_Multi_Build As Boolean = False
                Dim update_Is_Multi_Component As Boolean = False
                Dim update_Material_Type_Id As Boolean = True
                Dim update_Max_Tonnes As Boolean = False
                Dim update_Is_Visible As Boolean = True
                Dim update_Start_Tonnes As Boolean = True
                Dim update_Start_Date As Boolean = (Not startDate = DoNotSetValues.DateTime)
                Dim update_Start_Shift As Boolean = update_Start_Date
                Dim update_End_Date As Boolean = (Not endDate = DoNotSetValues.DateTime)
                Dim update_End_Shift As Boolean = update_End_Date
                Dim update_Stockpile_State_Id As Boolean = True
                Dim update_Notes As Boolean = True
                Dim haulage_Raw_Resolve_All As Boolean = False
                Dim update_Reclaim_Start_Date As Boolean = False
                Dim update_Reclaim_Start_Shift As Boolean = False
                Dim update_Completion_Description As Boolean = False

                destinationRow("StockpileId") = stockpileId.ToString

                'update the Stockpile Record
                _stockpileDal.UpdateStockpile(stockpileId, Convert.ToInt16(update_stockpile_Name), stockpileName, _
                     Convert.ToInt16(update_Description), stockpileDescription, Convert.ToInt16(update_Is_Multi_Build), _
                     Convert.ToInt16(is_Multi_Build), Convert.ToInt16(update_Is_Multi_Component), Convert.ToInt16(is_Multi_Component), _
                     Convert.ToInt16(update_Material_Type_Id), materialTypeId.Value, Convert.ToInt16(update_Is_In_Reports), _
                     Convert.ToInt16(isInReports), Convert.ToInt16(update_Max_Tonnes), max_Tonnes, Convert.ToInt16(update_Is_Visible), _
                     Convert.ToInt16(isVisible), Convert.ToInt16(update_Notes), notes, Convert.ToInt16(update_Start_Tonnes), _
                     startTonnes, Convert.ToInt16(haulage_Raw_Resolve_All))

                'Update the Stockpile Build Record
                _stockpileDal.UpdateStockpileBuild(stockpileId, _defaultBuildId, Convert.ToInt16(update_Stockpile_State_Id), _
                     stockpileStateId, Convert.ToInt16(update_Start_Date), startDate, Convert.ToInt16(update_Start_Shift), _
                     startShift, Convert.ToInt16(update_Reclaim_Start_Date), reclaim_Start_Date, Convert.ToInt16(update_Reclaim_Start_Shift), _
                     reclaim_Start_Shift, Convert.ToInt16(update_End_Date), endDate, Convert.ToInt16(update_End_Shift), endShift, _
                     Convert.ToInt16(update_Completion_Description), completion_Description, Convert.ToInt16(haulage_Raw_Resolve_All))
            End If

            If Not sourceRow("StockpileType") Is DBNull.Value Then
                _stockpileDal.AddOrUpdateStockpileNotes(stockpileId, Convert.ToString(sourceRow("StockpileType")), _stockpileTypeNotes, 1)
            End If
            If Not sourceRow("ProductSize") Is DBNull.Value Then
                _stockpileDal.AddOrUpdateStockpileNotes(stockpileId, Convert.ToString(sourceRow("ProductSize")), _productSizeNotes, 2)
            End If

        ElseIf dataTableName = "StockpileGrade" Then
            AddTableColumn(destinationRow.Table, "GradeId", GetType(String), Nothing)

            'determine the appropriate relation name
            destinationStockpileRow = DirectCast(sourceRow.GetParentRow(_stockpileGradeRelationName)("DestinationRow"), DataRow)
            stockpileId = Convert.ToInt32(destinationStockpileRow("StockpileId"))

            'resolve the grade
            gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).Value

            _stockpileDal.AddOrUpdateStockpileBuildComponentGrade(stockpileId, _defaultBuildId, _defaultComponentId, _
             gradeId, Convert.ToSingle(IfDBNull(sourceRow("Value"), NullValues.Single)))

            'save the grade id
            destinationRow("GradeId") = gradeId.ToString
        End If

    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim stockpileId As Int32 = NullValues.Int32
        Dim startTonnes As Double = NullValues.Double
        Dim startDate As DateTime = NullValues.DateTime
        Dim startShift As String = DoNotSetValues.Char
        Dim endDate As DateTime = NullValues.DateTime
        Dim endShift As String = DoNotSetValues.Char
        Dim stockpileStateId As String = NullValues.String
        Dim materialTypeId As Int32?
        Dim destinationStockpileRow As DataRow
        Dim gradeId As Int16
        Dim stockpileDescription As String = NullValues.String
        Dim locationId As Int32
        Dim systemStartDate As DateTime?
        Dim stockpileName As String = NullValues.String
        Dim notes As String = NullValues.String
        Dim max_Tonnes As Double = NullValues.Double
        Dim reclaim_Start_Date As DateTime = NullValues.DateTime
        ' Exception raised in DAL when NullValues.String is used - DoNotSetValues.Char must be used to represent a null value.
        Dim reclaim_Start_Shift As String = DoNotSetValues.Char
        Dim completion_Description As String = NullValues.String
        Dim isInReports As Int16 = NullValues.Int16
        Dim isVisible As Boolean

        Dim is_Multi_Build As Boolean = False
        Dim is_Multi_Component As Boolean = False
        Dim update_stockpile_Name As Boolean = syncQueueChangedFields.Select("ChangedField = 'StockpileName'").Length > 0
        Dim update_Is_In_Reports As Boolean = syncQueueChangedFields.Select("ChangedField = 'IsInReports'").Length > 0
        Dim update_Description As Boolean = syncQueueChangedFields.Select("ChangedField = 'Description'").Length > 0
        Dim update_Is_Multi_Build As Boolean = False
        Dim update_Is_Multi_Component As Boolean = False
        Dim update_Material_Type_Id As Boolean = (syncQueueChangedFields.Select("ChangedField = 'Mine'").Length > 0) Or (syncQueueChangedFields.Select("ChangedField = 'MaterialType'").Length > 0)
        Dim update_Max_Tonnes As Boolean = False
        Dim update_Is_Visible As Boolean = syncQueueChangedFields.Select("ChangedField = 'IsVisible'").Length > 0
        Dim update_Start_Tonnes As Boolean = syncQueueChangedFields.Select("ChangedField = 'StartTonnes'").Length > 0
        Dim update_Start_Date As Boolean = syncQueueChangedFields.Select("ChangedField = 'StartDate'").Length > 0
        Dim update_Start_Shift As Boolean = syncQueueChangedFields.Select("ChangedField = 'StartShift'").Length > 0
        Dim update_End_Date As Boolean = syncQueueChangedFields.Select("ChangedField = 'EndDate'").Length > 0
        Dim update_End_Shift As Boolean = syncQueueChangedFields.Select("ChangedField = 'EndShift'").Length > 0
        Dim update_Stockpile_State_Id As Boolean = update_End_Date
        Dim update_Notes As Boolean = False
        Dim haulage_Raw_Resolve_All As Boolean = False
        Dim update_Reclaim_Start_Date As Boolean = False
        Dim update_Reclaim_Start_Shift As Boolean = False
        Dim update_Completion_Description As Boolean = False

        If dataTableName = "Stockpile" Then
            'set the Stockpile fields
            stockpileId = Convert.ToInt32(destinationRow("StockpileId"))

            isInReports = Convert.ToInt16(IfDBNull(sourceRow("IsInReports"), NullValues.Int16))
            isVisible = Convert.ToBoolean(sourceRow("IsVisible"))

            systemStartDate = GetSystemStartDateFromCache()
            startDate = Convert.ToDateTime(IfDBNull(sourceRow("StartDate"), systemStartDate.Value))
            If startDate < systemStartDate Then
                startDate = systemStartDate.Value
            End If
            startShift = Convert.ToString(IfDBNull(sourceRow("StartShift"), DoNotSetValues.String))
            If Not String.IsNullOrEmpty(startShift) Then
                startShift = startShift.Substring(0, 1)
            End If

            endDate = Convert.ToDateTime(IfDBNull(sourceRow("EndDate"), DoNotSetValues.DateTime))
            endShift = Convert.ToString(IfDBNull(sourceRow("EndShift"), DoNotSetValues.String))
            If Not String.IsNullOrEmpty(endShift) Then
                endShift = endShift.Substring(0, 1)
            End If

            startTonnes = Convert.ToDouble(IIf(sourceRow("StartTonnes") Is DBNull.Value, 0.0, sourceRow("StartTonnes")))

            'determine an appropriate material type
            locationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("Mine"))).Value

            materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_normalMaterialCategoryId, Convert.ToString(sourceRow("MaterialType")), locationId)
            If Not materialTypeId.HasValue Then
                materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_miscategorisedMaterialCategoryId, _
                    Convert.ToString(sourceRow("MaterialType")), Nothing).Value
            End If

            If Not sourceRow("Description") Is DBNull.Value Then
                stockpileDescription = Convert.ToString(sourceRow("Description"))
            Else
                stockpileDescription = Nothing
            End If

            'set up stockpile state id
            If sourceRow("EndDate") Is DBNull.Value Then
                stockpileStateId = "NORMAL"
            Else
                stockpileStateId = "CLOSED"
            End If

            'update the Stockpile Record
            _stockpileDal.UpdateStockpile(stockpileId, Convert.ToInt16(update_stockpile_Name), stockpileName, _
             Convert.ToInt16(update_Description), stockpileDescription, Convert.ToInt16(update_Is_Multi_Build), _
             Convert.ToInt16(is_Multi_Build), Convert.ToInt16(update_Is_Multi_Component), Convert.ToInt16(is_Multi_Component), _
             Convert.ToInt16(update_Material_Type_Id), materialTypeId.Value, Convert.ToInt16(update_Is_In_Reports), _
             Convert.ToInt16(isInReports), Convert.ToInt16(update_Max_Tonnes), max_Tonnes, Convert.ToInt16(update_Is_Visible), _
             Convert.ToInt16(isVisible), Convert.ToInt16(update_Notes), notes, Convert.ToInt16(update_Start_Tonnes), _
             startTonnes, Convert.ToInt16(haulage_Raw_Resolve_All))

            ' only update the stockpile build if something significant has changed
            If (update_Stockpile_State_Id Or update_Start_Date Or update_Start_Shift Or update_Reclaim_Start_Date _
                Or update_Reclaim_Start_Shift Or update_End_Date Or update_End_Shift Or update_Completion_Description _
                Or haulage_Raw_Resolve_All) Then

                'Update the Stockpile Build Record
                _stockpileDal.UpdateStockpileBuild(stockpileId, _defaultBuildId, Convert.ToInt16(update_Stockpile_State_Id), _
                 stockpileStateId, Convert.ToInt16(update_Start_Date), startDate, Convert.ToInt16(update_Start_Shift), _
                 startShift, Convert.ToInt16(update_Reclaim_Start_Date), reclaim_Start_Date, Convert.ToInt16(update_Reclaim_Start_Shift), _
                 reclaim_Start_Shift, Convert.ToInt16(update_End_Date), endDate, Convert.ToInt16(update_End_Shift), endShift, _
                 Convert.ToInt16(update_Completion_Description), completion_Description, Convert.ToInt16(haulage_Raw_Resolve_All))

                ' We don't need to update the stockpilebuildcomponent explicitly here because it is done automatically when start tonnes changes (and no other relevant details can change through this import)
            End If

            If syncQueueChangedFields.Select("ChangedField = 'StockpileType'").Length > 0 Then
                _stockpileDal.AddOrUpdateStockpileNotes(stockpileId, Convert.ToString(sourceRow("StockpileType")), _stockpileTypeNotes, 1)

                'Checks to see if the stockpile is already in a group.
                ' if the stockpile is already in a group assume the original setting by the user, import, etc is correct and dont change it.
                ' This stockpile group code was only to assign the post crusher stockpiles automatically anyway, to limit the work required by the users in the UI.
                If _utilityDal.GetStockpileGroupStockpileList(NullValues.String, 1, stockpileId, DoNotSetValues.Boolean, NullValues.Int32, 1).Rows.Count = 0 Then
                    If Not (GetStockpileGroupMembership(Convert.ToString(sourceRow("StockpileType"))) Is Nothing) Then
                        _utilityDal.AddStockpileGroupStockpile(GetStockpileGroupMembership(Convert.ToString(sourceRow("StockpileType"))), stockpileId)
                    End If
                End If
            End If

            If syncQueueChangedFields.Select("ChangedField = 'ProductSize'").Length > 0 Then
                _stockpileDal.AddOrUpdateStockpileNotes(stockpileId, Convert.ToString(sourceRow("ProductSize")), _productSizeNotes, 1)
            End If

        ElseIf dataTableName = "StockpileGrade" Then
            'determine the appropriate relation name
            destinationStockpileRow = DirectCast(sourceRow.GetParentRow(_stockpileGradeRelationName)("DestinationRow"), DataRow)
            stockpileId = Convert.ToInt32(Convert.ToString(destinationStockpileRow("StockpileId")))
            gradeId = Convert.ToInt16(Convert.ToString(destinationStockpileRow("GradeId")))

            _stockpileDal.AddOrUpdateStockpileBuildComponentGrade(stockpileId, _defaultBuildId, _defaultComponentId, _
             gradeId, Convert.ToSingle(IfDBNull(sourceRow("Value"), NullValues.Single)))
        End If
    End Sub

    Protected Overrides Sub ProcessValidate(ByVal dataTableName As String, _
     ByVal sourceRow As System.Data.DataRow, _
     ByVal destinationRow As System.Data.DataRow, _
     ByVal importSyncValidate As System.Data.DataTable, _
     ByVal importSyncValidateField As System.Data.DataTable, _
     ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As System.Data.DataRow, _
     ByVal syncQueueChangedFields As System.Data.DataTable, _
     ByVal importSyncDal As Common.Import.Database.ImportSync)

        If dataTableName = "Stockpile" Then
            ProcessValidateStockpile(sourceRow, importSyncValidate, importSyncValidateField, syncQueueRow, syncAction)

        ElseIf dataTableName = "StockpileGrade" Then
            ProcessValidateStockpileGrade(sourceRow, importSyncValidate, importSyncValidateField, syncAction, syncQueueRow)
        End If
    End Sub

    Protected Function GetSystemStartDateFromCache() As Date?
        ' if the cached system start date was loaded more than the allowed cache time
        If (Not _cachedSystemStartDateLoaded.HasValue) OrElse (Date.Now.Subtract(_cachedSystemStartDateLoaded.Value).TotalMinutes > _systemStartDateAllowedCachingMinutes) Then
            ' clear out the value
            _cachedSystemStartDate = Nothing
        End If

        ' if there is no cached value
        If _cachedSystemStartDate Is Nothing Then
            ' get one
            Dim startDateString As String
            Dim startDate As DateTime

            startDateString = _utilityDal.GetSystemSetting("SYSTEM_START_DATE")
            If DateTime.TryParse(startDateString, startDate) Then
                _cachedSystemStartDate = startDate
                _cachedSystemStartDateLoaded = DateTime.Now
            End If
        End If

        Return _cachedSystemStartDate

    End Function

    ''' <summary>
    ''' Provides the source data required by the Stockpile import.
    ''' </summary>
    ''' <param name="sourceSchema">The required schema that is to be adhered to.</param>
    ''' <returns>A dataset matching the provided schema.</returns>
    ''' <remarks>
    ''' Loads the data in from one of two sources:
    ''' 1. The real web-service endpoint, or
    ''' 1. a dummy XML file that has been provided representing the actual payload.
    ''' </remarks>
    Protected Overrides Function LoadSource(ByVal sourceSchema As System.IO.StringReader) As System.Data.DataSet

        Dim returnDataSet As DataSet = Nothing

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A source schema must be provided.")
        End If

        returnDataSet = New DataSet()
        returnDataSet.ReadXmlSchema(sourceSchema)
        returnDataSet.EnforceConstraints = False

        'load the data into the supplied ADO.NET dataset
        LoadSourceFromWebService(Site, returnDataSet)

        If returnDataSet.Tables(0).Rows.Count = 0 Then
            Throw New InvalidOperationException("No stockpiles were returned by source system.  This is an indication of source system error rather than a true result.")
        End If

        'set all row versions as "unmodified"
        returnDataSet.AcceptChanges()

        'check that we actually have "clean" data (i.e. all fields conform to their respective data types); if not, fail the import
        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try

        Return returnDataSet
    End Function


    '''Private Methods

    Private Sub ProcessValidateStockpile(ByVal sourceRow As System.Data.DataRow, _
     ByVal importSyncValidate As System.Data.DataTable, _
     ByVal importSyncValidateField As System.Data.DataTable, _
     ByVal syncQueueRow As System.Data.DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration)

        Dim materialTypeId As Int32?
        Dim locationId As Int32?

        If syncAction = Data.SyncImportSyncActionEnumeration.Insert Or _
         syncAction = Data.SyncImportSyncActionEnumeration.Update Then

            'check that the site exists
            locationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("Mine")))

            If Not locationId.HasValue Then
                GeneralHelper.LogValidationError("The site/hub specified does not exist", _
                 "Site", syncQueueRow, importSyncValidate, importSyncValidateField)
            Else
                'validate the Material Type
                If Not sourceRow("MaterialType") Is DBNull.Value Then
                    materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_normalMaterialCategoryId, _
                     Convert.ToString(sourceRow("MaterialType")), locationId)

                    If Not materialTypeId.HasValue Then
                        materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(_miscategorisedMaterialCategoryId, _
                         Convert.ToString(sourceRow("MaterialType")), Nothing)
                    End If
                End If
                If Not materialTypeId.HasValue Then
                    GeneralHelper.LogValidationError("The Material Type must be provided and must be valid in the system", _
                     "MaterialType", syncQueueRow, importSyncValidate, importSyncValidateField)
                End If
            End If

            'Ensure the start date and start shift are specified
            If sourceRow("StartDate") Is DBNull.Value Then
                GeneralHelper.LogValidationError("The Start Date must be provided", _
                 "StartDate", syncQueueRow, importSyncValidate, importSyncValidateField)
            End If

            'Check that stockpile does not open and close on the same date and shift.
            If Not sourceRow("EndDate") Is DBNull.Value AndAlso _
             Not sourceRow("EndShift") Is DBNull.Value AndAlso _
             Not sourceRow("StartShift") Is DBNull.Value AndAlso _
             Not sourceRow("StartDate") Is DBNull.Value AndAlso _
             Convert.ToDateTime(sourceRow("EndDate")).Date.Equals(Convert.ToDateTime(sourceRow("StartDate")).Date) And _
             sourceRow("StartShift").Equals(sourceRow("EndShift")) Then
                GeneralHelper.LogValidationError("Stockpile cannot open and close on the same date/shift", _
                 New String() {"StartDate", "StartShift", "EndDate", "EndShift"}, _
                 syncQueueRow, importSyncValidate, importSyncValidateField)
            End If

            'Check that stockpile start date is not after the end date.
            If Not sourceRow("StartDate") Is DBNull.Value _
             AndAlso Not sourceRow("EndDate") Is DBNull.Value _
             AndAlso Convert.ToDateTime(sourceRow("StartDate")) > Convert.ToDateTime(sourceRow("EndDate")) Then
                GeneralHelper.LogValidationError("Stockpile start date is after the end date", _
                 New String() {"StartDate", "EndDate"}, syncQueueRow, importSyncValidate, importSyncValidateField)
            End If
        End If

        If syncAction = Data.SyncImportSyncActionEnumeration.Insert Then
            ' -------------
            ' The check to see whether an insert stockpile already exists is obsolete because ProcessInsert now handles this case
            ' -------------

            'check that the stockpile doesn't already exist
            'stockpileId = _stockpileDal.GetStockpileIdFromName(sourceRow("StockpileName").ToString)
            'If stockpileId <> NullValues.Int32 Then
            '    GeneralHelper.LogValidationError("Stockpile already exists in the system", _
            '     "StockpileName", syncQueueRow, importSyncValidate, importSyncValidateField)
            'End If
        End If
    End Sub

    Private Sub ProcessValidateStockpileGrade(ByVal sourceRow As DataRow, _
        ByVal importSyncValidate As DataTable, _
        ByVal importSyncValidateField As DataTable, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow)

        Dim importSyncValidateId As Long

        'check that the grade exists
        If syncAction = Data.SyncImportSyncActionEnumeration.Insert Then
            If Not ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).HasValue Then
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                 Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                 "Grade name does not exist.", "Grade name does not exist.")
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "GradeName")
            End If
        End If

        'check the grade value supplied is valid
        If syncAction = Data.SyncImportSyncActionEnumeration.Insert _
         OrElse syncAction = Data.SyncImportSyncActionEnumeration.Update Then
            If IfDBNull(sourceRow("Value"), _negativeValue) < 0 Then
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                 Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                 "Grade value was less than 0.", _
                 String.Format("Grade value was {0}.", sourceRow("Value")))
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Value")
            End If
        End If
    End Sub

    Private Function DoesStockpileTypeExist(ByVal stockpileTypeId As String) As Boolean
        Static stockpileTypeList As DataTable
        Dim stockpileTypes As DataRow()
        Dim result As Boolean

        If stockpileTypeList Is Nothing Then
            stockpileTypeList = _stockpileDal.GetStockpileTypeList()
        End If

        stockpileTypes = stockpileTypeList.Select(String.Format("Stockpile_Type_ID = '{0}'", stockpileTypeId))

        If stockpileTypes.Length = 0 Then
            result = False
        Else
            result = True
        End If

        Return result
    End Function

    Private Sub AddInitialGrades(ByVal stockpileId As Integer)
        Dim gradeData As DataTable = _utilityDal.GetGradeList(NullValues.Int16)
        Dim gradeRow As DataRow

        For Each gradeRow In gradeData.Rows
            _stockpileDal.AddOrUpdateStockpileBuildComponentGrade(stockpileId, _defaultBuildId, _defaultComponentId, Convert.ToInt16(gradeRow.Item("Grade_ID")), 0)
        Next
    End Sub

    Private Shared Function GetStockpileGroupMembership(ByVal stockpileType As String) As String
        'Interface returns initial details, only used for post crusher stockpiles

        If stockpileType = "Post Crusher" Then
            Return "Post Crusher"
        Else
            Return Nothing
        End If
    End Function

    Private Sub LoadSourceFromWebService(ByVal partitionSite As String, ByVal returnDataSet As DataSet)
        Dim mq2Client As MQ2Service.IM_MQ2_DS

        Dim retrieveStockpilesRequest1 As MQ2Service.retrieveStockpilesRequest1
        Dim stockpilesRequest As MQ2Service.RetrieveStockpilesRequest
        Dim retrieveStockpilesResponse1 As MQ2Service.retrieveStockpilesResponse1
        Dim stockpilesResponse As MQ2Service.RetrieveStockpilesResponse
        Dim index As Integer

        stockpilesRequest = New MQ2Service.RetrieveStockpilesRequest()
        stockpilesRequest.MineSiteCode = partitionSite

        Trace.WriteLine(String.Format("Loading from Web Service: Site = {0}", partitionSite))

        retrieveStockpilesRequest1 = New MQ2Service.retrieveStockpilesRequest1(stockpilesRequest)

        mq2Client = WebServicesFactory.CreateMQ2WebServiceClient()
        Try
            retrieveStockpilesResponse1 = mq2Client.retrieveStockpiles(retrieveStockpilesRequest1)
        Catch ex As Exception
            Throw New DataException("Error while retrieving stockpiles data from MQ2 web service.", ex)
        End Try

        stockpilesResponse = retrieveStockpilesResponse1.RetrieveStockpilesResponse

        If stockpilesResponse.Status.StatusFlag Then
            Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
        Else
            Throw New InvalidOperationException(String.Format("Error while receiving response (at {0}) with status message: {1}", _
                DateTime.Now.ToString("HH:mm:ss dd-MMM-yyyy"), stockpilesResponse.Status.StatusMessage))
        End If

        If Not stockpilesResponse.Stockpiles Is Nothing Then
            For index = 0 To stockpilesResponse.Stockpiles.Length - 1 Step 1
                LoadStockpileRecord(stockpilesResponse.Stockpiles(index), returnDataSet)
            Next
        End If

        'remove the rows marked as delete
        'note that nothing is being deleted! it's just for good practise to ensure it's clean when passed out
        returnDataSet.AcceptChanges()
    End Sub

    Private Sub LoadStockpileRecord(ByVal stockpileRecord As MQ2Service.StockpileType, ByVal returnDataSet As DataSet)
        Dim stockpilesTable As DataTable
        Dim stockpilesRow As DataRow
        Dim temp As Object

        stockpilesTable = returnDataSet.Tables("Stockpile")
        stockpilesRow = stockpilesTable.NewRow()

        stockpilesRow("StartShift") = _defaultShift
        stockpilesRow("EndShift") = _defaultShift
        stockpilesRow("EndDate") = DBNull.Value
        stockpilesRow("IsInReports") = Convert.ToInt16(False)
        stockpilesRow("StartTonnes") = 0

        stockpilesRow("StockpileGroup") = stockpileRecord.Name.ReadStringWithDbNull()
        stockpilesRow("StockpileName") = stockpileRecord.BusinessId.ReadStringWithDbNull()
        stockpilesRow("IsVisible") = stockpileRecord.Active.ReadStringAsBoolean()
        If Not stockpileRecord.Location Is Nothing Then
            stockpilesRow("Mine") = stockpileRecord.Location.Mine.ReadStringWithDbNull()
        End If
        stockpilesRow("StockpileType") = stockpileRecord.StockpileType1.ReadStringWithDbNull()
        stockpilesRow("Description") = stockpileRecord.Description.ReadStringWithDbNull()
        stockpilesRow("MaterialType") = stockpileRecord.OreType.ReadStringWithDbNull()
        temp = stockpileRecord.Type.ReadStringWithDbNull()
        If TypeOf temp Is String AndAlso Convert.ToString(temp) = "Weighted Avg" Then
            stockpilesRow("StockpileAlgorithm") = "Average"
        ElseIf temp Is Nothing Or DBNull.Value.Equals(temp) Then
            stockpilesRow("StockpileAlgorithm") = _defaultAlgorithm
        Else
            stockpilesRow("StockpileAlgorithm") = temp
        End If
        temp = stockpileRecord.StartDate.ReadAsDateTimeWithDbNull(stockpileRecord.StartDateSpecified)
        If TypeOf temp Is DateTime Then
            stockpilesRow("StartDate") = Convert.ToDateTime(temp).AddDays(-7)
        Else
            stockpilesRow("StartDate") = temp
        End If
        stockpilesRow("ProductSize") = stockpileRecord.ProductSize.ReadStringWithDbNull()

        'perform name translations as required
        stockpilesRow("StockpileName") = CodeTranslationHelper.RecodeTransaction(Convert.ToString(stockpilesRow("StockpileName")), Nothing, Site)

        'more Ajilon hacks - "NULLS" need to be turned back into ---
        If stockpilesRow("MaterialType") Is DBNull.Value Then
            stockpilesRow("MaterialType") = "---"
        End If

        stockpilesTable.Rows.Add(stockpilesRow)
    End Sub

End Class
