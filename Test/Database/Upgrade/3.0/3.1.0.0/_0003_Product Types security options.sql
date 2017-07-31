
-- Create the permissions required for the Recon data export report item on the 
-- analysis tab
Insert Into SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
Select 'UTILITIES_PRODUCT_TYPE', 'Utilities', 'REC', 'Access to the Product Type Utilities Screen', 99 UNION
SELECT 'BHPBIO_DEFAULT_PRODUCT_TYPE_EDIT','Utilities','REC','Access to edit the Product Types',9 UNION
SELECT 'UTILITIES_SHIPPING_TARGETS','Utilities','REC','Access to edit the Default Shipping Targets',10

Insert Into SecurityRoleOption
(
	Role_Id, Option_Id, Application_Id
)
Select 'REC_ADMIN', 'UTILITIES_PRODUCT_TYPE', 'REC'  UNION
SELECT 'REC_ADMIN', 'BHPBIO_DEFAULT_PRODUCT_TYPE_EDIT', 'REC' UNION
SELECT 'REC_ADMIN', 'UTILITIES_SHIPPING_TARGETS', 'REC' 


