--
-- This script renames the existing BPF0 flows so that the names are clearer when
-- the new weightometers are added
--
-- Renames:
--	WB-BeneFinesRaw -> WB-BeneFinesToBPF0-Raw
--	WB-M251-Corrected -> WB-BeneFinesToBPF0-Corrected
--

Set NoCount On
Go

Declare @FromId Varchar(128)
Declare @ToId Varchar(128)

-- drop the FK constraints from the given tables
Alter Table dbo.WeightometerFlowPeriod Drop Constraint [FK__WEIGHTOMETER_FLOW_PERIOD__WEIGHTOMETER]
Alter Table dbo.WeightometerLocation Drop Constraint [FK1_WEIGHTOMETER_LOCATION]
Alter Table dbo.WeightometerSample Drop Constraint [FK__WEIGHTOMETER_SAMPLE__WEIGHTOMETER]

--
-- Rename WB-BeneFinesRaw to WB-BeneFinesToBPF0-Raw
--
Set @FromId = 'WB-BeneFinesRaw'
Set @ToId = 'WB-BeneFinesToBPF0-Raw'

-- check that the FromId exists in weightometer
If Not Exists (Select top 1 * from dbo.Weightometer where Weightometer_Id = @FromId)
Begin
	Raiserror('Cannot rename Weightometer: FromId "%s" does not exist in the Weightometer table', 16, 1, @FromId)
	Return
End

-- Make sure that the ToId doesn't already exist, the rename would still work, but it would result
-- in merging the two weightometers
If Exists (Select top 1 * from dbo.Weightometer where Weightometer_Id = @ToId)
Begin
	Raiserror('Cannot rename Weightometer: ToId "%s" already exists in the Weightometer table', 16, 1, @ToId)
	Return
End

-- update the ids
Update dbo.WeightometerFlowPeriod Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.WeightometerLocation Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.WeightometerSample Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.Weightometer Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId

Print 'Rename complete: weightometer "' + @FromId + '" renamed to "' + @ToId + '"'


--
-- Rename WB-M251-Corrected to WB-BeneFinesToBPF0-Corrected
--
Set @FromId = 'WB-M251-Corrected'
Set @ToId = 'WB-BeneFinesToBPF0-Corrected'

-- check that the FromId exists in weightometer
If Not Exists (Select top 1 * from dbo.Weightometer where Weightometer_Id = @FromId)
Begin
	Raiserror('Cannot rename Weightometer: FromId "%s" does not exist in the Weightometer table', 16, 1, @FromId)
	Return
End

-- Make sure that the ToId doesn't already exist, the rename would still work, but it would result
-- in merging the two weightometers
If Exists (Select top 1 * from dbo.Weightometer where Weightometer_Id = @ToId)
Begin
	Raiserror('Cannot rename Weightometer: ToId "%s" already exists in the Weightometer table', 16, 1, @ToId)
	Return
End

-- update the ids
Update dbo.WeightometerFlowPeriod Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.WeightometerLocation Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.WeightometerSample Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId
Update dbo.Weightometer Set Weightometer_Id = @ToId Where Weightometer_Id = @FromId

Print 'Rename complete: weightometer "' + @FromId + '" renamed to "' + @ToId + '"'

-- re-add the constraints
Alter Table dbo.WeightometerFlowPeriod With Check Add Constraint [FK__WEIGHTOMETER_FLOW_PERIOD__WEIGHTOMETER] 
Foreign Key(Weightometer_Id)
References dbo.Weightometer (Weightometer_Id)

Alter Table dbo.WeightometerLocation With Check Add Constraint [FK1_WEIGHTOMETER_LOCATION]
Foreign Key(Weightometer_Id)
References dbo.Weightometer (Weightometer_Id)

Alter Table dbo.WeightometerSample With Check Add Constraint [FK__WEIGHTOMETER_SAMPLE__WEIGHTOMETER] 
Foreign Key(Weightometer_Id)
References dbo.Weightometer (Weightometer_Id)

