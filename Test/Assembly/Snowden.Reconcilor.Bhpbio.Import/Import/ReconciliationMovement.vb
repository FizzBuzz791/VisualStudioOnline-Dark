Imports System.Data.SqlClient
Imports Snowden.Common.Import
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Bhpbio.Import.BlastholesService

Friend NotInheritable Class ReconciliationMovement
    Inherits Data.LoadImport

    Private Const _settingReconciliationMovementPayloadType As String = "ReconciliationMovementPayloadType"
    Private Const _settingReconciliationMovementPayloadSource As String = "ReconciliationMovementPayloadSource"
    Private Const _xmlPayloadType As String = "XMLFile"
    Private Const _webServicePayloadType As String = "WebService"
    Private Const _bulkCopyBatchSize As Int32 = 1000
    Private Const _numberOfDaysPerWebRequest As Int32 = 15
    Private Const _negativeValue As Int32 = -1

    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _settings As ConfigurationSettings

    Friend Sub New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Recon Movements"
        _settings = ConfigurationSettings.GetConfigurationSettings()
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, True))
        Return True
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        _dateFrom = Nothing
        _dateTo = Nothing
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)
        ' attempt to fix '24 hour delay' issue, although it seems this condition is already catered for in above function call
        _dateTo.AddDays(1)
    End Sub

    Protected Overrides Function LoadSource() As Integer
        Dim data As DataSet = Nothing
        Dim schemaReader As System.IO.StringReader = Nothing

        Try
            'Read in the schema
            data = New DataSet()
            schemaReader = New System.IO.StringReader(My.Resources.ResourceManager.GetObject("ReconciliationMovementSource").ToString)
            data.ReadXmlSchema(schemaReader)
            data.EnforceConstraints = False

            'emulate the loaddata call
            If QuickOptions.LoadData Then
                data.ReadXml(QuickOptions.LoadDataPath)
            Else
                'load the data into the ADO.NET dataset
                LoadSourceFromWebService(_dateFrom, _dateTo, data)
            End If

            data.AcceptChanges()

            'emulate the savedata call
            If QuickOptions.SaveData Then
                data.WriteXml(QuickOptions.SaveDataPath)
            End If

            'check that we actually have "clean" data (i.e. all fields conform to their respective data types); if not, fail the import
            Try
                data.EnforceConstraints = True
            Catch ex As ConstraintException
                Throw New DataException(data.GetErrorReport(), ex)
            End Try

            'Synchronize with database, simple replacement
            Synchronise(data.Tables("ReconciliationMovement"))
        Finally
            If Not schemaReader Is Nothing Then
                schemaReader.Dispose()
                schemaReader = Nothing
            End If
        End Try
    End Function

    Private Sub Synchronise(ByVal data As DataTable)
        Dim bulkCopy As SqlBulkCopy = Nothing
        Dim bhpbioImportDal As DalBaseObjects.IBhpbioBlock

        'set up the dal & share the active transactions
        bhpbioImportDal = New SqlDal.SqlDalBhpbioBlock
        bhpbioImportDal.DataAccess.DataAccessConnection = Me.ImportDal.DataAccess.DataAccessConnection

        Try
            'clear the staging table
            bhpbioImportDal.DeleteBhpbioReconciliationMovementStage()

            'bulk copy the new data
            bulkCopy = New SqlBulkCopy(DirectCast(ImportDal.DataAccess.DatabaseConnection, SqlConnection), _
             SqlBulkCopyOptions.CheckConstraints, ImportDal.DataAccess.Transaction)
            bulkCopy.DestinationTableName = "dbo.BhpbioImportReconciliationMovementStage"
            bulkCopy.BatchSize = _bulkCopyBatchSize
            bulkCopy.BulkCopyTimeout = ImportDalHelper.AdoCommandTimeoutExtended
            bulkCopy.WriteToServer(data)
            bulkCopy.Close()

            'call the stored procedure to synchronise the data
            bhpbioImportDal.UpdateBhpbioReconciliationMovement()
        Finally
            If Not bhpbioImportDal Is Nothing Then
                bhpbioImportDal.Dispose()
                bhpbioImportDal = Nothing
            End If

            If Not bulkCopy Is Nothing Then
                bulkCopy = Nothing
            End If
        End Try
    End Sub

    ''' <summary>
    ''' Invokes the Web Service specified; functionality currently stubbed.
    ''' </summary>
    ''' <param name="webServiceUri"></param>
    ''' <param name="returnDataSet"></param>
    ''' <remarks></remarks>
    Private Sub LoadSourceFromWebService(ByVal partitionDateFrom As Date, ByVal partitionDateTo As Date, ByVal returnDataSet As DataSet)

        Dim blastholesClient As BlastholesService.IM_Blastholes_DS
        Dim retrieveRecMovementRequest1 As retrieveReconciliationMovementsRequest1
        Dim recMovementRequest As RetrieveReconciliationMovementsRequest
        Dim retrieveRecMovementResponse1 As retrieveReconciliationMovementsResponse1
        Dim recMovementResponse As RetrieveReconciliationMovementsResponse
        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime

        'create a new wcf-client instance
        blastholesClient = WebServicesFactory.CreateBlastholesWebServiceClient()

        'create the parameters once and set the mine-site
        recMovementRequest = New RetrieveReconciliationMovementsRequest()
        recMovementRequest.StartDateSpecified = True
        recMovementRequest.EndDateSpecified = True

        Trace.WriteLine(String.Format("Loading from Web Service: From = {0:dd-MMM-yyyy}, To = {1:dd-MMM-yyyy}", partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = partitionDateFrom
        currentDateTo = partitionDateFrom.AddDays(_numberOfDaysPerWebRequest)
        If currentDateTo >= partitionDateTo Then
            currentDateTo = partitionDateTo
        End If

        While currentDateFrom <= partitionDateTo
            Trace.WriteLine(String.Format("Requesting partition: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy}", currentDateFrom, currentDateTo))

            recMovementRequest.StartDate = currentDateFrom.ToUniversalTime()
            recMovementRequest.EndDate = currentDateTo.ToUniversalTime()

            'create a new request and invoke it
            retrieveRecMovementRequest1 = New retrieveReconciliationMovementsRequest1(recMovementRequest)
            Try
                retrieveRecMovementResponse1 = blastholesClient.retrieveReconciliationMovements(retrieveRecMovementRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving reconciliation movements data from Blastholes web service.", ex)
            End Try

            recMovementResponse = retrieveRecMovementResponse1.RetrieveReconciliationMovementsResponse

            'check we received a payload - we always expect one
            If recMovementResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd/MMM/yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd/MMM/yyyy}) with status message: {1}", _
                    DateTime.Now, recMovementResponse.Status.StatusMessage))
            End If

            If (Not recMovementResponse.FetchReconciliationMovementsResponse Is Nothing) AndAlso _
                (Not recMovementResponse.FetchReconciliationMovementsResponse.FetchReconciliationMovementsResult Is Nothing) Then

                For index As Integer = 0 To recMovementResponse.FetchReconciliationMovementsResponse.FetchReconciliationMovementsResult.Length - 1
                    LoadReconciliationMovements(recMovementResponse.FetchReconciliationMovementsResponse.FetchReconciliationMovementsResult(index), returnDataSet)
                Next
            End If

            'increment the date range
            currentDateFrom = currentDateTo.AddDays(1)
            currentDateTo = currentDateFrom.AddDays(_numberOfDaysPerWebRequest)
            If currentDateTo >= partitionDateTo Then
                currentDateTo = partitionDateTo
            End If
        End While

        returnDataSet.AcceptChanges()
    End Sub

    Private Sub LoadReconciliationMovements(ByVal block As BlockType, ByVal returnDataSet As DataSet)
        Dim recMovementTable As DataTable
        Dim recMovementRow As DataRow
        Dim blockNumber As Object = DBNull.Value
        Dim blockName As Object = DBNull.Value
        Dim site As Object = DBNull.Value
        Dim oreBody As Object = DBNull.Value
        Dim pit As Object = DBNull.Value
        Dim patternNumber As Object = DBNull.Value
        Dim bench As Object = DBNull.Value
        Dim lastModifiedDate As Object = DBNull.Value
        Dim lastModifiedUser As Object = DBNull.Value

        recMovementTable = returnDataSet.Tables("ReconciliationMovement")

        blockNumber = block.Number.ReadStringWithDbNull()
        blockName = block.Name.ReadStringWithDbNull()
        lastModifiedDate = block.LastModifiedDate.ReadAsDateTimeWithDbNull(block.LastModifiedDateSpecified)
        lastModifiedUser = block.LastModifiedUser.ReadStringWithDbNull()
        'Pattern
        If Not block.Pattern Is Nothing Then
            site = block.Pattern.Site.ReadStringWithDbNull()
            oreBody = block.Pattern.Orebody.ReadStringWithDbNull()
            pit = block.Pattern.Pit.ReadStringWithDbNull()
            patternNumber = block.Pattern.Number.ReadStringWithDbNull()
            bench = block.Pattern.Bench.ReadStringWithDbNull()
        End If
        'Movements
        If Not block.Movement Is Nothing Then
            For index As Integer = 0 To block.Movement.Length - 1
                recMovementRow = recMovementTable.NewRow
                recMovementTable.Rows.Add(recMovementRow)

                recMovementRow("BlockNumber") = blockNumber
                recMovementRow("BlockName") = blockName
                recMovementRow("Site") = site
                recMovementRow("Orebody") = oreBody
                recMovementRow("Pit") = pit
                recMovementRow("PatternNumber") = patternNumber
                recMovementRow("Bench") = bench
                recMovementRow("DateFrom") = block.Movement(index).DateFrom.Date
                recMovementRow("DateTo") = block.Movement(index).DateTo.Date
                recMovementRow("LastModifiedDate") = _
                    block.Movement(index).LastModifiedDate.Date.ReadAsDateTimeWithDbNull(block.Movement(index).LastModifiedDateSpecified)
                recMovementRow("LastModifiedUser") = block.Movement(index).LastModifiedUser.ReadStringWithDbNull()
                recMovementRow("MinedPercentage") = block.Movement(index).MinedPercentage.ReadAsDoubleWithDbNull(block.Movement(index).MinedPercentageSpecified)
            Next
        End If
    End Sub

    Protected Overrides Function ProcessData() As Integer
        'do nothing
    End Function

    Protected Overrides Sub ProcessPrepareData()

    End Sub

    Protected Overrides Sub SetupDataAccessObjects()

    End Sub
End Class

