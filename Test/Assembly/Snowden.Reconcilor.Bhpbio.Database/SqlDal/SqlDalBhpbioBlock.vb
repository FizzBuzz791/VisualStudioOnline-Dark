Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.SqlDataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalBhpbioBlock
        Inherits SqlDalBase
        Implements IBhpbioBlock

#Region " Constructors "
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(connectionString As String)
            MyBase.New(connectionString)
        End Sub

        Public Sub New(databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
        End Sub

        Public Sub New(dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        Public Sub AddOrUpdateDigblockPolygon(digblockId As String, point As String) Implements IBhpbioBlock.AddOrUpdateDigblockPolygon
            With DataAccess
                .CommandText = "dbo.AddOrUpdateDigblockPolygon"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iDigblock_ID", CommandDataType.VarChar, CommandDirection.Input, digblockId)
                    .Add("@iDigblockPolygonPoints", CommandDataType.VarChar, CommandDirection.Input, point)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioReconciliationMovementStage() Implements IBhpbioBlock.DeleteBhpbioReconciliationMovementStage
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioReconciliationMovementStage"
                .CommandType = CommandObjectType.StoredProcedure

                .ParameterCollection.Clear()

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub UpdateBhpbioReconciliationMovement(Optional ByVal pitLocationId As Integer = -1) _
            Implements IBhpbioBlock.UpdateBhpbioReconciliationMovement

            With DataAccess
                .CommandText = "dbo.UpdateBhpbioReconciliationMovement"
                .CommandType = CommandObjectType.StoredProcedure

                .ParameterCollection.Clear()

                If pitLocationId <> -1 Then
                    .ParameterCollection.Add("@iPitLocationId", CommandDataType.Int, CommandDirection.Input, pitLocationId)
                End If

                .ExecuteNonQuery()
            End With
        End Sub

        Function GetBhpbioStagingModelBlocks(site As String, pit As String, bench As String) As DataTable _
            Implements IBhpbioBlock.GetBhpbioStagingModelBlocks

            With DataAccess
                .CommandText = "Staging.GetBhpbioStagingModelBlocks"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, site)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, pit)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, bench)
                End With

                Return .ExecuteDataTable()
            End With
        End Function

        Function GetBhpbioStagingBlockId(blockNumber As String, blockName As String, site As String, orebody As String, pit As String, bench As String,
            patternNumber As String) As Int32 Implements IBhpbioBlock.GetBhpbioStagingBlockId

            With DataAccess
                .CommandText = "Staging.GetBhpbioStagingBlockId"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockNumber", CommandDataType.VarChar, CommandDirection.Input, blockNumber)
                    .Add("@iBlockName", CommandDataType.VarChar, CommandDirection.Input, blockName)
                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, site)
                    .Add("@iOrebody", CommandDataType.VarChar, CommandDirection.Input, orebody)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, pit)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, bench)
                    .Add("@iPatternNumber", CommandDataType.VarChar, CommandDirection.Input, patternNumber)
                    .Add("@oBlockId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)
                End With

                .ExecuteNonQuery()

                Dim blockId As Int32
                If .ParameterCollection("@oBlockId").Value Is DBNull.Value Then
                    blockId = NullValues.Int32
                Else
                    blockId = Convert.ToInt32(.ParameterCollection("@oBlockId").Value)
                End If

                Return blockId
            End With
        End Function

        Public Sub AddOrUpdateBhpbioImportLoadRowMessages(blockNumber As String, blockName As String, site As String, orebody As String, pit As String,
            bench As String, patternNumber As String, modelName As String) Implements IBhpbioBlock.AddOrUpdateBhpbioImportLoadRowMessages

            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioImportLoadRowMessages"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockNumber", CommandDataType.VarChar, CommandDirection.Input, blockNumber)
                    .Add("@iBlockName", CommandDataType.VarChar, CommandDirection.Input, blockName)
                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, site)
                    .Add("@iOrebody", CommandDataType.VarChar, CommandDirection.Input, orebody)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, pit)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, bench)
                    .Add("@iPatternNumber", CommandDataType.VarChar, CommandDirection.Input, patternNumber)
                    .Add("@iModelName", CommandDataType.VarChar, CommandDirection.Input, modelName)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioImportLoadRowMessages() Implements IBhpbioBlock.DeleteBhpbioImportLoadRowMessages
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioImportLoadRowMessages"
                .CommandType = CommandObjectType.StoredProcedure

                .ParameterCollection.Clear()

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioModelBlockLumpFinesInformation(modelBlockId As Integer) Implements IBhpbioBlock.DeleteBhpbioModelBlockLumpFinesInformation
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioModelBlockLumpFinesInformation"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iModelBlockId", CommandDataType.Int, CommandDirection.Input, modelBlockId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub AddOrUpdateBhpbioBlastBlockLumpPercent(modelBlockId As Int32, geometType As String, sequenceNo As Int32, lumpPercent As Decimal) _
            Implements IBhpbioBlock.AddOrUpdateBhpbioBlastBlockLumpPercent

            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioBlastBlockLumpPercent"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iModelBlockId", CommandDataType.Int, CommandDirection.Input, modelBlockId)
                    .Add("@iGeometType", CommandDataType.VarChar, CommandDirection.Input, geometType)
                    .Add("@iSequenceNo", CommandDataType.Int, CommandDirection.Input, sequenceNo)
                    .Add("@iLumpPercent", CommandDataType.Decimal, CommandDirection.Input, lumpPercent)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Sub AddOrUpdateBhpbioBlastBlockLumpFinesGrade(modelBlockId As Int32, geometType As String, sequenceNo As Int32, gradeId As Int16, lumpValue As Single,
            finesValue As Single) Implements IBhpbioBlock.AddOrUpdateBhpbioBlastBlockLumpFinesGrade

            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioBlastBlockLumpFinesGrade"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iModelBlockId", CommandDataType.Int, CommandDirection.Input, 14, modelBlockId)
                    .Add("@iGeometType", CommandDataType.VarChar, CommandDirection.Input, geometType)
                    .Add("@iSequenceNo", CommandDataType.Int, CommandDirection.Input, 14, sequenceNo)
                    .Add("@iGradeId", CommandDataType.Int, CommandDirection.Input, gradeId)
                    .Add("@iLumpValue", CommandDataType.Real, CommandDirection.Input, lumpValue)
                    .Add("@iFinesValue", CommandDataType.Real, CommandDirection.Input, finesValue)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioStagingBlockHoldingPitCode(blockName As String, site As String, orebody As String, pit As String, bench As String,
            patternNumber As String) As String Implements IBhpbioBlock.GetBhpbioStagingBlockHoldingPitCode

            With DataAccess
                .CommandText = "Staging.GetBhpbioStagingBlockHoldingPitCode"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockName", CommandDataType.VarChar, CommandDirection.Input, 14, blockName)
                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, 9, site)
                    .Add("@iOrebody", CommandDataType.VarChar, CommandDirection.Input, 2, orebody)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, 3, pit)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, 4, bench)
                    .Add("@iPatternNumber", CommandDataType.VarChar, CommandDirection.Input, 4, patternNumber)
                End With

                Dim result As Object = .ExecuteScalar2()
                If result Is DBNull.Value Then
                    Return Nothing
                Else
                    Return DirectCast(result, String)
                End If
            End With
        End Function

        ''' <summary>
        ''' Add a grade value to a stage block model
        ''' </summary>
        ''' <param name="modelBlockId">The Id of the model block that should have a grade appended</param>
        ''' <param name="geometType">The name of the geomet type</param>
        ''' <param name="gradeName">The name of the analyte/grade</param>
        ''' <param name="romValue">The head value</param>
        ''' <param name="lumpValue">The lump value if any</param>
        ''' <param name="finesValue">The fines value if any</param>
        ''' <remarks>any of the grade values may be null</remarks>
        Public Sub AddBhpbioStageBlockModelGrade(modelBlockId As Integer, geometType As String, gradeName As String, romValue As Nullable(Of Double),
            lumpValue As Nullable(Of Double), finesValue As Nullable(Of Double)) Implements IBhpbioBlock.AddBhpbioStageBlockModelGrade

            With DataAccess
                .CommandText = "Staging.AddBhpbioStageBlockModelGrade"
                .CommandType = CommandObjectType.StoredProcedure

                If (Not romValue.HasValue) Then
                    romValue = NullValues.Double
                End If
                If (Not finesValue.HasValue) Then
                    finesValue = NullValues.Double
                End If
                If (Not lumpValue.HasValue) Then
                    lumpValue = NullValues.Double
                End If

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockModelId", CommandDataType.Int, CommandDirection.Input, modelBlockId)
                    .Add("@iGeometType", CommandDataType.VarChar, CommandDirection.Input, 15, geometType)
                    .Add("@iGradeName", CommandDataType.VarChar, CommandDirection.Input, 31, gradeName)
                    .Add("@iHeadValue", CommandDataType.Float, CommandDirection.Input, romValue.Value)
                    .Add("@iLumpValue", CommandDataType.Float, CommandDirection.Input, lumpValue.Value)
                    .Add("@iFinesValue", CommandDataType.Float, CommandDirection.Input, finesValue.Value)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub AddUpdateBlockModelResourceClassification(modelBlockId As Integer, resourceClassification As String, percentage As Double) _
            Implements IBhpbioBlock.AddUpdateBlockModelResourceClassification

            With DataAccess
                .CommandText = "Staging.AddUpdateBlockModelResourceClassification"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockModelId", CommandDataType.Int, CommandDirection.Input, modelBlockId)
                    .Add("@iResourceClassification", CommandDataType.VarChar, CommandDirection.Input, 31, resourceClassification)
                    .Add("@iPercentage", CommandDataType.Float, CommandDirection.Input, percentage)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Delete a stage block
        ''' </summary>
        ''' <param name="timestamp">Timestamp of the message containing the delete command</param>
        ''' <param name="blockExternalSystemId">Identifier for the block</param>
        Public Sub DeleteBhpbioStageBlock(timestamp As DateTime, blockExternalSystemId As String) Implements IBhpbioBlock.DeleteBhpbioStageBlock
            With DataAccess
                .CommandText = "Staging.DeleteBhpbioStageBlock"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockExternalSystemId", CommandDataType.VarChar, CommandDirection.Input, 255, blockExternalSystemId)
                    .Add("@iTimestamp", CommandDataType.DateTime, CommandDirection.Input, timestamp)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Add a stage block point
        ''' </summary>
        ''' <param name="blockId">Identifier for the Block</param>
        ''' <param name="x">Easting (x) value</param>
        ''' <param name="y">Northing (y) value</param>
        ''' <param name="z">ToeRL (z) value</param>
        ''' <param name="pointNumber">A number used to order the point</param>
        Public Sub AddBhpbioStageBlockPoint(blockId As Integer, x As Double, y As Double, z As Double, pointNumber As Integer) _
            Implements IBhpbioBlock.AddBhpbioStageBlockPoint

            With DataAccess
                .CommandText = "Staging.AddBhpbioStageBlockPoint"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockId", CommandDataType.Int, CommandDirection.Input, blockId)
                    .Add("@iX", CommandDataType.Float, CommandDirection.Input, x)
                    .Add("@iY", CommandDataType.Float, CommandDirection.Input, y)
                    .Add("@iZ", CommandDataType.Float, CommandDirection.Input, z)
                    .Add("@iPointNumber", CommandDataType.Int, CommandDirection.Input, pointNumber)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Delete all stage block points associated with a Block
        ''' </summary>
        ''' <param name="blockId">the internal identifer of the Block whose points are to be deleted</param>
        Public Sub DeleteBhpbioStageBlockPoints(blockId As Integer) Implements IBhpbioBlock.DeleteBhpbioStageBlockPoints
            With DataAccess
                .CommandText = "Staging.DeleteBhpbioStageBlockPoints"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockId", CommandDataType.Int, CommandDirection.Input, blockId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Add or update a block in the staging area, only if the timestamp provided is the latest seen for the Block
        ''' </summary>
        ''' <param name="timestamp">timestamp associated with the data to be saged</param>
        ''' <param name="blockExternalSystemId">the external identifer of the Block to be added or updated</param>
        ''' <param name="blockName">the name of the block</param>
        ''' <param name="blockNumber">the number of the block</param>
        ''' <param name="lithologyType">the geoType (or lithology) of the Block</param>
        ''' <param name="flitchExternalSystemId">Identifies the flitch of the Block</param>
        ''' <param name="patternExternalSystemId">Identifies the pattern of the block</param>
        ''' <param name="dateBlocked">the datetime the block was blocked out</param>
        ''' <param name="centroidX">Easting (x) of the blocks centre</param>
        ''' <param name="centroidY">Northing (y)of the blocks centre</param>
        ''' <param name="centroidZ">ToeRL (z) of the blocks centre</param>
        ''' <param name="blockId">The block Id corresponding to the blockExternalSystemId</param>
        ''' <param name="isLatest">reference parameter set true if this data was the latest for the Block</param>
        ''' <remarks>This procedure call will take no action of the timestamp is not the latest seen for the Block</remarks>
        Public Sub AddOrUpdateBhpbioStageBlockIfLatest(timestamp As DateTime, blockExternalSystemId As String, blockName As String, blockNumber As Integer,
            lithologyType As String, flitchExternalSystemId As String, patternExternalSystemId As String, site As String, oreBody As String, pit As String,
            alternativePitCode As String, bench As String, patternNumber As String, dateBlocked As DateTime, centroidX As Double, centroidY As Double,
            centroidZ As Double, ByRef blockId As Nullable(Of Integer), ByRef isLatest As Boolean) Implements IBhpbioBlock.AddOrUpdateBhpbioStageBlockIfLatest

            Dim outBlockId As DataAccessParameter
            Dim outIsLatest As DataAccessParameter

            With DataAccess
                .CommandText = "Staging.AddOrUpdateBhpbioStageBlockIfLatest"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockExternalSystemId", CommandDataType.VarChar, CommandDirection.Input, 255, blockExternalSystemId)
                    .Add("@iTimestamp", CommandDataType.DateTime, CommandDirection.Input, timestamp)
                    .Add("@iLithologyType", CommandDataType.VarChar, CommandDirection.Input, 9, lithologyType)

                    .Add("@iFlitchExternalSystemId", CommandDataType.VarChar, CommandDirection.Input, 255, flitchExternalSystemId)
                    .Add("@iPatternExternalSystemId", CommandDataType.VarChar, CommandDirection.Input, 255, patternExternalSystemId)

                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, 16, site)
                    .Add("@iOrebody", CommandDataType.VarChar, CommandDirection.Input, 16, oreBody)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, 16, pit)
                    .Add("@iAlternativePitCode", CommandDataType.VarChar, CommandDirection.Input, 10, alternativePitCode)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, 16, bench)
                    .Add("@iPatternNumber", CommandDataType.VarChar, CommandDirection.Input, 16, patternNumber)
                    .Add("@iBlockName", CommandDataType.VarChar, CommandDirection.Input, 14, blockName)
                    .Add("@iBlockNumber", CommandDataType.VarChar, CommandDirection.Input, blockNumber.ToString())

                    .Add("@iDateBlocked", CommandDataType.DateTime, CommandDirection.Input, dateBlocked)

                    .Add("@iCentroidX", CommandDataType.Float, CommandDirection.Input, centroidX)
                    .Add("@iCentroidY", CommandDataType.Float, CommandDirection.Input, centroidY)
                    .Add("@iCentroidZ", CommandDataType.Float, CommandDirection.Input, centroidZ)

                    outBlockId = .Add("@oBlockId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)
                    outIsLatest = .Add("@oIsLatest", CommandDataType.Bit, CommandDirection.Output, NullValues.Boolean)
                End With

                .ExecuteNonQuery()
            End With

            If outBlockId.Value Is DBNull.Value Then
                blockId = Nothing
            Else
                blockId = CType(outBlockId.Value, Integer)
            End If

            If outIsLatest.Value Is DBNull.Value Then
                isLatest = False
            Else
                isLatest = CType(outIsLatest.Value, Boolean)
            End If
        End Sub

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
        ''' <param name="lumpPercentAsShipped">the percentage of lump material - AsShipped</param>
        ''' <param name="lumpPercentAsDropped">the percentage of lump material - AsDropped</param>
        ''' <param name="modelBlockId">reference parameter set to the id of the model block record on add</param>
        Public Sub AddBhpbioStageBlockModel(modelType As String, blockId As Integer, materialCode As String, volume As Double, tonnes As Double,
            density As Double, lastModifiedUserName As String, lastModifiedDateTime As DateTime, modelFileName As String,
            lumpPercentAsShipped As Nullable(Of Decimal), lumpPercentAsDropped As Nullable(Of Decimal),
            ByRef modelBlockId As Nullable(Of Integer)) Implements IBhpbioBlock.AddBhpbioStageBlockModel

            Dim outId As DataAccessParameter

            With DataAccess
                .CommandText = "Staging.AddBhpbioStageBlockModel"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                .Clear()
                .Add("@iBlockId", CommandDataType.Int, CommandDirection.Input, blockId)
                .Add("@iModelName", CommandDataType.VarChar, CommandDirection.Input, 31, modelType)

                .Add("@iMaterialTypeName", CommandDataType.VarChar, CommandDirection.Input, 15, materialCode)
                .Add("@iVolume", CommandDataType.Float, CommandDirection.Input, volume)
                .Add("@iTonnes", CommandDataType.Float, CommandDirection.Input, tonnes)
                .Add("@iDensity", CommandDataType.Float, CommandDirection.Input, density)

                .Add("@iLastModifiedUsername", CommandDataType.VarChar, CommandDirection.Input, 50, lastModifiedUserName)
                .Add("@iLastModifiedDateTime", CommandDataType.DateTime, CommandDirection.Input, lastModifiedDateTime)

                .Add("@iLumpPercentAsShipped", CommandDataType.Decimal, CommandDirection.Input, lumpPercentAsShipped)
                .Add("@iLumpPercentAsDropped", CommandDataType.Decimal, CommandDirection.Input, lumpPercentAsDropped)

                .Add("@iModelFilename", CommandDataType.VarChar, CommandDirection.Input, 200, modelFileName)

                outId = .Add("@oModelBlockId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)
                End With

                .ExecuteNonQuery()
            End With

            If outId.IsNullValue Then
                modelBlockId = Nothing
            Else
                modelBlockId = CType(outId.Value, Integer)
            End If
        End Sub

        ''' <summary>
        ''' Delete all model blocks (and associated grades) associated with the specified Block and model type
        ''' </summary>
        ''' <param name="blockId">Internal Id of the block</param>
        ''' <param name="modelType">the type of the model whose data should be removed</param>
        Public Sub DeleteBhpbioStageBlockModels(blockId As Integer, modelType As String) Implements IBhpbioBlock.DeleteBhpbioStageBlockModels
            With DataAccess
                .CommandText = "Staging.DeleteBhpbioStageBlockModels"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iBlockId", CommandDataType.Int, CommandDirection.Input, blockId)
                    .Add("@iModelName", CommandDataType.VarChar, CommandDirection.Input, 31, modelType)
                End With

                .ExecuteNonQuery()
            End With
        End Sub
    End Class
End Namespace