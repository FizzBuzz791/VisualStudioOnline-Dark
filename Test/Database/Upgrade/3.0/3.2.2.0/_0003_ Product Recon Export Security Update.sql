
Update SecurityOption 
	Set Description = 'Access to run the Product Reconciliation Data Export'
	Where Option_Id = 'ANALYSIS_PROD_RECON_DATA_EXPORT'

-- this export is supposed to accessable for everyone, so make sure we add all the required
-- roles for it
Delete From SecurityRoleOption
	Where Option_Id = 'ANALYSIS_PROD_RECON_DATA_EXPORT'

Insert Into SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'REC_VIEW', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_AREAC', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_NJV', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_WAIO', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_YANDI', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_JIMBLEBAR', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT' Union
	Select 'BHP_YARRIE', 'REC', 'ANALYSIS_PROD_RECON_DATA_EXPORT'
