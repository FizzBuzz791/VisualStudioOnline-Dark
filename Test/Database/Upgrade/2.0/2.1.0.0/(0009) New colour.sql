
INSERT INTO BhpbioReportColor
(
	TagId, Description, IsVisible, Color, LineStyle, MarkerShape
)
Select 'CompareGradeControl/ShortTermGeology','Comparison of Grade Control to Short Term Geology Model', 1,'Cyan','Solid','None' Union

-- these colors are needed for the Supply Chain Monitoring report to work properly
Select 'DirectFeed', 'Direct Feed', 1, 'DarkRed', 'Solid', 'None' Union
Select 'OreForRail', 'Ore For Rail', 1, 'Orange', 'Solid', 'None' Union
Select 'ExPitToOreStockpile', 'ExPit To Ore Stockpile', 1, 'SeaGreen', 'Solid', 'None' Union
Select 'StockpileToCrusher', 'Stockpile To Crusher', 1, 'Purple', 'Solid', 'None'