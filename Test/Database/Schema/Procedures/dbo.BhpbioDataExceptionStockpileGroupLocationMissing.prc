 IF OBJECT_ID('dbo.BhpbioDataExceptionStockpileGroupLocationMissing') IS NOT NULL
    DROP PROCEDURE dbo.BhpbioDataExceptionStockpileGroupLocationMissing
GO 
  
CREATE PROCEDURE dbo.BhpbioDataExceptionStockpileGroupLocationMissing
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ErrorStockpiles TABLE
	(
		StockpileId INT,
		StockpileName VARCHAR(51) COLLATE DATABASE_DEFAULT
	)
	
	DECLARE @StockpilesDesignated TABLE
	(
		StockpileId Int
	)
	
	DECLARE @DataExceptionTypeId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DataExceptionStockpileGroupLocationMissing',
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
		
		SET @DataExceptionTypeId = (SELECT Data_Exception_Type_Id
									FROM dbo.DataExceptionType DET
									WHERE Name = 'Stockpile Not In Designation Group')
		
		INSERT INTO @StockpilesDesignated
		( StockpileId )
		SELECT S.Stockpile_Id
		FROM dbo.Stockpile S
			INNER JOIN dbo.StockpileGroupStockpile SGS 
				ON SGS.Stockpile_Id = S.Stockpile_Id
			INNER JOIN dbo.BhpbioStockpileGroupDesignation BSGD
				ON SGS.Stockpile_Group_Id = BSGD.StockpileGroupId

		INSERT INTO @StockpilesDesignated
		( StockpileId )
		SELECT S.Stockpile_Id
		FROM dbo.Stockpile S
			INNER JOIN dbo.StockpileGroupStockpile SGS
				ON SGS.Stockpile_Id = S.Stockpile_Id
			LEFT JOIN @StockpilesDesignated SD
				ON SD.StockpileId = S.Stockpile_Id
		WHERE SGS.Stockpile_Group_Id IN ('Post Crusher', 'ROM', 'Crusher Product', 'Port Train Rake', 'HUB Train Rake')
			AND SD.StockpileId IS NULL
		
		INSERT INTO @ErrorStockpiles
		( StockpileId, StockpileName )
		SELECT DPT.Source_Stockpile_Id, S.Stockpile_Name
		FROM dbo.DataProcessTransaction DPT
			INNER JOIN Stockpile S
				On S.Stockpile_Id = DPT.Source_Stockpile_Id
			LEFT JOIN dbo.Mill M
				ON M.Stockpile_Id = DPT.Source_Stockpile_Id
			LEFT JOIN @StockpilesDesignated SD
				ON SD.StockpileId = DPT.Source_Stockpile_Id			
		WHERE DPT.Source_Stockpile_Id IS NOT NULL
			AND M.Stockpile_Id IS NULL
			AND SD.StockpileId IS NULL
		GROUP BY DPT.Source_Stockpile_Id, S.Stockpile_Name
			
		INSERT INTO @ErrorStockpiles
		( StockpileId, StockpileName )
		SELECT DPT.Destination_Stockpile_Id, S.Stockpile_Name
		FROM dbo.DataProcessTransaction DPT
			INNER JOIN Stockpile S
				On S.Stockpile_Id = DPT.Destination_Stockpile_Id
			LEFT JOIN dbo.Mill M
				ON M.Stockpile_Id = DPT.Destination_Stockpile_Id
			LEFT JOIN @StockpilesDesignated SD
				ON SD.StockpileId = DPT.Destination_Stockpile_Id			
			LEFT JOIN @ErrorStockpiles ES
				On ES.StockpileId = DPT.Destination_Stockpile_Id
		WHERE DPT.Destination_Stockpile_Id IS NOT NULL
			AND M.Stockpile_Id IS NULL
			AND SD.StockpileId IS NULL
			AND ES.StockpileId IS NULL
		GROUP BY DPT.Destination_Stockpile_Id, S.Stockpile_Name

		UPDATE DE
			SET Data_Exception_Status_Id = 'R'
		FROM DataException DE
			LEFT JOIN @ErrorStockpiles ES
				ON ES.StockpileId = DE.Details_XML.value('(/DocumentElement/Stockpile_Group_Designation/Stockpile_Id)[1]', 'INT')
		WHERE ES.StockpileId IS NULL
			AND DE.Data_Exception_Type_Id = @DataExceptionTypeId

		DELETE ES
		FROM @ErrorStockpiles ES
			INNER JOIN dbo.DataException DE
				ON DE.Data_Exception_Type_Id = @DataExceptionTypeId
					AND DE.Data_Exception_Status_Id IN ('A', 'D')
					AND DE.Details_XML.value('(/DocumentElement/Stockpile_Group_Designation/Stockpile_Id)[1]', 'INT') = ES.StockpileId
		
		INSERT INTO DataException
		( Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, Data_Exception_Status_Id, Short_Description, Long_Description, Details_XML )
		SELECT @DataExceptionTypeId, GetDate(), dbo.GetFirstShiftType(), 'A', 'Stockpile: ' + ES.StockpileName + ', is not in a group with a relevant designation',
			'Stockpile: ' + ES.StockpileName + ', is not assigned to a group with a relevant designation. Please assign the stockpile to one of the relevant designation groups or the post crusher group.',
			'<DocumentElement><Stockpile_Group_Designation><Stockpile_Id>' + CAST(ES.StockpileId AS VARCHAR) + '</Stockpile_Id><Stockpile_Name>' + ES.StockpileName + '</Stockpile_Name></Stockpile_Group_Designation></DocumentElement>'
		FROM @ErrorStockpiles ES
		
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

GRANT EXECUTE ON dbo.BhpbioDataExceptionStockpileGroupLocationMissing TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddBhpbioPortBalance">
 <Procedure>
	Adds port hub balance records.
 </Procedure>
</TAG>
*/