declare @NextOrder int
declare @ReportName varchar(255)
declare @SecurityOption varchar(255)
declare @identity int

set @ReportName = '03.17 Factors vs Time Report - Resource Classification (Line-Chart)'

select	@NextOrder = max ([Order_No]) + 1 
from	[dbo].[Report]
where	[Report_Group_Id] = 3

INSERT INTO [dbo].[Report]
			([Name], [Description], [Report_Path], [Report_Group_Id], [Order_No])
VALUES		('BhpbioFactorsVsTimeResourceClassificationReport',
			@ReportName, '', 3, @NextOrder)

-- Need to get identity of the inserted row and use that for the other table inserts
SET @identity = SCOPE_IDENTITY ()
SET @SecurityOption = 'Report_' + cast(@identity as varchar(10))

INSERT INTO [dbo].[SecurityOption]
			([Application_Id], [Option_Id], [Option_Group_Id], [Description], [Sort_Order])
VALUES		('REC', @SecurityOption, 'Reports', 
            'Access to Report ''' + @ReportName + '''', 99)

INSERT INTO [dbo].[SecurityRoleOption] ([Role_Id], [Application_Id], [Option_Id])
SELECT	[RoleId], 'REC', @SecurityOption
FROM	[dbo].[SecurityRole]
WHERE	[RoleId] <> 'REC_PURGE'
