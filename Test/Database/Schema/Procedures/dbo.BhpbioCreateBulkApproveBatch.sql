IF OBJECT_ID('dbo.BhpbioCreateBulkApproveBatch') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioCreateBulkApproveBatch  
GO 
CREATE PROCEDURE [dbo].[BhpbioCreateBulkApproveBatch]
(
	@operationType		BIT,
	@iUserId			INT,
	@locationId			INT,
	@monthFrom			DATETIME,
	@monthTo			DATETIME,
	@locationTypeFrom	INT,
	@locationTypeTo		INT,
	@oApprovalId		INT OUTPUT
)
AS
BEGIN
	INSERT INTO [dbo].[BhpbioCreateBulkApproveBatch]
	(
		[OperationType],
		[User],
		[CreatedTime],
		[Status]
	)
	VALUES
	(
		@operationType,
		@iUserId,
		CURRENT_TIMESTAMP,
		0
	)
	SET @oApprovalId = SCOPE_IDENTITY() 
END
Go

GRANT EXECUTE ON dbo.BhpbioCreateBulkApproveBatch TO BhpbioGenericManager
Go