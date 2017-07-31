IF OBJECT_ID('dbo.GetBhpbioPortBlending') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioPortBlending  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioPortBlending 
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

	SELECT @TransactionName = 'GetBhpbioPortBlending',
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
		-- create a temporary table with the port blending information
		SELECT bpb.BhpbioPortBlendingId, bpb.SourceHubLocationId, bpb.DestinationHubLocationId,
			bpb.SourceProductSize, bpb.DestinationProductSize, bpb.SourceProduct, bpb.DestinationProduct,
			bpb.StartDate, bpb.EndDate, bpb.LoadSiteLocationId, bpb.Tonnes,
			l2.Name AS DestinationHubLocationName, l3.Name As SourceHubLocationName, l4.Name As LoadSiteLocationName
		INTO dbo.#PortBlending
		FROM dbo.BhpbioPortBlending AS bpb
			INNER JOIN dbo.Location AS l2
				ON (bpb.DestinationHubLocationId = l2.Location_Id)
			INNER JOIN dbo.Location AS l3
				ON (bpb.SourceHubLocationId = l3.Location_Id)
			INNER JOIN dbo.Location AS l4
				ON (bpb.LoadSiteLocationId = l4.Location_Id)
		WHERE bpb.EndDate >= ISNULL(@iDateFrom, bpb.EndDate)
			AND bpb.StartDate <= ISNULL(@iDateTo, bpb.StartDate)
			AND EXISTS
				(
					SELECT 1
					FROM dbo.GetBhpbioReportLocation(@iLocationId) AS rl
					WHERE rl.LocationId = bpb.DestinationHubLocationId
				)

		-- create a temporary table with the port blending grades
		SELECT pbg.BhpbioPortBlendingId, pbg.GradeId, pbg.GradeValue
		INTO dbo.#PortBlendingGrade
		FROM dbo.BhpbioPortBlendingGrade AS pbg
			INNER JOIN dbo.#PortBlending AS pb
				ON (pbg.BhpbioPortBlendingId = pb.BhpbioPortBlendingId)

		-- output port blending information
		SELECT BhpbioPortBlendingId, SourceHubLocationId, DestinationHubLocationId,
			StartDate, EndDate, SourceProductSize, DestinationProductSize, SourceProduct, DestinationProduct,
			LoadSiteLocationId, Tonnes, 
			DestinationHubLocationName, SourceHubLocationName, LoadSiteLocationName
		FROM dbo.#PortBlending

		SELECT BhpbioPortBlendingId, GradeId, GradeValue
		FROM dbo.#PortBlendingGrade

		SELECT Grade_Id AS GradeId, Grade_Name AS GradeName, Order_No AS OrderNo
		FROM dbo.Grade

		-- Clean up temporary tables
		DROP TABLE dbo.#PortBlendingGrade
		DROP TABLE dbo.#PortBlending
		
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

GRANT EXECUTE ON dbo.GetBhpbioPortBlending TO BhpbioGenericManager
GO
