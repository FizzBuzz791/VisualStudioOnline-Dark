DECLARE @permission	VARCHAR(255)
SET @permission = 'APPROVAL_BULK'

IF NOT EXISTS (SELECT * FROM [dbo].[SecurityOption] WHERE Option_id = @permission)
BEGIN
	INSERT INTO [dbo].[SecurityOption] VALUES
	(
		'REC',
		@permission,
		'Approval',
		'Access to Bulk Approval',
		99
	)
	
	INSERT INTO [dbo].[SecurityRoleOption]  VALUES
	(
		'REC_ADMIN',
		'REC',
		@permission
	)
END