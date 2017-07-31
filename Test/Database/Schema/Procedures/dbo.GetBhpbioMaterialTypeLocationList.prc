IF OBJECT_ID('dbo.GetBhpbioMaterialTypeLocationList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioMaterialTypeLocationList
GO 
  
CREATE PROCEDURE dbo.GetBhpbioMaterialTypeLocationList
(
	@iMaterialTypeId INT = NULL
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioMaterialTypeLocationList',
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
		-- delete the material type location records
		SELECT L.Location_Id As LocationId, L.Name As LocationName,
			CASE WHEN (MTL.Location_Id IS NULL) THEN 0 ELSE 1 END AS IsIncluded
		FROM Location L
			INNER JOIN LocationType LT
				On (LT.Location_Type_Id = L.Location_Type_Id)
			LEFT JOIN dbo.MaterialTypeLocation MTL
				ON (MTL.Location_Id = L.Location_Id
					AND MTL.Material_Type_Id = @iMaterialTypeId)
		WHERE LT.Description = 'Site'
		ORDER BY L.Name

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

GRANT EXECUTE ON dbo.GetBhpbioMaterialTypeLocationList TO BhpbioGenericManager
GO
