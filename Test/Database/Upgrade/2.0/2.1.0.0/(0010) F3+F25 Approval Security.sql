-- Only REC_ADMIN should be able to approve F2.5 and F3. This sets up the required
-- security settings to allow this to happen

-- Some new security options specific for the F3 and F2.5 approvals
Insert Into SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'APPROVAL_F3', 'Approval', 'Access to approve F3 data', 2 Union
	Select 'REC', 'APPROVAL_F25', 'Approval', 'Access to approve F2.5 data', 2

-- associate the options with the REC_ADMIN role
Insert Into SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'APPROVAL_F3' Union
	Select 'REC_ADMIN', 'REC', 'APPROVAL_F25'
