IF OBJECT_ID('dbo.GetBhpbioReportThresholdList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportThresholdList
GO 

CREATE PROCEDURE dbo.GetBhpbioReportThresholdList
(
	@iLocationId INT,
	@iThresholdTypeId VARCHAR(31),
	@iOnlyInherited BIT = 0,
	@iOnlyLocation BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		DECLARE @CurrentLocation INT
		DECLARE @TonnesFieldId INT
		DECLARE @VolumeFieldId INT
		DECLARE @CurrentThresholdTypeId VARCHAR(31)
		
		SET @TonnesFieldId = 0
		SET @VolumeFieldId = -1
		
		DECLARE @Results TABLE
		(
			LocationId INT NULL,
			LocationName VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
			ThresholdTypeId VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
			FieldId SMALLINT NULL,
			FieldName VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
			LowThreshold FLOAT NULL,
			HighThreshold FLOAT NULL,
			AbsoluteThreshold BIT NULL
		)
		
		DECLARE @Field TABLE
		(
			FieldId SMALLINT,
			FieldName VARCHAR(31) COLLATE DATABASE_DEFAULT
		)

		-- Insert the required fields into the result set.
		INSERT INTO @Field
			(FieldId, FieldName)
		SELECT @TonnesFieldId, 'Tonnes'
		UNION
		SELECT @VolumeFieldId, 'Volume'
		UNION
		SELECT Grade_Id, Grade_Name
		FROM dbo.Grade

		IF @iOnlyLocation = 1
		BEGIN

			SELECT TOP 1 @CurrentThresholdTypeId = ThresholdTypeId
			FROM dbo.BhpbioReportThresholdType
			WHERE ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL
			ORDER BY ThresholdTypeId ASC

			WHILE @CurrentThresholdTypeId IS NOT NULL
			BEGIN

			-- Obtain the location and threshold information for only this location id.
			INSERT INTO @Results
				(LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, LowThreshold, HighThreshold, AbsoluteThreshold)
			SELECT L.Location_Id, L.Description, TT.ThresholdTypeId, F.FieldId, F.FieldName, BRT.LowThreshold, BRT.HighThreshold, BRT.AbsoluteThreshold
			FROM @Field AS F
				INNER JOIN dbo.Location AS L
					ON (L.Location_Id = @iLocationId)
				INNER JOIN dbo.BhpbioReportThresholdType AS TT
					ON (TT.ThresholdTypeId = @CurrentThresholdTypeId)
				LEFT JOIN dbo.BhpbioReportThreshold AS BRT
					ON (L.Location_ID = BRT.LocationID
						AND TT.ThresholdTypeId = BRT.ThresholdTypeId
						AND BRT.FieldId = F.FieldID)

			SET @CurrentThresholdTypeId = (SELECT TOP 1 ThresholdTypeId
											FROM dbo.BhpbioReportThresholdType
											WHERE ThresholdTypeId > @CurrentThresholdTypeId
											AND (ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL)
											ORDER BY ThresholdTypeId ASC)
			
			END

		END

		IF @iOnlyInherited = 1 OR (@iOnlyInherited = 0 AND @iOnlyLocation = 0 )
		BEGIN
		
			SELECT TOP 1 @CurrentThresholdTypeId = ThresholdTypeId
			FROM dbo.BhpbioReportThresholdType
			WHERE ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL
			ORDER BY ThresholdTypeId ASC
					
			WHILE @CurrentThresholdTypeId IS NOT NULL
			BEGIN

					
				SET @CurrentLocation = @iLocationId
				
				-- Cycle up through the parents until we find a location which has values we get to 
				--- the top.
				WHILE @CurrentLocation IS NOT NULL
				BEGIN

					IF EXISTS (	SELECT TOP 1 1 
								FROM dbo.BhpbioReportThreshold 
								WHERE LocationId = @CurrentLocation
									AND (ThresholdTypeId = @CurrentThresholdTypeId)
							  )
					BEGIN

						-- If records exist at this level do not return anything as we are not inheriting.
						IF @CurrentLocation <> @iLocationId OR (@iOnlyLocation = 0 AND @iOnlyInherited = 0)
						BEGIN
							-- Update the records based on this location.
							INSERT INTO @Results
								(LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, LowThreshold, HighThreshold, AbsoluteThreshold)
							SELECT L.Location_Id, L.Description, TT.ThresholdTypeId, F.FieldId, F.FieldName, BRT.LowThreshold, BRT.HighThreshold, BRT.AbsoluteThreshold
							FROM @Field AS F
								INNER JOIN dbo.Location AS L
									ON (L.Location_Id = @CurrentLocation)
								INNER JOIN dbo.BhpbioReportThresholdType AS TT
									ON (TT.ThresholdTypeId = @CurrentThresholdTypeId)
								LEFT JOIN dbo.BhpbioReportThreshold AS BRT
									ON (L.Location_ID = BRT.LocationID
										AND TT.ThresholdTypeId = BRT.ThresholdTypeId
										AND BRT.FieldId = F.FieldID)
						END
						
						-- We have found our match so finish the looping
						SET @CurrentLocation = NULL
					END
				
					IF NOT EXISTS (SELECT 1 FROM dbo.Location WHERE Location_Id = @CurrentLocation)
					BEGIN
						SET @CurrentLocation = NULL
					END
					
					-- Cycle up the parent heirachy
					SELECT @CurrentLocation = L.Parent_Location_Id
					FROM dbo.Location AS L
					WHERE L.Location_Id = @CurrentLocation
				END

				SET @CurrentThresholdTypeId = (SELECT TOP 1 ThresholdTypeId
												FROM dbo.BhpbioReportThresholdType
												WHERE ThresholdTypeId > @CurrentThresholdTypeId
												AND (ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL)
												ORDER BY ThresholdTypeId ASC)


			
			END
											
		END
		
		IF (@iOnlyInherited = 0 AND @iOnlyLocation = 0 )
		BEGIN
		
			SELECT TOP 1 @CurrentThresholdTypeId = ThresholdTypeId
			FROM dbo.BhpbioReportThresholdType
			WHERE ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL
			ORDER BY ThresholdTypeId ASC
					
			WHILE @CurrentThresholdTypeId IS NOT NULL
			BEGIN
	
				IF NOT EXISTS(SELECT 1 FROM @Results WHERE ThresholdTypeId = @CurrentThresholdTypeId)	
				BEGIN		
		
				-- Obtain the location and threshold information for only this location id.
				INSERT INTO @Results
					(LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, LowThreshold, HighThreshold, AbsoluteThreshold)
				SELECT L.Location_Id, L.Description, TT.ThresholdTypeId, F.FieldId, F.FieldName,
					NULL, 
					NULL, 
					0
				FROM @Field AS F
					INNER JOIN dbo.Location AS L
						ON (L.Location_Id = @iLocationId)
					INNER JOIN dbo.BhpbioReportThresholdType AS TT
						ON (TT.ThresholdTypeId = @CurrentThresholdTypeId)
						
				END
				
				SET @CurrentThresholdTypeId = (SELECT TOP 1 ThresholdTypeId
								FROM dbo.BhpbioReportThresholdType
								WHERE ThresholdTypeId > @CurrentThresholdTypeId
								AND (ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL)
								ORDER BY ThresholdTypeId ASC)
			
			END
		END
		
		SELECT LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, LowThreshold, HighThreshold, AbsoluteThreshold
		FROM @Results
			
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioReportThresholdList TO BhpbioGenericManager

GO

--EXEC dbo.GetBhpbioReportThresholdList @iLocationId = 1, @iThresholdTypeId = null, @iOnlyInherited = 0, @iOnlyLocation = 0

