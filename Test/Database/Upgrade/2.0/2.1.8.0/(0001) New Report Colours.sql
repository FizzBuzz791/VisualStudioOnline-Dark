
-- some of these are not needed until 2.2, but we might as well create them now. Do a check for OreForRail first
-- to make sure we don't try to put these in twice
IF NOT EXISTS (SELECT TagId FROM BhpbioReportColor WHERE TagId = 'OreForRail')
BEGIN
	INSERT INTO BhpbioReportColor
	(
		TagId, Description, IsVisible, Color, LineStyle, MarkerShape
	)
	Select 'OreForRail', 'Ore For Rail', 1, 'Orange', 'Solid', 'None' Union
	Select 'DirectFeed', 'Direct Feed', 1, 'DarkRed', 'Solid', 'None' Union
	Select 'ExPitToOreStockpile', 'ExPit To Ore Stockpile', 1, 'SeaGreen', 'Solid', 'None' Union
	Select 'StockpileToCrusher', 'Stockpile To Crusher', 1, 'Purple', 'Solid', 'None' Union
	Select 'MiningModelOreForRailEquivalent', 'Mining Model Ore For Rail Equivalent', 1, 'Coral', 'Solid', 'None'
END
