DECLARE @OrderNo int

SELECT	@OrderNo = COALESCE(max(Order_No), 0) + 1
FROM	[dbo].[WeightometerSampleField]


INSERT INTO [dbo].[WeightometerSampleField]
           ([Weightometer_Sample_Field_Id], [Description], [Order_No], [In_Table], [Has_Value], [Has_Notes], [Has_Formula])
     VALUES('SampleCount', 'Sample Count', @OrderNo, 0, 1, 0, 0)