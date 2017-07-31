IF Object_Id('dbo.GetBhpbioExcludeHubLocation') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioExcludeHubLocation
GO

CREATE FUNCTION dbo.GetBhpbioExcludeHubLocation
(
	@iExclusionType VARCHAR(50)
)
RETURNS @Location TABLE
(
	LocationId INT
	Primary KEY (LocationId)
)
BEGIN
	INSERT INTO @Location
		(LocationId)
	SELECT Distinct HubLocationId
	FROM BhpbioFactorExclusionFilter
	WHERE ExclusionType = @iExclusionType
	OR @iExclusionType IS NULL

	RETURN
END
GO