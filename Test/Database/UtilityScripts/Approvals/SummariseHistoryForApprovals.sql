-----------------------------------------------------------------------------------------------------------------
-- PLEASE USE THE ApprovalUtilityScript instead of this script if possible...
--
-- The ApprovalUtilityScript takes temporary location hierarchy positions into account while this script does not
-----------------------------------------------------------------------------------------------------------------

DECLARE @startMonth DATETIME
DECLARE @endMonth DATETIME

-------------------------------------------------------------------------------------
-- SET THE DATE RANGE BELOW TO LIMIT THE AMOUNT OF SUMMARY DATA BEING BUILT / REBUILT
SET @startMonth = '2009-03-01'
SET @endMonth = '2009-04-01'
-------------------------------------------------------------------------------------

-- variables used to accept query parameters
DECLARE @tagId VARCHAR(31)
DECLARE @locationId INTEGER
DECLARE @approvedMonth DATETIME
DECLARE @userId INTEGER

-- create a cursor used to process all approved rows within range
DECLARE curApprovedData CURSOR FOR	SELECT bad.TagId, bad.LocationId, bad.ApprovedMonth, bad.UserId
									FROM dbo.BhpbioApprovalData bad
										INNER JOIN dbo.Location l ON l.Location_Id = bad.LocationId
									WHERE bad.ApprovedMonth BETWEEN @startMonth AND @endMonth
									ORDER BY bad.ApprovedMonth, l.Location_Type_Id DESC, bad.LocationId, bad.TagId
-- Note the data is processed in month order and then in order of location type Id descending.. this means summarise data for deeper levels before top levels 
-- as would be the case if the summaries were triggered manually by approvals

-- open the cursor and fetch the first row
OPEN curApprovedData

FETCH NEXT FROM curApprovedData INTO @tagId, @locationId, @approvedMonth, @userId

-- while a row was fetched
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT convert(varchar, GetDate(), 108) + ': About to summarise Month: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)
	-- perform the data summarisation associated with the approval
	-- ie the same summarisation as if the data was just approved
	exec dbo.SummariseBhpbioDataRelatedToApproval @iTagId = @tagId,
												  @iLocationId = @locationId,
												  @iApprovalMonth = @approvedMonth,
												  @iUserId = @userId
												  
	PRINT convert(varchar, GetDate(), 108) + ': Finished summarising: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)

	-- fetch the next row
	FETCH NEXT FROM curApprovedData INTO @tagId, @locationId, @approvedMonth, @userId
END

CLOSE curApprovedData
DEALLOCATE curApprovedData
