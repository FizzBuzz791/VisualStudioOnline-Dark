INSERT INTO [dbo].[Setting]
(
	[Setting_Id],
	[Description],
	[Data_Type],
	[Is_User_Editable],
	[Value]
)
VALUES
(
	'BHPBIO_ApprovalAssessment_HaulageErrors',
	'Link to quickreference guide section haulage errors',
	'STRING',
	1,
	'http://www.downergroup.com/What-we-do/Mining/Snowden.aspx' --TODO replaced with actual quick reference guide
)
GO	

INSERT INTO [dbo].[Setting]
(
	[Setting_Id],
	[Description],
	[Data_Type],
	[Is_User_Editable],
	[Value]
)
VALUES
(
	'BHPBIO_ApprovalAssessment_DataExceptions',
	'Link to quickreference guide section data exceptions',
	'STRING',
	1,
	'http://www.downergroup.com/What-we-do/Mining/Snowden.aspx' --TODO replaced with actual quick reference guide
)
GO	

INSERT INTO [dbo].[Setting]
(
	[Setting_Id],
	[Description],
	[Data_Type],
	[Is_User_Editable],
	[Value]
)
VALUES
(
	'BHPBIO_ApprovalAssessment_ValidationFailures',
	'Link to quickreference guide section validation failures',
	'STRING',
	1,
	'http://www.downergroup.com/What-we-do/Mining/Snowden.aspx' --TODO replaced with actual quick reference guide
)
GO	

	
INSERT INTO [dbo].[Setting]
(
	[Setting_Id],
	[Description],
	[Data_Type],
	[Is_User_Editable],
	[Value]
)
VALUES
(
	'BHPBIO_ApprovalAssessment_UngroupedStockpiles',
	'Link to quickreference guide section ungrouped stockpiles',
	'STRING',
	1,
	'../Stockpiles/Default.aspx?LocationId={0}&SelectedMonth={1}' --TODO replaced with actual quick reference guide
)
GO	

	
	
	
