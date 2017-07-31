IF OBJECT_ID('dbo.UpdateBhpbioMissingSampleDataException') IS NOT NULL
	DROP PROCEDURE dbo.UpdateBhpbioMissingSampleDataException
GO 

CREATE PROCEDURE [dbo].[UpdateBhpbioMissingSampleDataException]
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @minimumSignificantTonnes INTEGER
	
	SET NOCOUNT ON 
	
	-- determine the minimum movement tonnages to be considered significant
	SELECT @minimumSignificantTonnes = convert(INTEGER, value)
	FROM Setting
	WHERE Setting_Id = 'WEIGHTOMETER_MINIMUM_TONNES_SIGNIFICANT'
	
	IF @minimumSignificantTonnes IS NULL
	BEGIN
		SET @minimumSignificantTonnes = 1
	END
	
	SELECT @TransactionName = 'UpdateBhpbioMissingSampleDataException',
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
		
		IF @iDateFrom > @iDateTo
		BEGIN
			RAISERROR('Date From cannot occur after Date To', 16, 1)		
		END
		
		DECLARE @DataExceptionTypeId INT
				
		DECLARE @BCStartDate DATETIME
				
		DECLARE @CurrentDate DATETIME	
		DECLARE @AdjustedDate DATETIME
			
		DECLARE @SettingValue VARCHAR(255)
		DECLARE @DaysFromCurrentToExclude INT
			
		DECLARE @CurrentProcessingDate DATETIME
		
		DECLARE @ProcessDate TABLE
		(
			[Date] DATETIME
		)
					
		SET @CurrentDate = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) 
		
		-- Grab the exception type
		SELECT @DataExceptionTypeId = Data_Exception_Type_Id
		FROM dbo.DataExceptionType
		WHERE [Name] = 'No sample information over a 24-hour period'
				
		IF @DataExceptionTypeId IS NULL
		BEGIN
			RAISERROR('Data Exception Type for missing sample information could not be found', 16, 1)	
		END
		
		-- Get the number of days prior to the current date to exclude from the missing sample scan
		EXEC dbo.GetSystemSetting 
				@iSetting_Id = 'WEIGHTOMETER_MISSING_SAMPLE_IGNORE_MOST_RECENT_DAYS',
				@iValue = @SettingValue OUTPUT
		
		SET @DaysFromCurrentToExclude = CAST(COALESCE(@SettingValue, '0') AS INT)
		SET @AdjustedDate = DATEADD(DAY, @DaysFromCurrentToExclude * (-1), @CurrentDate)
		
		SET @SettingValue = NULL
		
		EXEC dbo.GetSystemSetting 
				@iSetting_Id = 'WB_C2_BACK_CALCULATION_START_DATE',
				@iValue = @SettingValue OUTPUT
		
		SET @BCStartDate = CAST(COALESCE(@SettingValue, '1-Jan-2014') AS DATETIME)
		
		IF (NOT @AdjustedDate < @BCStartDate AND NOT @iDateTo < @BCStartDate)
		BEGIN
		
			-- adjust the parameter date range if they fall within the exclusion zone
			IF @AdjustedDate < @iDateTo
			BEGIN		
				SET @iDateTo = @AdjustedDate			
			END
			
			IF @iDateFrom < @BCStartDate
			BEGIN
				SET @iDateFrom = @BCStartDate	
			END
			ELSE IF @AdjustedDate < @iDateFrom
			BEGIN		
				SET @iDateFrom = @AdjustedDate			
			END
			
			SET @CurrentProcessingDate = @iDateFrom
			
			-- Generate a table of distinct days to check for exceptions
			WHILE (@CurrentProcessingDate <= @iDateTo)
			BEGIN
			
				INSERT INTO @ProcessDate ([Date])
				VALUES (@CurrentProcessingDate)
				
				SET @CurrentProcessingDate = DATEADD(DAY, 1, @CurrentProcessingDate)
				
			END

			DECLARE @MissingSamples TABLE
			(
				Weightometer VARCHAR(31),
				[Date] DATETIME,
				Shift CHAR(1),
				PRIMARY KEY (Weightometer, [Date], Shift)
			)
			
			DECLARE @ExistingDataExceptions TABLE
			(
				DataExceptionId INT,
				Weightometer VARCHAR(31),
				[Date] DATETIME,
				Shift CHAR(1),
				PRIMARY KEY (DataExceptionId, Weightometer, [Date], Shift)
			)												
			
			-- Locate instances of missing samples
			INSERT INTO @MissingSamples (Weightometer, [Date], Shift)
			SELECT DISTINCT w.Weightometer_Id, pd.[Date], st.[Shift]
			FROM dbo.Weightometer w			
			CROSS JOIN @ProcessDate pd
			CROSS JOIN dbo.ShiftType st		
			LEFT OUTER JOIN dbo.BhpbioWeightometerDataExceptionExemption wdee
				ON w.Weightometer_Id = wdee.Weightometer_Id
					AND @DataExceptionTypeId = wdee.Data_Exception_Type_Id
					AND wdee.[Start_Date] <= pd.[Date]
					AND (wdee.End_Date IS NULL OR wdee.End_Date >= pd.[Date])	
			LEFT OUTER JOIN dbo.WeightometerFlowPeriod wfp
				ON wfp.Weightometer_Id = w.Weightometer_Id				
			WHERE (SELECT SUM(ws.Tonnes)
					FROM dbo.WeightometerSample ws
					WHERE ws.Weightometer_Id = w.Weightometer_Id
						AND ws.Weightometer_Sample_Shift = st.Shift
						AND ws.Weightometer_Sample_Date = pd.[Date]
				  ) >= @minimumSignificantTonnes
			 
			AND NOT EXISTS (
				SELECT TOP 1 1
				FROM dbo.WeightometerSample ws
				INNER JOIN dbo.WeightometerSampleNotes wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
				WHERE ws.Weightometer_Id = w.Weightometer_Id
					AND ws.Weightometer_Sample_Shift = st.Shift
					AND ws.Weightometer_Sample_Date = pd.[Date] 
					AND wsn.[Notes] IN ('CRUSHER ACTUALS', 'PORT ACTUALS', 'SHUTTLE', 'UNDILUTED RAKES')			
			)
			AND wdee.Weightometer_Id IS NULL
			AND wfp.Destination_Mill_Id IS NULL
			
			-- Get any existing data exceptions of that type during the specified range
			INSERT INTO @ExistingDataExceptions (DataExceptionId, Weightometer, [Date], Shift)
			SELECT DISTINCT de.Data_Exception_Id, de.Details_XML.value('(/DocumentElement/Missing_Samples/Weightometer_Id)[1]', 'nvarchar(31)'),
				   de.Data_Exception_Date, de.Data_Exception_Shift
			FROM dbo.DataException de	
			WHERE de.Data_Exception_Type_Id = @DataExceptionTypeId
				AND de.Data_Exception_Date >= @iDateFrom
				AND de.Data_Exception_Date <= @iDateTo	
			
			-- Clear existing data exceptions that are no longer valid	
			DELETE FROM dbo.DataException
			FROM (
				SELECT ede.DataExceptionId
				FROM @ExistingDataExceptions ede
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM @MissingSamples ms
					WHERE ms.Weightometer = ede.Weightometer
						AND ms.[Date] = ede.[Date]
						AND ms.Shift = ede.Shift
				)
			) ex
			WHERE ex.DataExceptionId = Data_Exception_Id
					
			-- Create the new data exceptions (if a matching data exception does not already exist)
			INSERT INTO dbo.DataException (Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, 
										   Data_Exception_Status_Id, Short_Description, Long_Description, Details_XML)
			SELECT @DataExceptionTypeId, ms.[Date], ms.Shift, 'A', 
				   'Missing sample information for weightometer ' + ms.Weightometer + ' on ' + 
						CAST(DATENAME(DAY, ms.[Date]) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, ms.[Date]) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, ms.[Date]) AS VARCHAR), 
				   'There are movements for weightometer ' + ms.Weightometer + ' on ' +
						CAST(DATENAME(DAY, ms.[Date]) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, ms.[Date]) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, ms.[Date]) AS VARCHAR) + 
						', however there are no available sample results on that day for that weightometer.',
				   '<DocumentElement><Missing_Samples><Weightometer_Id>' + ms.Weightometer + '</Weightometer_Id></Missing_Samples></DocumentElement>'
			FROM @MissingSamples ms
			WHERE NOT EXISTS (
				SELECT TOP 1 1
				FROM @ExistingDataExceptions ede
				WHERE ms.Weightometer = ede.Weightometer
					AND ms.[Date] = ede.[Date]
					AND ms.Shift = ede.Shift
			) 
					
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
GO 

GRANT EXECUTE ON dbo.UpdateBhpbioMissingSampleDataException TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioMissingSampleDataException">
 <Procedure>
	Inserts/Deletes Missing Sample Data Exceptions
 </Procedure>
</TAG>
*/

