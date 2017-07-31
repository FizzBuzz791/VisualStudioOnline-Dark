If (Not Exists(Select 1 From AuditType Where Name = 'Import Auto-Queue Agent Started'))
Begin
	Insert into AuditType 
	(
		Audit_Type_Group_Id, Name
	)
	SELECT atg.Audit_Type_Group_Id, 'Import Auto-Queue Agent Started'
		FROM AuditTypeGroup atg
		WHERE atg.Name = 'Import' UNION ALL
	SELECT atg.Audit_Type_Group_Id, 'Import Auto-Queue Agent Stopped'
		FROM AuditTypeGroup atg
		WHERE atg.Name = 'Import' UNION ALL
	SELECT atg.Audit_Type_Group_Id, 'Import Auto-Queue Agent Failure'
		FROM AuditTypeGroup atg
		WHERE atg.Name = 'Import'


End