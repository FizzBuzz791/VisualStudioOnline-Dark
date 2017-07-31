--
-- The totals are already reported, so we can't change them, but we do want to update
-- the historical data for the lump and fines because the definition of the calculation
-- has changed
--

declare @DateFrom datetime = '2009-01-01'
declare @DateTo datetime = '2017-07-31'
declare @CurrentMonth datetime = @DateFrom

while @CurrentMonth <= @DateTo
begin
	exec [dbo].SummariseBhpbioShippingTransaction_UF_ONLY @CurrentMonth, 2
	exec [dbo].SummariseBhpbioShippingTransaction_UF_ONLY @CurrentMonth, 4
	exec [dbo].SummariseBhpbioShippingTransaction_UF_ONLY @CurrentMonth, 6
	exec [dbo].SummariseBhpbioShippingTransaction_UF_ONLY @CurrentMonth, 8
	exec [dbo].SummariseBhpbioShippingTransaction_UF_ONLY @CurrentMonth, 133098
	set @CurrentMonth = dateadd(m, 1, @CurrentMonth)
	print @CurrentMonth
end

Go

-- drop the temp proc, so as not to fill the db with obsolete procs
IF OBJECT_ID('dbo.SummariseBhpbioShippingTransaction_UF_ONLY') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioShippingTransaction_UF_ONLY 
GO 