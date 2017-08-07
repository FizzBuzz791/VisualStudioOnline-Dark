IF OBJECT_ID('dbo.GetBhpbioSampleStationList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStationList
GO 

CREATE PROCEDURE dbo.GetBhpbioSampleStationList
(
	@LocationId INT = 1,
	@ProductSize VARCHAR = NULL
)
AS
BEGIN
	IF @ProductSize IS NULL OR @ProductSize = 'LUMP,FINES,ROM'
		SELECT *
		FROM dbo.BhpbioSampleStation
		WHERE ProductSize IN ('LUMP', 'FINES', 'ROM')
			AND Location_Id IN (SELECT LocationId
								FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', '2009-01-01', GETDATE()))
	ELSE IF @ProductSize = 'LUMP,FINES'
		SELECT *
		FROM dbo.BhpbioSampleStation
		WHERE ProductSize IN ('LUMP', 'FINES')
			AND Location_Id IN (SELECT LocationId
								FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', '2009-01-01', GETDATE()))
	ELSE IF @ProductSize = 'LUMP,ROM'
		SELECT *
		FROM dbo.BhpbioSampleStation
		WHERE ProductSize IN ('LUMP', 'ROM')
			AND Location_Id IN (SELECT LocationId
								FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', '2009-01-01', GETDATE()))
	ELSE IF @ProductSize = 'FINES,ROM'
		SELECT *
		FROM dbo.BhpbioSampleStation
		WHERE ProductSize IN ('FINES', 'ROM')
			AND Location_Id IN (SELECT LocationId
								FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', '2009-01-01', GETDATE()))
	ELSE
		SELECT *
		FROM dbo.BhpbioSampleStation
		WHERE ProductSize = @ProductSize
			AND Location_Id IN (SELECT LocationId
								FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, 'SITE', '2009-01-01', GETDATE()))
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioSampleStationList TO BhpbioGenericManager
GO