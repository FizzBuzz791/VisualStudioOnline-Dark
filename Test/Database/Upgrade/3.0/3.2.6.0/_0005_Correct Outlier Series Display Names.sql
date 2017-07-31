UPDATE DataSeries.SeriesType
SET Name = REPLACE(Name,'F15','F1.5')
WHERE Name like '%F15%'
GO

UPDATE DataSeries.SeriesType
SET Name = REPLACE(Name,'F25','F2.5')
WHERE Name like '%F25%'
GO

UPDATE stat
SET stat.StringValue = REPLACE(stat.StringValue, 'F15','F1.5')
FROM DataSeries.SeriesTypeAttribute stat
WHERE stat.Name = 'OutlierConfiguration_Description'
	AND stat.StringValue like 'F15%'
GO

UPDATE stat
SET stat.StringValue = REPLACE(stat.StringValue, 'F25','F2.5')
FROM DataSeries.SeriesTypeAttribute stat
WHERE stat.Name = 'OutlierConfiguration_Description'
	AND stat.StringValue like 'F25%'
GO