IF OBJECT_ID('dbo.DoesBhpbioQueuedBlocksJobExist') IS NOT NULL
     DROP PROCEDURE dbo.DoesBhpbioQueuedBlocksJobExist
GO 
  
CREATE PROCEDURE dbo.DoesBhpbioQueuedBlocksJobExist
(
	@iImportId INT,
	@iSite VARCHAR(31),
	@iPit VARCHAR(31),
	@iBench VARCHAR(31),
	@oExists BIT OUTPUT
)

AS 
BEGIN 

	Set @oExists = dbo.BhpbioDoesQueuedBlocksJobExist(@iImportId, @iSite, @iPit, @iBench)

END
GO


GRANT EXECUTE ON dbo.DoesBhpbioQueuedBlocksJobExist TO BhpbioGenericManager
GO
