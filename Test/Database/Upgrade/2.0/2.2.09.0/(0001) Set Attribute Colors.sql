
-- These attributes are now being used on the Factor vs Time reports, so we need them to be visible
-- on the utilities page, and have appropriate colors
Update dbo.BhpbioReportColor Set IsVisible = 1, Color = 'SeaGreen' Where TagId = 'Attribute Volume'
Update dbo.BhpbioReportColor Set IsVisible = 1, Color = 'SandyBrown' Where TagId = 'Attribute Density'
Update dbo.BhpbioReportColor Set IsVisible = 1, Color = 'LightBlue' Where TagId = 'Attribute H2O'

Go
