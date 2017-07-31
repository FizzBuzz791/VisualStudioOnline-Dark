IF OBJECT_ID('dbo.GetBhpbioDigblockPolygonWithinRangeAndBench') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioDigblockPolygonWithinRangeAndBench
GO

CREATE PROCEDURE dbo.GetBhpbioDigblockPolygonWithinRangeAndBench
(
	@iDigblock_Id VARCHAR(31),
	@iMinX FLOAT,
	@iMaxX FLOAT,
	@iMinY FLOAT,
	@iMaxY FLOAT,
	@iZ INT
)
WITH ENCRYPTION 
AS
BEGIN
	SET NOCOUNT ON

	-- Get All Digblocks and fall within the range
	-- Return all of the Digblocks records.

	DECLARE @Bench INT
	DECLARE @BenchTypeId TINYINT
	DECLARE @DigblockLocation INT

	SELECT @DigblockLocation = Location_Id
	FROM dbo.DigblockLocation
	WHERE Digblock_Id = @iDigblock_Id

	SELECT @BenchTypeId = Location_Type_Id
	FROM dbo.LocationType
	WHERE Description = 'Bench'

	SET @Bench = dbo.GetLocationTypeLocationId(@DigblockLocation, @BenchTypeId)

	SELECT dp.Digblock_Id, dp.[Order_No], dp.X, dp.Y, dp.Z
	FROM dbo.DigblockPolygon AS dp
		INNER JOIN dbo.DigblockLocation AS dl
			ON (dl.Digblock_Id = dp.Digblock_Id)
	WHERE DP.Digblock_Id IN
		(
			SELECT DISTINCT Digblock_Id
			FROM dbo.DigblockPolygon
			WHERE x BETWEEN @iMinX AND @iMaxX
				AND Y BETWEEN @iMinY AND @iMaxY
				AND Z = @iZ
		)
		AND (@iDigblock_Id IS NULL OR (dp.Digblock_Id <> @iDigblock_Id))
		AND dbo.GetLocationTypeLocationId(dl.Location_Id, @BenchTypeId) = @Bench
END
GO

GRANT EXECUTE ON dbo.GetBhpbioDigblockPolygonWithinRangeAndBench TO CoreDepletionManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetDigblockPolygonWithinRange">
 <Procedure>
	Returns the list of polygons assigned to @iDigblock_Id that vall in the range
	Specified by the parameters.
 </Procedure>
</TAG>
*/ 