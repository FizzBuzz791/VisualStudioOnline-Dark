
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'DisplayNameSuffixAttribute', 'WeightometerId'
FROM DataSeries.SeriesType st
WHERE st.Id like '%Weight%'
AND NOT EXISTS (
	SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id and stat.Name = 'DisplayNameSuffixAttribute'
)
GO
