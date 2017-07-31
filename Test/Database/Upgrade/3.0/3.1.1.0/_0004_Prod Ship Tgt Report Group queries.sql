-- Insert new report group

Declare @ReportGroupName Varchar(128) = 'Product and Shipping Targets Reports'
Declare @groupid int 

If Not Exists (Select 1 From ReportGroup Where Name = @ReportGroupName)
Begin
	Insert Into ReportGroup values (@ReportGroupName, @ReportGroupName, 4)
	select @groupid = Report_Group_Id from reportgroup where name = @ReportGroupName

	-- Create Security Option entries
	INSERT INTO SecurityOption(Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
		SELECT 'REC','ReportGroup_'+cast(@groupid as varchar(20)),'Reports','Access to Report Group Product and Shipping Targets',99

	INSERT INTO SecurityRoleOption (Role_Id, Application_Id, Option_Id)
		SELECT 'REC_ADMIN','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_AREAC','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_JIMBLEBAR','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_NJV','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_WAIO','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_YANDI','REC','ReportGroup_'+cast(@groupid as varchar(20)) UNION
		SELECT 'BHP_YARRIE','REC','ReportGroup_'+cast(@groupid as varchar(20))

	INSERT INTO SecurityRoleOption (Role_Id, Application_Id, Option_Id)
		SELECT sr.RoleId, so.Application_Id, so.Option_Id
		FROM SecurityRole AS sr
			CROSS JOIN Report AS r
			INNER JOIN SecurityOption AS so
				ON 'Report_' + CAST(r.Report_Id AS varchar(10)) = so.Option_Id
			LEFT OUTER JOIN SecurityRoleOption AS sro
				ON sr.RoleId = sro.Role_Id
				AND so.Application_Id = sro.Application_Id
				AND so.Option_Id = sro.Option_Id
		WHERE sr.RoleId LIKE 'BHP_%'
			AND r.Report_Group_Id = @groupid
			AND sro.Role_Id IS NULL
End

-- Set "Presentation Reports" Report Group Visibility Order. Move to botton
update ReportGroup set order_no = 5 where name = 'Presentation Reports'

-- Move reports to new GroupBox / -- Rename reports to match newly created Group and display order
select @groupid = Report_Group_Id from reportgroup where name = @ReportGroupName 

update report set Report_Group_Id = @groupid, description = '04.1 Product Reconciliation Report (Happy Faces)' where name = 'BhpbioHUBProductReconciliationReport'

update report set Report_Group_Id = @groupid, description = '04.2 Product HUB Contribution Report (Bar Charts)' where name = 'BhpbioF1F2F3ProductReconContributionReport'

update report set Report_Group_Id = @groupid, description = '04.3 Product Reconciliation by Attribute Report (Line Chart)' where name = 'BhpbioF1F2F3ReconciliationProductAttributeReport'

update report set Report_Group_Id = @groupid, description = '04.4 Product Factors Against Shipping Targets Report (Line Chart)' where name = 'BhpbioFactorsVsShippingTargetsReport'

update report set Report_Group_Id = @groupid, description = '04.5 Product Factors by Location Against Shipping Targets Report (Line Chart)' where name = 'BhpbioFactorsByLocationVsShippingTargetsReport'

update report set Report_Group_Id = @groupid, description = '04.6 Factors vs Time by Product Report (Line-Chart)' where name = 'BhpbioFactorsVsTimeProductReport'

update report set Report_Group_Id = @groupid, description = '04.7 Product Supply Chain Monitoring Report (Bar Chart)' where name = 'BhpbioProductSupplyChainMonitoringReport'


