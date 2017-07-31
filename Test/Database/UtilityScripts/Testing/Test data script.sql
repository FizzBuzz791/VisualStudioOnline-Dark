BEGIN TRAN

Declare
	@StartDate Datetime,
	@EndDate Datetime
Select
	@StartDate = '2013-01-01',
	@EndDate = '2013-06-01'
	

Declare @ThePits Table
(
	PitId Int Not Null Primary Key
)
Insert Into @ThePits (PitId)
Select Location_Id
From Location
Where Location_Type_Id = 4

Declare @LumpGradeModifiers Table
( 
	GradeId SmallInt NOT NULL Primary Key,
	LumpModifier Decimal(5,4)
)
Insert Into @LumpGradeModifiers (GradeId, LumpModifier)
Select 1, 1.05 Union All
Select 2, 1.00 Union All
Select 3, 1.10 Union All
Select 4, 0.90 Union All
Select 5, 0.70 Union All
Select 6, 1.15

---------------------------------------------
-- Populate Settings --
---------------------------------------------
Update Setting Set Value = @StartDate
Where Setting_Id = 'LUMP_FINES_CUTOVER_DATE'

---------------------------------------------
-- Populate BhpbioDefaultLumpFines --
---------------------------------------------
Delete From dbo.BhpbioDefaultLumpFines

Insert Into dbo.BhpbioDefaultLumpFines
(
	LocationId, StartDate, LumpPercent, IsNonDeletable
)
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'WAIO' Union All
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'Yandi' And Location_Type_Id = 2 Union All --hub
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'Yandi' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.45, 1 From dbo.Location Where [Name] = 'NJV' And Location_Type_Id = 2 Union All --hub
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.35, 1 From dbo.Location Where [Name] = 'Newman' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.25, 1 From dbo.Location Where [Name] = 'OB18' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.75, 1 From dbo.Location Where [Name] = 'OB23/25' And Location_Type_Id = 3  --site

Insert Into dbo.BhpbioDefaultLumpFines
(
	LocationId, StartDate, LumpPercent, IsNonDeletable
)
Select l.Location_Id, '2009-04-01', 0.45, 1
From Location l
Left Join BhpbioDefaultLumpFines dlf on dlf.LocationId = l.Location_Id
Where dlf.LocationId Is Null
And Location_Type_Id <= 4 --PIT

-----------------------------------------------------------
-- Populate WeightometerSampleNotes with some test data. --
-----------------------------------------------------------
Delete From dbo.WeightometerSampleNotes 
Where Weightometer_Sample_Field_Id = 'ProductSize'

Insert Into dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Notes)
Select WS.Weightometer_Sample_Id, 'ProductSize', 'FINES'
From dbo.WeightometerSample WS
Left Join stockpile S1 on WS.source_stockpile_id = S1.stockpile_id
Left Join stockpile S2 on WS.destination_stockpile_id = S2.stockpile_id
Where WS.Weightometer_Sample_Date Between @StartDate And @EndDate
And (
s1.description like '%fines%' 
or s1.stockpile_name like '%fines%' 
or s2.description like '%fines%' 
or s2.stockpile_name like '%fines%' 
)

Insert Into dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Notes)
Select WS.Weightometer_Sample_Id, 'ProductSize', 'LUMP'
From dbo.WeightometerSample WS
Left Join Stockpile S1 on WS.source_stockpile_id = S1.stockpile_id
Left Join Stockpile S2 on WS.destination_stockpile_id = S2.stockpile_id
Left Join WeightometerSampleNotes WSN 
	On WSN.Weightometer_Sample_Id = WS.Weightometer_Sample_Id
	And WSN.Weightometer_Sample_Field_Id = 'ProductSize'
Where Weightometer_Sample_Date Between @StartDate And @EndDate
And WSN.Weightometer_Sample_Id Is Null
And (
s1.description like '%lump%' 
or s1.stockpile_name like '%lump%' 
or s2.description like '%lump%' 
or s2.stockpile_name like '%lump%' 
)

------------------------------------------
-- Populate BhpbioHaulageLumpPercent --
------------------------------------------
Delete From dbo.HaulageValue
Where Haulage_Field_Id = 'LumpPercent'

Insert Into dbo.HaulageValue (Haulage_Id, Haulage_Field_Id, Field_Value)
Select h.Haulage_Id, 'LumpPercent', ((ABS(CHECKSUM(NEWID())) % 3500) + 3000) / 10000.0
From dbo.Haulage h
Where h.Haulage_Date Between @StartDate And @EndDate

---------------------------------------------
-- Populate BhpbioHaulageLumpFinesGrade --
---------------------------------------------
Delete From dbo.BhpbioHaulageLumpFinesGrade

Insert Into dbo.BhpbioHaulageLumpFinesGrade (HaulageRawId, GradeId, LumpValue, FinesValue)
Select h.Haulage_Raw_Id, hg.Grade_Id, hg.Grade_Value * lgm.LumpModifier, 
	(hg.Grade_value - (hg.Grade_Value * lgm.LumpModifier * lp.Field_Value)) / (1 - lp.Field_Value)
From dbo.Haulage h
Inner Join dbo.HaulageGrade hg on h.Haulage_Id = hg.Haulage_Id
Inner Join dbo.HaulageValue lp on lp.Haulage_Id = h.Haulage_Id and lp.Haulage_Field_Id = 'LumpPercent'
Inner Join @LumpGradeModifiers lgm
	On lgm.GradeId = hg.Grade_Id
Where h.Haulage_Date Between @StartDate And @EndDate

------------------------------------------
-- Populate BhpbioBlastBlockLumpPercent --
------------------------------------------
Delete From dbo.BhpbioBlastBlockLumpPercent

Insert Into dbo.BhpbioBlastBlockLumpPercent (ModelBlockId, SequenceNo, LumpPercent)
Select mb.Model_Block_Id, mbp.Sequence_No, ((ABS(CHECKSUM(NEWID())) % 3500) + 3000) / 10000.0
From dbo.ModelBlock mb
Inner Join dbo.ModelBlockPartial mbp
	On mbp.Model_Block_Id = mb.Model_Block_Id
Inner Join dbo.ModelBlockLocation mbl
	On mb.Model_Block_Id = mbl.Model_Block_Id
Inner Join dbo.Location block
	On mbl.Location_Id = block.Location_Id
Inner Join dbo.Location blast
	On block.Parent_Location_Id = blast.Location_Id
Inner Join dbo.Location bench
	On blast.Parent_Location_Id = bench.Location_Id
Inner Join dbo.Location pit
	On bench.Parent_Location_Id = pit.Location_Id
Inner Join @ThePits pits
	On pit.Location_Id = pits.PitId

--Select Top 1000 *
--From dbo.BhpbioBlastBlockLumpPercent


---------------------------------------------
-- Populate BhpbioBlastBlockLumpFinesGrade --
---------------------------------------------
Delete From dbo.BhpbioBlastBlockLumpFinesGrade

Insert Into dbo.BhpbioBlastBlockLumpFinesGrade (ModelBlockId, SequenceNo, GradeId, LumpValue, FinesValue)
Select mb.Model_Block_Id, mbp.Sequence_No, mbpg.Grade_Id,
	mbpg.Grade_Value * lgm.LumpModifier, 
	(mbpg.Grade_value - (mbpg.Grade_Value * lgm.LumpModifier * lp.LumpPercent)) / (1 - lp.LumpPercent)
From dbo.ModelBlock mb
Inner Join dbo.ModelBlockPartial mbp
	On mbp.Model_Block_Id = mb.Model_Block_Id
Inner Join dbo.ModelBlockPartialGrade mbpg
	On mbpg.Model_Block_Id = mbp.Model_Block_Id
	And mbpg.Sequence_No = mbp.Sequence_No
Inner Join dbo.BhpbioBlastBlockLumpPercent lp
	On lp.ModelBlockId = mb.Model_Block_Id
Inner Join @LumpGradeModifiers lgm
	On lgm.GradeId = mbpg.Grade_Id
Inner Join dbo.ModelBlockLocation mbl
	On mb.Model_Block_Id = mbl.Model_Block_Id
Inner Join dbo.Location block
	On mbl.Location_Id = block.Location_Id
Inner Join dbo.Location blast
	On block.Parent_Location_Id = blast.Location_Id
Inner Join dbo.Location bench
	On blast.Parent_Location_Id = bench.Location_Id
Inner Join dbo.Location pit
	On bench.Parent_Location_Id = pit.Location_Id
Inner Join @ThePits pits
	On pit.Location_Id = pits.PitId

--Select Top 1000 * From dbo.BhpbioBlastBlockLumpFinesGrade


COMMIT

