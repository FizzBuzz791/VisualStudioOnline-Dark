
-- Create the permissions required for the Recon data export report item on the 
-- analysis tab
INSERT INTO SecurityOption
(
	Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order
)
SELECT 'REC','ANALYSIS_RECON_DATA_EXPORT','Analysis','Access to run the reconciliation data export report',6 UNION ALL
SELECT 'REC','ANALYSIS_BLASTBLOCK_DATA_EXPORT','Analysis','Access to run the blastblock data export report',7

INSERT INTO SecurityRoleOption
(
	Role_Id, Application_Id, Option_Id
)
SELECT 'REC_ADMIN','REC','ANALYSIS_RECON_DATA_EXPORT' UNION ALL
SELECT 'REC_ADMIN','REC','ANALYSIS_BLASTBLOCK_DATA_EXPORT'