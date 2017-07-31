IF OBJECT_ID('dbo.SummariseBhpbioDataRelatedToApproval') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioDataRelatedToApproval
GO 
  
CREATE PROCEDURE dbo.SummariseBhpbioDataRelatedToApproval
(
	@iTagId VARCHAR(63),
	@iLocationId INT,
	@iApprovalMonth DATETIME,
	@iUserId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @TransactionName VARCHAR
	DECLARE @TransactionCount INTEGER
	
	SELECT @TransactionName = 'SummariseBhpbioDataRelatedToApproval',
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
	
		-- Here we plug-in data summarisation steps as part of the approval
		-- based on the supplied @iTagId
		
		IF @iTagId = 'F1Factor'
		BEGIN
			-- summarise ActualY data
			exec dbo.SummariseBhpbioActualY @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
											
			exec dbo.SummariseBhpbioAdditionalHaulageRelated @iSummaryMonth = @iApprovalMonth, 
										@iSummaryLocationId = @iLocationId,
										@iIsHighGrade = 1,
										@iSpecificMaterialTypeId = null
			
			
			DECLARE @oreMaterialTypes TABLE (
				Material_Type_Id INT,
				Is_Processed BIT
			)	
			INSERT INTO @oreMaterialTypes (Material_Type_Id, Is_Processed)
				SELECT MaterialTypeId, 0
				FROM dbo.GetBhpbioReportHighGrade()						
				
			DECLARE @materialTypeIdToProcess INT
			SELECT @materialTypeIdToProcess = (SELECT TOP 1 Material_Type_Id FROM @oreMaterialTypes WHERE Is_Processed = 0)
			
			-- Process Ore Material Types one at a time without setting up a cursor (to avoid potential messy clean up on exception within one of the called procedures)
			WHILE @materialTypeIdToProcess IS NOT NULL
			BEGIN

				
				-- summarise Hauled From Block Movements
				exec dbo.SummariseBhpbioOMHauledFromBlock @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @materialTypeIdToProcess
				
				UPDATE @oreMaterialTypes SET Is_Processed = 1 WHERE Material_Type_Id = @materialTypeIdToProcess
				-- get the next type to process
				SELECT @materialTypeIdToProcess = (SELECT TOP 1 Material_Type_Id FROM @oreMaterialTypes WHERE Is_Processed = 0)
			END
		END
		
		IF @iTagId = 'F1GeologyModel'
		BEGIN
			-- summarise geology model movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Geology'
		END
		
		IF @iTagId = 'F1GradeControlModel'
		BEGIN
			-- summarise grade control movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Grade Control'
		END
		
		IF @iTagId = 'F1MiningModel'
		BEGIN
			-- summarise mining model movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Mining'
		END
		
		IF @iTagId = 'F15ShortTermGeologyModel'
		BEGIN
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Short Term Geology'

			-- need to create a new summary of grade control data for only those blocks where STGM data is present
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Grade Control STGM'
		END
		
		IF @iTagId like 'OtherMaterial%'
		BEGIN
			DECLARE @otherMaterialTypeId INTEGER
			
			-- determine the MaterialType associated with the OtherMaterial movement
			SELECT @otherMaterialTypeId = OtherMaterialTypeId
			FROM dbo.BhpbioReportDataTags rdt
			WHERE rdt.TagId = @iTagId
			
			-- summarise Geology Model Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Geology'
													
			-- summarise STGM Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Short Term Geology'
			
			-- summarise Grade Control Model Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Grade Control'
			
			-- summarise Grade Control STGM Model Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Grade Control STGM'
			
			-- summarise Mining Model Movements													
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Mining'
													
			-- summarise stockpile movements (for the specific type)
			exec dbo.SummariseBhpbioOMToStockpile @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @otherMaterialTypeId
			
			-- summarise Hauled From Block Movements
			exec dbo.SummariseBhpbioOMHauledFromBlock @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @otherMaterialTypeId
														
			
			exec dbo.SummariseBhpbioAdditionalHaulageRelated @iSummaryMonth = @iApprovalMonth,
																		@iSummaryLocationId = @iLocationId,
																		@iIsHighGrade = null,
																		@iSpecificMaterialTypeId = @otherMaterialTypeId
		END
		
		IF @iTagId = 'F2MineProductionActuals'
		BEGIN
			-- summarise ActualC data
			exec dbo.SummariseBhpbioActualC @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
											
			-- and at the same time summarise the Bene Feed
			exec dbo.SummariseBhpbioActualBeneProduct	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F2StockpileToCrusher'
		BEGIN
			-- summarise ActualZ data for the site
			exec dbo.SummariseBhpbioActualZ @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F25OreForRail'
		BEGIN
			-- summarise ActualZ data for the site
			exec dbo.SummariseBhpbioOreForRail @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
		END

		IF @iTagId = 'F25PostCrusherStockpileDelta'
		BEGIN
			-- summarise SitePostCrusherStockpileDelta data
			
			-- for Hub crushers
			exec dbo.SummariseBhpbioPostCrusherStockpileDelta @iSummaryMonth = @iApprovalMonth, 
															  @iSummaryLocationId = @iLocationId,
															  @iPostCrusherLevel = 'Hub'
			
			-- and Site crushers												  
			exec dbo.SummariseBhpbioPostCrusherStockpileDelta @iSummaryMonth = @iApprovalMonth, 
															  @iSummaryLocationId = @iLocationId,
															  @iPostCrusherLevel = 'Site'
		END
		
		IF @iTagId = 'F3PortStockpileDelta'
		BEGIN
			exec dbo.SummariseBhpbioPortStockpileDelta	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F3PortBlendedAdjustment'
		BEGIN
			exec dbo.SummariseBhpbioPortBlendedAdjustment	@iSummaryMonth = @iApprovalMonth, 
															@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F3OreShipped'
		BEGIN
			exec dbo.SummariseBhpbioShippingTransaction @iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
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
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.SummariseBhpbioDataRelatedToApproval TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioDataRelatedToApproval
	@iTagId = 'F2Factor',
	@iLocationId = 3,
	@iApprovalMonth = '2009-11-01',
	@iUserId = 1
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioDataRelatedToApproval">
 <Procedure>
	Generates a set of summary data based on supplied criteria.
	The criteria used is the same that would be passed to the corresponding Approval call
	
	Pass: 
			@iTagId: indicates the type of approval to generate summary information for
			@iLocationId: indicates a location related to the approval operation (for F1 approvals this would be a Pit and so on)
			@iApprovalMonth: the approval month to generate summary data for
			@iUserId: Identifies the user performing the operation			
 </Procedure>
</TAG>
*/