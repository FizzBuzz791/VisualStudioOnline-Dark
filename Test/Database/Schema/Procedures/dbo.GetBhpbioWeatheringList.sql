IF OBJECT_ID('dbo.GetBhpbioWeatheringList') IS NOT NULL
	DROP PROCEDURE [dbo].[GetBhpbioWeatheringList]
GO 

CREATE PROCEDURE [dbo].[GetBhpbioWeatheringList]
AS
BEGIN
	SELECT	[Id],
			[Description],
			[DisplayValue],
			[Colour]
	FROM	[dbo].[BhpbioWeathering]
END 
GO

GRANT EXECUTE ON [dbo].[GetBhpbioWeatheringList] TO BhpbioGenericManager
GO