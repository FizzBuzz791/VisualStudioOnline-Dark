Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Core.Database
Imports Snowden.Common.Import
Imports Snowden.Common.Import.Data
Imports Snowden.Common.Import.Database
Imports Snowden.Common.Database.DataAccessBaseObjects.DoNotSetValues
Imports Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Import.MaterialTrackerService

Friend NotInheritable Class PortBalances
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _numberOfDaysPerWebRequest As Int32 = 30
    Private Const _defaultProduct As String = "Unknown"
    Private Const _defaultProductSize As String = "TOTAL"

    Private _settings As ConfigurationSettings

    Private _dates As IList(Of DateTime)
    Private _utilityDal As IUtility
    Private _portImportDal As IPortImport
    Private _disposed As Boolean

    Protected ReadOnly Property Dates() As IList(Of DateTime)
        Get
            Return _dates
        End Get
    End Property

    Public Sub New(Optional config As ConfigurationSettings = Nothing)
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "PortBalance"
        SourceSchemaName = "PortBalance"
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

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, True))
        Return True
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        Dim dateFrom As DateTime
        Dim dateTo As DateTime
        Dim currentDate As DateTime
        Dim requestDates As IList(Of DateTime)

        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, dateFrom, dateTo)

        'calculate the distinct list of month-end dates for the given date from/to range
        requestDates = New Generic.List(Of DateTime)
        currentDate = dateFrom
        While currentDate <= dateTo
            If currentDate.AddDays(1).Day = 1 Then
                requestDates.Add(currentDate)
            End If

            currentDate = currentDate.AddDays(1)
        End While
        _dates = requestDates
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Return _dates.Contains(DirectCast(keyRows("BalanceDate"), DateTime))
    End Function

    Protected Overrides Sub ProcessPrepareData(ByVal dataTableName As String, ByVal sourceRow As System.Data.DataRow, ByVal destinationRow As System.Data.DataRow, ByVal syncAction As Common.Import.Data.SyncImportSyncActionEnumeration, ByVal syncQueueRow As System.Data.DataRow, ByVal importSyncDal As Common.Import.Database.ImportSync)

    End Sub

    Protected Overrides Sub SetupDataAccessObjects()

    End Sub

    Protected Overrides Sub PreCompare()
        'Set up the DAL object here
        _portImportDal = New SqlDalPortImport(DestinationDataAccessConnection)
        _utilityDal = New SqlDalUtility(DestinationDataAccessConnection)

        ReferenceDataCachedHelper.UtilityDal = _utilityDal
        LocationDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Sub PostCompare()
        'do nothing
    End Sub

    ''' <remarks>
    ''' No checks necessary as I am the only process that manages these tables.
    ''' </remarks>
    Protected Overrides Sub ProcessConflict(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal importSyncConflict As DataTable, _
     ByVal importSyncConflictField As DataTable, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

    End Sub

    Protected Overrides Sub ProcessDelete(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        If dataTableName = "PortBalance" Then
            Dim bhpbioPortBalancesId As Int32 = Convert.ToInt32(Convert.ToString(destinationRow("bhpbioPortBalanceId")))
            'deletes both, PortBalance and PortBalanceGrade records
            _portImportDal.DeleteBhpbioPortBalances(bhpbioPortBalancesId)
        End If
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim hubLocationId As Int32
        Dim bhpbioPortBalanceId As Int32
        Dim gradeId As Int16?
        Dim gradeValue As Double
        Dim destinationPortBalanceRow As DataRow

        DataHelper.AddTableColumn(destinationRow.Table, "BhpbioPortBalanceId", GetType(String), Nothing)

        If dataTableName = "PortBalance" Then

            hubLocationId = LocationDataCachedHelper.GetLocationId( _
                CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("Hub"))), "Hub", Nothing).Value

            bhpbioPortBalanceId = _portImportDal.AddBhpbioPortBalances(hubLocationId, Convert.ToDateTime(sourceRow("BalanceDate")), _
                Convert.ToDouble(sourceRow("Tonnes")), Convert.ToString(sourceRow("Product")), Convert.ToString(sourceRow("ProductSize")))

        ElseIf dataTableName = "PortBalanceGrade" Then

            'add the grade id column
            AddTableColumn(destinationRow.Table, "GradeId", GetType(Int16), Nothing)

            'resolve the grade
            gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

            If Not gradeId.HasValue Then
                Throw New MissingFieldException(String.Format("The grade name '{0}' could not be resolved.", sourceRow("GradeName")))
            End If

            gradeValue = Convert.ToSingle(sourceRow("HeadValue"))

            destinationPortBalanceRow = DirectCast(sourceRow.GetParentRow("FK_PortBalance_PortBalanceGrade")("DestinationRow"), DataRow)
            bhpbioPortBalanceId = Convert.ToInt32(destinationPortBalanceRow("BhpbioPortBalanceId"))
            destinationPortBalanceRow = Nothing

            'insert the grade
            _portImportDal.AddOrUpdateBhpbioPortBalanceGrade(bhpbioPortBalanceId, gradeId.Value, gradeValue)

            'save the grade id
            destinationRow("GradeId") = gradeId.Value
        End If

        'save the id that was used (for all records)
        destinationRow("BhpbioPortBalanceId") = bhpbioPortBalanceId.ToString
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim gradeId As Int16?
        Dim gradeValue As Double

        Dim bhpbioPortBalanceId As Int32 = Convert.ToInt32(destinationRow("BhpbioPortBalanceId"))

        If dataTableName = "PortBalance" Then

            _portImportDal.UpdateBhpbioPortBalances(bhpbioPortBalanceId, Convert.ToDouble(sourceRow("Tonnes")), _
                Convert.ToString(sourceRow("Product")), Convert.ToString(sourceRow("ProductSize")))

        ElseIf dataTableName = "PortBalanceGrade" Then

            If syncQueueChangedFields.Select("ChangedField = 'HeadValue'").Length > 0 Then

                'add the grade id column
                AddTableColumn(destinationRow.Table, "GradeId", GetType(Int16), Nothing)

                'resolve the grade
                gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

                If Not gradeId.HasValue Then
                    Throw New MissingFieldException(String.Format("The grade name [{0}] could not be resolved.", sourceRow("GradeName")))
                End If

                gradeValue = Convert.ToSingle(sourceRow("HeadValue"))

                'update the grade
                _portImportDal.AddOrUpdateBhpbioPortBalanceGrade(bhpbioPortBalanceId, gradeId.Value, gradeValue)

            End If
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

        If dataTableName = "PortBalance" Then
            'check that the Tonnes > 0
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
                Or syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then

                If Convert.ToDouble(sourceRow("Tonnes")) <= 0 Then
                    importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                        Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), _
                        "Tonnes value was less than or equal to 0.", _
                        String.Format("Tonnes value was {0}.", Convert.ToDouble(sourceRow("Tonnes")).ToString))
                    SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Tonnes")
                End If
            End If

            hubLocationId = LocationDataCachedHelper.GetLocationId( _
                CodeTranslationHelper.HubCodeMESToReconcilor(Convert.ToString(sourceRow("Hub"))), "Hub", Nothing)
            If Not hubLocationId.HasValue Then
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), "The Hub cannot be resolved.", _
                    String.Format("The Hub value was {0}.", sourceRow("Hub")))
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Hub")
            End If

        ElseIf dataTableName = "PortBalanceGrade" Then

            If Not ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString).HasValue Then
                validationMessage = String.Format("The Grade Name '{0}' could not be resolved.", sourceRow("GradeName"))

                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), validationMessage, validationMessage)

                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Grades")
            End If

            'check that the grade value is valid
            Dim gradeValue As Double
            Dim parseSuccessful As Boolean = Double.TryParse(sourceRow("HeadValue").ToString, gradeValue)
            If (Not parseSuccessful) OrElse gradeValue < 0.0 Then
                importSyncValidateId = SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, _
                    Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), "The Grade Value must be numeric and greater than zero.", _
                    String.Format("The Grade Value was: [{0}]", sourceRow("HeadValue")))
                SyncImportDataHelper.AddImportSyncValidateField(importSyncValidateField, importSyncValidateId, "Grades")
            End If

        End If
    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    Protected Overrides Function LoadSource(ByVal sourceSchema As System.IO.StringReader) As System.Data.DataSet
        Dim returnDataSet As DataSet = Nothing

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A source port balance schema must be provided.")
        End If

        returnDataSet = New DataSet()
        returnDataSet.ReadXmlSchema(sourceSchema)
        returnDataSet.EnforceConstraints = False

        'load the data into the supplied ADO.NET dataset with the specified schema
        LoadSourceFromWebService(Dates, returnDataSet)

        returnDataSet.AcceptChanges()

        'check that we actually have "clean" data (i.e. all fields conform to their respective data types); if not, fail the import
        Try
            returnDataSet.EnforceConstraints = True
        Catch ex As ConstraintException
            Throw New DataException(returnDataSet.GetErrorReport(), ex)
        End Try

        Return returnDataSet
    End Function

    Public Sub LoadSourceFromWebService(ByVal dates As IList(Of DateTime), ByVal returnDataSet As DataSet)

        Dim client As MaterialTrackerService.IM_MT_DS
        Dim retrievePortBalanceRequest1 As retrievePortBalancesRequest1
        Dim portBalanceRequest As RetrievePortBalancesRequest
        Dim retrievePortBalanceResponse1 As retrievePortBalancesResponse1
        Dim portBalanceResponse As RetrievePortBalancesResponse
        Dim currentDate As DateTime

        'create a new wcf-client instance
        client = WebServicesFactory.CreateMaterialTrackerWebServiceClient()

        'create the parameters once and set the mine-site
        portBalanceRequest = New RetrievePortBalancesRequest()
        portBalanceRequest.StartDateSpecified = True

        Trace.WriteLine("Loading from Web Service ...")

        'loop through the dates
        For Each currentDate In dates
            Trace.WriteLine("Requesting: " & currentDate.AddDays(1))

            portBalanceRequest.StartDate = currentDate.AddDays(1).ToUniversalTime

            'create a new request and invoke it
            retrievePortBalanceRequest1 = New retrievePortBalancesRequest1(portBalanceRequest)
            Try
                retrievePortBalanceResponse1 = client.retrievePortBalances(retrievePortBalanceRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving port balances data from Material Tracker web service.", ex)
            End Try

            portBalanceResponse = retrievePortBalanceResponse1.RetrievePortBalancesResponse

            'check we received a payload - we always expect one
            If portBalanceResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", System.DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    System.DateTime.Now, portBalanceResponse.Status.StatusMessage))
            End If

            If Not portBalanceResponse.PortBalances Is Nothing Then
                For index As Integer = 0 To portBalanceResponse.PortBalances.Length - 1
                    LoadPortBalances(portBalanceResponse.PortBalances(index), returnDataSet)
                Next
            End If
        Next

        returnDataSet.AcceptChanges()
    End Sub

    Private Sub LoadPortBalances(ByVal portBalStockpile As PortBalancesStockpileType, ByVal returnDataSet As DataSet)
        Dim portBalancesTable As DataTable
        Dim portBalanceGradeTable As DataTable
        Dim portBalanceRow As DataRow
        Dim hub As Object
        Dim balanceDate As Object
        Dim tonnes As Object
        Dim product As Object
        Dim productSize As Object

        hub = Nothing : balanceDate = Nothing : tonnes = Nothing
        portBalancesTable = returnDataSet.Tables("PortBalance")
        portBalanceGradeTable = returnDataSet.Tables("PortBalanceGrade")

        hub = portBalStockpile.Hub.ReadStringWithDbNull()
        balanceDate = portBalStockpile.BalanceDate.ReadAsDateTimeWithDbNull(portBalStockpile.BalanceDateSpecified)
        tonnes = portBalStockpile.Tonnes.ReadAsDoubleWithDbNull(portBalStockpile.TonnesSpecified)
        product = portBalStockpile.Product.ReadStringWithDbNull()
        If TypeOf product Is DBNull Then
            product = _defaultProduct
        End If
        productSize = portBalStockpile.ProductSize.ReadStringWithDbNull()
        If TypeOf productSize Is DBNull Then
            productSize = _defaultProductSize
        End If

        If TypeOf balanceDate Is DateTime Then
            balanceDate = DirectCast(balanceDate, DateTime).AddDays(-1)
        End If
        If TypeOf hub Is String And TypeOf balanceDate Is DateTime Then
            If portBalancesTable.Select(String.Format("Hub = '{0}' AND BalanceDate = #{1}# AND Product = '{2}'", _
             hub.ToString(), Convert.ToDateTime(balanceDate).ToString("O"), product.ToString())).Length = 0 Then
                'create a new Haulage Record and add it to the table
                portBalanceRow = portBalancesTable.NewRow()
                portBalancesTable.Rows.Add(portBalanceRow)

                portBalanceRow("Hub") = hub
                portBalanceRow("BalanceDate") = balanceDate
                portBalanceRow("Product") = product
                portBalanceRow("ProductSize") = productSize
                portBalanceRow("Tonnes") = tonnes
            Else
                portBalanceRow = portBalancesTable.Select(String.Format("Hub = '{0}' AND BalanceDate = #{1}# AND Product = '{2}'", _
                    hub.ToString(), Convert.ToDateTime(balanceDate).ToString("O"), product.ToString())).First

                If TypeOf tonnes Is Double Then
                    portBalancesTable.Rows.Item(portBalancesTable.Rows.IndexOf(portBalanceRow)).Item("Tonnes") = _
                        DirectCast(tonnes, Double) + CDbl(portBalanceRow("Tonnes").ToString)
                End If
            End If
        Else
            portBalanceRow = portBalancesTable.NewRow()
            portBalancesTable.Rows.Add(portBalanceRow)
            portBalanceRow("Hub") = hub
            portBalanceRow("BalanceDate") = balanceDate
            portBalanceRow("Product") = product
            portBalanceRow("ProductSize") = productSize
            portBalanceRow("Tonnes") = tonnes
        End If

        LoadPortBalanceGrades(portBalStockpile, portBalanceGradeTable, portBalanceRow)
    End Sub

    Private Sub LoadPortBalanceGrades(ByVal portBalStockpile As PortBalancesStockpileType, ByVal portBalanceGradeTable As DataTable, ByVal portBalanceRow As DataRow)
        Dim haulageGradeRow As DataRow
        Dim index As Integer

        If Not portBalStockpile.Grade Is Nothing Then
            For index = 0 To portBalStockpile.Grade.Length - 1
                If CodeTranslationHelper.RelevantGrades.Contains(portBalStockpile.Grade(index).Name, StringComparer.OrdinalIgnoreCase) Then
                    haulageGradeRow = portBalanceGradeTable.NewRow()
                    haulageGradeRow("GradeName") = portBalStockpile.Grade(index).Name
                    haulageGradeRow("HeadValue") = portBalStockpile.Grade(index).HeadValue.ReadAsDoubleWithDbNull(portBalStockpile.Grade(index).HeadValueSpecified)
                    haulageGradeRow.SetParentRow(portBalanceRow)
                    portBalanceGradeTable.Rows.Add(haulageGradeRow)
                End If
            Next
        End If
    End Sub


End Class
