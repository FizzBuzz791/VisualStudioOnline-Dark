DELETE 
FROM AuditType
WHERE Audit_Type_Id BETWEEN 35 AND 44

SET IDENTITY_INSERT dbo.AuditType ON
INSERT dbo.AuditType
(
	Audit_Type_Id, Audit_Type_Group_Id, [Name]
)
SELECT 35, 6, 'Purge Requested' UNION
SELECT 36, 6, 'Purge Approved' UNION
SELECT 37, 6, 'Purge Cancelled' UNION
SELECT 38, 6, 'Purge Obsolete' UNION
SELECT 39, 6, 'Purge Initiated' UNION
SELECT 40, 6, 'Purge Completed' UNION
SELECT 41, 6, 'Purge Failed' UNION
SELECT 42, 6, 'Purge Agent Error' UNION
SELECT 43, 6, 'Purge Agent Started' UNION
SELECT 44, 6, 'Purge Agent Stopped'

SET IDENTITY_INSERT dbo.AuditType OFF