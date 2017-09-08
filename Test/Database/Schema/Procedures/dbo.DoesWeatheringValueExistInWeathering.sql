IF OBJECT_ID('dbo.DoesWeatheringValueExistInWeathering') IS NOT NULL
     DROP PROCEDURE dbo.DoesWeatheringValueExistInWeathering  
GO 
  
CREATE PROCEDURE dbo.DoesWeatheringValueExistInWeathering
(
	@iWeathering VARCHAR(7),
	@oReturn BIT OUTPUT
)

AS 
BEGIN 
	
	set @oReturn = (
		SELECT	CAST(COUNT(*) AS bit) 
		FROM	[dbo].[BhpbioWeathering]
		WHERE	DisplayValue = @iWeathering
	)
	
END 
GO

GRANT EXECUTE ON dbo.DoesWeatheringValueExistInWeathering TO BhpbioGenericManager