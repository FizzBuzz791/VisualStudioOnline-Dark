
-- THIS SCRIPT REMOVES CONFIGURATION OF THE MineProductionExpitEquivalent series where specified at the PIT level
-- MPEE should not be tracked at the pit level

BEGIN TRANSACTION

-- delete the points of related series
DELETE sa2d FROM DataSeries.SeriesPoint sa2d 
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue = 'PIT'
)

-- delete the attributes of the related series
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue = 'PIT'
) 

-- Delete the related series
DELETE s2d
FROM DataSeries.SeriesType st 
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
	INNER JOIN DataSeries.Series s2d ON s2d.PrimaryRelatedSeriesId = s.Id
	LEFT JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue = 'PIT'

-- delete the points
DELETE sa2d FROM DataSeries.SeriesPoint sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue = 'PIT'
)

-- delete the attributes
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue = 'PIT'
) 

-- Delete the series
DELETE s
FROM DataSeries.SeriesType st 
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
	LEFT JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
WHERE st.Id like 'MineProductionExpitEqulivent%' AND satt.StringValue IS NULL


COMMIT TRANSACTION

GO
