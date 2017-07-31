IF OBJECT_ID('dbo.GetBhpbioResourceClassificationByLocation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioResourceClassificationByLocation
GO 
  
CREATE PROCEDURE dbo.GetBhpbioResourceClassificationByLocation
(
	@iLocationId Int,
	@iLocationDateFrom DateTime,
	@iBlockedDateFrom DateTime = Null,
	@iBlockedDateTo DateTime = Null
)
WITH ENCRYPTION
AS
BEGIN 

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioResourceClassificationByLocation',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY

	Declare @LocationType Int

		Select 
			@LocationType = Location_Type_Id
		From Location 
		Where Location_Id = @iLocationId

		Select
			@iLocationId as LocationId,
			bm.Block_Model_Id as BlockModelId,
			bm.Name as BlockModelName,
			bm.Description as BlockModelDescription,
			IsNull(mbpv.Model_Block_Partial_Field_Id, 'ResourceClassificationUnknown') As ResourceClassification,
			SUM(mbp.Tonnes * IsNull(mbpv.Field_Value / 100, 1)) as Tonnes
		from dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 1,'BLOCK', @iLocationDateFrom, @iLocationDateFrom) l
			Inner Join ModelBlockLocation mbl 
				On mbl.Location_Id = l.LocationId
			Inner Join ModelBlock mb
				On mb.Model_Block_Id = mbl.Model_Block_Id
			Inner Join ModelBlockPartial mbp
				On mbp.Model_Block_Id = mb.Model_Block_Id
			Inner Join BlockModel bm
				On bm.Block_Model_Id = mb.Block_Model_Id
			Left Join ModelBlockPartialNotes bd
				on bd.Model_Block_Id = mbp.Model_Block_Id
					and bd.Sequence_No = mbp.Sequence_No
					and bd.Model_Block_Partial_Field_Id = 'BlockedDate'
			Left Join ModelBlockPartialValue mbpv
				On mbpv.Model_Block_Id = mbp.Model_Block_Id
					And mbpv.Sequence_No = mbp.Sequence_No
					And mbpv.Model_Block_Partial_Field_Id like 'ResourceClassification%'
		Where Convert(datetime, Replace(bd.Notes, '.0000000', '.000'), 126) between @iBlockedDateFrom and @iBlockedDateTo
			Or (@iBlockedDateFrom is Null And @iBlockedDateTo is Null)
		Group By bm.Name, bm.Block_Model_Id, bm.Description, mbpv.Model_Block_Partial_Field_Id

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and all's well
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioResourceClassificationByLocation TO BhpbioGenericManager
GO

