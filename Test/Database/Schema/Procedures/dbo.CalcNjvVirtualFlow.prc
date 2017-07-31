IF OBJECT_ID('dbo.CalcNjvVirtualFlow') IS NOT NULL
	DROP PROCEDURE dbo.CalcNjvVirtualFlow
GO 
  
CREATE PROCEDURE dbo.CalcNjvVirtualFlow
(
	@iCalcDate DATETIME
)
AS 
BEGIN 

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
		SELECT @TransactionName = 'CalcNjvVirtualFlow',
		@TransactionCount = @@TranCount 

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

		DECLARE @WeightometerInflowCount FLOAT
		DECLARE @Inflow FLOAT
		DECLARE @RawInflow FLOAT
		DECLARE @Outflow FLOAT
		DECLARE @Counter INT
		
		DECLARE @WeightometerInflowId AS VARCHAR(31)
		DECLARE @WeightometerOutflowId AS VARCHAR(31)
		
		DECLARE @Cur CURSOR
				
		SET @WeightometerInflowId = 'NJV-COSToOHP'
		
		SELECT TOP 1 @WeightometerOutflowId = wfp.Weightometer_Id 
		FROM WeightometerFlowPeriod wfp 
		WHERE wfp.Source_Crusher_Id = 'NH-OHP4' 
			AND wfp.Destination_Stockpile_Id IS NULL 
			AND (wfp.End_Date IS NULL OR wfp.End_Date >= @iCalcDate)
		ORDER BY 
				CASE WHEN wfp.End_Date IS NULL THEN 1 ELSE 0 END ASC, -- prioritise records with an end date ahead of those without
				wfp.End_Date ASC -- then in ascending order of end_date
		
		-- GET WEIGHTOMETER INFLOW
		SELECT @Inflow = SUM(Coalesce(WS.Corrected_Tonnes, WS.Tonnes)), @RawInflow = SUM(WS.Tonnes)
		FROM WeightometerSample WS
		WHERE Weightometer_Id = @WeightometerInflowId
			AND Weightometer_Sample_Date = @iCalcDate
			AND Destination_Stockpile_Id IS NULL

		-- GET WEIGHTOMETER INFLOWVIRTUAL
		SELECT @Outflow = SUM(Coalesce(WS.Corrected_Tonnes, WS.Tonnes))
		FROM WeightometerSample WS
		WHERE Weightometer_Id = @WeightometerOutflowId
			AND Weightometer_Sample_Date = @iCalcDate
			AND Source_Stockpile_Id IS NULL

		IF @RawInflow = @Outflow
		BEGIN
			UPDATE WeightometerSample
				SET Corrected_Tonnes = NULL
			WHERE Weightometer_Id = @WeightometerInflowId
				AND Weightometer_Sample_Date = @iCalcDate
				AND Destination_Stockpile_Id IS NULL
		END
		ELSE IF Coalesce(@Inflow, 0) > 0 And Coalesce(@Outflow, 0) = 0
		BEGIN
			UPDATE WeightometerSample
				SET Corrected_Tonnes = 0
			WHERE Weightometer_Id = @WeightometerInflowId
				AND Weightometer_Sample_Date = @iCalcDate
				AND Destination_Stockpile_Id IS NULL
		END
		ELSE IF Coalesce(@Inflow, 0) = 0 AND Coalesce(@Outflow, 0) > 0
		BEGIN
			IF EXISTS (SELECT *
						FROM WeightometerSample
						WHERE Weightometer_Id = @WeightometerInflowId
							AND Weightometer_Sample_Date = @iCalcDate
							AND Destination_Stockpile_Id IS NULL)
			BEGIN
				IF @RawInflow > 0
				BEGIN
					UPDATE WeightometerSample
					SET Corrected_Tonnes = (Tonnes / @RawInflow) * @Outflow
					WHERE Weightometer_Id = @WeightometerInflowId
						AND Weightometer_Sample_Date = @iCalcDate
						AND Destination_Stockpile_Id IS NULL
				END
				ELSE
				BEGIN
					DECLARE @NoRecords INT
					SELECT @NoRecords = Count(*)
					FROM WeightometerSample
						WHERE Weightometer_Id = @WeightometerInflowId
							AND Weightometer_Sample_Date = @iCalcDate
							AND Destination_Stockpile_Id IS NULL
							
					UPDATE WeightometerSample
					SET Corrected_Tonnes = @Outflow / @NoRecords
					WHERE Weightometer_Id = @WeightometerInflowId
						AND Weightometer_Sample_Date = @iCalcDate
						AND Destination_Stockpile_Id IS NULL
				END
			END
			ELSE
			BEGIN
				EXEC AddWeightometerSample
					@iWeightometer_Id = @WeightometerInflowId,
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = 'D',
					@iTonnes = @Outflow,
					@iOrder_No = 1,
					@oWeightometer_Sample_Id = Null
			END
		END
		ELSE IF Coalesce(@Inflow, 0) <> Coalesce(@Outflow, 0)
		BEGIN
			UPDATE WeightometerSample
				SET Corrected_Tonnes = (Coalesce(Corrected_Tonnes, Tonnes, 0) / @Inflow) * @Outflow
				WHERE Weightometer_Id = @WeightometerInflowId
					AND Weightometer_Sample_Date = @iCalcDate
					AND Destination_Stockpile_Id IS NULL
		END
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
					
		Exec RecalcL1Raise @iCalcDate
		
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

GRANT EXECUTE ON dbo.CalcNjvVirtualFlow TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcNjvVirtualFlow">
 <Procedure>
	Updates the Yandi Production Data for the crushers.
 </Procedure>
</TAG>
*/

