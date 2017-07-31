IF OBJECT_ID('dbo.GetBhpbioReportDataActualStockpileToCrusher') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualStockpileToCrusher 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualStockpileToCrusher
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @StockpileToCrusher TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		ProductSize VARCHAR(5) NULL,
		Attribute INT NULL,
		Value FLOAT NULL
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualStockpileToCrusher',
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
		INSERT INTO @StockpileToCrusher
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, LocationId, Attribute, Value, ProductSize)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, ProductSize
		FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iIncludeLiveData, @iIncludeApprovedData)
			
		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, ProductSize, Value AS Tonnes
		FROM @StockpileToCrusher
		WHERE Attribute = 0
		
		SELECT CalendarDate, LocationId AS ParentLocationId, Attribute As GradeId,
			MaterialTypeId, ProductSize, G.Grade_Name As GradeName, ISNULL(Value, 0.0) As GradeValue
		FROM @StockpileToCrusher AS STC
			INNER JOIN dbo.Grade AS G
				ON (STC.Attribute = G.Grade_Id)
		WHERE STC.Attribute > 0

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualStockpileToCrusher TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualStockpileToCrusher
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = NULL,
	@iLocationId = 6,
	@iChildLocations = 1,
	@iIncludeLiveData = 0
	@iIncludeApprovedData = 1
*/