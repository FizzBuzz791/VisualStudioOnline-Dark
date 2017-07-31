IF OBJECT_ID('dbo.GetBhpbioLocationListWithOverrideAndDates') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationListWithOverrideAndDates 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationListWithOverrideAndDates
(
	@iLocationId INT,
	@ilowestLocationTypeDescription VARCHAR(31),
	@iStartDate DATETIME,
	@iEndDate DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 

	SELECT l.Location_Id, l.Name, l.Location_Type_Id, lt.Description AS Location_Type_Description,
		ISNULL(bld.Parent_Location_Id, 0) AS Parent_Location_Id, l.Description,
		ISNULL(lt.Parent_Location_Type_Id, 0) AS Parent_Location_Type_Id,
		bl.IncludeStart,
		bl.IncludeEnd
	FROM GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 1, @ilowestLocationTypeDescription, @iStartDate, @iEndDate) AS bl
		INNER JOIN BhpbioLocationDate AS bld
			ON bl.LocationId = bld.Location_Id
			AND bl.IncludeStart BETWEEN bld.Start_Date AND bld.End_Date
		INNER JOIN Location AS l
			ON bld.Location_Id = l.Location_Id
		INNER JOIN LocationType AS lt
			ON l.Location_Type_Id = lt.Location_Type_Id
	ORDER BY  l.Location_Type_Id, l.Name
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationListWithOverrideAndDates TO BhpbioGenericManager
GO
