IF OBJECT_ID('dbo.GetBhpbioOutlierAnalysisPoints') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioOutlierAnalysisPoints
GO 
  
CREATE PROCEDURE dbo.GetBhpbioOutlierAnalysisPoints
(
	@iSeriesId INTEGER,
	@iDateFrom DATETIME,
	@iDateTo DATETIME
)
WITH ENCRYPTION
AS
BEGIN 

	-- Determine the month prior to the system start... this is needed to calculate ordinal values
	DECLARE @monthPriorSystemStart DATETIME
	
	SELECT @monthPriorSystemStart = DateAdd(month, -1,Convert(DateTime, Value))
	FROM Setting
	WHERE Setting_Id = 'SYSTEM_START_DATE'
		
	SELECT
	   st.Name as SeriesTypeName, 
	   DateAdd(month, sp.Ordinal, @monthPriorSystemStart) as Month,
	   seriesLocationTypeAtt.StringValue as LocationType,
	   pl.Name as ParentLocationName,
	   l.Name as LocationName,
	   CASE WHEN lt.Description ='PIT' THEN pl.Name + ' '+ l.Name ELSE l.Name END as DisplayLocationName,
	   productSizeAtt.StringValue as ProductSize, -- LUMP, FINES, TOTAL etc
	   materialTypeAtt.IntegerValue as MaterialTypeId,
	   attributeAtt.StringValue as Attribute, -- this is the name of the attribute this series relates to (Tonnes, Density, Fe, P, SiO2 etc)
	   gradeAtt.StringValue as Grade, -- only filled in when relevant
	   projectionMethodAtt.StringValue as ProjectionMethod,
	   
		outStandardDeviationPoint.Value AS  SeriesSD, -- the size of the standard deviation of this series at the ordinal
				
		-- Value
		sp.Value AS  Value,
				
		-- Projected Value
		CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END
			AS  ProjectedValue,
				
		-- Deviation
		sp.Value - CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END
			AS Deviation,

	   outStandardisedDeviationPoint.Value AS DeviationInSD,

	   CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END
			+ outlierThresholdAtt.DoubleValue * outStandardDeviationPoint.Value
		AS UpperDetectionLimit,

	   CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END 
			- outlierThresholdAtt.DoubleValue * outStandardDeviationPoint.Value
			AS LowerDetectionLimit,

	   outRollingAverageProjectionPoint.Value as Mean
	FROM DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership stgm ON stgm.SeriesTypeId = st.Id AND stgm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup' -- ie series type is for series under outlier anaylsis
		INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id -- join in the actual series

		-- get the outlier description for the series type
		LEFT JOIN DataSeries.SeriesTypeAttribute outlierDescAtt ON outlierDescAtt.SeriesTypeId = st.Id AND outlierDescAtt.Name = 'OutlierConfiguration_Description'
		LEFT JOIN DataSeries.SeriesTypeAttribute outlierPriorityAtt ON outlierPriorityAtt.SeriesTypeId = st.Id AND outlierPriorityAtt.Name = 'OutlierConfiguration_Priority'
		LEFT JOIN DataSeries.SeriesTypeAttribute outlierThresholdAtt ON outlierThresholdAtt.SeriesTypeId = st.Id AND outlierThresholdAtt.Name = 'OutlierConfiguration_OutlierThreshold'
	    LEFT JOIN DataSeries.SeriesTypeAttribute calculationIdAtt ON calculationIdAtt.SeriesTypeId = st.Id AND calculationIdAtt.Name = 'CalculationId'

		LEFT JOIN DataSeries.SeriesTypeAttribute projectionMethodAtt ON projectionMethodAtt.SeriesTypeId = st.Id AND projectionMethodAtt.Name = 'OutlierConfiguration_ProjectedValueMethod'

		LEFT JOIN DataSeries.SeriesAttribute seriesLocationAtt ON seriesLocationAtt.SeriesId = s.Id AND seriesLocationAtt.Name = 'LocationId' -- join in the location Id
		LEFT JOIN DataSeries.SeriesAttribute seriesLocationTypeAtt ON seriesLocationTypeAtt.SeriesId = s.Id AND seriesLocationTypeAtt.Name = 'LocationType' -- join in the location type
		LEFT JOIN DataSeries.SeriesAttribute productSizeAtt ON productSizeAtt.SeriesId = s.Id AND productSizeAtt.Name = 'ProductSize' -- join the product size
		LEFT JOIN DataSeries.SeriesAttribute materialTypeAtt ON materialTypeAtt.SeriesId = s.Id AND materialTypeAtt.Name = 'MaterialTypeId' -- join in the material type
		LEFT JOIN DataSeries.SeriesTypeAttribute attributeAtt ON attributeAtt.SeriesTypeId = s.SeriesTypeId AND attributeAtt.Name = 'Attribute' 

		LEFT JOIN DataSeries.SeriesAttribute gradeAtt ON gradeAtt.SeriesId = s.Id AND gradeAtt.Name = 'Grade' 

		-- get the actual point value for this series
		INNER JOIN DataSeries.SeriesPoint sp ON sp.SeriesId = s.Id
	
		-- now get the Outlier series related to each primary data series
		LEFT JOIN DataSeries.Series outLinearProjectionSeries ON outLinearProjectionSeries.SeriesTypeId = 'OD_LinearProjection' AND outLinearProjectionSeries.PrimaryRelatedSeriesId = s.Id
		LEFT JOIN DataSeries.Series outLinearProjectionInterceptSeries ON outLinearProjectionInterceptSeries.SeriesTypeId = 'OD_LinearProjectionIntercept' AND outLinearProjectionInterceptSeries.PrimaryRelatedSeriesId = s.Id
		LEFT JOIN DataSeries.Series outLinearProjectionSlopeSeries ON outLinearProjectionSlopeSeries.SeriesTypeId = 'OD_LinearProjectionSlope' AND outLinearProjectionSlopeSeries.PrimaryRelatedSeriesId = s.Id
		LEFT JOIN DataSeries.Series outStandardDeviationSeries ON outStandardDeviationSeries.SeriesTypeId = 'OD_OutlierStandardDeviation' AND outStandardDeviationSeries.PrimaryRelatedSeriesId = s.Id
		LEFT JOIN DataSeries.Series outStandardisedDeviationSeries ON outStandardisedDeviationSeries.SeriesTypeId = 'OD_OutllierStandardisedDeviation' AND outStandardisedDeviationSeries.PrimaryRelatedSeriesId = s.Id
		LEFT JOIN DataSeries.Series outRollingAverageProjectionSeries ON outRollingAverageProjectionSeries.SeriesTypeId = 'OD_RollingAverageProjection' AND outRollingAverageProjectionSeries.PrimaryRelatedSeriesId = s.Id

		-- now get the Outlier series points
		LEFT JOIN DataSeries.SeriesPoint outLinearProjectionPoint ON outLinearProjectionPoint.SeriesId = outLinearProjectionSeries.Id AND outLinearProjectionPoint.Ordinal = sp.Ordinal
		LEFT JOIN DataSeries.SeriesPoint outLinearProjectionInterceptPoint ON outLinearProjectionInterceptPoint.SeriesId = outLinearProjectionInterceptSeries.Id AND outLinearProjectionInterceptPoint.Ordinal = sp.Ordinal
		LEFT JOIN DataSeries.SeriesPoint outLinearProjectionSlopePoint ON outLinearProjectionSlopePoint.SeriesId = outLinearProjectionSlopeSeries.Id AND outLinearProjectionSlopePoint.Ordinal = sp.Ordinal
		LEFT JOIN DataSeries.SeriesPoint outStandardDeviationPoint ON outStandardDeviationPoint.SeriesId = outStandardDeviationSeries.Id AND outStandardDeviationPoint.Ordinal = sp.Ordinal
		LEFT JOIN DataSeries.SeriesPoint outStandardisedDeviationPoint ON outStandardisedDeviationPoint.SeriesId = outStandardisedDeviationSeries.Id AND outStandardisedDeviationPoint.Ordinal = sp.Ordinal
		LEFT JOIN DataSeries.SeriesPoint outRollingAverageProjectionPoint ON outRollingAverageProjectionPoint.SeriesId = outRollingAverageProjectionSeries.Id AND outRollingAverageProjectionPoint.Ordinal = sp.Ordinal
	
		INNER JOIN Location l ON l.Location_Id = seriesLocationAtt.IntegerValue
		INNER JOIN LocationType lt ON lt.Location_Type_Id = l.Location_Type_Id
		LEFT JOIN Location pl ON pl.Location_Id = l.Parent_Location_Id
	
	WHERE 
		s.Id = @iSeriesId
		AND DateAdd(month, sp.Ordinal, @monthPriorSystemStart) >= @iDateFrom
		AND DateAdd(month, sp.Ordinal, @monthPriorSystemStart) <= @iDateTo
	ORDER BY sp.Ordinal
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioOutlierAnalysisPoints TO BhpbioGenericManager
GO