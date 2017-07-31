IF OBJECT_ID('dbo.GetBhpbioReportDataActualMineProduction') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualMineProduction  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualMineProduction
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
	DECLARE @ChildLocations BIT
	
	DECLARE @MineProductionActual TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		ProductSize VARCHAR(5) NULL,
		Attribute INT NOT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualMineProduction',
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
		INSERT INTO @MineProductionActual
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, LocationId, ProductSize, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, ProductSize, Attribute, Value
		FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iIncludeLiveData, @iIncludeApprovedData)

		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, ProductSize, Value AS Tonnes
		FROM @MineProductionActual
		WHERE Attribute = 0
		
		SELECT mpa.CalendarDate, mpa.LocationId AS ParentLocationId, mpa.Attribute As GradeId,
			mpa.MaterialTypeId, mpa.ProductSize, g.Grade_Name As GradeName, mpa.Value As GradeValue
		FROM @MineProductionActual AS mpa
			INNER JOIN dbo.Grade AS g
				ON (mpa.Attribute = g.Grade_Id)
		WHERE mpa.Attribute > 0

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualMineProduction TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualMineProduction 
	@iDateFrom = '1-JUN-2009', 
	@iDateTo = '30-JUN-2009', 
	@iDateBreakdown = null,
	@iLocationId = 1,
	@iChildLocations = 0,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
*/
