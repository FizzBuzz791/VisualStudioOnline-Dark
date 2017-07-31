IF Object_id('dbo.GetLocationTypeId') IS NOT NULL 
     DROP PROCEDURE dbo.GetLocationTypeId
GO 

CREATE PROCEDURE dbo.GetLocationTypeId
(
	@iDescription VARCHAR(255),
	@oLocationTypeId INT OUTPUT
)
AS
BEGIN

	SELECT @oLocationTypeId=locType.Location_Type_Id FROM [dbo].[LocationType] locType 
	WHERE locType.Description=@iDescription

End
GO

GRANT EXECUTE ON dbo.GetLocationTypeId TO BhpbioGenericManager
GO
