DELETE FROM DataSeries.SeriesTypeGroup 
WHERE Id like '%F2DensityFactor%'

GO

UPDATE stat 
SET StringValue = 'RollingAverage' 
FROM DataSeries.SeriesTypeAttribute stat 
WHERE stat.SeriesTypeId = 'HaulageToOreVsNonOre_Tonnes'
	AND stat.Name = 'OutlierConfiguration_ProjectedValueMethod'

GO

UPDATE stat
SET stat.BooleanValue = 1
FROM DataSeries.SeriesTypeAttribute stat
WHERE stat.SeriesTypeId = 'BeneRatio_Fe_PS_MT' 
	AND stat.Name = 'ByProductSize'

GO
