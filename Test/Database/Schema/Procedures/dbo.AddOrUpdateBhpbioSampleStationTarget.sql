IF OBJECT_ID('dbo.AddOrUpdateBhpbioSampleStationTarget') IS NOT NULL 
     DROP PROCEDURE dbo.AddOrUpdateBhpbioSampleStationTarget
GO 

CREATE PROCEDURE dbo.AddOrUpdateBhpbioSampleStationTarget
(
	@SampleStation_Id INT,
	@StartDate DATE,
	@CoverageTarget DECIMAL,
	@CoverageWarning DECIMAL,
	@RatioTarget INT,
	@RatioWarning INT,
	@EndDate DATE = NULL,
	@Id INT = NULL
)
AS
BEGIN
	IF @Id IS NULL
		INSERT INTO dbo.BhpbioSampleStationTarget (SampleStation_Id, StartDate, EndDate, CoverageTarget, CoverageWarning, RatioTarget, RatioWarning)
		VALUES (@SampleStation_Id, @StartDate, @EndDate, @CoverageTarget, @CoverageWarning, @RatioTarget, @RatioWarning)
	ELSE
		UPDATE dbo.BhpbioSampleStationTarget SET
			SampleStation_Id = @SampleStation_Id,
			StartDate = @StartDate,
			EndDate = @EndDate,
			CoverageTarget = @CoverageTarget,
			CoverageWarning = @CoverageWarning,
			RatioTarget = @RatioTarget,
			RatioWarning = @RatioWarning
		WHERE Id = @Id
END
GO

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioSampleStation TO BhpbioGenericManager
GO