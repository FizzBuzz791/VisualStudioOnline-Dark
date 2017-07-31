-- ************************************************************************************
--
-- IMPORTANT:
-- Disable Reconcilor Services before executing script.  Trigger calc virtual flow
-- from 12/12/2012 following successful execution to force recalculation and
-- crusher balancing.
--
-- TEST STEPS:
--  * New haulage to IOWA and other primary crushers is resolved as the correct YD-OHP
--    secondary crusher equivalent.
--  * No production import validation failures are raised related to missing source, 
--    destination or weightometer configuration at Yandi (existing errors should be
--    resolved subsequent ot import run).
--  * YD-COS movements do not contribute to the 'z' and 'C' values used to calculate
--    Ex-pit Equivalent figures.
--  * No new weightometer sample records are created (virtual or otherwise) for movements
--    sourced from Yandi primary crushers.
--
--
-- POST DEPLOYMENT MONITORING:
--  * Manually trigger haulage and production imports and check for successful execution.
--  * Ensure no new haulage records appear post 12th December that deliver material to 
--    a Yandi primary crusher (IOWA, ICP, YD-Y2)
--  * Ensure no new weightometer sample records appear for the Yandi primary crusher
--    weightometers (YD-IOWA_To_YD-Y2, YD-Y2_VirtualFlow, YD-ICP_To_YD-Y2)
--
-- ************************************************************************************

BEGIN TRAN

  -- working variables
  DECLARE @HaulageResolveId Int
  DECLARE @HaulageResolveCode Varchar(31)
  DECLARE @CosStockpileId Int
  DECLARE @WeightometerSampleDate DateTime

  -- constants
  DECLARE @CutoffDate DateTime
  DECLARE @CutoffDatePlusOne DateTime
  DECLARE @WeightometerIowa Varchar(20)
  DECLARE @WeightometerYD2PC Varchar(20)
  DECLARE @WeightometerYD2ICP Varchar(20)
  DECLARE @CrusherIowa Varchar(20)
  DECLARE @CrusherYD2PCNew Varchar(20)
  DECLARE @CrusherYD2PCOld Varchar(20)
  DECLARE @CrusherYD2ICP Varchar(20)
  DECLARE @CrusherYD1PC Varchar(20)
  DECLARE @CrusherYD3EASTPC Varchar(20)
  DECLARE @CrusherYD3WESTPC Varchar(20)
  DECLARE @CrusherYDOHP1 Varchar(20)
  DECLARE @CrusherYDOHP2 Varchar(20)
  DECLARE @CrusherYDOHP3 Varchar(20)
  DECLARE @ReportExcludeGroup Varchar(20)

  -- set up constants

  SET @CutoffDate = '2012-12-12'
  SET @CutoffDatePlusOne = DateAdd(DAY, 1, @CutoffDate)
  SET @ReportExcludeGroup = 'ReportExclude'

  -- defunct primary crushers
  SET @CrusherIowa = 'YD-IOWA'
  SET @CrusherYD1PC = 'YD-YD1-PC'
  SET @CrusherYD2PCOld = 'YD-Y2'
  SET @CrusherYD2PCNew = 'YD-YD2-PC'
  SET @CrusherYD2ICP = 'YD-ICP'
  SET @CrusherYD3EASTPC = 'YD-YD3-EAST-PC'
  SET @CrusherYD3WESTPC = 'YD-YD3-WEST-PC'

  -- defunct weightometers
  SET @WeightometerIowa = 'YD-IOWA_To_YD-Y2'
  SET @WeightometerYD2PC = 'YD-Y2_VirtualFlow'
  SET @WeightometerYD2ICP = 'YD-ICP_To_YD-Y2'

  -- secondary crushers
  SET @CrusherYDOHP1 = 'YD-OHP1'
  SET @CrusherYDOHP2 = 'YD-OHP2'
  SET @CrusherYDOHP3 = 'YD-OHP3'

  -- disable virtual flows for Yandi Primary Crushers
  -- (from 13th December onwards only secondary crushers will be modelled)
  UPDATE WeightometerFlowPeriod
  SET End_Date = @CutoffDate
  WHERE Weightometer_Id = @WeightometerIowa
  OR Weightometer_Id = @WeightometerYD2PC
  OR Weightometer_Id = @WeightometerYD2ICP

  -- expire any existing haulage resolution rules and create replacement rules
  DECLARE HaulageResolveCursor CURSOR FOR
  SELECT Haulage_Resolve_Basic_Id, Code
  FROM HaulageResolveBasic
  WHERE Resolve_To_Date IS NULL
  AND (Crusher_Id = @CrusherIowa OR Crusher_Id = @CrusherYD2PCOld OR Crusher_Id = @CrusherYD2ICP)

  OPEN HaulageResolveCursor
  FETCH NEXT FROM HaulageResolveCursor INTO @HaulageResolveId, @HaulageResolveCode

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- disable this entry
    EXECUTE UpdateHaulageCorrectionResolutionBasic 
       @iHaulage_Resolve_Basic_Id = @HaulageResolveId
      ,@iDeactivate = 1
      ,@iDeactivate_Date = @CutoffDate
      ,@iDeactivate_Shift = 'D'

    -- create an equivalent entry that resolves directly to YD-OHP2
    EXECUTE AddHaulageCorrectionResolutionBasic
       @iCode = @HaulageResolveCode
      ,@iResolve_From_Date = @CutoffDatePlusOne
      ,@iResolve_From_Shift = 'D'
      ,@iCrusher_Id = @CrusherYDOHP2
    
    FETCH NEXT FROM HaulageResolveCursor INTO @HaulageResolveId, @HaulageResolveCode
  END

  CLOSE HaulageResolveCursor
  DEALLOCATE HaulageResolveCursor

  -- create additional rules to bypass IOWA and YD-Y2 (delete or disable any existing)
  DELETE FROM HaulageResolveBasic
  WHERE CODE = @CrusherIowa
  OR CODE = @CrusherYD2PCOld

  EXECUTE AddHaulageCorrectionResolutionBasic
     @iCode = @CrusherIowa
    ,@iResolve_From_Date = @CutoffDatePlusOne
    ,@iResolve_From_Shift = 'D'
    ,@iCrusher_Id = @CrusherYDOHP2

  EXECUTE AddHaulageCorrectionResolutionBasic
     @iCode = @CrusherYD2PCOld
    ,@iResolve_From_Date = @CutoffDatePlusOne
    ,@iResolve_From_Shift = 'D'
    ,@iCrusher_Id = @CrusherYDOHP2

  -- create additional rules for new Yandi primary crushers
  IF NOT EXISTS (SELECT 1 FROM HaulageResolveBasic WHERE Code = @CrusherYD1PC AND Crusher_Id = @CrusherYDOHP1)
  BEGIN
    EXECUTE AddHaulageCorrectionResolutionBasic
       @iCode = @CrusherYD1PC
      ,@iResolve_From_Date = @CutoffDatePlusOne
      ,@iResolve_From_Shift = 'D'
      ,@iCrusher_Id = @CrusherYDOHP1
  END

  IF NOT EXISTS (SELECT 1 FROM HaulageResolveBasic WHERE Code = @CrusherYD2PCNew AND Crusher_Id = @CrusherYDOHP2)
  BEGIN
    EXECUTE AddHaulageCorrectionResolutionBasic
         @iCode = @CrusherYD2PCNew
        ,@iResolve_From_Date = @CutoffDatePlusOne
        ,@iResolve_From_Shift = 'D'
        ,@iCrusher_Id = @CrusherYDOHP2
  END

  IF NOT EXISTS (SELECT 1 FROM HaulageResolveBasic WHERE Code = @CrusherYD3EASTPC AND Crusher_Id = @CrusherYDOHP3)
  BEGIN
    EXECUTE AddHaulageCorrectionResolutionBasic
       @iCode = @CrusherYD3EASTPC
      ,@iResolve_From_Date = @CutoffDatePlusOne
      ,@iResolve_From_Shift = 'D'
      ,@iCrusher_Id = @CrusherYDOHP3
  END

  IF NOT EXISTS (SELECT 1 FROM HaulageResolveBasic WHERE Code = @CrusherYD3WESTPC AND Crusher_Id = @CrusherYDOHP3)
  BEGIN
    EXECUTE AddHaulageCorrectionResolutionBasic
       @iCode = @CrusherYD3WESTPC
      ,@iResolve_From_Date = @CutoffDatePlusOne
      ,@iResolve_From_Shift = 'D'
      ,@iCrusher_Id = @CrusherYDOHP3
  END

  -- add YD-COS stockpiles to report exclusion stockpile group
  DECLARE YandiCosCursor CURSOR FOR
  SELECT Stockpile_Id
  FROM Stockpile
  WHERE Stockpile_Name Like 'YD-YD_-COS'

  OPEN YandiCosCursor
  FETCH NEXT FROM YandiCosCursor INTO @CosStockpileId

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- add stockpile group entry
    EXECUTE AddStockpileGroupStockpile
       @iStockpile_Group_Id = @ReportExcludeGroup
      ,@iStockpile_Id = @CosStockpileId
    
    FETCH NEXT FROM YandiCosCursor INTO @CosStockpileId
  END

  CLOSE YandiCosCursor
  DEALLOCATE YandiCosCursor

  -- insert production resolution rules

  INSERT INTO BhpbioProductionResolveBasic (
    [Code]
   ,[Resolve_From_Date]
   ,[Resolve_From_Shift]
   ,[Crusher_Id]
   ,[Description]
   ,[Production_Direction])
  SELECT @CrusherYD1PC, @CutoffDatePlusOne, 'D', @CrusherYDOHP1, 'Yandi Primary Crusher 1 Resolve to Secondary Crusher 1', 'B' UNION ALL
  SELECT @CrusherIowa, @CutoffDatePlusOne, 'D', @CrusherYDOHP2, 'Yandi Primary Crusher Iowa Resolve to Secondary Crusher 2', 'B' UNION ALL
  SELECT @CrusherYD2PCNew, @CutoffDatePlusOne, 'D', @CrusherYDOHP2, 'Yandi Primary Crusher 2 Resolve to Secondary Crusher 2', 'B' UNION ALL
  SELECT @CrusherYD3EASTPC, @CutoffDatePlusOne, 'D', @CrusherYDOHP3, 'Yandi Primary Crusher 3 East Resolve to Secondary Crusher 3', 'B' UNION ALL
  SELECT @CrusherYD3WESTPC, @CutoffDatePlusOne, 'D', @CrusherYDOHP3, 'Yandi Primary Crusher 3 West Resolve to Secondary Crusher 3', 'B' 

  -- update existing haulage 
  UPDATE Haulage
  SET Destination_Crusher_Id = @CrusherYDOHP2
  WHERE Haulage_Date > @CutoffDate
  AND (Destination_Crusher_Id = @CrusherIowa OR Destination_Crusher_Id = @CrusherYD2PCOld)

  -- delete virtual weightometer records 
  DELETE FROM WeightometerSample
  WHERE Weightometer_Sample_Date > @CutoffDate 
  AND (Weightometer_Id = @WeightometerYD2PC)
  
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


-- re-resolve all haulage
EXEC HaulageRawResolveAll
GO





