IF OBJECT_ID('dbo.GetBhpbioShippingNominationItemById') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioShippingNominationItemById
GO 
  
CREATE PROCEDURE dbo.GetBhpbioShippingNominationItemById
(
	@iBhpbioShippingNominationItemId INT
)
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
	
		SELECT stn.BhpbioShippingNominationItemId,
			stn.NominationKey,
			stn.ItemNo,
			stn.OfficialFinishTime,
			stn.LastAuthorisedDate,
			stn.CustomerNo,
			stn.CustomerName,
			stnp.HubLocationId,
			stn.ShippedProduct,
			stnp.Tonnes 
		FROM dbo.BhpbioShippingNominationItem stn
		INNER JOIN dbo.BhpbioShippingNominationItemParcel stnp
			ON stn.BhpbioShippingNominationItemId = stnp.BhpbioShippingNominationItemId
		WHERE stn.BhpbioShippingNominationItemId = @iBhpbioShippingNominationItemId
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioShippingNominationItemById TO BhpbioGenericManager
GO
