Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IBhpbioBlock
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Sub AddOrUpdateDigblockPolygon(ByVal digblockId As String, ByVal point As String)

        Sub UpdateBhpbioReconciliationMovement(Optional ByVal pitLocationId As Integer = -1)

        Sub DeleteBhpbioReconciliationMovementStage()

        Sub AddOrUpdateBhpbioBlastBlockLumpPercent(
            ByVal modelBlockId As Int32,
            ByVal geometType As String,
            ByVal sequenceNo As Int32,
            ByVal lumpPercent As Decimal)

        Sub AddOrUpdateBhpbioBlastBlockLumpFinesGrade(
            ByVal modelBlockId As Int32,
            ByVal geometType As String,
            ByVal sequenceNo As Int32,
            ByVal gradeId As Int16,
            ByVal lumpValue As Single,
            ByVal finesValue As Single)

        Sub DeleteBhpbioModelBlockLumpFinesInformation(ByVal modelBlockId As Int32)

        Function GetBhpbioStagingBlockHoldingPitCode(
            ByVal blockName As String,
            ByVal site As String,
            ByVal orebody As String,
            ByVal pit As String,
            ByVal bench As String,
            ByVal patternNumber As String) As String

        Function GetBhpbioStagingModelBlocks(ByVal site As String,
         ByVal pit As String, ByVal bench As String) As DataTable

        Function GetBhpbioStagingBlockId(ByVal blockNumber As String,
            ByVal blockName As String,
            ByVal site As String,
            ByVal orebody As String,
            ByVal pit As String,
            ByVal bench As String,
            ByVal patternNumber As String) As Int32

        Sub AddOrUpdateBhpbioImportLoadRowMessages(ByVal blockNumber As String,
            ByVal blockName As String,
            ByVal site As String,
            ByVal orebody As String,
            ByVal pit As String,
            ByVal bench As String,
            ByVal patternNumber As String,
            ByVal modelName As String)

        Sub DeleteBhpbioImportLoadRowMessages()

        Sub AddUpdateBlockModelResourceClassification(ByVal modelBlockId As Integer, ByVal resourceClassification As String, ByVal percentage As Double)

        ''' <summary>
        ''' Add a grade value to a stage block model
        ''' </summary>
        ''' <param name="modelBlockId">The Id of the model block that should have a grade appended</param>
        ''' <param name="geometType">Identify the source of geomet data for this row</param>
        ''' <param name="analyteName">The name of the analyte/grade</param>
        ''' <param name="romValue">The head value</param>
        ''' <param name="lumpValue">The lump value if any</param>
        ''' <param name="finesValue">The fines value if any</param>
        ''' <remarks>any of the grade values may be null</remarks>
        Sub AddBhpbioStageBlockModelGrade(ByVal modelBlockId As Integer, ByVal geometType As String, ByVal analyteName As String, ByVal romValue As Nullable(Of Double), ByVal lumpValue As Nullable(Of Double), ByVal finesValue As Nullable(Of Double))

        ''' <summary>
        ''' Delete a stage block
        ''' </summary>
        ''' <param name="timestamp">Timestamp of the message containing the delete command</param>
        ''' <param name="blockExternalSystemId">Identifier for the block</param>
        Sub DeleteBhpbioStageBlock(ByVal timestamp As DateTime, ByVal blockExternalSystemId As String)

        ''' <summary>
        ''' Add a stage block point
        ''' </summary>
        ''' <param name="blockId">Internal identifier for the Block</param>
        ''' <param name="x">Easting (x) value</param>
        ''' <param name="y">Northing (y) value</param>
        ''' <param name="z">ToeRL (z) value</param>
        ''' <param name="pointNumber">A number used to order the point</param>
        Sub AddBhpbioStageBlockPoint(ByVal blockId As Integer, ByVal x As Double, ByVal y As Double, ByVal z As Double, ByVal pointNumber As Integer)

        ''' <summary>
        ''' Delete all stage block poiints associated with a Block
        ''' </summary>
        ''' <param name="blockId">the internal identifer of the Block whose points are to be deleted</param>
        Sub DeleteBhpbioStageBlockPoints(ByVal blockId As Integer)

        ''' <summary>
        ''' Add or update a block in the staging area, only if the timestamp provided is the latest seen for the Block
        ''' </summary>
        ''' <param name="timestamp">timestamp associated with the data to be saged</param>
        ''' <param name="blockExternalSystemId">the external identifer of the Block to be added or updated</param>
        ''' <param name="blockNumber">the number of the block</param>
        ''' <param name="blockName">the name of the block</param>
        ''' <param name="lithologyType">the lithologyType (or geoType) of the Block</param>
        ''' <param name="flitchExternalSystemId">Identifies the flitch of the Block</param>
        ''' <param name="patternExternalSystemId">Identifies the pattern of the block</param>
        ''' <param name="dateBlocked">the datetime the block was blocked out</param>
        ''' <param name="centroidX">Easting (x) of the blocks centre</param>
        ''' <param name="centroidY">Northing (y)of the blocks centre</param>
        ''' <param name="centroidZ">ToeRL (z) of the blocks centre</param>
        ''' <param name="blockId">reference parameter set to the internal Id of the Block</param>
        ''' <param name="isLatest">reference parameter set true if this data was the latest for the Block</param>
        ''' <remarks>This procedure call will take no action of the timestamp is not the latest seen for the Block</remarks>
        Sub AddOrUpdateBhpbioStageBlockIfLatest(ByVal timestamp As DateTime,
                                                ByVal blockExternalSystemId As String,
                                                ByVal blockName As String,
                                                ByVal blockNumber As Integer,
                                                ByVal lithologyType As String,
                                                ByVal flitchExternalSystemId As String,
                                                ByVal patternExternalSystemId As String,
                                                ByVal site As String,
                                                ByVal oreBody As String,
                                                ByVal pit As String,
                                                ByVal alternativePitCode As String,
                                                ByVal bench As String,
                                                ByVal patternNumber As String,
                                                ByVal dateBlocked As DateTime,
                                                ByVal centroidX As Double,
                                                ByVal centroidY As Double,
                                                ByVal centroidZ As Double,
                                                ByRef blockId As Nullable(Of Integer),
                                                ByRef isLatest As Boolean)

        ''' <summary>
        ''' Add block model record for a Block
        ''' </summary>
        ''' <param name="modelType">the type of model</param>
        ''' <param name="blockId">the internal identifier for the Block</param>
        ''' <param name="materialCode">material code</param>
        ''' <param name="volume">volume</param>
        ''' <param name="tonnes">tonnes within this model block</param>
        ''' <param name="density">density</param>
        ''' <param name="lastModifiedUserName">the name of the user responsbile for last update</param>
        ''' <param name="lastModifiedDateTime">the date and time of last update</param>
        ''' <param name="modelFileName">the filename associated with this model data</param>
        ''' <param name="lumpPercentAsShipped">the percentage of lump material</param>
        ''' <param name="lumpPercentAsDropped">the percentage of lump material</param>
        ''' <param name="modelBlockId">reference parameter set to the id of the model block record on add</param>
        Sub AddBhpbioStageBlockModel(ByVal modelType As String, ByVal blockId As Integer, ByVal materialCode As String, ByVal volume As Double, ByVal tonnes As Double, ByVal density As Double, ByVal lastModifiedUserName As String, ByVal lastModifiedDateTime As DateTime, ByVal modelFileName As String, ByVal lumpPercentAsShipped As Nullable(Of Decimal), ByVal lumpPercentAsDropped As Nullable(Of Decimal), ByRef modelBlockId As Nullable(Of Integer))

        ''' <summary>
        ''' Delete all model blocks (and associated grades) associated with the specified Block and model type
        ''' </summary>
        ''' <param name="blockId">Intenral Id of the block</param>
        ''' <param name="modelType">the type of the model whose data should be removed</param>
        Sub DeleteBhpbioStageBlockModels(ByVal blockId As Integer, ByVal modelType As String)
    End Interface
End Namespace
