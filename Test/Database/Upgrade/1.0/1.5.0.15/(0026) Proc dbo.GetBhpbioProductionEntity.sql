IF OBJECT_ID('dbo.GetBhpbioProductionEntity') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioProductionEntity
GO 
  
CREATE PROCEDURE dbo.GetBhpbioProductionEntity
(
	@iSiteLocationId INT,
	@iTransactionDate DATETIME,
	@iCode VARCHAR(255),
	@iType VARCHAR(255),
	@iDirection VARCHAR(255),
	@oStockpileId INT OUTPUT,
	@oCrusherId VARCHAR(31) OUTPUT,
	@oMillId VARCHAR(31) OUTPUT
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @StockpileId INT
	DECLARE @CrusherId VARCHAR(31)
	DECLARE @MillId VARCHAR(31)
	DECLARE @Resolved BIT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioProductionEntity',
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
		SET @StockpileId = NULL
		SET @CrusherId = NULL
		SET @MillId = NULL

		EXEC dbo.BhpbioResolveBasic
			@iTransactionDate = @iTransactionDate,
			@iCode = @iCode,
			@iResolution_Target = @iDirection,
			@oResolved = @Resolved OUTPUT,
			@oDigblockId = NULL,
			@oStockpileId = @StockpileId OUTPUT,
			@oCrusherId = @CrusherId OUTPUT,
			@oMillId = @MillId OUTPUT

		IF @Resolved = 0
		BEGIN
			IF @iType = 'crusher'
			BEGIN
				-- this is a simple crusher lookup based on:
				-- 1. The Site's location recorded against the Crusher
				-- 2. The Code directly mapped to the Crusher's Id

				SET @CrusherId =
					(
						SELECT cl.Crusher_Id
						FROM dbo.CrusherLocation AS cl
							INNER JOIN dbo.Location AS l
								ON (cl.Location_Id = l.Location_Id)
						WHERE l.Location_Id = @iSiteLocationId
							AND cl.Crusher_Id = @iCode
					)
					
				IF @CrusherId IS NULL
				BEGIN
					SET @MillId =
						(
							SELECT cl.Mill_Id
							FROM dbo.MillLocation AS cl
								INNER JOIN dbo.Location AS l
									ON (cl.Location_Id = l.Location_Id)
							WHERE l.Location_Id = @iSiteLocationId
								AND cl.Mill_Id = @iCode
						)
				END
			END
			ELSE IF @iType = 'post crusher' OR @iType = 'pre crusher' 
			BEGIN
				-- this is a simple stockpile lookup based on:
				-- 1. The Site's location recorded against the Stockpile
				-- 2. The Code directly mapped to the Stockpile's Name

				SET @StockpileId = 
					(
						SELECT s.Stockpile_Id
						FROM dbo.BhpbioStockpileLocationDate AS sl
							INNER JOIN dbo.Stockpile AS s
								ON (sl.Stockpile_Id = s.Stockpile_Id)
								AND	(@iTransactionDate BETWEEN sl.[Start_Date] AND sl.End_Date)
						WHERE sl.Location_Id = @iSiteLocationId
							AND s.Stockpile_Name = @iCode
					)
			END
			ELSE IF @iType = 'train rake'
			BEGIN
				-- this lookup is based on a specific stockpile from:
				-- 1. The Site's location recorded against the stockpile
				-- 2. The stockpile's membership with the Port Train Rake stockpile group
				-- note that regardless of code, all mappings are made to a SINGLE specific stockpile
				
				-- Compat for NJV Hub, if the direction is source then 'Hub Train Rake' stockpile group.
				
				IF @iDirection = 'SOURCE' 
				BEGIN
					SET @StockpileId =
						(
							SELECT s.Stockpile_Id
							FROM dbo.Stockpile AS s
								INNER JOIN dbo.StockpileGroupStockpile AS sgs
									ON (sgs.Stockpile_Id = s.Stockpile_Id)
								INNER JOIN dbo.StockpileGroup AS sg
									ON (sg.Stockpile_Group_Id = sgs.Stockpile_Group_Id)
								INNER JOIN dbo.BhpbioStockpileLocationDate AS sl
									ON (sl.Stockpile_Id = s.Stockpile_Id)
									AND	(@iTransactionDate BETWEEN sl.[Start_Date] AND sl.End_Date)
								INNER JOIN dbo.Location L
									ON (l.Location_Id = sl.Location_Id)
							WHERE sl.Location_Id = dbo.GetLocationTypeLocationId(@iSiteLocationId, l.Location_Type_Id)
								AND sg.Stockpile_Group_Id = 'Hub Train Rake'
						)				
				END
				ELSE
				BEGIN
					SET @StockpileId =
						(
							SELECT s.Stockpile_Id
							FROM dbo.Stockpile AS s
								INNER JOIN dbo.StockpileGroupStockpile AS sgs
									ON (sgs.Stockpile_Id = s.Stockpile_Id)
								INNER JOIN dbo.StockpileGroup AS sg
									ON (sg.Stockpile_Group_Id = sgs.Stockpile_Group_Id)
								INNER JOIN dbo.BhpbioStockpileLocationDate AS sl
									ON (sl.Stockpile_Id = s.Stockpile_Id)
									AND	(@iTransactionDate BETWEEN sl.[Start_Date] AND sl.End_Date)
							WHERE sl.Location_Id = @iSiteLocationId
								AND sg.Stockpile_Group_Id = 'Port Train Rake'
						)
				END
			END
		END

		-- return the results
		SET @oStockpileId = @StockpileId
		SET @oCrusherId = @CrusherId
		SET @oMillId = @MillId

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

GRANT EXECUTE ON dbo.GetBhpbioProductionEntity TO BhpbioGenericManager
GO
