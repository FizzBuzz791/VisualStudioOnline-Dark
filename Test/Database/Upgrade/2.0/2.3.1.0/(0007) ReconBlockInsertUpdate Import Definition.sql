--Data population of ReconBlockInsertUpdate import definition and configuration
DECLARE @ImportId INT

INSERT INTO Import
Select 'ReconBlockInsertUpdate',1,2,'Blocks Insert/Update Interface from Blastholes to the Reconcilor Blastholes Holding area.',1,60,NULL

SET @ImportId = SCOPE_IDENTITY()

INSERT INTO ImportParameter
Select @ImportId, ParameterName, DisplayName, IsRequired, DefaultParameterValue, OrderNo, IsVisible, IsEnabled
From ImportParameter
Where ImportId = 2


