IF OBJECT_ID('dbo.BhpbioDeleteLocationGroup') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioDeleteLocationGroup  
GO 

CREATE PROCEDURE [dbo].[BhpbioDeleteLocationGroup]
(
 @iLocationGroupId INT
)
AS
BEGIN 
  IF @iLocationGroupId is NULL
  BEGIN
    RAISERROR ('Parameter @iLocationGroupId not specified',16,1);
  END

  BEGIN TRANSACTION
  DELETE FROM [dbo].[BhpbioLocationGroupLocation] WHERE LocationGroupId=@iLocationGroupId
  DELETE FROM [dbo].[BhpbioLocationGroup] WHERE LocationGroupId=@iLocationGroupId
  COMMIT TRANSACTION
END

GO

GRANT EXECUTE ON dbo.BhpbioDeleteLocationGroup TO BhpbioGenericManager
GO
