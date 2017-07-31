DELETE 
FROM AuditType
WHERE Audit_Type_Group_Id = 7

DELETE 
FROM AuditTypeGroup
WHERE Audit_Type_Group_Id = 7

INSERT AuditTypeGroup
(
	Audit_Type_Group_Id, [Name], [Description]
)
SELECT 7, 'Data Series Processing', 'Events triggered by the Data Series Processing Agent & UI Interface related to data series processing activities'

SET IDENTITY_INSERT dbo.AuditType ON
INSERT dbo.AuditType
(
	Audit_Type_Id, Audit_Type_Group_Id, [Name]
)
SELECT 53, 7, 'Data Series Processing Agent Started' UNION
SELECT 54, 7, 'Data Series Processing Agent Stopped' UNION
SELECT 55, 7, 'Data Series Processing Agent Error'

SET IDENTITY_INSERT dbo.AuditType OFF

GO