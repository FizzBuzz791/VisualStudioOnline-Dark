IF OBJECT_ID('dbo.GetBhpbioOutlierAnalysisSeriesAttributes') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioOutlierAnalysisSeriesAttributes
GO 
  
CREATE PROCEDURE dbo.GetBhpbioOutlierAnalysisSeriesAttributes
(
	@iSeriesId INTEGER
)
WITH ENCRYPTION
AS
BEGIN 
	SELECT
	   s.SeriesTypeId,
	   st.Name + CASE WHEN displayNameSuffixVal.StringValue IS NOT NULL THEN ' (' + displayNameSuffixVal.StringValue + ')' ELSE '' END as SeriesTypeName, 
	   seriesLocationTypeAtt.StringValue as LocationType,
	   pl.Name as ParentLocationName,
	   l.Name as LocationName,
	   productSizeAtt.StringValue as ProductSize, -- LUMP, FINES, TOTAL etc
	   mt.Description as MaterialType,
	   attributeAtt.StringValue as Attribute, -- this is the name of the attribute this series relates to (Tonnes, Density, Fe, P, SiO2 etc)
	   gradeAtt.StringValue as Grade, -- only filled in when relevant
	   projectionMethodAtt.StringValue as ProjectionMethod,
	   outlierThresholdAtt.DoubleValue as Threshold
	FROM DataSeries.Series s
		INNER JOIN  DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
		LEFT JOIN DataSeries.SeriesTypeAttribute projectionMethodAtt ON projectionMethodAtt.SeriesTypeId = st.Id AND projectionMethodAtt.Name = 'OutlierConfiguration_ProjectedValueMethod'
		LEFT JOIN DataSeries.SeriesAttribute seriesLocationAtt ON seriesLocationAtt.SeriesId = s.Id AND seriesLocationAtt.Name = 'LocationId' -- join in the location Id
		LEFT JOIN DataSeries.SeriesAttribute seriesLocationTypeAtt ON seriesLocationTypeAtt.SeriesId = s.Id AND seriesLocationTypeAtt.Name = 'LocationType' -- join in the location type
		LEFT JOIN DataSeries.SeriesAttribute productSizeAtt ON productSizeAtt.SeriesId = s.Id AND productSizeAtt.Name = 'ProductSize' -- join the product size
		LEFT JOIN DataSeries.SeriesAttribute materialTypeAtt ON materialTypeAtt.SeriesId = s.Id AND materialTypeAtt.Name = 'MaterialTypeId' -- join in the material type
		LEFT JOIN DataSeries.SeriesTypeAttribute attributeAtt ON attributeAtt.SeriesTypeId = s.SeriesTypeId AND attributeAtt.Name = 'Attribute' 
		LEFT JOIN DataSeries.SeriesTypeAttribute displayNameSuffixAtt ON displayNameSuffixAtt.SeriesTypeId = st.Id AND displayNameSuffixAtt.Name = 'DisplayNameSuffixAttribute'
		LEFT JOIN DataSeries.SeriesAttribute displayNameSuffixVal ON displayNameSuffixVal.SeriesId = s.Id AND displayNameSuffixVal.Name = displayNameSuffixAtt.StringValue
		LEFT JOIN DataSeries.SeriesAttribute gradeAtt ON gradeAtt.SeriesId = s.Id AND gradeAtt.Name = 'Grade' 
		LEFT JOIN MaterialType mt ON mt.Material_Type_Id = materialTypeAtt.IntegerValue
		LEFT JOIN DataSeries.SeriesTypeAttribute outlierThresholdAtt ON outlierThresholdAtt.SeriesTypeId = st.Id AND outlierThresholdAtt.Name = 'OutlierConfiguration_OutlierThreshold'
		INNER JOIN Location l ON l.Location_Id = seriesLocationAtt.IntegerValue
		INNER JOIN LocationType lt ON lt.Location_Type_Id = l.Location_Type_Id
		LEFT JOIN Location pl ON pl.Location_Id = l.Parent_Location_Id
	WHERE 
		s.Id = @iSeriesId
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioOutlierAnalysisSeriesAttributes TO BhpbioGenericManager
GO

