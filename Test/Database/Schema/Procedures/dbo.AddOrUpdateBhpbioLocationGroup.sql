IF OBJECT_ID('dbo.AddOrUpdateBhpbioLocationGroup') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioLocationGroup  
GO 
CREATE PROCEDURE [dbo].[AddOrUpdateBhpbioLocationGroup]
(
 @iLocationGroupId INT,
 @iLocationId INT,         --Thats the Id of the site the deposit is associated with
 @iName NVARCHAR(31),
 @iLocationIds NVARCHAR(255),
 @iLocationGroupTypeName NVARCHAR(31)
)
AS
BEGIN 
 BEGIN TRANSACTION

 IF @iLocationId is NULL
 BEGIN
    RAISERROR ('Parameter @iLocationId not specified',16,1);
 END

 DECLARE @l TABLE (Location_Id INT, Location_Type_Id INT);
 INSERT INTO @l (Location_Id,Location_Type_Id) 
     SELECT Location_Id,Location_Type_Id FROM [dbo].[Location] WHERE Location_Id = @iLocationId
 IF NOT EXISTS (SELECT * FROM @l)
     RAISERROR ('Location @iLocationId does not exist',16,1);

 DECLARE @locationGroupId INT
 IF @iLocationGroupId IS NULL
 BEGIN
    PRINT 'Add Deposit'
	INSERT INTO [dbo].[BhpbioLocationGroup]
	(
		LocationGroupTypeName,
		ParentLocationId,
		Name,
		CreatedDate
	)
	VALUES
	(
		@iLocationGroupTypeName,
		@iLocationId,
		@iName,
		CURRENT_TIMESTAMP
	)
	SET @locationGroupId = SCOPE_IDENTITY()
 END
 ELSE
 BEGIN
    --Delete all associations for this deposit
    DELETE FROM [dbo].[BhpbioLocationGroupLocation] WHERE LocationGroupId=@iLocationGroupId

    PRINT 'Update Deposit'
    UPDATE [dbo].[BhpbioLocationGroup]
	SET Name=@iName
	WHERE LocationGroupTypeName=@iLocationGroupTypeName AND LocationGroupId=@iLocationGroupId
	SET @locationGroupId = @iLocationGroupId
 END
	 


  /*Split the comma separated value list and update tables accordingly*/
  DECLARE @pitId INT
  DECLARE depositcursor CURSOR FAST_FORWARD FOR
  SELECT * FROM [dbo].SplitString(@iLocationIds,',')
  OPEN depositCursor
  FETCH NEXT FROM depositCursor into @pitId
  WHILE @@FETCH_STATUS =0
  BEGIN
    
    INSERT INTO [dbo].[BhpbioLocationGroupLocation] 
	( 
		LocationGroupId,
		LocationId
	)
	VALUES
	(
	    @locationGroupId,
		@pitId
	)

	FETCH NEXT FROM depositCursor INTO @PitId
  END
  CLOSE depositCursor
  DEALLOCATE depositCursor

  COMMIT TRANSACTION
END

GO

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioLocationGroup TO BhpbioGenericManager
GO
