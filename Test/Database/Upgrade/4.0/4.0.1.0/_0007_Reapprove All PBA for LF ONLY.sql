--
-- The totals are already reported, so we can't change them, but we do want to update
-- the historical data for the lump and fines because the definition of the calculation
-- has changed
--

declare @DateFrom datetime = '2014-09-01'
declare @DateTo datetime = '2017-07-31'
declare @CurrentMonth datetime = @DateFrom

while @CurrentMonth <= @DateTo
begin
	exec [dbo].TmpSummariseBhpbioPortBlendedAdjustment_LFOnly @CurrentMonth, 2
	exec [dbo].TmpSummariseBhpbioPortBlendedAdjustment_LFOnly @CurrentMonth, 4
	exec [dbo].TmpSummariseBhpbioPortBlendedAdjustment_LFOnly @CurrentMonth, 6
	exec [dbo].TmpSummariseBhpbioPortBlendedAdjustment_LFOnly @CurrentMonth, 8
	exec [dbo].TmpSummariseBhpbioPortBlendedAdjustment_LFOnly @CurrentMonth, 133098
	set @CurrentMonth = dateadd(m, 1, @CurrentMonth)
	print @CurrentMonth
end

Go

-- drop the temp proc, so as not to fill the db with obsolete procs
IF OBJECT_ID('dbo.TmpSummariseBhpbioPortBlendedAdjustment_LFOnly') IS NOT NULL
     DROP PROCEDURE dbo.TmpSummariseBhpbioPortBlendedAdjustment_LFOnly 
GO 