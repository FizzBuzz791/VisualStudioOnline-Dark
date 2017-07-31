IF OBJECT_ID('dbo.AddOrUpdateBhpbioShippingNomination') IS NOT NULL
	DROP PROCEDURE dbo.AddOrUpdateBhpbioShippingNomination
GO

CREATE PROCEDURE dbo.AddOrUpdateBhpbioShippingNomination
(
	@iNominationKey INT,
	@iVesselName VARCHAR(63)
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BhpbioShippingNominationItemId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioShippingNomination',
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
		-- create/update the base transaction record
		IF NOT EXISTS
			(
				SELECT 1
				FROM dbo.BhpbioShippingNomination
				WHERE NominationKey = @iNominationKey
			)
		BEGIN
			INSERT INTO dbo.BhpBioShippingNomination
			(
				NominationKey, VesselName
			)
			VALUES
			(
				@iNominationKey, @iVesselName
			)
		END
		ELSE
		BEGIN
			UPDATE dbo.BhpbioShippingNomination
			SET VesselName = @iVesselName
			WHERE NominationKey = @iNominationKey
				AND VesselName <> @iVesselName
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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioShippingNomination TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddOrUpdateBhpbioShippingNomination">
 <Procedure>
	Adds and updates the parent shipping transaction records.
 </Procedure>
</TAG>
*/	