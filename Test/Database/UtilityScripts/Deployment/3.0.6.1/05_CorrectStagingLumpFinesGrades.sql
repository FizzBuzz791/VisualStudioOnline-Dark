-- Correct Staging grades ----
BEGIN TRANSACTION
	-- first copy the values about to be updated
	INSERT INTO [Staging].[TmpLumpFinesStageBlockModelGradeCorrection](
			[BlockModelId],
			[GradeName],
			[GradeValue],
			[LumpValue],
			[FinesValue]
			)
	SELECT 
		bmg.BlockModelId, bmg.GradeName, bmg.GradeValue, bmg.LumpValue, bmg.FinesValue
	FROM 
		Staging.TmpStageLumpFinesBlockCorrectionBlocks cb
		INNER JOIN Staging.StageBlock b ON b.BlockFullName = cb.BlockFullName
		INNER JOIN Staging.StageBlockModel sb ON sb.BlockId = b.BlockId
		INNER JOIN Staging.StageBlockModelGrade bmg ON bmg.BlockModelId = sb.BlockModelId
		WHERE (NOT sb.BlockModelName = 'Grade Control')

	UPDATE lfg
		SET lfg.CorrectedLumpValue = lfg.FinesValue,	-- switch lump and fines
			lfg.CorrectedFinesValue = lfg.LumpValue,	-- switch lump and fines
			lfg.[CorrectedGradeValue] = lfg.[GradeValue]			-- copy head grade
	FROM [Staging].[TmpLumpFinesStageBlockModelGradeCorrection] lfg

	-- recalculate H2O total grades for As-Dropped and As-Shipped based on individual lump fines values
	UPDATE lfg
		SET lfg.[CorrectedGradeValue] =  (lfg.CorrectedLumpValue * (sbm.LumpPercent/100.0)) + (lfg.CorrectedFinesValue * ((100 - sbm.LumpPercent)/100.0))
	FROM [Staging].[TmpLumpFinesStageBlockModelGradeCorrection] lfg
		INNER JOIN Staging.StageBlockModel sbm ON sbm.BlockModelId = lfg.BlockModelId
	WHERE lfg.GradeName like '%H2O-As%'
	AND Not sbm.LumpPercent IS NULL
	AND Not lfg.CorrectedLumpValue IS NULL
	AND Not lfg.CorrectedFinesValue IS NULL

	-- now correct staging
	UPDATE sbmg
		SET sbmg.GradeValue = lfg.CorrectedGradeValue,
			sbmg.LumpValue = lfg.CorrectedLumpValue,
			sbmg.FinesValue = lfg.CorrectedFinesValue
	FROM [Staging].[TmpLumpFinesStageBlockModelGradeCorrection] lfg
		INNER JOIN Staging.StageBlockModelGrade sbmg ON sbmg.BlockModelId = lfg.BlockModelId AND sbmg.GradeName = lfg.GradeName

--ROLLBACK TRANSACTION -- (FOR TESTING)
COMMIT TRANSACTION
GO


