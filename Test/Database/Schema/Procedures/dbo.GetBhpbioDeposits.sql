IF OBJECT_ID('dbo.GetBhpbioDeposits') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioDeposits  
GO 

--used by generating a list of pits for a deposit and "grey out\disable"the checkbox for the pits associated with another deposit 

CREATE PROCEDURE [dbo].[GetBhpbioDeposits]
(
  @iLocationId INT
)
AS
BEGIN
    --this Location
    SELECT * FROM [dbo].[Location] WHERE Parent_Location_Id=@iLocationId 
	--all LocationGroupLocations
	SELECT * FROM [dbo].[BhpbioLocationGroupLocation]
	--all LocationGroups (Deposits) linked to that Location
	SELECT * FROM [dbo].[BhpbioLocationGroup] WHERE ParentLocationId=@iLocationId 
END

GO

GRANT EXECUTE ON dbo.GetBhpbioDeposits TO BhpbioGenericManager
GO

