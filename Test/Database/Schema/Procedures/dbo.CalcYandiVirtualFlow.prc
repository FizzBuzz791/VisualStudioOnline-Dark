IF OBJECT_ID('dbo.CalcYandiVirtualFlow') IS NOT NULL
	DROP PROCEDURE dbo.CalcYandiVirtualFlow
GO 
  
CREATE PROCEDURE dbo.CalcYandiVirtualFlow
(
	@iCalcDate DATETIME
)
AS 
BEGIN 
	  -- this is the date when COS stockpiles were introduced for Yandi, subsequent to this date
	  -- Reconcilor has been re-configured not to model the Yandi primary crushers at all,
	  -- and name resolution rules put in place to divert all movements to/from the secondary
	  -- (OHP) crushers.  therefore no crusher balancing logic is required subsequent to this
	  -- date
    DECLARE @YandiCrusherReconfigurationDate DateTime
    SET @YandiCrusherReconfigurationDate = '2012-12-12'

    IF (@iCalcDate <= @YandiCrusherReconfigurationDate)
    BEGIN

		DECLARE @TransactionCount INT
		DECLARE @TransactionName VARCHAR(32)

		SET NOCOUNT ON 
		
			SELECT @TransactionName = 'CalcYandiVirtualFlow',
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
		  DECLARE @Outflow FLOAT
		  DECLARE @InflowVirtual FLOAT
		  DECLARE @WeightometerSampleId INT
		  DECLARE @Counter INT
      		
		  DECLARE @Weightometer_ID AS VARCHAR(31)
  		
		  DECLARE @Cur CURSOR
  				
		  SET @Weightometer_ID = 	'YD-Y2_VirtualFlow'	
  		
		  -- GET WEIGHTOMETER INFLOW
		  SELECT @Inflow = SUM(WS.Tonnes)
		  FROM WeightometerSample WS
		  WHERE Weightometer_Id In ('YD-ICP_To_YD-Y2', 'YD-IOWA_To_YD-Y2')
			  AND Weightometer_Sample_Date = @iCalcDate

		  -- GET WEIGHTOMETER INFLOWVIRTUAL
		  SELECT @InflowVirtual = SUM(WS.Tonnes)
		  FROM WeightometerSample WS
		  WHERE Weightometer_Id In ('YD-Y2_VirtualFlow')
			  AND Weightometer_Sample_Date = @iCalcDate

		  -- GET WEIGHTOMETER OUTFLOW
		  SELECT @Outflow = SUM(WS.Tonnes)
		  FROM WeightometerSample WS
		  WHERE Weightometer_Id In ('YD-Y2Outflow')
			  AND Weightometer_Sample_Date = @iCalcDate

		  IF Coalesce(@Inflow, 0) + Coalesce(@InflowVirtual, 0) <> Coalesce(@Outflow, 0)
		  BEGIN
			  IF EXISTS (SELECT *
						  FROM WeightometerSample
						  WHERE Weightometer_Id = @Weightometer_ID
							  AND Weightometer_Sample_Date = @iCalcDate)
			  BEGIN
				  SET @Cur = CURSOR FOR
					  SELECT Weightometer_Sample_Id
					  FROM WeightometerSample
					  WHERE Weightometer_Id = @Weightometer_ID
						  AND Weightometer_Sample_Date = @iCalcDate
  				
				  OPEN @Cur
  				
				  FETCH NEXT FROM @Cur INTO @WeightometerSampleId
  				
				  WHILE @@FETCH_STATUS = 0
				  BEGIN
					  EXEC DeleteWeightometerSample
						  @iWeightometer_Sample_Id = @WeightometerSampleId
  						
					  FETCH NEXT FROM @Cur INTO @WeightometerSampleId
				  END
  				
				  CLOSE @Cur
				  DEALLOCATE @Cur
			  END
  			
			  SET @InflowVirtual = @Outflow - Coalesce(@Inflow, 0)
  			
			  If @InflowVirtual >= 0
			  BEGIN
				  EXEC AddWeightometerSample
					  @iWeightometer_Id = @Weightometer_ID,
					  @iWeightometer_Sample_Date = @iCalcDate,
					  @iWeightometer_Sample_Shift = 'D',
					  @iTonnes = @InflowVirtual,
					  @iOrder_No = 1,
					  @oWeightometer_Sample_Id = Null
  					
				  UPDATE WeightometerSample
				  SET Corrected_Tonnes = NULL
				  WHERE Weightometer_Id In ('YD-ICP_To_YD-Y2', 'YD-IOWA_To_YD-Y2')
					  AND Weightometer_Sample_Date = @iCalcDate
			  END
			  ELSE
			  BEGIN
				  UPDATE WeightometerSample
				  SET Corrected_Tonnes = Tonnes * Coalesce(@Outflow, 0) / Coalesce(@Inflow, 0)
				  WHERE Weightometer_Id In ('YD-ICP_To_YD-Y2', 'YD-IOWA_To_YD-Y2')
					  AND Weightometer_Sample_Date = @iCalcDate
			  END
		  END
		  ELSE
		  BEGIN
			  UPDATE WeightometerSample
			  SET Corrected_Tonnes = NULL
			  WHERE Weightometer_Id In ('YD-ICP_To_YD-Y2', 'YD-IOWA_To_YD-Y2', @Weightometer_ID, 'YD-Y2Outflow')
				  AND Weightometer_Sample_Date = @iCalcDate
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
END 
GO

GRANT EXECUTE ON dbo.CalcYandiVirtualFlow TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcYandiVirtualFlow">
 <Procedure>
	Updates the Yandi Production Data for the crushers.
 </Procedure>
</TAG>
*/



