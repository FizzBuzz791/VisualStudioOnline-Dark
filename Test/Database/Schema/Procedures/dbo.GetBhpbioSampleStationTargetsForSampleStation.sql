IF OBJECT_ID('dbo.GetBhpbioSampleStationTargetsForSampleStation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStationTargetsForSampleStation
GO 

CREATE PROCEDURE dbo.GetBhpbioSampleStationTargetsForSampleStation
(
	@SampleStationId INT
)
AS
BEGIN
	DECLARE @sampleStationTargets TABLE (
		TempId INT IDENTITY (1,1),
		Id INT NOT NULL,
		SampleStation_Id INT NOT NULL,
		StartDate DATETIME NOT NULL,
		EndDate DATETIME NULL,
		CoverageTarget INT NOT NULL,
		CoverageWarning INT NOT NULL,
		RatioTarget INT NOT NULL,
		RatioWarning INT NOT NULL
	)

	INSERT INTO @sampleStationTargets (Id, SampleStation_Id, StartDate, CoverageTarget, CoverageWarning, RatioTarget, RatioWarning)
	SELECT SST.Id, SST.SampleStation_Id, SST.StartDate, SST.CoverageTarget*100, SST.CoverageWarning*100, SST.RatioTarget, SST.RatioWarning
	FROM BhpbioSampleStationTarget SST
	WHERE SST.SampleStation_Id = @SampleStationId
	ORDER BY SST.StartDate

	UPDATE S1
	SET S1.EndDate = DATEADD(MILLISECOND, -100, S2.StartDate)
	FROM @sampleStationTargets S1
	INNER JOIN @sampleStationTargets S2 ON S2.TempId = S1.TempId + 1

	SELECT * FROM @sampleStationTargets ORDER BY StartDate DESC
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioSampleStationTargetsForSampleStation TO BhpbioGenericManager
GO