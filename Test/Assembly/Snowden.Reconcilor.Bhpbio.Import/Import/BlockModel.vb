Imports System.IO
Imports System.Runtime.CompilerServices
Imports System.Text
Imports System.Xml
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database
Imports Snowden.Common.Import
Imports Snowden.Common.Import.Data
Imports Snowden.Common.Import.Database
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.Database.SqlDal
Imports Snowden.Reconcilor.Core.Import
Imports Snowden.Reconcilor.Core.Import.StandardImports
Imports IDigblock = Snowden.Reconcilor.Core.Database.DalBaseObjects.IDigblock
Imports IHaulage = Snowden.Reconcilor.Core.Database.DalBaseObjects.IHaulage

Friend NotInheritable Class BlockModel
    Inherits BlockModelSyncImport

    Private Const MAXIMUM_ALLOWED_POINTS As Integer = 20000
    Private Const MAXIMUM_ALLOWED_RESOURCE_CLASS As Double = 100
    Private Const GRADE_CONTROL_MODEL_NAME As String = "Grade Control"
    Private Const MATERIAL_CATEGORY_ID As String = "OreType"
    Private ReadOnly _gradeNamesToInvert As String() = {"Density"}
    Private _bhpbioUtilityDal As IUtility
    Private _digblockDal As IDigblock
    Private _bhpbioImportDal As IBhpbioBlock
    Private _approvalDal As IApproval
    Private _haulageDal As IHaulage
    Private _bhpbioDigblockDal As Database.DalBaseObjects.IDigblock
    Private _bhpbioImportManagerDal As Database.DalBaseObjects.IImportManager

    Private ReadOnly _resourceClassificationColumnNames As String() = {
        "ResourceClassification1",
        "ResourceClassification2",
        "ResourceClassification3",
        "ResourceClassification4",
        "ResourceClassification5"
    }

    Private _site As String
    Private _pit As String
    Private _bench As String

    Private ReadOnly Property Site As String
        Get
            Return _site
        End Get
    End Property

    Private ReadOnly Property Pit As String
        Get
            Return _pit
        End Get
    End Property

    Private ReadOnly Property Bench As String
        Get
            Return _bench
        End Get
    End Property

    Protected Overrides Function ValidateParameters(parameters As IDictionary(Of String, String),
                                                    validationMessage As StringBuilder) As Boolean
        'check that all parameters exists
        If Not parameters.ContainsKey("Site") _
         AndAlso Not parameters.ContainsKey("Pit") _
         AndAlso Not parameters.ContainsKey("Bench") Then
            validationMessage.Append("Cannot find the Site, Pit or Bench parameters.  At least one must be provided.")
            Return False
        Else
            Return True
        End If
    End Function

    Protected Overrides Sub LoadParameters(parameters As IDictionary(Of String, String))
        If (parameters.ContainsKey("Site")) AndAlso (parameters("Site") <> String.Empty) Then
            _site = CodeTranslationHelper.SingleSiteCodeFromReconcilor(parameters("Site").Trim(" "c).ToUpper, toShortCode:=False)
        Else
            _site = Nothing
        End If

        If parameters.ContainsKey("Pit") AndAlso (parameters("Pit") <> String.Empty) Then
            _pit = CodeTranslationHelper.CorrectPit(parameters("Pit"))
        Else
            _pit = Nothing
        End If

        If parameters.ContainsKey("Bench") AndAlso (parameters("Bench") <> String.Empty) Then
            _bench = CodeTranslationHelper.CorrectBench(parameters("Bench"))
        Else
            _bench = Nothing
        End If
    End Sub

    Protected Overrides Sub ProcessPrepareData(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow,
        syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow, importSyncDal As ImportSync)
        'do nothing (i.e. override Core)
    End Sub

    Protected Overrides Function LoadSource(sourceSchema As StringReader) As DataSet
        Dim returnDataSet As DataSet
        Dim blockImportDal As IBhpbioBlock = Nothing
        Dim row As DataRow

        'simply confirms that a schema is provided
        If sourceSchema Is Nothing Then
            Throw New ArgumentException("A block model source schema must be provided.")
        Else
            Dim schemaName As String = SourceSchemaName + "Source"
            returnDataSet = New DataSet()
            returnDataSet.ReadXmlSchema(sourceSchema)
            returnDataSet.DataSetName = schemaName
        End If

        Try
            returnDataSet.Tables("BlastModelBlockWithPointAndGrade").BeginLoadData()

            blockImportDal = New SqlDalBhpbioBlock
            blockImportDal.DataAccess.DataAccessConnection = ImportDal.DataAccess.DataAccessConnection

            returnDataSet.Tables("BlastModelBlockWithPointAndGrade").Merge(
                blockImportDal.GetBhpbioStagingModelBlocks(
                    Convert.ToString(IIf(Site Is Nothing, NullValues.String, Site)),
                    Convert.ToString(IIf(Pit Is Nothing, NullValues.String, Pit)),
                    Convert.ToString(IIf(Bench Is Nothing, NullValues.String, Bench))))

            For Each row In returnDataSet.Tables("BlastModelBlockWithPointAndGrade").Rows
                'loop through the incoming point data and replace it with a compressed stream
                If Not (row("Point") Is DBNull.Value) Then
                    row("Point") = GeneralHelper.CompressString(Convert.ToString(row("Point")), "<cp>", "</cp>")
                End If

                'correct the block names
                'correct: Pit, Bench, PatternNumber, BlockName
                row("Pit") = CodeTranslationHelper.CorrectPit(Convert.ToString(row("Pit")))
                row("Bench") = CodeTranslationHelper.CorrectBench(Convert.ToString(row("Bench")))
                row("PatternNumber") = CodeTranslationHelper.CorrectPatternNumber(Convert.ToString(row("PatternNumber")))
                row("BlockName") = CodeTranslationHelper.CorrectBlockName(Convert.ToString(row("BlockName")))
            Next

            Try
                returnDataSet.Tables("BlastModelBlockWithPointAndGrade").EndLoadData()
                ' Allow constraint errors to continue on importing the rest of the import
            Catch ex As ConstraintException
                ConstraintError = DataHelper.CheckDataSetConstraints(returnDataSet)
                ImportHelper.RemoveConstraintErrorRows(returnDataSet)
                returnDataSet.EnforceConstraints = True
            End Try

        Finally
            If Not (blockImportDal Is Nothing) Then
                blockImportDal.Dispose()
            End If
        End Try

        returnDataSet.AcceptChanges()

        Return returnDataSet
    End Function

    Protected Overrides Function GetImportSyncRows() As IDataReader
        Return _bhpbioImportManagerDal.GetBhpbioBlockImportSyncRowsForLocation(ImportId, 1, _site, _pit, _bench)
    End Function

    Protected Overrides Function GetNextSyncQueueEntry(syncTableOrderNo As Long, importId As Short) As DataTable
        Return _bhpbioImportManagerDal.GetBhpbioNextSyncQueueEntryForLocation(syncTableOrderNo, importId, _site, _pit, _bench)
    End Function

    Protected Overrides Function LoadDestinationRow(tableName As String, keyRows As DataRow) As Boolean
        Return (_site Is Nothing OrElse _site = Convert.ToString(keyRows("Site"))) _
            AndAlso (_pit Is Nothing OrElse _pit = Convert.ToString(keyRows("Pit"))) _
            AndAlso (_bench Is Nothing OrElse _bench = Convert.ToString(keyRows("Bench")))
    End Function

    Protected Overrides Sub LoadDataSet(sourceDataSet As DataSet)

    End Sub

    Protected Overrides Sub ProcessValidate(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow, importSyncValidate As DataTable,
        importSyncValidateField As DataTable, syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow, syncQueueChangedFields As DataTable,
        importSyncDal As ImportSync)

        Dim fieldName As String
        Dim hasLumpFinesPercentAsShipped = False
        Dim hasLumpFinesPercentAsDropped = False
        Dim geometType = String.Empty

        Dim siteLocationId As Int32?
        Dim doc As XmlDocument
        Dim node As XmlNode
        Dim childNode As XmlNode
        Dim gradeValue As Single
        Dim lumpGradeValue As Single
        Dim finesGradeValue As Single

        Dim currentGrade As String = Nothing

        Dim digblock As Boolean

        Dim spatialX As Double
        Dim spatialY As Double
        Dim spatialZ As Double
        Dim changedFields As DataRow() = Nothing

        ShareDalObjectTransactions()

        'generic check, do for all actions.
        'if it's a digblock - check that it is unique
        Dim blockCode As String = CodeTranslationHelper.GenerateBlockCode(Convert.ToString(sourceRow("BlockName")),
                                                                          Convert.ToString(sourceRow("Pit")), Convert.ToString(sourceRow("Bench")),
                                                                          Convert.ToString(sourceRow("PatternNumber")))

        'Check that it does not exceed the maximum allowable length.
        If blockCode.Length > 31 Then
            Dim message As String = "The blast block '" & blockCode & "' is too long."
            SyncImportDataHelper.AddImportSyncValidate(importSyncValidate, Convert.ToInt64(syncQueueRow("ImportSyncQueueId")), message, message)
        End If

        If Not syncQueueChangedFields Is Nothing Then
            changedFields = syncQueueChangedFields.Select("ChangedField = 'LastModifiedDate' Or ChangedField = 'LastModifiedUser'")
        End If

        'If our changed fields are not only last modified date or last modified user then run the validate steps.
        If (syncQueueChangedFields Is Nothing) OrElse (Not syncQueueChangedFields Is Nothing AndAlso changedFields.Length < syncQueueChangedFields.Rows.Count) Then
            'INSERT CHECKS
            If syncAction = SyncImportSyncActionEnumeration.Insert Then
                'check the locations (orebody, site and pit only - the rest are merged in)
                If Not (sourceRow("Site") Is DBNull.Value) Then
                    siteLocationId = GetSiteLocationId(Convert.ToString(sourceRow("Site")))
                    If Not siteLocationId.HasValue Then
                        GeneralHelper.LogValidationError("The Site, '" & Convert.ToString(sourceRow("Site")) & "' cannot be resolved.", "Site", syncQueueRow,
                                                         importSyncValidate, importSyncValidateField)
                    End If
                End If

                'check that the material type is valid (if the site was provided)
                If siteLocationId.HasValue Then
                    Dim materialTypeId As Integer? = ReferenceDataCachedHelper.GetMaterialTypeId(MATERIAL_CATEGORY_ID,
                                                                                                 Convert.ToString(sourceRow("ModelOreType")),
                                                                                                 LocationDataUncachedHelper.GetParentLocationId(siteLocationId.Value).Value)

                    If Not materialTypeId.HasValue Then
                        materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(MATERIAL_CATEGORY_ID,
                         Convert.ToString(sourceRow("ModelOreType")), siteLocationId.Value)
                    End If

                    If Not materialTypeId.HasValue Then
                        GeneralHelper.LogValidationError("The Model Ore Type, '" & Convert.ToString(sourceRow("ModelOreType")) & "' cannot be resolved.",
                                                         "ModelOreType", syncQueueRow, importSyncValidate, importSyncValidateField)
                    End If
                End If

                'check that the block model exists
                Dim blockModelId As Integer? = ReferenceDataCachedHelper.GetBlockModelId(Convert.ToString(sourceRow("ModelName")))
                If Not blockModelId.HasValue Then
                    GeneralHelper.LogValidationError("The block model '" & Convert.ToString(sourceRow("ModelName")) & "' cannot be located.", "ModelName",
                                                     syncQueueRow, importSyncValidate, importSyncValidateField)
                End If


                If _digblockDal.GetDigblockExists(blockCode) And (Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper())) Then
                    GeneralHelper.LogValidationError("The blast block already exists.",
                                                     "The blast block '" & blockCode & "' already exists.",
                                                     {"BlockName", "Pit", "Bench", "PatternNumber"},
                                                     syncQueueRow, importSyncValidate, importSyncValidateField)
                End If

                'check the centroid information
                'first - check if the block code already exists.  if it does then it's no problem.
                If blockModelId.HasValue AndAlso Not BlockModelDal.GetModelBlockExists(blockModelId.Value, NullValues.Int32, blockCode,
                    NullValues.Double, NullValues.Double, NullValues.Double) Then

                    'we have now confirmed that the code is new
                    'check the centroid information to ensure that we're not duping the centroid information
                    If sourceRow("CentroidEasting") Is DBNull.Value Then
                        spatialX = NullValues.Double
                    Else
                        spatialX = Convert.ToDouble(sourceRow("CentroidEasting"))
                    End If

                    If sourceRow("CentroidNorthing") Is DBNull.Value Then
                        spatialY = NullValues.Double
                    Else
                        spatialY = Convert.ToDouble(sourceRow("CentroidNorthing"))
                    End If

                    If sourceRow("CentroidRL") Is DBNull.Value Then
                        spatialZ = NullValues.Double
                    Else
                        spatialZ = Convert.ToDouble(sourceRow("CentroidRL"))
                    End If

                    'check the centroid - but for ANY block within this model
                    If BlockModelDal.GetModelBlockExists(blockModelId.Value, NullValues.Int32, NullValues.String, spatialX, spatialY, spatialZ) Then
                        GeneralHelper.LogValidationError("This centroid already belongs to another block for this model.",
                                                         {"CentroidEasting", "CentroidNorthing", "CentroidRL"}, syncQueueRow, importSyncValidate,
                                                         importSyncValidateField)
                    End If
                End If
            End If

            'INSERT / UPDATE checks
            If syncAction = SyncImportSyncActionEnumeration.Insert Or syncAction = SyncImportSyncActionEnumeration.Update Then
                For Each fieldName In New String() {"ModelTonnes", "BlockNumber", "LastModifiedUser", "ModelLumpPercentAsShipped", "ModelLumpPercentAsDropped", "StratNum"}
                    Select Case fieldName
                        Case "ModelTonnes" 'check for <= 0.0 or NULL
                            If (sourceRow(fieldName) Is DBNull.Value OrElse Convert.ToDouble(sourceRow(fieldName)) <= 0.0) Then
                                GeneralHelper.LogValidationError(fieldName & " must be supplied and must be > 0.0.", fieldName, syncQueueRow,
                                                                 importSyncValidate, importSyncValidateField)
                            End If
                        Case "BlockNumber", "LastModifiedUser" 'check for NULL/empty fields
                            If DataHelper.IfDBNull(sourceRow(fieldName), "").Length = 0 Then
                                GeneralHelper.LogValidationError("The " & fieldName & " must be provided.", fieldName, syncQueueRow, importSyncValidate,
                                                                 importSyncValidateField)
                            End If
                        Case "ModelLumpPercentAsShipped" 'check Lump Percent is within a valid range, if present
                            If Not sourceRow(fieldName) Is DBNull.Value Then
                                hasLumpFinesPercentAsShipped = True
                                If (Convert.ToDecimal(sourceRow(fieldName)) < 0.0) Or (Convert.ToDecimal(sourceRow(fieldName)) > 100) Then
                                    GeneralHelper.LogValidationError("Lump Percent As Shipped must be between 0 and 100 inclusive.", fieldName,
                                                                     syncQueueRow, importSyncValidate, importSyncValidateField)
                                End If
                            End If
                        Case "ModelLumpPercentAsDropped" 'check Lump Percent is within a valid range, if present
                            If Not sourceRow(fieldName) Is DBNull.Value Then
                                hasLumpFinesPercentAsDropped = True
                                If (Convert.ToDecimal(sourceRow(fieldName)) < 0.0) Or (Convert.ToDecimal(sourceRow(fieldName)) > 100) Then
                                    GeneralHelper.LogValidationError("Lump Percent As Dropped must be between 0 and 100 inclusive.", fieldName,
                                                                     syncQueueRow, importSyncValidate, importSyncValidateField)
                                End If
                            End If
                        Case "StratNum"
                            If Not sourceRow(fieldName) Is DBNull.Value Then
                                Dim stratNum = CStr(sourceRow(fieldName))
                                If (Not _bhpbioUtilityDal.DoesStratNumExistInStratigraphyHierarchy(stratNum)) Then
                                    GeneralHelper.LogValidationError("StratNum does not exist", $"StratNum {stratNum} does not exist", {stratNum},
                                    syncQueueRow, importSyncValidate, importSyncValidateField)
                                End If
                            End If
                    End Select
                Next

                'check the grades have been provided at all
                If sourceRow("Grade") Is DBNull.Value Then
                    GeneralHelper.LogValidationError("No grades have been provided.", "Grade", syncQueueRow, importSyncValidate, importSyncValidateField)
                Else
                    Dim gradeNameList As IList(Of String) = New List(Of String)

                    doc = New XmlDocument()
                    doc.LoadXml(Convert.ToString(sourceRow("Grade")))

                    ' For Each grade in the block
                    For Each node In doc.SelectNodes("//Grade/row")
                        Dim hasLumpGrade = False
                        Dim hasFinesGrade = False
                        Dim hasLumpAndFineValue = False
                        Dim hasHeadGrade = False
                        Dim hasGeometType = False
                        Dim errorLogged = False
                        gradeValue = 0
                        lumpGradeValue = 0
                        finesGradeValue = 0

                        ' For Each attribute of the grade
                        For Each childNode In node.ChildNodes
                            Select Case childNode.Name
                                Case "GradeName"
                                    currentGrade = childNode.InnerText

                                    gradeNameList.Add(currentGrade.ToLower)

                                    If Not ReferenceDataCachedHelper.GetGradeId(currentGrade).HasValue Then
                                        GeneralHelper.LogValidationError("The Grade Name '" & currentGrade & "' could not be determined.", "Grade", syncQueueRow,
                                                                         importSyncValidate, importSyncValidateField)
                                    End If
                                Case "GradeValue"
                                    If (Not String.IsNullOrEmpty(childNode.InnerText)) Then
                                        hasHeadGrade = True

                                        gradeValue = Convert.ToSingle(childNode.InnerText)

                                        If Convert.ToDouble(gradeValue) < 0.0 Then
                                            GeneralHelper.LogValidationError("The Grade Value cannot be less than zero.", "Grade", syncQueueRow,
                                                                             importSyncValidate, importSyncValidateField)
                                        End If
                                    End If
                                Case "LumpValue", "GradeLumpValue"
                                    If (Not String.IsNullOrEmpty(childNode.InnerText)) Then
                                        lumpGradeValue = Convert.ToSingle(childNode.InnerText)

                                        If Convert.ToDouble(lumpGradeValue) < 0.0 Then
                                            GeneralHelper.LogValidationError("The Lump Grade Value cannot be less than zero.", "Grade", syncQueueRow,
                                                                             importSyncValidate, importSyncValidateField)
                                        End If

                                        hasLumpGrade = True
                                    End If
                                Case "FinesValue", "GradeFinesValue"
                                    If (Not String.IsNullOrEmpty(childNode.InnerText)) Then


                                        finesGradeValue = Convert.ToSingle(childNode.InnerText)

                                        If Convert.ToDouble(finesGradeValue) < 0.0 Then
                                            GeneralHelper.LogValidationError("The Fines Grade Value cannot be less than zero.", "Grade", syncQueueRow,
                                                                             importSyncValidate, importSyncValidateField)
                                        End If

                                        hasFinesGrade = True
                                    End If
                                Case "GeometType"
                                    geometType = childNode.InnerText
                                    hasGeometType = True
                            End Select
                        Next

                        If Not hasHeadGrade Then
                            errorLogged = True
                            ' The head grade was missing for this grade.. if a grade row was provided at all... then head grade should have been provided
                            GeneralHelper.LogValidationError(String.Format("An expected Head Grade Value is missing ({0} {1}).", IIf(hasGeometType, geometType, "Unknown Geomet Type"), currentGrade), "Grade", syncQueueRow, importSyncValidate,
                                                             importSyncValidateField)
                        End If



                        ' now we need to make sure that if we have a lump or fines grade value, that we have both. We will not try fill in
                        ' missing values. Raise a validation error if such a case occurs
                        If hasFinesGrade <> hasLumpGrade AndAlso (hasFinesGrade Or hasLumpGrade) Then
                            errorLogged = True
                            GeneralHelper.LogValidationError("Both a Lump Grade Value and Fines Grade Value are required", "Grade", syncQueueRow,
                                                             importSyncValidate, importSyncValidateField)
                        ElseIf (hasFinesGrade And hasLumpGrade) Then
                            ' Use this variable to simplify other checks
                            hasLumpAndFineValue = True
                        End If

                        If (Not errorLogged) Then
                            'Only perform these checks if no errors previously logged
                            If (hasLumpAndFineValue) Then
                                If (geometType = CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED And Not hasLumpFinesPercentAsShipped) Or
                                   (geometType = CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED And Not hasLumpFinesPercentAsDropped) Then
                                    GeneralHelper.LogValidationError(
                                                        String.Format("Lump and fines block grades cannot be provided without a corresponding block Lump Percent value ({0} {1}).", geometType, currentGrade), "Grade",
                                                        syncQueueRow, importSyncValidate, importSyncValidateField)
                                End If
                            Else

                                ' NEED TO CLARIFY IF IT IS VALID TO HAVE A GRADE IN THE GRADE LIST THAT DOESN'T HAVE LUMP/FINES WHEN 
                                ' THERE IS AN AS OR AD LUMP %. E.G. H20???
                                ' THE EXISTING BUSINESS RULE NEVER WORKED, AND THIS WAS A REIMPLEMENTATION OF IT, BUT PHILL WANTS
                                ' CLARIFICATION FROM BHP BEFORE PUTTING IT IN

                                ' PREVIOUS CODE
                                ''If (hasLumpFinesPercentAsShipped And Not hasLumpFinesPercentAsShipped) Then
                                ''    GeneralHelper.LogValidationError("Lump and Fines Grade values are missing and block Lump Percent is specified.",
                                ''                                     "ModelLumpPercentAsShipped",
                                ''                                     syncQueueRow, importSyncValidate, importSyncValidateField)
                                ''End If

                                ' REPLACEMENT VERSION
                                'check Lump Fines grades supplied with AS and AD Lump Percent field
                                'If (hasLumpFinesPercentAsShipped And geometType = CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED) Or
                                '   (hasLumpFinesPercentAsDropped And geometType = CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED) Then
                                '    GeneralHelper.LogValidationError(String.Format("Lump and Fines Grade values are missing and block Lump Percent is specified ({0} {1}).", geometType, currentGrade),
                                '                                 "ModelLumpPercentAsShipped",
                                '                                 syncQueueRow, importSyncValidate, importSyncValidateField)
                                'End If
                            End If

                        End If
                    Next

                    'check that each grade is present for the Grade Control model
                    If Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper()) Then
                        For Each currentGrade In ReferenceDataCachedHelper.GetGradeList(gradeControlModelMandatoryGradesOnly:=True)
                            If Not gradeNameList.Contains(currentGrade.ToLower) Then
                                GeneralHelper.LogValidationError("Cannot find the grade, '" & currentGrade & "'.", "Grade", syncQueueRow, importSyncValidate,
                                                                 importSyncValidateField)
                            End If
                        Next
                    End If
                End If

                'check the point provided is correct
                If Not sourceRow("Point") Is DBNull.Value Then
                    'supports both compressed & uncompressed point data
                    Dim points As String = Convert.ToString(sourceRow("Point"))
                    If points.StartsWith("<cp>") And points.EndsWith("</cp>") Then
                        points = GeneralHelper.DecompressString(points, "<cp>", "</cp>")
                    End If

                    doc = New XmlDocument()
                    doc.LoadXml(points)

                    Dim pointsList = doc.GetElementsByTagName("Number")

                    If pointsList.Count > MAXIMUM_ALLOWED_POINTS Then
                        Dim pointsValidationMessage = String.Format("A Block can only have a maximum of {0} points", MAXIMUM_ALLOWED_POINTS)
                        GeneralHelper.LogValidationError(pointsValidationMessage, "Point", syncQueueRow, importSyncValidate, importSyncValidateField)
                    Else
                        For Each node In pointsList
                            If Convert.ToInt32(node.InnerText) < 0 Then
                                GeneralHelper.LogValidationError("The point's sequence number greater than zero.", "Point", syncQueueRow, importSyncValidate,
                                                                 importSyncValidateField)
                            ElseIf Math.Abs(Convert.ToDouble(node.InnerText) - Math.Floor(Convert.ToDouble(node.InnerText))) > Double.Epsilon Then
                                GeneralHelper.LogValidationError("The point's sequence number must be a whole number.", "Point", syncQueueRow,
                                                                 importSyncValidate, importSyncValidateField)
                            End If
                        Next
                    End If
                End If

                'check resource classification
                If Not sourceRow("ResourceClassification") Is DBNull.Value Then
                    doc = New XmlDocument()
                    doc.LoadXml(Convert.ToString(sourceRow("ResourceClassification")))

                    Dim totalPercent = 0.0

                    For Each node In doc.GetElementsByTagName("row")
                        Dim resourceClassification = node("ResourceClassification").InnerText
                        Dim resourceClassificationPct = Convert.ToDouble(node("Percentage").InnerText)

                        If _resourceClassificationColumnNames.Contains(resourceClassification) Then
                            If resourceClassificationPct < 0 Then
                                GeneralHelper.LogValidationError("Resource classification values cannot be less than zero", "ResourceClassification",
                                                                 syncQueueRow, importSyncValidate, importSyncValidateField)
                            End If

                            totalPercent = totalPercent + resourceClassificationPct
                        Else
                            ' field name has to be in the list above
                            GeneralHelper.LogValidationError("Invalid Resource Classification Category", "ResourceClassification", syncQueueRow,
                                                             importSyncValidate, importSyncValidateField)
                        End If
                    Next

                    ' the resource classification fields have to add to 100 %
                    If Math.Abs(totalPercent - MAXIMUM_ALLOWED_RESOURCE_CLASS) > 0.005 Then
                        GeneralHelper.LogValidationError("The Resource Classification records must total 100 %", "ResourceClassification", syncQueueRow,
                                                         importSyncValidate, importSyncValidateField)
                    End If
                End If

                'Additional validation checks
                ' For new records check GUID id is unique
                ' For existing records where the GUID is changing, check that the new GUID is unique
                digblock = Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper())
                If digblock Then
                    Dim blockExternalSystemIdUniqueCheck = False
                    'get the GUID value
                    Dim blockExternalId As String = Convert.ToString(sourceRow("BlockExternalSystemId"))

                    If syncAction = SyncImportSyncActionEnumeration.Insert Then
                        ' always check on insert
                        blockExternalSystemIdUniqueCheck = True
                    Else
                        ' FOR UPDATES
                        ' only check if the new value differs from existing
                        ' check that, if the external id differs from the existing one... it does not exist on any other block...
                        Dim existingBlockExternalSystemId As String = _bhpbioDigblockDal.GetBhpbioDigblockFieldNotes(blockCode, "BlockExternalSystemId")

                        'If existing external system id is  null or empty
                        If (existingBlockExternalSystemId = NullValues.String Or String.IsNullOrEmpty(existingBlockExternalSystemId)) Then
                            ' then check
                            blockExternalSystemIdUniqueCheck = True
                        ElseIf (Not String.IsNullOrEmpty(blockExternalId)) AndAlso (Not (blockExternalId.ToUpper().Equals(existingBlockExternalSystemId.ToUpper()))) Then
                            ' if the values differ, then check the new value is unique
                            blockExternalSystemIdUniqueCheck = True
                        End If
                    End If

                    'Check that the GUID Id (BlockExternalSystemId) does not already exist.
                    If blockExternalSystemIdUniqueCheck AndAlso Not (blockExternalId = NullValues.String Or String.IsNullOrEmpty(blockExternalId)) AndAlso
                        _bhpbioDigblockDal.DoesBhpbioDigblockNotesExist("BlockExternalSystemId", blockExternalId) Then

                        GeneralHelper.LogValidationError("The Block External System Id already exists.", "BlockExternalSystemId", syncQueueRow,
                                                         importSyncValidate, importSyncValidateField)
                    End If
                End If
            End If

            If syncAction = SyncImportSyncActionEnumeration.Delete Then
                digblock = Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper())
                If digblock Then
                    'check to see if the column exists in the destination
                    If Not destinationRow.Table.Columns.Contains("DigblockId") Then
                        Throw New InvalidOperationException("Cannot find the DigblockId field in the destination row however this is a Grade Control block.")
                    End If

                    Dim digblockId As String = Convert.ToString(destinationRow("DigblockId"))

                    'check for haulage attached to this block
                    If _bhpbioDigblockDal.DoesBhpbioDigblockHaulageExist(digblockId) Then
                        GeneralHelper.LogValidationError("There are haulage records associated with this block.", "DigblockId", syncQueueRow, importSyncValidate,
                                                         importSyncValidateField)
                    End If

                    If _bhpbioDigblockDal.DoesBhpbioDigblockAssociationsExist(digblockId) Then
                        GeneralHelper.LogValidationError("There are approval or reconciliation movement records associated with this block.", "DigblockId",
                                                         syncQueueRow, importSyncValidate, importSyncValidateField)
                    End If
                End If
            End If
        End If
    End Sub

    Protected Overrides Sub ProcessConflict(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow, importSyncConflict As DataTable,
                                            importSyncConflictField As DataTable, syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow,
                                            syncQueueChangedFields As DataTable, importSyncDal As ImportSync)
        ShareDalObjectTransactions()
    End Sub

    Protected Overrides Sub ProcessDelete(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow,
                                          syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow, syncQueueChangedFields As DataTable,
                                          importSyncDal As ImportSync)

        Dim digblockId As String
        Dim modelBlockId As Int32
        Dim sequenceNo As Int32
        Dim modelBlockLocation As DataTable
        Dim locationTypeName As String
        Dim isError As Boolean
        Dim errorMessage As String
        Dim locationId As Int32
        Dim modelBlockLocationRows() As DataRow
        Dim isDigblock As Boolean

        ShareDalObjectTransactions()

        'only if its grade control
        If (Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper())) Then
            digblockId = Convert.ToString(destinationRow("DigblockId"))
            isDigblock = True
        Else
            digblockId = Nothing
        End If

        If isDigblock Then
            _bhpbioDigblockDal.DeleteBhpbioDataExceptionDigblockHasHaulage(digblockId)
        End If

        modelBlockId = Convert.ToInt32(Convert.ToString(destinationRow("ModelBlockId")))
        sequenceNo = Convert.ToInt32(Convert.ToString(destinationRow("SequenceNo")))

        'retrieve the recorded location information
        modelBlockLocation = BlockModelDal.GetModelBlockLocation(modelBlockId)

        'remove any associated lump/fines data
        _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED, sequenceNo, NullValues.Decimal)
        _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED, sequenceNo, NullValues.Decimal)

        'delete the model block partial record
        BlockModelDal.DeleteModelBlockPartial(modelBlockId, sequenceNo)

        'check if the model block record is now orphaned
        If BlockModelDal.GetModelBlockPartialList(modelBlockId, NullValues.Int32).Rows.Count = 0 Then
            'delete the model block
            _bhpbioImportDal.DeleteBhpbioModelBlockLumpFinesInformation(modelBlockId)
            BlockModelDal.DeleteModelBlockLocation(modelBlockId)
            BlockModelDal.DeleteModelBlock(modelBlockId)
        End If

        'delete the digblock location links
        If Not digblockId Is Nothing Then
            _digblockDal.DeleteDigblockLocation(digblockId)
            _digblockDal.DeleteDigblock(digblockId)
        End If

        'try to delete location records that may now be orphaned
        errorMessage = Nothing

        'try to delete block, blast, bench and pit - in that order
        For Each locationTypeName In New String() {"Block", "Blast", "Bench", "Pit"}
            modelBlockLocationRows = modelBlockLocation.Select("LocationTypeDescription = '" & locationTypeName & "'")
            If modelBlockLocationRows.Length > 0 Then
                locationId = Convert.ToInt32(modelBlockLocationRows(0)("LocationId"))

                _bhpbioUtilityDal.TryDeleteLocation(locationId, NullValues.String, NullValues.Int16,
                 NullValues.String, isError, errorMessage)
            End If
        Next
    End Sub

    Protected Overrides Sub ProcessInsert(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow,
        syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow, syncQueueChangedFields As DataTable,
        importSyncDal As ImportSync)

        ShareDalObjectTransactions()

        Dim blockCode As String
        Dim materialTypeId As Int32?

        Dim modelBlocks As DataTable
        Dim blockModelId As Int32?
        Dim modelBlockId As Int32
        Dim sequenceNo As Int32

        Dim siteLocationId As Int32
        Dim blockLocationId As Int32

        Dim spatialX As Double
        Dim spatialY As Double
        Dim spatialZ As Double

        Dim addToDigblock As Boolean
        Dim hasLumpFinesAsShipped As Boolean
        Dim hasLumpFinesAsDropped As Boolean

        Dim stratNum As String = Nothing

        'find/insert the location hierarchy
        ProcessInsertLocation(Convert.ToString(sourceRow("Site")),
         Convert.ToString(sourceRow("Pit")), Convert.ToString(sourceRow("Bench")),
         Convert.ToString(sourceRow("PatternNumber")), Convert.ToString(sourceRow("BlockName")),
         siteLocationId, blockLocationId)

        'decode the material type id based on the material types
        'firstly try by hub.  if that fails then try by site.
        materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(MATERIAL_CATEGORY_ID,
         Convert.ToString(sourceRow("ModelOreType")),
         LocationDataUncachedHelper.GetParentLocationId(siteLocationId).Value)

        If Not materialTypeId.HasValue Then
            materialTypeId = ReferenceDataCachedHelper.GetMaterialTypeId(MATERIAL_CATEGORY_ID,
             Convert.ToString(sourceRow("ModelOreType")), siteLocationId)
        End If

        'add the digblock
        If sourceRow("CentroidEasting") Is DBNull.Value Then
            spatialX = NullValues.Double
        Else
            spatialX = Convert.ToDouble(sourceRow("CentroidEasting"))
        End If

        If sourceRow("CentroidNorthing") Is DBNull.Value Then
            spatialY = NullValues.Double
        Else
            spatialY = Convert.ToDouble(sourceRow("CentroidNorthing"))
        End If

        If sourceRow("CentroidRL") Is DBNull.Value Then
            spatialZ = NullValues.Double
        Else
            spatialZ = Convert.ToDouble(sourceRow("CentroidRL"))
        End If

        blockCode = CodeTranslationHelper.GenerateBlockCode(Convert.ToString(sourceRow("BlockName")),
         Convert.ToString(sourceRow("Pit")), Convert.ToString(sourceRow("Bench")),
         Convert.ToString(sourceRow("PatternNumber")))

        addToDigblock = (Convert.ToString(sourceRow("ModelName")).ToUpper() = GRADE_CONTROL_MODEL_NAME.ToUpper())

        If addToDigblock Then
            _digblockDal.AddDigblock(blockCode, materialTypeId.Value,
             Convert.ToDouble(sourceRow("ModelTonnes")), NullValues.String, Now(), NullValues.DateTime, NullValues.String,
             Convert.ToInt16(False), Convert.ToInt16(True), spatialX, spatialY, spatialZ,
             NullValues.String, Convert.ToInt16(True), Convert.ToInt16(False), Convert.ToInt16(False),
             NullValues.DateTime, Nothing)

            _digblockDal.AddOrUpdateDigblockNotes(blockCode, Convert.ToString(sourceRow("BlockExternalSystemId")), "BlockExternalSystemId", NullValues.Int32)


            'associate with the location
            _digblockDal.AddOrUpdateDigblockLocation(blockCode,
             Convert.ToInt16(ReferenceDataCachedHelper.GetLocationTypeId("Block", Nothing)), blockLocationId)
        End If

        'add the model block
        blockModelId = ReferenceDataCachedHelper.GetBlockModelId(Convert.ToString(sourceRow("ModelName")))

        'locate or create a model block
        modelBlocks = BlockModelDal.GetModelBlockList(blockModelId.Value, NullValues.Int32, blockCode)
        If modelBlocks.Rows.Count = 0 Then
            modelBlockId = BlockModelDal.AddModelBlock(blockModelId.Value, blockCode,
             spatialX, spatialY, spatialZ, NullValues.Single, NullValues.Single, NullValues.Single)

            BlockModelDal.AddOrUpdateModelBlockLocation(modelBlockId, ReferenceDataCachedHelper.GetLocationTypeId("Block", Nothing).Value, blockLocationId)
        Else
            modelBlockId = Convert.ToInt32(modelBlocks.Rows(0)("Model_Block_Id"))
        End If

        'create a new model block sequence
        sequenceNo = BlockModelDal.AddModelBlockPartial(modelBlockId, materialTypeId.Value, Convert.ToDouble(sourceRow("ModelTonnes")), NullValues.Int32)

        '(add grades)
        hasLumpFinesAsShipped = (Not sourceRow("ModelLumpPercentAsShipped") Is DBNull.Value)
        hasLumpFinesAsDropped = (Not sourceRow("ModelLumpPercentAsDropped") Is DBNull.Value)

        ProcessInsertUpdateGrade(blockCode, modelBlockId, sequenceNo, addToDigblock,
         Convert.ToString(sourceRow("Grade")), hasLumpFinesAsShipped OrElse hasLumpFinesAsDropped)

        '(add points - but only for digblock as there is no model block spatial component within rec)
        If addToDigblock AndAlso Not (sourceRow("Point") Is DBNull.Value) Then
            ProcessInsertUpdatePoint(blockCode, Convert.ToString(sourceRow("Point")))
        End If

        'Add Resource Classification
        If Not sourceRow("ResourceClassification") Is DBNull.Value Then
            ProcessInsertUpdateResourceClassification(modelBlockId, sequenceNo, Convert.ToString(sourceRow("ResourceClassification")))
        End If

        'add notes, values
        'fields to store: BlockId, GeoType, BlockedDate, BlastedDate, LastModifiedUser, LastModifiedDate, ModelFilename

        BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
         "BlockNumber", Convert.ToString(sourceRow("BlockNumber")), NullValues.Int32)
        If sourceRow("GeoType") Is DBNull.Value Then
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
              "GeoType", NullValues.String, NullValues.Int32)
        Else
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
              "GeoType", Convert.ToString(sourceRow("GeoType")), NullValues.Int32)
        End If
        BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
         "BlockedDate", Convert.ToDateTime(sourceRow("BlockedDate")).ToString("O"), NullValues.Int32)
        If sourceRow("BlastedDate") Is DBNull.Value Then
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
             "BlastedDate", NullValues.String, NullValues.Int32)
        Else
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
             "BlastedDate", Convert.ToDateTime(sourceRow("BlastedDate")).ToString("O"), NullValues.Int32)
        End If

        BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
         "LastModifiedUser", Convert.ToString(DataHelper.IfDBNull(sourceRow("LastModifiedUser"), NullValues.String)), NullValues.Int32)

        If sourceRow("LastModifiedDate") Is DBNull.Value Then
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
             "LastModifiedDate", NullValues.String, NullValues.Int32)
        Else
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
             "LastModifiedDate", Convert.ToDateTime(DataHelper.IfDBNull(sourceRow("LastModifiedDate"), NullValues.DateTime)).ToString("O"),
             NullValues.Int32)
        End If

        If Not sourceRow("ModelFilename") Is DBNull.Value Then
            BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
              "ModelFilename", Convert.ToString(sourceRow("ModelFilename")), NullValues.Int32)
        End If

        If Not sourceRow("ModelVolume") Is DBNull.Value Then
            BlockModelDal.AddOrUpdateModelBlockPartialValue(modelBlockId, sequenceNo,
                "ModelVolume", Convert.ToDouble(sourceRow("ModelVolume")), NullValues.Int32)
        End If

        If addToDigblock Then
            _digblockDal.AddOrUpdateDigblockNotes(blockCode,
             Convert.ToString(sourceRow("BlockNumber")), "BlockNumber", NullValues.Int32)
            If sourceRow("GeoType") Is DBNull.Value Then
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                 NullValues.String, "GeoType", NullValues.Int32)
            Else
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                 Convert.ToString(sourceRow("GeoType")), "GeoType", NullValues.Int32)
            End If
            _digblockDal.AddOrUpdateDigblockNotes(blockCode,
             Convert.ToDateTime(sourceRow("BlockedDate")).ToString("O"), "BlockedDate", NullValues.Int32)
            If sourceRow("BlastedDate") Is DBNull.Value Then
                _digblockDal.AddOrUpdateDigblockNotes(blockCode, NullValues.String, "BlastedDate", NullValues.Int32)
            Else
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                 Convert.ToDateTime(sourceRow("BlastedDate")).ToString("O"), "BlastedDate", NullValues.Int32)
            End If

            _digblockDal.AddOrUpdateDigblockNotes(blockCode,
             Convert.ToString(DataHelper.IfDBNull(sourceRow("LastModifiedUser"), NullValues.String)), "LastModifiedUser", NullValues.Int32)

            If sourceRow("LastModifiedDate") Is DBNull.Value Then
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                 NullValues.String, "LastModifiedDate", NullValues.Int32)
            Else
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                 Convert.ToDateTime(DataHelper.IfDBNull(sourceRow("LastModifiedDate"), NullValues.DateTime)).ToString("O"),
                 "LastModifiedDate", NullValues.Int32)
            End If

            If Not sourceRow("ModelVolume") Is DBNull.Value Then
                _digblockDal.AddOrUpdateDigblockValue(blockCode,
                    Convert.ToDouble(sourceRow("ModelVolume")), "ModelVolume", NullValues.Int32)
            End If

            If Not sourceRow("StratNum") Is DBNull.Value Then
                _digblockDal.AddOrUpdateDigblockNotes(blockCode,
                    Convert.ToString(sourceRow("StratNum")), "StratNum", NullValues.Int32)
            End If
        End If

        'create the digblock/model block links where available
        ProcessInsertDigblockModelBlock(blockCode)

        'create associated lump/fines data
        If (hasLumpFinesAsShipped) Then
            _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED, sequenceNo, Convert.ToDecimal(sourceRow("ModelLumpPercentAsShipped")) / 100)
        End If

        If (hasLumpFinesAsDropped) Then
            _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED, sequenceNo, Convert.ToDecimal(sourceRow("ModelLumpPercentAsDropped")) / 100)
        End If

        'record DigblockId, ModelBlockId, SequenceNo
        DataHelper.AddTableColumn(destinationRow.Table, "DigblockId", GetType(String), Nothing)
        DataHelper.AddTableColumn(destinationRow.Table, "BlockModelId", GetType(String), Nothing)
        DataHelper.AddTableColumn(destinationRow.Table, "ModelBlockId", GetType(String), Nothing)
        DataHelper.AddTableColumn(destinationRow.Table, "SequenceNo", GetType(String), Nothing)

        'only write the DigblockId if we are a grade control record!
        If addToDigblock Then
            destinationRow("DigblockId") = blockCode
        Else
            destinationRow("DigblockId") = Nothing
        End If

        destinationRow("BlockModelId") = blockModelId.ToString
        destinationRow("ModelBlockId") = modelBlockId.ToString
        destinationRow("SequenceNo") = sequenceNo.ToString
    End Sub

    Protected Overrides Sub ProcessUpdate(dataTableName As String, sourceRow As DataRow, destinationRow As DataRow,
        syncAction As SyncImportSyncActionEnumeration, syncQueueRow As DataRow, syncQueueChangedFields As DataTable, importSyncDal As ImportSync)

        ShareDalObjectTransactions()

        Dim digblockId As String
        Dim blockModelId = Convert.ToInt32(Convert.ToString(destinationRow("BlockModelId")))
        Dim modelBlockId = Convert.ToInt32(Convert.ToString(destinationRow("ModelBlockId")))
        Dim sequenceNo = Convert.ToInt32(Convert.ToString(destinationRow("SequenceNo")))

        'note: as the ModelName is part of the key, this cannot change between versions of the row
        Dim digblock = Convert.ToString(sourceRow("ModelName")).ToUpper().Equals(GRADE_CONTROL_MODEL_NAME.ToUpper())
        If digblock Then
            'check to see if the column exists in the destination
            If Not destinationRow.Table.Columns.Contains("DigblockId") Then
                Throw New InvalidOperationException(
                 "Cannot find the DigblockId field in the destination row however this is a Grade Control block.")
            End If
            digblockId = Convert.ToString(destinationRow("DigblockId"))

            ' check if the Block has haulage... if so, raise a data exception (Block changed while haulage exists)
            If _bhpbioDigblockDal.DoesBhpbioDigblockHaulageExist(digblockId) And HasSignificantDataChanged(syncQueueChangedFields) Then
                _bhpbioDigblockDal.AddOrActivateBhpbioDataExceptionDigblockHasHaulage(digblockId)
            End If
        Else
            digblockId = Nothing
        End If

        'the following fields can change: BlockNumber, GeoType, BlockedDate, BlastedDate,
        'CentroidEasting, CentroidNorthing, CentroidRL, ModelTonnes,
        'LastModifiedUser, LastModifiedDate, Point, Grade, StratNum

        ProcessChangedFieldNotes("BlockNumber", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("GeoType", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("BlockedDate", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("BlastedDate", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("LastModifiedUser", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("LastModifiedDate", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("ModelFilename", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("BlockExternalSystemId", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)
        ProcessChangedFieldNotes("StratNum", syncQueueChangedFields, modelBlockId, sequenceNo, sourceRow, digblock, digblockId)

        If syncQueueChangedFields.Select("ChangedField = 'ModelVolume'").Length > 0 Then
            If Not sourceRow("ModelVolume") Is DBNull.Value Then
                BlockModelDal.AddOrUpdateModelBlockPartialValue(modelBlockId, sequenceNo,
                  "ModelVolume", Convert.ToDouble(sourceRow("ModelVolume")), NullValues.Int32)

                If digblock Then
                    _digblockDal.AddOrUpdateDigblockValue(digblockId,
                        Convert.ToDouble(sourceRow("ModelVolume")), "ModelVolume", NullValues.Int32)
                End If
            End If
        End If

        If syncQueueChangedFields.Select("ChangedField = 'Point'").Length > 0 And digblock Then
            _digblockDal.DeleteDigblockPolygon(digblockId)
            If Not sourceRow("Point") Is DBNull.Value Then
                ProcessInsertUpdatePoint(digblockId, Convert.ToString(sourceRow("Point")))
            End If
        End If

        Dim hasLumpFinesAsShipped = (Not sourceRow("ModelLumpPercentAsShipped") Is DBNull.Value)
        Dim hasLumpFinesAsDropped = (Not sourceRow("ModelLumpPercentAsDropped") Is DBNull.Value)
        If syncQueueChangedFields.Select("ChangedField = 'Grade'").Length > 0 Then
            ProcessInsertUpdateGrade(digblockId, modelBlockId, sequenceNo, digblock, sourceRow("Grade").ToString(), hasLumpFinesAsShipped OrElse hasLumpFinesAsDropped)
        End If

        If syncQueueChangedFields.Select("ChangedField = 'ResourceClassification'").Length > 0 Then
            ProcessInsertUpdateResourceClassification(modelBlockId, sequenceNo, sourceRow("ResourceClassification").ToString())
        End If

        If syncQueueChangedFields.Select("ChangedField = 'CentroidEasting'" &
                                         " OR ChangedField = 'CentroidNorthing'" &
                                         " OR ChangedField = 'CentroidRL'" &
                                         " OR ChangedField = 'ModelTonnes'" &
                                         " OR ChangedField = 'ModelOreType'").Length > 0 Then

            Dim spatialX As Double
            Dim spatialY As Double
            Dim spatialZ As Double

            'determine the centroid spatial elements
            If sourceRow("CentroidEasting") Is DBNull.Value Then
                spatialX = NullValues.Double
            Else
                spatialX = Convert.ToDouble(sourceRow("CentroidEasting"))
            End If

            If sourceRow("CentroidNorthing") Is DBNull.Value Then
                spatialY = NullValues.Double
            Else
                spatialY = Convert.ToDouble(sourceRow("CentroidNorthing"))
            End If

            If sourceRow("CentroidRL") Is DBNull.Value Then
                spatialZ = NullValues.Double
            Else
                spatialZ = Convert.ToDouble(sourceRow("CentroidRL"))
            End If

            'update the model block / digblock
            BlockModelDal.UpdateModelBlock(modelBlockId, blockModelId, NullValues.String,
             spatialX, spatialY, spatialZ, NullValues.Single, NullValues.Single, NullValues.Single,
             Convert.ToInt16(True), Convert.ToInt16(False), Convert.ToInt16(True), Convert.ToInt16(True),
             Convert.ToInt16(True), Convert.ToInt16(False), Convert.ToInt16(False), Convert.ToInt16(False))

            BlockModelDal.UpdateModelBlockPartial(modelBlockId, sequenceNo,
             Convert.ToDouble(sourceRow("ModelTonnes")), Convert.ToInt16(False), NullValues.Int32)

            If digblock Then
                _digblockDal.UpdateDigblock(digblockId, NullValues.String, NullValues.Int32, NullValues.DateTime,
                 NullValues.Char, NullValues.DateTime, NullValues.Char, Convert.ToInt16(False),
                 Convert.ToDouble(sourceRow("ModelTonnes")), spatialX, spatialY, spatialZ, NullValues.String,
                 Convert.ToInt16(True), Convert.ToInt16(False), Convert.ToInt16(False), Convert.ToInt16(False),
                 Convert.ToInt16(False), Convert.ToInt16(False), Convert.ToInt16(False), Convert.ToInt16(False),
                 Convert.ToInt16(True), Convert.ToInt16(True), Convert.ToInt16(True), Convert.ToInt16(True),
                 Convert.ToInt16(False), Convert.ToInt16(False))
            End If
        End If

        ProcessChangedFieldLumpPercent("ModelLumpPercentAsShipped", syncQueueChangedFields, hasLumpFinesAsShipped, modelBlockId,
            CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED, sequenceNo, sourceRow)
        ProcessChangedFieldLumpPercent("ModelLumpPercentAsDropped", syncQueueChangedFields, hasLumpFinesAsDropped, modelBlockId,
            CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED, sequenceNo, sourceRow)
    End Sub

    Private Shared Function HasSignificantDataChanged(syncQueueChangedFields As DataTable) As Boolean
        Dim significantDataHasChanged = False

        If syncQueueChangedFields.Select("ChangedField = 'ModelTonnes'").Length > 0 Then
            significantDataHasChanged = True
        End If

        If syncQueueChangedFields.Select("ChangedField = 'ModelVolume'").Length > 0 Then
            significantDataHasChanged = True
        End If

        If syncQueueChangedFields.Select("ChangedField = 'Grade'").Length > 0 Then
            significantDataHasChanged = True
        End If

        ' This won't get triggered until ore-type changes are handled as updates instead of a delete/insert.
        If syncQueueChangedFields.Select("ChangedField = 'ModelOreType'").Length > 0 Then
            significantDataHasChanged = True
        End If

        Return significantDataHasChanged
    End Function

    Private Sub ProcessChangedFieldNotes(changedField As String, syncQueueChangedFields As DataTable, modelBlockId As Integer, sequenceNo As Integer,
        sourceRow As DataRow, digblock As Boolean, digblockId As String)

        If syncQueueChangedFields.Select("ChangedField = '" & changedField & "'").Length > 0 Then
            If Not changedField.Equals("BlockExternalSystemId") Then
                If sourceRow(changedField) Is DBNull.Value And Not (changedField.Equals("ModelFilename") Or changedField.Equals("ModelVolume") Or changedField.Equals("StratNum")) Then
                    BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
                        changedField, NullValues.String, NullValues.Int32)
                ElseIf changedField.Equals("BlockedDate") Or changedField.Equals("BlastedDate") Or changedField.Equals("LastModifiedDate") Then
                    BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
                        changedField, Convert.ToDateTime(sourceRow(changedField)).ToString("O"), NullValues.Int32)
                ElseIf (Not changedField.Equals("StratNum")) Then
                    BlockModelDal.AddOrUpdateModelBlockPartialNotes(modelBlockId, sequenceNo,
                        changedField, Convert.ToString(sourceRow(changedField)), NullValues.Int32)
                End If
            End If

            If digblock And Not changedField.Equals("ModelFilename") Then
                If sourceRow(changedField) Is DBNull.Value And Not (changedField.Equals("ModelVolume") Or changedField.Equals("BlockExternalSystemId")) Then
                    _digblockDal.AddOrUpdateDigblockNotes(digblockId,
                        NullValues.String, changedField, NullValues.Int32)
                ElseIf changedField.Equals("BlockedDate") Or changedField.Equals("BlastedDate") Or changedField.Equals("LastModifiedDate") Then
                    _digblockDal.AddOrUpdateDigblockNotes(digblockId,
                        Convert.ToDateTime(sourceRow(changedField)).ToString("O"), changedField, NullValues.Int32)
                Else
                    _digblockDal.AddOrUpdateDigblockNotes(digblockId,
                        Convert.ToString(sourceRow(changedField)), changedField, NullValues.Int32)
                End If
            End If
        End If
    End Sub

    Private Sub ProcessChangedFieldLumpPercent(changedField As String, syncQueueChangedFields As DataTable, hasLumpFines As Boolean, modelBlockId As Integer,
        geometType As String, sequenceNo As Integer, sourceRow As DataRow)

        If syncQueueChangedFields.Select("ChangedField = '" & changedField & "'").Length > 0 Then
            If (hasLumpFines) Then
                _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, geometType, sequenceNo, Convert.ToDecimal(sourceRow(changedField)) / 100)
            Else
                _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId, geometType, sequenceNo, NullValues.Decimal)
            End If
        End If
    End Sub

    Private Sub ShareDalObjectTransactions()
        ImportSyncDal.DataAccess.ShareTransaction(BlockModelDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_bhpbioUtilityDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_digblockDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_bhpbioImportDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_approvalDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_bhpbioDigblockDal.DataAccess)
        ImportSyncDal.DataAccess.ShareTransaction(_bhpbioImportManagerDal.DataAccess)
    End Sub

    Protected Overrides Sub SetupDataAccessObjects()
        MyBase.SetupDataAccessObjects()

        _bhpbioUtilityDal = New Database.SqlDal.SqlDalUtility()
        _bhpbioUtilityDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _digblockDal = New Core.Database.SqlDal.SqlDalDigblock()
        _digblockDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _bhpbioImportDal = New SqlDalBhpbioBlock()
        _bhpbioImportDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _approvalDal = New SqlDalApproval()
        _approvalDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _haulageDal = New Core.Database.SqlDal.SqlDalHaulage()
        _haulageDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _bhpbioDigblockDal = New Database.SqlDal.SqlDalDigblock()
        _bhpbioDigblockDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection

        _bhpbioImportManagerDal = New SqlDalImportManager()
        _bhpbioImportManagerDal.DataAccess.DataAccessConnection = ImportSyncDal.DataAccess.DataAccessConnection


        ReferenceDataCachedHelper.BlockModelDal = BlockModelDal
        ReferenceDataCachedHelper.UtilityDal = _bhpbioUtilityDal
        LocationDataUncachedHelper.UtilityDal = _bhpbioUtilityDal
    End Sub

    Protected Overrides Sub PostProcess(importSyncDal As ImportSync)
        MyBase.PostProcess(importSyncDal)

        importSyncDal.DataAccess.ShareTransaction(_haulageDal.DataAccess)
        importSyncDal.DataAccess.ShareTransaction(UtilityDal.DataAccess)

        _haulageDal.HaulageRawResolveAll()

        _bhpbioUtilityDal.UpdateBhpbioLocationDate()
        
        If (ImportJobId.HasValue) Then
            _bhpbioUtilityDal.UpdateBhpbioImportSyncRowFilterData(ImportJobId.Value)
        End If
    End Sub

    Private Sub ProcessInsertDigblockModelBlock(digblockId As String)
        Dim modelBlocks As DataTable
        Dim digblockExists As Boolean
        Dim digblockModelBlocks As DataTable
        Dim currentModelBlockId As Int32
        Dim currentRow As DataRow

        'locate a digblock that matches the given model block signature
        digblockExists = _digblockDal.GetDigblockExists(digblockId)

        'only try to link up if a digblock exists
        If digblockExists Then
            'locate any model blocks that match the given digblock signature
            modelBlocks = BlockModelDal.GetModelBlockList(NullValues.Int32, NullValues.Int32, digblockId)

            'find the existing DigblockModelBlock links - based on the expected digblock code
            digblockModelBlocks = _digblockDal.GetDigblockModelBlockList(digblockId, NullValues.Int32)

            'loop through each model block and check if it exists in the existing links - if not then add it
            For Each currentRow In modelBlocks.Rows
                currentModelBlockId = Convert.ToInt32(currentRow("Model_Block_Id"))

                If digblockModelBlocks.Select("ModelBlockId = " & currentModelBlockId.ToString).Length = 0 Then
                    BlockModelDal.AddDigblockModelBlock(currentModelBlockId, digblockId, 1.0, 1.0)
                End If
            Next
        End If
    End Sub

    Private Sub ProcessInsertLocation(inSite As String, inPit As String, inBench As String,
     patternNumber As String, blockName As String, ByRef returnSiteLocationId As Int32,
     ByRef returnBlockLocationId As Int32)
        Dim siteLocationId As Int32
        Dim pitLocationId As Int32?
        Dim benchLocationId As Int32?
        Dim blastLocationId As Int32?
        Dim blockLocationId As Int32?

        'discover the location type
        siteLocationId = GetSiteLocationId(inSite).Value

        'load / add the pit
        pitLocationId = LocationDataUncachedHelper.GetLocationId(inPit, "Pit", siteLocationId)
        If Not pitLocationId.HasValue Then
            pitLocationId = _bhpbioUtilityDal.AddLocation(inPit,
             ReferenceDataCachedHelper.GetLocationTypeId("Pit", Nothing).Value, siteLocationId, inPit)
        End If

        'load / add the bench
        benchLocationId = LocationDataUncachedHelper.GetLocationId(inBench, "Bench", pitLocationId)
        If Not benchLocationId.HasValue Then
            benchLocationId = _bhpbioUtilityDal.AddLocation(inBench,
             ReferenceDataCachedHelper.GetLocationTypeId("Bench", Nothing).Value, pitLocationId.Value, inBench)
        End If

        'load / add the blast
        blastLocationId = LocationDataUncachedHelper.GetLocationId(patternNumber, "Blast", benchLocationId)
        If Not blastLocationId.HasValue Then
            blastLocationId = _bhpbioUtilityDal.AddLocation(patternNumber,
             ReferenceDataCachedHelper.GetLocationTypeId("Blast", Nothing).Value, benchLocationId.Value, patternNumber)
        End If

        'load / add the blast
        blockLocationId = LocationDataUncachedHelper.GetLocationId(blockName, "Block", blastLocationId)
        If Not blockLocationId.HasValue Then
            blockLocationId = _bhpbioUtilityDal.AddLocation(blockName,
             ReferenceDataCachedHelper.GetLocationTypeId("Block", Nothing).Value, blastLocationId.Value, blockName)
        End If

        'return the known resolved locations
        returnSiteLocationId = siteLocationId
        returnBlockLocationId = blockLocationId.Value
    End Sub

    Private Sub ProcessInsertUpdateGrade(digblockId As String, modelBlockId As Int32,
     sequenceNo As Int32, digblock As Boolean, xml As String, hasLumpFines As Boolean)
        Dim doc As XmlDocument
        Dim node As XmlNode
        Dim childNode As XmlNode

        Dim gradeId As Int16
        Dim gradeIdH2OAsShipped As Int16
        Dim gradeIdH2OAsDropped As Int16
        Dim geometType As String
        Dim gradeName As String
        Dim gradeValue As Single
        Dim lumpValue As Single
        Dim finesValue As Single
        ' make a HashSet to keep track of grade names as grades are written to DigblockGrades
        Dim gradeNamesWrittenToDigblock As New HashSet(Of String)

        doc = New XmlDocument()
        doc.LoadXml(xml)
        For Each node In doc.SelectNodes("//Grade/row")

            gradeValue = NullValues.Single
            lumpValue = NullValues.Single
            finesValue = NullValues.Single
            gradeName = Nothing
            geometType = CodeTranslationHelper.GEOMET_TYPE_NA

            For Each childNode In node.ChildNodes
                Select Case childNode.Name
                    Case "GradeName"
                        gradeId = ReferenceDataCachedHelper.GetGradeId(childNode.InnerText).Value
                        gradeName = childNode.InnerText
                    Case "GeometType"
                        geometType = CodeTranslationHelper.ToGeometTypeString(childNode.InnerText)
                    Case "GradeValue"
                        gradeValue = Convert.ToSingle(childNode.InnerText)
                    Case "GradeLumpValue"
                        lumpValue = Convert.ToSingle(childNode.InnerText)
                    Case "GradeFinesValue"
                        finesValue = Convert.ToSingle(childNode.InnerText)
                End Select
            Next

            If gradeName = "H2O" Then
                ' also need the as-shipped and as-dropped grade Ids
                ' this is to insert the special H2O-As-Shipped and H2O-As-Dropped values
                gradeIdH2OAsShipped = ReferenceDataCachedHelper.GetGradeId("H2O-As-Shipped").Value
                gradeIdH2OAsDropped = ReferenceDataCachedHelper.GetGradeId("H2O-As-Dropped").Value
            End If
            ' If the value is a grade such as a density that has tonnes in the numerator rather than the denominator..such as:   tonnes / m3
            ' then we need to take the inverse of the value so that Reconcilor tonnes weighted averages will work correctly
            If (_gradeNamesToInvert.Contains(gradeName)) Then
                If Math.Abs(gradeValue - NullValues.Single) > Single.Epsilon AndAlso gradeValue > 0 Then
                    gradeValue = (1 / gradeValue)
                End If

                'NOTE: Under current design, there are no Lump or Fines Density grade values...  Density currently only applies to Model comparisons only...
                ' however this code is here in case the above assumption is ever changed
                If Math.Abs(lumpValue - NullValues.Single) > Single.Epsilon AndAlso lumpValue > 0 Then
                    lumpValue = (1 / lumpValue)
                End If

                If Math.Abs(finesValue - NullValues.Single) > Single.Epsilon AndAlso finesValue > 0 Then
                    finesValue = (1 / finesValue)
                End If
            End If

            If digblock AndAlso geometType = CodeTranslationHelper.GEOMET_TYPE_NA Then
                Dim digblockGradeValue As Single = gradeValue
                If (Not String.IsNullOrEmpty(gradeName)) AndAlso gradeName.StartsWith("H2O") AndAlso Math.Abs(digblockGradeValue - NullValues.Single) < Single.Epsilon Then
                    ' replace null H2O grade values with 0s only in the context of Digblock Grade insertion
                    digblockGradeValue = 0
                End If
                _digblockDal.AddOrUpdateDigblockGrade(digblockId, gradeId, digblockGradeValue)
                ' keep track of the names of digblock grades written
                gradeNamesWrittenToDigblock.Add(gradeName)
            End If

            BlockModelDal.AddOrUpdateModelBlockPartialGrade(modelBlockId, sequenceNo, gradeId, gradeValue)
            If (hasLumpFines AndAlso Not (geometType = CodeTranslationHelper.GEOMET_TYPE_NA)) Then
                _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpFinesGrade(modelBlockId, geometType, sequenceNo, gradeId, lumpValue, finesValue)
            End If

            If (gradeName = "H2O" AndAlso geometType = CodeTranslationHelper.GEOMET_TYPE_AS_DROPPED) Then
                ' add the special H2O As-Dropped grade
                ' potentially this can be removed if the application no longer requires H2O As-Dropped
                BlockModelDal.AddOrUpdateModelBlockPartialGrade(modelBlockId, sequenceNo, gradeIdH2OAsDropped, gradeValue)
                _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpFinesGrade(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_NA, sequenceNo, gradeIdH2OAsDropped, lumpValue, finesValue)
            End If

            If (gradeName = "H2O" AndAlso geometType = CodeTranslationHelper.GEOMET_TYPE_AS_SHIPPED) Then
                ' add the special H2O As-Shipped grade
                ' potentially this can be removed if the application no longer requires H2O As-Shipped
                BlockModelDal.AddOrUpdateModelBlockPartialGrade(modelBlockId, sequenceNo, gradeIdH2OAsShipped, gradeValue)
                _bhpbioImportDal.AddOrUpdateBhpbioBlastBlockLumpFinesGrade(modelBlockId, CodeTranslationHelper.GEOMET_TYPE_NA, sequenceNo, gradeIdH2OAsShipped, lumpValue, finesValue)
            End If
        Next

        If digblock Then
            ' loop through all grade names that start with H2O
            ' and for any not written, write a 0 value to DigblockGrade.
            ' This is neccessary due to the fact that H2O values are not always set; BUT Recalc requires non-null Digblock Grade values for all grades in order to process a shift
            '   NOTE:  this is to be avoided in ModelBlockPartialGrade (and anywhere else as far as possible)
            For Each gradeNameToCheck As String In ReferenceDataCachedHelper.GetGradeList().Where(Function(n) n.StartsWith("H2O"))
                If Not gradeNamesWrittenToDigblock.Contains(gradeNameToCheck) Then
                    ' write a 0 value where the grade was missing
                    gradeId = ReferenceDataCachedHelper.GetGradeId(gradeNameToCheck).Value
                    _digblockDal.AddOrUpdateDigblockGrade(digblockId, gradeId, 0)
                End If
            Next
        End If

    End Sub

    Private Sub ProcessInsertUpdateResourceClassification(modelBlockId As Integer, sequenceNo As Integer, xml As String)

        Dim addedClassifications As New List(Of String)

        ' if all the RC data was removed for a block, then an empty xml string will get sent through
        ' to update against
        If Not String.IsNullOrEmpty(xml) Then
            Dim doc = New XmlDocument()
            doc.LoadXml(xml)

            For Each node As XmlNode In doc.SelectNodes("//ResourceClassification/row")
                Dim resourceClassification = String.Empty
                Dim percentage = Double.MinValue

                For Each childNode As XmlNode In node.ChildNodes
                    Select Case childNode.Name
                        Case "ResourceClassification"
                            resourceClassification = childNode.InnerText
                        Case "Percentage"
                            percentage = Convert.ToDouble(childNode.InnerText)
                    End Select
                Next

                addedClassifications.Add(resourceClassification)
                BlockModelDal.AddOrUpdateModelBlockPartialValue(modelBlockId, sequenceNo, resourceClassification, percentage, NullValues.Int32)
            Next
        End If

        ' go through the list of resource classification codes, and delete any that were not
        ' in the given xml
        For Each resourceClassification In _resourceClassificationColumnNames
            If Not addedClassifications.Contains(resourceClassification) Then
                BlockModelDal.DeleteModelBlockPartialValue(modelBlockId, sequenceNo, resourceClassification)
            End If
        Next
    End Sub

    Private Sub ProcessInsertUpdatePoint(digblockId As String, xml As String)
        Dim doc As XmlDocument
        Dim node As XmlNode
        Dim childNode As XmlNode
        Dim uncompressedPoints As String

        Dim pointNumber As Int16
        Dim spatialX As Double
        Dim spatialY As Double
        Dim spatialZ As Double

        'supports both compressed & uncompressed point data
        If xml.StartsWith("<cp>") And xml.EndsWith("</cp>") Then
            uncompressedPoints = GeneralHelper.DecompressString(xml, "<cp>", "</cp>")
        Else
            uncompressedPoints = xml
        End If

        doc = New XmlDocument()
        doc.LoadXml(uncompressedPoints)
        For Each node In doc.SelectNodes("//Point/row")
            For Each childNode In node.ChildNodes
                Select Case childNode.Name
                    Case "Number"
                        pointNumber = Convert.ToInt16(childNode.InnerText)
                    Case "Northing"
                        spatialY = Convert.ToDouble(childNode.InnerText)
                    Case "Easting"
                        spatialX = Convert.ToDouble(childNode.InnerText)
                    Case "RL"
                        spatialZ = Convert.ToDouble(childNode.InnerText)
                End Select
            Next

            _digblockDal.AddDigblockPolygon(digblockId, spatialX, spatialY, spatialZ, pointNumber, NullValues.Int32)
        Next
    End Sub

    Private Function GetSiteLocationId(siteName As String) As Int32?
        'sites are known to be unique - so we can centralise this bit of norty logic

        Static locationLoaded As Boolean = False
        Static waioLocationId As Int32
        Static hubLocationIds As Int32()
        Dim hubLocationId As Int32
        Dim siteLocationId As Int32?

        If Not locationLoaded Then
            'resolve WAIO & collect hubs
            waioLocationId = LocationDataUncachedHelper.GetLocationId("WAIO", "Company", Nothing).Value
            hubLocationIds = LocationDataUncachedHelper.GetLocationLookup(waioLocationId, "Hub", "Hub")
            locationLoaded = True
        End If

        'resolve the site based on the known location names
        siteLocationId = Nothing

        ' convert the siteName
        Dim translatedSiteName = CodeTranslationHelper.BlockDataSiteToReconcilor(siteName)
        For Each hubLocationId In hubLocationIds
            siteLocationId = LocationDataUncachedHelper.GetLocationId(translatedSiteName, "Site", hubLocationId)
            If siteLocationId.HasValue Then
                Exit For
            End If
        Next

        Return siteLocationId
    End Function

    Public Sub New()
        ImportName = "Blocks"
        SourceSchemaName = "BlockModel"
    End Sub
End Class

Public Module DalExtensions
    <Extension()>
    Public Sub DeleteModelBlockPartialValue(dal As SqlDalBlockModel, modelBlockId As Integer, sequenceNo As Integer, modelBlockPartialFieldId As String)
        ' this proc will delete the partial value record if it is passed a null value
        ' we add this extension method to make it clear what is happening when we pass in a null value
        dal.AddOrUpdateModelBlockPartialValue(modelBlockId, sequenceNo, modelBlockPartialFieldId, NullValues.Double, NullValues.Int32)
    End Sub
End Module