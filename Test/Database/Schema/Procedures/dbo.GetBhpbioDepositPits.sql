IF OBJECT_ID('dbo.GetBhpbioDepositPits') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioDepositPits 
GO

--This SP returns data for a list of deposits with the comma separated list of pitnames for a certain location
--The magic happens in code, this sp just provides the data required

CREATE PROCEDURE [dbo].[GetBhpbioDepositPits]
(
  @iLocationGroupId INT,
  @parentSiteId INT
)
AS
BEGIN
    DECLARE @siteLocationId INT
	SET @siteLocationId =
	(
	    SELECT deposit.ParentLocationId
		FROM [dbo].[BhpbioLocationGroup] deposit
		WHERE deposit.LocationGroupId=@iLocationGroupId
	)

    --Deposit
	SELECT * FROM [dbo].[BhpbioLocationGroup] deposit 
	WHERE  deposit.LocationGroupId=@iLocationGroupId 

	--Associated Pits (not just mine)
	SELECT * FROM [dbo].[BhpbioLocationGroupLocation] location

	
	IF @parentSiteId IS NULL
	BEGIN
	    SET @parentSiteId =@siteLocationId
	END

	--All pits of that site
    SELECT location.Name, location.Location_Id  FROM [dbo].[Location] location JOIN [dbo].[LocationType] locationType
    ON location.Location_Type_Id=locationType.Location_Type_Id 
    WHERE locationType.Description='Pit' AND
 location.Parent_Location_Id=@parentSiteId
	


END

GO

GRANT EXECUTE ON dbo.GetBhpbioDepositPits TO BhpbioGenericManager
GO
