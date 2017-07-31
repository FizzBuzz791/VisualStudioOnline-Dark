IF NOT EXISTS (SELECT * FROM [dbo].[AuditTypeGroup] WHERE Name = 'BulkApprove')
BEGIN
	DECLARE @bulkApprovalAuditTypeGroupId	INT
	SELECT @bulkApprovalAuditTypeGroupId = MAX(auditTypes.Audit_Type_Group_Id)+1 FROM [dbo].[AuditTypeGroup] auditTypes

	INSERT INTO [dbo].[AuditTypeGroup]
	(
		Audit_Type_Group_Id,
		Name,
		Description
	)
	VALUES
	(
		@bulkApprovalAuditTypeGroupId,
		'BulkApprove',
		'Events triggered by the bulk approval agent'
	)

	DECLARE @auditTypeId	INT
	SELECT @auditTypeId = MAX(auditTypes.Audit_Type_Id)+1 FROM [dbo].[AuditType] auditTypes

	SET IDENTITY_INSERT dbo.AuditType ON
	INSERT INTO [dbo].[AuditType]
	(
		Audit_Type_Id,
		Audit_Type_Group_Id,
		[Name]
	)
	SELECT  @auditTypeId+1, @bulkApprovalAuditTypeGroupId, 'Bulk Approval Processing Agent Started' UNION
	SELECT  @auditTypeId+2, @bulkApprovalAuditTypeGroupId, 'Bulk Approval Processing Agent Stopped' UNION
	SELECT  @auditTypeId+3, @bulkApprovalAuditTypeGroupId, 'Bulk Approval Processing Agent Error'
	
	SET IDENTITY_INSERT dbo.AuditType OFF
END