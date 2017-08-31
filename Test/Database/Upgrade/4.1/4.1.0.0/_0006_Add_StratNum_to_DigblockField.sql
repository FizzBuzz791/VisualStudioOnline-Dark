DECLARE @OrderNo int

SELECT	@OrderNo = COALESCE(max(Order_No), 0) + 1
FROM	[dbo].[DigblockField]


INSERT INTO [dbo].[DigblockField] ([Digblock_Field_Id], [Description], [Order_No], [In_Table], [Has_Value], [Has_Notes], [Has_Formula])
 VALUES ('StratNum', 'Stratigraphy Number', @OrderNo, 1, 0, 1, 0)

GO

