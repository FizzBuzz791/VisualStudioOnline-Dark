Insert Into dbo.BhpbioDefaultLumpFines
(
	LocationId, StartDate, LumpPercent, IsNonDeletable
)
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'WAIO' Union All
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'Yandi' And Location_Type_Id = 2 Union All --hub
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.5, 1 From dbo.Location Where [Name] = 'Yandi' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.45, 1 From dbo.Location Where [Name] = 'NJV' And Location_Type_Id = 2 Union All --hub
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.35, 1 From dbo.Location Where [Name] = 'Newman' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.25, 1 From dbo.Location Where [Name] = 'OB18' And Location_Type_Id = 3 Union All --site
Select Location_Id, dbo.GetSystemStartDateFromSettings(), 0.75, 1 From dbo.Location Where [Name] = 'OB23/25' And Location_Type_Id = 3  --site
Go