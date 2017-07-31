-- Add indexes to tables currently missing indexes (or potentially not sufficiently indexed)

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
