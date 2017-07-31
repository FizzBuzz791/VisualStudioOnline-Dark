If Object_Id('dbo.BhpbioDefaultLumpFines') Is Not Null
	Drop Table dbo.BhpbioDefaultLumpFines
Go

Create Table dbo.BhpbioDefaultLumpFines
(
	BhpbioDefaultLumpFinesId Int Identity(1, 1),
	LocationId Int Not Null,
	StartDate DateTime Not Null,
	LumpPercent Decimal(5,4) Not Null,
	IsNonDeletable Bit Not Null Default(0),
	
	Constraint PK_BhpbioDefaultLumpFines Primary Key Clustered (BhpbioDefaultLumpFinesId Asc)
)
Go

Alter Table dbo.BhpbioDefaultLumpFines Add Constraint FK_BhpbioDefaultLumpFines_Location
Foreign Key (LocationId) References dbo.Location (Location_Id)
Go