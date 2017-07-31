-- Add indexes to tables currently missing indexes (or potentially not sufficiently indexed)
-- NOTE: This script adds indexes to Reconcilor.Core AND Snowden.Common tables (a subset of these are included in a Snowden.Common upgrade script)...

-- Support quick filtering of Import Jobs by status.  This is a commonly used filter.
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_ImportJob_01')
	DROP INDEX IX_ImportJob_01 ON dbo.ImportJob
GO
CREATE NonClustered INDEX IX_ImportJob_01 on dbo.ImportJob(ImportJobStatusId) INCLUDE ( ImportJobId , ImportId , Priority )
GO

-- Index to support filtering import sync rows by import Id (first) then row.. (support import queries)
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_ImportSyncRow_01')
	DROP INDEX IX_ImportSyncRow_01 ON dbo.ImportSyncRow
GO
CREATE NonClustered INDEX IX_ImportSyncRow_01 ON dbo.ImportSyncRow ( ImportId, ImportSyncRowId) INCLUDE ( IsCurrent )
GO

-- Support filtering data exception by Type and Date
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_DataException_01')
	DROP INDEX IX_DataException_01 ON dbo.DataException
GO
CREATE NonClustered INDEX IX_DataException_01 ON dbo.DataException ( Data_Exception_Type_Id , Data_Exception_Date )
GO

-- Drop obsolete weightometer sample records
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_WEIGHTOMETER_SAMPLE__WEIGHTOMETER_Id')
	DROP INDEX IX_WEIGHTOMETER_SAMPLE__WEIGHTOMETER_Id ON dbo.WeightometerSample
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_WEIGHTOMETER_SAMPLE__WEIGHTOMETER_SAMPLE_DATE')
	DROP INDEX IX_WEIGHTOMETER_SAMPLE__WEIGHTOMETER_SAMPLE_DATE ON dbo.WeightometerSample
GO

-- Create replacement Weightometer Sample Indexes
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_WeightometerSample_01')
	DROP INDEX IX_WeightometerSample_01 ON dbo.WeightometerSample
GO
CREATE NonClustered INDEX IX_WeightometerSample_01 ON dbo.WeightometerSample ( Source_Stockpile_Id , Weightometer_Sample_Date ) INCLUDE ( Weightometer_Sample_Id , Weightometer_Id , Destination_Stockpile_Id , Tonnes )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_WeightometerSample_02')
	DROP INDEX IX_WeightometerSample_02 ON dbo.WeightometerSample
GO
CREATE NonClustered INDEX IX_WeightometerSample_02 ON dbo.WeightometerSample ( Destination_Stockpile_Id , Weightometer_Sample_Date ) INCLUDE ( Weightometer_Sample_Id , Weightometer_Id , Source_Stockpile_Id , Tonnes )
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_WeightometerSample_03')
	DROP INDEX IX_WeightometerSample_03 ON dbo.WeightometerSample
GO
CREATE NonClustered INDEX IX_WeightometerSample_03 ON dbo.WeightometerSample ( Weightometer_Sample_Date ) INCLUDE ( Weightometer_Sample_Id , Weightometer_Id , Source_Stockpile_Id , Destination_Stockpile_Id , Tonnes )
GO

-- Create a DTT index on destination crusher in the style of other indexes on that table
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_DATA_TRANSACTION_TONNES_FLOW_DESTINATION__CRUSHER')
	DROP INDEX IX_DATA_TRANSACTION_TONNES_FLOW_DESTINATION__CRUSHER ON dbo.DataTransactionTonnesFlow
GO
CREATE NonClustered INDEX IX_DATA_TRANSACTION_TONNES_FLOW_DESTINATION__CRUSHER ON dbo.DataTransactionTonnesFlow ( Destination_Crusher_Id ) INCLUDE ( Data_Transaction_Tonnes_Id , Weightometer_Sample_Id , Source_Stockpile_Id , Source_Crusher_Id , Destination_Stockpile_Id )
GO

