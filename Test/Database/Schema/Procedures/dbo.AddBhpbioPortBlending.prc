IF OBJECT_ID('dbo.AddBhpbioPortBlending') IS NOT NULL
    DROP PROCEDURE dbo.AddBhpbioPortBlending
GO 
  
CREATE PROCEDURE dbo.AddBhpbioPortBlending
(
	@iSourceHubLocationId INT,
    @iDestinationHubLocationId INT,
    @iStartDate DATETIME,
    @iEndDate DATETIME,
    @iSourceProductSize VARCHAR(5),
    @iDestinationProductSize VARCHAR(5),
    @iSourceProduct VARCHAR(30),
    @iDestinationProduct VARCHAR(30),
    @iLoadSiteLocationId VARCHAR(51),
    @iTonnes FLOAT,
    @oBhpbioPortBlendingId INT OUTPUT
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddBhpbioPortBlending',
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
		-- create/update the nomination record
		INSERT INTO dbo.BhpbioPortBlending
		(
			SourceHubLocationID, DestinationHubLocationId, StartDate, EndDate, SourceProductSize, DestinationProductSize, SourceProduct, DestinationProduct, LoadSiteLocationId, Tonnes
		)
		SELECT @iSourceHubLocationId, @iDestinationHubLocationId, @iStartDate, @iEndDate, @iSourceProductSize, @iDestinationProductSize, @iSourceProduct, @iDestinationProduct, @iLoadSiteLocationId, @iTonnes

		SET @oBhpbioPortBlendingId = Scope_Identity()

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

GRANT EXECUTE ON dbo.AddBhpbioPortBlending TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddBhpbioPortBlending">
 <Procedure>
	Adds port blending records.
 </Procedure>
</TAG>
*/
 