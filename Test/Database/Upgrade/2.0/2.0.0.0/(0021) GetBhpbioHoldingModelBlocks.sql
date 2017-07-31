IF OBJECT_ID('dbo.GetBhpbioHoldingModelBlocks') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioHoldingModelBlocks
GO

CREATE PROCEDURE dbo.GetBhpbioHoldingModelBlocks
(
	@iSite VARCHAR(9),
	@iPit VARCHAR(10),
	@iBench VARCHAR(4)
)
AS
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY
		SELECT
			-- key fields
			b.Site, b.Orebody,
			COALESCE(b.MQ2PitCode, b.Pit) AS Pit,
			b.Bench, b.PatternNumber, b.BlockName,
			m.ModelName, m.ModelOreType,
			-- attribute fields
			b.BlockNumber, b.GeoType, b.BlockedDate, b.BlastedDate,
			b.CentroidEasting, b.CentroidNorthing,
			(
				CASE
					WHEN b.CentroidRL = 0 THEN NULL
					ELSE b.CentroidRL
				END
			) AS CentroidRL,
			m.ModelTonnes, 
			m.LumpPercent as ModelLumpPercent, 
			m.LastModifiedUser, 
			m.LastModifiedDate,
			(
				SELECT p.Number,
					p.Easting, p.Northing, p.RL
				FROM dbo.BhpbioBlastBlockPointHolding AS p
				WHERE p.BlockId = b.BlockId
					-- optimisation: only load polygon points for the geology model
					AND m.ModelName = 'Grade Control'
				FOR XML PATH, ELEMENTS, ROOT('Point')
			) AS Point,
			(
				SELECT GradeName, GradeValue, GradeLumpValue, GradeFinesValue
				FROM
					(
						SELECT GradeName, GradeValue, LumpValue as GradeLumpValue, FinesValue as GradeFinesValue
						FROM dbo.BhpbioBlastBlockModelGradeHolding AS g2
						WHERE g2.BlockId = b.BlockId
							AND g2.ModelName = m.ModelName
							AND g2.ModelOreType = m.ModelOreType
						UNION ALL
						SELECT 'Density', m2.ModelDensity AS Density, null as GradeLumpValue, null as GradeFinesValue
						FROM dbo.BhpbioBlastBlockModelHolding AS m2
						WHERE m2.BlockId = b.BlockId
							AND m2.ModelName = m.ModelName
							AND m2.ModelOreType = m.ModelOreType
					) AS gradesXml
				FOR XML PATH, ELEMENTS, ROOT('Grade')
			) AS Grade
		FROM dbo.BhpbioBlastBlockHolding AS b
			INNER JOIN dbo.BhpbioBlastBlockModelHolding AS m
				ON (b.BlockId = m.BlockId)
		WHERE b.Site = ISNULL(@iSite, b.Site)
			AND ISNULL(b.MQ2PitCode, b.Pit) = ISNULL(@iPit, ISNULL(b.MQ2PitCode, b.Pit))
			AND b.Bench = ISNULL(@iBench, b.Bench)
			-- these must not be NULL - otherwise we can't generate a key of any sort !
			AND b.Site IS NOT NULL  -- can't be null in source - but just in case
			AND COALESCE(b.MQ2PitCode, b.Pit) IS NOT NULL  -- can't be null in source - but just in case
			AND b.Bench IS NOT NULL  -- can't be null in source - but just in case
			AND b.BlockName IS NOT NULL  -- can't be null in source - but just in case
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioHoldingModelBlocks TO BhpbioGenericManager
GO