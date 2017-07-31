
Set NoCount On

declare @AsDroppedRowId Int
declare @StagingBlockModelId Int

Select top(1) 
	@AsDroppedRowId = RowId,
	@StagingBlockModelId = StagingBlockModelId
from Staging.TmpAsDroppedImport
where StagingBlockModelId is not null
	and Processed = 0
	--and site = 'AREAC'
ORDER BY [Site], Pit, RowId

While @AsDroppedRowId Is Not Null
Begin
	
	BEGIN TRANSACTION [Tran1]
	BEGIN TRY


	-- import to the staging tables
	DECLARE @MODEL_NAME varchar(64)
	DECLARE @AD_LUMP_PCT numeric(7,4)
	DECLARE @AD_LUMP_FE real
	DECLARE @AD_LUMP_P real
	DECLARE @AD_LUMP_SIO2 real
	DECLARE @AD_LUMP_AL2O3 real
	DECLARE @AD_LUMP_LOI real
	DECLARE @AD_LUMP_H2O real

	DECLARE @AD_FINES_FE real
	DECLARE @AD_FINES_P real
	DECLARE @AD_FINES_SIO2 real
	DECLARE @AD_FINES_AL2O3 real
	DECLARE @AD_FINES_LOI real
	DECLARE @AD_FINES_H2O real
	
	DECLARE @AS_FINES_UF real
	DECLARE @AD_FINES_UF real

	DECLARE @AS_LUMP_H2O real
	DECLARE @AS_FINES_H2O real

	Select
		@MODEL_NAME = MODEL,
		@AD_LUMP_PCT = [AD_LUMP_PCT],
		@AD_LUMP_FE	= [AD_LUMP_FE], @AD_FINES_FE = [AD_FINES_FE],
		@AD_LUMP_P = [AD_LUMP_P], @AD_FINES_P = [AD_FINES_P],
		@AD_LUMP_SIO2 = [AD_LUMP_SIO2], @AD_FINES_SIO2 = [AD_FINES_SIO2],
		@AD_LUMP_AL2O3 = [AD_LUMP_AL2O3], @AD_FINES_AL2O3 = [AD_FINES_AL2O3],
		@AD_LUMP_LOI = [AD_LUMP_LOI], @AD_FINES_LOI = [AD_FINES_LOI],
		@AD_LUMP_H2O = [AD_LUMP_H2O], @AD_FINES_H2O = [AD_FINES_H2O],
		@AS_FINES_UF = [AS_FINES_UF], @AD_FINES_UF = [AD_FINES_UF],
		@AS_LUMP_H2O = AS_LUMP_H2O, @AS_FINES_H2O = AS_FINES_H2O
	From Staging.TmpAsDroppedImport
	Where RowId = @AsDroppedRowId
	
	
	UPDATE [Staging].[StageBlockModel]
	SET LumpPercentAsDropped = @AD_LUMP_PCT
	WHERE BlockModelId = @StagingBlockModelId
	

	Delete From Staging.StageBlockModelGrade
	Where BlockModelId = @StagingBlockModelId
		and GeometType = 'As-Dropped'
			

	Insert Into Staging.StageBlockModelGrade (BlockModelId, GradeName, GradeValue, LumpValue, FinesValue, GeometType)
		Select
			@StagingBlockModelId,
			Grade_Name,
			IsNull(bmg.GradeValue, 0.0) as GradeValue,
			(
				Case
					When Grade_Name = 'Fe' Then @AD_LUMP_FE
					When Grade_Name = 'P' Then @AD_LUMP_P
					When Grade_Name = 'SiO2' Then @AD_LUMP_SIO2
					When Grade_Name = 'Al2O3' Then @AD_LUMP_AL2O3
					When Grade_Name = 'LOI' Then @AD_LUMP_LOI
					When Grade_Name = 'H2O' Then @AD_LUMP_H2O
					Else Null
				End
			) as LumpValue,
			(
				Case
					When Grade_Name = 'Fe' Then @AD_FINES_FE
					When Grade_Name = 'P' Then @AD_FINES_P
					When Grade_Name = 'SiO2' Then @AD_FINES_SIO2
					When Grade_Name = 'Al2O3' Then @AD_FINES_AL2O3
					When Grade_Name = 'LOI' Then @AD_FINES_LOI
					When Grade_Name = 'H2O' Then @AD_FINES_H2O
					Else Null
				End
			) as FinesValue,
			'As-Dropped'
		From dbo.Grade g
			left join Staging.StageBlockModelGrade bmg
				on bmg.BlockModelId = @StagingBlockModelId
					and bmg.GradeName = g.Grade_Name
					and GeometType = 'NA'
		Where Grade_Name in ('Fe', 'P', 'SiO2', 'Al2O3', 'LOI', 'H2O')
	
	-- update the AS grades
	Update Staging.StageBlockModelGrade
		Set 
			LumpValue = (
				Case
					When GradeName = 'H2O' Then @AS_LUMP_H2O
					Else Null
				End
			),
			FinesValue = (
				Case
					When GradeName = 'H2O' Then @AS_FINES_H2O
					Else Null
				End
			)
	Where BlockModelId = @StagingBlockModelId
		and GeometType = 'As-Shipped'
		and GradeName in ('H2O')
	

	Delete From Staging.StageBlockModelGrade
	Where GradeName in ('H2O-As-Dropped', 'H2O-As-Shipped')
		And BlockModelId = @StagingBlockModelId	
	
	-- ultra fines is a special case - we delete this and insert it separately
	Delete From Staging.StageBlockModelGrade
	Where GradeName = 'Ultrafines'
		And BlockModelId = @StagingBlockModelId

	DECLARE @AS_LUMP_PCT numeric(7,4)

	SELECT @AS_LUMP_PCT = LumpPercentAsShipped
	FROM Staging.StageBlockModel WHERE BlockModelId = @StagingBlockModelId

	IF NOT (@AD_LUMP_PCT IS NULL OR @AD_FINES_UF IS NULL)
	BEGIN
		-- only insert ultrafines if there is actually a lump % for the geomet type
		Insert Into Staging.StageBlockModelGrade (BlockModelId, GeometType, GradeName, GradeValue, LumpValue, FinesValue)
			Select @StagingBlockModelId, 'As-Dropped', 'Ultrafines', 0.0, 0.0, @AD_FINES_UF
	END

	IF NOT (@AS_LUMP_PCT IS NULL OR @AS_FINES_UF IS NULL)
	BEGIN
		-- only insert ultrafines if there is actually a lump % for the geomet type
		Insert Into Staging.StageBlockModelGrade (BlockModelId, GeometType, GradeName, GradeValue, LumpValue, FinesValue)
			Select @StagingBlockModelId, 'As-Shipped', 'Ultrafines', 0.0, 0.0, @AS_FINES_UF
	END

	Update g
		set g.GradeValue = (1 - (Case 
			When GeometType = 'As-Shipped' Then smb.LumpPercentAsShipped / 100.0
			Else smb.LumpPercentAsDropped / 100.0
		End)) * FinesValue
	from Staging.StageBlockModelGrade g
		inner join Staging.StageBlockModel smb
			on smb.BlockModelId = smb.BlockModelId
	Where g.GradeName = 'Ultrafines'
		and g.BlockModelId = @StagingBlockModelId
	
	
	-- import to the live tables
	exec Staging.ImportStagingModelBlockAsDroppedToLiveTables @StagingBlockModelId
	
	
	-- import to the summary tables	
	exec Staging.ImportStagingModelBlockAsDroppedToSummaryTables @StagingBlockModelId, null, 1

	
	If @MODEL_NAME = 'Grade Control'
	Begin
	
		-- because of the GC with STM thing, we need to insert another record into approved
		-- when the model is GC. This model doesn't exist in the live tables, but the data is 
		-- duplicated in approved
		declare @GradeControlWithSTMId int = 5
		exec Staging.ImportStagingModelBlockAsDroppedToSummaryTables @StagingBlockModelId, @GradeControlWithSTMId, 1
		
	
	End

	-- mark the row as processed
	Update Staging.TmpAsDroppedImport
	Set Processed = 1, Message = null
	Where RowId = @AsDroppedRowId
	
	COMMIT TRANSACTION


	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		Update Staging.TmpAsDroppedImport
		Set Processed = 1,
			Message = ERROR_MESSAGE()
		Where RowId = @AsDroppedRowId

		print ERROR_MESSAGE()
	END CATCH 
	
	-- get the next row
	Set @AsDroppedRowId = null
	Select top(1) 
		@AsDroppedRowId = RowId,
		@StagingBlockModelId = StagingBlockModelId
	from Staging.TmpAsDroppedImport
	where StagingBlockModelId is not null
		and Processed = 0
		--and site = 'AREAC'
	ORDER BY [Site], Pit, RowId

	print @StagingBlockModelId
End
