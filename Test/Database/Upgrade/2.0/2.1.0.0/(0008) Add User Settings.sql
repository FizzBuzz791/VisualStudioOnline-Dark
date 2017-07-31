Insert Into dbo.SecurityUserSettingType
(
	[Name], [Description]
)
Select 'Reconciliation_Data_Export_Location_Id', 'Reconciliation_Data_Export_Location_Id' Union All
Select 'Reconciliation_Data_Export_Date_From', 'Reconciliation_Data_Export_Date_From' Union All
Select 'Reconciliation_Data_Export_Date_To', 'Reconciliation_Data_Export_Date_To' Union All
Select 'Reconciliation_Data_Export_Date_Breakdown', 'Reconciliation_Data_Export_Date_Breakdown' Union All
Select 'Reconciliation_Data_Export_Approval_Status', 'Reconciliation_Data_Export_Approval_Status' Union All
Select 'Reconciliation_Data_Export_Lump_Fines', 'Reconciliation_Data_Export_Lump_Fines' Union All
Select 'Reconciliation_Data_Export_Sublocations', 'Reconciliation_Data_Export_Sublocations' Union All
Select 'Blastblock_Data_Export_Location_Id', 'Blastblock_Data_Export_Location_Id' Union All
Select 'Blastblock_Data_Export_Date_From', 'Blastblock_Data_Export_Date_From' Union All
Select 'Blastblock_Data_Export_Date_To', 'Blastblock_Data_Export_Date_To' Union All
Select 'Blastblock_Data_Export_Approval_Status', 'Blastblock_Data_Export_Approval_Status'
