
-- Add the new Report Exclusion Group
IF NOT EXISTS(SELECT * FROM StockpileGroup WHERE Stockpile_Group_Id ='ReportExclude HvP')
BEGIN
	INSERT INTO StockpileGroup(Stockpile_Group_Id,[Description],Order_No)
	VALUES ('ReportExclude HvP','Reporting exclusion group specifically for Haulage vs Plant reporting', 17)
END

-- Add the Stockpile to the exclusion  group
IF NOT EXISTS (SELECT * FROM StockpileGroupStockpile sgs
				INNER JOIN Stockpile s ON s.Stockpile_Id = sgs.Stockpile_Id
				WHERE s.Stockpile_Name = 'JB-COS01' AND sgs.Stockpile_Group_Id = 'ReportExclude HvP')
BEGIN
	INSERT INTO StockpileGroupStockpile(Stockpile_Group_Id, Stockpile_Id)
	SELECT 'ReportExclude HvP', s.Stockpile_Id
	FROM Stockpile s
	WHERE s.Stockpile_Name = 'JB-COS01'
END

-- add the exclusion type
IF NOT EXISTS (SELECT * FROM BhpbioFactorExclusionFilter f WHERE f.ExclusionType = 'HaulageVsPlantReport')
BEGIN

	INSERT INTO BhpbioFactorExclusionFilter(StockpileGroupId, ExclusionType)
	VALUES ('ReportExclude HvP','HaulageVsPlantReport')
END


IF NOT EXISTS (SELECT * FROM dbo.StockpileGroupNotes WHERE Stockpile_Group_Id = 'ReportExclude HvP')
BEGIN

	INSERT INTO dbo.StockpileGroupNotes (Stockpile_Group_Id,Stockpile_Group_Field_Id,Notes)
	VALUES ('ReportExclude HvP', 'ADMIN_EDITABLE_ONLY', 'TRUE')
END

GO
