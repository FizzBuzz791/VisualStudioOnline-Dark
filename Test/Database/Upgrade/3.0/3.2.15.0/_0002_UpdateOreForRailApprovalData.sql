-- update Ore For Rail summary data
DECLARE @month DATETIME
DECLARE @maxMonth DATETIME
DECLARE @minAllowedMonth DATETIME
SET @minAllowedMonth = '2009-04-01'

SELECT @month = MIN(s.SummaryMonth),@maxMonth = MAX(s.SummaryMonth) 
	FROM BhpbioSummaryEntry se INNER JOIN BhpbioSummary s ON s.SummaryId = se.SummaryId
	WHERE se.SummaryEntryTypeId = 22 AND se.LocationId = 8 -- NJV

IF @month < @minAllowedMonth
BEGIN
	SET @month = @minAllowedMonth
END

WHILE @month <= @maxMonth
BEGIN
	IF EXISTS (SELECT * FROM BhpbioApprovalData WHERE TagId = 'F25OreForRail' AND LocationId = 8 AND ApprovedMonth = @month)
	BEGIN
		exec dbo.SummariseBhpbioOreForRail @month,8
	END
	SET @month = DATEADD(month,1,@month)
END