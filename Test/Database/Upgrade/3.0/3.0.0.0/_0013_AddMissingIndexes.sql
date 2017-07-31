-- Add indexes to tables currently missing indexes (or potentially not sufficiently indexed)
-- NOTE: This script adds indexes ONLY to BHPB IO custom tables... see also equivalent upgrades script in Reconcilor.Core

-- Index to lookup Met Balancing records by date and weightometer
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_BhpbioMetBalancing_01')
	DROP INDEX IX_BhpbioMetBalancing_01 ON dbo.BhpbioMetBalancing
GO
CREATE NonClustered INDEX IX_BhpbioMetBalancing_01 ON dbo.BhpbioMetBalancing ( CalendarDate , Weightometer , WetTonnes )
GO

-- Create an index on approval data by month
IF  EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_BhpbioApprovalData_01')
	DROP INDEX IX_BhpbioApprovalData_01 ON dbo.BhpbioApprovalData
GO
CREATE NonClustered INDEX IX_BhpbioApprovalData_01 ON dbo.BhpbioApprovalData ( ApprovedMonth ) INCLUDE ( TagId , LocationId , UserId )
GO