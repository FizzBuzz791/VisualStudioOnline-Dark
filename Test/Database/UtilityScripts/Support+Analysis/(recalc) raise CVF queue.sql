--
-- The will raise the CVF queue enties for the given date range
-- suprisingly there isn't a proc for this already
--
DECLARE @DateFrom DATETIME = '2015-01-01'
DECLARE @DateTo DATETIME = '2015-05-01'
DECLARE @CurrentProcessingDate DATETIME

--SET @DateTo = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) 
SET @CurrentProcessingDate = @DateFrom

WHILE @CurrentProcessingDate <= @DateTo
BEGIN
	PRINT CAST(@CurrentProcessingDate AS VARCHAR)
	EXEC CalcVirtualFlowRaise @CurrentProcessingDate
	SET @CurrentProcessingDate = DATEADD(DAY, 1, @CurrentProcessingDate)
END

print 'Running CVF'
EXEC CalcVirtualflow
