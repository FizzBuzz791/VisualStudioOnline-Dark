
--
-- This script fixes issue WREC-1130
--
-- The output stockpile has changed for the 25-C2 crusher. This means that 25-PostC2ToTrainRake movements
-- no longer get collected.
--
-- This can be fixed just by adding a new WFP record, and putting an end date on the old one, that is what
-- this script does
--
GO

Declare @SourceStockpileId Int
Select @SourceStockpileId = Stockpile_Id From Stockpile Where Stockpile_Name = '25-16001CONE'

If (Select Count(*) From WeightometerFlowPeriod Where Weightometer_Id = '25-PostC2ToTrainRake' AND Source_Stockpile_Id = @SourceStockpileId) = 0
Begin
	
	If @SourceStockpileId Is Not Null
	Begin

		Update WeightometerFlowPeriod
			Set End_Date = '2015-07-08'
		Where Weightometer_Id = '25-PostC2ToTrainRake'
			And Source_Stockpile_Id = (Select Stockpile_Id From Stockpile Where Stockpile_Name = '25-15001CONE')

		Insert Into  WeightometerFlowPeriod (
			Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, 
			Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, 
			Is_Calculated, Processing_Order_No
		)
			Select '25-PostC2ToTrainRake', Null, @SourceStockpileId, Null, Null, Null, Null, Null, 0, 34
	End
	Else
	Begin
		Print 'Could not find Stockpile_Id from Stockpile "25-16001CONE"'
	End
End
Else
Begin
	Print 'Skipping: 25-PostC2ToTrainRake already has a WeightometerFlowPeriod record for the source stockpile'
End

GO