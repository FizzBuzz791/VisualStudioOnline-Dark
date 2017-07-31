Imports Snowden.Reconcilor.Core.Database
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Common.Import
Imports Snowden.Common.Import.Database
Imports Snowden.Common.Import.Data
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.DataHelper
Imports System.Data.SqlClient

Friend NotInheritable Class Production
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _productSizeFines As String = "FINES"
    Private Const _productSizeLump As String = "LUMP"
    Private Shared ReadOnly _allowedProductSizesForStorage As New List(Of String)(New String() {_productSizeFines, _productSizeLump})

    Private Const _numberOfDaysPerWebRequest As Int32 = 7

    Private _settings As ConfigurationSettings

    Private Const _minimumDateText As String = "1-Jan-1900"
    Private Const _defaultShiftType As String = "D"

    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _site As String
    Private _utilityDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
    Private _stockpileDal As Snowden.Reconcilor.Core.Database.DalBaseObjects.IStockpile

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

    Public Sub New()
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Production"
        SourceSchemaName = "Production"
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

    Protected Overrides Sub SetupDataAccessObjects()
        _utilityDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(ImportSyncDal.DataAccess.DataAccessConnection)
        _stockpileDal = New Snowden.Reconcilor.Core.Database.SqlDal.SqlDalStockpile(ImportSyncDal.DataAccess.DataAccessConnection)

        ReferenceDataCachedHelper.UtilityDal = _utilityDal
        LocationDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
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

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)
        _site = CodeTranslationHelper.SingleSiteCodeFromReconcilor(parameters("Site"), toShortCode:=True)
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Dim calendarDate As DateTime

        'all tables have the HaulageDate and Site column - these can be used to partition accordingly
        calendarDate = DirectCast(keyRows("TransactionDate"), DateTime)

        Return (calendarDate >= _dateFrom) And (calendarDate <= _dateTo) And _
         (Convert.ToString(keyRows("SourceMineSite")).ToUpper = _site.ToUpper)
    End Function

    Protected Overrides Sub PreCompare()
        'do nothing
    End Sub

    Protected Overrides Sub PostCompare()
        'do nothing
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

        'no checks required as the UI does not contain this functionality
    End Sub

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim weightometerSampleId As Int32 = Convert.ToInt32(Convert.ToString(destinationRow("WeightometerSampleId")))

        If dataTableName = "Transaction" Then
            Try
                _utilityDal.DeleteWeightometerSample(weightometerSampleId, NullValues.String, NullValues.DateTime, NullValues.String, NullValues.Int32)
            Catch ex As SqlException
                If ex.Message.Contains("weightometer sample does not exist") Then
                    Trace.WriteLine("Attempted to delete Weightometer Sample record that does not exist: ignoring...")
                Else
                    Throw ex
                End If
            End Try
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim destinationWeightometerSampleRow As DataRow
        Dim weightometerSampleId As Int32
        Dim weightometerId As String
        Dim sourceStockpileId As Int32
        Dim sourceCrusherId As String
        Dim sourceMillId As String
        Dim destStockpileId As Int32
        Dim destCrusherId As String
        Dim destMillId As String
        Dim isError As Boolean
        Dim errorDescription As String
        Dim sourceRowSingleValue As Single
        Dim sourceLocationId As Int32
        Dim destinationLocationId As Int32
        Dim gradeId As Int16?
        Dim gradeValue As Single

        'add the destination key
        Snowden.Common.Database.DataHelper.AddTableColumn(destinationRow.Table, "WeightometerSampleId", GetType(String), Nothing)

        If dataTableName = "Transaction" Then

            'get the location ids, add the haulage raw location entries
            sourceLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("SourceMineSite"))).Value
            destinationLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("DestinationMineSite"))).Value

            'get the site's source & dest stockpile / crusher / mill
            sourceCrusherId = NullValues.String
            sourceMillId = NullValues.String
            destCrusherId = NullValues.String
            destMillId = NullValues.String

            _utilityDal.GetBhpbioProductionEntity(sourceLocationId, Convert.ToString(sourceRow("Source")), _
                Convert.ToString(sourceRow("SourceLocationType")), "SOURCE", Convert.ToDateTime(sourceRow("TransactionDate")), _
                sourceStockpileId, sourceCrusherId, sourceMillId)

            _utilityDal.GetBhpbioProductionEntity(destinationLocationId, Convert.ToString(sourceRow("Destination")), _
                Convert.ToString(sourceRow("DestinationType")), "DESTINATION", Convert.ToDateTime(sourceRow("TransactionDate")), _
                destStockpileId, destCrusherId, destMillId)

            'get the associated weightometer id
            weightometerId = NullValues.String
            errorDescription = NullValues.String

            _utilityDal.GetBhpbioProductionWeightometer(sourceStockpileId, sourceCrusherId, sourceMillId, _
                destStockpileId, destCrusherId, destMillId, Convert.ToDateTime(sourceRow("TransactionDate")), _
                Convert.ToString(sourceRow("SourceLocationType")), Convert.ToString(sourceRow("DestinationType")), _
                sourceLocationId, weightometerId, isError, errorDescription)

            'add the sample record
            weightometerSampleId = _utilityDal.AddWeightometerSample(weightometerId, _
                Convert.ToDateTime(sourceRow("TransactionDate")), _defaultShiftType, 1, _
                Convert.ToDouble(sourceRow("Tonnes")), NullValues.Double, sourceStockpileId, destStockpileId)

            'add the notes
            If Not (sourceRow("SampleSource") Is DBNull.Value) Then
                _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "SampleSource", sourceRow("SampleSource").ToString)
            End If

            'add the values
            If Not (sourceRow("SampleTonnes") Is DBNull.Value) Then
                If Single.TryParse(sourceRow("SampleTonnes").ToString, sourceRowSingleValue) Then
                    _utilityDal.AddOrUpdateWeightometerSampleValue(weightometerSampleId, "SampleTonnes", sourceRowSingleValue)
                Else
                    Throw New Exception("Failed to Convert SampleTonnes to a Single: " & sourceRow("SampleTonnes").ToString)
                End If
            End If

            Dim effectiveProductSize As String = GetEffectiveProductSize(sourceRow)

            If Not (effectiveProductSize Is Nothing) Then
                _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "ProductSize", effectiveProductSize)
            End If

        ElseIf dataTableName = "TransactionGrade" Then
            'add the grade id column
            AddTableColumn(destinationRow.Table, "GradeId", GetType(Int16), Nothing)

            'resolve the grade
            gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

            If Not gradeId.HasValue Then
                Throw New MissingFieldException(String.Format("The grade {0} could not be resolved.", sourceRow("GradeName")))
            End If

            gradeValue = ReadGradeValueFromSourceRow(sourceRow)

            destinationWeightometerSampleRow = DirectCast(sourceRow.GetParentRow("FK_Transaction_TransactionGrade")("DestinationRow"), DataRow)
            weightometerSampleId = Convert.ToInt32(destinationWeightometerSampleRow("WeightometerSampleId"))
            destinationWeightometerSampleRow = Nothing

            'this IF statement check is a WORK AROUND
            'MQ2 currently contains 0.0 grade values which are definitely not supposed to be that value
            If gradeValue > 0.0 Then
                _utilityDal.AddOrUpdateWeightometerSampleGrade(weightometerSampleId, gradeId.Value, gradeValue)
            End If

            'save the grade id
            destinationRow("GradeId") = gradeId.Value
        End If

        'save the id
        destinationRow("WeightometerSampleId") = weightometerSampleId
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim weightometerSampleId As Int32
        Dim gradeId As Int16?
        Dim gradeValue As Single

        weightometerSampleId = Convert.ToInt32(destinationRow("WeightometerSampleId"))

        If dataTableName = "Transaction" Then

            If syncQueueChangedFields.Select("ChangedField = 'Tonnes'").Length > 0 Then
                _utilityDal.UpdateWeightometerSample(weightometerSampleId, Convert.ToInt16(False), NullValues.String, _
                 Convert.ToInt16(False), NullValues.DateTime, Convert.ToInt16(False), NullValues.String, _
                 Convert.ToInt16(False), NullValues.Int32, Convert.ToInt16(True), DirectCast(sourceRow("Tonnes"), Double), _
                 Convert.ToInt16(False), NullValues.Double, Convert.ToInt16(False), NullValues.Int32, _
                 Convert.ToInt16(False), NullValues.Int32)
            End If

            If syncQueueChangedFields.Select("ChangedField = 'SampleSource'").Length > 0 Then
                If Not (sourceRow("SampleSource") Is DBNull.Value) Then
                    _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "SampleSource", sourceRow("SampleSource").ToString)
                Else
                    _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "SampleSource", NullValues.String)
                End If
            End If

            If syncQueueChangedFields.Select("ChangedField = 'SampleTonnes'").Length > 0 Then
                If Not (sourceRow("SampleTonnes") Is DBNull.Value) Then
                    _utilityDal.AddOrUpdateWeightometerSampleValue(weightometerSampleId, "SampleTonnes", Convert.ToSingle(sourceRow("SampleTonnes")))
                Else
                    _utilityDal.AddOrUpdateWeightometerSampleValue(weightometerSampleId, "SampleTonnes", NullValues.Single)
                End If
            End If

            If syncQueueChangedFields.Select("ChangedField = 'ProductSize'").Length > 0 Then
                Dim effectiveProductSize = GetEffectiveProductSize(sourceRow)
                If (effectiveProductSize Is Nothing) Then
                    _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "ProductSize", NullValues.String)
                Else
                    _utilityDal.AddOrUpdateWeightometerSampleNotes(weightometerSampleId, "ProductSize", effectiveProductSize)
                End If
            End If

        ElseIf dataTableName = "TransactionGrade" Then

            ' If SampleValue has changed....   or HeadValue has changed and there is no SampleValue
            ' Then Re-evaluate and update the grade value
            If (syncQueueChangedFields.Select("ChangedField = 'SampleValue'").Length > 0 _
                OrElse (syncQueueChangedFields.Select("ChangedField = 'HeadValue'").Length > 0 AndAlso IsColumnValueNullOrEmpty(sourceRow, "SampleValue"))) Then

                'resolve the grade
                gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

                If Not gradeId.HasValue Then
                    Throw New MissingFieldException(String.Format("The grade {0} could not be resolved.", sourceRow("GradeName")))
                End If

                gradeValue = ReadGradeValueFromSourceRow(sourceRow)

                'this IF statement check is a WORK AROUND
                'MQ2 currently contains 0.0 grade values which are definitely not supposed to be that value
                'Port Actual Grades Should not be getting entered, they should be wiped.
                If (gradeValue > 0.0) Then
                    _utilityDal.AddOrUpdateWeightometerSampleGrade(weightometerSampleId, gradeId.Value, gradeValue)
                Else
                    _utilityDal.AddOrUpdateWeightometerSampleGrade(weightometerSampleId, gradeId.Value, NullValues.Single)
                End If
            End If
        End If
    End Sub

    ''' <summary>
    ''' GetEffectiveProductSize processes a ProductSize from a source row and returns the value appropriate for storage
    ''' </summary>
    Protected Function GetEffectiveProductSize(ByRef row As DataRow) As String
        Dim productSize As String = Nothing

        If (row.Table.Columns.Contains("ProductSize") AndAlso (Not row("ProductSize") Is DBNull.Value) AndAlso (Not row("ProductSize") Is Nothing)) Then
            Dim productSizeRead As String = row("ProductSize").ToString().ToUpper

            If _allowedProductSizesForStorage.Contains(productSizeRead) Then
                productSize = productSizeRead
            End If
        End If

        Return productSize
    End Function

    ''' <summary>
    ''' IsColumnValueNullOrEmpty determines whether a source row has a value for a specified column
    ''' </summary>
    Protected Function IsColumnValueNullOrEmpty(ByRef row As DataRow, ByVal column As String) As Boolean
        Dim isNullOrEmpty As Boolean = True

        If (row.Table.Columns.Contains(column) AndAlso Not (row(column) Is Nothing OrElse row(column) Is DBNull.Value OrElse String.IsNullOrEmpty(row(column).ToString()))) Then
            isNullOrEmpty = False
        End If

        Return isNullOrEmpty
    End Function

    ''' <summary>
    ''' ReadGradeValueFromSourceRow reads the grade to be associated with a production movement.  This will either be the SampleValue (preferred) or HeadValue if no SampleValue exists
    ''' </summary>
    Protected Function ReadGradeValueFromSourceRow(ByRef row As DataRow) As Single
        Dim gradeValue As Single ' default to 0.0

        If (Not IsColumnValueNullOrEmpty(row, "SampleValue")) Then
            gradeValue = Convert.ToSingle(row("SampleValue"))
        ElseIf (Not IsColumnValueNullOrEmpty(row, "HeadValue")) Then
            gradeValue = Convert.ToSingle(row("HeadValue"))
        End If

        Return gradeValue
    End Function

    Protected Overrides Sub ProcessValidate(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal importSyncValidate As DataTable, _
        ByVal importSyncValidateField As DataTable, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim importSyncValidateId As Int64
        Dim gradeValue As Single
        Dim parseSuccessful As Boolean

        Dim sourceLocationId As Int32?
        Dim destinationLocationId As Int32?

        Dim sourceStockpileId As Int32
        Dim sourceCrusherId As String
        Dim sourceMillId As String
        Dim destStockpileId As Int32
        Dim destCrusherId As String
        Dim destMillId As String

        Dim isError As Boolean
        Dim errorDescription As String
        Dim weightometerId As String

        Dim sourceResolved As Boolean
        Dim destinationResolved As Boolean
        Dim validationMessage As String = String.Empty

        If dataTableName = "Transaction" Then
            'Type can only be Movement and Error
            If Convert.ToString(sourceRow("Type")) <> "Movement" AndAlso Convert.ToString(sourceRow("Type")) <> "Error" Then
                validationMessage = String.Format("The Type can only be Movement and Error, but was: [{0}]", sourceRow("Type"))
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), "The Type can only be 'Movement' or 'Error'.", _
                    validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Type")
            End If

            'Tonnes must be > 0
            If Convert.ToDouble(sourceRow("Tonnes")) <= 0.0 Then
                validationMessage = "The Tonnes must be greater than 0.0."
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Tonnes")
            End If

            'attempt to map the SOURCE to a site... if it isn't found then try to map to a hub
            sourceLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("SourceMineSite")))
            If Not sourceLocationId.HasValue Then
                validationMessage = String.Format("The Source Mine Site/Hub code '{0}' cannot be resolved.", Convert.ToString(sourceRow("SourceMineSite")))
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "SourceMineSite")
            End If

            'attempt to map the DESTINATION to a site... if it isn't found then try to map to a hub
            destinationLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("DestinationMineSite")))
            If Not destinationLocationId.HasValue Then
                validationMessage = String.Format("The Destination Mine Site/Hub code '{0}' cannot be resolved.", Convert.ToString(sourceRow("DestinationMineSite")))
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "DestinationMineSite")
            End If

            'resolve the SOURCE
            If Not sourceLocationId.HasValue Then
                sourceResolved = False
                sourceCrusherId = Nothing
                sourceMillId = Nothing
            Else
                sourceResolved = True

                'check that the source locations can be decoded
                sourceStockpileId = NullValues.Int32
                sourceCrusherId = NullValues.String
                sourceMillId = NullValues.String

                '(+) by source
                _utilityDal.GetBhpbioProductionEntity(sourceLocationId.Value, _
                    Convert.ToString(sourceRow("Source")), Convert.ToString(sourceRow("SourceLocationType")), "SOURCE", _
                    Convert.ToDateTime(sourceRow("TransactionDate")), sourceStockpileId, sourceCrusherId, sourceMillId)

                If (sourceStockpileId = NullValues.Int32) And (sourceCrusherId = NullValues.String) And (sourceMillId = NullValues.String) Then
                    validationMessage = "The Source cannot be determined."

                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)

                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Source")

                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "SourceLocationType")

                    sourceResolved = False
                End If
            End If

            'resolve the DESTINATION
            If Not destinationLocationId.HasValue Then
                destinationResolved = False
                destCrusherId = Nothing
                destMillId = Nothing
            Else
                destinationResolved = True

                'check that the destination locations can be decoded
                destStockpileId = NullValues.Int32
                destCrusherId = NullValues.String
                destMillId = NullValues.String

                '(+) by destination
                _utilityDal.GetBhpbioProductionEntity(destinationLocationId.Value, Convert.ToString(sourceRow("Destination")), _
                    Convert.ToString(sourceRow("DestinationType")), "DESTINATION", _
                    Convert.ToDateTime(sourceRow("TransactionDate")), destStockpileId, destCrusherId, destMillId)

                If (destStockpileId = NullValues.Int32) And (destCrusherId = NullValues.String) And (destMillId = NullValues.String) Then
                    validationMessage = "The Destination cannot be determined."

                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)

                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Destination")

                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "DestinationType")

                    destinationResolved = False
                End If
            End If

            '(+) by Weightometer
            If sourceResolved And destinationResolved Then
                weightometerId = NullValues.String
                errorDescription = NullValues.String

                'note: the weightometer must exist at the source
                _utilityDal.GetBhpbioProductionWeightometer(sourceStockpileId, sourceCrusherId, sourceMillId, _
                    destStockpileId, destCrusherId, destMillId, Convert.ToDateTime(sourceRow("TransactionDate")), _
                    Convert.ToString(sourceRow("SourceLocationType")), Convert.ToString(sourceRow("DestinationType")), _
                    sourceLocationId.Value, weightometerId, isError, errorDescription)

                If isError Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), errorDescription, errorDescription)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "TransactionDate")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Source")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "SourceLocationType")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Destination")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "DestinationType")
                End If
            End If

            'check if the source stockpile (if required) is available
            If (sourceStockpileId <> NullValues.Int32) AndAlso Not (_stockpileDal.GetStockpileBuildActive(sourceStockpileId, NullValues.Int32, _
                Convert.ToDateTime(sourceRow("TransactionDate")), _defaultShiftType)) Then

                validationMessage = "The source stockpile is not active for this transaction date."
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "TransactionDate")
            End If

            'check if the destination stockpile (if required) is available
            If (destStockpileId <> NullValues.Int32) AndAlso Not (_stockpileDal.GetStockpileBuildActive(destStockpileId, NullValues.Int32, _
                Convert.ToDateTime(sourceRow("TransactionDate")), _defaultShiftType)) Then

                validationMessage = "The destination stockpile is not active for this transaction date."
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "TransactionDate")
            End If

        ElseIf dataTableName = "TransactionGrade" Then

            'Grades - Name must resolve, Value must be > 0
            'NOTE: there is a WORKAROUND for MQ2 having 0.0 grade values
            ' currently the check lets these through as we need the tonnes records to load

            'check that the grade id can be resolved
            If Not ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).HasValue Then
                validationMessage = String.Format("The Grade Name '{0}' could not be determined.", sourceRow("GradeName"))

                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)

                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Grades")
            End If

            Dim gradeValueColumn As String = "HeadValue"

            If Not IsColumnValueNullOrEmpty(sourceRow, "SampleValue") Then
                gradeValueColumn = "SampleValue"
            End If

            'check that the grade value is valid
            parseSuccessful = Single.TryParse(sourceRow(gradeValueColumn).ToString, gradeValue)

            If (Not parseSuccessful) OrElse gradeValue < 0.0 Then
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), "The Grade Value must be numeric and greater than zero.", _
                    String.Format("The Grade Value was: [{0}]", sourceRow(gradeValueColumn)))
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Grades")
            End If
        End If
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)

        ' Revise Weightometer Ids based on temporary location assignments
        _utilityDal.CorrectBhpbioProductionWeightometerAndDestinationAssignments()

        ' Trigger the CalcVirtualFlow process
        _utilityDal.CalcVirtualFlow()

        ' Raise missing sample data exceptions
        _utilityDal.UpdateBhpbioMissingSampleDataException(DateFrom, DateTo)

    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    Protected Overrides Function LoadSource(ByVal sourceSchema As System.IO.StringReader) As System.Data.DataSet
        Dim returnDataSet As DataSet = Nothing

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A production source schema must be provided.")
        End If

        'create the dataset to the requested schema
        returnDataSet = New DataSet()
        returnDataSet.ReadXmlSchema(sourceSchema)
        returnDataSet.EnforceConstraints = False

        'load from the web service
        LoadSourceFromWebService(DateFrom, DateTo, Site, returnDataSet)

        'remove any records marked as "Error"
        For Each transactionRow In returnDataSet.Tables("Transaction").Select()
            If Convert.ToString(transactionRow("Type")) = "Error" Then
                transactionRow.Delete()
            End If
        Next

        'mark the returned dataset as "clean"
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
    ''' Loads the Production from the Production Service applying the partitions.
    ''' </summary>
    ''' <param name="partitionDateFrom">The from date that we are partitioning on.  The date is inclusive.</param>
    ''' <param name="partitionDateTo">The to date that we are partitioning on.  The date is inclusive.</param>
    ''' <param name="partitionSite">The Site that we are partitioning on.</param>
    ''' <param name="returnDataSet">
    ''' The incoming dataset must have a schema pre-specified.
    ''' The data is populated into this schema.
    ''' </param>
    ''' <remarks>
    ''' Due to the large amounts of data requested we have opted to break it into small chunks.
    ''' These requests are processed serially and the results are aggregated.
    ''' </remarks>
    Private Sub LoadSourceFromWebService(ByVal partitionDateFrom As DateTime, ByVal partitionDateTo As DateTime, _
        ByVal partitionSite As String, ByVal returnDataSet As DataSet)

        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime
        Dim mq2Client As MQ2Service.IM_MQ2_DS

        Dim retrieveProdMovementRequest1 As MQ2Service.retrieveProductionMovementsRequest1
        Dim prodMovementRequest As MQ2Service.RetrieveProductionMovementsRequest
        Dim retrieveProdMovementResponse1 As MQ2Service.retrieveProductionMovementsResponse1
        Dim prodMovementResponse As MQ2Service.RetrieveProductionMovementsResponse
        Dim index As Integer

        prodMovementRequest = New MQ2Service.RetrieveProductionMovementsRequest()
        prodMovementRequest.StartDateSpecified = True
        prodMovementRequest.EndDateSpecified = True
        prodMovementRequest.MineSiteCode = partitionSite

        Trace.WriteLine(String.Format("Loading from Web Service: Site = {0}, From = {1:dd-MMM-yyyy}, To = {2:dd-MMM-yyyy}", _
            partitionSite, partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddDays(_numberOfDaysPerWebRequest)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine(String.Format("Requesting partition: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy} at {2:HH:m:ss dd-MMM-yyyy}", currentDateFrom, currentDateTo, DateTime.Now))

            prodMovementRequest.StartDate = currentDateFrom.ToUniversalTime()
            prodMovementRequest.EndDate = currentDateTo.ToUniversalTime()

            'create a new request and invoke it
            retrieveProdMovementRequest1 = New MQ2Service.retrieveProductionMovementsRequest1(prodMovementRequest)

            mq2Client = WebServicesFactory.CreateMQ2WebServiceClient()
            Try
                retrieveProdMovementResponse1 = mq2Client.retrieveProductionMovements(retrieveProdMovementRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving production data from MQ2 web service.", ex)
            End Try

            prodMovementResponse = retrieveProdMovementResponse1.RetrieveProductionMovementsResponse

            If prodMovementResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    DateTime.Now, prodMovementResponse.Status.StatusMessage))
            End If

            If Not prodMovementResponse.Production Is Nothing Then
                For index = 0 To prodMovementResponse.Production.Length - 1
                    LoadProdMovementRecord(prodMovementResponse.Production(index), returnDataSet)
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

    Private Sub LoadProdMovementRecord(ByVal prodMovementTransaction As MQ2Service.ProdMovesTransactionType, ByVal returnDataSet As DataSet)
        Dim transactionTable As DataTable
        Dim transactionGradeTable As DataTable
        Dim transactionRow As DataRow

        transactionTable = returnDataSet.Tables("Transaction")
        transactionGradeTable = returnDataSet.Tables("TransactionGrade")
        transactionRow = transactionTable.NewRow()
        transactionTable.Rows.Add(transactionRow)

        'prodMovementTransaction.Location.Mine
        'skip over this element; we used to store this in a SITE field however
        'it has been superceded by SourceMineSite and DestinationMineSite

        transactionRow("TransactionDate") = prodMovementTransaction.TransactionDate.ReadAsDateTimeWithDbNull(prodMovementTransaction.TransactionDateSpecified)
        transactionRow("Source") = prodMovementTransaction.Source.ReadStringWithDbNull()
        transactionRow("SourceLocationType") = prodMovementTransaction.SourceType.ReadStringWithDbNull()
        transactionRow("Destination") = prodMovementTransaction.Destination.ReadStringWithDbNull()
        transactionRow("DestinationType") = prodMovementTransaction.DestinationType.ReadStringWithDbNull()
        transactionRow("Type") = prodMovementTransaction.Type.ReadStringWithDbNull()
        transactionRow("SourceMineSite") = prodMovementTransaction.SourceMineSite.ReadStringWithDbNull()
        transactionRow("DestinationMineSite") = prodMovementTransaction.DestinationMineSite.ReadStringWithDbNull()
        transactionRow("Tonnes") = prodMovementTransaction.Tonnes.ReadAsDoubleWithDbNull(prodMovementTransaction.TonnesSpecified)
        transactionRow("ProductSize") = prodMovementTransaction.ProductSize.ReadStringWithDbNull()
        transactionRow("SampleSource") = prodMovementTransaction.SampleSource.ReadStringWithDbNull()
        transactionRow("SampleTonnes") = prodMovementTransaction.SampleTonnes.ReadAsDoubleWithDbNull(prodMovementTransaction.SampleTonnesSpecified)

        'pre-process product size
        If (Not transactionRow("ProductSize") Is DBNull.Value) Then
            transactionRow("ProductSize") = Convert.ToString(transactionRow("ProductSize")).ToUpper()
        End If

        'perform name translations as required
        If TypeOf transactionRow("Source") Is String And TypeOf transactionRow("SourceLocationType") Is String Then
            transactionRow("Source") = CodeTranslationHelper.RecodeTransaction( _
             DirectCast(transactionRow("Source"), String), DirectCast(transactionRow("SourceLocationType"), String), _
             DirectCast(transactionRow("SourceMineSite"), String))
        End If

        If TypeOf transactionRow("Destination") Is String And TypeOf transactionRow("DestinationType") Is String Then
            transactionRow("Destination") = CodeTranslationHelper.RecodeTransaction( _
             DirectCast(transactionRow("Destination"), String), DirectCast(transactionRow("DestinationType"), String), _
             DirectCast(transactionRow("DestinationMineSite"), String))
        End If

        LoadTransactionGrades(prodMovementTransaction, transactionGradeTable, transactionRow)
    End Sub

    Private Sub LoadTransactionGrades(ByVal prodMovementTransaction As MQ2Service.ProdMovesTransactionType, ByVal transactionGradeTable As DataTable, ByVal transactionRow As DataRow)
        Dim transactionGradeRow As DataRow
        Dim index As Integer

        If Not prodMovementTransaction.Grade Is Nothing Then
            For index = 0 To prodMovementTransaction.Grade.Length - 1
                If CodeTranslationHelper.RelevantGrades.Contains(prodMovementTransaction.Grade(index).Name, StringComparer.OrdinalIgnoreCase) Then
                    transactionGradeRow = transactionGradeTable.NewRow()
                    transactionGradeRow("GradeName") = prodMovementTransaction.Grade(index).Name
                    If (prodMovementTransaction.Grade(index).HeadValueSpecified) Then
                        transactionGradeRow("HeadValue") = Convert.ToSingle(prodMovementTransaction.Grade(index).HeadValue)
                    End If

                    If (prodMovementTransaction.Grade(index).SampleValueSpecified) Then
                        transactionGradeRow("SampleValue") = Convert.ToSingle(prodMovementTransaction.Grade(index).SampleValue)
                    End If
                    transactionGradeRow.SetParentRow(transactionRow)
                    transactionGradeTable.Rows.Add(transactionGradeRow)
                End If
            Next
        End If
    End Sub

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)

    End Sub

End Class
