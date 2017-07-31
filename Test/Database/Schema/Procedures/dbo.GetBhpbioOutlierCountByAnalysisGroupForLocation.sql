IF OBJECT_ID('dbo.GetBhpbioOutlierCountByAnalysisGroupForLocation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioOutlierCountByAnalysisGroupForLocation
GO 
  
CREATE PROCEDURE dbo.GetBhpbioOutlierCountByAnalysisGroupForLocation
(
	@iStartDate DATETIME,
	@iEndDate DATETIME,
	@iLocationId INTEGER,
	@iProductSize VARCHAR(20) = Null,
	@iAttribute VARCHAR(20) = Null,
	@iMinimumDeviation FLOAT,
	@iIncludeDirectSubLocations BIT,
	@iIncludeAllSubLocations BIT
)
WITH ENCRYPTION
AS
BEGIN 

	-- Determine the month prior to the system start... this is needed to calculate ordinal values
	DECLARE @monthPriorSystemStart DATETIME
	
	SELECT @monthPriorSystemStart = DateAdd(month, -1,Convert(DateTime, Value))
	FROM Setting
	WHERE Setting_Id = 'SYSTEM_START_DATE'

	-- This script is a starting point for analysis queries of outlier data..  it needs to be reviewed and refined
	-- the joins and where conditions should be a guide..
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			IncludeStart DATETIME, 
			IncludeEnd DATETIME,
			PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
		)

		DECLARE @minLocationType AS VARCHAR(20)
		SET @minLocationType = 'Pit'

		IF @iIncludeAllSubLocations = 0
		BEGIN
			SELECT @minLocationType = CASE WHEN lt.Description = 'Pit' OR clt.Description IS NULL THEN 'Pit' ELSE clt.Description END
			FROM Location l
				INNER JOIN LocationType lt ON lt.Location_Type_Id = l.Location_Type_Id
				LEFT JOIN LocationType clt ON clt.Parent_Location_Type_Id = lt.Location_Type_Id
			WHERE l.Location_Id = @iLocationId
		END

		INSERT INTO @Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, @minLocationType, @iStartDate, @iEndDate)

		SELECT g.Id As AnalysisGroup, g.Name as AnalysisGroupName, outliersBySeriesType.ProductSize, outliersBySeriesType.MaterialTypeId, SUM(outliersBySeriesType.OutlierCount) as OutlierCount
		FROM DataSeries.SeriesTypeGroup g
		LEFT JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeGroupId = g.Id
		LEFT JOIN (
			-- how to select outliers for series
			SELECT s.SeriesTypeId, productSizeAtt.StringValue as ProductSize, materialTypeAtt.IntegerValue as MaterialTypeId, COUNT(*) as OutlierCount
			FROM DataSeries.SeriesType st
				INNER JOIN DataSeries.SeriesTypeGroupMembership stgm ON stgm.SeriesTypeId = st.Id AND stgm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup' -- ie series type is for series under outlier anaylsis
				INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
				LEFT JOIN DataSeries.SeriesAttribute seriesLocationAtt ON seriesLocationAtt.SeriesId = s.Id AND seriesLocationAtt.Name = 'LocationId' -- join in the location Id
				LEFT JOIN DataSeries.SeriesAttribute productSizeAtt ON productSizeAtt.SeriesId = s.Id AND productSizeAtt.Name = 'ProductSize' -- join the product size
				LEFT JOIN DataSeries.SeriesAttribute materialTypeAtt ON materialTypeAtt.SeriesId = s.Id AND materialTypeAtt.Name = 'MaterialTypeId' -- join the material type
				LEFT JOIN DataSeries.SeriesTypeAttribute attributeAtt ON attributeAtt.SeriesTypeId = s.SeriesTypeId AND attributeAtt.Name = 'Attribute' 
				LEFT JOIN DataSeries.SeriesAttribute gradeAtt ON gradeAtt.SeriesId = s.Id AND gradeAtt.Name = 'Grade' 
				LEFT JOIN DataSeries.SeriesTypeAttribute outlierThresholdAtt ON outlierThresholdAtt.SeriesTypeId = st.Id AND outlierThresholdAtt.Name = 'OutlierConfiguration_OutlierThreshold'
				-- get the actual point value for this series
				INNER JOIN DataSeries.SeriesPoint sp ON sp.SeriesId = s.Id
				-- now get the Outlier series related to each primary data series
				LEFT JOIN DataSeries.Series outStandardisedDeviationSeries ON outStandardisedDeviationSeries.SeriesTypeId = 'OD_OutllierStandardisedDeviation' AND outStandardisedDeviationSeries.PrimaryRelatedSeriesId = s.Id
				LEFT JOIN DataSeries.SeriesPoint outStandardisedDeviationPoint ON outStandardisedDeviationPoint.SeriesId = outStandardisedDeviationSeries.Id AND outStandardisedDeviationPoint.Ordinal = sp.Ordinal
				-----
				INNER JOIN @Location AS L
					ON (L.LocationId = seriesLocationAtt.IntegerValue
						AND DateAdd(month, sp.Ordinal, @monthPriorSystemStart) BETWEEN L.IncludeStart AND L.IncludeEnd)
				----
				INNER JOIN Location loc ON loc.Location_Id = L.LocationId
				LEFT JOIN Location pl ON pl.Location_Id = L.ParentLocationId
			WHERE 
				DateAdd(month, sp.Ordinal, @monthPriorSystemStart) BETWEEN @iStartDate AND @iEndDate
				-- an outlier has a standardised devation greater than or equal to detection threshold
				AND ABS(outStandardisedDeviationPoint.Value) >= outlierThresholdAtt.DoubleValue
				AND ABS(outStandardisedDeviationPoint.Value) >= @iMinimumDeviation
				-- check for membership to a specific analysis group if required
				AND (loc.Location_Id =  @iLocationId
						OR @iIncludeAllSubLocations = 1
						OR (@iIncludeDirectSubLocations = 1 AND loc.Parent_Location_Id = @iLocationId)
					)
			GROUP BY s.SeriesTypeId,productSizeAtt.StringValue, materialTypeAtt.IntegerValue
			) outliersBySeriesType ON outliersBySeriesType.SeriesTypeId = gm.SeriesTypeId
		WHERE g.ContextKey = 'OutlierAnalysisGroup'
		GROUP BY g.Id, g.Name,outliersBySeriesType.ProductSize, outliersBySeriesType.MaterialTypeId
			
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioOutlierCountByAnalysisGroupForLocation TO BhpbioGenericManager
GO
