
-- Create the permissions required for the Recon data export report item on the 
-- analysis tab
INSERT INTO SecurityOption
(
	Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order
)
SELECT 'REC','ANALYSIS_PROD_RECON_DATA_EXPORT','Analysis','Access to run the reconciliation prod recon data export report',8

INSERT INTO SecurityRoleOption
(
	Role_Id, Application_Id, Option_Id
)
SELECT 'REC_ADMIN','REC','ANALYSIS_PROD_RECON_DATA_EXPORT' 