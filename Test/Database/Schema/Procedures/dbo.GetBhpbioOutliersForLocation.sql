IF OBJECT_ID('dbo.GetBhpbioOutliersForLocation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioOutliersForLocation
GO

CREATE PROCEDURE dbo.GetBhpbioOutliersForLocation
(
	@iAnalysisGroup VARCHAR(100) = NULL,
	@iStartDate DATETIME,
	@iEndDate DATETIME,
	@iLocationId INTEGER = NULL,
	@iProductSize VARCHAR(20) = NULL,
	@iAttribute VARCHAR(20) = NULL,
	@iMinimumDeviation FLOAT,
	@iIncludeDirectSubLocations BIT,
	@iIncludeAllSubLocations BIT,
	@iExcludeTotalMaterialDuplicates BIT = 0,
	@iIncludeAllPoints BIT = 0
)
WITH ENCRYPTION
AS
BEGIN 
	-- Determine the month prior to the system start... this is needed to calculate ordinal values
	DECLARE @monthPriorSystemStart DATETIME
	
	SELECT @monthPriorSystemStart = DateAdd(month, -1,Convert(DateTime, Value))
	FROM Setting
	WHERE Setting_Id = 'SYSTEM_START_DATE'

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

		DECLARE @outliers TABLE (
			SeriesId INT,
			SeriesTypeId VARCHAR(100),
			SeriesKey VARCHAR(100),
			LocationId INT,
			ParentLocationId INT,
			CalculationId VARCHAR(250),
			[Month] DATETIME,
			SeriesTypeName VARCHAR(100),
			[Priority] INTEGER, 
			LocationType VARCHAR(100),
			ParentLocationName VARCHAR(100),
			LocationName VARCHAR(100),
			ProductSize VARCHAR(100),
			MaterialTypeId INTEGER,
			MaterialTypeAbbreviation VARCHAR(100),
			Attribute VARCHAR(100),
			Grade VARCHAR(100),
			ProjectionMethod VARCHAR(100),
			SeriesSD FLOAT,
			Value FLOAT,
			ProjectedValue FLOAT,
			Deviation FLOAT,
			DeviationInSD FLOAT,
			ThresholdSDs FLOAT,
			SeriesTypeDescription VARCHAR(100),
      IsOutlier BIT
		)

		INSERT INTO @outliers(SeriesId, SeriesTypeId, SeriesKey, LocationId, ParentLocationId, CalculationId, [Month], SeriesTypeName, [Priority], LocationType, 
							  ParentLocationName, LocationName, ProductSize, MaterialTypeId,  MaterialTypeAbbreviation, Attribute, Grade, ProjectionMethod, SeriesSD, 
							  Value, ProjectedValue, Deviation, DeviationInSD, ThresholdSDs, SeriesTypeDescription, IsOutlier)
		SELECT 
				s.Id as SeriesId,
				s.SeriesTypeId,
				s.SeriesKey,
				L.LocationId,
				loc.Parent_Location_Id as ParentLocationId,
				calculationIdAtt.StringValue as CalculationId,
				DateAdd(month, sp.Ordinal, @monthPriorSystemStart) as Month,
				st.Name + CASE WHEN displayNameSuffixVal.StringValue IS NOT NULL THEN ' (' + displayNameSuffixVal.StringValue + ')' ELSE '' END as SeriesTypeName, 
				outlierPriorityAtt.IntegerValue as [Priority], -- this must be part of the sort
				seriesLocationTypeAtt.StringValue as LocationType,
				pl.Name as ParentLocationName,
				CASE WHEN lty.Description like 'Pit' THEN pl.Name + ' ' +  loc.Name ELSE loc.Name END as LocationName,
				productSizeAtt.StringValue as ProductSize, -- LUMP, FINES, TOTAL etc
				materialTypeAtt.IntegerValue as MaterialTypeId,
				mt.Abbreviation as MaterialTypeAbbreviation,
				CASE 	WHEN attributeAtt.StringValue = 'Grade' THEN  gradeAtt.StringValue 
						ELSE attributeAtt.StringValue 
				END as Attribute, -- this is the name of the attribute this series relates to (Tonnes, Density, Fe, P, SiO2 etc)
				gradeAtt.StringValue as Grade, -- only filled in when relevant
	   			projectionMethodAtt.StringValue as ProjectionMethod,

	   			-- SD
				outStandardDeviationPoint.Value as SeriesSD, -- the size of the standard deviation of this series
				
				-- Value
				sp.Value  AS  Value,
				
				-- Projected Value
				CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END 
					AS  ProjectedValue,
				
				-- Deviation
				sp.Value - CASE WHEN projectionMethodAtt.StringValue = 'RollingAverage' THEN outRollingAverageProjectionPoint.Value ELSE outLinearProjectionPoint.Value END AS Deviation,
				
				outStandardisedDeviationPoint.Value AS DeviationInSD,
				outlierThresholdAtt.DoubleValue as ThresholdSDs, -- outlier threshold in terms of number of standard deviations... always positive but should be taken as a +- threshold 		
				outlierDescAtt.StringValue as SeriesTypeDescription,
        CASE WHEN ABS(outStandardisedDeviationPoint.Value) >= outlierThresholdAtt.DoubleValue THEN 1 ELSE 0 END AS IsOutlier
		FROM DataSeries.SeriesType st
			INNER JOIN DataSeries.SeriesTypeGroupMembership stgm ON stgm.SeriesTypeId = st.Id AND stgm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup' -- ie series type is for series under outlier anaylsis
			INNER JOIN DataSeries.Series s ON s.SeriesTypeId = st.Id
			LEFT JOIN DataSeries.SeriesTypeAttribute outlierDescAtt ON outlierDescAtt.SeriesTypeId = st.Id AND outlierDescAtt.Name = 'OutlierConfiguration_Description'
			LEFT JOIN DataSeries.SeriesTypeAttribute outlierPriorityAtt ON outlierPriorityAtt.SeriesTypeId = st.Id AND outlierPriorityAtt.Name = 'OutlierConfiguration_Priority'
			LEFT JOIN DataSeries.SeriesTypeAttribute outlierThresholdAtt ON outlierThresholdAtt.SeriesTypeId = st.Id AND outlierThresholdAtt.Name = 'OutlierConfiguration_OutlierThreshold'
			LEFT JOIN DataSeries.SeriesTypeAttribute projectionMethodAtt ON projectionMethodAtt.SeriesTypeId = st.Id AND projectionMethodAtt.Name = 'OutlierConfiguration_ProjectedValueMethod'
			LEFT JOIN DataSeries.SeriesTypeAttribute calculationIdAtt ON calculationIdAtt.SeriesTypeId = st.Id AND calculationIdAtt.Name = 'CalculationId'
			LEFT JOIN DataSeries.SeriesTypeAttribute displayNameSuffixAtt ON displayNameSuffixAtt.SeriesTypeId = st.Id AND displayNameSuffixAtt.Name = 'DisplayNameSuffixAttribute'
				
			LEFT JOIN DataSeries.SeriesAttribute seriesLocationAtt ON seriesLocationAtt.SeriesId = s.Id AND seriesLocationAtt.Name = 'LocationId' -- join in the location Id
			LEFT JOIN DataSeries.SeriesAttribute seriesLocationTypeAtt ON seriesLocationTypeAtt.SeriesId = s.Id AND seriesLocationTypeAtt.Name = 'LocationType' -- join in the location type
			LEFT JOIN DataSeries.SeriesAttribute productSizeAtt ON productSizeAtt.SeriesId = s.Id AND productSizeAtt.Name = 'ProductSize' -- join the product size
			LEFT JOIN DataSeries.SeriesAttribute materialTypeAtt ON materialTypeAtt.SeriesId = s.Id AND materialTypeAtt.Name = 'MaterialTypeId' -- join in the material type
			LEFT JOIN DataSeries.SeriesTypeAttribute attributeAtt ON attributeAtt.SeriesTypeId = s.SeriesTypeId AND attributeAtt.Name = 'Attribute' 
			LEFT JOIN DataSeries.SeriesAttribute gradeAtt ON gradeAtt.SeriesId = s.Id AND gradeAtt.Name = 'Grade' 
			LEFT JOIN DataSeries.SeriesAttribute displayNameSuffixVal ON displayNameSuffixVal.SeriesId = s.Id AND displayNameSuffixVal.Name = displayNameSuffixAtt.StringValue
			
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
				
			LEFT JOIN MaterialType mt ON mt.Material_Type_Id = materialTypeAtt.IntegerValue
			-----
			INNER JOIN @Location AS L
				ON (L.LocationId = seriesLocationAtt.IntegerValue
					AND DateAdd(month, sp.Ordinal, @monthPriorSystemStart) BETWEEN L.IncludeStart AND L.IncludeEnd)
			----
			INNER JOIN Location loc ON loc.Location_Id = L.LocationId
			INNER JOIN LocationType lty ON lty.Location_Type_Id = loc.Location_Type_Id
			LEFT JOIN Location pl ON pl.Location_Id = loc.Parent_Location_Id
		WHERE 
			DateAdd(month, sp.Ordinal, @monthPriorSystemStart) BETWEEN @iStartDate AND @iEndDate
			-- an outlier has a standardised devation greater than or equal to detection threshold
      AND (@iIncludeAllPoints = 1 OR (
			  ABS(outStandardisedDeviationPoint.Value) >= outlierThresholdAtt.DoubleValue
			  AND ABS(outStandardisedDeviationPoint.Value) >= @iMinimumDeviation))
			-- check for membership to a specific analysis group if required
			AND
			(
				@iAnalysisGroup IS NULL 
					OR EXISTS (SELECT * FROM DataSeries.SeriesTypeGroupMembership analysisGroupMembership WHERE analysisGroupMembership.SeriesTypeId = st.Id AND analysisGroupMembership.SeriesTypeGroupId = @iAnalysisGroup)
			)
			AND (loc.Location_Id =  @iLocationId
					OR @iIncludeAllSubLocations = 1
					OR (@iIncludeDirectSubLocations = 1 AND loc.Parent_Location_Id = @iLocationId)
				)
			AND (@iProductSize IS NULL OR COALESCE(productSizeAtt.StringValue,'TOTAL') = @iProductSize) -- use TOTAL as a default product size when running comparisons if none specified
			AND (@iAttribute IS NULL OR
				( @iAttribute = gradeAtt.StringValue OR @iAttribute = attributeAtt.StringValue)
				)
		
		IF @iExcludeTotalMaterialDuplicates = 1
		BEGIN
			-- delete apparent duplicates where the total material outlier is the same as one of the specific material type outliers
			DELETE totout
			FROM @outliers totout
				INNER JOIN @outliers mtout ON mtout.LocationId = totout.LocationId  -- same location
												AND mtout.CalculationId = totout.CalculationId -- and calculation
												AND mtout.[Month] = totout.[Month]  -- and month
												AND mtout.ProductSize = totout.ProductSize -- and product size 
												AND COALESCE(mtout.Attribute,'') = COALESCE(totout.Attribute,'') -- and attribute
												AND COALESCE(mtout.Grade,'') = COALESCE(totout.Grade,'') -- and grade
												AND mtout.Value = totout.Value -- and value
			WHERE totout.MaterialTypeId IS NULL AND NOT mtout.MaterialTypeId IS NULL -- where one is all material and the other is specific material
		END

		SELECT SeriesId, SeriesTypeId, SeriesKey, LocationId, ParentLocationId, CalculationId, [Month], SeriesTypeName, [Priority], LocationType, 
							  ParentLocationName, LocationName, ProductSize, MaterialTypeId,  MaterialTypeAbbreviation, Attribute, Grade, ProjectionMethod, SeriesSD, 
							  Value, ProjectedValue, Deviation, DeviationInSD, ThresholdSDs, SeriesTypeDescription, IsOutlier
		FROM @outliers
		ORDER BY [Priority], ABS(DeviationInSD) DESC, SeriesTypeName
END 
Go

GRANT EXECUTE ON dbo.GetBhpbioOutliersForLocation TO BhpbioGenericManager
GO