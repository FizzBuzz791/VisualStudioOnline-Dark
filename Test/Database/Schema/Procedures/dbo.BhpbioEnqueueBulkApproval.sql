IF OBJECT_ID('dbo.BhpbioEnqueueBulkApproval') IS NOT NULL 
     DROP PROCEDURE dbo.BhpbioEnqueueBulkApproval
GO 

CREATE PROCEDURE [dbo].[BhpbioEnqueueBulkApproval]
(
	@iApproval					BIT,
	@iApprovalUserId			INT,
	@iLocationId				INT,
	@iEarliestMonth				DATETIME,
	@iLatestMonth				DATETIME,
	@iTopLevelLocationTypeId	INT,
	@iLowestLevelLocationTypeId	INT,
	@iIsBulk					BIT,
	@oApprovalId				INT OUTPUT
)
AS
BEGIN
	INSERT INTO dbo.[BhpbioBulkApprovalBatch]
	(
		[Approval],
		[UserId],
		[CreatedTime],
		[Status],
		[EarliestMonth],
		[LatestMonth],
		[TopLevelLocationTypeId],
		[LocationId],
		[LowestLevelLocationTypeId],
		[IsBulk]
	)
	VALUES
	(
		@iApproval,
		@iApprovalUserId,
		CURRENT_TIMESTAMP,
		'QUEUING',
		@iEarliestMonth,
		@iLatestMonth,
		@iTopLevelLocationTypeId,
		@iLocationId,
		@iLowestLevelLocationTypeId,
		@iIsBulk
	)
	SET @oApprovalId = SCOPE_IDENTITY() 
END
GO

GRANT EXECUTE ON dbo.BhpbioEnqueueBulkApproval TO BhpbioGenericManager
GO