-----------------------------------------------------------------------------------------------------------------
-- PLEASE USE THE ApprovalUtilityScript instead of this script if possible...
--
-- The ApprovalUtilityScript takes temporary location hierarchy positions into account while this script does not
-----------------------------------------------------------------------------------------------------------------

DECLARE @userName NVARCHAR(31)
DECLARE @userId INTEGER
DECLARE @removeTemporaryTableAfterScriptRun BIT

-------------------------------------------------------
-- Important: This script relies on data being setup in a temporary table
-- by the "DetermineApprovalStatus.sql script"
-- See readme.txt in the same folder as this script for instructions
-------------------------------------------------------

-------------------------------------------------------------------------------------
-- Set the control variables below required by the script
-------------------------------------------------------------------------------------
SET @userName = 'APAC\welln' -- this username will be the user who appeared to make the approvals
SET @removeTemporaryTableAfterScriptRun = 1 -- this flag controls whether the temporary table is removed after the run or not
-------------------------------------------------------------------------------------

SELECT @userId = su.UserId 
FROM dbo.SecurityUser su
WHERE su.NTAccountName = @userName

IF @userId IS NULL
BEGIN
	-- a userId is required... throw an error if there is no matching username found
	RAISERROR('There was no matching user record found for the specified username', 1, 0)
END
ELSE
BEGIN
	-- variables used to accept query parameters
	DECLARE @tagId NVARCHAR(31)
	DECLARE @locationId INTEGER
	DECLARE @digblockId NVARCHAR(31)
	DECLARE @approvedMonth DATETIME

	-- create a cursor used to process all approved rows within range
	DECLARE curData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
									FROM #BhpbioTemporaryApprovalStatus tas
									WHERE tas.IsApproved = 0
									ORDER BY tas.ApprovalMonth, tas.ApprovalLevel, tas.LocationId

	-- open the cursor and fetch the first row
	OPEN curData

	FETCH NEXT FROM curData INTO @tagId, @locationId, @digblockId, @approvedMonth

	-- while a row was fetched
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT convert(varchar, GetDate(), 108) + ': About to approve Month: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)
		
		IF @tagId = 'Digblock'
		BEGIN
			-- perform the approval
			exec dbo.ApproveBhpbioApprovalDigblock	@iDigblockId = @digblockId,
													@iApprovalMonth = @approvedMonth,
													@iUserId = @userId
		END
		ELSE
		BEGIN
			-- perform the approval
			exec dbo.ApproveBhpbioApprovalData	@iTagId = @tagId,
												@iLocationId = @locationId,
												@iApprovalMonth = @approvedMonth,
												@iUserId = @userId
		END
		
													  
		PRINT convert(varchar, GetDate(), 108) + ': Finished approving: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)

		-- fetch the next row
		FETCH NEXT FROM curData INTO @tagId, @locationId, @digblockId, @approvedMonth
	END

	CLOSE curData
	DEALLOCATE curData
END

IF @removeTemporaryTableAfterScriptRun = 1 AND OBJECT_ID('tempdb.dbo.#BhpbioTemporaryApprovalStatus') IS NOT NULL
BEGIN
	DROP TABLE #BhpbioTemporaryApprovalStatus
END