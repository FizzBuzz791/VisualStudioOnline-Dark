-- This script unapproves and reapproves selectively, for a specific tag, location type and date range
-- This is a post migration step
-- This script has been setup for F3PortBlendedAdjustment, all Hubs, since the LUMP_FINES_CUTOVER_DATE
DECLARE @month DATETIME
DECLARE @endTime DATETIME

DECLARE @tagId VARCHAR(50)
SET @tagId = 'F3PortBlendedAdjustment'

DECLARE @locationTypeId INTEGER
SET @locationTypeId = 2

DECLARE @userId INTEGER
SELECT @userId = UserId FROM SecurityUser WHERE NTAccountName like '%\loacs'

SELECT @month = convert(datetime,(SELECT Value FROM Setting WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE'))
SET @endTime = GETDATE()

WHILE @month <= @endTime
BEGIN
	PRINT convert(varchar,@month,103)

	DECLARE @iLocationId INTEGER
	SET @iLocationId = NULL

	SET @iLocationId = (SELECT TOP 1 Location_Id FROM Location WHERE Location_Type_Id = @locationTypeId AND Location_Id > IsNull(@iLocationId,0) ORDER BY Location_Id)

	WHILE NOT @iLocationId IS NULL
	BEGIN
		-- check if the value is approved for this month and location
		IF EXISTS(SELECT * FROM BhpbioApprovalData WHERE LocationId = @iLocationId AND ApprovedMonth = @month AND TagId = @tagId)
		BEGIN
			PRINT 'Unapproving: ' + convert(varchar, @iLocationId)
			-- unapprove
			exec dbo.UnapproveBhpbioApprovalData @tagId, @iLocationId, @month
			PRINT 'Approving: ' + convert(varchar, @iLocationId)
			-- approve
			exec dbo.ApproveBhpbioApprovalData @tagId, @iLocationId, @month, @userId
			PRINT 'Reapproved: ' + convert(varchar, @iLocationId)
		END

		SET @iLocationId = (SELECT TOP 1 Location_Id FROM Location WHERE Location_Type_Id = @locationTypeId AND Location_Id > IsNull(@iLocationId,0) ORDER BY Location_Id)
	END
	
	SET @month = DATEADD(month,1,@month)
END
