DELETE 
FROM AuditType
WHERE Audit_Type_Group_Id = 6

DELETE 
FROM AuditTypeGroup
WHERE Audit_Type_Group_Id = 6

INSERT AuditTypeGroup
(
	Audit_Type_Group_Id, [Name], [Description]
)
SELECT 6, 'Purge', 'Events triggered by the Purge Agent & UI Interface related to purge activities'