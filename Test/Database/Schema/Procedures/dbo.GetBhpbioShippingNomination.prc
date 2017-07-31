IF OBJECT_ID('dbo.GetBhpbioShippingNomination') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioShippingNomination  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioShippingNomination 
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

	SELECT @TransactionName = 'GetBhpbioShippingNomination',
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
	
		--For Grade Pivoting
		CREATE TABLE dbo.#ShippingTransactionGrade
		(
			BhpbioShippingNominationItemParcelId INT NOT NULL,
			GradeName  VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			GradeValue Real Null,
			
			PRIMARY KEY (BhpbioShippingNominationItemParcelId, GradeName)
		)
		
		--Main Result SET
		CREATE TABLE dbo.#ShippingTransaction
		(
			BhpbioShippingNominationItemParcelId INT  NOT NULL,
			BhpbioShippingNominationItemId INT NOT NULL,
			NominationKey INT  NULL,
			VesselName VARCHAR(63) COLLATE DATABASE_DEFAULT  NULL,
			Nomination INT  NULL,
			DateOrder DATETIME NULL,
			OfficialFinishTime DATETIME NULL,
			LastAuthorisedDate DATETIME NULL,
			CustomerNo INT NULL,
			CustomerName VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
			ProductCode VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
			ProductSize VARCHAR(5) NULL,
			COA DATETIME NULL,
			Undersize FLOAT NULL,
			Oversize FLOAT NULL,
			HubLocationId FLOAT NULL,
			HubLocationName VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
			Tonnes FLOAT NULL,
			NoParcels INT NULL,
			PRIMARY KEY (BhpbioShippingNominationItemParcelId, BhpbioShippingNominationItemId)
		)


		INSERT INTO dbo.#ShippingTransaction
		(
			BhpbioShippingNominationItemParcelId, BhpbioShippingNominationItemId,
			NominationKey, VesselName, Nomination, DateOrder, OfficialFinishTime, LastAuthorisedDate,
			CustomerNo,	CustomerName, ProductCode, ProductSize,
			COA, Undersize, Oversize, HubLocationId, HubLocationName, Tonnes 
		)
		SELECT stnp.BhpbioShippingNominationItemParcelId, stn.BhpbioShippingNominationItemId, 
			stn.NominationKey, st.VesselName, stn.ItemNo, stn.OfficialFinishTime, stn.OfficialFinishTime, stn.LastAuthorisedDate, 
			stn.CustomerNo, stn.CustomerName, stn.ShippedProduct, stn.ShippedProductSize,
			stn.COA, stn.Undersize, stn.Oversize, stnp.HubLocationId, L.Name AS HubLocationName, stnp.Tonnes
		FROM dbo.BhpbioShippingNomination AS st
			INNER JOIN dbo.BhpbioShippingNominationItem AS stn
				ON (st.NominationKey = stn.NominationKey)
			INNER JOIN dbo.BhpbioShippingNominationItemParcel AS stnp
				ON (stn.BhpbioShippingNominationItemId = stnp.BhpbioShippingNominationItemId)
			INNER JOIN dbo.Location AS l
				ON (stnp.HubLocationId = l.Location_Id)
		WHERE stn.OfficialFinishTime >= ISNULL(@iDateFrom, stn.OfficialFinishTime)
			AND stn.OfficialFinishTime <= ISNULL(DateAdd(millisecond, -1, dateadd(day, 1, @iDateTo)), stn.OfficialFinishTime)
			AND stnp.HubLocationId IN
				(
					SELECT rl.LocationId
					FROM dbo.GetBhpbioReportLocation(@iLocationId) AS rl
				)
									
		UPDATE st
		SET NoParcels = RS1.NoParcels
		FROM
			(
				SELECT BhpbioShippingNominationItemId, COUNT(BhpbioShippingNominationItemId) as NoParcels
				FROM dbo.#ShippingTransaction
				GROUP BY BhpbioShippingNominationItemId
			)AS RS1
			INNER JOIN #ShippingTransaction AS st
				ON st.BhpbioShippingNominationItemId = RS1.BhpbioShippingNominationItemId
		

		INSERT INTO #ShippingTransaction
		(
			BhpbioShippingNominationItemParcelId, BhpbioShippingNominationItemId,
			NominationKey, VesselName, Nomination, DateOrder, OfficialFinishTime, LastAuthorisedDate,
			CustomerNo,	CustomerName, ProductCode, ProductSize,
			COA, Undersize, Oversize, HubLocationId, HubLocationName, Tonnes, NoParcels 
		)
		SELECT -1 As BhpbioShippingNominationItemParcelId, BhpbioShippingNominationItemId,
			NominationKey, VesselName, Nomination, DateOrder, OfficialFinishTime, LastAuthorisedDate,
			CustomerNo,	CustomerName, ProductCode, ProductSize,
			COA, Undersize, Oversize, NULL, NULL, NULL, -1
		FROM dbo.#ShippingTransaction
		WHERE NoParcels > 1
		GROUP BY BhpbioShippingNominationItemId,
			NominationKey, VesselName, Nomination, OfficialFinishTime, DateOrder, LastAuthorisedDate,
			CustomerNo,	CustomerName, ProductCode, ProductSize,
			COA, Undersize, Oversize
		

		INSERT INTO dbo.#ShippingTransactionGrade
		(
			BhpbioShippingNominationItemParcelId, GradeName, GradeValue
		)
		SELECT t.BhpbioShippingNominationItemParcelId, g.Grade_Name, stng.GradeValue
		FROM dbo.BhpbioShippingNominationItemParcelGrade AS stng
			INNER JOIN dbo.#ShippingTransaction AS t
				ON (stng.BhpbioShippingNominationItemParcelId = t.BhpbioShippingNominationItemParcelId)
			INNER JOIN dbo.Grade AS g
				ON stng.GradeId = g.Grade_Id
		UNION ALL	
		--Dummy Grade Values Ensure All Grade are Pivoted
		SELECT -1 AS BhpbioShippingNominationItemParcelId, G.Grade_Name, Null AS Grade_Value
		FROM dbo.Grade AS G
		WHERE G.Is_Visible = 1 

	
		--Pivot Grades Onto Main table
		EXEC dbo.PivotTable
			@iTargetTable='#ShippingTransaction',
			@iPivotTable='#ShippingTransactionGrade',
			@iJoinColumns='#ShippingTransaction.BhpbioShippingNominationItemParcelId = #ShippingTransactionGrade.BhpbioShippingNominationItemParcelId',
			@iPivotColumn='GradeName',
			@iPivotValue='GradeValue',
			@iPivotType='REAL'		

		-- Output shipping information
		UPDATE st
		SET Tonnes = RS1.Tonnes,
			Al2O3 = RS1.Al2O3,
			Fe = RS1.Fe,
			LOI = RS1.LOI,
			P = RS1.P,
			SiO2 = RS1.SiO2,
			H2O = RS1.H2O
		FROM (
			SELECT BhpbioShippingNominationItemId,
				SUM(Tonnes) AS TONNES,
				SUM(TONNES * Al2O3) /SUM(TONNES) As Al2O3,
				SUM(TONNES * Fe) /SUM(TONNES) As Fe,
				SUM(TONNES * LOI) /SUM(TONNES) As LOI,
				SUM(TONNES * P) /SUM(TONNES) As P,
				SUM(TONNES * SiO2) /SUM(TONNES) As SiO2,
				SUM(TONNES * H2O) /SUM(TONNES) As H2O
			FROM dbo.#ShippingTransaction
			WHERE NoParcels > 1
			GROUP BY BhpbioShippingNominationItemId
		) AS RS1
			INNER JOIN dbo.#ShippingTransaction AS st
				ON st.BhpbioShippingNominationItemId = RS1.BhpbioShippingNominationItemId
		WHERE st.NoParcels = -1
		
		UPDATE #ShippingTransaction
		SET NominationKey = NULL, 
			VesselName = NULL, 
			Nomination = NULL, 
			OfficialFinishTime = NULL, 
			LastAuthorisedDate = NULL,
			CustomerNo = NULL,	
			CustomerName = NULL, 
			ProductCode = NULL, 
			ProductSize = NULL,
			COA = NULL,
			Undersize = NULL, 
			Oversize = NULL
		WHERE NoParcels > 1		
			
		SELECT BhpbioShippingNominationItemParcelId, BhpbioShippingNominationItemId,
			NominationKey, VesselName, Nomination, 
			OfficialFinishTime, DateOrder, LastAuthorisedDate,
			CustomerNo,	CustomerName, ProductCode, ProductSize,
			COA, Undersize, Oversize, HubLocationId, HubLocationName, 
			Tonnes, Al2O3, Fe, LOI, P, SiO2, H2O
		FROM dbo.#ShippingTransaction
		ORDER BY DateOrder, BhpbioShippingNominationItemId,  BhpbioShippingNominationItemParcelId

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

GRANT EXECUTE ON dbo.GetBhpbioShippingNomination TO BhpbioGenericManager
GO
					
/*
testing

EXEC dbo.GetBhpbioShippingNomination
	@iDateFrom = NULL,
	@iDateTo = NULL,
	@iLocationId = NULL
*/
