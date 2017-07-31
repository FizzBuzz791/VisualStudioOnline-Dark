-- add appropriate reporting colors for new attributes

Insert Into dbo.BhpbioReportColor(TagId, Description, IsVisible, Color, LineStyle, MarkerShape)
Select 'Attribute Volume', 'Volume', 0, 'Black', 'Solid', 'None'
Union All
Select 'Attribute Density', 'Density', 0, 'Brown', 'Solid', 'None'
Union All
Select 'Attribute H2O', 'H2O', 0, 'Blue', 'Solid', 'None'
Union All
Select 'Attribute H2O-As-Dropped', 'H2O-As-Dropped', 0, 'Blue', 'Dash', 'None'
Union All
Select 'Attribute H2O-As-Shipped', 'H2O-As-Shipped', 0, 'Blue', 'DashDot', 'None'
Union All
Select 'F2DensityFactor', 'F2 Density Factor', 1, 'Chocolate', 'Solid', 'None'
Union All
Select 'RecoveryFactorDensity', 'Recovery Factor (Density)', 1, 'DarkOrchid', 'Solid', 'None'
Union All
Select 'ActualMined', 'Total Hauled (H-Value)', 1, 'OrangeRed', 'Solid', 'None'
Union All
Select 'GradeControlSTGM', 'Grade Control (STGM)', 1, 'DarkCyan', 'Solid', 'None'
Go

-- in SSRS2008R2 some of the line style names have changed. The attributes in the ReportColor table
-- get passed straight through to the Graph control, so we need to update these field names
Update BhpbioReportColor Set LineStyle = 'Dashed' Where LineStyle = 'Dash'
Update BhpbioReportColor Set LineStyle = 'Dotted' Where LineStyle = 'Dot'
Go
