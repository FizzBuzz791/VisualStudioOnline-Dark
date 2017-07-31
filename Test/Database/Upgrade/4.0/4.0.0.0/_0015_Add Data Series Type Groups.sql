-- Add a group for all raw data series
INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFGMFactor','RFGM and Contributing Data', null)
INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFGMFactorOnly','RFGM Factor Only', null)

INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFMMFactor','RFMM and Contributing Data', null)
INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFMMFactorOnly','RFMM Factor Only', null)

INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFSTMFactor','RFSTM and Contributing Data', null)
INSERT INTO DataSeries.SeriesTypeGroup (Id, Name, ContextKey) 
	VALUES ('OutlierAnalysisRFSTMFactorOnly','RFSTM Factor Only', null)
GO
