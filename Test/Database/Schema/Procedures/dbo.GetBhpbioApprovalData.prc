--exec GetBhpbioApprovalData '2009-08-28 09:10:25.747'


IF OBJECT_ID('dbo.GetBhpbioApprovalData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalData
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalData
(
	@iMonthFilter DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @MonthDate DATETIME
	DECLARE @TotalChildren INT
	DECLARE @LowestLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	DECLARE @EndMonthDate DATETIME

	DECLARE @LocationId INT
	
	DECLARE @GradeControlTagId VARCHAR(64)
	DECLARE @GradeControlSTGMTagId VARCHAR(64)
	
	SET @GradeControlTagId = 'F1GradeControlModel'
	SET @GradeControlSTGMTagId = 'F15GradeControlSTGM'

	DECLARE @LowestLocationSignOff TABLE
	(
		LocationId INT NOT NULL,
		TagId VARCHAR(63) COLLATE DATABASE_DEFAULT NOT NULL,
		Approved BIT NOT NULL,
		UserId INT NOT NULL,
		SignOffDate datetime NULL,
		PRIMARY KEY (LocationId, TagId, UserId)
	)

	CREATE TABLE #LocationMap
	(
		LocationId INT NOT NULL,
		ChildLocationId INT NOT NULL,
		
		PRIMARY KEY (LocationId, ChildLocationId)
	)
	
	CREATE NONCLUSTERED INDEX IX_LocationMap_Child ON #LocationMap (ChildLocationId) INCLUDE (LocationId)
	
	DECLARE @ReturnLocation TABLE
	(
		LocationId INT Primary Key,
		Children INT
	)
	
	DECLARE @BAD TABLE
	(
		LocationId Int,
		TagId VARCHAR(63) COLLATE DATABASE_DEFAULT,
		SignOffDate datetime null
		
		Primary Key (LocationId, TagId)
	)


	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalData',
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
		SET @MonthDate = dbo.GetDateMonth(@iMonthFilter)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))
		
		SELECT @LowestLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Pit'
		
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT INTO #LocationMap
			(LocationId, ChildLocationId)	
		SELECT LocationId, ChildLocationId
		FROM dbo.GetBhpbioLocationChildMap(@iMonthFilter, NULL, @LowestLocationTypeId)

		-- Retrieve all approved locations and attach to the children nodes.
		INSERT INTO @LowestLocationSignOff
			(LocationId, TagId, Approved, UserId,SignOffDate)
		SELECT LM.ChildLocationId, AD.TagId, 1, AD.UserId,ad.SignoffDate
		FROM dbo.BhpbioApprovalData AS AD
			INNER JOIN #LocationMap AS LM
				ON (AD.LocationId = LM.LocationId)
		WHERE AD.ApprovedMonth = @MonthDate
		Group By LM.ChildLocationId, AD.TagId, AD.UserId,AD.SignoffDate
		
		-- Grade Control STGM data is a special case. In the sense that the live
		-- data is generated on the fly, the approve data is as well, so it always
		-- mirrors the actual Grade Control Approvals
		DELETE FROM @LowestLocationSignOff where TagId = @GradeControlSTGMTagId
		INSERT INTO @LowestLocationSignOff
			(LocationId, TagId, Approved, UserId,SignOffDate)
		SELECT LocationId, @GradeControlSTGMTagId, Approved, UserId,SignOffDate
		FROM @LowestLocationSignOff lso
		WHERE TagId = @GradeControlTagId
	
		-- Obtain all the return locations and their max children
		INSERT INTO @ReturnLocation
			(LocationId, Children)
		SELECT L.LocationId, Count(1) AS Children
		FROM (
				SELECT LocationId
				FROM #LocationMap 
				GROUP BY LocationId
			 ) AS L
			INNER JOIN #LocationMap AS LM
				ON (L.LocationId = LM.LocationId)
		GROUP BY L.LocationId
				
		INSERT INTO @BAD
		(LocationId, TagId,SignOffDate)
		SELECT BAD.LocationId, BAD.TagId,bad.SignoffDate
		FROM dbo.BhpbioApprovalData BAD
			INNER JOIN dbo.BhpbioReportDataTags BRDT 
				ON (BAD.TagId = BRDT.TagId)
		WHERE BRDT.TagGroupId In ('F1Factor', 'OtherMaterial')
			AND BAD.ApprovedMonth = @MonthDate
			
		-- Retrieve Tag Information
		SELECT DT.TagId, DT.TagGroupId, RL.LocationId, @MonthDate AS ApprovalMonth, L.Parent_Location_Id AS ParentLocationId,
			CASE WHEN RL.Children = AT.Number THEN
					1 
				WHEN BIRM.TagId IS NULL AND DT.TagGroupId IN ('F1Factor', 'OtherMaterial') AND BIRM.SiteLocationId IS NOT NULL THEN
					1
				ELSE
					0
				END AS Approved, 
			RL.Children, AT.Number AS NumberApproved
		FROM @ReturnLocation AS RL
			CROSS JOIN dbo.BhpbioReportDataTags AS DT
			INNER JOIN dbo.Location AS L ON L.Location_Id = RL.LocationId
			LEFT JOIN (
				SELECT SiteLocationId, PitLocationId, BAD.TagId
				FROM GetBhpbioReportReconBlockLocations(1, @MonthDate, @EndMonthDate, 0) RM 
				LEFT JOIN @BAD BAD ON BAD.LocationId = RM.PitLocationId 
				GROUP BY SiteLocationId, PitLocationId, BAD.TagId
			) BIRM ON (L.Location_Id = BIRM.PitLocationId AND DT.TagId = BIRM.TagId)			
			LEFT JOIN (
				SELECT LLSO.TagId, Count(1) AS Number, LM.LocationId
				FROM @LowestLocationSignOff AS LLSO
					INNER JOIN #LocationMap AS LM ON LLSO.LocationId = LM.ChildLocationId
				GROUP BY LLSO.TagId, LM.LocationId
			) AT ON AT.TagId = DT.TagId AND AT.LocationId = RL.LocationId
		ORDER BY DT.TagId, DT.TagGroupId, RL.LocationId

	Declare @Return Table
	(
		TagId VARCHAR(63) COLLATE DATABASE_DEFAULT NOT NULL,
		LocationId INT NOT NULL,
		UserId INT NOT NULL,
		FirstName Varchar(31) Collate Database_Default,
		LastName Varchar(31) Collate Database_Default,
		SignOffDate datetime

	)
		---- Retrieve User Information
		Insert into @return
			Select a.TagId , a.LocationId , a.UserId, a.FirstName, a.LastName, a.SignOffDate From
				(SELECT L.TagId AS TagId, L.LocationId, U.UserId AS UserId, 
					U.FirstName AS FirstName, U.LastName AS LastName, L.SignOffDate
				FROM (
					SELECT LLSO.TagId, LLSO.UserId, LM.LocationId, LLSO.SignOffDate
					FROM @LowestLocationSignOff AS LLSO
						INNER JOIN #LocationMap AS LM
							ON (LLSO.LocationId = LM.ChildLocationId)
						INNER JOIN @ReturnLocation AS RL
							ON (RL.LocationId = LM.LocationId)
					GROUP BY LLSO.UserId, LLSO.TagId, LM.LocationId, LLSO.SignOffDate
					) AS L
					INNER JOIN dbo.SecurityUser AS u
						ON (L.UserId = u.UserId)) AS A
		
				Select TagId, LocationId, UserId, FirstName, LastName, SignOffDate
				From @return A   
				Where SignOffDate = (  
					Select MAX(SignOffDate)   
					From @return   
					Where tagid = a.tagid 
						And locationid=a.locationid 
						And FirstName=a.FirstName 
						And LastName = a.LastName 
						And UserId= a.userid
				) 
	
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
	
	DROP TABLE #LocationMap
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioApprovalData TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalData '1-Jul-2014'
--EXEC dbo.GetBhpbioApprovalData '1-nov-2009'
