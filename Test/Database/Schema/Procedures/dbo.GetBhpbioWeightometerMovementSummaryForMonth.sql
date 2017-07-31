If Exists (Select * From dbo.sysobjects Where id = object_id(N'dbo.GetBhpbioWeightometerMovementSummaryForMonth') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure dbo.GetBhpbioWeightometerMovementSummaryForMonth
Go
Create Procedure dbo.GetBhpbioWeightometerMovementSummaryForMonth
(
	@iMonth DateTime
)
With Encryption
As
Begin
	Set Nocount On
	
	Declare @TransactionCount Int
	Declare @TransactionName Varchar(32)
	
	Declare @SampleSourceField Varchar(31)
	Set @SampleSourceField = 'SampleSource'
	
	Declare @DateFrom date,
		@DateTo date,
		@LumpFinesCutoverDate date
	
	Select @TransactionName = 'GetBhpbioWeightometerMovementSummaryForMonth',
			@TransactionCount = @@TranCount

	Set @DateFrom = DATEADD(d, -DAY(@iMonth) + 1, @iMonth)
	Set @DateTo = DATEADD(d, -1, DATEADD(m, 1, @DateFrom))
	Set @LumpFinesCutoverDate = (SELECT CAST(Value AS date) FROM Setting WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE')

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	If @TransactionCount = 0
	Begin
		Set Transaction Isolation Level Repeatable Read
		Begin Transaction
	End
	Else
	Begin
		Save Transaction @TransactionName
	End
  
	DECLARE @weightometerData TABLE (
		Month DATETIME,
		WeightometerId VARCHAR(31),
		LocationId INT,
		LocationName VARCHAR(31),
		LocationType VARCHAR(31),
		ProductSize VARCHAR(31),
		Attribute VARCHAR(31),
		Value FLOAT,
		WeightingTonnes FLOAT
	)
  
	Begin Try
	
		IF (@DateFrom >= @LumpFinesCutoverDate)
		BEGIN
			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT @DateFrom AS Month, w.Weightometer_Id as WeightometerId, w.Location_Id as LocationId, l.Name as LocationName, lt.Description as LocationType,
				ISNULL(wsn.Notes, lfr.ProductSize) AS ProductSize, 'Tonnes' AS Attribute,
				SUM(ISNULL(ws.Tonnes * lfr.[Percent], ws.Tonnes)) AS Value,
				0.0 as WeightingTonnes
			FROM [dbo].[GetBhpbioWeightometerLocationWithOverride](@DateFrom, @DateTo) AS w
				INNER JOIN Location AS l
					ON w.Location_Id = l.Location_Id
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
				INNER JOIN WeightometerSample AS ws
					ON w.Weightometer_Id = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date BETWEEN w.IncludeStart AND w.IncludeEnd
				LEFT OUTER JOIN WeightometerSampleNotes AS wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					AND wsn.Notes IN ('LUMP', 'FINES')
				LEFT OUTER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) AS lfr
					ON w.Location_Id = lfr.LocationId
					AND @DateFrom BETWEEN lfr.StartDate AND lfr.EndDate
					AND wsn.Notes IS NULL
			GROUP BY w.Weightometer_Id, w.Location_Id, l.Name, lt.Description, ISNULL(wsn.Notes, lfr.ProductSize)

			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT @DateFrom AS Month, w.Weightometer_Id, w.Location_Id, l.Name, lt.Description,
				ISNULL(wsn.Notes, lfr.ProductSize) AS ProductSize, g.Grade_Name AS Attribute,
				CASE WHEN IsNull(SUM(ws.Tonnes * wsg.Grade_Value),0) = 0 
					THEN 0
					ELSE
						SUM(ws.Tonnes * IsNull(lfr.[Percent],1) * wsg.Grade_Value)
							/
						SUM(ws.Tonnes * IsNull(lfr.[Percent],1))
					END AS Value,
					SUM(ws.Tonnes * IsNull(lfr.[Percent],1)) As WeightingTonnes
			FROM [dbo].[GetBhpbioWeightometerLocationWithOverride](@DateFrom, @DateTo) AS w
				INNER JOIN Location AS l
					ON w.Location_Id = l.Location_Id
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
				INNER JOIN WeightometerSample AS ws
					ON w.Weightometer_Id = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date BETWEEN w.IncludeStart AND w.IncludeEnd
				LEFT OUTER JOIN WeightometerSampleNotes AS wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					AND wsn.Notes IN ('LUMP', 'FINES')
				LEFT OUTER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) AS lfr
					ON w.Location_Id = lfr.LocationId
					AND @DateFrom BETWEEN lfr.StartDate AND lfr.EndDate
					AND wsn.Notes IS NULL
				INNER JOIN dbo.WeightometerSampleNotes AS wsnss
					ON (wsnss.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						AND wsnss.Weightometer_Sample_Field_Id = @SampleSourceField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(1, @DateFrom, @DateTo, 0) AS ss
					ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
						AND ws.Weightometer_Id = ss.Weightometer_Id
						AND w.Location_Id = ss.LocationId
						AND wsnss.Notes = ss.SampleSource)
				INNER JOIN WeightometerSampleGrade AS wsg
					ON ws.Weightometer_Sample_Id = wsg.Weightometer_Sample_Id
				INNER JOIN Grade as g
					ON wsg.Grade_Id = g.Grade_Id
			GROUP BY w.Weightometer_Id, w.Location_Id, l.Name, lt.Description, ISNULL(wsn.Notes, lfr.ProductSize), g.Grade_Name

			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName,LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT Month, WeightometerId, LocationId, LocationName, LocationType, 'TOTAL' AS ProductSize, Attribute, SUM(Value),NULL
			FROM @weightometerData
			WHERE Attribute = 'TONNES'
			GROUP BY Month, WeightometerId, LocationId, LocationName, LocationType, Attribute

			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT Month, WeightometerId, LocationId, LocationName, LocationType, 'TOTAL' AS ProductSize, Attribute, SUM(Value * WeightingTonnes) / SUM(WeightingTonnes),NULL
			FROM @weightometerData
			WHERE Attribute <> 'TONNES'
			GROUP BY Month, WeightometerId, LocationId, LocationName, LocationType, Attribute
			
			SELECT Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value
			FROM @weightometerData
			ORDER BY WeightometerId, Attribute, ProductSize
		END
		ELSE
		BEGIN
			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT @DateFrom AS Month, w.Weightometer_Id as WeightometerId, w.Location_Id as LocationId, l.Name as LocationName, lt.Description as LocationType,
				'TOTAL' AS ProductSize, 'Tonnes' AS Attribute,
				SUM(ws.Tonnes) AS Value,
				0.0 as WeightingTonnes
			FROM [dbo].[GetBhpbioWeightometerLocationWithOverride](@DateFrom, @DateTo) AS w
				INNER JOIN Location AS l
					ON w.Location_Id = l.Location_Id
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
				INNER JOIN WeightometerSample AS ws
					ON w.Weightometer_Id = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date BETWEEN w.IncludeStart AND w.IncludeEnd
			GROUP BY w.Weightometer_Id, w.Location_Id, l.Name, lt.Description

			INSERT INTO @weightometerData(Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value, WeightingTonnes)
			SELECT @DateFrom AS Month, w.Weightometer_Id, w.Location_Id, l.Name, lt.Description,
				'TOTAL' AS ProductSize, g.Grade_Name AS Attribute,
				CASE WHEN IsNull(SUM(ws.Tonnes * wsg.Grade_Value),0) = 0 
					THEN 0
					ELSE
						SUM(ws.Tonnes * wsg.Grade_Value)
							/
						SUM(ws.Tonnes)
					END AS Value,
					SUM(ws.Tonnes) As WeightingTonnes
			FROM [dbo].[GetBhpbioWeightometerLocationWithOverride](@DateFrom, @DateTo) AS w
				INNER JOIN Location AS l
					ON w.Location_Id = l.Location_Id
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
				INNER JOIN WeightometerSample AS ws
					ON w.Weightometer_Id = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date BETWEEN w.IncludeStart AND w.IncludeEnd
				LEFT OUTER JOIN WeightometerSampleNotes AS wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					AND wsn.Notes IN ('LUMP', 'FINES')
				INNER JOIN dbo.WeightometerSampleNotes AS wsnss
					ON (wsnss.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						AND wsnss.Weightometer_Sample_Field_Id = @SampleSourceField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(1, @DateFrom, @DateTo, 0) AS ss
					ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
						AND ws.Weightometer_Id = ss.Weightometer_Id
						AND w.Location_Id = ss.LocationId
						AND wsnss.Notes = ss.SampleSource)
				INNER JOIN WeightometerSampleGrade AS wsg
					ON ws.Weightometer_Sample_Id = wsg.Weightometer_Sample_Id
				INNER JOIN Grade as g
					ON wsg.Grade_Id = g.Grade_Id
			GROUP BY w.Weightometer_Id, w.Location_Id, l.Name, lt.Description, g.Grade_Name

			SELECT Month, WeightometerId, LocationId, LocationName, LocationType, ProductSize, Attribute, Value
			FROM @weightometerData
			ORDER BY WeightometerId, Attribute, ProductSize
		END
		
		-- if we started a new transaction that is still valid then commit the changes
		If (@TransactionCount = 0) And (XAct_State() = 1)
		Begin
			Commit Transaction
		End
	End Try
	Begin Catch
		-- if we started a transaction then roll it back
		If (@TransactionCount = 0)
		Begin
			Rollback Transaction
		End
		-- if we are part of an existing transaction and 
		Else If (XAct_State() = 1) And (@TransactionCount > 0)
		Begin
			Rollback Transaction @TransactionName
		End

		Exec dbo.StandardCatchBlock
	End Catch
End
Go

Grant Execute On dbo.GetBhpbioWeightometerMovementSummaryForMonth To BhpbioGenericManager
Go
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioWeightometerMovementSummaryForMonth">
 <Procedure>
 </Procedure>
</TAG>
*/