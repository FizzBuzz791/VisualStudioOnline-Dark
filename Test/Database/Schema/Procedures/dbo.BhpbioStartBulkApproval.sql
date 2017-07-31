IF OBJECT_ID('dbo.BhpbioStartBulkApproval') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioStartBulkApproval  
GO 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Filter Variables:
--		@iBulkApprovalId			-- the id of the corresponding bulk approval batch record in table BhpbioBulkApprovalBatch
--		@iEarliestMonth				-- the first month in the set to process
--		@iLatestMonth				-- the latest month in the set to process
--		@iTopLevelLocationTypeId	-- sets the highest level location type to be included (one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock)
--		@iLocationId				-- the name of the top level location which represents the top of the location branch to operate within
--		@iLowestLevelLocationTypeId -- sets the lowestlevel location type to be included (one of @ltCompany, @ltHub, @ltSite, @ltPit, @ltBench, @ltBlast, @ltBlock)
--		@iApprovalUserId			-- the user Id to associate with approvals
--		@iOperationType				-- 0 unapprove, 1 = approve

-- Warning:
--		Copying approval data prior to changes is recommended (ie BhpbioApprovalData and BhpbioApprovalDigblock)
--

------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[BhpbioStartBulkApproval]
(
	@iBulkApprovalId				INT,
	@iEarliestMonth					DATETIME,
	@iLatestMonth					DATETIME,
	@iTopLevelLocationTypeId		INT,
	@iLocationId					INT,
	@iLowestLevelLocationTypeId		INT,
	@iApprovalUserId				INT,
	@iOperationType					BIT--0 unapprove, 1 = approve
)
AS
BEGIN
	DECLARE @requiredApprovalsCount INT
	DECLARE @actualApprovalsCount INT

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

	-- check for valid batch id
	IF (@iBulkApprovalId IS NULL) OR NOT EXISTS (SELECT * FROM BhpbioBulkApprovalBatch WHERE Id=@iBulkApprovalId)
	BEGIN
		--TODO consider picking up pending batches automatically, if bulkApprovalId not specified?
		RAISERROR ('Invalid bulk approval batch specified.', 11, 1)
	END
		
	-- update batch status
	IF EXISTS (SELECT * FROM BhpbioBulkApprovalBatch WHERE Id=@iBulkApprovalId)
	BEGIN
		UPDATE BhpbioBulkApprovalBatch SET Status='PENDING' WHERE Id=@iBulkApprovalId
	END

	DECLARE @lumpFinesCutover DATETIME

	SELECT @lumpFinesCutover = Value
	FROM Setting 
	WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE'

	IF @lumpFinesCutover IS NULL
	BEGIN
		RAISERROR ('Unable to determine the LUMP / FINES CUTOVER DATE.', 11, 1)
	END

	BEGIN TRY
		-- do not add an outer transaction to this - it will cause locking issues when running other
		-- methods

		IF EXISTS (	SELECT * 
					FROM BhpbioLocationDate ld
					WHERE ld.Location_Id = @iLocationId	
					AND	(
								-- start date in overide range but end date is not 
								(@iEarliestMonth BETWEEN ld.Start_Date AND ld.End_Date) AND NOT (@iLatestMonth BETWEEN ld.Start_Date AND ld.End_Date) 
								OR 
								-- start date is not in overide range but end date is  
								NOT (@iEarliestMonth BETWEEN ld.Start_Date AND ld.End_Date) AND (@iLatestMonth BETWEEN ld.Start_Date AND ld.End_Date) 
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
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, NULL, @iEarliestMonth, @iLatestMonth)
		
		-- remove location types from returned branch that are above the requested top location type id (to meet new Rec4 requirement)
		DELETE L
		FROM @Location l
		INNER JOIN Location ll ON l.LocationId = ll.Location_Id
		WHERE ll.Location_Type_Id < @iTopLevelLocationTypeId

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

		IF @ltBlock BETWEEN @iTopLevelLocationTypeId AND @iLowestLevelLocationTypeId
		BEGIN
			IF @iOperationType = 1
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
				WHERE d.ActivityMonth BETWEEN @iEarliestMonth AND @iLatestMonth
				ORDER BY 1, 2, 3, 4, 5
			END
			
			IF @iOperationType = 0

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
				WHERE bad.ApprovedMonth BETWEEN @iEarliestMonth AND @iLatestMonth
				ORDER BY 1, 2, 3, 4
			END
		END

		IF @ltPit BETWEEN @iTopLevelLocationTypeId AND @iLowestLevelLocationTypeId
		BEGIN
			IF @iOperationType = 1
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
					CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@iEarliestMonth,@iLatestMonth,'MONTH',1)) months
					CROSS JOIN dbo.BhpbioReportDataTags brdt
					LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = pit.Location_Id
						AND bad.ApprovedMonth =  months.Start_Date
						AND bad.TagId = brdt.TagId
				WHERE pit.Location_Type_Id = @ltPit
					AND (brdt.TagId like 'F1%' OR brdt.TagId like 'Other%')
					AND (months.Start_Date >= @lumpFinesCutover OR NOT (brdt.TagId like '%Lump%' Or brdt.TagId like '%Fines%'))
				ORDER BY 1, 2, 3, 4
			END
			
			IF @iOperationType = 0
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
				WHERE bad.ApprovedMonth BETWEEN @iEarliestMonth AND @iLatestMonth
					AND pit.Location_Type_Id = @ltPit
				ORDER BY 1, 2, 3, 4
			END
		END

		IF @ltSite BETWEEN @iTopLevelLocationTypeId AND @iLowestLevelLocationTypeId

		BEGIN
			IF @iOperationType = 1

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
					CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@iEarliestMonth,@iLatestMonth,'MONTH',1)) months
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
			
			IF @iOperationType = 0

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
				WHERE bad.ApprovedMonth BETWEEN @iEarliestMonth AND @iLatestMonth
					AND ste.Location_Type_Id = @ltSite
				ORDER BY 1, 2, 3, 4
			END
		END

		IF @ltHub BETWEEN @iTopLevelLocationTypeId AND @iLowestLevelLocationTypeId

		BEGIN
			IF @iOperationType = 1

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
					CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@iEarliestMonth,@iLatestMonth,'MONTH',1)) months
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
			
			IF @iOperationType = 0

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
				WHERE bad.ApprovedMonth BETWEEN @iEarliestMonth AND @iLatestMonth
					AND hub.Location_Type_Id = @ltHub
				ORDER BY 1, 2, 3, 4
			END
		END

		IF @iOperationType = 0
		BEGIN

			-- variables used to accept query parameters
			DECLARE @unapproveTagId NVARCHAR(63)
			DECLARE @unapproveLocationId INTEGER
			DECLARE @unapproveDigblockId NVARCHAR(31)
			DECLARE @unapprovalMonth DATETIME
			DECLARE @currentUnapprovalCounter	INT
			
			SELECT @requiredApprovalsCount=COUNT(*) FROM @BhpbioActualApprovals
			-- create a cursor used to process all approved rows within range
			DECLARE curUnapproveData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
											FROM @BhpbioActualApprovals tas
											ORDER BY tas.ApprovalMonth, tas.ApprovalLevel DESC, tas.LocationId

			-- open the cursor and fetch the first row
			OPEN curUnapproveData

			FETCH NEXT FROM curUnapproveData INTO @unapproveTagId, @unapproveLocationId, @unapproveDigblockId, @unapprovalMonth

			-- while a row was fetched
			SET @currentUnapprovalCounter=0
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @currentUnapprovalCounter=@currentUnapprovalCounter+1
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
				
				---- write a progress record here -----------------------
				---- Consider: perhaps write or update only once every X operations
				---------------------------------------------------------
				
				--TODO Consider: perhaps write or update only once every X operations or use update
				INSERT INTO [dbo].[BhpbioBulkApprovalBatchProgress]
				(
					[BulkApprovalBatchId],
					[TimeStamp],
					[ApprovedMonth],
					[ProcessingLocationId],
					[LastApprovalTagId],
					[CountApprovalsProcessed],
					[TotalCountApprovals]
				)
				VALUES
				(
					@iBulkApprovalId,
					CURRENT_TIMESTAMP,
					@unapprovalMonth,
					@unapproveLocationId,
					@unapproveTagId,
					@currentUnapprovalCounter,
					@requiredApprovalsCount
				)

															  
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

		IF @iOperationType = 1

		BEGIN
			-- variables used to accept query parameters
			DECLARE @approvalTagId NVARCHAR(63)
			DECLARE @approvalLocationId INTEGER
			DECLARE @approvalDigblockId NVARCHAR(31)
			DECLARE @approvalMonth DATETIME
			DECLARE @currentApprovalCounter	INT
			
			
			SELECT @requiredApprovalsCount= COUNT(*) FROM @BhpbioRequiredApprovals tas
											WHERE tas.IsApproved = 0
											
			-- create a cursor used to process all approved rows within range
			DECLARE curApprovalData CURSOR FOR	SELECT tas.TagId, tas.LocationId, tas.DigblockId, tas.ApprovalMonth
											FROM @BhpbioRequiredApprovals tas
											WHERE tas.IsApproved = 0
											ORDER BY tas.ApprovalMonth, tas.ApprovalLevel, tas.LocationId

			-- open the cursor and fetch the first row
			OPEN curApprovalData

			FETCH NEXT FROM curApprovalData INTO @approvalTagId, @approvalLocationId, @approvalDigblockId, @approvalMonth

			-- while a row was fetched
			SET @currentApprovalCounter = 0
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @currentApprovalCounter= @currentApprovalCounter+1
				PRINT convert(varchar, GetDate(), 108) + ': About to approve Month: ' + convert(varchar,@approvalMonth) + ', Tag Id: ' + @approvalTagId + ', Location Id: ' + convert(varchar, @approvalLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@approvalDigblockId,''))
				
				IF @approvalTagId = 'Digblock'
				BEGIN
					-- perform the approval
					exec dbo.ApproveBhpbioApprovalDigblock	@iDigblockId = @approvalDigblockId,
															@iApprovalMonth = @approvalMonth,
															@iUserId = @iApprovalUserId



				END
				ELSE
				BEGIN
					-- perform the approval
					exec dbo.ApproveBhpbioApprovalData	@iTagId = @approvalTagId,
														@iLocationId = @approvalLocationId,
														@iApprovalMonth = @approvalMonth,
														@iUserId = @iApprovalUserId

				END
				
				--TODO Consider: perhaps write or update only once every X operations or use update
				INSERT INTO [dbo].[BhpbioBulkApprovalBatchProgress]
				(
					[BulkApprovalBatchId],
					[TimeStamp],
					[ApprovedMonth],
					[ProcessingLocationId],
					[LastApprovalTagId],
					[CountApprovalsProcessed],
					[TotalCountApprovals]
				)
				VALUES
				(
					@iBulkApprovalId,
					CURRENT_TIMESTAMP,
					@approvalMonth,
					@approvalLocationId,
					@approvalTagId,
					@currentApprovalCounter,
					@requiredApprovalsCount
				)
															  
				PRINT convert(varchar, GetDate(), 108) + ': Finished approving: ' + convert(varchar,@approvalMonth) + ', Tag Id: ' + @approvalTagId + ', Location Id: ' + convert(varchar, @approvalLocationId) + ', Digblock Id: ' + convert(varchar, IsNull(@approvalDigblockId,''))

				-- fetch the next row
				FETCH NEXT FROM curApprovalData INTO @approvalTagId, @approvalLocationId, @approvalDigblockId, @approvalMonth
			END

			CLOSE curApprovalData
			DEALLOCATE curApprovalData
		END

		--If there was a batch associated with this job, update the status to processed
		IF EXISTS (SELECT * FROM BhpbioBulkApprovalBatch WHERE Id=@iBulkApprovalId)
		BEGIN
			UPDATE BhpbioBulkApprovalBatch SET Status='COMPLETE' WHERE Id=@iBulkApprovalId
		END
				
	END TRY
	BEGIN CATCH
		

		IF (SELECT CURSOR_STATUS('global','curUnapproveData')) >= -1
		BEGIN
			IF (SELECT CURSOR_STATUS('global','curUnapproveData')) > -1
			BEGIN
				CLOSE curUnapproveData
			END
			DEALLOCATE curUnapproveData
		END
		IF (SELECT CURSOR_STATUS('global','curApprovalData')) >= -1
		BEGIN
			IF (SELECT CURSOR_STATUS('global','curApprovalData')) > -1
			BEGIN
				CLOSE curApprovalData
			END
			DEALLOCATE curApprovalData

		END

		EXEC dbo.StandardCatchBlock
		
		IF EXISTS (SELECT * FROM BhpbioBulkApprovalBatch WHERE Id=@iBulkApprovalId)
		BEGIN
			UPDATE BhpbioBulkApprovalBatch SET Status='FAILED' WHERE Id=@iBulkApprovalId
		END

		PRINT 'Error encountered.'

	END CATCH
END
GO

GRANT EXECUTE ON dbo.BhpbioStartBulkApproval TO BhpbioGenericManager
GO
