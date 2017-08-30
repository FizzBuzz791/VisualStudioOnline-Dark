Imports System.Data.SqlClient
Imports Snowden.Common.Import
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Bhpbio.Import.BlastholesService

Friend NotInheritable Class ReconBlockInsertUpdate
    Inherits Data.LoadImport

    Private Const _bulkCopyBatchSize As Int32 = 250
    Private Const _nullDefaultString As String = "<n>"
    Private Const _nullDefaultNumber As Int32 = -1
    Private Const _numberOfSecondsPerWebRequest As Int32 = 259200  '3days
    Private Const _numberOfSecondsDivisor As Int32 = 3
    Private Const _minimumDateText As String = "1-Jan-1900"

    Private _settings As ConfigurationSettings
    Private _dateFrom As DateTime
    Private _dateTo As DateTime

    Public Sub New(Optional config As ConfigurationSettings = Nothing)
        ImportGroup = "Reconcilor Generics"
        ImportName = "ReconBlockInsertUpdate"
        _settings = ConfigurationSettings.GetConfigurationSettings(config)
    End Sub

    Protected Overrides Sub ProcessPrepareData()

    End Sub

    Protected Overrides Sub SetupDataAccessObjects()
        Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility()
        dalUtility.DataAccess.DataAccessConnection = ImportDal.DataAccess.DataAccessConnection

        ReferenceDataCachedHelper.UtilityDal = dalUtility
    End Sub

    Protected Overrides Function ValidateParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String), ByVal validationMessage As System.Text.StringBuilder) As Boolean
        Dim testDate As DateTime
        Dim testInt32 As Int32
        Dim parseSucceeded As Boolean
        Dim currentParameter As String = ""

        Dim validates As Boolean = True

        'check that all parameters exists
        If Not parameters.ContainsKey("DateTo") Then
            validates = False
            validationMessage.Append("Cannot find the DateTo parameter.")
        ElseIf Not parameters.ContainsKey("DateFrom") Then
            validates = False
            validationMessage.Append("Cannot find the DateFrom parameter.")
        ElseIf Not parameters.ContainsKey("DateFromLookbackDays") Then
            validates = False
            validationMessage.Append("Cannot find the DateFromLookbackDays parameter.")
        ElseIf Not parameters.ContainsKey("DateFromAbsoluteMinimum") Then
            validates = False
            validationMessage.Append("Cannot find the DateFromAbsoluteMinimum parameter.")
        ElseIf parameters("DateFrom") = Nothing And _
         parameters("DateFromLookbackDays") = Nothing And _
         parameters("DateFromAbsoluteMinimum") = Nothing Then
            validates = False
            validationMessage.Append("Values must be specified for at least one of the DateFrom, DateFromLookbackDays or DateFromAbsoluteMinumum parameters.")
        Else
            'check that the parameters contain the correct contents

            'check the parameter is either Empty and a valid date
            For Each currentParameter In New String() {"DateTo", "DateFrom", "DateFromAbsoluteMinimum"}
                If Not (parameters(currentParameter) = Nothing) Then
                    parseSucceeded = DateTime.TryParse(parameters(currentParameter), testDate)
                    If Not parseSucceeded Then
                        validates = False
                        validationMessage.Append("The ")
                        validationMessage.Append(currentParameter)
                        validationMessage.Append(" parameter must be a valid date.")
                    End If
                End If
            Next

            'check that the DateFromLookbackDays is a valid number
            If validates Then
                If Not (parameters("DateFromLookbackDays") = Nothing) Then
                    parseSucceeded = Int32.TryParse(parameters("DateFromLookbackDays"), testInt32)
                    If Not parseSucceeded Then
                        validates = False
                        validationMessage.Append("The DateFromLookbackDays parameter must be a whole number.")
                    End If
                End If
            End If
        End If

        Return validates
    End Function

    Protected Overrides Sub LoadParameters(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String))

        Dim dateFromLookback As DateTime

        'determine the final from/to dates based on the parameters above
        If parameters("DateTo") = Nothing Then
            _dateTo = DateTime.SpecifyKind(Now, DateTimeKind.Unspecified)
        Else
            _dateTo = Convert.ToDateTime(parameters("DateTo"))
        End If

        'take the earliest date defined from the two "from" date options
        If parameters("DateFrom") = Nothing Then
            _dateFrom = Nothing
        Else
            _dateFrom = Convert.ToDateTime(parameters("DateFrom"))
        End If

        If Not String.IsNullOrEmpty(parameters("DateFromLookbackDays")) Then
            dateFromLookback = _dateTo.AddDays(-Convert.ToInt32(parameters("DateFromLookbackDays")))
            If (_dateFrom = Nothing) OrElse (dateFromLookback < _dateFrom) Then
                _dateFrom = dateFromLookback
            End If
        End If

        If (_dateFrom = Nothing) OrElse (_dateFrom < CDate(IIf(parameters("DateFromAbsoluteMinimum") <> "", parameters("DateFromAbsoluteMinimum"), _minimumDateText))) Then
            _dateFrom = Convert.ToDateTime(parameters("DateFromAbsoluteMinimum"))
        End If
    End Sub

    Protected Overrides Function LoadSource() As Integer
        Dim data As DataSet = Nothing
        Dim schemaReader As System.IO.StringReader = Nothing

        Try
            'Read in the schema
            data = New DataSet()
            schemaReader = New System.IO.StringReader(My.Resources.ResourceManager.GetObject("BlastBlockInsertUpdateLoadSource").ToString)
            data.ReadXmlSchema(schemaReader)

            'emulate the loaddata call
            If QuickOptions.LoadData Then
                data.ReadXml(QuickOptions.LoadDataPath)
            Else
                'load the data into the ADO.NET dataset
                LoadSourceFromWebService(_dateFrom, _dateTo, data)
            End If

            data.AcceptChanges()

            Trace.WriteLine("")
            Trace.WriteLine("Data Loaded (rows):")
            Trace.WriteLine("  BlastBlock: " & data.Tables("BlastBlock").Rows.Count)
            Trace.WriteLine("  BlastBlockModel: " & data.Tables("BlastBlockModel").Rows.Count)
            Trace.WriteLine("  BlastBlockModelGrade: " & data.Tables("BlastBlockModelGrade").Rows.Count)

            'emulate the savedata call
            If QuickOptions.SaveData Then
                data.WriteXml(QuickOptions.SaveDataPath)
            End If

            'Synchronize with database, simple replacement
            SynchronizeHoldingTable(data)

        Finally
            If Not schemaReader Is Nothing Then
                schemaReader.Dispose()
                schemaReader = Nothing
            End If
        End Try
    End Function

    Private Sub SynchronizeHoldingTable(ByVal data As DataSet)
        Dim blockHoldingRow As DataRow
        Dim blockModelHoldingRows As DataRow()
        Dim blockModelHoldingRow As DataRow
        Dim blockModelGradeHoldingRows As DataRow()
        Dim bhpbioStagingBlockId As Integer

        Dim bhpbioImportDal As DalBaseObjects.IBhpbioBlock
        Dim displayInterval As Int32

        'set up the DALs
        bhpbioImportDal = New SqlDal.SqlDalBhpbioBlock

        Try
            bhpbioImportDal.DataAccess.DataAccessConnection = ImportDal.DataAccess.DataAccessConnection

            'Clear all error messages from previous run
            bhpbioImportDal.DeleteBhpbioImportLoadRowMessages()

            displayInterval = Convert.ToInt32(data.Tables("BlastBlock").Rows.Count / 50)
            If displayInterval = 0 Then
                displayInterval = 1
            End If

            'synchronise the blocks
            For Each blockHoldingRow In data.Tables("BlastBlock").Rows

                Dim modelBlockId As Nullable(Of Integer)

                'display the progress indicator
                If (data.Tables("BlastBlock").Rows.IndexOf(blockHoldingRow) Mod displayInterval) = 0 Then
                    Trace.WriteLine("Record: " & data.Tables("BlastBlock").Rows.IndexOf(blockHoldingRow).ToString & " of " & data.Tables("BlastBlock").Rows.Count)
                End If

                'run a transaction block by block
                bhpbioImportDal.DataAccess.BeginTransaction()

                'Get Block Id
                'If Block Id does not exist this should have been picked up as a validation error
                bhpbioStagingBlockId = bhpbioImportDal.GetBhpbioStagingBlockId( _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("BlockNumber"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("BlockName"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Site"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Orebody"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Pit"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Bench"), NullValues.String)), _
                    Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("PatternNumber"), NullValues.String)))

                blockModelHoldingRows = data.Tables("BlastBlockModel").Select("BlockId = " & Convert.ToInt32(blockHoldingRow("BlockId")).ToString)

                If (blockModelHoldingRows.Length > 0 And bhpbioStagingBlockId = NullValues.Int32) Then

                    'if there is a model for a block which does not exist yet, then log validation failure (but only one per block)
                    bhpbioImportDal.AddOrUpdateBhpbioImportLoadRowMessages( _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("BlockNumber"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("BlockName"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Site"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Orebody"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Pit"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("Bench"), NullValues.String)), _
                        Convert.ToString(DataHelper.IfDBNull(blockHoldingRow("PatternNumber"), NullValues.String)), _
                        "Grade Control") 'this is to state that record is missing for Grade Control Model

                Else
                    'load related BlockModelGrade records (for all models?)
                    blockModelGradeHoldingRows = data.Tables("BlastBlockModelGrade").Select("BlockId = " & Convert.ToInt32(blockHoldingRow("BlockId")).ToString)

                    Dim modelTypeSet As New HashSet(Of String)

                    'loop for each model record
                    For Each blockModelHoldingRow In blockModelHoldingRows
                        Dim modelName As String = Convert.ToString(blockModelHoldingRow("ModelName"))
                        modelBlockId = Nothing




                        'Exclude Grade Control records
                        If modelName <> "Grade Control" Then
                            ' if this is the first model record for the specific model type...
                            ' clear out model data for this type
                            If (Not modelTypeSet.Contains(modelName)) Then
                                modelTypeSet.Add(modelName)

                                bhpbioImportDal.DeleteBhpbioStageBlockModels(bhpbioStagingBlockId, modelName)
                            End If

                            Dim LumpPercentAsShipped As Decimal = Convert.ToDecimal(DataHelper.IfDBNull(blockModelHoldingRow("ModelLumpPercentAsShipped"), NullValues.Decimal))
                            Dim LumpPercentAsDropped As Decimal = Convert.ToDecimal(DataHelper.IfDBNull(blockModelHoldingRow("ModelLumpPercentAsDropped"), NullValues.Decimal))

                            bhpbioImportDal.AddBhpbioStageBlockModel(modelName,
                                                                    bhpbioStagingBlockId,
                                                                    Convert.ToString(blockModelHoldingRow("ModelOreType")),
                                                                    Convert.ToDouble(blockModelHoldingRow("ModelVolume")),
                                                                    Convert.ToDouble(blockModelHoldingRow("ModelTonnes")),
                                                                    Convert.ToDouble(blockModelHoldingRow("ModelDensity")),
                                                                    Convert.ToString(blockModelHoldingRow("LastModifiedUser")),
                                                                    Convert.ToDateTime(DataHelper.IfDBNull(blockModelHoldingRow("LastModifiedDate"), NullValues.DateTime)),
                                                                    Convert.ToString(blockModelHoldingRow("ModelFilename")),
                                                                    LumpPercentAsShipped,
                                                                    LumpPercentAsDropped,
                                                                    Nothing,
                                                                    modelBlockId)

                            If (Not modelBlockId Is Nothing) Then
                                ' perform grade inserts
                                Dim modelBlockGradeRows = blockModelGradeHoldingRows _
                                    .Where(Function(r) r("ModelName").ToString = blockModelHoldingRow("ModelName").ToString _
                                               AndAlso r("ModelOreType").ToString = blockModelHoldingRow("ModelOreType").ToString) _
                                    .ToList


                                For Each modelBlockGradeRow In modelBlockGradeRows
                                    If Convert.ToString(modelBlockGradeRow("GradeName")).StartsWith("ResourceClassification") Then
                                        InsertResourceClassificationGrade(bhpbioImportDal, modelBlockId.Value, modelBlockGradeRow)
                                        Continue For
                                    End If

                                    'Exclude Grade Control records
                                    If Convert.ToString(modelBlockGradeRow("ModelName")) <> "Grade Control" Then

                                        ' ignore moisture grades for rows other than those with a geomet type - we insert these manually because of the transformation we need to do on them
                                        Dim gradeName = Convert.ToString(modelBlockGradeRow("GradeName"))
                                        Dim geometType As String = CodeTranslationHelper.ToGeometTypeString(modelBlockGradeRow("GeometType"))

                                        bhpbioImportDal.AddBhpbioStageBlockModelGrade(modelBlockId.Value,
                                              geometType,
                                              Convert.ToString(modelBlockGradeRow("GradeName")),
                                              Convert.ToDouble(DataHelper.IfDBNull(modelBlockGradeRow("GradeValue"), NullValues.Double)),
                                              Convert.ToDouble(DataHelper.IfDBNull(modelBlockGradeRow("LumpValue"), NullValues.Double)),
                                              Convert.ToDouble(DataHelper.IfDBNull(modelBlockGradeRow("FinesValue"), NullValues.Double)))
                                    End If
                                Next
                            End If

                        End If
                    Next
                End If

                'commit the transaction (block by block)
                bhpbioImportDal.DataAccess.CommitTransaction()
            Next

        Finally
            If (Not bhpbioImportDal.DataAccess.Transaction Is Nothing) Then
                bhpbioImportDal.DataAccess.RollbackTransaction()
            End If

            If Not bhpbioImportDal Is Nothing Then
                bhpbioImportDal.Dispose()
                bhpbioImportDal = Nothing
            End If
        End Try
    End Sub

    ' With the moisture grades we have to do some normalization in order to get the grades values we want
    ' We get two grades from BH - H2O and H2O_AD. These then need to be transformed in order to create the
    ' 3 grades that we need
    '
    ' H2O[Total] = H2O[Total] (unchanged)
    ' H2O[Lump] = null
    ' H2O[Fines] = null
    '
    ' H2O-As-Shipped[Total] = Calculated from L/F split
    ' H2O-As-Shipped[Lump] = H2O[Lump]
    ' H2O-As-Shipped[Fines] = H2O[Fines]
    '
    ' ' AD values come from a grade called H2O_AD
    ' H2O-As-Dropped[Total] = Calculated from L/F split
    ' H2O-As-Dropped[Lump] = H2O_AD[Lump]
    ' H2O-As-Dropped[Fines] = H2O_AD[Fines]
    '
    ' See WREC-667 for a complete description of this.
    '
    <Obsolete("This method is no longer required as the As-Shipped and As-Dropped grades are stored explicitly in staging")>
    Private Sub InsertModelMoistureGrades(ByVal bhpbioImportDal As DalBaseObjects.IBhpbioBlock, ByVal bhpbioBlockModelId As Integer,
                                     ByRef H2O As DataRow, ByRef H2O_AS As DataRow, ByRef H2O_AD As DataRow, ByVal ModelLumpPercentAsShipped As Decimal, ByVal ModelLumpPercentAsDropped As Decimal)

        ModelLumpPercentAsDropped = ModelLumpPercentAsDropped / 100D
        ModelLumpPercentAsShipped = ModelLumpPercentAsShipped / 100D

        If Not H2O Is Nothing Then
            bhpbioImportDal.AddBhpbioStageBlockModelGrade(bhpbioBlockModelId,
             CodeTranslationHelper.GEOMET_TYPE_NA,
             "H2O",
             Convert.ToDouble(H2O("GradeValue")),
             NullValues.Double,
             NullValues.Double
            )
        End If

        If Not H2O_AS Is Nothing Then
            Dim H2O_AS_Lump = DataHelper.IfDBNull(H2O_AS("LumpValue"), NullValues.Double)
            Dim H2O_AS_Fines = DataHelper.IfDBNull(H2O_AS("FinesValue"), NullValues.Double)

            If H2O_AS_Lump <> NullValues.Double And H2O_AS_Fines <> NullValues.Double And ModelLumpPercentAsShipped <> NullValues.Decimal Then
                bhpbioImportDal.AddBhpbioStageBlockModelGrade(bhpbioBlockModelId,
                 CodeTranslationHelper.GEOMET_TYPE_NA,
                 "H2O-As-Shipped",
                 (H2O_AS_Lump * ModelLumpPercentAsShipped) + (H2O_AS_Fines * (1 - ModelLumpPercentAsShipped)),
                 H2O_AS_Lump,
                 H2O_AS_Fines
                )
            End If
        End If

        If Not H2O_AD Is Nothing Then
            Dim H2O_AD_Lump = DataHelper.IfDBNull(H2O_AD("LumpValue"), NullValues.Double)
            Dim H2O_AD_Fines = DataHelper.IfDBNull(H2O_AD("FinesValue"), NullValues.Double)

            If H2O_AD_Lump <> NullValues.Double And H2O_AD_Fines <> NullValues.Double And ModelLumpPercentAsDropped <> NullValues.Decimal Then
                bhpbioImportDal.AddBhpbioStageBlockModelGrade(bhpbioBlockModelId,
                 CodeTranslationHelper.GEOMET_TYPE_NA,
                 "H2O-As-Dropped",
                 (H2O_AD_Lump * ModelLumpPercentAsDropped) + (H2O_AD_Fines * (1 - ModelLumpPercentAsDropped)),
                 H2O_AD_Lump,
                 H2O_AD_Fines
                )
            End If
        End If
    End Sub
    Private Sub InsertResourceClassificationGrade(ByVal bhpbioImportDal As DalBaseObjects.IBhpbioBlock, ByVal bhpbioBlockModelId As Integer,
                                     ByRef resourceRow As DataRow)

        If resourceRow IsNot Nothing Then
            Dim resourceClassification = resourceRow("GradeName").ToString()
            Dim resourceClassificationPct = Convert.ToDouble(resourceRow("GradeValue"))
            bhpbioImportDal.AddUpdateBlockModelResourceClassification(bhpbioBlockModelId, resourceClassification, resourceClassificationPct)
        End If

    End Sub
    ''' <summary>
    ''' Invokes the Web Service specified; functionality currently stubbed.
    ''' </summary>
    ''' <param name="webServiceUri"></param>
    ''' <param name="returnDataSet"></param>
    ''' <remarks></remarks>
    Private Sub LoadSourceFromWebService(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal returnDataSet As DataSet)
        Dim client As BlastholesService.IM_Blastholes_DS

        'create a new wcf-client instance
        client = WebServicesFactory.CreateBlastholesWebServiceClient()

        GetWebRequestDataPeriod(dateFrom, dateTo, _numberOfSecondsPerWebRequest, client, returnDataSet)

        'remove the rows marked as delete
        'note that nothing is being deleted! it's just for good practise to ensure it's clean when passed out

        returnDataSet.AcceptChanges()
    End Sub

    Private Sub GetWebRequestDataPeriod(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal requestIntervalSeconds As Int32, _
        ByVal client As BlastholesService.IM_Blastholes_DS, ByVal returnDataSet As DataSet)

        Dim currentDateFrom As DateTime
        Dim currentDateTo As DateTime
        Dim successfulRequest As Boolean

        'loop through the dates based on a specified period
        currentDateFrom = dateFrom
        currentDateTo = dateFrom.AddSeconds(requestIntervalSeconds).AddMilliseconds(-1)
        If currentDateTo >= dateTo Then
            currentDateTo = dateTo
        End If

        While currentDateFrom < dateTo
            successfulRequest = GetWebRequestData(currentDateFrom, currentDateTo, client, returnDataSet)

            If Not successfulRequest Then
                'request the same period - based on a shorter date range
                If requestIntervalSeconds = 1 Then
                    Throw New InvalidOperationException( _
                        String.Format("The request interval cannot be further reduced below 1-second. Dates requested: {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy}.", _
                            dateFrom, dateTo))
                End If

                'recursively call to progress the date range
                GetWebRequestDataPeriod(currentDateFrom, currentDateTo, requestIntervalSeconds \ _numberOfSecondsDivisor, client, returnDataSet)
            End If

            'increment the date range
            currentDateFrom = currentDateTo
            currentDateTo = currentDateFrom.AddSeconds(requestIntervalSeconds).AddMilliseconds(-1)
            If currentDateTo >= dateTo Then
                currentDateTo = dateTo
            End If
        End While
    End Sub

    Private Function GetWebRequestData(ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
        ByVal client As BlastholesService.IM_Blastholes_DS, ByVal returnDataSet As DataSet) As Boolean

        Dim retrieveBlocksRequest1 As retrieveReconciliationBlocksRequest1
        Dim blocksRequest As RetrieveReconciliationBlocksRequest
        Dim retrieveBlocksResponse1 As retrieveReconciliationBlocksResponse1
        Dim blocksResponse As RetrieveReconciliationBlocksResponse

        Trace.WriteLine(String.Empty)
        Trace.WriteLine("Request:")
        Trace.WriteLine(String.Format("  Period = {0:dd-MMM-yyyy} to {1:dd-MMM-yyyy}", dateFrom, dateTo.ToString))
        Trace.WriteLine(String.Format("  Range = {0} minutes.", (dateTo - dateFrom).TotalMinutes.ToString("0.0")))

        'define the parameters
        blocksRequest = New RetrieveReconciliationBlocksRequest()
        blocksRequest.StartDateSpecified = True
        blocksRequest.EndDateSpecified = True
        blocksRequest.StartDate = dateFrom.ToUniversalTime()
        blocksRequest.EndDate = dateTo.ToUniversalTime()

        'create a new request and invoke it
        retrieveBlocksRequest1 = New retrieveReconciliationBlocksRequest1(blocksRequest)
        retrieveBlocksResponse1 = client.retrieveReconciliationBlocks(retrieveBlocksRequest1)
        blocksResponse = retrieveBlocksResponse1.RetrieveReconciliationBlocksResponse

        'check we received a payload - we always expect one
        If blocksResponse.Status.StatusFlag Then
            Trace.WriteLine(String.Format("Successfully received response at: {0:HH:mm:ss dd-MMM-yyyy}", DateTime.Now))
        Else
            Throw New InvalidOperationException(String.Format("Error while receiving response (at {0:HH:mm:ss dd-MMM-yyyy}) with status message: {1}", _
                DateTime.Now, blocksResponse.Status.StatusMessage))
        End If

        'loop through each record and populate the data set; check if data conforms to schema on each iteration
        If (Not blocksResponse.FetchReconciliationBlocksResponse Is Nothing) AndAlso _
            (Not blocksResponse.FetchReconciliationBlocksResponse.FetchReconciliationBlocksResult Is Nothing) Then

            For index As Integer = 0 To blocksResponse.FetchReconciliationBlocksResponse.FetchReconciliationBlocksResult.Length - 1
                returnDataSet.EnforceConstraints = False

                LoadBlastBlockRecord(blocksResponse.FetchReconciliationBlocksResponse.FetchReconciliationBlocksResult(index), returnDataSet)

                Try
                    returnDataSet.EnforceConstraints = True
                Catch ex As ConstraintException
                    Throw New DataException(returnDataSet.GetErrorReport(), ex)
                End Try
            Next
        End If

        Return True 'if we got this far, then we're successful
    End Function

    ''' <summary>
    ''' Loads the single Block element contained within the payload.
    ''' </summary>
    Private Sub LoadBlastBlockRecord(ByVal block As BlockType, ByVal returnDataSet As DataSet)
        Dim blastBlockTable As DataTable
        Dim blastBlockPointTable As DataTable
        Dim blastBlockModelTable As DataTable
        Dim blastBlockModelGradeTable As DataTable
        Dim blastBlockRow As DataRow
        Dim index As Integer

        Try
            blastBlockTable = returnDataSet.Tables("BlastBlock")
            blastBlockPointTable = returnDataSet.Tables("BlastBlockPoint")
            blastBlockModelTable = returnDataSet.Tables("BlastBlockModel")
            blastBlockModelGradeTable = returnDataSet.Tables("BlastBlockModelGrade")

            blastBlockRow = blastBlockTable.NewRow()
            blastBlockTable.Rows.Add(blastBlockRow)

            blastBlockRow("BlockNumber") = block.Number.ReadStringWithDbNull()
            blastBlockRow("BlockName") = block.Name.ReadStringWithDbNull()
            If (Not blastBlockRow("BlockName") Is System.DBNull.Value) Then
                blastBlockRow("BlockName") = blastBlockRow("BlockName").ToString().Trim()
            End If
            blastBlockRow("GeoType") = block.GeoType.ReadStringWithDbNull()
            blastBlockRow("MQ2PitCode") = block.MQ2PitCode.ReadStringWithDbNull()
            blastBlockRow("BlockedDate") = block.BlockedDate.ReadAsDateWithDbNull(block.BlockedDateSpecified)
            blastBlockRow("BlastedDate") = block.BlastedDate.ReadAsDateWithDbNull(block.BlastedDateSpecified)

            'Pattern
            If (Not block.Pattern Is Nothing) Then
                blastBlockRow("Site") = block.Pattern.Site.ReadStringWithDbNull()
                blastBlockRow("Orebody") = block.Pattern.Orebody.ReadStringWithDbNull()
                blastBlockRow("Pit") = block.Pattern.Pit.ReadStringWithDbNull()
                blastBlockRow("Bench") = block.Pattern.Bench.ReadStringWithDbNull()
                blastBlockRow("PatternNumber") = block.Pattern.Number.ReadStringWithDbNull()
            End If

            'Model
            If (Not block.Model Is Nothing) Then
                For index = 0 To block.Model.Length - 1 Step 1
                    LoadModel(block.Model(index), blastBlockRow, blastBlockModelTable, blastBlockModelGradeTable)
                Next
            End If

        Catch ex As Exception
            Throw New DataException(String.Format( _
                "Unable to load blast block with site '{0}', orebody '{1}', pit '{2}', bench '{3}' patternnumber '{4}' and blocknumber '{5}'.", _
                block.Pattern.Site, block.Pattern.Orebody, block.Pattern.Pit, block.Pattern.Bench, block.Pattern.Number, block.Number), ex)
        End Try
    End Sub

    ''' <summary>
    ''' Loads the single Model record.
    ''' </summary>
    Private Sub LoadModel(ByVal model As ModelType, ByVal blastBlockRow As DataRow, _
        ByVal blastBlockModelTable As DataTable, ByVal blastBlockModelGradeTable As DataTable)

        ' skip this record if a valid model name is not returned
        If (Not TranslateModelName(model.Name.ReadStringWithDbNull()) Is System.DBNull.Value) Then
            Dim blastBlockModelRow As DataRow

            blastBlockModelRow = blastBlockModelTable.NewRow()
            blastBlockModelRow.SetParentRow(blastBlockRow)
            blastBlockModelTable.Rows.Add(blastBlockModelRow)

            'set the defaults - unfortunately these can be null from the source
            blastBlockModelRow("ModelOreType") = _nullDefaultString

            blastBlockModelRow("ModelName") = TranslateModelName(model.Name.ReadStringWithDbNull())
            If (Not model.OreType.ReadStringWithDbNull() Is System.DBNull.Value) Then
                blastBlockModelRow("ModelOreType") = model.OreType.ReadStringWithDbNull()
            End If
            blastBlockModelRow("ModelFilename") = model.Filename.ReadStringWithDbNull()
            blastBlockModelRow("ModelVolume") = model.Volume.ReadAsDoubleWithDbNull(model.VolumeSpecified)
            blastBlockModelRow("ModelTonnes") = model.Tonnes.ReadAsDoubleWithDbNull(model.TonnesSpecified)
            blastBlockModelRow("ModelDensity") = model.Density.ReadAsDoubleWithDbNull(model.DensitySpecified)
            blastBlockModelRow("ModelLumpPercentAsShipped") = model.LumpPercentAsShipped.ReadAsDoubleWithDbNull(model.LumpPercentAsShippedSpecified)
            blastBlockModelRow("ModelLumpPercentAsDropped") = model.LumpPercentAsDropped.ReadAsDoubleWithDbNull(model.LumpPercentAsDroppedSpecified)
            blastBlockModelRow("LastModifiedUser") = model.LastModifiedUser.ReadStringWithDbNull()
            If (model.LastModifiedDateSpecified AndAlso model.LastModifiedDate > NullValues.DateTime) Then
                blastBlockModelRow("LastModifiedDate") = model.LastModifiedDate.ReadAsDateTimeWithDbNull(model.LastModifiedDateSpecified)
            Else
                blastBlockModelRow("LastModifiedDate") = NullValues.DateTime
            End If

            For index As Integer = 0 To model.Grade.Length - 1 Step 1
                Dim grade As BlastholesService.Grade = model.Grade(index)
                LoadGrade(grade, blastBlockModelGradeTable, blastBlockModelRow)
            Next
        End If

    End Sub

    ''' <summary>
    ''' Loads the single Grade object contained within the ModelType object.
    ''' </summary>
    Private Sub LoadGrade(ByVal grade As BlastholesService.Grade, ByVal blastBlockModelGrade As DataTable, ByVal blastBlockModelRow As DataRow)

        Dim gradeName As String = CodeTranslationHelper.GetRelevantGrade(grade.Name.ReadStringWithDbNull())
        Dim geometType As String = CodeTranslationHelper.ToGeometTypeString(grade.GeometType)

        If Not gradeName Is Nothing Then
            Dim gradeValue As Object = grade.HeadValue.ReadAsDoubleWithDbNull(grade.HeadValueSpecified)
            Dim lumpValue As Object = grade.LumpValue.ReadAsDoubleWithDbNull(grade.LumpValueSpecified)
            Dim finesValue As Object = grade.FinesValue.ReadAsDoubleWithDbNull(grade.FinesValueSpecified)

            ' only try to insert if there is some kind of value
            ' ignore grade entries that have no values at all
            If ((Not gradeValue Is Nothing AndAlso Not gradeValue Is DBNull.Value) OrElse _
               (Not lumpValue Is Nothing AndAlso Not lumpValue Is DBNull.Value) OrElse _
               (Not finesValue Is Nothing AndAlso Not finesValue Is DBNull.Value)) Then

                ' there is some kind of value to be saved
                Dim blastBlockModelGradeRow As DataRow = blastBlockModelGrade.NewRow()
                blastBlockModelGradeRow.SetParentRow(blastBlockModelRow)
                blastBlockModelGrade.Rows.Add(blastBlockModelGradeRow)

                blastBlockModelGradeRow("GradeName") = gradeName
                blastBlockModelGradeRow("GeometType") = geometType
                blastBlockModelGradeRow("GradeValue") = gradeValue
                blastBlockModelGradeRow("LumpValue") = lumpValue
                blastBlockModelGradeRow("FinesValue") = finesValue
            End If
        End If
    End Sub

    Private Function TranslateModelName(ByVal modelName As Object) As Object
        If TypeOf modelName Is String Then
            Select Case DirectCast(modelName, String).ToLower
                Case "block" : Return "Grade Control"
                Case "gradecontrol" : Return "Grade Control"
                Case "reserve" : Return "Mining"
                Case "resource" : Return "Geology"
                Case "stgm" : Return "Short Term Geology"
                Case Else : Return modelName
            End Select
        Else
            Return DBNull.Value
        End If
    End Function

    Protected Overrides Function ProcessData() As Integer
        'do nothing
    End Function
End Class
