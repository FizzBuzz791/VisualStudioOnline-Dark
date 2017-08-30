Imports System.Text
Imports Snowden.Common.Import
Imports Snowden.Common.Database
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects
Imports Snowden.Common.Import.Data
Imports Snowden.Reconcilor.Core.Database.SqlDal

Friend NotInheritable Class StockpileAdjustment
    Inherits SyncImport

    Private Const _defaultShift As String = "D"
    Private Const _StockpileAdjustmentAlgorithm As String = "Unknown"
    Private Const _numberOfDaysPerWebRequest As Int32 = 15
    Private Const _defaultBuildId As Int32 = 1
    Private Const _defaultComponentId As Int32 = 1

    Private _settings As ConfigurationSettings
    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _site As String
    Private _stockpileDal As IStockpile
    Private _utilityDal As IUtility
    Private _bhpbioUtilityDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
    Private _disposed As Boolean

    Protected Property DateTo() As DateTime
        Get
            Return _dateTo
        End Get
        Set(ByVal value As DateTime)
            _dateTo = value
        End Set
    End Property

    Protected Property DateFrom() As DateTime
        Get
            Return _dateFrom
        End Get
        Set(ByVal value As DateTime)
            _dateFrom = value
        End Set
    End Property

    Protected Property Site() As String
        Get
            Return _site
        End Get
        Set(ByVal value As String)
            _site = value
        End Set
    End Property

    Public Sub New(Optional config As ConfigurationSettings = Nothing)
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Stockpile Adjustment"
        SourceSchemaName = "StockpileAdjustment"
        CanGenerateSourceSchema = True
        _settings = ConfigurationSettings.GetConfigurationSettings(config)
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
                    If (Not _bhpbioUtilityDal Is Nothing) Then
                        _bhpbioUtilityDal.Dispose()
                        _bhpbioUtilityDal = Nothing
                    End If
                End If
            End If

            _disposed = True
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Protected Overrides Sub SetupDataAccessObjects()
        _stockpileDal = New SqlDalStockpile(ImportSyncDal.DataAccess.DataAccessConnection)
        _utilityDal = New SqlDalUtility(ImportSyncDal.DataAccess.DataAccessConnection)
        _bhpbioUtilityDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(ImportSyncDal.DataAccess.DataAccessConnection)

        ReferenceDataCachedHelper.UtilityDal = _bhpbioUtilityDal
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As IDictionary(Of String, String), ByVal validationMessage As StringBuilder) As Boolean
        Dim validates As Boolean = True

        'check the standard date parameters
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, validates))

        'check the site parameter
        If validates Then
            If Not parameters.ContainsKey("Site") Then
                validates = False
                validationMessage.Append("Cannot find the Site parameter.")

            ElseIf parameters("Site") = Nothing Then
                validates = False
                validationMessage.Append("The Site parameter must not be blank.")
            End If
        End If

        Return validates
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As IDictionary(Of String, String))
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)
        _site = CodeTranslationHelper.SingleSiteCodeFromReconcilor(parameters("Site"), toShortCode:=True)
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As DataRow) As Boolean
        Dim stockpileAdjustmentDate As DateTime

        'all tables have the HaulageDate and Mine column - these can be used to partition accordingly
        stockpileAdjustmentDate = Convert.ToDateTime(keyRows("StockpileAdjustmentDate"))

        Return (_site Is Nothing OrElse _site.ToUpper = Convert.ToString(keyRows("Mine")).ToUpper) _
               AndAlso ((stockpileAdjustmentDate >= _dateFrom) And (stockpileAdjustmentDate <= _dateTo))
    End Function

    Protected Overrides Sub PostCompare()
        ' do nothing
    End Sub

    Protected Overrides Sub PreCompare()
        ' do nothing
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
    End Sub

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)
    End Sub

    Protected Overrides Sub ProcessConflict(ByVal dataTableName As String, ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
        ByVal importSyncConflict As DataTable, ByVal importSyncConflictField As DataTable, ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, ByVal syncQueueChangedFields As DataTable, ByVal importSyncDal As ImportSync)

        Dim stockpileId As Int32
        Dim stockpileAdjustmentDate As DateTime
        Dim stockpileAdjustments As DataTable

        If dataTableName.ToLower <> "stockpileadjustmentgrade" And syncAction = SyncImportSyncActionEnumeration.Insert Then
            'check that the stockpile adjustment is unique for thie stockpile/date/shift
            stockpileAdjustmentDate = Convert.ToDateTime(sourceRow("StockpileAdjustmentDate"))
            stockpileId = _stockpileDal.GetStockpileIdFromName(sourceRow("StockpileName").ToString)

            stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, stockpileAdjustmentDate, _
                DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

            If stockpileAdjustments.Rows.Count <> 0 Then
                GeneralHelper.LogConflict("There is already an adjustment on this date/shift for this Stockpile.", _
                    New String() {"StockpileName", "StockpileAdjustmentDate"}, syncQueueRow, importSyncConflict, importSyncConflictField)
            End If
        End If
    End Sub

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, ByVal importSyncDal As ImportSync)

        Dim stockpileAdjustmentId As Int32
        Dim stockpileAdjustments As DataTable
        Dim stockpileId As Int32
        Dim stockpileAdjustmentDate As DateTime
        Dim stockpileAdjustmentShift As String
        Dim gradeId As Short

        stockpileId = _stockpileDal.GetStockpileIdFromName(Convert.ToString(sourceRow("StockpileName")))
        stockpileAdjustmentShift = Convert.ToString(sourceRow("StockpileAdjustmentShift"))
        stockpileAdjustmentDate = Convert.ToDateTime(sourceRow("StockpileAdjustmentDate"))

        stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, _
                                                                         stockpileAdjustmentDate, DoNotSetValues.Int16, _
                                                                         stockpileId, _
                                                                         DoNotSetValues.Int32, DoNotSetValues.Int32, _
                                                                         DoNotSetValues.Int32)

        If stockpileAdjustments.Rows.Count = 0 Then
            Throw New ArgumentException(String.Format( _
                "Cannot delete Stockpile Adjustment for stockpile '{0}' as the adjustment does not exist.", sourceRow("StockpileName")))
        Else
            stockpileAdjustmentId = Convert.ToInt32(stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id"))

            If dataTableName.ToLower = "stockpileadjustmentgrade" Then

                gradeId = ReferenceDataCachedHelper.GetGradeId(Convert.ToString(sourceRow("GradeName"))).Value
                _stockpileDal.AddOrUpdateStockpileAdjustmentGrade(stockpileAdjustmentId, gradeId, NullValues.Single)

                stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, stockpileAdjustmentDate, _
                    DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

                'Check if there are any grades left on this adjustment.
                If Not ((stockpileAdjustments.Rows(0).Table.Columns.Contains("Fe") AndAlso _
                    Not stockpileAdjustments.Rows(0)("Fe") Is DBNull.Value) Or _
                    (stockpileAdjustments.Rows(0).Table.Columns.Contains("P") AndAlso _
                    Not stockpileAdjustments.Rows(0)("P") Is DBNull.Value) Or _
                    (stockpileAdjustments.Rows(0).Table.Columns.Contains("SiO2") AndAlso _
                    Not stockpileAdjustments.Rows(0)("SiO2") Is DBNull.Value) Or _
                    (stockpileAdjustments.Rows(0).Table.Columns.Contains("Al2O3") AndAlso _
                    Not stockpileAdjustments.Rows(0)("Al2O3") Is DBNull.Value) Or _
                    (stockpileAdjustments.Rows(0).Table.Columns.Contains("LOI") AndAlso _
                    Not stockpileAdjustments.Rows(0)("LOI") Is DBNull.Value)) Then

                    'If there are no grades left on this adjustment then set the is grades adjustment flag to false
                    _stockpileDal.UpdateStockpileAdjustment(stockpileAdjustmentId, stockpileId, _defaultBuildId, stockpileAdjustmentDate, _
                        stockpileAdjustmentShift, "MQ2 Imported Adjustment", Convert.ToInt16(True), Convert.ToInt16(True), _
                        Convert.ToInt16(False), NullValues.Double, _defaultComponentId, Convert.ToInt16(False), _
                        DoNotSetValues.Int32, Convert.ToInt16(False), DoNotSetValues.Int32, DoNotSetValues.Int32, Convert.ToInt16(False))
                End If
            Else
                _stockpileDal.DeleteStockpileAdjustment(stockpileAdjustmentId)
            End If
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, ByVal syncQueueRow As DataRow, ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim stockpileAdjustmentId As Int32
        Dim stockpileId As Int32
        Dim stockpileAdjustmentDate As DateTime
        Dim stockpileAdjustmentShift As String
        Dim stockpileAdjustmentTonnes As Double
        Dim gradeId As Short
        Dim gradeValue As Single
        Dim stockpileAdjustments As DataTable

        stockpileId = _stockpileDal.GetStockpileIdFromName(sourceRow("StockpileName").ToString)

        If stockpileId = NullValues.Int32 Then
            Throw New ArgumentException(String.Format( _
                "Stockpile with stockpile name '{0}' does not exist in Reconcilor.", sourceRow("StockpileName")))
        End If

        If Not (sourceRow("StockpileAdjustmentDate") Is Nothing) Then
            If Not (DateTime.TryParse(sourceRow("StockpileAdjustmentDate").ToString, stockpileAdjustmentDate)) Then
                Throw New InvalidCastException("StockpileAdjustmentDate field cannot be parsed as a DateTime type.")
            End If
        Else
            Throw New NullReferenceException("StockpileAdjustmentDate is null.")
        End If

        If Not (sourceRow("StockpileAdjustmentShift") Is Nothing) Then
            stockpileAdjustmentShift = sourceRow("StockpileAdjustmentShift").ToString
        Else
            Throw New NullReferenceException("StockpileAdjustmentShift is null.")
        End If

        Dim stockpileAdjustmentType As String = String.Empty
        If Not (sourceRow("StockpileAdjustmentType") Is Nothing) Then
            stockpileAdjustmentType = sourceRow("StockpileAdjustmentType").ToString
        Else
            Throw New NullReferenceException("StockpileAdjustmentType is null.")
        End If

        'If this is a grade  
        If dataTableName.ToLower = "stockpileadjustmentgrade" Then

            stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, stockpileAdjustmentDate, _
                DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

            If stockpileAdjustments.Rows.Count = 0 Then
                Throw New ArgumentException(String.Format( _
                    "Cannot update adjustment with grades for stockpile name '{0}' because no adjustments exist.", sourceRow("StockpileName")))
            Else
                If Not (stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id") Is Nothing) Then
                    If Not (Int32.TryParse(stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id").ToString, stockpileAdjustmentId)) Then
                        Throw New InvalidCastException("StockpileAdjustmentId cannot be parsed as an Int32 type.")
                    End If
                Else
                    Throw New NullReferenceException("StockpileAdjustmentId is null.")
                End If

                stockpileAdjustmentTonnes = 0
                Double.TryParse(stockpileAdjustments.Rows(0)("Tonnes").ToString, stockpileAdjustmentTonnes)
                Trace.WriteLine(String.Format("Stockpile Adjustment Tonnes: {0}", stockpileAdjustmentTonnes))

                If Not (sourceRow("GradeName") Is Nothing) Then
                    gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).Value
                Else
                    Throw New NullReferenceException("GradeName is null.")
                End If

                If Not (sourceRow("GradeValue") Is Nothing) Then
                    If Not (Single.TryParse(sourceRow("GradeValue").ToString, gradeValue)) Then
                        Throw New InvalidCastException("GradeValue cannot be parsed as Single type.")
                    End If
                Else
                    Throw New NullReferenceException("GradeValue is null.")
                End If

                _stockpileDal.AddOrUpdateStockpileAdjustmentGrade(stockpileAdjustmentId, gradeId, gradeValue)
                'If this has grades make sure we set the is grade adjustment flag.
                _stockpileDal.UpdateStockpileAdjustment(stockpileAdjustmentId, stockpileId, _defaultBuildId, stockpileAdjustmentDate, _
                    stockpileAdjustmentShift, "MQ2 Imported Adjustment", Convert.ToInt16(True), Convert.ToInt16(True), _
                    Convert.ToInt16(True), stockpileAdjustmentTonnes, _defaultComponentId, Convert.ToInt16(False), _
                    DoNotSetValues.Int32, Convert.ToInt16(False), DoNotSetValues.Int32, DoNotSetValues.Int32, Convert.ToInt16(False))
            End If
        End If

        ' if this is tonnes 
        If dataTableName.ToLower = "stockpileadjustment" Then

            If Not (sourceRow("StockpileAdjustmentTonnes") Is Nothing) Then
                If Not (Double.TryParse(sourceRow("StockpileAdjustmentTonnes").ToString, stockpileAdjustmentTonnes)) Then
                    Throw New InvalidCastException("StockpileAdjustmentTonnes cannot be parsed as a Double type: StockpileAdjustment")
                End If
            Else
                Throw New NullReferenceException("StockpileAdjustmentTonnes is null: StockpileAdjustment")
            End If

            If (stockpileAdjustmentType = "-") Then
                stockpileAdjustmentTonnes *= -1
            End If

            'Initially Is_Grades_Adjustment will be set to false until a grade is added to stockpile adjustment grade.
            stockpileAdjustmentId = _stockpileDal.AddStockpileAdjustment(stockpileId, _defaultBuildId, stockpileAdjustmentDate, _
                stockpileAdjustmentShift, "MQ2 Imported Adjustment", Convert.ToInt16(True), Convert.ToInt16(True), _
                Convert.ToInt16(False), stockpileAdjustmentTonnes, _defaultComponentId, Convert.ToInt16(False), _
                DoNotSetValues.Int32, Convert.ToInt16(False), DoNotSetValues.Int32, DoNotSetValues.Int32, Convert.ToInt16(False))

            'write back the adjustment id
            DataHelper.AddTableColumn(destinationRow.Table, "StockpileAdjustmentId", GetType(String), Nothing)
            destinationRow("StockpileAdjustmentId") = stockpileAdjustmentId.ToString
        End If
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, ByVal syncQueueRow As DataRow, ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim stockpileAdjustmentId As Int32
        Dim stockpileId As Int32
        Dim stockpileAdjustmentDate As DateTime
        Dim stockpileAdjustmentShift As String
        Dim stockpileAdjustmentTonnes As Double
        Dim gradeId As Short
        Dim gradeValue As Single
        Dim stockpileAdjustments As DataTable

        stockpileId = _stockpileDal.GetStockpileIdFromName(sourceRow("StockpileName").ToString)

        If stockpileId = NullValues.Int32 Then
            Throw New ArgumentException(String.Format( _
                "Stockpile with stockpile name '{0}' does not exist in Reconcilor.", sourceRow("StockpileName")))
        End If

        If Not (sourceRow("StockpileAdjustmentDate") Is Nothing) Then
            If Not (DateTime.TryParse(sourceRow("StockpileAdjustmentDate").ToString, stockpileAdjustmentDate)) Then
                Throw New InvalidCastException("StockpileAdjustmentDate cannot be parsed as DateTime type.")
            End If
        Else
            Throw New NullReferenceException("StockpileAdjustmentDate is null.")
        End If

        If Not (sourceRow("StockpileAdjustmentShift") Is Nothing) Then
            stockpileAdjustmentShift = sourceRow("StockpileAdjustmentShift").ToString
        Else
            Throw New NullReferenceException("StockpileAdjustmentShift is null.")
        End If

        Dim stockpileAdjustmentType As String = String.Empty
        If Not (sourceRow("StockpileAdjustmentType") Is Nothing) Then
            stockpileAdjustmentType = sourceRow("StockpileAdjustmentType").ToString
        Else
            Throw New NullReferenceException("StockpileAdjustmentType is null.")
        End If

        'If this is a grade  
        If dataTableName.ToLower = "stockpileadjustmentgrade" Then

            stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, stockpileAdjustmentDate, _
                DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

            If stockpileAdjustments.Rows.Count = 0 Then
                Throw New ArgumentException(String.Format( _
                    "Cannot update Stockpile Adjustment for '{0}' with grades as the adjustment does not exist.", sourceRow("StockpileName")))
            Else
                If Not (stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id") Is Nothing) Then
                    If Not (Int32.TryParse(stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id").ToString, stockpileAdjustmentId)) Then
                        Throw New InvalidCastException("StockpileAdjustmentId cannot be cast as Int32 type.")
                    End If
                Else
                    Throw New NullReferenceException("StockpileAdjustmentId is null.")
                End If

                stockpileAdjustmentTonnes = 0
                Double.TryParse(stockpileAdjustments.Rows(0)("Tonnes").ToString, stockpileAdjustmentTonnes)
                Trace.WriteLine(String.Format("Stockpile Adjustment Tonnes: {0}", stockpileAdjustmentTonnes))

                If Not (sourceRow("GradeName") Is Nothing) Then
                    gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).Value
                Else
                    Throw New NullReferenceException("GradeName is null")
                End If

                If Not (sourceRow("GradeValue") Is Nothing) Then
                    If Not (Single.TryParse(sourceRow("GradeValue").ToString, gradeValue)) Then
                        Throw New InvalidCastException("GradeValue cannot be cast as Single type.")
                    End If
                Else
                    Throw New NullReferenceException("GradeValue is null.")
                End If

                _stockpileDal.AddOrUpdateStockpileAdjustmentGrade(stockpileAdjustmentId, _
                                                                   gradeId, gradeValue)
                'If this has grades make sure we set the is grade adjustment flag.
                _stockpileDal.UpdateStockpileAdjustment(stockpileAdjustmentId, stockpileId, _defaultBuildId, stockpileAdjustmentDate, _
                    stockpileAdjustmentShift, "MQ2 Imported Adjustment", Convert.ToInt16(True), Convert.ToInt16(True), _
                    Convert.ToInt16(True), stockpileAdjustmentTonnes, _defaultComponentId, Convert.ToInt16(False), _
                    DoNotSetValues.Int32, Convert.ToInt16(False), DoNotSetValues.Int32, DoNotSetValues.Int32, Convert.ToInt16(False))
            End If
        End If

        ' if this is tonnes 
        If dataTableName.ToLower = "stockpileadjustment" Then

            stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList(stockpileAdjustmentDate, stockpileAdjustmentDate, _
                DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

            If stockpileAdjustments.Rows.Count = 0 Then
                If Not (sourceRow("StockpileName") Is Nothing) Then
                    Throw New NullReferenceException("StockpileName is null.")
                Else
                    Throw New ArgumentException(String.Format( _
                        "Cannot update Stockpile Adjustment for  '{0}' with grades as the adjustment does not exist.", sourceRow("StockpileName")))
                End If
            Else
                If Not (stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id") Is Nothing) Then
                    If Not (Int32.TryParse(stockpileAdjustments.Rows(0)("Stockpile_Adjustment_Id").ToString, stockpileAdjustmentId)) Then
                        Throw New InvalidCastException("StockpileAdjustmentId cannot be cast as Int32 type.")
                    End If
                Else
                    Throw New NullReferenceException("StockpileAdjustmentId is null.")
                End If

                If Not (sourceRow("StockpileAdjustmentTonnes") Is Nothing) Then
                    If Not (Double.TryParse(sourceRow("StockpileAdjustmentTonnes").ToString, stockpileAdjustmentTonnes)) Then
                        Throw New InvalidCastException("StockpileAdjustmentTonnes cannot be cast as Double type: StockPileAdjustment")
                    End If
                Else
                    Throw New NullReferenceException("StockpileAdjustmentTonnes is null: StockpileAdjustment")
                End If

                If (stockpileAdjustmentType = "-") Then
                    stockpileAdjustmentTonnes *= -1
                End If

                'Initially Is_Grades_Adjustment will be set to false until a grade is added to stockpile adjustment grade.
                _stockpileDal.UpdateStockpileAdjustment(stockpileAdjustmentId, stockpileId, _defaultBuildId, stockpileAdjustmentDate, _
                    stockpileAdjustmentShift, "MQ2 Imported Adjustment", Convert.ToInt16(True), Convert.ToInt16(True), Convert.ToInt16(False), _
                    stockpileAdjustmentTonnes, _defaultComponentId, Convert.ToInt16(False), DoNotSetValues.Int32, Convert.ToInt16(False), _
                    DoNotSetValues.Int32, DoNotSetValues.Int32, Convert.ToInt16(False))

                'write back the adjustment id
                DataHelper.AddTableColumn(destinationRow.Table, "StockpileAdjustmentId", GetType(String), Nothing)
                destinationRow("StockpileAdjustmentId") = stockpileAdjustmentId.ToString
            End If
        End If
    End Sub

    Protected Overrides Sub ProcessValidate(ByVal dataTableName As String, ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
        ByVal importSyncValidate As DataTable, ByVal importSyncValidateField As DataTable, ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, ByVal syncQueueChangedFields As DataTable, ByVal importSyncDal As ImportSync)

        Dim importSyncValidateId As Long
        Dim userMessage As String
        Dim stockpileId As Int32
        Dim stockpile As DataTable
        Dim stockpileStartDate As DateTime
        Dim stockpileEndDate As DateTime
        Dim stockpileAdjustmentDate As DateTime
        Dim stockpileAdjustments As DataTable


        If dataTableName.ToLower = "stockpileadjustmentgrade" Then

            If Convert.ToSingle(sourceRow("GradeValue")) < 0 Then
                userMessage = "Negative grade value"
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "GradeValue")
            End If

        Else
            If syncAction = SyncImportSyncActionEnumeration.Insert Then
                'check that the type is either + or -
                If Convert.ToString(sourceRow("StockpileAdjustmentType")) <> "-" And _
                   Convert.ToString(sourceRow("StockpileAdjustmentType")) <> "+" Then
                    userMessage = "Unrecognised Stockpile Adjustment Type, must be '+' or '-'."
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileAdjustmentType")
                End If

                'ensure that a tonnes value is given
                If sourceRow("StockpileAdjustmentTonnes") Is DBNull.Value _
                   Or Convert.ToDouble(sourceRow("StockpileAdjustmentTonnes")) = 0.0 Then
                    userMessage = "Tonnes cannot be zero for a delta adjustment."
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileAdjustmentTonnes")
                End If

                'ensure that the Stockpile exists
                stockpileId = _stockpileDal.GetStockpileIdFromName(Convert.ToString(sourceRow("StockpileName")))
                If stockpileId = NullValues.Int32 Then
                    userMessage = "Stockpile does not exist."
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileName")
                Else
                    stockpileId = _stockpileDal.GetStockpileIdFromName(sourceRow("StockpileName").ToString)

                    If stockpileId = NullValues.Int32 Then
                        stockpileAdjustments = _stockpileDal.GetStockpileAdjustmentList( _
                            Convert.ToDateTime(sourceRow("StockpileAdjustmentDate")), _
                            Convert.ToDateTime(sourceRow("StockpileAdjustmentDate")), _
                            DoNotSetValues.Int16, stockpileId, DoNotSetValues.Int32, DoNotSetValues.Int32, DoNotSetValues.Int32)

                        If stockpileAdjustments.Rows.Count <> 0 Then
                            userMessage = "A Stockpile Adjustment already exists on this date/shift for this stockpile."
                            importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                                Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                        End If
                    End If
                End If

                'ensure the adjustment date is specified
                If sourceRow("StockpileAdjustmentDate") Is DBNull.Value Then
                    userMessage = "Adjustment date can not be null."
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileAdjustmentDate")
                End If

                'ensure the adjustment date is between the start and end date for the stockpile
                If stockpileId <> NullValues.Int32 Then
                    'already know stockpile exists - get start and end dates
                    stockpile = _stockpileDal.GetStockpileBuild(stockpileId, _defaultBuildId)
                    stockpileStartDate = Convert.ToDateTime(stockpile.Rows(0)("Start_Date"))
                    stockpileAdjustmentDate = Convert.ToDateTime(sourceRow("StockpileAdjustmentDate"))

                    If stockpileAdjustmentDate < stockpileStartDate Then
                        userMessage = "Adjustment cannot be before the stockpile start date."
                        importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                            Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                        SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileAdjustmentDate")
                    End If

                    If Not stockpile.Rows(0)("End_Date") Is DBNull.Value Then
                        stockpileEndDate = Convert.ToDateTime(stockpile.Rows(0)("End_Date"))
                        If stockpileAdjustmentDate > stockpileEndDate Then
                            userMessage = "Adjustment cannot be after the stockpile end date."
                            importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                                Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), userMessage, userMessage)
                            SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "StockpileAdjustmentDate")
                        End If
                    End If
                End If
            End If
        End If
    End Sub

    ''' <summary>
    ''' Provides the source data required by the StockpileAdjustment import.
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
        LoadSourceFromWebService(DateFrom, DateTo, Site, returnDataSet)

        returnDataSet.AcceptChanges()

        'check that we actually have "clean" data (i.e. all fields conform to their respective data types); if not, fail the import
        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try

        Return returnDataSet
    End Function

    ''' <summary>
    ''' Invokes the Web Service specified; functionality currently stubbed.
    ''' </summary>
    ''' <param name="webServiceUri"></param>
    ''' <param name="returnDataSet"></param>
    ''' <remarks></remarks>
    Private Sub LoadSourceFromWebService(ByVal partitionDateFrom As Date, ByVal partitionDateTo As Date, _
     ByVal partitionMine As String, ByVal returnDataSet As DataSet)

        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime
        Dim mq2Client As MQ2Service.IM_MQ2_DS

        Dim retrieveAdjustmentRequest1 As MQ2Service.retrieveStockpileAdjustmentsRequest1
        Dim adjustmentRequest As MQ2Service.RetrieveStockpileAdjustmentsRequest
        Dim retrieveAdjustmentResponse1 As MQ2Service.retrieveStockpileAdjustmentsResponse1
        Dim adjustmentResponse As MQ2Service.RetrieveStockpileAdjustmentsResponse
        Dim index As Integer

        adjustmentRequest = New MQ2Service.RetrieveStockpileAdjustmentsRequest()
        adjustmentRequest.StartDateSpecified = True
        adjustmentRequest.EndDateSpecified = True
        adjustmentRequest.MineSiteCode = partitionMine

        mq2Client = WebServicesFactory.CreateMQ2WebServiceClient()

        Trace.WriteLine(String.Format("Loading from Web Service: Site = {0}, From = {1:dd-MMM-yyyy}, To = {2:dd-MMM-yyyy}", partitionMine, partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddDays(_numberOfDaysPerWebRequest)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine(String.Format("Requesting: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy} at {2:HH:mm:ss dd-MMM-yyyy}", currentDateFrom, currentDateTo, DateTime.Now))

            adjustmentRequest.StartDate = currentDateFrom.ToUniversalTime()
            adjustmentRequest.EndDate = currentDateTo.ToUniversalTime()

            retrieveAdjustmentRequest1 = New MQ2Service.retrieveStockpileAdjustmentsRequest1(adjustmentRequest)
            Try
                retrieveAdjustmentResponse1 = mq2Client.retrieveStockpileAdjustments(retrieveAdjustmentRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving stockpile adjustments data from MQ2 web service.", ex)
            End Try

            adjustmentResponse = retrieveAdjustmentResponse1.RetrieveStockpileAdjustmentsResponse

            If adjustmentResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    DateTime.Now, adjustmentResponse.Status.StatusMessage))
            End If

            If Not adjustmentResponse.StockpileAdjustment Is Nothing Then
                For index = 0 To adjustmentResponse.StockpileAdjustment.Length - 1
                    LoadStockpileAdjustmentsRecord(adjustmentResponse.StockpileAdjustment(index), returnDataSet, partitionMine)
                Next
            End If

            'increment the date range
            currentDateFrom = currentDateTo.AddDays(1)
            currentDateTo = currentDateFrom.AddDays(_numberOfDaysPerWebRequest)
            If currentDateTo >= partitionDateTo Then
                currentDateTo = partitionDateTo
            End If
        End While

        'remove the rows marked as delete
        'note that nothing is being deleted! it's just for good practise to ensure it's clean when passed out
        returnDataSet.AcceptChanges()
    End Sub

    Private Shared Sub LoadStockpileAdjustmentsRecord(ByVal stockpileAdjustment As MQ2Service.AdjustmentType, ByVal returnDataSet As DataSet, ByVal site As String)
        Dim adjustmentTable As DataTable
        Dim adjustmentGradeTable As DataTable
        Dim adjustmentRows() As DataRow
        Dim adjustmentRow As DataRow
        Dim existingType As String
        Dim existingTonnes As Double
        Dim existingCalcTonnes As Double
        Dim newType As String
        Dim newTonnes As Double
        Dim newCalcTonnes As Double
        Dim grades As New Dictionary(Of String, Single)
        Dim gradeToMassAverageLamda As String
        Dim massAveragedGrade As Single
        Dim existingGradeRows As IEnumerable(Of DataRow)
        Dim stockpileAdjustmentGradeRow As DataRow

        adjustmentTable = returnDataSet.Tables("StockpileAdjustment")
        adjustmentGradeTable = returnDataSet.Tables("StockpileAdjustmentGrade")
        adjustmentRow = adjustmentTable.NewRow()

        If Not stockpileAdjustment.Location Is Nothing Then
            adjustmentRow("Mine") = stockpileAdjustment.Location.Mine.ReadStringWithDbNull()
        End If
        adjustmentRow("StockpileName") = stockpileAdjustment.StockpileID.ReadStringWithDbNull()
        adjustmentRow("StockpileAdjustmentType") = stockpileAdjustment.AdjustmentType1.ReadStringWithDbNull()
        adjustmentRow("StockpileAdjustmentDate") = stockpileAdjustment.AdjustmentDate.ReadAsDateWithDbNull(stockpileAdjustment.AdjustmentDateSpecified)
        adjustmentRow("StockpileAdjustmentTonnes") = stockpileAdjustment.Tonnes.ReadAsDoubleWithDbNull(stockpileAdjustment.TonnesSpecified)
        adjustmentRow("StockpileAdjustmentShift") = _defaultShift

        'the following fields are provided by the web service, but there are no business rules associated with them:
        'adjustmentRow("Bcm") = stockpileAdjustment.Bcm.ReadAsDoubleWithDbNull(stockpileAdjustment.BcmSpecified)
        'adjustmentRow("FinesTonnes") = stockpileAdjustment.FinesTonnes.ReadAsDoubleWithDbNull(stockpileAdjustment.FinesTonnesSpecified)
        'adjustmentRow("LumpTonnes") = stockpileAdjustment.LumpTonnes.ReadAsDoubleWithDbNull(stockpileAdjustment.LumpTonnesSpecified)
        'adjustmentRow("LastModifiedTime") = stockpileAdjustment.LastModifiedTime.ReadAsDateTimeWithDbNull(stockpileAdjustment.LastModifiedTimeSpecified)

        If TypeOf stockpileAdjustment.StockpileID Is String Then
            'perform name translations as required
            adjustmentRow("StockpileName") = CodeTranslationHelper.RecodeTransaction(Convert.ToString(adjustmentRow("StockpileName")), Nothing, site)
        End If

        ' check for exsiting adjustment on the same date and shift for this stockpile (only one adjustment is allowed)
        If TypeOf adjustmentRow("StockpileName") Is String _
         AndAlso TypeOf adjustmentRow("StockpileAdjustmentDate") Is DateTime Then
            'look for an existing adjustment - if one is available then aggregate
            'keys: Mine, StockpileName, StockpileAdjustmentDate 
            'note that StockpileAdjustmentShift is always the same value
            adjustmentRows = adjustmentTable.Select(String.Format( _
                "Mine = '{0}' AND StockpileName = '{1}' AND StockpileAdjustmentDate = #{2}#", _
                adjustmentRow("Mine").ToString(), adjustmentRow("StockpileName").ToString(), _
                Convert.ToDateTime(adjustmentRow("StockpileAdjustmentDate")).ToString("O")))
        Else
            adjustmentRows = Nothing
        End If

        If adjustmentRows Is Nothing OrElse adjustmentRows.Count = 0 Then

            adjustmentTable.Rows.Add(adjustmentRow)
            AddAdjustmentGrades(stockpileAdjustment, adjustmentGradeTable, adjustmentRow)

        Else

            'Reassign the pointer
            adjustmentRow = adjustmentRows(0)

            'calculate the new tonnes natively by adding the two together
            If Not adjustmentRow("StockpileAdjustmentTonnes") Is System.DBNull.Value AndAlso _
                Not adjustmentRow("StockpileAdjustmentType") Is System.DBNull.Value AndAlso _
                Not stockpileAdjustment.AdjustmentType1.ReadStringWithDbNull() Is System.DBNull.Value AndAlso _
                Not stockpileAdjustment.Tonnes.ReadAsDoubleWithDbNull(stockpileAdjustment.TonnesSpecified) Is System.DBNull.Value Then

                'load the existing tonnes / type
                existingTonnes = Convert.ToDouble(adjustmentRow("StockpileAdjustmentTonnes"))
                existingType = adjustmentRow("StockpileAdjustmentType").ToString

                existingTonnes = existingTonnes * Convert.ToDouble(IIf(existingType = "-", -1.0, 1.0))
                existingCalcTonnes = Convert.ToDouble(IIf(existingTonnes < 0, 0, existingTonnes))

                newTonnes = Convert.ToDouble(stockpileAdjustment.Tonnes)
                newType = stockpileAdjustment.AdjustmentType1.ToString

                newTonnes = newTonnes * Convert.ToDouble(IIf(newType = "-", -1.0, 1.0))
                newCalcTonnes = Convert.ToDouble(IIf(newTonnes < 0, 0, newTonnes))

                ' sum the existing and new tonnes to generate a new adjustment tonnes
                newTonnes = existingTonnes + newTonnes

                'save the result
                adjustmentRow("StockpileAdjustmentType") = IIf(newTonnes < 0.0, "-", "+")
                adjustmentRow("StockpileAdjustmentTonnes") = Math.Abs(newTonnes)

                'delete the record if they end up cancelling each other out
                'otherwise add the relevant grade rows, mass averaging them as we go.
                If (newTonnes = 0.0) Then
                    adjustmentRow.Delete()
                Else
                    'Pickup the relevant grade names.
                    For Each gradeToMassAverage As String In grades.Keys.ToList().Union( _
                        adjustmentRow.GetChildRows("FK_StockpileAdjustment_StockpileAdjustmentGrade"). _
                            ToDictionary(Function(f) DirectCast(f.Item("GradeName"), String)).Keys.ToList)

                        'Code analysis reports problems with local loop variables
                        'and lamda functions.
                        gradeToMassAverageLamda = gradeToMassAverage

                        'Get the old grade row.
                        existingGradeRows = adjustmentRow.GetChildRows("FK_StockpileAdjustment_StockpileAdjustmentGrade").ToList. _
                            Where(Function(f) DirectCast(f("GradeName"), String) = gradeToMassAverageLamda)

                        If existingGradeRows.Count <> 0 And grades.ContainsKey(gradeToMassAverage) Then
                            massAveragedGrade = Convert.ToSingle(((grades(gradeToMassAverage) * newCalcTonnes) + _
                                (existingGradeRows(0).Field(Of Single)("GradeValue") * existingCalcTonnes)) / _
                                (existingCalcTonnes + newCalcTonnes))
                        ElseIf grades.ContainsKey(gradeToMassAverage) Then
                            massAveragedGrade = _
                                Convert.ToSingle((grades(gradeToMassAverage) * newCalcTonnes) / _
                                (existingCalcTonnes + newCalcTonnes))
                        Else
                            massAveragedGrade = Convert.ToSingle((existingGradeRows(0).Field(Of Single)("GradeValue") * existingCalcTonnes) / _
                                (existingCalcTonnes + newCalcTonnes))
                        End If

                        'Modify the existing row.
                        If existingGradeRows.Count > 0 Then
                            existingGradeRows(0)("GradeName") = gradeToMassAverage
                            existingGradeRows(0)("GradeValue") = massAveragedGrade
                        Else
                            'If a new row is required because the grade doesn't exist then add one.
                            stockpileAdjustmentGradeRow = adjustmentGradeTable.NewRow
                            stockpileAdjustmentGradeRow("GradeName") = gradeToMassAverage
                            stockpileAdjustmentGradeRow("GradeValue") = massAveragedGrade
                            adjustmentGradeTable.Rows.Add(stockpileAdjustmentGradeRow)
                            stockpileAdjustmentGradeRow.SetParentRow(adjustmentRow)
                        End If
                    Next
                End If
            Else
                adjustmentRow("StockpileAdjustmentType") = DBNull.Value
                adjustmentRow("StockpileAdjustmentTonnes") = DBNull.Value
            End If
        End If

    End Sub

    Private Shared Sub AddAdjustmentGrades(ByVal stockpileAdjustment As MQ2Service.AdjustmentType, ByVal adjustmentGradeTable As DataTable, ByVal adjustmentRow As DataRow)
        Dim adjustmentGradeRow As DataRow
        Dim index As Integer

        If Not stockpileAdjustment.Grade Is Nothing Then
            For index = 0 To stockpileAdjustment.Grade.Length - 1 Step 1
                If CodeTranslationHelper.RelevantGrades.Contains(stockpileAdjustment.Grade(index).Name, StringComparer.OrdinalIgnoreCase) Then
                    adjustmentGradeRow = adjustmentGradeTable.NewRow()
                    adjustmentGradeRow("GradeName") = stockpileAdjustment.Grade(index).Name
                    adjustmentGradeRow("GradeValue") = stockpileAdjustment.Grade(index).HeadValue.ReadAsDoubleWithDbNull(stockpileAdjustment.Grade(index).HeadValueSpecified)
                    adjustmentGradeRow.SetParentRow(adjustmentRow)
                    adjustmentGradeTable.Rows.Add(adjustmentGradeRow)
                End If
            Next
        End If
    End Sub
End Class
