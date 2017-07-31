IF OBJECT_ID('dbo.GetBhpbioShippingTransaction') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioShippingTransaction  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioShippingTransaction 
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioShippingTransaction',
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
		-- create a temporary table with the shipping transaction information
		SELECT stn.BhpbioShippingTransactionNominationId, stn.NominationKey, stn.Nomination, stn.OfficialFinishTime,
			stn.LastAuthorisedDate, stn.CustomerNo, stn.CustomerName, stn.HubLocationId, stn.ProductCode,
			stn.Tonnes, st.VesselName, L.Name AS HubLocationName,
			stn.COA, stn.H2O, stn.Undersize, stn.Oversize
		INTO dbo.#ShippingTransaction
		FROM dbo.BhpbioShippingTransaction AS st
			INNER JOIN dbo.BhpbioShippingTransactionNomination AS stn
				ON (st.NominationKey = stn.NominationKey)
			INNER JOIN dbo.Location AS l
				ON (stn.HubLocationId = l.Location_Id)
		WHERE stn.OfficialFinishTime >= ISNULL(@iDateFrom, stn.OfficialFinishTime)
			AND stn.OfficialFinishTime <= ISNULL(DateAdd(millisecond, -1, dateadd(day, 1, @iDateTo)), stn.OfficialFinishTime)
			AND stn.HubLocationId IN
				(
					SELECT rl.LocationId
					FROM dbo.GetBhpbioReportLocation(@iLocationId) AS rl
				)

		-- create a temporary table with the shipping transaction grades
		SELECT t.BhpbioShippingTransactionNominationId, stng.GradeId, stng.GradeValue
		INTO dbo.#ShippingTransactionGrade
		FROM dbo.BhpbioShippingTransactionNominationGrade AS stng
			INNER JOIN dbo.#ShippingTransaction AS t
				ON (stng.BhpbioShippingTransactionNominationId = t.BhpbioShippingTransactionNominationId)

		-- Output shipping information
		SELECT BhpbioShippingTransactionNominationId, NominationKey, Nomination,
			OfficialFinishTime, LastAuthorisedDate, CustomerNo, CustomerName, HubLocationId, ProductCode,
			Tonnes, VesselName, HubLocationName, COA, H2O, Undersize, Oversize
		FROM dbo.#ShippingTransaction

		SELECT BhpbioShippingTransactionNominationId, GradeId, GradeValue
		FROM dbo.#ShippingTransactionGrade

		SELECT Grade_Id AS GradeId, Grade_Name AS GradeName, Order_No AS OrderNo
		FROM dbo.Grade

		-- Clean up temporary tables
		DROP TABLE dbo.#ShippingTransaction
		DROP TABLE dbo.#ShippingTransactionGrade
		
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

GRANT EXECUTE ON dbo.GetBhpbioShippingTransaction TO BhpbioGenericManager
GO
					
/*
testing

EXEC dbo.GetBhpbioShippingTransaction
	@iDateFrom = NULL,
	@iDateTo = NULL,
	@iLocationId = NULL
*/
