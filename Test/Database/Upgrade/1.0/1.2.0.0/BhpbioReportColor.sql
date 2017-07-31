INSERT INTO dbo.BhpbioReportColor
(
	TagId, Description, IsVisible, Color, LineStyle, MarkerShape
)
SELECT 'SitePostCrusherStockpileDelta', 'Site Post-Crusher Stockpile Delta', 1, 'Orchid', 'Solid', 'None'
UNION ALL SELECT 'HubPostCrusherStockpileDelta', 'Hub Post-Crusher Stockpile Delta', 1, 'DarkOrchid', 'Solid', 'None'
