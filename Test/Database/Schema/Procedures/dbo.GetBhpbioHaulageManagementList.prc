IF OBJECT_ID('dbo.GetBhpbioHaulageManagementList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioHaulageManagementList
GO 

CREATE PROCEDURE dbo.GetBhpbioHaulageManagementList
(
	@iFilter_Start_Date Datetime,
	@iFilter_Start_Shift Char(1) = Null,
	@iFilter_End_Date Datetime,
	@iFilter_End_Shift Char(1) = Null,
	@iFilter_Source Varchar(63) = Null,
	@iFilter_Destination Varchar(63) = Null,
	@iFilter_Truck Varchar(31) = Null,
	@iShowHaulageWithApprovedChild Bit = 1,
	@iTop Bit = 0,
	@iRecordLimit Int = Null,
	@iLocation_Id Int = Null,
	@oCountRecords Int = Null Output,
	@oCountSourceStockpile Int = Null Output,
	@oCountSourceDigblock Int = Null Output,
	@oCountSourceMill Int = Null Output,
	@oCountDestinationStockpile Int = Null Output,
	@oCountDestinationCrusher Int = Null Output,
	@oCountDestinationMill Int = Null Output,
	@oSumTonnes Float = Null Output
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioHaulageManagementList',
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
		-- Get Start and End shifts are null, default them to the min and max shifts respectivly.
		If @iFilter_Start_Shift Is Null And @iFilter_End_Shift Is Null
		Begin
			SET @iFilter_Start_Shift = dbo.GetFirstShiftType()
			SET @iFilter_End_Shift = dbo.GetLastShiftType()
		End
		
		-- return summary statistics
		Select @oCountRecords = Count(h.Haulage_Id),
			@oCountSourceStockpile = Coalesce(Sum(Case When h.Source_Stockpile_Id Is Null Then 0 Else 1 End),0),
			@oCountSourceDigblock = Coalesce(Sum(Case When h.Source_Digblock_Id Is Null Then 0 Else 1 End),0),
			@oCountSourceMill = Coalesce(Sum(Case When h.Source_Mill_Id Is Null Then 0 Else 1 End),0),
			@oCountDestinationStockpile = Coalesce(Sum(Case When h.Destination_Stockpile_Id Is Null Then 0 Else 1 End),0),
			@oCountDestinationCrusher = Coalesce(Sum(Case When h.Destination_Crusher_Id Is Null Then 0 Else 1 End),0),
			@oCountDestinationMill = Coalesce(Sum(Case When h.Destination_Mill_Id Is Null Then 0 Else 1 End),0),
			@oSumTonnes = Coalesce(Sum(h.Tonnes), 0.0)
		From dbo.Haulage As h
			Left Join dbo.Stockpile As ss
				On (ss.Stockpile_Id = h.Source_Stockpile_Id)
			Left Join Stockpile As DS
				On (ds.Stockpile_Id = h.Destination_Stockpile_Id)
			Left Join dbo.DigblockLocation as dl
				on (h.Source_Digblock_Id = dl.Digblock_Id)
			Left Join dbo.StockpileLocation as sl
				on (h.Source_Stockpile_Id = sl.Stockpile_Id)
			Left Join dbo.MillLocation as ml
				on (h.source_mill_id = ml.mill_id)
			Left Join dbo.CrusherLocation As cl
				On (h.Destination_Crusher_Id = cl.Crusher_Id)
			Left Join dbo.StockpileLocation As dsl
				On (h.Destination_Stockpile_Id = dsl.Stockpile_Id)
			Left Join dbo.MillLocation as dml
				On (h.Destination_Mill_Id = dml.Mill_Id)
		Where (Coalesce(H.Source_Digblock_Id, Cast(H.Source_Stockpile_Id As Varchar), H.Source_Mill_Id) = @iFilter_Source Or @iFilter_Source Is Null)
			And (Coalesce(H.Destination_Crusher_Id, Cast(H.Destination_Stockpile_Id As Varchar), H.Destination_Mill_Id) = @iFilter_Destination Or @iFilter_Destination Is Null)
			And (Truck_Id = @iFilter_Truck Or @iFilter_Truck Is Null)
			And Haulage_State_Id = 'N'
			And (Child_Haulage_Id Is Null And @iShowHaulageWithApprovedChild = 0 Or @iShowHaulageWithApprovedChild = 1)
			And Haulage_Date BETWEEN @iFilter_Start_Date AND @iFilter_End_Date
			And (dbo.CompareDateShift(Haulage_Date, Haulage_Shift, '>=', @iFilter_Start_Date, @iFilter_Start_Shift) = 1)
			And (dbo.CompareDateShift(Haulage_Date, Haulage_Shift, '<=', @iFilter_End_Date, @iFilter_End_Shift) = 1)
			AND EXISTS
				(
					SELECT top 1 1
					FROM dbo.GetLocationSubtree(@iLocation_Id) AS l2
					WHERE l2.Location_Id = dl.Location_Id
						OR l2.Location_Id = sl.Location_Id
						OR l2.Location_Id = ml.Location_Id
						OR l2.Location_Id = cl.Location_Id
						OR l2.Location_Id = dsl.Location_Id
						OR l2.Location_Id = dml.Location_Id
				)
		
		-- return actual haulage records
		Select H.Haulage_Id, H.Haulage_Date, dbo.GetShiftTypeName(H.Haulage_Shift) AS Haulage_Shift_Str, 
			Coalesce(H.Source_Digblock_Id, SS.Stockpile_Name, H.Source_Mill_Id) AS Source,
			Coalesce(DS.Stockpile_Name, H.Destination_Crusher_Id, H.Destination_Mill_Id) AS Destination,
			h.Truck_Id AS Truck, h.Tonnes,
			Case When H.Haulage_State_Id = 'N' And H.Child_Haulage_Id Is Null Then 1 Else 0 End As Editable,
			hr.Destination AS OriginalDestination,
			h.Loads
		INTO dbo.#Result
		From dbo.Haulage As h
			INNER JOIN dbo.HaulageRaw AS hr
				ON (h.Haulage_Raw_Id = hr.Haulage_Raw_Id)
			Left Join Stockpile As SS
				On SS.Stockpile_Id = H.Source_Stockpile_Id
			Left Join Stockpile As DS
				On DS.Stockpile_Id = H.Destination_Stockpile_Id
			Left Join dbo.digblocklocation As dl
				On h.source_digblock_id = dl.digblock_id
			Left Join dbo.stockpilelocation As sl
				On h.source_stockpile_id = sl.stockpile_id
			Left Join dbo.milllocation As ml
				On h.source_mill_id = ml.mill_id
			Left Join dbo.crusherlocation As cl
				On h.destination_crusher_id = cl.crusher_id
			Left Join dbo.stockpilelocation As dsl
				On h.destination_stockpile_id = dsl.stockpile_id
			Left Join dbo.milllocation as dml
				on h.destination_mill_id = dml.mill_id
		Where (Coalesce(H.Source_Digblock_Id, Cast(H.Source_Stockpile_Id As Varchar), H.Source_Mill_Id) = @iFilter_Source Or @iFilter_Source Is Null)
			And (Coalesce(H.Destination_Crusher_Id, Cast(H.Destination_Stockpile_Id As Varchar), H.Destination_Mill_Id) = @iFilter_Destination Or @iFilter_Destination Is Null)
			And (h.Truck_Id = @iFilter_Truck Or @iFilter_Truck Is Null)
			And h.Haulage_State_Id = 'N'
			And (h.Child_Haulage_Id Is Null And @iShowHaulageWithApprovedChild = 0 Or @iShowHaulageWithApprovedChild = 1)
			And h.Haulage_Date BETWEEN @iFilter_Start_Date AND @iFilter_End_Date
			And (dbo.CompareDateShift(h.Haulage_Date, h.Haulage_Shift, '>=', @iFilter_Start_Date, @iFilter_Start_Shift) = 1)
			And (dbo.CompareDateShift(h.Haulage_Date, h.Haulage_Shift, '<=', @iFilter_End_Date, @iFilter_End_Shift) = 1)
			AND EXISTS
				(
					SELECT TOP 1 1
					FROM dbo.GetLocationSubtree(@iLocation_Id) AS l2
					WHERE l2.Location_Id = dl.Location_Id
						OR l2.Location_Id = sl.Location_Id
						OR l2.Location_Id = ml.Location_Id
						OR l2.Location_Id = cl.Location_Id
						OR l2.Location_Id = dsl.Location_Id
						OR l2.Location_Id = dml.Location_Id
				)
		Order by H.Haulage_Date Desc, dbo.GetShiftTypeOrderNo(H.Haulage_Shift) Desc, Source, Destination, OriginalDestination

		IF @iRecordLimit IS NULL
		BEGIN
			SELECT *
			FROM dbo.#Result
		END
		ELSE
		BEGIN
			SELECT TOP (@iRecordLimit) *
			FROM dbo.#Result
		END

		DROP TABLE dbo.#Result

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

GRANT EXECUTE ON dbo.GetBhpbioHaulageManagementList TO BhpbioGenericManager
GO

/*
DECLARE
	@CountRecords Int,
	@CountSourceStockpile Int,
	@CountSourceDigblock Int,
	@CountSourceMill Int,
	@CountDestinationStockpile Int,
	@CountDestinationCrusher Int,
	@CountDestinationMill Int,
	@SumTonnes Float

EXEC dbo.GetBhpbioHaulageManagementList
	@iFilter_Start_Date = '01-APR-2008',
	@iFilter_Start_Shift = 'D',
	@iFilter_End_Date = '10-DEC-2008',
	@iFilter_End_Shift = 'D',
	@iFilter_Source = NULL,
	@iFilter_Destination = Null,
	@iFilter_Truck = Null,
	@iShowHaulageWithApprovedChild = 1,
	@iTop = 0,
	@iRecordLimit = NULL,
	@iLocation_Id = 1,
	@oCountRecords = @CountRecords OUTPUT,
	@oCountSourceStockpile = @CountSourceStockpile OUTPUT,
	@oCountSourceDigblock = @CountSourceDigblock OUTPUT,
	@oCountSourceMill = @CountSourceMill OUTPUT,
	@oCountDestinationStockpile = @CountDestinationStockpile OUTPUT,
	@oCountDestinationCrusher = @CountDestinationCrusher OUTPUT,
	@oCountDestinationMill = @CountDestinationMill OUTPUT,
	@oSumTonnes = @SumTonnes OUTPUT

SELECT @CountRecords, @CountSourceStockpile, @CountSourceDigblock, @CountSourceMill,
	@CountDestinationStockpile, @CountDestinationCrusher, @CountDestinationMill, @SumTonnes

*/

