--
-- the blocks imports need a separate set of location codes to the rest of the imports
-- which access MQ2. In the initial population script they were set to the MQ2 codes.
-- This script updates them to the correct values
--
ALTER TABLE [dbo].BhpbioImportLocationCode
	ALTER COLUMN LocationCode [varchar](16) NOT NULL

Update c
	Set c.LocationCode = Case 
		When c.LocationCode = 'YD' Then 'YANDI'
		When c.LocationCode = 'YR' Then 'YARRIE'
		When c.LocationCode = 'AC' Then 'AREAC'
		When c.LocationCode = 'WB' Then 'NEWMAN'
		When c.LocationCode = '18' Then 'OB18'
		When c.LocationCode = 'ER' Then 'EASTERN RIDGE'
		When c.LocationCode = 'JB' Then 'JIMBLEBAR'
		Else c.LocationCode
	End
From BhpbioImportLocationCode c
	inner join ImportParameter p on p.ImportParameterId = c.ImportParameterId
	inner join Import i on i.ImportId = p.ImportId
Where ImportName = 'Blocks'
