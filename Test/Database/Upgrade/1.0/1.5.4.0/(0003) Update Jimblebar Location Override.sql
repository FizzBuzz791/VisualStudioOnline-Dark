--Update Location overrides

Insert Into BhpbioLocationOverride
(Location_Id, Location_Type_Id, Parent_Location_Id, FromMonth, ToMonth)
Select 133098, 2, 1, '2012-10-01','2050-12-31'
Union All
Select 137230, 2, 1, '2050-12-31','2050-12-31'
Go


Exec dbo.UpdateBhpbioLocationDate
Go
