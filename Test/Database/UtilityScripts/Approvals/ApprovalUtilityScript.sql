--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- This is a utility script used to perform Approval system related data corrections and queries
--
-- The operation to be performed and the set of data in scope for the operation is controlled by a 
-- number of variables that should be initialised prior to execution
--
-- See the script block beginning with the comment '-- Script variable initilization'
--
-- Operations: The following 5 operations are possible with this script:
--		> output a list of details about required approvals
--		> output a list of required approvals for which there is no matching actual approval (missing approvals)
--		> output a list of details about actual approvals
--		> unapprove actual approvals
--		> approve missing approvals
--
-- Filter Variables:
--		@topLevelLocationTypeId		-- sets the highest level location type to be included (one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock)
--		@lowestLevelLocationTypeId  -- sets the lowestlevel location type to be included (one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock)
--		@topLevelLocationName		-- the name of the top level location which represents the top of the location branch to operate within
--		@earliestMonth				-- the first month in the set to process
--		@latestMonth				-- the latest month in the set to process
--
--
-- Control Variables:
--		@outputRequiredApprovals					-- If 1, details of required approvals will be output
--		@outputRequiredApprovalsShowsMissingOnly	-- If 1, modifies the required approvals output such that only missing approvals are output (if @outputRequiredApprovals is 0, then this variable has no effect)
--		@outputActualApprovals						-- If 1, details of actual approvals will be output
--		@unapproveActualApprovals					-- If 1, actual approvals will be unapproved
--		@approveMissingRequiredApprovals			-- If 1, missing approvals will be approved
--
--
-- NOTE: Unapproving and Approving in one script run is not supported
--
-- Other Variables:
--		@approvalUserName							-- A username used to find a user Id to associate with approvals
--
-- Warning:
--		Copying approval data prior to changes is recommended (ie BhpbioApprovalData and BhpbioApprovalDigblock)
--
------------------------------------------------------------------------------------------------

DECLARE @ltCompany INT
DECLARE @ltHub INT
DECLARE @ltSite INT
DECLARE @ltPit INT
DECLARE @ltBench INT
DECLARE @ltBlast INT
DECLARE @ltBlock INT

SET @ltCompany = 1
SET @ltHub = 2
SET @ltSite = 3
SET @ltPit = 4
SET @ltBench = 5
SET @ltBlast = 6
SET @ltBlock = 7

DECLARE @earliestMonth DATETIME
DECLARE @latestMonth DATETIME
DECLARE @topLevelLocationTypeId INT
DECLARE @topLevelLocationName nvarchar(31)
DECLARE @lowestLevelLocationTypeId INT
DECLARE @approvalUserName NVARCHAR(31)
DECLARE @outputRequiredApprovals BIT
DECLARE @outputActualApprovals BIT
DECLARE @unapproveActualApprovals BIT
DECLARE @approveMissingRequiredApprovals BIT
DECLARE @outputRequiredApprovalsShowsMissingOnly BIT
DECLARE @lumpFinesCutover DATETIME

-------------------------------------------------
-- Script variable initilization
-------------------------------------------------
SET @earliestMonth = '2014-05-01'	-- the earliest month to be matched
SET @latestMonth = '2014-05-30'		-- the latest month to be matched

-- set the range of location types to be included
SET @topLevelLocationTypeId = @ltHub	-- one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock
SET @lowestLevelLocationTypeId = @ltBlock	-- one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock
SET @topLevelLocationName = 'NJV'			-- the name of the top level location used to filter this operation

SET @outputRequiredApprovals = 0				-- if set to 1, all required approvals will be output whether they are approved or not
SET @outputRequiredApprovalsShowsMissingOnly = 0	-- if set to 1, when required approvals are listed (above option), only the required approvals that are missing approval will actually be output	
SET @outputActualApprovals = 0						-- if set to 1, the details of all actual approvals will be output

SET @unapproveActualApprovals = 0			-- If this is set to 1, all actual approvals matching the criteria will be unapproved
SET @approveMissingRequiredApprovals = 1	-- If this is set to 1, all approvals required but currently not approved will be automatically approved
-- NOTE: If both unapprove and approve flags are set at the same time then, all actual approvals will be unapproved, then all required approvals will be reapproved

SET @approvalUserName = 'APAC\c5patg'
-------------------------------------------------

SELECT @lumpFinesCutover = Value
FROM Setting 
WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE'

IF @lumpFinesCutover IS NULL
BEGIN
	RAISERROR ('Unable to determine the LUMP / FINES CUTOVER DATE.', 11, 1)
END

DECLARE @topLevelLocationId INT
DECLARE @approvalUserId INTEGER

BEGIN TRY
	BEGIN TRANSACTION
	
	IF @approveMissingRequiredApprovals = 1
	BEGIN
		IF @unapproveActualApprovals = 1
		BEGIN
			RAISERROR ('Unapproving and Approving in one script run is not supported.', 11, 1)
		END
		
		SELECT @approvalUserId = su.UserId 
		FROM dbo.SecurityUser su
		WHERE su.NTAccountName = @approvalUserName
		
		IF @approvalUserId IS NULL
		BEGIN
			RAISERROR ('Approval username was not recognised.', 11, 1)
		END
	END

	-- look up the top level location Id based on the name, type and period
	SELECT @topLevelLocationId = ld.Location_Id
	FROM BhpbioLocationDate ld
		INNER JOIN Location l ON l.Location_Id = ld.Location_Id
	WHERE l.Name = @topLevelLocationName AND ld.Location_Type_Id = @topLevelLocationTypeId
	AND @earliestMonth BETWEEN ld.Start_Date AND ld.End_Date

	IF @topLevelLocationId IS NULL
	BEGIN 
		RAISERROR ('Location with the specified name was not found at the specified location type within the date range', 11, 1)
	END

	IF EXISTS (	SELECT * 
				FROM BhpbioLocationDate ld
				INNER JOIN Location l ON l.Location_Id = ld.Location_Id
				WHERE	l.Name = @topLevelLocationName AND ld.Location_Type_Id = @topLevelLocationTypeId
						AND (
							-- if an override starts in the range
							(ld.Start_Date > @earliestMonth AND ld.Start_Date <= @latestMonth)
							OR
							-- or ends in the range
							(ld.Start_Date <= @earliestMonth AND ld.End_Date < @earliestMonth)
						)
				)
	BEGIN
		RAISERROR('This script cannot be run against a location that has a location override within the date range specified', 11, 1)
	END

	-- find all locations within this branch
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId,IncludeStart,IncludeEnd)
	)

	INSERT INTO @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@topLevelLocationId, 0, NULL, @earliestMonth, @latestMonth)

	-- Table for storing the required approvals
	DECLARE @BhpbioRequiredApprovals TABLE
	(
		ApprovalMonth DateTime,
		LocationId INT,
		DigblockId VARCHAR(31),
		TagId VARCHAR(63),
		IsApproved BIT,
		ApprovalLevel VARCHAR(31)
	)

	-- Table for storing the approvals that have actually been made.. whether or not they have been approved
	DECLARE @BhpbioActualApprovals TABLE
	(
		ApprovalMonth DateTime,
		LocationId INT,
		DigblockId VARCHAR(31),
		TagId VARCHAR(63),
		ApprovalLevel VARCHAR(31)
	)

	IF @ltBlock BETWEEN @topLevelLocationTypeId AND @lowestLevelLocationTypeId
	BEGIN
		IF @outputRequiredApprovals = 1 OR @approveMissingRequiredApprovals = 1
		BEGIN
			-- Block approvals: Required
			INSERT INTO @BhpbioRequiredApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				IsApproved,
				ApprovalLevel
			)
			SELECT DISTINCT ActivityMonth, 
					dl.Location_Id,
					d.Digblock_Id,
					'Digblock',
					CASE WHEN bad.DigblockId IS NULL THEN 0 ELSE 1 END As IsApproved,
					'1: Digblock'
			FROM 
			(
				SELECT DISTINCT d1.Digblock_Id, dbo.GetDateMonth(h1.Haulage_Date) AS ActivityMonth
					FROM dbo.Digblock d1
					INNER JOIN dbo.DigblockLocation dl1 ON dl1.Digblock_Id = d1.Digblock_Id
					INNER JOIN @Location locFilter ON locFilter.LocationId = dl1.Location_Id
					INNER JOIN dbo.Haulage h1 ON h1.Source_Digblock_Id = d1.Digblock_Id
				UNION
				SELECT DISTINCT d2.Digblock_Id, dbo.GetDateMonth(RM.DateFrom) AS ActivityMonth
					FROM dbo.Digblock d2
					INNER JOIN dbo.DigblockLocation dl2 ON dl2.Digblock_Id = d2.Digblock_Id
					INNER JOIN @Location locFilter ON locFilter.LocationId = dl2.Location_Id
					INNER JOIN dbo.BhpbioImportReconciliationMovement RM ON RM.BlockLocationId = dl2.Location_Id
					WHERE RM.MinedPercentage IS NOT NULL 
					
			) d
				INNER JOIN dbo.DigblockLocation dl ON dl.Digblock_Id = d.Digblock_Id
				INNER JOIN dbo.BhpbioLocationDate block ON block.Location_Id = dl.Location_Id AND d.ActivityMonth BETWEEN block.Start_Date and block.End_Date
				LEFT JOIN dbo.BhpbioApprovalDigblock bad ON bad.DigblockId = d.Digblock_Id
				AND bad.ApprovedMonth = d.ActivityMonth
			WHERE d.ActivityMonth BETWEEN @earliestMonth AND @latestMonth
			ORDER BY 1, 2, 3, 4, 5
		END
		
		IF @outputActualApprovals = 1 OR @unapproveActualApprovals = 1
		BEGIN
			-- block actual approvals
			INSERT INTO @BhpbioActualApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				ApprovalLevel
			)
			SELECT DISTINCT bad.ApprovedMonth, 
					dl.Location_Id,
					d.Digblock_Id,
					'Digblock',
					'1: Digblock'
			FROM dbo.BhpbioApprovalDigblock bad
				INNER JOIN dbo.Digblock d ON d.Digblock_Id = bad.DigblockId
				INNER JOIN dbo.DigblockLocation dl ON dl.Digblock_Id = bad.DigblockId
				INNER JOIN @Location locFilter ON locFilter.LocationId = dl.Location_Id
				INNER JOIN dbo.BhpbioLocationDate block ON block.Location_Id = dl.Location_Id AND bad.ApprovedMonth BETWEEN block.Start_Date and block.End_Date
			WHERE bad.ApprovedMonth BETWEEN @earliestMonth AND @latestMonth
			ORDER BY 1, 2, 3, 4
		END
	END

	IF @ltPit BETWEEN @topLevelLocationTypeId AND @lowestLevelLocationTypeId
	BEGIN
		IF @outputRequiredApprovals = 1 OR @approveMissingRequiredApprovals = 1
		BEGIN
			-- pit approvals
			INSERT INTO @BhpbioRequiredApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				IsApproved,
				ApprovalLevel
			)
			SELECT DISTINCT months.Start_Date as [Month], 
					pit.Location_Id,
					null,
					brdt.TagId, 
					CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
					'2: Pit'
			FROM 
				dbo.BhpbioLocationDate pit
				INNER JOIN @Location locFilter ON locFilter.LocationId = pit.Location_Id
				CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@earliestMonth,@latestMonth,'MONTH',1)) months
				CROSS JOIN dbo.BhpbioReportDataTags brdt
				LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = pit.Location_Id
					AND bad.ApprovedMonth =  months.Start_Date
					AND bad.TagId = brdt.TagId
			WHERE pit.Location_Type_Id = @ltPit
				AND (brdt.TagId like 'F1%' OR brdt.TagId like 'Other%')
				AND (months.Start_Date >= @lumpFinesCutover OR NOT (brdt.TagId like '%Lump%' Or brdt.TagId like '%Fines%'))
			ORDER BY 1, 2, 3, 4
		END
		
		IF @outputActualApprovals = 1 OR @unapproveActualApprovals = 1
		BEGIN
			-- pit actual approvals
			INSERT INTO @BhpbioActualApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				ApprovalLevel
			)
			SELECT bad.ApprovedMonth, 
					pit.Location_Id,
					null,
					brdt.TagId, 
					'2: Pit'
			FROM dbo.BhpbioApprovalData bad
				INNER JOIN BhpbioReportDataTags brdt ON brdt.TagId = bad.TagId
				INNER JOIN dbo.BhpbioLocationDate pit ON pit.Location_Id = bad.LocationId AND bad.ApprovedMonth BETWEEN pit.Start_Date and pit.End_Date
				INNER JOIN @Location locFilter ON locFilter.LocationId = pit.Location_Id
			WHERE bad.ApprovedMonth BETWEEN @earliestMonth AND @latestMonth
				AND pit.Location_Type_Id = @ltPit
			ORDER BY 1, 2, 3, 4
		END
	END

	IF @ltSite BETWEEN @topLevelLocationTypeId AND @lowestLevelLocationTypeId
	BEGIN
		IF @outputRequiredApprovals = 1 OR @approveMissingRequiredApprovals = 1
		BEGIN
			-- site approvals: required
			INSERT INTO @BhpbioRequiredApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				IsApproved,
				ApprovalLevel
			)

			SELECT months.Start_Date as [Month], ste.Location_Id, null, brdt.TagId,
				CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
				'3: Site'
			FROM dbo.BhpbioLocationDate ste
				INNER JOIN @Location locFilter ON locFilter.LocationId = ste.Location_Id
				CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@earliestMonth,@latestMonth,'MONTH',1)) months
				CROSS JOIN dbo.BhpbioReportDataTags brdt
				LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = ste.Location_Id
					AND bad.ApprovedMonth = months.Start_Date
					AND bad.TagId = brdt.TagId
			WHERE ste.Location_Type_Id = @ltSite
				AND months.Start_Date BETWEEN ste.Start_Date AND ste.End_Date
				AND (brdt.TagId like 'F2%'
					AND brdt.TagId not like 'F25%')
				AND (months.Start_Date >= @lumpFinesCutover OR NOT (brdt.TagId like '%Lump%' Or brdt.TagId like '%Fines%'))
			ORDER BY 1, 2, 3, 4
		END
		
		IF @outputActualApprovals = 1 OR @unapproveActualApprovals = 1
		BEGIN
			-- site actual approvals
			INSERT INTO @BhpbioActualApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				ApprovalLevel
			)
			SELECT bad.ApprovedMonth as [Month],
				 ste.Location_Id, 
				 null, 
				 brdt.TagId,
				 '3: Site'
			FROM dbo.BhpbioApprovalData bad
				INNER JOIN BhpbioReportDataTags brdt ON brdt.TagId = bad.TagId
				INNER JOIN dbo.BhpbioLocationDate ste ON ste.Location_Id = bad.LocationId AND bad.ApprovedMonth BETWEEN ste.Start_Date and ste.End_Date
				INNER JOIN @Location locFilter ON locFilter.LocationId = ste.Location_Id
			WHERE bad.ApprovedMonth BETWEEN @earliestMonth AND @latestMonth
				AND ste.Location_Type_Id = @ltSite
			ORDER BY 1, 2, 3, 4
		END
	END

	IF @ltHub BETWEEN @topLevelLocationTypeId AND @lowestLevelLocationTypeId
	BEGIN
		IF @outputRequiredApprovals = 1 OR @approveMissingRequiredApprovals = 1
		BEGIN
			-- hub approvals
			INSERT INTO @BhpbioRequiredApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				IsApproved,
				ApprovalLevel
			)
			SELECT  months.Start_Date as [Month], hub.Location_Id as HubId, null,
				brdt.TagId, CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
				'4: Hub'
			FROM dbo.BhpbioLocationDate hub
				INNER JOIN @Location locFilter ON locFilter.LocationId = hub.Location_Id
				INNER JOIN dbo.LocationType lt ON lt.Location_Type_Id = hub.Location_Type_Id
				CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@earliestMonth,@latestMonth,'MONTH',1)) months
				CROSS JOIN dbo.BhpbioReportDataTags brdt
				LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = hub.Location_Id
					AND bad.ApprovedMonth = months.Start_Date
					AND bad.TagId = brdt.TagId
			WHERE hub.Location_Type_Id = @ltHub
				AND (brdt.TagId like 'F3%'
					OR brdt.TagId like 'F25%')
				AND (months.Start_Date >= @lumpFinesCutover OR NOT (brdt.TagId like '%Lump%' Or brdt.TagId like '%Fines%'))
			ORDER BY 1, 2, 3, 4
		
		END
		
		IF @outputActualApprovals = 1 OR @unapproveActualApprovals = 1
		BEGIN
			-- hub actual approvals
			INSERT INTO @BhpbioActualApprovals
			(
				ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				ApprovalLevel
			)
			SELECT bad.ApprovedMonth as [Month], 
				hub.Location_Id as HubId, 
				null,
				brdt.TagId,
				'4: Hub'
			FROM dbo.BhpbioApprovalData bad
				INNER JOIN BhpbioReportDataTags brdt ON brdt.TagId = bad.TagId
				INNER JOIN dbo.BhpbioLocationDate hub ON hub.Location_Id = bad.LocationId AND bad.ApprovedMonth BETWEEN hub.Start_Date and hub.End_Date
				INNER JOIN @Location locFilter ON locFilter.LocationId = hub.Location_Id
			WHERE bad.ApprovedMonth BETWEEN @earliestMonth AND @latestMonth
				AND hub.Location_Type_Id = @ltHub
			ORDER BY 1, 2, 3, 4
		END
	END

	IF @outputRequiredApprovals = 1
	BEGIN
		SELECT	ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				IsApproved,
				ApprovalLevel,
				CASE WHEN ggggGrandParentLoc.Name IS NULL THEN '' ELSE ggggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN gggGrandParentLoc.Name IS NULL THEN '' ELSE gggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN ggGrandParentLoc.Name IS NULL THEN '' ELSE ggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN greatGrandParentLoc.Name IS NULL THEN '' ELSE greatGrandParentLoc.Name + '-> ' END
			+	CASE WHEN grandParentLoc.Name IS NULL THEN '' ELSE grandParentLoc.Name + '-> ' END
			+	CASE WHEN parentLoc.Name IS NULL THEN '' ELSE parentLoc.Name + '-> ' END
			+	CASE WHEN loc.Name IS NULL THEN '' ELSE loc.Name END
			As LocationString
		FROM @BhpbioRequiredApprovals bra
			LEFT JOIN dbo.Location loc ON loc.Location_Id = bra.LocationId
			LEFT JOIN dbo.Location parentLoc ON parentLoc.Location_Id = loc.Parent_Location_Id
			LEFT JOIN dbo.Location grandParentLoc ON grandParentLoc.Location_Id = parentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location greatGrandParentLoc ON greatGrandParentLoc.Location_Id = grandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location ggGrandParentLoc ON ggGrandParentLoc.Location_Id = greatGrandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location gggGrandParentLoc ON gggGrandParentLoc.Location_Id = ggGrandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location ggggGrandParentLoc ON ggggGrandParentLoc.Location_Id = gggGrandParentLoc.Parent_Location_Id
		WHERE (IsApproved = 0 OR @outputRequiredApprovalsShowsMissingOnly = 0)
		ORDER BY bra.ApprovalMonth, bra.ApprovalLevel, bra.TagId, 7 
	END

	IF @outputActualApprovals= 1
	BEGIN
		SELECT	ApprovalMonth,
				LocationId,
				DigblockId,
				TagId,
				1 as IsApproved,
				ApprovalLevel,
				CASE WHEN ggggGrandParentLoc.Name IS NULL THEN '' ELSE ggggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN gggGrandParentLoc.Name IS NULL THEN '' ELSE gggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN ggGrandParentLoc.Name IS NULL THEN '' ELSE ggGrandParentLoc.Name + '-> ' END
			+	CASE WHEN greatGrandParentLoc.Name IS NULL THEN '' ELSE greatGrandParentLoc.Name + '-> ' END
			+	CASE WHEN grandParentLoc.Name IS NULL THEN '' ELSE grandParentLoc.Name + '-> ' END
			+	CASE WHEN parentLoc.Name IS NULL THEN '' ELSE parentLoc.Name + '-> ' END
			+	CASE WHEN loc.Name IS NULL THEN '' ELSE loc.Name END
			As LocationString
		FROM @BhpbioActualApprovals baa
			LEFT JOIN dbo.Location loc ON loc.Location_Id = baa.LocationId
			LEFT JOIN dbo.Location parentLoc ON parentLoc.Location_Id = loc.Parent_Location_Id
			LEFT JOIN dbo.Location grandParentLoc ON grandParentLoc.Location_Id = parentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location greatGrandParentLoc ON greatGrandParentLoc.Location_Id = grandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location ggGrandParentLoc ON ggGrandParentLoc.Location_Id = greatGrandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location gggGrandParentLoc ON gggGrandParentLoc.Location_Id = ggGrandParentLoc.Parent_Location_Id
			LEFT JOIN dbo.Location ggggGrandParentLoc ON ggggGrandParentLoc.Location_Id = gggGrandParentLoc.Parent_Location_Id
		ORDER BY baa.ApprovalMonth, baa.ApprovalLevel, baa.TagId, 7 
	END

	IF @unapproveActualApprovals = 1
	BEGIN

		-- variables used to accept query parameters
		DECLARE @unapproveTagId NVARCHAR(63)
		DECLARE @unapproveLocationId INTEGER
		DECLARE @unapproveDigblockId NVARCHAR(31)
		DECLARE @unapprovalMonth DATETIME

		-- create a cursor used to process all approved rows within range
		DECLARE curUnapproveData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
										FROM @BhpbioActualApprovals tas
										ORDER BY tas.ApprovalMonth, tas.ApprovalLevel DESC, tas.LocationId

		-- open the cursor and fetch the first row
		OPEN curUnapproveData

		FETCH NEXT FROM curUnapproveData INTO @unapproveTagId, @unapproveLocationId, @unapproveDigblockId, @unapprovalMonth

		-- while a row was fetched
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT convert(varchar, GetDate(), 108) + ': About to unapprove Month: ' + convert(varchar,@unapprovalMonth) + ', Tag Id: ' + @unapproveTagId + ', Location Id: ' + convert(varchar, @unapproveLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@unapproveDigblockId,''))
			
			IF @unapproveTagId = 'Digblock'
			BEGIN
				-- perform the unapproval
				exec dbo.UnapproveBhpbioApprovalDigblock	@iDigblockId = @unapproveDigblockId,
														@iApprovalMonth = @unapprovalMonth
			END
			ELSE
			BEGIN
				-- perform the unapproval
				exec dbo.UnapproveBhpbioApprovalData	@iTagId = @unapproveTagId,
													@iLocationId = @unapproveLocationId,
													@iApprovalMonth = @unapprovalMonth
			END
			
														  
			PRINT convert(varchar, GetDate(), 108) + ': Finished unapproving: ' + convert(varchar,@unapprovalMonth) + ', Tag Id: ' + @unapproveTagId + ', Location Id: ' + convert(varchar, @unapproveLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@unapproveDigblockId,''))

			-- fetch the next row
			FETCH NEXT FROM curUnapproveData INTO @unapproveTagId, @unapproveLocationId, @unapproveDigblockId, @unapprovalMonth
		END

		CLOSE curUnapproveData
		DEALLOCATE curUnapproveData
		
		-- any required approval is now not approved
		UPDATE @BhpbioRequiredApprovals
		SET IsApproved = 0
	END

	IF @approveMissingRequiredApprovals = 1
	BEGIN
		-- variables used to accept query parameters
		DECLARE @approvalTagId NVARCHAR(63)
		DECLARE @approvalLocationId INTEGER
		DECLARE @approvalDigblockId NVARCHAR(31)
		DECLARE @approvalMonth DATETIME

		-- create a cursor used to process all approved rows within range
		DECLARE curApprovalData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
										FROM @BhpbioRequiredApprovals tas
										WHERE tas.IsApproved = 0
										ORDER BY tas.ApprovalMonth, tas.ApprovalLevel, tas.LocationId

		-- open the cursor and fetch the first row
		OPEN curApprovalData

		FETCH NEXT FROM curApprovalData INTO @approvalTagId, @approvalLocationId, @approvalDigblockId, @approvalMonth

		-- while a row was fetched
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT convert(varchar, GetDate(), 108) + ': About to approve Month: ' + convert(varchar,@approvalMonth) + ', Tag Id: ' + @approvalTagId + ', Location Id: ' + convert(varchar, @approvalLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@approvalDigblockId,''))
			
			IF @approvalTagId = 'Digblock'
			BEGIN
				-- perform the approval
				exec dbo.ApproveBhpbioApprovalDigblock	@iDigblockId = @approvalDigblockId,
														@iApprovalMonth = @approvalMonth,
														@iUserId = @approvalUserId
			END
			ELSE
			BEGIN
				-- perform the approval
				exec dbo.ApproveBhpbioApprovalData	@iTagId = @approvalTagId,
													@iLocationId = @approvalLocationId,
													@iApprovalMonth = @approvalMonth,
													@iUserId = @approvalUserId
			END
			
														  
			PRINT convert(varchar, GetDate(), 108) + ': Finished approving: ' + convert(varchar,@approvalMonth) + ', Tag Id: ' + @approvalTagId + ', Location Id: ' + convert(varchar, @approvalLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@approvalDigblockId,''))

			-- fetch the next row
			FETCH NEXT FROM curApprovalData INTO @approvalTagId, @approvalLocationId, @approvalDigblockId, @approvalMonth
		END

		CLOSE curApprovalData
		DEALLOCATE curApprovalData
	END

	-- clean up outstanding transactions
	WHILE (@@TRANCOUNT > 0)
	BEGIN
		COMMIT TRANSACTION
	END
	PRINT 'Completed Normally.'

END TRY
BEGIN CATCH
	WHILE (@@TRANCOUNT > 0)
	BEGIN
		ROLLBACK TRANSACTION
	END
	CLOSE curApprovalData
	DEALLOCATE curApprovalData
	EXEC dbo.StandardCatchBlock
	
	PRINT 'Error encountered.'

END CATCH
