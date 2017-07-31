IF OBJECT_ID('dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments') IS NOT NULL
     DROP PROCEDURE dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments
GO 
  
CREATE PROCEDURE dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'CorrectBhpbioProductionWeightometerAndDestinationAssignments',
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
	
		Declare @startDateRangeToCheck DateTime
		Declare @endDateRangeToCheck DateTime
		
		Set @startDateRangeToCheck = dbo.GetSystemStartDate()
		Set @endDateRangeToCheck = GetDate()
		
		-- An in-memory table used to store information about weightometer samples that require correction
		Declare @WeightometerSamplesToUpdate Table(
			Weightometer_Sample_Id Int,
			Weightometer_Sample_Date DateTime,
			Current_Weightometer_Id Varchar(31),
			Current_Destination_Stockpile_Id Int,
			Location_Id Int,
			Expected_Weightometer_Id Varchar(31),
			Expected_Destination_Stockpile_Id Int,
			Is_New Bit Default 1
		)

		-- An in-memory table used to set correction variables
		-- This is used because a number of different corrections need to be applied.  These corrections can be made to operate generically based on control parameters
		-- added to this table
		Declare @correctionControlTable Table (
			SourceStockpileGroup varchar(31),
			DestinationStockpileGroup varchar(31),
			WeightometerSuffix varchar(31),
			Update_Weightometer bit,
			Update_Destination_Stockpile_Id bit
		)

		Declare @minEffectedSampleDate DateTime

		-- This is the data that controls the correction flow
		-- It is used to select weightometer samples based on weightometer suffixes, stockpile groupings
		Insert Into @correctionControlTable
			-- Select [Source Group], [Destination Group], [Weightometer Suffix], [Update Weightometer Flag], [Update Destination Flag]
			Select null, 'Port Train Rake', 'PostCrusherToTrainRake', 1, 1 Union
			Select null, 'Post Crusher','PostCrusherToPostCrusher', 1, 0 Union
			Select 'Post Crusher', null, 'PostCrusherToPreCrusher', 1, 0

		-- Variables to hold the contents of the control variables for each loop
		Declare @sourceStockpileGroup Varchar(31)
		Declare @destinationStockpileGroup Varchar(31)
		Declare @weightometerSuffix Varchar(31)
		Declare @updateWeightometer Bit
		Declare @updateDestinationStockpile Bit

		-- A cursor used to process contents of the control table
		Declare curWeightometer Cursor For 
			Select SourceStockpileGroup, DestinationStockpileGroup, WeightometerSuffix, Update_Weightometer, Update_Destination_Stockpile_Id
			From @correctionControlTable
			
		Open curWeightometer

		-- process every row in the control table
		Fetch Next From curWeightometer Into @sourceStockpileGroup, @destinationStockpileGroup, @weightometerSuffix, @updateWeightometer, @updateDestinationStockpile
		While @@FETCH_STATUS = 0
		Begin
			-- Find all weightometer samples where: 
			--   there is a mismatch between source and destination location Ids
			--	 the weightometer suffix matches that specified in the control table
			--	 AND there is some kind of location mismatch.. either the source and destination stockpile locations don't match... 
			--	or the location of the source does not match the location of the weightometer
			Insert Into @WeightometerSamplesToUpdate (
				Weightometer_Sample_Id,
				Weightometer_Sample_Date,
				Current_Weightometer_Id,
				Current_Destination_Stockpile_Id,
				Location_Id
			)
			Select ws.Weightometer_Sample_Id,
				   ws.Weightometer_Sample_Date,
				   ws.Weightometer_Id as Current_Weightometer_Id,
				   ws.Destination_Stockpile_Id as Current_Destination_Stockpile_Id,
				   sld.Location_Id
			From WeightometerSample ws
				-- join in informaton about the source stockpile
				Inner Join Stockpile s ON s.Stockpile_Id = ws.Source_Stockpile_Id
				-- including its dynamic locaiton assignment at the time of the transaction
				Inner Join BhpbioStockpileLocationDate sld ON sld.Stockpile_Id = s.Stockpile_Id And ws.Weightometer_Sample_Date BETWEEN sld.Start_Date and sld.End_Date
				Inner Join BhpbioLocationDate l ON l.Location_Id = sld.Location_Id
					And ws.Weightometer_Sample_Date between l.Start_Date and l.End_Date
				-- join in location information about the weightometer
				Inner Join dbo.GetBhpbioWeightometerLocationWithOverride(@startDateRangeToCheck, @endDateRangeToCheck) wlo
					ON wlo.Weightometer_Id = ws.Weightometer_Id
					And ws.Weightometer_Sample_Date between wlo.IncludeStart and wlo.IncludeEnd
				-- join in information about the destination stockpile
				Inner Join Stockpile d 	ON d.Stockpile_Id = ws.Destination_Stockpile_Id
				Inner Join BhpbioStockpileLocationDate dld ON dld.Stockpile_Id = d.Stockpile_Id And ws.Weightometer_Sample_Date BETWEEN dld.Start_Date and dld.End_Date
			Where	-- where the weightometer suffix matches that specified in the control variable
					ws.Weightometer_Id like '%' + @weightometerSuffix
					-- and the locations don't match (ie cross-site issue detected OR weightometer location does not match source location)
					And 
						(
							   (sld.Location_Id <> dld.Location_Id And l.Parent_Location_Id <> dld.Location_Id)
							OR (sld.Location_Id <> wlo.Location_Id)
						)
					-- and the source stockpile is within the required group (if any group is required at all for this operation)
					AND 
						( 
							@sourceStockpileGroup IS NULL
							OR EXISTS (Select * from StockpileGroupStockpile ssgs where ssgs.Stockpile_Id = s.Stockpile_Id ANd ssgs.Stockpile_Group_Id = @sourceStockpileGroup)
						)
			
			-- find the expected weightometer
			If @updateWeightometer = 1
			Begin
				-- if the weightometer is to be corrected
				-- find the weightometer that has a matching suffix that exists at the relevant location
				Update wsu 
				Set Expected_Weightometer_Id = wlo.Weightometer_Id
				From @WeightometerSamplesToUpdate wsu
					Inner Join dbo.GetBhpbioWeightometerLocationWithOverride(@startDateRangeToCheck, @endDateRangeToCheck) wlo
							On wlo.Weightometer_Id like '%' + @weightometerSuffix
							And wlo.Location_Id = wsu.Location_Id
							And wsu.Weightometer_Sample_Date between wlo.IncludeStart and wlo.IncludeEnd
				Where wsu.Is_New = 1
					And wsu.Current_Weightometer_Id <> wlo.Weightometer_Id
			End
			
			-- find the expected destination stockpile
			If @updateDestinationStockpile = 1
			Begin
				-- if the destination stockpile Id is to be corrected
				-- find the stockpile that belongs to the specified stockpile group AND exists at the relevant location at the time of the transaction
				Update wsu 
				Set Expected_Destination_Stockpile_Id = sld.Stockpile_Id
				From @WeightometerSamplesToUpdate wsu
					Inner Join BhpbioStockpileLocationDate sld 
						On sld.Location_Id = wsu.Location_Id
							And wsu.Weightometer_Sample_Date between sld.Start_date and sld.End_Date
					Inner Join StockpileGroupStockpile sgs
						On sld.Stockpile_Id = sgs.Stockpile_Id
							And sgs.Stockpile_Group_Id = @destinationStockpileGroup
				Where wsu.Is_New = 1
					And wsu.Current_Destination_Stockpile_Id <> sld.Stockpile_Id
			End
			
			Update @WeightometerSamplesToUpdate
			Set Is_New = 0
			-- get the next set of control variables
			Fetch Next From curWeightometer Into @sourceStockpileGroup, @destinationStockpileGroup, @weightometerSuffix, @updateWeightometer, @updateDestinationStockpile
		End

		-- we have now finished with the cursor.. close and deallocate
		Close curWeightometer
		Deallocate curWeightometer

		-- perfrom the update operation against the weightometer sample table
		Update ws
		Set ws.Weightometer_Id = IsNull(wsu.Expected_Weightometer_Id,ws.Weightometer_Id),
			ws.Destination_Stockpile_Id = IsNull(wsu.Expected_Destination_Stockpile_Id,ws.Destination_Stockpile_Id)
		From WeightometerSample ws
			Inner Join @WeightometerSamplesToUpdate wsu 
			On wsu.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				
		-- if corrections were made... raise a calc virtual flow at the earliest correction date
		Select @minEffectedSampleDate = Min(ws.Weightometer_Sample_Date)
		From WeightometerSample ws
			Inner Join @WeightometerSamplesToUpdate wsu 
				On wsu.Weightometer_Sample_Id = ws.Weightometer_Sample_Id

		If (@minEffectedSampleDate is not null)
		Begin
			exec dbo.CalcVirtualFlowRaise @minEffectedSampleDate
		End
	
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

GRANT EXECUTE ON dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments TO BhpbioGenericManager
GO

