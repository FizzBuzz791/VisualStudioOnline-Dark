Imports Snowden.Reconcilor.Core.Database
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Common.Import
Imports Snowden.Common.Database.DataAccessBaseObjects.DoNotSetValues
Imports Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Import.Database
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Import.MaterialTrackerService
Imports Snowden.Common.Import.Data

Friend NotInheritable Class PortBlending
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _portBlendingGradeRelationName As String = "FK_PortBlending_PortBlendingGrade"
    Private Const _minimumDateText As String = "1-Jan-1900"

    Private _settings As ConfigurationSettings
    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _utilityDal As IUtility
    Private _portImportDal As IPortImport

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

    Public Sub New(Optional config As ConfigurationSettings = Nothing)
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "PortBlending"
        SourceSchemaName = "PortBlending"
        CanGenerateSourceSchema = False
        _settings = ConfigurationSettings.GetConfigurationSettings(config)
    End Sub

    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If (Not _disposed) Then
                If (disposing) Then
                    If (Not _portImportDal Is Nothing) Then
                        _portImportDal.Dispose()
                        _portImportDal = Nothing
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
        _portImportDal = New SqlDalPortImport(DestinationDataAccessConnection)
        _utilityDal = New SqlDalUtility(DestinationDataAccessConnection)

        LocationDataCachedHelper.UtilityDal = _utilityDal
        ReferenceDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, True))
        Return True
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)

        'recalculate the start/end dates
        'the from date needs to be pushed back to the first of the nearest month requested
        'the to date needs to be pushed forward to the last second of the month requested

        _dateFrom = New DateTime(_dateFrom.Year, _dateFrom.Month, 1)
        _dateTo = New DateTime(_dateTo.Year, _dateTo.Month, 1).AddMonths(1).AddMilliseconds(-1)
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Dim startDate As DateTime
        Dim endDate As DateTime

        startDate = Convert.ToDateTime(keyRows("StartDate"))
        endDate = Convert.ToDateTime(keyRows("EndDate"))

        Return (endDate >= _dateFrom) And (startDate <= _dateTo)
    End Function

    Protected Overrides Sub PreCompare()
        'do nothing
    End Sub

    Protected Overrides Sub PostCompare()
        'do nothing
    End Sub

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)

    End Sub

    ''' <remarks>
    ''' No checks necessary as I am the only process that manages these tables.
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

    End Sub

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim bhpbioPortBlendingId As Int32
        Dim gradeId As Int16

        bhpbioPortBlendingId = Convert.ToInt32(destinationRow("BhpbioPortBlendingId"))

        If dataTableName = "PortBlending" Then

            _portImportDal.DeleteBhpbioPortBlending(bhpbioPortBlendingId)

        ElseIf dataTableName = "PortBlendingGrade" Then

            gradeId = Convert.ToInt16(destinationRow("GradeId"))
            _portImportDal.AddUpdateDeleteBhpbioPortBlendingGrade(bhpbioPortBlendingId, gradeId, NullValues.Single)
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim sourceHubLocationId As Int32?
        Dim destinationHubLocationId As Int32?
        Dim loadSiteLocationId As Int32?
        Dim sourceProductSize As String
        Dim destinationProductSize As String
        Dim bhpbioPortBlendingId As Int32
        Dim gradeId As Int16?

        If dataTableName = "PortBlending" Then
            sourceHubLocationId = LocationDataCachedHelper.GetLocationId( _
                CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("SourceHub"))), "Hub", Nothing)

            destinationHubLocationId = LocationDataCachedHelper.GetLocationId( _
                CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("DestinationHub"))), "Hub", Nothing)

            loadSiteLocationId = LocationDataCachedHelper.GetLocationId( _
                CodeTranslationHelper.Mq2SiteToReconcilor(Convert.ToString(sourceRow("LoadSites"))), "Site", Nothing)

            If sourceRow("SourceProductSize") Is DBNull.Value Then
                sourceProductSize = NullValues.String
            Else
                sourceProductSize = Convert.ToString(sourceRow("SourceProductSize"))
            End If
            If sourceRow("DestinationProductSize") Is DBNull.Value Then
                destinationProductSize = NullValues.String
            Else
                destinationProductSize = Convert.ToString(sourceRow("DestinationProductSize"))
            End If

            'add the new transaction nomination row
            bhpbioPortBlendingId = _portImportDal.AddBhpbioPortBlending( _
                sourceHubLocationId.Value, destinationHubLocationId.Value, _
                Convert.ToString(sourceRow("SourceProduct")), sourceProductSize, _
                Convert.ToString(sourceRow("DestinationProduct")), destinationProductSize, _
                Convert.ToDateTime(sourceRow("StartDate")), Convert.ToDateTime(sourceRow("EndDate")), _
                loadSiteLocationId.Value, Convert.ToDouble(sourceRow("Tonnes")))

        ElseIf dataTableName = "PortBlendingGrade" Then
            'resolve grade name
            gradeId = ReferenceDataCachedHelper.GetGradeId(Convert.ToString(sourceRow("GradeName")))
            If Not gradeId.HasValue Then
                Throw New MissingFieldException(String.Format("The grade name '{0}' could not be resolved.", sourceRow("GradeName")))
            End If

            'find out the parent's id
            bhpbioPortBlendingId = Convert.ToInt32( _
                DirectCast(sourceRow.GetParentRow(_portBlendingGradeRelationName)("DestinationRow"), DataRow)("BhpbioPortBlendingId"))

            _portImportDal.AddUpdateDeleteBhpbioPortBlendingGrade(bhpbioPortBlendingId, _
                gradeId.Value, Convert.ToSingle(sourceRow("HeadValue")))

            'save the grade that was used
            DataHelper.AddTableColumn(destinationRow.Table, "GradeId", GetType(String), Nothing)
            destinationRow("GradeId") = gradeId.ToString
        End If

        'save the blending id that was used (for all records)
        DataHelper.AddTableColumn(destinationRow.Table, "BhpbioPortBlendingId", GetType(String), Nothing)
        destinationRow("BhpbioPortBlendingId") = bhpbioPortBlendingId.ToString
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim bhpbioPortBlendingId As Int32
        Dim sourceProductSize As String
        Dim destinationProductSize As String
        Dim gradeId As Int16

        'find out the id (common to all rows)
        bhpbioPortBlendingId = Convert.ToInt32(destinationRow("BhpbioPortBlendingId"))

        If dataTableName = "PortBlending" Then

            If sourceRow("SourceProductSize") Is DBNull.Value Then
                sourceProductSize = NullValues.String
            Else
                sourceProductSize = Convert.ToString(sourceRow("SourceProductSize"))
            End If
            If sourceRow("DestinationProductSize") Is DBNull.Value Then
                destinationProductSize = NullValues.String
            Else
                destinationProductSize = Convert.ToString(sourceRow("DestinationProductSize"))
            End If

            _portImportDal.UpdateBhpbioPortBlending(bhpbioPortBlendingId, sourceProductSize, destinationProductSize, Convert.ToDouble(sourceRow("Tonnes")))

        ElseIf dataTableName = "PortBlendingGrade" Then

            gradeId = Convert.ToInt16(destinationRow("GradeId"))
            _portImportDal.AddUpdateDeleteBhpbioPortBlendingGrade(bhpbioPortBlendingId, gradeId, Convert.ToSingle(sourceRow("HeadValue")))
        End If
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
        Dim locationId As Int32?
        Dim validationMessage As String = String.Empty

        locationId = LocationDataCachedHelper.GetLocationId( _
            CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("SourceHub"))), "Hub", Nothing)
        If Not locationId.HasValue Then
            importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                "The Source Hub cannot be resolved.", _
                String.Format("The Source Hub value was '{0}'.", sourceRow("SourceHub")))
            SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "SourceHub")
        End If

        locationId = LocationDataCachedHelper.GetLocationId( _
            CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("DestinationHub"))), _
            "Hub", Nothing)
        If Not locationId.HasValue Then
            importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                "The Destination Hub cannot be resolved.", _
                String.Format("The Destination Hub value was '{0}'.", sourceRow("DestinationHub")))
            SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "DestinationHub")
        End If

        locationId = LocationDataCachedHelper.GetLocationId( _
            CodeTranslationHelper.Mq2SiteToReconcilor(Convert.ToString(sourceRow("LoadSites"))), _
            "Site", Nothing)
        If Not locationId.HasValue Then
            importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                "The Load Site cannot be resolved.", _
                String.Format("The Load Site value was '{0}'.", sourceRow("LoadSites")))
            SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "LoadSites")
        End If

        If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
            Or syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then

            If dataTableName = "PortBlending" Then
                'check that the Tonnes > 0
                If syncAction = SyncImportSyncActionEnumeration.Insert Or syncAction = SyncImportSyncActionEnumeration.Update Then
                    If Convert.ToDouble(sourceRow("Tonnes")) <= 0 Then
                        importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                            Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                            "Tonnes value was less than or equal to 0.", _
                            String.Format("Tonnes value was '{0}'.", sourceRow("Tonnes")))
                        SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Tonnes")
                    End If
                End If

            ElseIf dataTableName = "PortBlendingGrade" Then
                'check that the grade exists
                If syncAction = SyncImportSyncActionEnumeration.Insert Then
                    If Not ReferenceDataCachedHelper.GetGradeId(Convert.ToString(sourceRow("GradeName"))).HasValue Then
                        validationMessage = "Grade name does not exist."
                        importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                            Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)
                        SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "GradeName")
                    End If
                End If

                'check the grade value supplied is valid
                If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
                 OrElse syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then
                    If Convert.ToDouble(sourceRow("HeadValue")) < 0 Then
                        importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                            Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                            "Grade value was less than 0.", _
                            String.Format("Grade value was '{0}'.", sourceRow("HeadValue")))
                        SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "HeadValue")
                    End If
                End If
            End If
        End If
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    ''' <summary>
    ''' Provides the source data required by the port blending import.
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
            Throw New ArgumentException("A source port blending schema must be provided.")
        Else
            returnDataSet = New DataSet()
            returnDataSet.ReadXmlSchema(sourceSchema)
        End If

        'load the data into the supplied ADO.NET dataset
        LoadSourceFromWebService(DateFrom, DateTo, returnDataSet)

        'set all row versions as "unmodified"
        returnDataSet.AcceptChanges()

        Return returnDataSet
    End Function

    Public Sub LoadSourceFromWebService(ByVal partitionDateFrom As DateTime, ByVal partitionDateTo As DateTime, ByVal returnDataSet As DataSet)

        Dim client As MaterialTrackerService.IM_MT_DS
        Dim retrievePortBlendingRequest1 As retrievePortBlendingRequest1
        Dim portBlendingRequest As RetrievePortBlendingRequest
        Dim retrievePortBlendingResponse1 As retrievePortBlendingResponse1
        Dim portBlendingResponse As RetrievePortBlendingResponse
        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime

        'create a new wcf-client instance
        client = WebServicesFactory.CreateMaterialTrackerWebServiceClient()

        'create the parameters once
        portBlendingRequest = New RetrievePortBlendingRequest()
        portBlendingRequest.StartDateSpecified = True
        portBlendingRequest.EndDateSpecified = True

        Trace.WriteLine(String.Format("Loading from Web Service: From = {0:dd-MMM-yyyy}, To = {1:dd-MMM-yyyy}", partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddMonths(1).AddMilliseconds(-1)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine(String.Format("Requesting partition: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy}", currentDateFrom, currentDateTo))

            portBlendingRequest.StartDate = currentDateFrom.ToUniversalTime
            portBlendingRequest.EndDate = currentDateTo.ToUniversalTime

            'create a new request and invoke it
            retrievePortBlendingRequest1 = New retrievePortBlendingRequest1(portBlendingRequest)
            Try
                retrievePortBlendingResponse1 = client.retrievePortBlending(retrievePortBlendingRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving port blending data from Material Tracker web service.", ex)
            End Try
            portBlendingResponse = retrievePortBlendingResponse1.RetrievePortBlendingResponse

            'check we received a payload - we always expect one
            If portBlendingResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", System.DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    System.DateTime.Now, portBlendingResponse.Status.StatusMessage))
            End If

            If Not portBlendingResponse.PortBlending Is Nothing Then
                For index As Integer = 0 To portBlendingResponse.PortBlending.Length - 1
                    LoadPortBlending(portBlendingResponse.PortBlending(index), returnDataSet)
                Next
            End If

            'increment the date range
            currentDateFrom = currentDateFrom.AddMonths(1)
            currentDateTo = currentDateTo.AddDays(1).AddMonths(1).AddDays(-1)
            If currentDateTo >= partitionDateTo Then
                currentDateTo = partitionDateTo
            End If
        End While

        returnDataSet.AcceptChanges()
    End Sub

    ''' <summary>
    ''' Loads the single Port Blending element contained within the payload.
    ''' </summary>
    Private Sub LoadPortBlending(ByVal blendingMovement As BlendingMovementType, ByVal returnDataSet As DataSet)

        Dim portBlendingTable As DataTable
        Dim portBlendingGradeTable As DataTable
        Dim portBlendingRow As DataRow

        returnDataSet.EnforceConstraints = False

        portBlendingTable = returnDataSet.Tables("PortBlending")
        portBlendingGradeTable = returnDataSet.Tables("PortBlendingGrade")
        portBlendingRow = portBlendingTable.NewRow()
        portBlendingTable.Rows.Add(portBlendingRow)

        portBlendingRow("SourceProduct") = blendingMovement.SourceProduct.ReadStringWithDbNull()
        portBlendingRow("DestinationProduct") = blendingMovement.DestinationProduct.ReadStringWithDbNull()
        portBlendingRow("SourceHub") = blendingMovement.SourceHub.ReadStringWithDbNull()
        portBlendingRow("DestinationHub") = blendingMovement.DestinationHub.ReadStringWithDbNull()
        portBlendingRow("StartDate") = blendingMovement.StartDate.ReadAsDateTimeWithDbNull(blendingMovement.StartDateSpecified)
        portBlendingRow("EndDate") = blendingMovement.EndDate.ReadAsDateTimeWithDbNull(blendingMovement.EndDateSpecified)
        portBlendingRow("LoadSites") = blendingMovement.LoadSites.ReadStringWithDbNull()
        portBlendingRow("SourceProductSize") = blendingMovement.SourceProductSize.ReadStringWithDbNull()
        portBlendingRow("DestinationProductSize") = blendingMovement.DestinationProductSize.ReadStringWithDbNull()
        portBlendingRow("Tonnes") = blendingMovement.Tonnes.ReadAsDoubleWithDbNull(blendingMovement.TonnesSpecified)
        'Grades
        LoadPortBlendingGrades(blendingMovement, portBlendingRow, portBlendingGradeTable)

        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try
    End Sub

    Private Sub LoadPortBlendingGrades(ByVal blendingMovement As BlendingMovementType, ByVal portBlendingRow As DataRow, ByVal portBlendingGradeTable As DataTable)
        If Not blendingMovement.Grade Is Nothing Then
            Dim portBlendingGradeRow As DataRow

            If Not blendingMovement.Grade Is Nothing Then
                For index As Integer = 0 To blendingMovement.Grade.Length - 1
                    Dim gradeName As String = CodeTranslationHelper.GetRelevantGrade(blendingMovement.Grade(index).Name.ReadStringWithDbNull())

                    If Not gradeName Is Nothing Then
                        portBlendingGradeRow = portBlendingGradeTable.NewRow()
                        portBlendingGradeRow("GradeName") = blendingMovement.Grade(index).Name.ReadStringWithDbNull()
                        portBlendingGradeRow("HeadValue") = blendingMovement.Grade(index).HeadValue.ReadAsDoubleWithDbNull(blendingMovement.Grade(index).HeadValueSpecified)
                        portBlendingGradeRow.SetParentRow(portBlendingRow)
                        portBlendingGradeTable.Rows.Add(portBlendingGradeRow)
                    End If
                Next
            End If
        End If
    End Sub

End Class