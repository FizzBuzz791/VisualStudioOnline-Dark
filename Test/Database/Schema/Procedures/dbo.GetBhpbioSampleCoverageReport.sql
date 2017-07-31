IF Object_Id('dbo.GetBhpbioSampleCoverageReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioSampleCoverageReport
GO

CREATE PROCEDURE dbo.GetBhpbioSampleCoverageReport
(
	@iLocationId INT,
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iGroupBy VARCHAR(10) = 'Crusher'
)
AS
BEGIN

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @CrusherResults TABLE
	(
		CrusherId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		WeightometerId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		TotalTonnes FLOAT,
		SampleTonnes FLOAT,
		TotalNoOfDays FLOAT,
		NoOfDaysSampled FLOAT
	)
	
	DECLARE @DateResults TABLE
	(
		DayDate DATETIME,
		TotalTonnes FLOAT,
		SampleTonnes FLOAT,
		TotalNoOfDays FLOAT,
		NoOfDaysSampled FLOAT
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioRecoveryAnalysisReport',
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
	
			-- ensure the Total is the first record
			Insert Into @CrusherResults (CrusherId, WeightometerId)
			Select 'Total', 'Total'

			-- get the list of active crushers and the corresponding weightometers for the selected location and date range
			Insert Into @CrusherResults (CrusherId, WeightometerId)
			Select Distinct c.Crusher_Id, wfp.Weightometer_Id
			From dbo.Crusher c
				Inner Join dbo.CrusherLocation cl
					On c.Crusher_Id = cl.Crusher_Id
				Inner Join dbo.WeightometerFlowPeriod wfp
					On (wfp.Source_Crusher_Id = c.Crusher_id
						Or wfp.Destination_Crusher_Id = c.Crusher_id)
			Where cl.Location_Id In
			(
				Select LocationId
				From dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'Site', @iDateFrom, @iDateTo) --get all child locations including the location itself
			)
				And (wfp.End_Date Is Null Or wfp.End_Date <= @iDateFrom) --ensure crusher is active
			
			-- work out tonnes percentage
			If @iGroupBy = 'Crusher'
			Begin
				Update r
				Set r.TotalTonnes = aggr.Tonnes
				From @CrusherResults r
					Inner Join
					(
						Select ws.Weightometer_Id, Sum(ws.Tonnes) As Tonnes
						From @CrusherResults r
							Inner Join dbo.WeightometerSample ws
								On r.WeightometerId = ws.Weightometer_Id
						Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
						Group By ws.Weightometer_Id
					) As aggr
						On r.WeightometerId = aggr.Weightometer_Id
						
				Update r
				Set r.SampleTonnes = aggr.Tonnes
				From @CrusherResults r
					Inner Join
					(
						Select ws.Weightometer_Id, Sum(ws.Tonnes) As Tonnes
						From @CrusherResults r
							Inner Join dbo.WeightometerSample ws
								On r.WeightometerId = ws.Weightometer_Id
							Inner Join dbo.WeightometerSampleNotes wsn
								On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
									And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
									And wsn.Notes = 'CRUSHER ACTUALS')
						Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
						Group By ws.Weightometer_Id
					) As aggr
						On r.WeightometerId = aggr.Weightometer_Id
			End
			Else If @iGroupBy = 'Day'
			Begin
				Insert Into @DateResults (DayDate, TotalTonnes)
				Select ws.Weightometer_Sample_Date, Sum(ws.Tonnes)
				From @CrusherResults r
					Inner Join dbo.WeightometerSample ws
						On r.WeightometerId = ws.Weightometer_Id
				Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
				Group By ws.Weightometer_Sample_Date
				
				Update r
				Set r.SampleTonnes = aggr.Tonnes
				From @DateResults r
					Inner Join
					(
						Select ws.Weightometer_Sample_Date, Sum(ws.Tonnes) As Tonnes
						From @CrusherResults r
							Inner Join dbo.WeightometerSample ws
								On r.WeightometerId = ws.Weightometer_Id
							Inner Join dbo.WeightometerSampleNotes wsn
								On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
									And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
									And wsn.Notes = 'CRUSHER ACTUALS')
						Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
						Group By ws.Weightometer_Sample_Date
					) As aggr
						On r.DayDate = aggr.Weightometer_Sample_Date
			End
			
			-- now the Total
			Update r
			Set r.TotalTonnes = aggr.Tonnes
			From @CrusherResults r
				Inner Join
				(
					Select Sum(ws.Tonnes) As Tonnes
					From @CrusherResults r
						Inner Join dbo.WeightometerSample ws
							On r.WeightometerId = ws.Weightometer_Id
					Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
				) As aggr
					On r.WeightometerId = 'Total'
			
			Update r
			Set r.SampleTonnes = aggr.Tonnes
			From @CrusherResults r
				Inner Join
				(
					Select Sum(ws.Tonnes) As Tonnes
					From @CrusherResults r
						Inner Join dbo.WeightometerSample ws
							On r.WeightometerId = ws.Weightometer_Id
						Inner Join dbo.WeightometerSampleNotes wsn
							On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
								And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
								And wsn.Notes = 'CRUSHER ACTUALS')
					Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
				) As aggr
					On r.WeightometerId = 'Total'
			
			
			-- work out days percentage
			If @iGroupBy = 'Crusher'
			Begin
				Update @CrusherResults
				Set TotalNoOfDays = Cast(DateDiff(Day, @iDateFrom, @iDateTo) As Float) + 1.0
				
				Update r
				Set r.NoOfDaysSampled = aggr.NoOfDaysSampled
				From @CrusherResults r
					Inner Join
					(
						Select WeightometerId, Sum(HasSample) As NoOfDaysSampled
						From
						(
							Select ws.Weightometer_Sample_Date, ws.Weightometer_Id As WeightometerId,
							Case When Max(wsn.Notes) Is Not Null
								Then 1.0
								Else 0.0
							End As HasSample
							From @CrusherResults r
								Inner Join dbo.WeightometerSample ws
									On r.WeightometerId = ws.Weightometer_Id
								Left Outer Join dbo.WeightometerSampleNotes wsn
									On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
										And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
										And wsn.Notes = 'CRUSHER ACTUALS')
							Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
							Group By ws.Weightometer_Sample_Date, ws.Weightometer_Id
						) As a
						Group By WeightometerId
					) As aggr
						On r.WeightometerId = aggr.WeightometerId
						
				Update r
				Set r.NoOfDaysSampled = aggr.NoOfDaysSampled
				From @CrusherResults r
					Inner Join
					(
						Select Sum(HasSample) As NoOfDaysSampled
						From
						(
							Select ws.Weightometer_Sample_Date,
							Case When Max(wsn.Notes) Is Not Null
								Then 1.0
								Else 0.0
							End As HasSample
							From @CrusherResults r
								Inner Join dbo.WeightometerSample ws
									On r.WeightometerId = ws.Weightometer_Id
								Left Outer Join dbo.WeightometerSampleNotes wsn
									On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
										And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
										And wsn.Notes = 'CRUSHER ACTUALS')
							Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
							Group By ws.Weightometer_Sample_Date
						) As a
					) As aggr
						On r.WeightometerId = 'Total'
			End
			Else If @iGroupBy = 'Day'
			Begin
				Update @DateResults
				Set TotalNoOfDays = Cast(DateDiff(Day, @iDateFrom, @iDateTo) As Float) + 1.0
				
				Update r
				Set r.NoOfDaysSampled = aggr.HasSample
				From @DateResults r
					Inner Join
					(
						Select ws.Weightometer_Sample_Date,
						Case When Max(wsn.Notes) Is Not Null
							Then 1.0
							Else 0.0
						End As HasSample
						From @CrusherResults r
							Inner Join dbo.WeightometerSample ws
								On r.WeightometerId = ws.Weightometer_Id
							Left Outer Join dbo.WeightometerSampleNotes wsn
								On (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
									And wsn.Weightometer_Sample_Field_Id = 'SampleSource'
									And wsn.Notes = 'CRUSHER ACTUALS')
						Where ws.Weightometer_Sample_Date Between @iDateFrom And @iDateTo
						Group By ws.Weightometer_Sample_Date
					) As aggr
						On r.DayDate = aggr.Weightometer_Sample_Date
			End
			
			
			-- return results
			If @iGroupBy = 'Crusher'
			Begin
				Select CrusherId,
					WeightometerId, 
					Case When SampleTonnes / TotalTonnes Is Null
						Then 0
						Else (SampleTonnes / TotalTonnes) * 100
					End As CoveragePercentageTonnes,
					Case When NoOfDaysSampled / TotalNoOfDays Is Null
						Then 0
						Else (NoOfDaysSampled / TotalNoOfDays) * 100
					End As CoveragePercentageDays
				From @CrusherResults
			End
			Else If @iGroupBy = 'Day'
			Begin
				Select DayDate,
					Case When SampleTonnes / TotalTonnes Is Null
						Then 0
						Else (SampleTonnes / TotalTonnes) * 100
					End As CoveragePercentageTonnes,
					NoOfDaysSampled As CoveragePercentageDays -- this is because in a day either there's a sample, or there's nothing
				From @DateResults
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

GRANT EXECUTE ON dbo.GetBhpbioSampleCoverageReport TO BhpbioGenericManager
GO
