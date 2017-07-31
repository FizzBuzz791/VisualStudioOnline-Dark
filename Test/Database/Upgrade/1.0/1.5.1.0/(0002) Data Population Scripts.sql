/*
		Create Jingbao Hub - Parent to WAIO
*/

INSERT INTO Location (Name,Location_Type_Id,Parent_Location_Id,Description)
SELECT 'Jingbao',2,1,'Jingbao (Virtual Hub)'
WHERE NOT EXISTS (SELECT 1 FROM Location WHERE Name = 'Jingbao')

/*
		Add Exclusion Filters for Jingbao Hub 
*/
INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
SELECT Location_Id,'PortBalance'
FROM Location WHERE [Name]='Jingbao'
AND NOT EXISTS 
	(SELECT 1 FROM BhpbioFactorExclusionFilter HEF
	 INNER JOIN Location L ON L.Location_ID = HEF.HubLocationId
	 WHERE	L.[Name]='Jingbao' AND L.Location_Type_ID=2 AND ExclusionType='PortBalance')

INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
SELECT Location_Id,'PortBlending'
FROM Location WHERE [Name]='Jingbao'
AND NOT EXISTS 
	(SELECT 1 FROM BhpbioFactorExclusionFilter HEF
	 INNER JOIN Location L ON L.Location_ID = HEF.HubLocationId
	 WHERE	L.[Name]='Jingbao' AND L.Location_Type_ID=2 AND ExclusionType='PortBlending')

INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
SELECT Location_Id,'ShippingTransaction'
FROM Location WHERE [Name]='Jingbao'
AND NOT EXISTS 
	(SELECT 1 FROM BhpbioFactorExclusionFilter HEF
	 INNER JOIN Location L ON L.Location_ID = HEF.HubLocationId
	 WHERE	L.[Name]='Jingbao' AND L.Location_Type_ID=2 AND ExclusionType='ShippingTransaction')

/*
		-- TESTING 
INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
select 6,'PortBalance'
where not exists 
	(select 1 from BhpbioFactorExclusionFilter 
	 where	HubLocationId=6 and ExclusionType='PortBalance')

INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
select 6,'PortBlending'
where not exists 
	(select 1 from BhpbioFactorExclusionFilter 
	 where	HubLocationId=6 and ExclusionType='PortBlending')

INSERT INTO BhpbioFactorExclusionFilter(HubLocationId, ExclusionType)
select 6,'ShippingTransaction'
where not exists 
	(select 1 from BhpbioFactorExclusionFilter 
	 where	HubLocationId=6 and ExclusionType='ShippingTransaction')
*/

-- Add a new stockpile group for stockpiles to exclude from factor calculations.
DECLARE @iDescription varchar(255)
DECLARE @iLocation_Type_Id tinyint
DECLARE @iName varchar(31)
DECLARE @iOrder_No int
DECLARE @iParent_Location_Id int
DECLARE @iStockpile_Group_Id varchar(31)
DECLARE @iStockpile_Id int
DECLARE @RC int

Select
	@iStockpile_Group_Id = 'ReportExclude',
	@iDescription = 'Reporting exclusion group',
	@iOrder_No = max(Order_No)+1
From dbo.StockpileGroup

If Not Exists (Select * From dbo.StockpileGroup Where Stockpile_Group_Id = @iStockpile_Group_Id)
Begin
	EXECUTE @RC = [dbo].[AddStockpileGroup] 
	   @iStockpile_Group_Id
	  ,@iDescription
	  ,@iOrder_No
End

-- Add new stockpile group to the exclusion table.
Insert Into dbo.BhpbioFactorExclusionFilter(StockpileGroupId, ExclusionType)
Select @iStockpile_Group_Id, 'ActualC'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'ActualC')
Union
Select @iStockpile_Group_Id, 'ActualY'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'ActualY')
Union
Select @iStockpile_Group_Id, 'ActualZ'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'ActualZ')
Union
Select @iStockpile_Group_Id, 'PostCrusher'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'PostCrusherDelta')
Union
Select @iStockpile_Group_Id, 'BeneProduct'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'PostCrusherDelta')
Union
Select @iStockpile_Group_Id, 'GenericReports'
Where Not Exists (Select * From dbo.BhpbioFactorExclusionFilter Where StockpileGroupId = @iStockpile_Group_Id And ExclusionType = 'PostCrusherDelta')

-- Add Jingbao related stockpiles to the reporting exclusion stockpile group
DECLARE JINGBAO_CURSOR Cursor
FOR 
	Select Stockpile_Id
	From dbo.Stockpile
	Where Description Like '%jing%'

Open JINGBAO_CURSOR

Fetch NEXT FROM JINGBAO_CURSOR INTO @iStockpile_Id 
While (@@FETCH_STATUS <> -1)
BEGIN
	IF (@@FETCH_STATUS <> -2)

		EXECUTE @RC = [dbo].[AddStockpileGroupStockpile] 
		   @iStockpile_Group_Id
		  ,@iStockpile_Id

	Fetch NEXT FROM JINGBAO_CURSOR INTO @iStockpile_Id 
END

CLOSE JINGBAO_CURSOR
DEALLOCATE JINGBAO_CURSOR



/*
		Create Crusher C9 at Whaleback
*/

INSERT	INTO dbo.Crusher (Crusher_Id, Description)
SELECT	'WB-C9', 'Whaleback Crusher 9'
WHERE NOT EXISTS (SELECT 1 FROM dbo.Crusher WHERE Crusher_Id='WB-C9')

INSERT	INTO dbo.Weightometer (Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id)
SELECT	'WB-C9DOutFlow', 'WB-C9 Outflow to Stockpile', 1, 'CVF+L1', NULL
WHERE NOT EXISTS (SELECT 1 FROM dbo.Weightometer WHERE Weightometer_Id='WB-C9DOutFlow')

INSERT	INTO dbo.WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
SELECT	'WB-C9DOutFlow', 3, 9
WHERE NOT EXISTS (SELECT 1 FROM dbo.WeightometerLocation WHERE Weightometer_Id='WB-C9DOutFlow')

INSERT	INTO dbo.WeightometerFlowPeriod (Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No)
SELECT	'WB-C9DOutFlow', NULL, NULL, 'WB-C9', NULL, NULL, NULL, NULL, 0, (SELECT MAX(Processing_Order_No)+1 FROM	dbo.WeightometerFlowPeriod)
WHERE NOT EXISTS (SELECT 1 FROM dbo.WeightometerFlowPeriod WHERE Weightometer_Id='WB-C9DOutFlow' AND Source_Crusher_Id='WB-C9')

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
SELECT 'WB-C9', 3, 9
WHERE NOT EXISTS (SELECT 1 FROM dbo.CrusherLocation WHERE Crusher_Id='WB-C9')