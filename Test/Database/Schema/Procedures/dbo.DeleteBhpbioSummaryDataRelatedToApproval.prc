IF OBJECT_ID('dbo.DeleteBhpbioSummaryDataRelatedToApproval') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryDataRelatedToApproval
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioSummaryDataRelatedToApproval
(
	@iTagId VARCHAR(63),
	@iLocationId INT,
	@iApprovalMonth DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @TransactionName VARCHAR
	DECLARE @TransactionCount INTEGER
	
	SELECT @TransactionName = 'DeleteBhpbioSummaryDataRelatedToApproval',
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
	
		DECLARE @summaryEntryTypeId INTEGER
		
		-- Here we plug-in data summarisation clering steps as part of the approval
		-- based on the Tag Id supplied
		
		IF @iTagId = 'F1Factor'
		BEGIN
			-- clear summary for ActualY movements as part of the F1 process
			exec dbo.DeleteBhpbioSummaryActualY @iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId
												
			exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iApprovalMonth, 
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
				-- summarise stockpile movements
				exec dbo.DeleteBhpbioSummaryOMToStockpile @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @materialTypeIdToProcess
				
				-- summarise Hauled From Block Movements
				exec dbo.DeleteBhpbioSummaryOMHauledFromBlock @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @materialTypeIdToProcess
				
				UPDATE @oreMaterialTypes SET Is_Processed = 1 WHERE Material_Type_Id = @materialTypeIdToProcess
				-- get the next type to process
				SELECT @materialTypeIdToProcess = (SELECT TOP 1 Material_Type_Id FROM @oreMaterialTypes WHERE Is_Processed = 0)
			END
			
		END
		
		IF @iTagId = 'F1GeologyModel'
		BEGIN
			-- clear summary for  geology model movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Geology'
		END
		
		IF @iTagId = 'F1GradeControlModel'
		BEGIN
			-- clear summary for  grade control movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Grade Control'
		END
		
		IF @iTagId = 'F1MiningModel'
		BEGIN
			-- clear summary for  mining model movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Mining'
		END
		
		IF @iTagId = 'F15ShortTermGeologyModel'
		BEGIN
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Short Term Geology'

			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Grade Control STGM'
		END
		
		IF @iTagId like 'OtherMaterial%'
		BEGIN
			DECLARE @otherMaterialTypeId INTEGER
			
			SELECT @otherMaterialTypeId = rdt.OtherMaterialTypeId
			FROM dbo.BhpbioReportDataTags rdt
			WHERE rdt.TagId = @iTagId
			
			-- clear summary for movements using the 3 models
			-- for only the MaterialType related to the OtherMaterial% tag
			
			-- geology model
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Geology'
			-- STGM
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Short Term Geology'
														
			-- grade control model
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Grade Control'
			
			-- grade control STGM
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Grade Control STGM'
														
			-- mining model													
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Mining'
														
			-- clear summary for Actual Other Movements to Stockpiles
			exec dbo.DeleteBhpbioSummaryOMToStockpile	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iSpecificMaterialTypeId = @otherMaterialTypeId

			--  Hauled From Block Movements
			exec dbo.DeleteBhpbioSummaryOMHauledFromBlock @iSummaryMonth = @iApprovalMonth,
														@iSummaryLocationId = @iLocationId,
														@iSpecificMaterialTypeId = @otherMaterialTypeId														
			
			exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iApprovalMonth, 
																	@iSummaryLocationId = @iLocationId,
																	@iIsHighGrade = null,
																	@iSpecificMaterialTypeId = @otherMaterialTypeId
		END
		
		IF @iTagId = 'F2MineProductionActuals'
		BEGIN
			-- obtain the Actual Type Id for ActualC storage
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualC'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualCSampleTonnes'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			-- delete Bene Feed data									
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualBeneFeed'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
												
			-- delete Bene Product data									
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualBeneProduct'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F2StockpileToCrusher'
		BEGIN
			-- obtain the Actual Type Id for ActualC storage
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualZ'
			
			-- delete ActualZ data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F25OreForRail'
		BEGIN
			-- obtain the Actual Type Id for OreForRail storage
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'OreForRail'
			
			-- delete ActualZ data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'OreForRailGrades'
			
			-- Grades for Hub crushers
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
		END
		
		
		IF @iTagId = 'F25PostCrusherStockpileDelta'
		BEGIN
			-- summarise SitePostCrusherStockpileDelta data
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'HubPostCrusherStockpileDelta'
			
			-- for Hub crushers
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'SitePostCrusherStockpileDelta'
			
			-- and Site crushers												  
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'HubPostCrusherSpDeltaGrades'
			
			-- Grades for Hub crushers
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'SitePostCrusherSpDeltaGrades'
			
			-- and Site crushers												  
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3PortStockpileDelta'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'PortStockpileDelta'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3PortBlendedAdjustment'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'PortBlending'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3OreShipped'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ShippingTransaction'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryDataRelatedToApproval TO BhpbioGenericManager
GO

/*
exec dbo.DeleteBhpbioSummaryDataRelatedToApproval
	@iTagId = 'F2Factor',
	@iLocationId = 3,
	@iApprovalMonth = '2009-11-01'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryDataRelatedToApproval">
 <Procedure>
	Deletes a set of summary data based on supplied criteria.
	The criteria used is the same that would be passed to the corresponding UnApproval call
	
	Pass: 
			@iTagId: indicates the type of approval to remove summary information for
			@iLocationId: indicates a location related to the removal operation (for F1 approvals this would be a Pit and so on)
			@iApprovalMonth: the approval month to remove summary data for
							
 </Procedure>
</TAG>
*/	
