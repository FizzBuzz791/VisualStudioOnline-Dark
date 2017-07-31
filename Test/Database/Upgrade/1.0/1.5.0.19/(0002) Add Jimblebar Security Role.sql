-- Create Jimblebar security role using AreaC as a template
Begin Transaction

Insert Into SecurityRole 
Values ('BHP_JIMBLEBAR', 'Jimblebar User')

Insert Into BhpBioSecurityRoleLocation
Select 'BHP_JIMBLEBAR', Location_Id 
From Location
Where Name = 'Jimblebar'
And Location_Type_Id = 2

Insert Into SecurityRoleOption
Select 'BHP_JIMBLEBAR', Application_Id, Option_Id
from SecurityRoleOption
Where Role_Id = 'BHP_AREAC'

Commit Transaction
