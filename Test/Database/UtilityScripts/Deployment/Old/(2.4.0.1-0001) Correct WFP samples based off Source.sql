--
-- The purpose of this script is to move weightometer samples from one weightometer to another based off the weightometer
-- flow period table.
--
-- This is required because changes to the WFP table will not effect existing data unless it changes, even when the Production
-- import is run again.
--
-- Current the script will only compare the source stockpile to see if it matches a different weightometer
--
-- This was developed as part of WREC-1130 to correct the 25-PostC2ToTrainRake weightometer. It can safely be run more 
-- than once, the second time it will do nothing as there will be no matching samples
--
GO

declare @StartDate datetime = '2015-07-08'
declare @TargetWeightometerId varchar(64) = '25-PostC2ToTrainRake'

declare @MisappliedSamples table (
	Weightometer_Sample_Id int
)

--
-- We are looking for all samples that match the source sp of the WFP record
-- but are applied to a DIFFERENT weightometer. These are the ones we have to 
-- move over
--
Insert Into @MisappliedSamples 
	select
		Weightometer_Sample_Id
	from WeightometerSample ws
		inner join WeightometerFlowPeriod wfp 
			on (wfp.Weightometer_Id = @TargetWeightometerId)
			and (ws.Weightometer_Sample_Date < wfp.End_Date or wfp.End_Date is null)
		inner join Stockpile ssp 
			on ssp.Stockpile_Id = ws.Source_Stockpile_Id
		inner join Stockpile dsp 
			on dsp.Stockpile_Id = ws.Destination_Stockpile_Id
	where ssp.Stockpile_Id = wfp.Source_Stockpile_Id
		and ws.Weightometer_Sample_Date > @StartDate
		and ws.Weightometer_Id like '25-%'
		and dsp.Stockpile_Name like '%train rake%'
		and ws.Weightometer_Id != @TargetWeightometerId
	order by weightometer_sample_date desc

select COUNT(*) as SampleCount from @MisappliedSamples

-- We just change the weightometer_id. It is important we do it this way instead of 
-- inserting new records so that the ImportSyncRow ids match with the WeightometerSample
-- records
Update WeightometerSample 
Set Weightometer_Id = @TargetWeightometerId 
Where Weightometer_Sample_Id in (Select Weightometer_Sample_Id From @MisappliedSamples)

--
-- now raise the CVF in case the samples are used in other calculations
-- Do it from the start date set above until the current date. We could make this more
-- efficent by getting the minimum sample date from the query above
--
DECLARE @DateFrom DATETIME = @StartDate
DECLARE @DateTo DATETIME
DECLARE @CurrentProcessingDate DATETIME

SET @DateTo = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) 
SET @CurrentProcessingDate = @DateFrom

WHILE @CurrentProcessingDate <= @DateTo
BEGIN
	PRINT CAST(@CurrentProcessingDate AS VARCHAR)
	EXEC CalcVirtualFlowRaise @CurrentProcessingDate
	SET @CurrentProcessingDate = DATEADD(DAY, 1, @CurrentProcessingDate)
END

print 'Running CVF'
EXEC CalcVirtualflow

GO