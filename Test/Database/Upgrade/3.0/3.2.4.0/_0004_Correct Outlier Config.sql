-- Make sure that the site based series types are really tagged as Site and above
UPDATE statt
	SET statt.StringValue = 'Site and above'
FROM DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
WHERE st.Id IN (
	'F2Factor_Fe_PS',
	'F2Factor_Grade_PS',
	'F2Factor_Tonnes_PS',
	'MineProductionActuals_Fe_PS',
	'MineProductionActuals_Fe_PS_MT',
	'MineProductionActuals_Grade_PS',
	'MineProductionActuals_Grade_PS_MT',
	'MineProductionActuals_Tonnes_PS',
	'MineProductionActuals_Tonnes_PS_MT',
	'MineProductionExpitEqulivent_Fe_PS',
	'MineProductionExpitEqulivent_Fe_PS_MT',
	'MineProductionExpitEqulivent_Grade_PS',
	'MineProductionExpitEqulivent_Grade_PS_MT',
	'MineProductionExpitEqulivent_Tonnes_PS',
	'MineProductionExpitEqulivent_Tonnes_PS_MT'
)
GO

-- THIS SCRIPT REMOVES DATA AT THE PIT AND SITE LEVEL WHERE THE SERIES TYPES ARE RELEVANT ONLY AT HIGHER LEVELS
BEGIN TRANSACTION

-- delete the points of related series
DELETE sa2d FROM DataSeries.SeriesPoint sa2d 
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE (
				(statt.StringValue = 'Site and above' AND satt.StringValue = 'PIT')
		    OR	(statt.StringValue = 'Hub and above' AND satt.StringValue IN ('PIT', 'SITE'))
		  )
)

-- delete the attributes of the related series
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d
	INNER JOIN DataSeries.Series s2d ON s2d.Id = sa2d.SeriesId
	WHERE s2d.PrimaryRelatedSeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	WHERE (
				(statt.StringValue = 'Site and above' AND satt.StringValue = 'PIT')
		    OR	(statt.StringValue = 'Hub and above' AND satt.StringValue IN ('PIT', 'SITE'))
		  )
) 

-- Delete the related series
DELETE s2d
FROM DataSeries.SeriesType st 
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
	INNER JOIN DataSeries.Series s2d ON s2d.PrimaryRelatedSeriesId = s.Id
	LEFT JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
WHERE (
				(statt.StringValue = 'Site and above' AND satt.StringValue = 'PIT')
		    OR	(statt.StringValue = 'Hub and above' AND satt.StringValue IN ('PIT', 'SITE'))
	  )

-- delete the points
DELETE sa2d FROM DataSeries.SeriesPoint sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
		INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
	WHERE 
		(
				(statt.StringValue = 'Site and above' AND satt.StringValue = 'PIT')
		    OR	(statt.StringValue = 'Hub and above' AND satt.StringValue IN ('PIT', 'SITE'))
		)
)

-- delete the attributes
DELETE sa2d FROM DataSeries.SeriesAttribute sa2d WHERE sa2d.SeriesId IN 
(
	SELECT DISTINCT s.Id as SeriesId
	FROM DataSeries.SeriesType st 
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
		INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
	WHERE (
				(statt.StringValue = 'Site and above' AND satt.StringValue = 'PIT')
		    OR	(statt.StringValue = 'Hub and above' AND satt.StringValue IN ('PIT', 'SITE'))
		  )
) 

-- Delete the series
DELETE s
FROM DataSeries.SeriesType st 
	INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
	LEFT JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'LocationType'
	INNER JOIN DataSeries.SeriesTypeAttribute statt ON statt.SeriesTypeId = st.Id AND statt.Name = 'LocationType'
WHERE (statt.StringValue = 'Site and above' OR statt.StringValue = 'Hub and above') AND satt.StringValue IS NULL

COMMIT TRANSACTION

GO

