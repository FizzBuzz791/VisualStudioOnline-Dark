
-- new security option for the BB Ore Type export
INSERT INTO SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	SELECT 'REC', 'ANALYSIS_BLASTBLOCK_DATA_EXPORT_ORE_TYPE', 'Analysis', 'Access to run the blastblock data export report', 7

--
-- everyone who has access to the existing export report should have access to the 
-- new one as well, so we copy the role options over in order to do this
--
INSERT INTO SecurityRoleOption
	SELECT Role_Id, Application_Id, 'ANALYSIS_BLASTBLOCK_DATA_EXPORT_ORE_TYPE'
	FROM SecurityRoleOption
	WHERE Option_Id LIKE 'ANALYSIS_BLASTBLOCK_DATA_EXPORT'