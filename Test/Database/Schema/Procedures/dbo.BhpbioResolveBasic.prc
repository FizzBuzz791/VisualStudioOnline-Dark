 If Exists (Select 1 From sysobjects Where ID = Object_Id('dbo.BhpbioResolveBasic'))
	Drop Procedure dbo.BhpbioResolveBasic
Go

Create Procedure dbo.BhpbioResolveBasic
(
	@iTransactionDate Datetime,
	@iCode Varchar(31),
	@iResolution_Target VarChar(11),
	@oResolved Bit = 0 Output,
	@oDigblockId VARCHAR(31) Output,
	@oStockpileId INT Output,
	@oCrusherId VARCHAR(31) Output,
	@oMillId VARCHAR(31) Output
)


As

Begin
	-- uses the basic resolution methods to resolve the record
	-- this is achieved by the following steps:
	-- 1. Attempt to map through HaulageResolveBasic (based on rules)
	-- 2. Attempt to map directly to Digblock
	-- 3. Attempt to map directly to Stockpile
	-- 4. Attempt to map directly to Crusher

	-- iResolution_Target is either SOURCE or DESTINATION

	Declare @Digblock_Id VarChar(31)
	Declare @Stockpile_Id Int
	Declare @Build_Id Int
	Declare @Component_Id Int
	Declare @Crusher_Id VarChar(31)
	Declare @Mill_Id VarChar(31)
	Declare @Haulage_Resolve_Basic_Id Int
	Declare @TransactionShift Varchar(1)
	
	SET @TransactionShift = dbo.GetFirstShiftType()

	Declare @Resolved Bit

	Set NoCount On

	Set @Resolved = 0

	-- clear all variables
	Set @Digblock_Id = Null
	Set @Stockpile_Id = Null
	Set @Build_Id = Null
	Set @Component_Id = Null
	Set @Crusher_Id = Null
	Set @Mill_Id = Null
	Set @Haulage_Resolve_Basic_Id = Null

	-- attempt to map through HaulageResolveBasic
	Set @Haulage_Resolve_Basic_Id = Null

	Select @Haulage_Resolve_Basic_Id = Haulage_Resolve_Basic_Id
	From dbo.HaulageResolveBasic HRB
	Where Code = @iCode
		And (	HRB.Haulage_Direction = 'B'
				Or (HRB.Haulage_Direction =  'S' And @iResolution_Target = 'SOURCE')
				Or (HRB.Haulage_Direction =  'D' And @iResolution_Target = 'DESTINATION'))

	If @Haulage_Resolve_Basic_Id Is Not Null
	Begin
		Select @Digblock_Id = Digblock_Id,
			@Stockpile_Id = Stockpile_Id,
			@Build_Id = Build_Id,
			@Component_Id = Component_Id,
			@Crusher_Id = Crusher_Id
		From dbo.HaulageResolveBasic
		Where Haulage_Resolve_Basic_Id = @Haulage_Resolve_Basic_Id

		Set @Resolved = 1
	End

	-----
	Set @Haulage_Resolve_Basic_Id = Null

	If @Resolved = 0
	BEGIN
		Select @Haulage_Resolve_Basic_Id = Production_Resolve_Basic_Id
		From dbo.BhpbioProductionResolveBasic HRB
		Where Code = @iCode
			And (	HRB.Production_Direction = 'B'
					Or (HRB.Production_Direction =  'S' And @iResolution_Target = 'SOURCE')
					Or (HRB.Production_Direction =  'D' And @iResolution_Target = 'DESTINATION'))

		If @Haulage_Resolve_Basic_Id Is Not Null
		Begin
			Select @Digblock_Id = Digblock_Id,
				@Stockpile_Id = Stockpile_Id,
				@Build_Id = Build_Id,
				@Component_Id = Component_Id,
				@Crusher_Id = Crusher_Id
			From dbo.BhpbioProductionResolveBasic
			Where Production_Resolve_Basic_Id = @Haulage_Resolve_Basic_Id

			Set @Resolved = 1
		End
	END
	-- attempt to map directly to Digblock
	-- note: a digblock can only be a source
	--       this may be changed in future releases
	If @iResolution_Target = 'SOURCE'
	Begin
		If @Resolved = 0
		Begin
			Select @Digblock_Id = Digblock_Id
			From dbo.Digblock
			Where Digblock_Id = Left(@iCode, 31)

			If @Digblock_Id Is Not Null
				Set @Resolved = 1
		End
	End

	-- attempt to map directly to Mill
	-- note: the old system will not allow transactions to/from Mill
	--       this is available for any future extensions
	If @Resolved = 0
	Begin
		Select @Mill_Id = Mill_Id
		From dbo.Mill
		Where Mill_Id = Left(@iCode, 31)

		If @Mill_Id Is Not Null
			Set @Resolved = 1
	End

	-- attempt to map directly to Stockpile
	If @Resolved = 0
	Begin
		Select @Stockpile_Id = Stockpile_Id
		From dbo.Stockpile
		Where Stockpile_Name = Left(@iCode, 31)

		If @Stockpile_Id Is Not Null
			Set @Resolved = 1
	End

	-- attempt to map directly to Crusher
	-- note: a crusher can only be a destination
	--       this may be changed in future releases
	If @Resolved = 0
	Begin
		Select @Crusher_Id = Crusher_Id
		From dbo.Crusher
		Where Crusher_Id = Left(@iCode, 31)

		If @Crusher_Id Is Not Null
			Set @Resolved = 1
	End



	-- based on the stockpile resolution, attempt to fill in the "missing picture" for build
	-- note: if the component is not specified,
	-- the Recalc will fill in this information (it will pro-rata out against all components)
	If (@Resolved = 1)
		And (@Stockpile_Id Is Not Null) And (@Build_Id Is Null)
	Begin
		If (@iResolution_Target = 'SOURCE')
			Set @Build_Id = dbo.GetReclaimableStockpileBuild(@Stockpile_Id, @iTransactionDate, @TransactionShift)
		Else
			Set @Build_Id = dbo.GetBuildableStockpileBuild(@Stockpile_Id, @iTransactionDate, @TransactionShift)
	End

	Set @oResolved = @Resolved
	
	IF @Resolved = 1
	BEGIN
		SET @oDigblockId = @Digblock_Id
		SET @oStockpileId = @Stockpile_Id
		SET @oCrusherId = @Crusher_Id
		SET @oMillId = @Mill_Id
	END
	
END
GO

/*
<TAG Name="Data Dictionary" ProcedureName="BhpbioResolveBasic">
 <Procedure>
	Uses the basic resolution methods to resolve the record.
	This is achieved by the following steps:
	1. Attempt to map through HaulageResolveBasic (based on rules).
	2. Attempt to map directly to Digblock.
	3. Attempt to map directly to Stockpile.
	4. Attempt to map directly to Crusher.
	5. Attempt to map directly to Mill.
 </Procedure>
</TAG>
*/