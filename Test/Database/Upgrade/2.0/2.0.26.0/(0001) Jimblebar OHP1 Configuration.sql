-- ************************************************************************************
--
-- IMPORTANT:
-- Disable Reconcilor Services before executing script.  Trigger calc virtual flow
-- from 01/09/2013 following successful execution to force recalculation and
-- crusher balancing.
--
-- TEST STEPS:
--  * New haulage to JB-C1, JB-C2 is resolved to JB-OHP1 direct
--  * No production import validation failures are raised related to missing source, 
--    destination or weightometer configuration at Yandi (existing errors should be
--    resolved subsequent ot import run).
--  * JB-COS1 and JB-COS2 movements do not contribute to the 'z' and 'C' values used to calculate
--    Ex-pit Equivalent figures.
--  * No new weightometer sample records are created (virtual or otherwise) for movements
--    sourced from JB-C1, JB-C2 crushers.
--
--
-- POST DEPLOYMENT MONITORING:
--  * Manually trigger haulage and production imports and check for successful execution.
--  * Ensure no new haulage records appear post September 2013 that deliver material to 
--    JB-C1, JB-C2
--  * Ensure no new weightometer sample records appear for JB-C1, JB-C2
--
-- ************************************************************************************

BEGIN TRAN

  -- working variables
  DECLARE @HaulageResolveId Int
  DECLARE @HaulageResolveCode Varchar(31)
  DECLARE @ResolveFromDate DateTime
  DECLARE @CosStockpileId Int
  DECLARE @WeightometerSampleDate DateTime

  -- constants
  DECLARE @CutoffDate DateTime
  DECLARE @CutoffDatePlusOne DateTime
  DECLARE @CutoffDate2 DateTime
  DECLARE @CutoffDate2PlusOne DateTime
  DECLARE @CrusherC1 Varchar(20)
  DECLARE @CrusherC2 Varchar(20)
  
  DECLARE @CrusherOHP1 Varchar(20)
  DECLARE @CrusherC1MQ2Code Varchar(20)
  DECLARE @CrusherC2MQ2Code Varchar(20)
  DECLARE @WeightometerC1 Varchar(20)
  DECLARE @WeightometerC2 Varchar(20)
  DECLARE @WeightometerOHP1 Varchar(20)
  DECLARE @ReportExcludeGroup Varchar(20)

  -- set up constants

  SET @CutoffDate = '2013-08-31'
  SET @CutoffDatePlusOne = DateAdd(DAY, 1, @CutoffDate)

  SET @CutoffDate2 = '2014-01-31'
  SET @CutoffDate2PlusOne = DateAdd(DAY, 1, @CutoffDate2)
  
  SET @ReportExcludeGroup = 'ReportExclude'

  -- primary crushers
  SET @CrusherC1 = 'JB-C1'
  SET @CrusherC2 = 'JB-C2'
  SET @CrusherC1MQ2Code = 'JB-CR01'
  SET @CrusherC2MQ2Code = 'JB-CR02'

  -- defunct weightometers
  SET @WeightometerC1 = 'JB-C1OutFlow'
  SET @WeightometerC2 = 'JB-C2OutFlow'
  
  -- crushers to be reported for Actual Z & C
  SET @CrusherOHP1 = 'JB-OHP1'
  SET @WeightometerOHP1 = 'JB-OHP1OutFlow'
  
  -- Adjust existing resolve rule for C2
  UPDATE HaulageResolveBasic 
	SET Resolve_From_Date = @CutoffDate2PlusOne
  WHERE Code = @CrusherC2MQ2Code AND Resolve_To_Date IS NULL

  -- disable virtual flows for JB-C1 and JB-C2
  -- (from September 2013 onwards only secondary crushers will be modelled)
  UPDATE WeightometerFlowPeriod
  SET End_Date = @CutoffDate
  WHERE Weightometer_Id = @WeightometerC1

  UPDATE WeightometerFlowPeriod
  SET End_Date = @CutoffDate2
  WHERE Weightometer_Id = @WeightometerC2
  
  -- update existing haulage 
  UPDATE Haulage
  SET Destination_Crusher_Id = @CrusherOHP1
  WHERE Haulage_Date > @CutoffDate2
  AND (Destination_Crusher_Id = @CrusherC2)
  
  -- update existing weightometer sample
  UPDATE WeightometerSample
  SET Weightometer_Id = @WeightometerOHP1
  WHERE Weightometer_Sample_Date > @CutoffDate2
  AND (Weightometer_Id = @WeightometerC2)

  -- add JB-COS stockpiles to report exclusion stockpile group
  DECLARE CosCursor CURSOR FOR
  SELECT Stockpile_Id
  FROM Stockpile
  WHERE Stockpile_Name Like 'JB%COS%'

  OPEN CosCursor
  FETCH NEXT FROM CosCursor INTO @CosStockpileId

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- add stockpile group entry
    EXECUTE AddStockpileGroupStockpile
       @iStockpile_Group_Id = @ReportExcludeGroup
      ,@iStockpile_Id = @CosStockpileId
    
    FETCH NEXT FROM CosCursor INTO @CosStockpileId
  END

  CLOSE CosCursor
  DEALLOCATE CosCursor

  -- insert production resolution rules
  INSERT INTO BhpbioProductionResolveBasic (
    [Code]
   ,[Resolve_From_Date]
   ,[Resolve_From_Shift]
   ,[Crusher_Id]
   ,[Description]
   ,[Production_Direction])
  SELECT @CrusherC1MQ2Code, @CutoffDatePlusOne, 'D', @CrusherOHP1, 'JB Crusher 1 to JB-OHP 1', 'B' UNION ALL
  SELECT @CrusherC2MQ2Code, @CutoffDate2PlusOne, 'D', @CrusherOHP1, 'JB Crusher 2 to JB-OHP 2', 'B'
 
  -- raise recalc processing for affected period
  DECLARE WeightometerSampleCursor CURSOR FOR
  SELECT DISTINCT Weightometer_Sample_Date
  FROM WeightometerSample
  WHERE Weightometer_Sample_Date > @CutoffDate
  ORDER BY Weightometer_Sample_Date ASC

  OPEN WeightometerSampleCursor
  FETCH NEXT FROM WeightometerSampleCursor INTO @WeightometerSampleDate

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- add recalc queue entry
    EXECUTE RecalcL1Raise 
      @pDate = @WeightometerSampleDate
      
    FETCH NEXT FROM WeightometerSampleCursor INTO @WeightometerSampleDate
  END
  
  CLOSE WeightometerSampleCursor
  DEALLOCATE WeightometerSampleCursor

--ROLLBACK TRANSACTION
COMMIT TRANSACTION
GO