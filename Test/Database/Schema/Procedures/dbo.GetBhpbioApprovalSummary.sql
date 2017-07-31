IF OBJECT_ID('dbo.GetBhpbioApprovalSummary') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalSummary
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalSummary
(
	@iMonth				DATETIME,
	@iIncludeInactive	BIT = 0
)
AS 
BEGIN 
	DECLARE @tempLocationList TABLE(Location_Id INT, 
		Name VARCHAR(MAX), 
		Location_Type_Id INT, 
		Location_Type_Description VARCHAR(MAX), 
		Parent_Location_Id INT, 
		Description VARCHAR(MAX), 
		Parent_Location_Type_Id INT, 
		IncludeStart DATETIME, 
		IncludeEnd DATETIME)

	INSERT INTO @tempLocationList 
	  EXEC dbo.GetBhpbioLocationListWithOverrideAndDates 1, 'PIT', @iMonth, @iMonth

	SELECT L.Location_Id, L.Name, L.Parent_Location_Id, LT.Description AS LocationType, 
		CASE 
			WHEN BAD.LocationId IS NULL THEN 'Not Approved' 
			ELSE 'Approved' 
		END AS ApprovalStatus, 
		BAD.SignoffDate,
		CASE 
			WHEN LT.Description = 'PIT' AND @iIncludeInactive = 1 AND ActivePits.Active_Pit_Location_Id IS NULL THEN 'Inactive'
			WHEN LT.Description = 'PIT' AND @iIncludeInactive = 1 AND ActivePits.Active_Pit_Location_Id IS NOT NULL THEN 'Active'
			WHEN LT.Description = 'PIT' AND @iIncludeInactive = 0 THEN 'Active'
			ELSE 'N/A'
		END AS ActiveStatus  
	FROM @tempLocationList L
	INNER JOIN LocationType LT ON LT.Location_Type_Id = L.Location_Type_Id AND LT.Description IN ('Hub','Site','Pit')
	LEFT JOIN BhpbioApprovalData BAD ON BAD.LocationId = L.Location_Id AND BAD.ApprovedMonth = @iMonth 
		AND ((LT.Description = 'Hub' AND BAD.TagId = 'F3Factor') OR (LT.Description = 'Site' AND BAD.TagId = 'F2Factor') OR (LT.Description = 'Pit' AND BAD.TagId = 'F1Factor'))
	LEFT JOIN (
		-- distinct pits with activity
		SELECT DISTINCT PitLocation.Location_Id as Active_Pit_Location_Id
		FROM Haulage H
			INNER JOIN Digblock D ON D.Digblock_Id = H.Source_Digblock_Id
			INNER JOIN DigblockLocation DBL ON DBL.Digblock_Id = D.Digblock_Id
			INNER JOIN Location BlockLocation ON BlockLocation.Location_Id = DBL.Location_Id
			INNER JOIN Location BlastLocation ON BlastLocation.Location_Id = BlockLocation.Parent_Location_Id
			INNER JOIN Location BenchLocation ON BenchLocation.Location_Id = BlastLocation.Parent_Location_Id
			INNER JOIN Location PitLocation ON PitLocation.Location_Id = BenchLocation.Parent_Location_Id
		WHERE H.Haulage_Date BETWEEN @iMonth AND DATEADD(DAY,-1,DATEADD(MONTH, 1, @iMonth))
	   ) AS ActivePits ON ActivePits.Active_Pit_Location_Id = L.Location_Id
	WHERE ((LT.Description = 'Pit' AND ((@iIncludeInactive = 0 AND ActivePits.Active_Pit_Location_Id IS NOT NULL) OR (@iIncludeInactive = 1))) OR (LT.Description <> 'Pit'))
	ORDER BY LT.Location_Type_Id, L.Name
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioApprovalSummary TO BhpbioGenericManager
GO
