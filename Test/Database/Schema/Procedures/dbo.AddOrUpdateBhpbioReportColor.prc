IF OBJECT_ID('dbo.AddOrUpdateBhpbioReportColor') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioReportColor  
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioReportColor
(
	@iTagId VARCHAR(63),
	@iDescription VARCHAR(255) = NULL,
	@iIsVisible BIT = NULL,
	@iColor VARCHAR(255),
	@iLineStyle VARCHAR(50) = NULL,
	@iMarkerShape VARCHAR(50) = NULL
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioReportColor',
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
	
		IF EXISTS (SELECT 1 FROM dbo.BhpbioReportColor WHERE TagId = @iTagId)
		BEGIN 
			-- Update the color.
			UPDATE C
			SET Description = CASE WHEN @iDescription IS NULL THEN Description ELSE @iDescription END,
				IsVisible = CASE WHEN @iIsVisible IS NULL THEN IsVisible ELSE @iIsVisible END,
				Color = @iColor,
				LineStyle = @iLineStyle,
				MarkerShape = @iMarkerShape
			FROM dbo.BhpbioReportColor AS C
			WHERE TagId = @iTagId
		END
		ELSE
		BEGIN
			INSERT INTO dbo.BhpbioReportColor
				(TagId, Description, IsVisible, Color, LineStyle, MarkerShape)
			SELECT @iTagId, @iDescription, @iIsVisible, @iColor, @iLineStyle, @iMarkerShape
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
GRANT EXECUTE ON dbo.AddOrUpdateBhpbioReportColor TO BhpbioGenericManager
