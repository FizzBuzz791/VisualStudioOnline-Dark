IF OBJECT_ID('dbo.GetBhpbioSampleStationList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStationList
GO 

CREATE PROCEDURE dbo.GetBhpbioSampleStationList
(
	@LocationId INT = 1,
	@ProductSize VARCHAR(15) = NULL
)
AS
BEGIN
	SELECT SS.Id, SS.Name, SS.Description, LParent.Name + '/' + L.Name AS Location, 
			SS.ProductSize AS [Product Size], SS.Weightometer_Id AS [Weightometer], 
			FLOOR(SST.CoverageTarget * 100) AS [Coverage Target], FLOOR(SST.CoverageWarning * 100) AS [Coverage Warning], 
			SST.RatioTarget AS [Ratio Target], SST.RatioWarning AS [Ratio Warning]
	FROM BhpbioSampleStation SS
	INNER JOIN Location L ON L.Location_Id = SS.Location_Id
	INNER JOIN Location LParent ON LParent.Location_Id = L.Parent_Location_Id
	OUTER APPLY 
		(SELECT TOP 1 * 
		 FROM BhpbioSampleStationTarget SST 
		 WHERE SST.SampleStation_Id = SS.Id
		 ORDER BY SST.StartDate) AS SST
	WHERE SS.ProductSize IN (SELECT Item FROM dbo.SplitString(@ProductSize, ','))
		AND SS.Location_Id IN (SELECT LocationId
							   FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', GETDATE(), GETDATE()))
	ORDER BY SS.Name
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioSampleStationList TO BhpbioGenericManager
GO