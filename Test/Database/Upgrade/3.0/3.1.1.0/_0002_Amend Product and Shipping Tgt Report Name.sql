UPDATE dbo.Report SET Description = '03.16 Factors vs Time by Product Report (Line-Chart)' WHERE Name = 'BhpbioFactorsVsTimeProductReport'
GO

UPDATE dbo.Report SET Description = '02.12 Product Factors Against Shipping Targets Report (Line Chart)' WHERE Name = 'BhpbioFactorsVsShippingTargetsReport'
GO

UPDATE dbo.Report SET Description = '02.11 Product Factors by Location Against Shipping Targets Report (Line Chart)' WHERE Name = 'BhpbioFactorsByLocationVsShippingTargetsReport'
GO

UPDATE dbo.Report SET Description = '02.9 Product HUB Contribution Report (Bar Charts)' WHERE Name = 'BhpbioF1F2F3ProductReconContributionReport'
GO

-- 2.10 naming changes already handled in _0004_Correct Product Recon Att Report Name.sql

UPDATE dbo.Report SET Description = '02.8 Product Reconciliation Report (Happy Faces)' WHERE Name = 'BhpbioHUBProductReconciliationReport'
GO

UPDATE dbo.Report SET Description = '03.15 Product Supply Chain Monitoring Report (Bar Chart)' WHERE Name = 'BhpbioProductSupplyChainMonitoringReport'
GO

