IF OBJECT_ID('dbo.GetBhpbioProductTypeLocations') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioProductTypeLocations 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioProductTypeLocations
( 
	@iProductTypeId INT = NULL
) 
AS
BEGIN 
    SET NOCOUNT ON 
		IF @iProductTypeId is null
		BEGIN
			
			DECLARE @Temp TABLE (
				ProductTypeID INT,
				ProductTypeCode NVARCHAR(50),
				Description NVARCHAR(150),
				ProductSize NVARCHAR(50),
				LocationId INT,
				Hub NVARCHAR(50)
			)
			
			INSERT INTO @Temp
				SELECT 
					PT.ProductTypeID, 
					ProductTypeCode,
					PT.Description,
					PT.ProductSize,
					L.Location_id,
					Name as Hub
				FROM Location L 
					INNER JOIN BhpbioProductTypeLocation PTL 
						ON L.Location_Id = PTL.LocationId 
					INNER JOIN BhpbioProductType PT 
						ON PT.ProductTypeId = PTL.ProductTypeId
		
			-- if you select all ProductTypes, then the locations will be concatenated
			-- together so that there is only a single record per ProductType
			SELECT 
				ProductTypeID,
				ProductTypeCode, 
				Description , 
				ProductSize, 
				STUFF((SELECT ', ' + A.Hub FROM @Temp A Where A.ProductTypeID = B.ProductTypeID FOR XML PATH('')),1,1,'') As Hubs
			FROM @Temp B
			GROUP BY ProductTypeCode, Description, ProductTypeID,ProductSize
			
		END
		ELSE
		BEGIN
		
			-- if you get only a single ProductType, then all the locations will
			-- be returned with one row per location
			SELECT 
				PT.ProductTypeID, 
				ProductTypeCode,
				PT.Description,PT.ProductSize,
				L.Location_id, 
				Name as Hub 
			FROM Location L 
				INNER JOIN  BhpbioProductTypeLocation PTL 
					ON L.Location_Id = PTL.LocationId 
				INNER JOIN  BhpbioProductType PT 
					ON PT.ProductTypeId = PTL.ProductTypeId
			WHERE PTL.ProductTypeId = @iProductTypeId
			
		END
END 
GO 
GRANT EXECUTE ON dbo.GetBhpbioProductTypeLocations TO BhpbioGenericManager
