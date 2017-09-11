IF OBJECT_ID('dbo.DoesStratNumExistInStratigraphyHierarchy') IS NOT NULL
     DROP PROCEDURE dbo.DoesStratNumExistInStratigraphyHierarchy  
GO 
  
CREATE PROCEDURE dbo.DoesStratNumExistInStratigraphyHierarchy 
(
	@iStratNum VARCHAR(7),
	@oReturn BIT OUTPUT
)

AS 
BEGIN 
	
	set @oReturn = (
		SELECT	CAST(COUNT(*) AS bit) 
		FROM	[dbo].[BhpbioStratigraphyHierarchy]
		WHERE	StratNum = @iStratNum
	)
	
END 
GO

GRANT EXECUTE ON dbo.DoesStratNumExistInStratigraphyHierarchy TO BhpbioGenericManager