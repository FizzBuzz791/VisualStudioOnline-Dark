IF OBJECT_ID('dbo.GetBhpbioReportFactorProperties') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportFactorProperties
GO 

CREATE PROCEDURE dbo.GetBhpbioReportFactorProperties
(
	@iLocationId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		DECLARE @Results TABLE
		(
			LocationId INT NULL,
			LocationName VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
			ThresholdTypeId VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
			FieldId SMALLINT NULL,
			FieldName VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
			LowThreshold FLOAT NULL,
			HighThreshold FLOAT NULL,
			AbsoluteThreshold BIT NULL,
			DisplayPrecision INT NULL,
			DisplayFormat VARCHAR(10) COLLATE DATABASE_DEFAULT NULL
		)
		DECLARE @LocationId INT
		
		SET @LocationId = @iLocationId
		IF @LocationId <= 0 OR @LocationId IS NULL
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.Location
			WHERE Parent_Location_Id IS NULL
		END

		INSERT INTO @Results
			(LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, LowThreshold, HighThreshold, AbsoluteThreshold)
		EXEC dbo.GetBhpbioReportThresholdList
			@iLocationId = @LocationId,
			@iThresholdTypeId = NULL,
			@iOnlyInherited = 0,
			@iOnlyLocation = 0
			
		UPDATE @Results
		SET DisplayPrecision = 0,
			DisplayFormat = 'DP'
			
		UPDATE R
		SET R.DisplayPrecision = G.Display_Precision,
			R.DisplayFormat = G.Display_Format
		FROM @Results AS R
			INNER JOIN dbo.Grade AS G
				ON R.FieldId = G.Grade_Id

		SELECT LocationId, LocationName, ThresholdTypeId, FieldId, FieldName, 
			LowThreshold, HighThreshold, AbsoluteThreshold, DisplayPrecision, DisplayFormat
		FROM @Results
			
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioReportFactorProperties TO BhpbioGenericManager
GO

--exec dbo.GetBhpbioReportFactorProperties 0

			