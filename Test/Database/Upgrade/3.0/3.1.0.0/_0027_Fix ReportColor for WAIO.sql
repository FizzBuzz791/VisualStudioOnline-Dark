--
-- By default the WAIO color is Black, this causes problems with the shipping targets reports
-- because they have to show the WAIO location. We change the color to SkyBlue. If WAIO don't like this
-- they can change it themselves later on, but at least the report will render correctly
--
Update BhpbioReportColor
Set Color = 'SkyBlue'
Where TagId = '1' and Color = 'Black'
