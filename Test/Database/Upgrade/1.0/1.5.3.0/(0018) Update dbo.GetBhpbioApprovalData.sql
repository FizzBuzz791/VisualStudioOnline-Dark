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

	DECLARE @LowestLocationSignOff TABLE
	(
		LocationId INT NOT NULL,
		TagId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Approved BIT NOT NULL,
		UserId INT NOT NULL,
		PRIMARY KEY (LocationId, TagId, UserId)
	)

	DECLARE @LocationMap TABLE
	(
		LocationId INT NOT NULL,
		ChildLocationId INT NOT NULL
		PRIMARY KEY (LocationId, ChildLocationId)
	)
	
	DECLARE @ReturnLocation TABLE
	(
		LocationId INT NULL,
		Children INT
	)
	
	DECLARE @BAD TABLE
	(
		LocationId Int,
		TagId VARCHAR(31) COLLATE DATABASE_DEFAULT
	)
	
	DECLARE @BIRM TABLE
	(
		LocationId Int
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
		
		INSERT INTO @LocationMap
			(LocationId, ChildLocationId)	
		SELECT LocationId, ChildLocationId
		FROM dbo.GetBhpbioLocationChildMap(@iMonthFilter, NULL, @LowestLocationTypeId)

		-- Retrieve all approved locations and attach to the children nodes.
		INSERT INTO @LowestLocationSignOff
			(LocationId, TagId, Approved, UserId)
		SELECT LM.ChildLocationId, AD.TagId, 1, AD.UserId
		FROM dbo.BhpbioApprovalData AS AD
			INNER JOIN @LocationMap AS LM
				ON (AD.LocationId = LM.LocationId)
		WHERE AD.ApprovedMonth = @MonthDate
		Group By LM.ChildLocationId, AD.TagId, AD.UserId
	
		-- Obtain all the return locations and their max children
		INSERT INTO @ReturnLocation
			(LocationId, Children)
		SELECT L.LocationId, Count(1) AS Children
		FROM (
				SELECT LocationId
				FROM @LocationMap 
				GROUP BY LocationId
			 ) AS L
			INNER JOIN @LocationMap AS LM
				ON (L.LocationId = LM.LocationId)
		GROUP BY L.LocationId
				
		INSERT INTO @BAD
		(LocationId, TagId)
		SELECT BAD.LocationId, BAD.TagId
		FROM dbo.BhpbioApprovalData BAD
			INNER JOIN dbo.BhpbioReportDataTags BRDT 
				ON (BAD.TagId = BRDT.TagId)
		WHERE BRDT.TagGroupId In ('F1Factor', 'OtherMaterial')
			AND BAD.ApprovedMonth = @MonthDate
			
		INSERT INTO @BIRM
		(LocationId)
		SELECT dbo.GetLocationTypeLocationId(RM.BlockLocationId, @LowestLocationTypeId) As LocationId
		FROM dbo.BhpbioImportReconciliationMovement AS RM 
		WHERE RM.DateFrom >= @MonthDate
			AND RM.DateTo <= @EndMonthDate
		GROUP BY dbo.GetLocationTypeLocationId(RM.BlockLocationId, @LowestLocationTypeId)
			
		-- Retrieve Tag Information
		SELECT DT.TagId, DT.TagGroupId, RL.LocationId, @MonthDate AS ApprovalMonth, L.Parent_Location_Id AS ParentLocationId,
			CASE WHEN RL.Children = AT.Number THEN
					1 
				WHEN BIRM.TagId IS NULL AND DT.TagGroupId IN ('F1Factor', 'OtherMaterial') AND BIRM_S.LocationId IS NOT NULL THEN
					1
				ELSE
					0
				END AS Approved, 
			RL.Children, AT.Number AS NumberApproved
		FROM @ReturnLocation AS RL
			CROSS JOIN dbo.BhpbioReportDataTags AS DT
			INNER JOIN dbo.Location AS L
				ON (L.Location_Id = RL.LocationId)
			LEFT JOIN (SELECT LM.LocationId As LocationId, BAD.TagId
						FROM @BIRM AS RM
							INNER JOIN @LocationMap AS LM
								ON (RM.LocationId = LM.ChildLocationId)
							LEFT JOIN @BAD AS BAD
								ON BAD.LocationId = LM.ChildLocationId
						GROUP BY LM.LocationId, BAD.TagId
						) BIRM
				ON (L.Location_Id = BIRM.LocationId
					AND DT.TagId = BIRM.TagId)
			LEFT JOIN @BIRM BIRM_S
				ON (dbo.GetLocationTypeLocationId(L.Location_Id, @SiteLocationTypeId) = BIRM_S.LocationId)
			LEFT JOIN (
						SELECT LLSO.TagId, Count(1) AS Number, LM.LocationId
						FROM @LowestLocationSignOff AS LLSO
							INNER JOIN @LocationMap AS LM
								ON (LLSO.LocationId = LM.ChildLocationId)
						GROUP BY LLSO.TagId, LM.LocationId
						) AT
				ON AT.TagId = DT.TagId
					AND AT.LocationId = RL.LocationId
		ORDER BY DT.TagId, DT.TagGroupId, RL.LocationId

		-- Retrieve User Information
		SELECT L.TagId AS TagId, L.LocationId, U.UserId AS UserId, 
			U.FirstName AS FirstName, U.LastName AS LastName
		FROM (
			SELECT LLSO.TagId, LLSO.UserId, LM.LocationId
			FROM @LowestLocationSignOff AS LLSO
				INNER JOIN @LocationMap AS LM
					ON (LLSO.LocationId = LM.ChildLocationId)
				INNER JOIN @ReturnLocation AS RL
					ON (RL.LocationId = LM.LocationId)
			GROUP BY LLSO.UserId, LLSO.TagId, LM.LocationId
			) AS L
			INNER JOIN dbo.SecurityUser AS u
				ON (L.UserId = u.UserId)
			
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

GRANT EXECUTE ON dbo.GetBhpbioApprovalData TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalData '1-Mar-2008'
--EXEC dbo.GetBhpbioApprovalData '1-nov-2009'
