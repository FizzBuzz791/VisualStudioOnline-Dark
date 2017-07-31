IF OBJECT_ID('dbo.GetBhpbioPortBlendingForGeomet') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioPortBlendingForGeomet
Go 

CREATE FUNCTION dbo.GetBhpbioPortBlendingForGeomet(@iDateFrom Datetime, @iDateTo Datetime)
RETURNS @PortBlending table (
	[BhpbioPortBlendingId] int,
	[SourceHubLocationId] int,
	[DestinationHubLocationId] int,
	[LoadSiteLocationId] int,
	[StartDate] datetime,
	[EndDate] datetime,
	[SourceProductSize] varchar(32),
	[DestinationProductSize] varchar(32),
	[SourceProduct] varchar(32),
	[DestinationProduct] varchar(32),
	[Tonnes] FLOAT,
	[GeometMovementType] varchar(32)
)
BEGIN

	Insert Into @PortBlending
		select 
			*,
			CASE 
				WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'LUMP' And DestinationProductSize = 'FINES' THEN 'I'
				WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'FINES' And DestinationProductSize = 'LUMP' THEN 'NI'
				WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize = DestinationProductSize THEN 'NI'
				WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize <> DestinationProductSize THEN 'MIX'
				ELSE 'UNKNOWN'
			END 
		from dbo.BhpbioPortBlending
		where sourceproductsize is not null
			and destinationproductsize is not null
			and StartDate >= @iDateFrom
			and EndDate <= DateAdd(second, -1, DateAdd(DAY, 1, @iDateTo))

	Insert Into @PortBlending
		Select 
			BhpbioPortBlendingId,
			SourceHubLocationId,
			SourceHubLocationId as DestinationHubLocationId,
			LoadSiteLocationId,
			StartDate,
			EndDate,
			SourceProductSize,
			DestinationProductSize,
			SourceProduct,
			DestinationProduct,
			Tonnes,
			'I' as GeometMovementType
		From @PortBlending pb
		Where pb.GeometMovementType = 'MIX'

	Insert Into @PortBlending
		Select 
			BhpbioPortBlendingId,
			SourceHubLocationId,
			DestinationHubLocationId,
			LoadSiteLocationId,
			StartDate,
			EndDate,
			DestinationProductSize as SourceProductSize,
			DestinationProductSize,
			SourceProduct,
			DestinationProduct,
			Tonnes,
			'NI' as GeometMovementType
		From @PortBlending pb
		Where pb.GeometMovementType = 'MIX'

	delete from @PortBlending
	where GeometMovementType = 'MIX'

	update @PortBlending
		set GeometMovementType = (CASE 
			WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'LUMP' And DestinationProductSize = 'FINES' THEN 'I'
			WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'FINES' And DestinationProductSize = 'LUMP' THEN 'NI'
			WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize = DestinationProductSize THEN 'NI'
			WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize <> DestinationProductSize THEN 'MIX'
			ELSE 'UNKNOWN'
		END)

	RETURN
END
GO


IF OBJECT_ID('dbo.TmpSummariseBhpbioPortBlendedAdjustment_LFOnly') IS NOT NULL
     DROP PROCEDURE dbo.TmpSummariseBhpbioPortBlendedAdjustment_LFOnly 
GO 
   
-- for the 4.0 deployment we need to only resummarize the Lump and Fines for the port blended adjustment
-- leaving the tonnes as is.
--
-- This is a copy of the existing summary method, but it doesn't replace the TOTALs
CREATE PROCEDURE dbo.TmpSummariseBhpbioPortBlendedAdjustment_LFOnly
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME, 
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)
	
	DECLARE @Blending TABLE
	(
		BhpbioPortBlendingId INT,
		LocationId INT,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT,
		Removal BIT,
		GeometMovementType VARCHAR(32)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioPortBlendedAdjustment',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'PortBlending'
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		
		-- Determine locations of interest
		INSERT INTO @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT	L.LocationId, L.ParentLocationId, L.IncludeStart, L.IncludeEnd
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 0, 'SITE', @startOfMonth, @startOfNextMonth - 1) L
		-- Filter out any HubExclusionFilters 
		LEFT	JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF ON L.LocationId = HXF.LocationId
		WHERE	HXF.LocationId IS NULL
		

		---
		--- DELETE EVERYTHING EXCEPT THE TOTALS
		---
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
			AND bse.ProductSize <> 'TOTAL'
			AND EXISTS (
				SELECT * 
				FROM @Location loc 
				WHERE loc.LocationId = bse.LocationId
			)

		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO @Blending
			(
				BhpbioPortBlendingId, 
				LocationId, 
				ProductSize,
				Tonnes, 
				Removal,
				GeometMovementType
			)
		SELECT BPB.BhpbioPortBlendingId,
			L.LocationId,
			ISNULL(CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN BPB.DestinationProductSize ELSE BPB.SourceProductSize END, defaultlf.ProductSize), 
			ISNULL(defaultlf.[Percent], 1) * BPB.Tonnes, 
			CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN 0 ELSE 1 END,
			bpb.GeometMovementType
		FROM dbo.GetBhpbioPortBlendingForGeomet(@startOfMonth, @startOfNextMonth) AS BPB
			INNER JOIN @Location AS L
				ON (BPB.DestinationHubLocationId = L.LocationId OR BPB.LoadSiteLocationId = L.LocationId)
				AND BPB.StartDate BETWEEN L.IncludeStart AND L.IncludeEnd
			LEFT JOIN dbo.BhpbioLocationDate siteLocation
				ON siteLocation.Location_Id = BPB.LoadSiteLocationId
				AND BPB.StartDate BETWEEN siteLocation.Start_Date AND siteLocation.End_Date
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON BPB.SourceProductSize IS NULL
				AND BPB.LoadSiteLocationId = defaultlf.LocationId
				AND BPB.EndDate BETWEEN defaultlf.StartDate AND defaultlf.EndDate
			LEFT JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF 
				ON BPB.DestinationHubLocationId= HXF.LocationId
				OR siteLocation.Parent_Location_Id = HXF.LocationId
		WHERE BPB.StartDate >= @startOfMonth
			AND BPB.EndDate < @startOfNextMonth
			AND HXF.LocationId IS NULL	
			AND (ISNULL(defaultlf.[Percent], 1) > 0)

		-- roll up lump/fines tonnes for total
		-- totals are always non-integral as the geomettype - because no port blending it taken into
		-- account for the total block
		INSERT INTO @Blending
			(BhpbioPortBlendingId, LocationId, ProductSize, Tonnes, Removal, GeometMovementType)
		SELECT BhpbioPortBlendingId, LocationId, 'TOTAL', SUM(Tonnes), Removal, 'NI'
		FROM @Blending
		GROUP BY BhpbioPortBlendingId, LocationId, Removal

		---- Insert the tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT @summaryId,
			   @summaryEntryTypeId,
			   b.LocationId,
			   NULL,
			   b.ProductSize,
			   SUM(CASE WHEN b.Removal = 0 THEN b.Tonnes ELSE -b.Tonnes END)
		FROM @Blending AS b
		WHERE b.GeometMovementType <> 'I'
			AND b.ProductSize <> 'TOTAL'
		GROUP BY b.LocationId, b.ProductSize
		
		-- Insert the Grade values
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT 
			bse.SummaryEntryId,
			BPBG.GradeId,
			SUM(B.Tonnes * BPBG.GradeValue) / SUM(B.Tonnes) AS GradeValue
		FROM @Blending AS B
			INNER JOIN dbo.BhpbioPortBlendingGrade AS BPBG
				ON BPBG.BhpbioPortBlendingId = B.BhpbioPortBlendingId
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.LocationId = B.LocationId
				AND bse.ProductSize = B.ProductSize
				AND bse.SummaryId = @summaryId
		WHERE b.GeometMovementType <> 'I'
			AND b.ProductSize <> 'TOTAL'
		GROUP BY bse.SummaryEntryId, BPBG.GradeId
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END	
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO


/*
exec dbo.SummariseBhpbioPortBlendedAdjustment
	@iSummaryMonth = '2012-11-01',
	@iSummaryLocationId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioPortBlendedAdjustment">
 <Procedure>
	Generates a set of summary Port Blending Adjustment data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Hub) for which data will be summarised

 </Procedure>
</TAG>
*/