Imports Snowden.Reconcilor.Core.Database
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Common.Import
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Import.Data
Imports Snowden.Reconcilor.Bhpbio.Import.MaterialTrackerService

' Only run on save data?
Friend NotInheritable Class Shipping
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _numberOfDaysPerWebRequest As Int32 = 28
    Private _settings As ConfigurationSettings
    Private Const _shippingGradeRelationName As String = "FK_NominationParcel_NominationParcelGrade"
    Private Const _shippingParcelRelationName As String = "FK_Nomination_NominationParcel"
    Private Const _minimumDateText As String = "1-Jan-1900"

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

    <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", MessageId:="port")> _
    Protected ReadOnly Property portImportDal() As IPortImport
        Get
            Return _portImportDal
        End Get
    End Property

    Protected ReadOnly Property UtilityDal() As IUtility
        Get
            Return _utilityDal
        End Get
    End Property

    Public Sub New()
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Shipping"
        SourceSchemaName = "Shipping"
        CanGenerateSourceSchema = False
        _settings = ConfigurationSettings.GetConfigurationSettings()
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

        ReferenceDataCachedHelper.UtilityDal = _utilityDal
        LocationDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, True))
        Return True
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)
        _dateTo = _dateTo.AddHours(23).AddMinutes(59).AddSeconds(59).AddMilliseconds(999)
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Dim OfficialFinishTime As DateTime
        OfficialFinishTime = Convert.ToDateTime(keyRows("OfficialFinishTime"))
        Return (OfficialFinishTime >= _dateFrom) And (OfficialFinishTime <= _dateTo)
    End Function

    Protected Overrides Sub PreCompare()
        'do nothing
    End Sub

    Protected Overrides Sub PostCompare()
        'do nothing
    End Sub

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As DataRow, _
                                               ByVal syncAction As SyncImportSyncActionEnumeration, ByVal syncQueueRow As DataRow, _
                                               ByVal importSyncDal As ImportSync)
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

        Dim bhpbioShippingNominationItemId As Int32
        Dim bhpbioShippingNominationItemParcelId As Int32
        Dim gradeId As Nullable(Of Int16)

        'find out the id (common to all rows)

        If dataTableName = "Nomination" Then
            bhpbioShippingNominationItemId = Convert.ToInt32(destinationRow("bhpbioShippingNominationItemId"))
            portImportDal.DeleteBhpbioShippingNominationItem(bhpbioShippingNominationItemId)

        ElseIf dataTableName = "NominationParcel" Then
            bhpbioShippingNominationItemParcelId = Convert.ToInt32(destinationRow("bhpbioShippingNominationItemParcelId"))
            portImportDal.DeleteBhpbioShippingNominationItemParcel(bhpbioShippingNominationItemParcelId)

        ElseIf dataTableName = "NominationParcelGrade" Then
            bhpbioShippingNominationItemParcelId = Convert.ToInt32(destinationRow("bhpbioShippingNominationItemParcelId"))
            gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)
            If gradeId Is Nothing Then
                Throw New DataException(String.Format("The grade '{0}' cannot be resolved.", sourceRow("GradeName")))
            End If

            portImportDal.AddOrUpdateBhpbioShippingNominationItemParcelGrade(bhpbioShippingNominationItemParcelId, gradeId.Value, NullValues.Single)
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim hubLocationId As Int32
        Dim bhpbioShippingNominationItemId As Int32
        Dim bhpbioShippingNominationItemParcelId As Int32

        Dim gradeId As Int16
        Dim customerNo As Int32
        Dim customerName As String

        If dataTableName = "Nomination" Then

            'add the new transaction nomination row
            If sourceRow("CustomerNo") Is DBNull.Value Then
                customerNo = NullValues.Int32
            Else
                customerNo = Convert.ToInt32(sourceRow("CustomerNo"))
            End If
            If sourceRow("CustomerName") Is DBNull.Value Then
                customerName = NullValues.String
            Else
                customerName = Convert.ToString(sourceRow("CustomerName"))
            End If

            bhpbioShippingNominationItemId = portImportDal.AddBhpbioShippingNominationItem( _
                 Convert.ToInt32(sourceRow("NominationKey")), _
                 Convert.ToInt32(sourceRow("ItemNo")), _
                 Convert.ToDateTime(sourceRow("OfficialFinishTime")), _
                 If(sourceRow("LastAuthorisedDate") Is DBNull.Value, DoNotSetValues.DateTime, Convert.ToDateTime(sourceRow("LastAuthorisedDate"))), _
                 sourceRow("VesselName").ToString, _
                 customerNo, _
                 customerName, _
                 sourceRow("ShippedProduct").ToString, _
                 sourceRow("ShippedProductSize").ToString, _
                 If(sourceRow("COA") Is DBNull.Value, DoNotSetValues.DateTime, Convert.ToDateTime(sourceRow("COA").ToString)), _
                 If(sourceRow("Undersize") Is DBNull.Value, DoNotSetValues.Double, Convert.ToDouble(sourceRow("Undersize").ToString)), _
                 If(sourceRow("Oversize") Is DBNull.Value, DoNotSetValues.Double, Convert.ToDouble(sourceRow("Oversize").ToString)))

            DataHelper.AddTableColumn(destinationRow.Table, "BhpbioShippingNominationItemId", GetType(String), Nothing)
            destinationRow("BhpbioShippingNominationItemId") = bhpbioShippingNominationItemId.ToString

        ElseIf dataTableName = "NominationParcel" Then

            hubLocationId = LocationDataCachedHelper.GetLocationId( _
             CodeTranslationHelper.HubCodeMESToReconcilor(sourceRow("Hub").ToString), _
             "Hub", Nothing).Value

            bhpbioShippingNominationItemId = Convert.ToInt32( _
                DirectCast(sourceRow.GetParentRow(_shippingParcelRelationName)("DestinationRow"), DataRow)("BhpbioShippingNominationItemId"))

            bhpbioShippingNominationItemParcelId = portImportDal.AddBhpbioShippingNominationItemParcel( _
                 bhpbioShippingNominationItemId, _
                 hubLocationId, _
                 sourceRow("HubProduct").ToString, _
                 sourceRow("HubProductSize").ToString, _
                 Convert.ToDouble(sourceRow("Tonnes")))

            DataHelper.AddTableColumn(destinationRow.Table, "BhpbioShippingNominationItemId", GetType(String), Nothing)
            destinationRow("BhpbioShippingNominationItemId") = bhpbioShippingNominationItemId.ToString

            DataHelper.AddTableColumn(destinationRow.Table, "BhpbioShippingNominationItemParcelId", GetType(String), Nothing)
            destinationRow("BhpbioShippingNominationItemParcelId") = bhpbioShippingNominationItemParcelId.ToString

        ElseIf dataTableName = "NominationParcelGrade" Then
            Dim parentRow As DataRow = sourceRow.GetParentRow(_shippingGradeRelationName)
            If (parentRow Is Nothing) Then
                Throw New Exception("Missing parent relation for shipping nomination parcel grade.")
            End If
            Dim destinationShippingNominationRow As DataRow = DirectCast(parentRow("DestinationRow"), DataRow)

            'find out the parent's id
            bhpbioShippingNominationItemParcelId = Convert.ToInt32(destinationShippingNominationRow("BhpbioShippingNominationItemParcelId"))

            gradeId = ReferenceDataCachedHelper.GetGradeId(Convert.ToString(sourceRow("GradeName"))).Value

            portImportDal.AddOrUpdateBhpbioShippingNominationItemParcelGrade(bhpbioShippingNominationItemParcelId, _
             gradeId, Convert.ToSingle(sourceRow("HeadValue")))

            DataHelper.AddTableColumn(destinationRow.Table, "BhpbioShippingNominationItemParcelId", GetType(String), Nothing)
            destinationRow("BhpbioShippingNominationItemParcelId") = bhpbioShippingNominationItemParcelId.ToString

            'save the grade's id
            DataHelper.AddTableColumn(destinationRow.Table, "GradeId", GetType(String), Nothing)
            destinationRow("GradeId") = gradeId.ToString
        End If

        'save the id that was used (for all records)
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim hubLocationId As Int32
        Dim bhpbioShippingNominationItemId As Int32
        Dim bhpbioShippingNominationItemParcelId As Int32
        Dim gradeId As Int16
        Dim customerNo As Int32
        Dim customerName As String

        If dataTableName = "Nomination" Then

            'add the new transaction nomination row
            If sourceRow("CustomerNo") Is DBNull.Value Then
                customerNo = NullValues.Int32
            Else
                customerNo = Convert.ToInt32(sourceRow("CustomerNo"))
            End If
            If sourceRow("CustomerName") Is DBNull.Value Then
                customerName = NullValues.String
            Else
                customerName = Convert.ToString(sourceRow("CustomerName"))
            End If
            bhpbioShippingNominationItemId = Convert.ToInt32(destinationRow("BhpbioShippingNominationItemId"))

            portImportDal.UpdateBhpbioShippingNominationItem( _
                 bhpbioShippingNominationItemId, _
                 Convert.ToInt32(sourceRow("NominationKey")), _
                 Convert.ToInt32(sourceRow("ItemNo")), _
                 Convert.ToDateTime(sourceRow("OfficialFinishTime")), _
                 If(sourceRow("LastAuthorisedDate") Is DBNull.Value, DoNotSetValues.DateTime, Convert.ToDateTime(sourceRow("LastAuthorisedDate"))), _
                 sourceRow("VesselName").ToString, _
                 customerNo, _
                 customerName, _
                 sourceRow("ShippedProduct").ToString, _
                 sourceRow("ShippedProductSize").ToString, _
                 If(sourceRow("COA") Is DBNull.Value, DoNotSetValues.DateTime, Convert.ToDateTime(sourceRow("COA").ToString)), _
                 If(sourceRow("Undersize") Is DBNull.Value, DoNotSetValues.Double, Convert.ToDouble(sourceRow("Undersize").ToString)), _
                 If(sourceRow("Oversize") Is DBNull.Value, DoNotSetValues.Double, Convert.ToDouble(sourceRow("Oversize").ToString)))

        ElseIf dataTableName = "NominationParcel" Then
            bhpbioShippingNominationItemParcelId = Convert.ToInt32(destinationRow("bhpbioShippingNominationItemParcelId"))

            hubLocationId = LocationDataCachedHelper.GetLocationId( _
             CodeTranslationHelper.HubCodeMESToReconcilor(sourceRow("Hub").ToString), _
             "Hub", Nothing).Value

            portImportDal.UpdateBhpbioShippingNominationItemParcel( _
                bhpbioShippingNominationItemParcelId, _
                 bhpbioShippingNominationItemId, _
                 hubLocationId, _
                 sourceRow("HubProduct").ToString, _
                 sourceRow("HubProductSize").ToString, _
                 Convert.ToDouble(sourceRow("Tonnes")))

        ElseIf dataTableName = "NominationParcelGrade" Then
            bhpbioShippingNominationItemParcelId = Convert.ToInt32(destinationRow("BhpbioShippingNominationItemParcelId"))

            gradeId = Convert.ToInt16(destinationRow("GradeId"))

            portImportDal.AddOrUpdateBhpbioShippingNominationItemParcelGrade(bhpbioShippingNominationItemParcelId, _
                gradeId, Convert.ToSingle(sourceRow("HeadValue")))
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
        Dim hubLocationId As Int32?
        Dim validationMessage As String = String.Empty

        DataHelper.AddTableColumn(destinationRow.Table, "BhpbioShippingNominationItemId", GetType(String), Nothing)

        If dataTableName = "Nomination" Then

        ElseIf dataTableName = "NominationParcel" Then

            'check that the Tonnes > 0
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
             Or syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then
                If DirectCast(sourceRow("Tonnes"), Double) <= 0 Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                     Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                     "Tonnes value was less than or equal to 0.", _
                     "Tonnes value was " + sourceRow("Tonnes").ToString & ".")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Tonnes")
                End If

                hubLocationId = LocationDataCachedHelper.GetLocationId( _
                 CodeTranslationHelper.HubCodeMESToReconcilor(DirectCast(sourceRow("Hub"), String)), "Hub", Nothing)
                If Not hubLocationId.HasValue Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                     Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                     "The Hub cannot be resolved.", _
                     "The Hub value was " + sourceRow("Hub").ToString & ".")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Hub")
                End If
            End If

        ElseIf dataTableName = "NominationParcelGrade" Then
            'check that the grade exists
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert Then
                If Not ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).HasValue Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                     Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                     "Grade name does not exist.", "Grade name does not exist.")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "GradeName")
                End If
            End If

            'check the grade value supplied is valid
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
             OrElse syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then
                If DirectCast(sourceRow("HeadValue"), Double) < 0 Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                     Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                     "Grade value was less than 0.", _
                     "Grade value was " + sourceRow("HeadValue").ToString & ".")
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "HeadValue")
                End If
            End If
        End If
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)

    End Sub

    Protected Overrides Function LoadSource(ByVal sourceSchema As System.IO.StringReader) As System.Data.DataSet
        Dim returnDataSet As DataSet = Nothing

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A source shipping schema must be provided.")
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
        Dim retrieveShippingRequest1 As retrieveShippingRequest1
        Dim shippingRequest As RetrieveShippingRequest
        Dim retrieveShippingResponse1 As retrieveShippingResponse1
        Dim shippingResponse As RetrieveShippingResponse
        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime

        'create a new wcf-client instance
        client = WebServicesFactory.CreateMaterialTrackerWebServiceClient()

        'create the parameters once and set the mine-site
        shippingRequest = New RetrieveShippingRequest()
        shippingRequest.StartDateSpecified = True
        shippingRequest.EndDateSpecified = True

        Trace.WriteLine(String.Format("Loading from Web Service: From = {0:dd-MMM-yyyy}, To = {1:dd-MMM-yyyy}", partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddDays(_numberOfDaysPerWebRequest).AddHours(23).AddMinutes(59).AddSeconds(59).AddMilliseconds(999)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine("Requesting: " & currentDateFrom.ToString("O") & " to " & currentDateTo.ToString("O"))

            shippingRequest.StartDate = currentDateFrom.ToUniversalTime()
            shippingRequest.EndDate = currentDateTo.ToUniversalTime()

            'create a new request and invoke it
            retrieveShippingRequest1 = New retrieveShippingRequest1(shippingRequest)
            retrieveShippingResponse1 = client.retrieveShipping(retrieveShippingRequest1)
            shippingResponse = retrieveShippingResponse1.RetrieveShippingResponse

            'check we received a payload - we always expect one
            If shippingResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    DateTime.Now, shippingResponse.Status.StatusMessage))
            End If

            If Not shippingResponse.Shipping Is Nothing Then
                For index As Integer = 0 To (shippingResponse.Shipping.Length - 1)
                    LoadShippingNomination(shippingResponse.Shipping(index), returnDataSet)
                Next
            End If

            'increment the date range
            currentDateFrom = currentDateFrom.AddDays(_numberOfDaysPerWebRequest).AddDays(1)
            currentDateTo = currentDateTo.AddDays(_numberOfDaysPerWebRequest).AddDays(1)
            If currentDateTo >= partitionDateTo Then
                currentDateTo = partitionDateTo
            End If
        End While

        returnDataSet.AcceptChanges()
    End Sub

    ''' <summary>
    ''' Loads the single Shipping element contained within the payload.
    ''' </summary>
    Private Sub LoadShippingNomination(ByVal shipping As ShippingTransactionType, ByVal returnDataSet As DataSet)

        Dim nominationTable As DataTable
        Dim nominationParcelTable As DataTable
        Dim nominationParcelGradeTable As DataTable
        Dim nominationRow As DataRow

        returnDataSet.EnforceConstraints = False

        nominationTable = returnDataSet.Tables("Nomination")
        nominationParcelTable = returnDataSet.Tables("NominationParcel")
        nominationParcelGradeTable = returnDataSet.Tables("NominationParcelGrade")

        nominationRow = nominationTable.NewRow()
        nominationTable.Rows.Add(nominationRow)

        nominationRow("NominationKey") = shipping.NominationKey.ReadStringWithDbNull()
        nominationRow("VesselName") = shipping.VesselName.ReadStringWithDbNull()
        If Not shipping.NominationItem Is Nothing Then
            nominationRow("ItemNo") = shipping.NominationItem.ItemNo.ReadStringWithDbNull()
            nominationRow("OfficialFinishTime") = shipping.NominationItem.OfficialFinishTime.ReadAsDateTimeWithDbNull(shipping.NominationItem.OfficialFinishTimeSpecified)
            nominationRow("LastAuthorisedDate") = shipping.NominationItem.LastAuthorisedDate.ReadAsDateTimeWithDbNull(shipping.NominationItem.LastAuthorisedDateSpecified)
            nominationRow("CustomerNo") = shipping.NominationItem.CustomerNo.ReadStringAsInt32WithDbNull()
            nominationRow("CustomerName") = shipping.NominationItem.CustomerName.ReadStringWithDbNull()
            nominationRow("COA") = shipping.NominationItem.COA.ReadAsDateTimeWithDbNull(shipping.NominationItem.COASpecified)
            nominationRow("Undersize") = shipping.NominationItem.Undersize.ReadAsDoubleWithDbNull(shipping.NominationItem.UndersizeSpecified)
            nominationRow("Oversize") = shipping.NominationItem.Oversize.ReadAsDoubleWithDbNull(shipping.NominationItem.OversizeSpecified)
            nominationRow("ShippedProduct") = shipping.NominationItem.ShippedProduct.ReadStringWithDbNull()
            nominationRow("ShippedProductSize") = shipping.NominationItem.ShippedProductSize.ReadStringWithDbNull()
        End If

        If Not shipping.NominationItem.HubItem Is Nothing Then
            For index As Integer = 0 To shipping.NominationItem.HubItem.Length - 1
                LoadNominationParcel(shipping.NominationItem.HubItem(index), nominationRow, nominationParcelTable, nominationParcelGradeTable)
            Next
        End If

        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try
    End Sub

    Private Sub LoadNominationParcel(ByVal hubItem As HubItemType, ByVal nominationRow As DataRow, ByVal nominationParcelTable As DataTable, ByVal nominationParcelGradeTable As DataTable)
        Dim nominationParcelRow As DataRow

        nominationParcelRow = nominationParcelTable.NewRow()
        nominationParcelRow.SetParentRow(nominationRow)
        nominationParcelTable.Rows.Add(nominationParcelRow)

        nominationParcelRow("NominationKey") = nominationRow("NominationKey")
        nominationParcelRow("ItemNo") = nominationRow("ItemNo")
        nominationParcelRow("OfficialFinishTime") = nominationRow("OfficialFinishTime")
        nominationParcelRow("Hub") = hubItem.Hub.ReadStringWithDbNull()
        nominationParcelRow("HubProduct") = hubItem.HubProduct.ReadStringWithDbNull()
        nominationParcelRow("HubProductSize") = hubItem.HubProductSize.ReadStringWithDbNull()
        nominationParcelRow("Tonnes") = hubItem.Tonnes.ReadAsDoubleWithDefault(hubItem.TonnesSpecified, 0.0)

        If Not hubItem.Grade Is Nothing Then
            For index As Integer = 0 To hubItem.Grade.Length - 1
                LoadNominationParcelGrade(hubItem.Grade(index), nominationParcelRow, nominationParcelGradeTable)
            Next
        End If
    End Sub

    Private Sub LoadNominationParcelGrade(ByVal grade As Grade, ByVal nominationParcelRow As DataRow, ByVal nominationParcelGradeTable As DataTable)
        Dim nominationParcelGradeRow As DataRow
        Dim gradeCode As Object
        Dim gradeName As String

        gradeCode = grade.Name.ReadStringWithDbNull()
        If TypeOf gradeCode Is String Then

            gradeName = CodeTranslationHelper.GradeCodeBhpbioToReconcilor(DirectCast(gradeCode, String))

            If Not String.IsNullOrEmpty(gradeName) Then
                nominationParcelGradeRow = nominationParcelGradeTable.NewRow()
                nominationParcelGradeRow.SetParentRow(nominationParcelRow)
                nominationParcelGradeTable.Rows.Add(nominationParcelGradeRow)
                nominationParcelGradeRow("NominationKey") = nominationParcelRow("NominationKey")
                nominationParcelGradeRow("ItemNo") = nominationParcelRow("ItemNo")
                nominationParcelGradeRow("OfficialFinishTime") = nominationParcelRow("OfficialFinishTime")
                nominationParcelGradeRow("Hub") = nominationParcelRow("Hub")
                nominationParcelGradeRow("GradeName") = grade.Name.ReadStringWithDbNull()
                nominationParcelGradeRow("HeadValue") = grade.HeadValue.ReadAsDoubleWithDbNull(grade.HeadValueSpecified)
            End If
        End If
    End Sub

End Class
