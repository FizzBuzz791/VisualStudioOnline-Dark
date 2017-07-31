-- Insert the new approval type into the system
DECLARE @materialTypeId INTEGER

SELECT @materialTypeId = Material_Type_Id
FROM MaterialType 
WHERE Abbreviation = 'Blend Grade'

IF @materialTypeId IS NOT NULL
BEGIN
	INSERT INTO dbo.BhpbioReportDataTags(TagId, TagGroupId, TagGroupLocationTypeId, OtherMaterialTypeId)
		SELECT 'OtherMaterial_Blend_Grade', 'OtherMaterial', NULL, @materialTypeID
END
GO