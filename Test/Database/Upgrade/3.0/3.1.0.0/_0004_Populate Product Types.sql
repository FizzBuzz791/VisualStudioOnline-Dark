--
-- This populates the Product Types list with the data we have from BHP
-- this assumes the table is empty
--
Set Identity_Insert dbo.BhpbioProductType On

Declare @NBLL Integer = 1
Declare @MACF Integer = 2
Declare @JMBF Integer = 3
Declare @YNDF Integer = 4
Declare @NHGF Integer = 5

Insert Into BhpbioProductType(ProductTypeId, ProductTypeCode, Description, ProductSize)
	Select @NBLL, 'NBLL', 'Newman Blended Lump', 'LUMP' Union
	Select @MACF, 'MACF', 'MAC Fines', 'FINES' Union
	Select @JMBF, 'JMBF', 'Jimblebar Fines', 'FINES' Union
	Select @YNDF, 'YNDF', 'Yandi Fines', 'FINES' Union
	Select @NHGF, 'NHGF', 'Newman Fines', 'FINES'

Insert Into BhpbioProductTypeLocation(ProductTypeId, LocationId)
	Select @NBLL, 2 Union
	Select @NBLL, 4 Union
	Select @NBLL, 6 Union
	Select @NBLL, 8 Union
	Select @NBLL, 133098 Union
	Select @MACF, 6 Union
	Select @JMBF, 133098 Union
	Select @YNDF, 2 Union
	Select @NHGF, 8
	
Set Identity_Insert dbo.BhpbioProductType Off

