IF OBJECT_ID('dbo.GetBhpbioAnalysisVarianceList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioAnalysisVarianceList
GO 

CREATE PROCEDURE dbo.GetBhpbioAnalysisVarianceList
(
	@iLocationId INT,
	@iVarianceType CHAR(1) = NULL,
	@iOnlyInherited BIT = 0,
	@iOnlyLocation BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		DECLARE @CurrentLocation INT
		DECLARE @LocationId INT
		
		DECLARE @Results TABLE
		(
			LocationId INT,
			LocationName VARCHAR(255) COLLATE DATABASE_DEFAULT,
			VarianceType CHAR(1),
			Percentage FLOAT NOT NULL,
			Color VARCHAR(255) COLLATE Database_Default NULL
		)
		
		SET @LocationId = @iLocationId
		IF @LocationId < 1
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.Location
			WHERE Parent_Location_Id IS NULL
		END
		

		IF @iOnlyLocation = 1 OR (@iOnlyInherited = 0 AND @iOnlyLocation = 0)
		BEGIN
			INSERT INTO @Results
				(LocationId, LocationName, VarianceType, Percentage, Color)
			SELECT L.Location_Id, L.Description, BAV.VarianceType, BAV.Percentage, BAV.Color
			FROM dbo.Location AS L
				INNER JOIN dbo.BhpbioAnalysisVariance AS BAV
					ON L.Location_ID = BAV.LocationID
			WHERE L.Location_ID = @LocationId
				AND (BAV.VarianceType = @iVarianceType OR @iVarianceType IS NULL)
		END
		
		IF @iOnlyInherited = 1 OR (@iOnlyInherited = 0 AND @iOnlyLocation = 0 
									AND NOT EXISTS (SELECT 1 FROM @Results))
		BEGIN
			SET @CurrentLocation = @LocationId
			
			-- Cycle up through the parents until we find a location which has values we get to 
			--- the top.
			WHILE @CurrentLocation IS NOT NULL
			BEGIN

				IF EXISTS (	SELECT TOP 1 1 
							FROM dbo.BhpbioAnalysisVariance 
							WHERE LocationId = @CurrentLocation
						  )
				BEGIN

					-- If records exist at this level do not return anything as we are not inheriting.
					IF @CurrentLocation <> @LocationId
					BEGIN

						-- Update the records based on this location.
						INSERT INTO @Results
							(LocationId, LocationName, VarianceType, Percentage, Color)
						SELECT L.Location_Id, L.Description, BAV.VarianceType, BAV.Percentage, BAV.Color
						FROM dbo.Location AS L
							INNER JOIN dbo.BhpbioAnalysisVariance AS BAV
							ON L.Location_ID = BAV.LocationID
						WHERE L.Location_ID = @CurrentLocation
							AND (BAV.VarianceType = @iVarianceType OR @iVarianceType IS NULL)
					END
					
					-- We have found our match so finish the looping
					SET @CurrentLocation = NULL
				END
			
				-- Cycle up the parent heirachy
				SELECT @CurrentLocation = L.Parent_Location_Id
				FROM dbo.Location AS L
				WHERE L.Location_Id = @CurrentLocation
			END
		END
		
		
		SELECT LocationId, LocationName, VarianceType,Percentage, Color
		FROM @Results
			
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioAnalysisVarianceList TO BhpbioGenericManager
