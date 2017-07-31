-----------------------------------------------------------------------------------------------------------------
-- PLEASE USE THE ApprovalUtilityScript instead of this script if possible...
--
-- The ApprovalUtilityScript takes temporary location hierarchy positions into account while this script does not
-----------------------------------------------------------------------------------------------------------------

DECLARE @removeTemporaryTableAfterScriptRun BIT

-------------------------------------------------------
-- Important: This script relies on data being setup in a temporary table
-- by the "DetermineApprovalStatus.sql script"
-- See readme.txt in the same folder as this script for instructions
-------------------------------------------------------

-------------------------------------------------------------------------------------
-- Set the control variables below required by the script
-------------------------------------------------------------------------------------
SET @removeTemporaryTableAfterScriptRun = 0 -- this flag controls whether the temporary table is removed after the run or not
-------------------------------------------------------------------------------------

	-- variables used to accept query parameters
	DECLARE @tagId NVARCHAR(31)
	DECLARE @locationId INTEGER
	DECLARE @digblockId NVARCHAR(31)
	DECLARE @approvedMonth DATETIME

	-- create a cursor used to process all approved rows within range
	DECLARE curData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
									FROM #BhpbioTemporaryApprovalStatus tas
									WHERE tas.IsApproved = 1
									ORDER BY tas.ApprovalMonth, tas.ApprovalLevel, tas.LocationId

	-- open the cursor and fetch the first row
	OPEN curData

	FETCH NEXT FROM curData INTO @tagId, @locationId, @digblockId, @approvedMonth

	-- while a row was fetched
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT convert(varchar, GetDate(), 108) + ': About to unapprove Month: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)
		
		IF @tagId = 'Digblock'
		BEGIN
			-- perform the unapproval
			exec dbo.UnapproveBhpbioApprovalDigblock	@iDigblockId = @digblockId,
													@iApprovalMonth = @approvedMonth
		END
		ELSE
		BEGIN
			-- perform the unapproval
			exec dbo.UnapproveBhpbioApprovalData	@iTagId = @tagId,
												@iLocationId = @locationId,
												@iApprovalMonth = @approvedMonth
		END
		
													  
		PRINT convert(varchar, GetDate(), 108) + ': Finished unapproving: ' + convert(varchar,@approvedMonth) + ', Tag Id: ' + @tagId + ', Location Id: ' + convert(varchar, @locationId)

		-- fetch the next row
		FETCH NEXT FROM curData INTO @tagId, @locationId, @digblockId, @approvedMonth
	END

	CLOSE curData
	DEALLOCATE curData

IF @removeTemporaryTableAfterScriptRun = 1 AND OBJECT_ID('tempdb.dbo.#BhpbioTemporaryApprovalStatus') IS NOT NULL
BEGIN
	DROP TABLE #BhpbioTemporaryApprovalStatus
END