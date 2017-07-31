BEGIN TRANSACTION 

DECLARE @newSeriesTypeId1 NVARCHAR(50)
SET @newSeriesTypeId1 = N'RecoveryFactorMoisture_Tonnes_PS'

DECLARE @newSeriesTypeId2 NVARCHAR(50)
SET @newSeriesTypeId2 = N'RecoveryFactorMoisture_H2O_PS'

INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (@newSeriesTypeId1, N'Recovery Factor (Moisture) Tonnes', 0, 1)
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (@newSeriesTypeId2, N'Recovery Factor (Moisture) H2O', 0, 1)

INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId)
SELECT st.Id, 'OutlierSeriesTypeGroup'
FROM DataSeries.SeriesType st
	LEFT JOIN DataSeries.SeriesTypeGroupMembership existG ON existG.SeriesTypeId = st.Id AND existG.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE existG.SeriesTypeId IS NULL AND st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'ByGrade', NULL, NULL, 0, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'ByProductSize', NULL, NULL, 1, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'CalculationId', N'RecoveryFactorMoisture', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'LocationType', N'Site and above', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId1, N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'Attribute', N'H2O', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'ByGrade', NULL, NULL, 1, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'ByProductSize', NULL, NULL, 1, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'CalculationId', N'RecoveryFactorMoisture', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'LocationType', N'Site and above', NULL, NULL, NULL, NULL)
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (@newSeriesTypeId2, N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)

INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue, IntegerValue, BooleanValue, DateTimeValue, DoubleValue)
		SELECT st.Id, 'OutlierConfiguration_AbsoluteEnd',null, null, null,  '2060-01-01 00:00:00.000', null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_AbsoluteStart',null, null, null,  '2009-04-01 00:00:00.000', null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_Description',st.Name, null, null, null,  null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_IsActive',null, null, 1, null, null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_MinimumDataPoints',null, 12, null, null, null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_OutlierThreshold',null, null, null, null, 3
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_Priority',null,  
			CASE WHEN st.Id like '%Factor%Tonnes%' THEN 1
				WHEN st.Id like '%Factor%Fe%' THEN 2
				WHEN st.Id like '%Factor%Grade%' THEN 3
				WHEN st.Id like '%Tonnes%' THEN 4
				WHEN st.Id like '%Fe%' THEN 5
				WHEN st.Id like '%Grade%' THEN 6
				WHEN st.Id like '%H2O%' THEN 6
			ELSE 7
			END as Priority
			, null, null, null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_ProjectedValueMethod',
			-- for all tonnes series that are not factor series..linear projection.. for all else, rolling average
			CASE WHEN st.Id like '%Tonnes%' AND NOT st.Id like '%Factor%'  THEN 'LinearProjection' ELSE 'RollingAverage' END,
			null, null, null, null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_RollingSeriesSize',null, 24, null, null, null
		FROM DataSeries.SeriesType st 
		WHERE  st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)

INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId)
SELECT st.Id,'DataRetrievalGroup'
FROM  DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id AND gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeGroupMembership em WHERE em.SeriesTypeId = st.Id AND em.SeriesTypeGroupId = 'DataRetrievalGroup')
 AND st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
 
-- specify the retriever used to obtain data points (for all series types in the group)
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'RetrieverFullyQualifiedName', 'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries'
	FROM  DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id AND gm.SeriesTypeGroupId = 'DataRetrievalGroup'
WHERE st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
	AND NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'RetrieverFullyQualifiedName')

-- specify the processor used for data retrieval
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'DataRetrievalRequest_ProcessorFullyQualifiedName', 'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing'
	FROM  DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeGroupMembership sm ON sm.SeriesTypeId = st.Id AND sm.SeriesTypeGroupId = 'DataRetrievalGroup'
WHERE st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
	AND  NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'DataRetrievalRequest_ProcessorFullyQualifiedName')

-- specify the processor used for outlier detection for all series types in the outlier group
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'OutlierProcessRequest_ProcessorFullyQualifiedName', 'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing'
	FROM  DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeGroupMembership sm ON sm.SeriesTypeId = st.Id AND sm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE st.Id IN  (@newSeriesTypeId1, @newSeriesTypeId2)
 AND NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'OutlierProcessRequest_ProcessorFullyQualifiedName')

INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisRecoveryFactorMoisture','Recovery Factor Moisture','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES (@newSeriesTypeId1,'OutlierAnalysisRecoveryFactorMoisture')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES (@newSeriesTypeId2,'OutlierAnalysisRecoveryFactorMoisture')

COMMIT TRANSACTION


GO

