IF OBJECT_ID('dbo.GetBhpbioReportDataActualDirectFeed') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualDirectFeed
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualDirectFeed
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT,
	@iLowestStratLevel INT = 0, -- Default to 0 to prevent Stratigraphy grouping/reporting
	@iIncludeWeathering BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @DirectFeed TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ProductSize VARCHAR(5) NULL,
		LocationId INT NULL,
		Attribute INT NULL,
		Value FLOAT NULL,
		StratNum VARCHAR(7) NULL,
		StratLevel INT NULL,
		StratLevelName VARCHAR(15) NULL,
		Weathering VARCHAR(1) NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualDirectFeed',
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
	
		INSERT INTO @DirectFeed
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, ProductSize, LocationId, Attribute, Value, StratNum, StratLevel, StratLevelName, Weathering)
		SELECT X.CalendarDate, X.DateFrom, X.DateTo, X.DesignationMaterialTypeId, X.ProductSize, X.LocationId, X.Attribute, X.Value, X.StratNum, X.StratLevel, X.StratLevelName, X.Weathering
		FROM dbo.GetBhpbioReportActualX(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iLowestStratLevel, @iIncludeWeathering) AS X
			INNER JOIN dbo.GetBhpbioReportHighGrade() AS hg
				ON (X.DesignationMaterialTypeId = hg.MaterialTypeId)
			
		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, ProductSize, Value AS Tonnes, StratNum AS Strat, StratLevel, StratLevelName, Weathering
		FROM @DirectFeed
		WHERE Attribute = 0
		
		SELECT CalendarDate, LocationId AS ParentLocationId, Attribute As GradeId,
			MaterialTypeId, ETS.ProductSize, G.Grade_Name As GradeName, ISNULL(Value, 0.0) As GradeValue, ETS.StratNum AS Strat, ETS.StratLevel, ETS.StratLevelName, ETS.Weathering	
		FROM @DirectFeed AS ETS
			INNER JOIN dbo.Grade AS G
				ON (ETS.Attribute = G.Grade_Id)
		WHERE ETS.Attribute > 0
	
		-- if we started a new transaction that istill valid then commit the changes
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualDirectFeed TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualDirectFeed
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = NULL,
	@iLocationId = 6,
	@iChildLocations = 1,
	@iIncludeLiveData = 0
	@iIncludeApprovedData = 1
*/