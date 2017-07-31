
Insert Into SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
Select 'UTILITIES_OUTLIER_SERIES', 'Utilities', 'REC', 'Access to Outlier Series Configuration', 99 
GO

Insert Into SecurityRoleOption
(
	Role_Id, Option_Id, Application_Id
)
Select 'REC_ADMIN', 'UTILITIES_OUTLIER_SERIES', 'REC' 
GO