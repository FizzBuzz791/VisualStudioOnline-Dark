-- create a data retrieval group
IF NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeGroup sg WHERE sg.Id = 'DataRetrievalGroup')
BEGIN
	INSERT INTO DataSeries.SeriesTypeGroup(Id, Name, ContextKey)
	VALUES ('DataRetrievalGroup', 'DataRetrievalGroup', 'Data')
END
		
-- create a queue entry type for data retrieval
IF NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntryType qt WHERE qt.Code = 'DataRetrievalRequest')
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntryType(Id, Code, Priority,CausesAutomaticPointRemoval)
	VALUES (20, 'DataRetrievalRequest', 1, 1)
END

-- trigger outlier processing after data retrieval
IF NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntryTrigger qtrig INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = qtrig.TriggerQueueEntryTypeId WHERE qt.Code = 'DataRetrievalRequest')
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntryTrigger(TriggerQueueEntryTypeId, [TriggerSeriesTypeGroupId],[RaiseQueueEntryTypeId], [RaiseSeriesTypeGroupId],  [OrdinalOffset])

	SELECT (SELECT t.ID FROM DataSeries.SeriesQueueEntryType t WHERE t.Code = 'DataRetrievalRequest'),
	 null,
	 (SELECT r.ID FROM DataSeries.SeriesQueueEntryType r WHERE r.Code = 'OutlierProcessRequest'),
	 '{Copy}',
	  0 -- same ordinal
END

-- trigger outlier processing of the next ordinal after each success
IF NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntryTrigger qtrig INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = qtrig.TriggerQueueEntryTypeId WHERE qt.Code = 'OutlierProcessRequest')
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntryTrigger(TriggerQueueEntryTypeId, [TriggerSeriesTypeGroupId],[RaiseQueueEntryTypeId], [RaiseSeriesTypeGroupId],  [OrdinalOffset])

	SELECT (SELECT t.ID FROM DataSeries.SeriesQueueEntryType t WHERE t.Code = 'OutlierProcessRequest'),
	 null,
	 (SELECT r.ID FROM DataSeries.SeriesQueueEntryType r WHERE r.Code = 'OutlierProcessRequest'),
	 '{Copy}',
	  1 -- next ordinal
END

-- add all series in the outlier series group to the data retrieval group also (excep where they already belong to the group)
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId)
SELECT st.Id,'DataRetrievalGroup'
FROM  DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id AND gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeGroupMembership em WHERE em.SeriesTypeId = st.Id AND em.SeriesTypeGroupId = 'DataRetrievalGroup')

-- specify the retriever used to obtain data points (for all series types in the group)
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'RetrieverFullyQualifiedName', 'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries'
	FROM  DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id AND gm.SeriesTypeGroupId = 'DataRetrievalGroup'
WHERE NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'RetrieverFullyQualifiedName')

-- specify the processor used for data retrieval
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'DataRetrievalRequest_ProcessorFullyQualifiedName', 'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing'
	FROM  DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeGroupMembership sm ON sm.SeriesTypeId = st.Id AND sm.SeriesTypeGroupId = 'DataRetrievalGroup'
WHERE NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'DataRetrievalRequest_ProcessorFullyQualifiedName')

-- specify the processor used for outlier detection for all series types in the outlier group
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue)
SELECT st.Id, 'OutlierProcessRequest_ProcessorFullyQualifiedName', 'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing'
	FROM  DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeGroupMembership sm ON sm.SeriesTypeId = st.Id AND sm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeAttribute stat WHERE stat.SeriesTypeId = st.Id AND stat.Name = 'OutlierProcessRequest_ProcessorFullyQualifiedName')


GO
