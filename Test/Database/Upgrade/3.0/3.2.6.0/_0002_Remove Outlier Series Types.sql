-- THIS SCRIPT REMOVES UNNECCESSARY SERIES TYPES
BEGIN TRANSACTION

DECLARE @seriesTypesToRemove TABLE (
	SeriesTypeId VARCHAR(100)
)

INSERT INTO @seriesTypesToRemove(SeriesTypeId)
	SELECT DISTINCT st.Id FROM DataSeries.SeriesType st
	WHERE st.Id IN ('F25Factor_Fe_PS','F25Factor_Grade_PS','F2DensityFactor_Tonnes_PS','OreForRail_Fe_PS','OreForRail_Grade_PS','PortStockpileDelta_Fe_PS','PortStockpileDelta_Grade_PS')
	UNION
	SELECT DISTINCT st.Id FROM DataSeries.SeriesType st
	WHERE st.Id like 'PIT[_]%'
	UNION
	SELECT DISTINCT st.Id FROM DataSeries.SeriesType st
	WHERE st.Id like 'SITE[_]%'
	UNION
	SELECT DISTINCT st.Id FROM DataSeries.SeriesType st
	WHERE st.Id like 'HUB[_]%'
	UNION
	SELECT DISTINCT st.Id FROM DataSeries.SeriesType st
	WHERE st.Id like 'COMPANY[_]%'

-- delete the points of series types about to be removed
DELETE sa2d FROM DataSeries.SeriesPoint sa2d 
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM @seriesTypesToRemove st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId
)

-- delete the attributes of the related series
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM @seriesTypesToRemove st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId
)

-- Delete the related series
DELETE s2d
FROM @seriesTypesToRemove st 
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId
	INNER JOIN DataSeries.Series s2d ON s2d.PrimaryRelatedSeriesId = s.Id


-- delete the points
DELETE sa2d FROM DataSeries.SeriesPoint sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM @seriesTypesToRemove st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId
)

-- delete the attributes
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM @seriesTypesToRemove st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId
) 

-- Delete the series
DELETE s
FROM @seriesTypesToRemove st
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.SeriesTypeId

-- Delete the series type attributes
DELETE stat
FROM @seriesTypesToRemove st
	INNER JOIN DataSeries.SeriesTypeAttribute stat ON stat.SeriesTypeId = st.SeriesTypeId


-- Delete the series type group membership
DELETE stgm
FROM @seriesTypesToRemove st
	INNER JOIN DataSeries.SeriesTypeGroupMembership stgm ON stgm.SeriesTypeId = st.SeriesTypeId


-- Delete the series type
DELETE sty
FROM @seriesTypesToRemove st
	INNER JOIN DataSeries.SeriesType sty ON sty.Id = st.SeriesTypeId


COMMIT TRANSACTION




GO

