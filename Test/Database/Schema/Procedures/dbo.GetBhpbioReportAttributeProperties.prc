IF OBJECT_ID('dbo.GetBhpbioReportAttributeProperties') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportAttributeProperties
GO 

CREATE PROCEDURE dbo.GetBhpbioReportAttributeProperties
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
			DECLARE @Attribute TABLE
		(
			AttributeId SMALLINT NOT NULL,
			AttributeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			Description	VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
			OrderNo INT NOT NULL,
			Units VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
			DisplayPrecision INT NOT NULL,
			DisplayFormat VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
			GradeTypeId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			IsVisible BIT,
			AttributeColor VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL
		)

		DECLARE @TonnesFieldId INT
		SET @TonnesFieldId = 0
		
		DECLARE @VolumeFieldId INT
		SET @VolumeFieldId = -1
		
		INSERT INTO @Attribute
			(
				AttributeId, AttributeName, Description, OrderNo, Units, DisplayPrecision, 
				DisplayFormat, GradeTypeId, IsVisible, AttributeColor
			)
		SELECT G.Grade_Id, G.Grade_Name, G.Description, G.Order_No, G.Units, G.Display_Precision, 
			G.Display_Format, G.Grade_Type_Id, G.Is_Visible, BRC.Color
		FROM dbo.Grade G
		INNER JOIN dbo.BhpbioReportColor BRC
		ON 'Attribute '+Grade_name = TagId
		UNION 
		SELECT @TonnesFieldId, 'Tonnes', 'Tonnes', -1, 't', 0, 'DP', 'Tonnes', 1, BRC.Color
		FROM dbo.BhpbioReportColor BRC
		where BRC.TagId = 'Attribute Tonnes' 
		UNION 
		SELECT @VolumeFieldId, 'Volume', 'Volume', 0, 'cm', 0, 'DP', 'Volume', 1, BRC.Color
		FROM dbo.BhpbioReportColor BRC
		where BRC.TagId = 'Attribute Volume' 
		
		SELECT AttributeId, AttributeName, Description, OrderNo, Units, DisplayPrecision, 
			DisplayFormat, GradeTypeId, IsVisible, AttributeColor
		FROM @Attribute
		ORDER BY OrderNo
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioReportAttributeProperties TO BhpbioGenericManager
GO

--exec dbo.GetBhpbioReportAttributeProperties