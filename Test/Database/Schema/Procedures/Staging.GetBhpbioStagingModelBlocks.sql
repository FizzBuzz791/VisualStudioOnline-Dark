IF OBJECT_ID('Staging.GetBhpbioStagingModelBlocks') IS NOT NULL
	DROP PROCEDURE Staging.GetBhpbioStagingModelBlocks
GO

CREATE PROCEDURE Staging.GetBhpbioStagingModelBlocks
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
			m.ModelName, m.ModelOreType, b.BlockExternalSystemId,
			m.ModelFilename,
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
			m.ModelVolume,
			m.LumpPercentAsDropped as ModelLumpPercentAsDropped, 
			m.LumpPercentAsShipped as ModelLumpPercentAsShipped, 
			m.LastModifiedUser, 
			m.LastModifiedDate,
			(
				SELECT p.Number,
					p.Easting, p.Northing, p.RL
				FROM Staging.BhpbioStageBlockPoint AS p
				WHERE p.BlockId = b.BlockId
					-- optimisation: only load polygon points for the geology model
					AND m.ModelName like 'Grade Control'
				FOR XML PATH, ELEMENTS, ROOT('Point')
			) AS Point,
			(
				SELECT GeometType, GradeName, GradeValue, GradeLumpValue, GradeFinesValue
				FROM
					(
						SELECT GeometType, GradeName, GradeValue, LumpValue as GradeLumpValue, FinesValue as GradeFinesValue
						FROM Staging.BhpbioStageBlockModelGrade AS g2
							INNER JOIN dbo.Grade grade ON grade.Grade_Name = g2.GradeName
						WHERE g2.BlockId = b.BlockId
							AND g2.ModelName = m.ModelName
							AND g2.ModelOreType = m.ModelOreType
						UNION ALL
						SELECT 'NA' as GeometType, 'Density' as GradeName, m2.ModelDensity AS Density, null as GradeLumpValue, null as GradeFinesValue
						FROM Staging.BhpbioStageBlockModel AS m2
						WHERE m2.BlockId = b.BlockId
							AND m2.ModelName = m.ModelName
							AND m2.ModelOreType = m.ModelOreType
						UNION ALL
						-- special case ensure there is a placeholder head grade/ NA Ultrafines value
						SELECT 'NA' as GeometType, 'Ultrafines' as GradeName, 0 AS GradeValue, null as GradeLumpValue, null as GradeFinesValue
						FROM Staging.BhpbioStageBlockModel AS m3uf
							LEFT JOIN Staging.BhpbioStageBlockModelGrade AS guf ON guf.BlockId = m3uf.BlockId AND guf.ModelName = m3uf.ModelName AND guf.ModelOreType = m3uf.ModelOreType AND guf.GradeName = 'Ultrafines' AND IsNull(guf.GeometType,'NA') = 'NA'
						WHERE m3uf.BlockId = b.BlockId
							AND m3uf.ModelName = m.ModelName
							AND m3uf.ModelOreType = m.ModelOreType
							AND guf.GradeName IS NULL -- ie. no matched grade row
							AND m3uf.ModelName = 'Grade Control'  -- grade control only
					) AS gradesXml
				FOR XML PATH, ELEMENTS, ROOT('Grade')
			) AS Grade,
			(
				Select
					rc.ResourceClassification,
					rc.Percentage
				From Staging.StageBlockModelResourceClassification rc
					Inner Join Staging.StageBlockModel mb
						On mb.BlockModelId = rc.BlockModelId
				Where mb.BlockId =  b.BlockId
					And mb.BlockModelName = m.ModelName
					And mb.MaterialTypeName = m.ModelOreType
				FOR XML PATH, ELEMENTS, ROOT('ResourceClassification')
			) As ResourceClassification
			
		FROM Staging.BhpbioStageBlock AS b
			INNER JOIN Staging.BhpbioStageBlockModel AS m
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

GRANT EXECUTE ON Staging.GetBhpbioStagingModelBlocks TO BhpbioGenericManager
GO
