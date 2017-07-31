
INSERT INTO dbo.Crusher
(
	Crusher_id
	, Description
)
SELECT 'YD-OHP3'
	, 'Yandi Crusher 3'

INSERT INTO dbo.HaulageResolveBasic
(
	Code
	, Resolve_From_Date
	, Resolve_From_shift
	, Resolve_To_Date
	, Resolve_To_Shift
	, Stockpile_Id
	, Build_Id
	, Component_Id
	, Digblock_Id
	, Crusher_Id
	, Mill_Id
	, Description
	, Haulage_Direction
)
SELECT 'YD-YD3'
	, '2010-01-01 00:00:00.000'
	, 'D'
	, null
	, null
	, null
	, null
	, null
	, null
	, 'YD-OHP3'
	, null
	, 'Yandi OHP Crushers.'
	, 'B'

INSERT INTO dbo.BhpbioProductionResolveBasic
(
	Code
	, Resolve_From_Date
	, Resolve_From_Shift
	, Resolve_To_Date
	, Resolve_To_Shift
	, Stockpile_id
	, Build_id
	, Component_id
	, Digblock_id
	, Crusher_id
	, Mill_id
	, [Description]
	, Production_Direction
)
SELECT  'YD-YD3'
	, '2009-04-01 00:00:00.000'
	, 'D'
	, null
	, null
	, null
	, null
	, null
	, null
	, 'YD-OHP3'
	, null
	, 'Yandi OHP Crusher Rename for RGP5'
	, 'B'

INSERT INTO dbo.Weightometer
(
	Weightometer_id
	, Description
	, Is_visible
	, Weightometer_type_id
	, Weightometer_group_id
)
SELECT 'YD-Y3Outflow'
	, 'YD-Y3 Outflow to Stockpile.'
	, 1
	, 'CVF+L1'
	, null

INSERT INTO dbo.WeightometerLocation
(
	Weightometer_id
	, Location_type_id
	, Location_id
)
SELECT 'YD-Y3Outflow'
	, 3
	, 3
		
INSERT INTO dbo.WeightometerFlowPeriod
(
	Weightometer_id
	, End_date
	, Source_stockpile_id
	, Source_crusher_id
	, Source_mill_id
	, Destination_stockpile_id
	, Destination_Crusher_id
	, Destination_mill_id
	, Is_calculated
	, Processing_order_no
)
SELECT 'YD-Y3Outflow'
	, null
	, null
	, 'YD-OHP3'
	, null
	, null
	, null
	, null
	, 0
	, 27

/*


DELETE FROM dbo.WeightometerFlowPeriod
WHERE Weightometer_id = 'YD-Y3Outflow'

DELETE FROM dbo.WeightometerLocation
WHERE Weightometer_id = 'YD-Y3Outflow'

DELETE FROM dbo.Weightometer
WHERE Weightometer_Id = 'YD-Y3Outflow'

DELETE FROM dbo.BhpbioProductionResolveBasic
WHERE Code = 'YD-YD3'

DELETE FROM dbo.HaulageResolveBasic
WHERE Code = 'YD-YD3'

DELETE FROM dbo.Crusher
Where Crusher_id = 'YD-OHP3'



*/


