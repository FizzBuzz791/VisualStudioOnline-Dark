IF OBJECT_ID('dbo.IsBhpbioApprovalOtherMovementDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate  
GO 
    
CREATE PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oMovementsExist BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonth)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalOtherMovementDate',
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
		-- Updated the locations
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocationWithOverride(@iLocationId, @DateFrom, @DateTo)
		
		-- Obtain the Block Model XML
		SELECT @BlockModelXml = @BlockModelXml + '<BlockModel id="' + CAST(Block_Model_Id AS VARCHAR) + '"/>'
		FROM dbo.BlockModel
		SET @BlockModelXml = '<BlockModels>' + @BlockModelXml + '</BlockModels>'
		
		-- load the base data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @DateFrom,
			@iDateTo = @DateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = 1,
			@iBlockModels = @BlockModelXml,
			@iIncludeActuals = 1,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = NULL,
			@iIncludeLiveData = 1,
			@iIncludeApprovedData = 1
			

		-- Put the block model tonnes in.
		IF (SELECT Sum(Tonnes)
			FROM @Tonnes AS T
			WHERE T.Material NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
				AND T.Material IS NOT NULL) > 0
		BEGIN
			SET @oMovementsExist = 1
		END
		ELSE
		BEGIN
			SET @oMovementsExist = 0
		END
		
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

GRANT EXECUTE ON dbo.IsBhpbioApprovalOtherMovementDate TO BhpbioGenericManager

GO
