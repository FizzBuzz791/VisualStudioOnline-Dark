ALTER TABLE dbo.BhpbioReportDataTags ADD
	TagGroupLocationTypeId TINYINT NULL,
	OtherMaterialTypeId INT NULL,
	CONSTRAINT FK_BhpbioReportDataTags_TagGroupLocationTypeId FOREIGN KEY
		(TagGroupLocationTypeId) REFERENCES dbo.LocationType (Location_Type_Id),
	CONSTRAINT FK_BhpbioReportDataTags_OtherMaterialType FOREIGN KEY
		(OtherMaterialTypeId) REFERENCES dbo.MaterialType (Material_Type_Id)
GO

UPDATE T
SET T.OtherMaterialTypeId = MT.Material_Type_Id
FROM BhpbioReportDataTags AS T
	INNER JOIN MaterialType AS MT
		ON MT.Description = Replace(Replace(T.TagId, 'OtherMaterial_', ''), '_', ' ')
			AND MT.Material_Category_Id = 'Designation'
WHERE TagId LIKE 'OtherMaterial_%'
	
DELETE
FROM BhpbioReportDataTags
WHERE TagId LIKE 'OtherMaterial_%' ANd OtherMaterialTypeId IS NULL

UPDATE T
SET TagGroupLocationTypeId = 
	CASE WHEN TagGroupId = 'F1Factor' THEN (Select Location_Type_Id FROM dbo.LocationType WHERE Description = 'Pit')
	WHEN TagGroupId = 'F2Factor' THEN (Select Location_Type_Id FROM dbo.LocationType WHERE Description = 'Site')
	WHEN TagGroupId = 'F3Factor' THEN (Select Location_Type_Id FROM dbo.LocationType WHERE Description = 'Hub')
	ELSE NULL
	END
FROM dbo.BhpbioReportDataTags AS T