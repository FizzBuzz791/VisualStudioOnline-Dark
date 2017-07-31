declare @RecalcStart datetime
declare @RecalcEnd datetime

-- The start of the recalc has to be the first day after the recalc end date from the 
-- MonthlyApproval table.
--
-- The end of the recalc will be yesterday
Select @RecalcStart = dateadd(m, 1, MAX(Monthly_Approval_Month)) From MonthlyApproval
Set @RecalcEnd = CAST(dateadd(d, -1, GetDate()) As Date)

-- queue the recalc. This will automatically kick off a L2 after the L1 is complete, 
-- but it will NOT queue a CVF
exec dbo.RecalcL1RaisePeriod @RecalcStart, @RecalcEnd
