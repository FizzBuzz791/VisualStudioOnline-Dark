-- Backup the override table
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioStockpileLocationOverrideTemp]') AND type in (N'U'))
DROP TABLE [dbo].[BhpbioStockpileLocationOverrideTemp]
GO

SELECT * INTO BhpbioStockpileLocationOverrideTemp  FROM BhpbioStockpileLocationOverride

-- clear the override table
DELETE FROM BhpbioStockpileLocationOverride

-- insert into the override table records only for the stockpiles identified
INSERT INTO BhpbioStockpileLocationOverride(Stockpile_ID, Location_Type_Id, Location_Id, FromMonth, ToMonth)
SELECT s.Stockpile_Id, 3, 10, '2012-10-01', '2050-12-31'
FROM Stockpile s
INNER JOIN STockpileLocation sl ON sl.Stockpile_ID = s.Stockpile_ID
--	INNER JOIN BhpbioStockpileLocationOverride lo ON lo.Stockpile_ID = s.Stockpile_ID
WHERE s.Stockpile_Name IN
(
'JB-12F1F33',
'JB-13F1A30',
'JB-13F1A34',
'JB-13F1A37',
'JB-13F1A40',
'JB-13F1A42',
'JB-13F1A45',
'JB-13F1A48',
'JB-13F1A51',
'JB-13F1A54',
'JB-13F1A56',
'JB-13F1B28',
'JB-13F1B31',
'JB-13F1B35',
'JB-13F1B38',
'JB-13F1B41',
'JB-13F1B43',
'JB-13F1B46',
'JB-13F1B49',
'JB-13F1B52',
'JB-13F1B55',
'JB-13F1B60',
'JB-13F1S01',
'JB-13F2C26',
'JB-13F2C32',
'JB-13F2C39',
'JB-13F2C47',
'JB-13F2C53',
'JB-13F2D36',
'JB-13F2D44',
'JB-13F2D50',
'JB-13F2D57',
'JB-HG-ROMOS-01',
'JB-13104WL',
'JB-LTS_SP01',
'JB-LTS_SP02'
)

-- update the location date table
exec dbo.UpdateBhpbioStockpileLocationDate

-- correct historic data
exec dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments