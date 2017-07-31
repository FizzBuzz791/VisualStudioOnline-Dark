Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Common.Import.Database
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Bhpbio.Import.MaterialTrackerService
Imports Snowden.Common.Database.DataHelper

Friend NotInheritable Class MetBalancing
    Inherits Snowden.Common.Import.Data.SyncImport

    Private Const _shiftStartHour As Int32 = 6
    Private _settings As ConfigurationSettings
    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _utilityDal As DalBaseObjects.IUtility

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

    Public Sub New()
        MyBase.New()
        ImportGroup = "Reconcilor Generics"
        ImportName = "Met Balancing"
        SourceSchemaName = "MetBalancing"
        CanGenerateSourceSchema = False
        _settings = ConfigurationSettings.GetConfigurationSettings()
    End Sub

    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If (Not _disposed) Then
                If (disposing) Then
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
        _utilityDal = New SqlDal.SqlDalUtility
        _utilityDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        ReferenceDataCachedHelper.UtilityDal = _utilityDal
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        validationMessage.Append(ParameterHelper.ValidateStandardDateParameters(parameters, True))
        Return True
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))
        ParameterHelper.LoadStandardDateFilters(parameters, DestinationDataAccessConnection, _dateFrom, _dateTo)
    End Sub

    Protected Overrides Function LoadDestinationRow(ByVal tableName As String, ByVal keyRows As System.Data.DataRow) As Boolean
        Dim calendarDate As DateTime

        'all tables have the HaulageDate and Mine column - these can be used to partition accordingly
        calendarDate = Convert.ToDateTime(keyRows("CalendarDate"))

        Return (calendarDate >= _dateFrom) And (calendarDate <= _dateTo)
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

        Dim bhpbioMetBalancingId As Int32 = Convert.ToInt32(destinationRow("BhpbioMetBalancingId"))
        _utilityDal.DeleteBhpbioMetBalancing(bhpbioMetBalancingId)
    End Sub

    Protected Overrides Sub ProcessInsert(ByVal dataTableName As String, _
        ByVal sourceRow As DataRow, _
        ByVal destinationRow As DataRow, _
        ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
        ByVal syncQueueRow As DataRow, _
        ByVal syncQueueChangedFields As DataTable, _
        ByVal importSyncDal As ImportSync)

        Dim bhpbioMetBalancingId As Int32
        Dim weightometer As String
        Dim dryTonnes As Double
        Dim wetTonnes As Double
        Dim splitCycle As Double
        Dim splitPlant As Double
        Dim productSize As String
        Dim gradeId As Short?
        Dim gradeValue As Double
        Dim destinationMetBalanceRow As DataRow

        'save the id that was used (for all records)
        DataHelper.AddTableColumn(destinationRow.Table, "BhpbioMetBalancingId", GetType(String), Nothing)

        If dataTableName = "MetBalancing" Then

            If sourceRow("Weightometer") Is DBNull.Value Then
                weightometer = NullValues.String
            Else
                weightometer = Convert.ToString(sourceRow("Weightometer"))
            End If

            If sourceRow("DryTonnes") Is DBNull.Value Then
                dryTonnes = NullValues.Double
            Else
                dryTonnes = Convert.ToDouble(sourceRow("DryTonnes"))
            End If

            If sourceRow("WetTonnes") Is DBNull.Value Then
                wetTonnes = NullValues.Double
            Else
                wetTonnes = Convert.ToDouble(sourceRow("WetTonnes"))
            End If

            If sourceRow("SplitCycle") Is DBNull.Value Then
                splitCycle = NullValues.Double
            Else
                splitCycle = Convert.ToDouble(sourceRow("SplitCycle"))
            End If

            If sourceRow("SplitPlant") Is DBNull.Value Then
                splitPlant = NullValues.Double
            Else
                splitPlant = Convert.ToDouble(sourceRow("SplitPlant"))
            End If

            If sourceRow("ProductSize") Is DBNull.Value Then
                productSize = NullValues.String
            Else
                productSize = Convert.ToString(sourceRow("ProductSize"))
            End If

            bhpbioMetBalancingId = _utilityDal.AddBhpbioMetBalancing( _
                Convert.ToString(sourceRow("Site")), Convert.ToDateTime(sourceRow("CalendarDate")), _
                Convert.ToDateTime(sourceRow("StartDate")), Convert.ToDateTime(sourceRow("EndDate")), _
                Convert.ToString(sourceRow("PlantName")), Convert.ToString(sourceRow("StreamName")), _
                weightometer, dryTonnes, wetTonnes, splitCycle, splitPlant, productSize)

        ElseIf dataTableName = "MetBalancingGrade" Then

            'add the grade id column
            AddTableColumn(destinationRow.Table, "GradeId", GetType(Int16), Nothing)
            gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

            If Not gradeId.HasValue Then
                Throw New MissingFieldException(String.Format("The grade {0} could not be resolved.", sourceRow("GradeName")))
            End If

            destinationMetBalanceRow = DirectCast(sourceRow.GetParentRow("FK_MetBalancing_MetBalancingGrade")("DestinationRow"), DataRow)
            bhpbioMetBalancingId = Convert.ToInt32(destinationMetBalanceRow("BhpbioMetBalancingId"))
            destinationMetBalanceRow = Nothing

            gradeValue = Convert.ToDouble(sourceRow("HeadValue"))

            _utilityDal.AddOrUpdateBhpbioMetBalancingGrade(bhpbioMetBalancingId, gradeId.Value, gradeValue)

            'save the grade id
            destinationRow("GradeId") = gradeId.Value
        End If

        'save the id that was used (for all records)
        destinationRow("BhpbioMetBalancingId") = bhpbioMetBalancingId.ToString()
    End Sub

    Protected Overrides Sub ProcessUpdate(ByVal dataTableName As String, _
     ByVal sourceRow As DataRow, _
     ByVal destinationRow As DataRow, _
     ByVal syncAction As Snowden.Common.Import.Data.SyncImportSyncActionEnumeration, _
     ByVal syncQueueRow As DataRow, _
     ByVal syncQueueChangedFields As DataTable, _
     ByVal importSyncDal As ImportSync)

        Dim bhpbioMetBalancingId As Int32
        Dim weightometer As String
        Dim dryTonnes As Double
        Dim wetTonnes As Double
        Dim splitCycle As Double
        Dim splitPlant As Double
        Dim productSize As String
        Dim gradeId As Short?
        Dim gradeValue As Double

        bhpbioMetBalancingId = Convert.ToInt32(destinationRow("BhpbioMetBalancingId"))

        If dataTableName = "MetBalancing" Then

            If sourceRow("Weightometer") Is DBNull.Value Then
                weightometer = NullValues.String
            Else
                weightometer = Convert.ToString(sourceRow("Weightometer"))
            End If

            dryTonnes = Convert.ToDouble(sourceRow("DryTonnes"))

            If sourceRow("WetTonnes") Is DBNull.Value Then
                wetTonnes = NullValues.Double
            Else
                wetTonnes = Convert.ToDouble(sourceRow("WetTonnes"))
            End If

            If sourceRow("SplitCycle") Is DBNull.Value Then
                splitCycle = NullValues.Double
            Else
                splitCycle = Convert.ToDouble(sourceRow("SplitCycle"))
            End If

            If sourceRow("SplitPlant") Is DBNull.Value Then
                splitPlant = NullValues.Double
            Else
                splitPlant = Convert.ToDouble(sourceRow("SplitPlant"))
            End If

            If sourceRow("ProductSize") Is DBNull.Value Then
                productSize = NullValues.String
            Else
                productSize = Convert.ToString(sourceRow("ProductSize"))
            End If

            _utilityDal.UpdateBhpbioMetBalancing(bhpbioMetBalancingId, _
                Convert.ToDateTime(sourceRow("StartDate")), Convert.ToDateTime(sourceRow("EndDate")), _
                weightometer, dryTonnes, wetTonnes, splitCycle, splitPlant, productSize)

        ElseIf dataTableName = "MetBalancingGrade" Then

            If syncQueueChangedFields.Select("ChangedField = 'HeadValue'").Length > 0 Then
                'resolve the grade
                gradeId = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

                If Not gradeId.HasValue Then
                    Throw New MissingFieldException(String.Format("The grade {0} could not be resolved.", sourceRow("GradeName")))
                End If

                gradeValue = Convert.ToSingle(sourceRow("HeadValue"))
                _utilityDal.AddOrUpdateBhpbioMetBalancingGrade(bhpbioMetBalancingId, gradeId.Value, gradeValue)

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

        Dim field As String
        Dim gradeValue As Single
        Dim validationMessage As String = String.Empty

        If dataTableName = "MetBalancing" Then

            'perform INSERT checks
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert Then
                'Site must always be "WB Bene"
                If Convert.ToString(sourceRow("Site")) <> "WB Bene" Then
                    GeneralHelper.LogValidationError("Only 'WB Bene' is currently supported.", "Site", _
                     syncQueueRow, importSyncValidate, importSyncValidateField)
                End If
            End If

            'perform INSERT/UPDATE checks (on attributes)
            If syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Insert _
             Or syncAction = Common.Import.Data.SyncImportSyncActionEnumeration.Update Then

                'note: nulls are already checked from the incoming schema
                For Each field In New String() {"DryTonnes", "WetTonnes", "SplitCycle", "SplitPlant"}
                    If Not sourceRow(field) Is DBNull.Value _
                     AndAlso Convert.ToDouble(sourceRow(field)) < 0.0 Then
                        GeneralHelper.LogValidationError(field & " must be >= 0.0.", field, _
                         syncQueueRow, importSyncValidate, importSyncValidateField)
                    End If
                Next
            End If

        ElseIf dataTableName = "MetBalancingGrade" Then

            'Grade Names valid
            'Grade Values >= 0
            Dim gradeId As Short? = ReferenceDataCachedHelper.GetGradeId(sourceRow("GradeName").ToString)

            If Not gradeId.HasValue Then
                Throw New MissingFieldException(String.Format("The grade '{0}' could not be resolved.", sourceRow("GradeName")))
            End If

            gradeValue = Convert.ToSingle(sourceRow("HeadValue"))
            If gradeValue < 0.0 Then
                GeneralHelper.LogValidationError(String.Format("The grade value '{0}' must be >= 0.0.", gradeValue), "HeadValue", _
                    syncQueueRow, importSyncValidate, importSyncValidateField)
            End If

        End If

    End Sub

    Protected Overrides Sub PostProcess(ByVal importSyncDal As ImportSync)
        ' Trigger the CalcVirtualFlow process
        _utilityDal.CalcVirtualFlow()
    End Sub

    Protected Overrides Sub PreProcess(ByVal importSyncDal As ImportSync)
        'do nothing
    End Sub

    ''' <summary>
    ''' Provides the source data required by the Met Balancing import.
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
            Throw New ArgumentException("A MET balancing source schema must be provided.")
        End If

        returnDataSet = New DataSet()
        returnDataSet.ReadXmlSchema(sourceSchema)
        returnDataSet.EnforceConstraints = False

        'load the data into the supplied ADO.NET dataset
        LoadSourceFromWebService(DateFrom, DateTo, returnDataSet)

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

    Public Sub LoadSourceFromWebService(ByVal partitionDateFrom As DateTime, ByVal partitionDateTo As DateTime, ByVal returnDataSet As DataSet)

        Dim client As MaterialTrackerService.IM_MT_DS
        Dim retrieveMetBalanceRequest1 As retrieveMETBalancingRequest1
        Dim metBalanceRequest As RetrieveMETBalancingRequest
        Dim retrieveMetBalanceResponse1 As retrieveMETBalancingResponse1
        Dim metBalanceResponse As RetrieveMETBalancingResponse
        Dim shiftAdjustedPartitionDateFrom As DateTime
        Dim shiftAdjustedPartitionDateTo As DateTime
        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime

        'create a new wcf-client instance
        client = WebServicesFactory.CreateMaterialTrackerWebServiceClient()

        'create the parameters once
        metBalanceRequest = New RetrieveMETBalancingRequest()
        metBalanceRequest.StartDateSpecified = True
        metBalanceRequest.EndDateSpecified = True

        'determine the corrected partition date from / to
        shiftAdjustedPartitionDateFrom = partitionDateFrom.AddHours(_shiftStartHour)
        shiftAdjustedPartitionDateTo = partitionDateTo.AddHours(_shiftStartHour).AddMilliseconds(-1)

        Trace.WriteLine(String.Format("Loading from Web Service: From = {0:dd-MMM-yyyy}, To = {1:dd-MMM-yyyy}", partitionDateFrom, partitionDateTo))

        'loop through the dates - based on a specified period - this is configured to achieve < 2MB requests
        currentDateFrom = shiftAdjustedPartitionDateFrom
        currentDateTo = shiftAdjustedPartitionDateFrom.AddDays(1).AddMilliseconds(-1)

        While currentDateFrom <= shiftAdjustedPartitionDateTo
            Trace.WriteLine(String.Format("Requesting partition: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy}", currentDateFrom, currentDateTo))

            metBalanceRequest.StartDate = currentDateFrom.ToUniversalTime()
            metBalanceRequest.EndDate = currentDateTo.ToUniversalTime()

            'create a new request and invoke it
            retrieveMetBalanceRequest1 = New retrieveMETBalancingRequest1(metBalanceRequest)
            Try
                retrieveMetBalanceResponse1 = client.retrieveMETBalancing(retrieveMetBalanceRequest1)
            Catch ex As Exception
                Throw New DataException("Error while retrieving MET balancing data from Material Tracker web service.", ex)
            End Try

            metBalanceResponse = retrieveMetBalanceResponse1.RetrieveMETBalancingResponse

            'check we received a payload - we always expect one
            If metBalanceResponse.Status.StatusFlag Then
                Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
            Else
                Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                    DateTime.Now, metBalanceResponse.Status.StatusMessage))
            End If

            If Not metBalanceResponse.METBalancing Is Nothing Then
                For index As Integer = 0 To metBalanceResponse.METBalancing.Length - 1
                    LoadMetBalancing(metBalanceResponse.METBalancing(index), ParameterHelper.TruncateDate(currentDateFrom), returnDataSet)
                Next
            End If

            'increment the date range by one day
            currentDateFrom = currentDateFrom.AddDays(1)
            currentDateTo = currentDateTo.AddDays(1)
        End While

        returnDataSet.AcceptChanges()
    End Sub

    ''' <summary>
    ''' Loads the single METBalance element contained within the payload.
    ''' </summary>
    Private Sub LoadMetBalancing(ByVal metBalanceResult As METBalResultType, ByVal calendarDate As DateTime, ByVal returnDataSet As DataSet)
        Dim metBalanceTable As DataTable
        Dim metBalanceGradeTable As DataTable
        Dim metBalanceRow As DataRow
        Dim currentEndDate As Object = Nothing

        metBalanceTable = returnDataSet.Tables("MetBalancing")
        metBalanceGradeTable = returnDataSet.Tables("MetBalancingGrade")
        metBalanceRow = metBalanceTable.NewRow()
        metBalanceTable.Rows.Add(metBalanceRow)

        metBalanceRow("CalendarDate") = calendarDate
        metBalanceRow("Site") = metBalanceResult.Site.ReadStringWithDbNull()
        metBalanceRow("StartDate") = metBalanceResult.StartDate.ReadAsDateTimeWithDbNull(metBalanceResult.StartDateSpecified)
        currentEndDate = metBalanceResult.EndDate.ReadAsDateTimeWithDbNull(metBalanceResult.EndDateSpecified)
        metBalanceRow("EndDate") = currentEndDate
        metBalanceRow("PlantName") = metBalanceResult.PlantName.ReadStringWithDbNull()
        metBalanceRow("StreamName") = metBalanceResult.StreamName.ReadStringWithDbNull()
        metBalanceRow("Weightometer") = metBalanceResult.Weightometer.ReadStringWithDbNull()
        metBalanceRow("DryTonnes") = metBalanceResult.DryTonnes.ReadAsDoubleWithDbNull(metBalanceResult.DryTonnesSpecified)
        metBalanceRow("WetTonnes") = metBalanceResult.WetTonnes.ReadAsDoubleWithDbNull(metBalanceResult.WetTonnesSpecified)
        metBalanceRow("SplitCycle") = metBalanceResult.SplitCycle.ReadStringWithDbNull()
        'TODO: SplitPlant should be Decimal in xsd, but it's String: check with client!!!!!!!!!!!!!!!!!!!!
        metBalanceRow("SplitPlant") = metBalanceResult.SplitPlant.ReadStringAsDoubleWithDbNull()
        metBalanceRow("ProductSize") = metBalanceResult.ProductSize.ReadStringWithDbNull()

        LoadGrades(metBalanceResult, metBalanceRow, metBalanceGradeTable)

        'work around Honeywell bug
        If TypeOf currentEndDate Is DateTime Then
            Dim duplicateRows() As DataRow
            Dim query As String = String.Format("Site = 'WB Bene' AND PlantName = 'Overall' AND StreamName = 'Total Bene Product' AND EndDate = #{0:O}#", _
                DirectCast(currentEndDate, DateTime))

            duplicateRows = metBalanceTable.Select(query)
            If duplicateRows.Length > 1 Then
                'only deletes one duplicate row and child grades - this is explicitly the bug we're working around here
                For Each dupGradeRow As DataRow In duplicateRows(0).GetChildRows("FK_MetBalancing_MetBalancingGrade")
                    dupGradeRow.Delete()
                Next
                duplicateRows(0).Delete()
            End If
        End If
    End Sub

    Private Sub LoadGrades(ByVal metBalanceResult As METBalResultType, ByVal metBalanceRow As DataRow, ByVal metBalanceGradeTable As DataTable)
        Dim metBalanceGradeRow As DataRow
        Dim gradeName As String

        If Not metBalanceResult.Grade Is Nothing Then
            For index As Integer = 0 To metBalanceResult.Grade.Length - 1
                gradeName = GetMetBalanceRelevantGrade(metBalanceResult.Grade(index).Name.ReadStringWithDbNull())
                If Not gradeName Is Nothing Then
                    metBalanceGradeRow = metBalanceGradeTable.NewRow()
                    metBalanceGradeRow("CalendarDate") = metBalanceRow("CalendarDate")
                    metBalanceGradeRow("Site") = metBalanceRow("Site")
                    metBalanceGradeRow("PlantName") = metBalanceRow("PlantName")
                    metBalanceGradeRow("StreamName") = metBalanceRow("StreamName")
                    metBalanceGradeRow("GradeName") = metBalanceResult.Grade(index).Name.ReadStringWithDbNull()
                    metBalanceGradeRow("HeadValue") = metBalanceResult.Grade(index).HeadValue.ReadAsDoubleWithDbNull(metBalanceResult.Grade(index).HeadValueSpecified)
                    metBalanceGradeRow.SetParentRow(metBalanceRow)
                    metBalanceGradeTable.Rows.Add(metBalanceGradeRow)
                End If
            Next
        End If

    End Sub

    Private Function GetMetBalanceRelevantGrade(ByVal gradeName As Object) As String
        If TypeOf gradeName Is String Then
            Select Case DirectCast(gradeName, String).ToLower
                Case "fe" : Return "Fe"
                Case "p" : Return "P"
                Case "sio2" : Return "SiO2"
                Case "al2o3" : Return "Al2O3"
                Case "loi" : Return "LOI"
                Case "h2o" : Return "H2O"
                Case Else : Return Nothing
            End Select
        Else
            Return Nothing
        End If
    End Function
End Class
