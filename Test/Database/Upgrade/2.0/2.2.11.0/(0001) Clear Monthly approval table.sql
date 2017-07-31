
--
-- Due to some support changes, we need to clear the MonthlyApproval table when the PROD environment is
-- upgraded. This table stops the recalc from looking at certain dates. Since we are introducing new grades
-- when we go to v2.2, we will need to run the recalc from the very start
--
Delete From dbo.MonthlyApproval
