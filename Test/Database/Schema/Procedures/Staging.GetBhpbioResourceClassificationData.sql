IF OBJECT_ID('Staging.GetBhpbioResourceClassificationData') IS NOT NULL
	DROP PROCEDURE Staging.GetBhpbioResourceClassificationData
GO

CREATE PROCEDURE Staging.GetBhpbioResourceClassificationData
(
	@iDigblock VARCHAR(40)
	
)
AS
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY

			Select
				ModelBlockId, 
				MaterialTypeDescription,
				MaterialTypeLongDesc, 
				BlockModelName,
				Description,
				Max(Tonnes) as Tonnes,
				Max(ResourceClassification1) as Measured_High,   
				Max(ResourceClassification2) as Indicated_Medium,
				Max(ResourceClassification3) as Inferred_Low,   
				Max(ResourceClassification4) as Potential_VeryLow,
				Max(ResourceClassification5) as Other,
				Max(ResourceClassificationUnknown) as Unknown
			From ( 
				Select
					mb.Code,
					mb.Model_Block_Id as ModelBlockId,
					bm.Name as BlockModelName,
					mt.Material_Type_Id as MaterialTypeId,
					mbp.Sequence_No,
					mt.Abbreviation as MaterialTypeDescription,
					mt.Description as MaterialTypeLongDesc,
					mbpf.Model_Block_Partial_Field_Id as ClassificationName,
					mbpf.Description as ClassificationDescription,
					mbpv.Field_Value,
					mbp.Tonnes,
					bm.Description
				From ModelBlock mb
					Inner Join BlockModel bm
						On bm.Block_Model_Id = mb.Block_Model_Id
					Inner Join dbo.ModelBlockPartial mbp 
						On mbp.Model_Block_Id = mb.Model_Block_Id 
					Inner Join dbo.MaterialType mt
						On mt.Material_Type_Id = mbp.Material_Type_Id
					Inner Join dbo.ModelBlockPartialField mbpf
						On mbpf.Model_Block_Partial_Field_Id like 'ResourceClass%'
					Left Join dbo.ModelBlockPartialValue mbpv
						On mbpv.Model_Block_Id = mbp.Model_Block_Id
							And mbpv.Sequence_No = mbp.Sequence_No
							And mbpv.Model_Block_Partial_Field_Id = mbpf.Model_Block_Partial_Field_Id
				Where mb.Code = @iDigblock
			)tbl
			
			PIVOT (
				Max(Field_Value)
				For
				ClassificationName IN (
					ResourceClassification1, 
					ResourceClassification2, 
					ResourceClassification3, 
					ResourceClassification4,
					ResourceClassification5,
					ResourceClassificationUnknown
				)
			) As P
			
			Group By ModelBlockId, 
				MaterialTypeLongDesc, 
				MaterialTypeDescription,
				BlockModelName,
				Description

	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON Staging.GetBhpbioResourceClassificationData TO BhpbioGenericManager
GO
