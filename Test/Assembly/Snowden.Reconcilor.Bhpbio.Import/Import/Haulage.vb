Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Import
Imports Snowden.Common.Import.Data
Imports Snowden.Common.Import.Database
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Bhpbio.Import.MQ2Service
Imports System.Data.SqlClient

Friend NotInheritable Class Haulage
    Inherits Snowden.Reconcilor.Core.Import.HaulageSyncImport

    Private Const _unknownTruck As String = "Unknown"
    Private Const _defaultLoads As Int32 = 1
    Private Const _numberOfDaysPerWebRequest As Int32 = 28
    Private Const _defaultShift As Char = "D"c
    Private Const _romStockpileGroup As String = "ROM"
    Private Const _haulageNotesRelationName As String = "FK_Haulage_HaulageNotes"
    Private Const _haulageValueRelationName As String = "FK_Haulage_HaulageValue"
    Private Const _haulageGradeRelationName As String = "FK_Haulage_HaulageGrade"
    Private Const _negativeValue As Int32 = -1
    Private Const _minimumDateText As String = "1-Jan-1900"

    Private _settings As ConfigurationSettings

    Private _site As String

    Private _bhpbioHaulageDal As Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalHaulage
    Private _utilityDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
    Private _bhpbioDigblockDal As Bhpbio.Database.DalBaseObjects.IDigblock

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
        _settings = ConfigurationSettings.GetConfigurationSettings()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Haulage"
        SourceSchemaName = "Haulage"
        CanGenerateSourceSchema = False
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
        MyBase.LoadParameters(parameters)
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, MyBase.DateFrom, MyBase.DateTo)
        _site = CodeTranslationHelper.SingleSiteCodeFromReconcilor(parameters("Site"), toShortCode:=True)
    End Sub

    Protected Overrides Sub PreCompare()
        'do nothing
    End Sub

    Protected Overrides Sub PostCompare()
        'do nothing
    End Sub

    ''' <remarks>
    ''' Performs the following checks:
    ''' This override improves performance by loading destination data that is in the import's date range only.
    ''' </remarks>
    Protected Overrides Function GetImportSyncRows() As System.Data.IDataReader
        Return MyBase.ImportSyncDal.GetImportSyncRowsInDateRange(ImportId, NullValues.Int16, 1, NullValues.Int16, NullValues.Int16, _
            "/HaulageSource[1]/*[1]/HaulageDate[1]", MyBase.DateFrom, MyBase.DateTo)
    End Function

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Dim haulageDate As DateTime

        'all tables have the HaulageDate and Site column - these can be used to partition accordingly
        haulageDate = Convert.ToDateTime(keyRows("HaulageDate"))

        Return (_site Is Nothing OrElse _site.ToUpper = Convert.ToString(keyRows("SourceMineSite")).ToUpper) AndAlso _
         (haulageDate >= DateFrom) And (haulageDate <= DateTo)
    End Function

    ''' <remarks>
    ''' Performs the following checks:
    ''' 1. For Notes/Grade/Value records ensures the parent record is available.
    ''' 2. Runs the standard conflict checks.
    ''' </remarks>
    Protected Overrides Sub ProcessConflict(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal importSyncConflict As DataTable, _
     ByVal importSyncConflictField As DataTable, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim haulageRawId As Int32
        Dim conflictFlag As Int16
        Dim dataTableNameLower As String
        Dim relationName As String = Nothing
        Dim destinationHaulageRow As DataRow

        dataTableNameLower = dataTableName.ToLower

        'if we're performing an insert we want to check if the parent has made it in
        If syncAction = SyncImportSyncActionEnumeration.Insert _
         AndAlso (dataTableNameLower = "haulagenotes" _
                  OrElse dataTableNameLower = "haulagevalue" _
                  OrElse dataTableNameLower = "haulagegrade") Then

            'NOTE :: THIS CHECK CAN BE REMOVED
            ' THERE IS A LATENT DEFECT IN THE COMMON IMPORTS
            ' THAT STOPS CHILDREN FROM BEING LOADED IF THE PARENT DOESN'T LOAD
            ' AT THIS POINT IN TIME THE COMMON CODE CONTAINS THIS DEFECT
            ' REMOVE THIS CODE ONCE CONFIRMED THE DEFECT HAS BEEN ELIMINATED

            'determine the appropriate relation name
            Select Case dataTableNameLower
                Case "haulagenotes"
                    relationName = _haulageNotesRelationName
                Case "haulagevalue"
                    relationName = _haulageValueRelationName
                Case "haulagegrade"
                    relationName = _haulageGradeRelationName
            End Select

            'find the parent's destination row
            'note - there is always a parent available at this stage
            destinationHaulageRow = DirectCast(sourceRow.GetParentRow(relationName)("DestinationRow"), DataRow)

            If Not destinationHaulageRow.Table.Columns.Contains("HaulageRawId") _
             AndAlso Not (destinationHaulageRow("HaulageRawId") Is DBNull.Value) Then
                SyncImportDataHelper.AddImportSyncConflict(importSyncConflict, _
                 Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                 "The parent haulage row has not yet been inserted.", _
                 "The parent haulage row has not yet been inserted.")
            End If

        ElseIf syncAction = SyncImportSyncActionEnumeration.Delete Or _
                    syncAction = SyncImportSyncActionEnumeration.Update Then

            'for all delete/update actions we simply want to check if the haulage raw record
            'is in the standard conflict state

            'retrieve haulage raw id from the destination which will be validated
            haulageRawId = Convert.ToInt32(destinationRow("HaulageRawId"))
            haulageRawId = MyBase.HaulageDal.GetLastHaulageRawId(haulageRawId)

            'get the haulage raw conflict flag
            conflictFlag = MyBase.HaulageDal.GetHaulageRawConflictFlag(haulageRawId)

            If conflictFlag = 1 Then
                SyncImportDataHelper.AddImportSyncConflict(importSyncConflict, _
                 Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                 "The existing haulage raw record is currently in the conflict state.", _
                 "The existing haulage raw record is currently in the conflict state.")
            End If
        End If
    End Sub

    ''' <summary>
    ''' Determine whether a source matches the form of a Digblock code
    ''' </summary>
    ''' <param name="source">the source to check</param>
    ''' <returns>true if the source matches the form, otherwise false</returns>
    Private Function SourceMatchesDigblockPattern(ByVal source As String) As Boolean
        Dim r As New System.Text.RegularExpressions.Regex("[A-Z,a-z,0-9]*-[A-Z,a-z,0-9]*-[A-Z,a-z,0-9]*-[A-Z,a-z,0-9]")

        Return r.IsMatch(source)
    End Function

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim dataTableNameLower As String = String.Empty
        Dim haulageRawId As Int32

        dataTableNameLower = dataTableName.ToLower
        'find the latest haulage raw id
        haulageRawId = HaulageDal.GetLastHaulageRawId(Convert.ToInt32(destinationRow("HaulageRawId")))

        If dataTableNameLower = "haulage" Then
            'delete all lump/fines grades in the chain related to haulageRawId by setting other params to Null/Nothing:
            _bhpbioHaulageDal.AddOrUpdateBhpbioHaulageLumpFinesGrade(haulageRawId, Nothing, Nothing, Nothing)

            'now delete the main HaulageRaw record
            Try
                HaulageDal.DeleteHaulageRaw(haulageRawId)
            Catch ex As SqlException
                If ex.Message.Contains("Haulage record does not exist") Then
                    Trace.WriteLine("Attempted to delete Haualge Raw record that does not exists: ignoring...")
                Else
                    Throw ex
                End If
            End Try

            If SourceMatchesDigblockPattern(sourceRow("Source").ToString()) Then
                ' resolve any obsolete data exceptions related to digblock haulage
                _bhpbioDigblockDal.ResolveBhpbioDataExceptionDigblockHasHaulage(sourceRow("Source").ToString())
            End If
        Else
            'request the udpate
            HaulageDal.UpdateHaulageRaw(haulageRawId, _
                Convert.ToInt16(False), NullValues.String, _
                Convert.ToInt16(False), NullValues.String, _
                Convert.ToInt16(False), NullValues.Double, _
                Convert.ToInt16(False), NullValues.Int32, _
                Convert.ToInt16(False), NullValues.String, _
                Convert.ToInt16(False), NullValues.Int16, _
                Convert.ToInt16(False))

            If dataTableNameLower = "haulagegrade" Then
                HaulageDal.AddOrUpdateHaulageRawGrade(haulageRawId, Convert.ToInt16(destinationRow("GradeId")), NullValues.Single)
            ElseIf dataTableNameLower = "haulagevalue" Then
                HaulageDal.AddOrUpdateHaulageRawValue(haulageRawId, sourceRow("FieldId").ToString, NullValues.Single)
            ElseIf dataTableNameLower = "haulagenotes" Then
                HaulageDal.AddOrUpdateHaulageRawNotes(haulageRawId, sourceRow("FieldId").ToString, NullValues.String)
            End If
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim haulageRawId As Int32 = NullValues.Int32
        Dim dataTableNameLower As String = String.Empty
        Dim relationName As String = String.Empty
        Dim destinationHaulageRow As DataRow
        Dim gradeId As Nullable(Of Int16)
        Dim siteCode As String
        Dim sourceLocationId As Int32
        Dim destinationLocationId As Int32

        dataTableNameLower = dataTableName.ToLower

        'add resolution column (this is applicable to all tables)
        AddTableColumn(destinationRow.Table, "HaulageRawId", GetType(Int32), Nothing)

        If dataTableNameLower = "haulage" Then
            'Add the haulage record
            haulageRawId = HaulageDal.AddHaulageRaw( _
             Convert.ToDateTime(IfDBNull(sourceRow("HaulageDate"), NullValues.DateTime)), _
             IfDBNull(sourceRow("HaulageShift"), NullValues.String), _
             IfDBNull(sourceRow("Source"), NullValues.String), _
             IfDBNull(sourceRow("Destination"), NullValues.String), _
             IfDBNull(sourceRow("Tonnes"), NullValues.Double), _
             IfDBNull(sourceRow("Loads"), NullValues.Int32), _
             IfDBNull(sourceRow("Truck"), NullValues.String), _
             Convert.ToInt16(True), haulageRawId)

            'add the Haulage Raw Location records
            sourceLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("SourceMineSite"))).Value
            destinationLocationId = LocationDataCachedHelper.GetMQ2SiteOrHubLocationId(Convert.ToString(sourceRow("DestinationMineSite"))).Value
            HaulageDal.AddOrUpdateHaulageRawLocation(haulageRawId, 1, sourceLocationId, 1, destinationLocationId)

            'add the Source Mine Site record
            If sourceRow("SourceMineSite") Is DBNull.Value Then
                siteCode = NullValues.String
            Else
                siteCode = CodeTranslationHelper.Mq2SiteToReconcilor(Convert.ToString(sourceRow("SourceMineSite")))
                If siteCode = Nothing Then
                    siteCode = CodeTranslationHelper.Mq2HubToReconcilor(Convert.ToString("SourceMineSite"))
                End If
            End If
            HaulageDal.AddOrUpdateHaulageRawNotes(HaulageDal.GetLastHaulageRawId(haulageRawId), "SourceMineSite", siteCode)

            'add the Destination Mine Site record
            If sourceRow("DestinationMineSite") Is DBNull.Value Then
                siteCode = NullValues.String
            Else
                siteCode = CodeTranslationHelper.Mq2SiteToReconcilor(Convert.ToString(sourceRow("DestinationMineSite")))
                If siteCode = Nothing Then
                    siteCode = CodeTranslationHelper.Mq2HubToReconcilor(Convert.ToString(sourceRow("DestinationMineSite")))
                End If
            End If
            HaulageDal.AddOrUpdateHaulageRawNotes(HaulageDal.GetLastHaulageRawId(haulageRawId), "DestinationMineSite", siteCode)
        Else
            'find the parent haulage record's id prior to performing the inserts on the child records
            Select Case dataTableNameLower
                Case "haulagenotes"
                    relationName = _haulageNotesRelationName
                Case "haulagevalue"
                    relationName = _haulageValueRelationName
                Case "haulagegrade"
                    relationName = _haulageGradeRelationName
            End Select

            destinationHaulageRow = DirectCast(sourceRow.GetParentRow(relationName)("DestinationRow"), DataRow)
            haulageRawId = Convert.ToInt32(destinationHaulageRow("HaulageRawId"))
            haulageRawId = HaulageDal.GetLastHaulageRawId(haulageRawId)
            destinationHaulageRow = Nothing

            'request the udpate to the haulage raw record
            'note that we are NOT creating an audit child for each change
            HaulageDal.UpdateHaulageRaw(haulageRawId, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.Double, _
             Convert.ToInt16(False), NullValues.Int32, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.Int16, _
             Convert.ToInt16(False))

            'perform the insert
            If dataTableNameLower = "haulagegrade" Then
                'add the grade id column
                AddTableColumn(destinationRow.Table, "GradeId", GetType(Int16), Nothing)

                'resolve the grade
                gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

                If Not gradeId.HasValue Then
                    Throw New MissingFieldException(String.Format("The grade {0} could not be resolved.", sourceRow("GradeName")))
                End If

                'add the head grade record
                HaulageDal.AddOrUpdateHaulageRawGrade(haulageRawId, _
                 Convert.ToInt16(gradeId.Value), _
                 IfDBNull(sourceRow("HeadValue"), NullValues.Single))

                'add lump & fines grade values
                _bhpbioHaulageDal.AddOrUpdateBhpbioHaulageLumpFinesGrade(haulageRawId, Convert.ToInt16(gradeId.Value), _
                    IfDBNull(sourceRow("LumpValue"), NullValues.Single), IfDBNull(sourceRow("FinesValue"), NullValues.Single))

                'save the grade id
                destinationRow("GradeId") = gradeId.Value

            ElseIf dataTableNameLower = "haulagevalue" Then
                'add the value record
                HaulageDal.AddOrUpdateHaulageRawValue(haulageRawId, _
                 sourceRow("FieldId").ToString, _
                 IfDBNull(sourceRow("Value"), NullValues.Single))

            ElseIf dataTableNameLower = "haulagenotes" Then
                'add the note record
                HaulageDal.AddOrUpdateHaulageRawNotes(haulageRawId, _
                 sourceRow("FieldId").ToString, _
                 IfDBNull(sourceRow("Notes"), NullValues.String).ToString)
            End If
        End If

        'save the haulage raw id back
        destinationRow("HaulageRawId") = haulageRawId
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim haulageRawId As Int32 = NullValues.Int32
        Dim dataTableNameLower As String = String.Empty

        dataTableNameLower = dataTableName.ToLower

        'retrieve the last haulage raw id to be used by all code paths
        haulageRawId = HaulageDal.GetLastHaulageRawId(Convert.ToInt32(destinationRow("HaulageRawId")))

        If dataTableNameLower = "haulage" Then
            'update haulage raw base record (and remember the new id value)
            'only Tonnes / Loads can change

            haulageRawId = HaulageDal.UpdateHaulageRaw(haulageRawId, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(True), Convert.ToDouble(sourceRow("Tonnes")), _
             Convert.ToInt16(True), Convert.ToInt32(sourceRow("Loads")), _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), Convert.ToInt16(NullValues.Boolean), _
             Convert.ToInt16(True))

            If SourceMatchesDigblockPattern(sourceRow("Source").ToString()) Then
                _bhpbioDigblockDal.ResolveBhpbioDataExceptionDigblockHasHaulage(sourceRow("Source").ToString())
            End If
        Else
            'request the udpate to the haulage raw record
            'note that we are NOT creating an audit child for each change
            HaulageDal.UpdateHaulageRaw(haulageRawId, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.Double, _
             Convert.ToInt16(False), NullValues.Int32, _
             Convert.ToInt16(False), NullValues.String, _
             Convert.ToInt16(False), NullValues.Int16, _
             Convert.ToInt16(False))

            If dataTableNameLower = "haulagegrade" Then
                'update the grade's head value field
                HaulageDal.AddOrUpdateHaulageRawGrade(haulageRawId, _
                 Convert.ToInt16(destinationRow("GradeId")), _
                 IfDBNull(sourceRow("HeadValue"), NullValues.Single))

                'update lump & fines grade values
                _bhpbioHaulageDal.AddOrUpdateBhpbioHaulageLumpFinesGrade(haulageRawId, Convert.ToInt16(destinationRow("GradeId")), _
                    IfDBNull(sourceRow("LumpValue"), NullValues.Single), IfDBNull(sourceRow("FinesValue"), NullValues.Single))

            ElseIf dataTableNameLower = "haulagevalue" Then
                'update the value's Value field
                HaulageDal.AddOrUpdateHaulageRawValue(haulageRawId, _
                 sourceRow("FieldId").ToString, _
                 IfDBNull(sourceRow("Value"), NullValues.Single))

            ElseIf dataTableNameLower = "haulagenotes" Then
                'update the note's Notes field
                HaulageDal.AddOrUpdateHaulageRawNotes(haulageRawId, _
                 sourceRow("FieldId").ToString, _
                 IfDBNull(sourceRow("Notes"), NullValues.String).ToString)
            End If
        End If

        'Save off the new haulage raw id
        destinationRow("HaulageRawId") = haulageRawId
    End Sub

    Protected Overrides Sub ProcessValidate(ByVal dataTableName As String, _
    ByVal sourceRow As DataRow, _
    ByVal destinationRow As DataRow, _
    ByVal importSyncValidate As DataTable, _
    ByVal importSyncValidateField As DataTable, _
    ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
    ByVal syncQueueRow As DataRow, _
    ByVal syncQueueChangedFields As DataTable, _
    ByVal importSyncDal As ImportSync)

        Dim importSyncValidateId As Int64
        Dim dataTableNameLower As String = String.Empty
        Dim validationMessage As String = String.Empty

        dataTableNameLower = dataTableName.ToLower

        'Check if this record has already been approved.

        If dataTableNameLower = "haulage" Then
            'check that the Tonnes and Loads > 0
            If syncAction = Data.SyncImportSyncActionEnumeration.Insert _
             Or syncAction = Data.SyncImportSyncActionEnumeration.Update Then
                If IfDBNull(sourceRow("Tonnes"), _negativeValue) <= 0 Then
                    If TypeOf (sourceRow("Tonnes")) Is DBNull Then
                        validationMessage = "Tonnes value was NULL."
                    Else
                        validationMessage = String.Format("Tonnes value was {0}.", sourceRow("Tonnes"))
                    End If
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                        "Tonnes value was less than or equal to 0 or was not specified.", _
                        validationMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Tonnes")
                End If

                If IfDBNull(sourceRow("Loads"), _negativeValue) <= 0 Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                        "Number of loads value was less than or equal to 0.", _
                        "Loads value was " + sourceRow("Loads").ToString & ".")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Loads")
                End If
            End If

        ElseIf dataTableNameLower = "haulagegrade" Then
            'check that the grade exists
            If syncAction = Data.SyncImportSyncActionEnumeration.Insert Then
                If Not ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).HasValue Then
                    validationMessage = String.Format("Grade name '{0}' does not exist.", sourceRow("GradeName"))
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                        validationMessage, validationMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "GradeName")
                End If
            End If

            'check the head grade value supplied is valid
            If syncAction = Data.SyncImportSyncActionEnumeration.Insert _
             OrElse syncAction = Data.SyncImportSyncActionEnumeration.Update Then
                If IfDBNull(sourceRow("HeadValue"), _negativeValue) < 0 Then
                    If TypeOf (sourceRow("HeadValue")) Is DBNull Then
                        validationMessage = String.Format("'{0}' grade head value was NULL.", sourceRow("GradeName"))
                    Else
                        validationMessage = String.Format("'{0}' grade head value was {1}.", sourceRow("GradeName"), sourceRow("HeadValue"))
                    End If
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                        "Grade head value was less than 0 or was not specified.", _
                        validationMessage)
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "HeadValue")
                End If
            End If

        ElseIf dataTableNameLower = "haulagevalue" Then
            'no checks - we should check for the field_id
            'this has not been done as it is prevalidated from the only known consumer

        ElseIf dataTableNameLower = "haulagenotes" Then
            'no checks - we should check for the field_id
            'this has not been done as it is prevalidated from the only known consumer

        End If
    End Sub

    ''' Implementation of the Core abstract method: not used because everything is done in LoadSource method
    Protected Overrides Sub LoadDataSet(ByVal sourceDataSet As System.Data.DataSet)
    End Sub

    ''' <summary>
    ''' Provides the source data required by the haulage import.
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
        Dim sourceExclusion As Generic.IList(Of String)

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A haulage source schema must be provided.")
        End If

        returnDataSet = New DataSet()
        returnDataSet.ReadXmlSchema(sourceSchema)
        returnDataSet.EnforceConstraints = False

        'load the data into the supplied ADO.NET dataset
        LoadSourceFromWebService(DateFrom, DateTo, Site, returnDataSet)

        'remove any records marked as "Error"
        For Each transactionRow In returnDataSet.Tables("Haulage").Select()
            If Convert.ToString(transactionRow("Type")) = "Error" Then
                transactionRow.Delete()
            End If
        Next

        'remove any records which are marked as "exclusions"
        sourceExclusion = Nothing
        GetExclusions(sourceExclusion)

        For Each transactionrow In returnDataSet.Tables("Haulage").Select()
            If sourceExclusion.Contains(Convert.ToString(transactionrow("Source")), _
             StringComparer.InvariantCultureIgnoreCase) Then
                transactionrow.Delete()
            End If
        Next

        returnDataSet.AcceptChanges()

        'check that we actually have "clean" data (i.e. all fields conform to their respective data types); if not, fail the import
        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try

        Return returnDataSet
    End Function

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)

    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
        MyBase.PreProcess(importSyncDal)
        'Set up the DAL object here
        HaulageDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalHaulage(importSyncDal.DataAccess.DataAccessConnection)
        UtilityDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(importSyncDal.DataAccess.DataAccessConnection)

        ReferenceDataCachedHelper.UtilityDal = DirectCast(UtilityDal, Bhpbio.Database.DalBaseObjects.IUtility)
        LocationDataCachedHelper.UtilityDal = DirectCast(UtilityDal, Bhpbio.Database.DalBaseObjects.IUtility)
        _bhpbioHaulageDal = DirectCast(HaulageDal, Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalHaulage)
    End Sub

    ''' <summary>
    ''' Loads the Haulage from the Haulage Service applying the partitions.
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

        Dim retrieveHaulageRequest1 As MQ2Service.retrieveHaulageRequest1
        Dim haulageRequest As MQ2Service.RetrieveHaulageRequest
        Dim retrieveHaulageResponse1 As MQ2Service.retrieveHaulageResponse1
        Dim haulageResponse As MQ2Service.RetrieveHaulageResponse
        Dim index As Integer

        mq2Client = WebServicesFactory.CreateMQ2WebServiceClient()

        haulageRequest = New MQ2Service.RetrieveHaulageRequest()
        haulageRequest.StartDateSpecified = True
        haulageRequest.EndDateSpecified = True
        haulageRequest.MineSiteCode = partitionSite

        Trace.WriteLine(String.Format("Loading from Web Service: Site = {0}, From = {1:dd-MMM-yyyy}, To = {2:dd-MMM-yyyy}", partitionSite, partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddDays(_numberOfDaysPerWebRequest)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine(String.Format("Requesting partition: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy} at {2:HH:mm:ss dd-MMM-yyyy}", currentDateFrom, currentDateTo, DateTime.Now))

            haulageRequest.StartDate = currentDateFrom.ToUniversalTime()
            haulageRequest.EndDate = currentDateTo.ToUniversalTime()

            retrieveHaulageRequest1 = New MQ2Service.retrieveHaulageRequest1(haulageRequest)
            Try
                retrieveHaulageResponse1 = mq2Client.retrieveHaulage(retrieveHaulageRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving haulage data from MQ2 web service.", ex)
            End Try

            haulageResponse = retrieveHaulageResponse1.RetrieveHaulageResponse

            If haulageResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    DateTime.Now, haulageResponse.Status.StatusMessage))
            End If

            If Not haulageResponse.Haulage Is Nothing Then
                For index = 0 To haulageResponse.Haulage.Length - 1
                    LoadHaulageRecord(haulageResponse.Haulage(index), returnDataSet)
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

    Private Sub LoadHaulageRecord(ByVal haulageTransaction As MQ2Service.HaulageTransactionType, ByVal returnDataSet As DataSet)
        Dim haulageTable As DataTable
        Dim haulageNotesTable As DataTable
        Dim haulageValueTable As DataTable
        Dim haulageGradeTable As DataTable
        Dim haulageRow As DataRow

        haulageTable = returnDataSet.Tables("Haulage")
        haulageNotesTable = returnDataSet.Tables("HaulageNotes")
        haulageValueTable = returnDataSet.Tables("HaulageValue")
        haulageGradeTable = returnDataSet.Tables("HaulageGrade")

        haulageRow = haulageTable.NewRow()
        haulageTable.Rows.Add(haulageRow)

        haulageRow("HaulageShift") = _settings.DefaultShift
        haulageRow("Truck") = _unknownTruck
        haulageRow("Loads") = _defaultLoads

        'ignore Location as it is ignored in the old code; new code: haulageTransaction.Location.Mine

        haulageRow("HaulageDate") = haulageTransaction.TransactionDate.ReadAsDateTimeWithDbNull(haulageTransaction.TransactionDateSpecified)
        haulageRow("Type") = haulageTransaction.Type.ReadStringWithDbNull()
        haulageRow("Source") = haulageTransaction.Source.ReadStringWithDbNull()
        haulageRow("SourceMineSite") = haulageTransaction.SourceMineSite.ReadStringWithDbNull()

        AddHaulageNote(haulageTransaction, haulageNotesTable, haulageRow, "SourceLocationType", haulageTransaction.SourceLocationType.ReadStringWithDbNull())

        haulageRow("Destination") = haulageTransaction.Destination.ReadStringWithDbNull()
        haulageRow("DestinationMineSite") = haulageTransaction.DestinationMineSite.ReadStringWithDbNull()

        PerformLocationNameTranslations(haulageTransaction, haulageRow)

        AddHaulageNote(haulageTransaction, haulageNotesTable, haulageRow, "DestLocationType", haulageTransaction.DestinationType.ReadStringWithDbNull())

        Dim lastModDate As Object = haulageTransaction.LastModifiedTime.ReadAsDateTimeWithDbNull(haulageTransaction.LastModifiedTimeSpecified)
        If Not lastModDate Is DBNull.Value Then
            AddHaulageNote(haulageTransaction, haulageNotesTable, haulageRow, "LastModifiedTime", (DirectCast(lastModDate, DateTime).ToString("dd-MMM-yyyy")))
        End If

        haulageRow("Tonnes") = haulageTransaction.BestTonnes.ReadAsDoubleWithDbNull(haulageTransaction.BestTonnesSpecified)

        AddHaulageValue(haulageTransaction, haulageValueTable, haulageRow, "HauledTonnes", _
            haulageTransaction.HauledTonnes.ReadAsDoubleWithDbNull(haulageTransaction.HauledTonnesSpecified))
        AddHaulageValue(haulageTransaction, haulageValueTable, haulageRow, "LumpPercent", _
            haulageTransaction.LumpPercent.ReadAsDoubleWithDbNull(haulageTransaction.LumpPercentSpecified))
        AddHaulageValue(haulageTransaction, haulageValueTable, haulageRow, "GroundSurveyTonnes", _
            haulageTransaction.GroundSurveyTonnes.ReadAsDoubleWithDbNull(haulageTransaction.GroundSurveyTonnesSpecified))
        AddHaulageValue(haulageTransaction, haulageValueTable, haulageRow, "AerialSurveyTonnes", _
            haulageTransaction.AerialSurveyTonnes.ReadAsDoubleWithDbNull(haulageTransaction.AerialSurveyTonnesSpecified))

        AddHaulageGrades(haulageTransaction, haulageGradeTable, haulageRow)
    End Sub

    Private Sub PerformLocationNameTranslations(ByVal haulageTransaction As MQ2Service.HaulageTransactionType, ByVal haulageRow As DataRow)
        If Not haulageTransaction.SourceLocationType Is Nothing _
            AndAlso TypeOf haulageRow("Source") Is String _
            AndAlso TypeOf haulageRow("SourceMineSite") Is String Then

            haulageRow("Source") = CodeTranslationHelper.RecodeTransaction(Convert.ToString(haulageRow("Source")), _
                haulageTransaction.SourceLocationType, Convert.ToString(haulageRow("SourceMineSite")))
        End If

        If Not haulageTransaction.DestinationType Is Nothing _
            AndAlso TypeOf haulageRow("Destination") Is String _
            AndAlso TypeOf haulageRow("DestinationMineSite") Is String Then

            haulageRow("Destination") = CodeTranslationHelper.RecodeTransaction( _
                Convert.ToString(haulageRow("Destination")), haulageTransaction.DestinationType, _
                Convert.ToString(haulageRow("DestinationMineSite")))
        End If
    End Sub

    Private Sub AddHaulageNote(ByVal haulageTransaction As MQ2Service.HaulageTransactionType, ByVal haulageNotesTable As DataTable, _
                                ByVal haulageRow As DataRow, ByVal fieldId As String, ByVal note As Object)

        If Not TypeOf (note) Is DBNull Then
            Dim haulageNotesRow As DataRow = haulageNotesTable.NewRow()
            haulageNotesRow("FieldId") = fieldId
            haulageNotesRow("Notes") = note
            haulageNotesRow.SetParentRow(haulageRow)
            haulageNotesTable.Rows.Add(haulageNotesRow)
        End If
    End Sub

    Private Sub AddHaulageValue(ByVal haulageTransaction As MQ2Service.HaulageTransactionType, ByVal haulageValueTable As DataTable, _
                                ByVal haulageRow As DataRow, ByVal fieldId As String, ByVal fieldValue As Object)

        If Not TypeOf (fieldValue) Is DBNull Then
            Dim haulageValueRow As DataRow = haulageValueTable.NewRow()
            haulageValueRow("FieldId") = fieldId
            haulageValueRow("Value") = Convert.ToDouble(fieldValue)
            haulageValueRow.SetParentRow(haulageRow)
            haulageValueTable.Rows.Add(haulageValueRow)
        End If
    End Sub

    Private Sub AddHaulageGrades(ByVal haulageTransaction As MQ2Service.HaulageTransactionType, ByVal haulageGradeTable As DataTable, ByVal haulageRow As DataRow)
        Dim haulageGradeRow As DataRow
        Dim index As Integer

        If Not haulageTransaction.Grade Is Nothing Then
            For index = 0 To haulageTransaction.Grade.Length - 1 Step 1
                If CodeTranslationHelper.RelevantGrades.Contains(haulageTransaction.Grade(index).Name, StringComparer.OrdinalIgnoreCase) Then
                    haulageGradeRow = haulageGradeTable.NewRow()
                    haulageGradeRow("GradeName") = haulageTransaction.Grade(index).Name
                    haulageGradeRow("HeadValue") = haulageTransaction.Grade(index).HeadValue.ReadAsDoubleWithDbNull(haulageTransaction.Grade(index).HeadValueSpecified)
                    haulageGradeRow("LumpValue") = haulageTransaction.Grade(index).LumpValue.ReadAsDoubleWithDbNull(haulageTransaction.Grade(index).LumpValueSpecified)
                    haulageGradeRow("FinesValue") = haulageTransaction.Grade(index).FinesValue.ReadAsDoubleWithDbNull(haulageTransaction.Grade(index).FinesValueSpecified)
                    haulageGradeRow.SetParentRow(haulageRow)
                    haulageGradeTable.Rows.Add(haulageGradeRow)
                End If
            Next
        End If
    End Sub

    'records a list of haulage codes to ignore
    Private Sub GetExclusions(ByRef returnSource As Generic.IList(Of String))
        Dim source As New Generic.List(Of String)
        Dim romStockpile As DataRow
        Dim romStockpiles As DataTable = Nothing
        Dim utilityDal As Bhpbio.Database.DalBaseObjects.IUtility

        utilityDal = New Bhpbio.Database.SqlDal.SqlDalUtility
        Try
            utilityDal.DataAccess.DataAccessConnection = ImportDal.DataAccess.DataAccessConnection

            ReferenceDataCachedHelper.UtilityDal = utilityDal
            romStockpiles = utilityDal.GetStockpileGroupStockpileList(_romStockpileGroup, 1, NullValues.Int32)

            For Each romStockpile In romStockpiles.Rows
                source.Add(Convert.ToString(romStockpile("Stockpile_Name")))
            Next
        Finally
            'disposing is bad as it releases the connection?
            utilityDal = Nothing

            If Not (romStockpiles Is Nothing) Then
                romStockpiles.Dispose()
                romStockpiles = Nothing
            End If
        End Try

        returnSource = source
    End Sub

    Protected Overrides Sub SetupDataAccessObjects()
        MyBase.SetupDataAccessObjects()

        ReferenceDataCachedHelper.UtilityDal = New Bhpbio.Database.SqlDal.SqlDalUtility(ImportSyncDal.DataAccess.DataAccessConnection)
        If _bhpbioDigblockDal Is Nothing Then
            _bhpbioDigblockDal = New Bhpbio.Database.SqlDal.SqlDalDigblock(ImportSyncDal.DataAccess.DataAccessConnection)
        End If
    End Sub
End Class
