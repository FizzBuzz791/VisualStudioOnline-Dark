CREATE TABLE [dbo].[BhpbioLocationGroupLocation]
(
  LocationGroupId INT NOT NULL,
  LocationId INT NOT NULL UNIQUE,
  PRIMARY KEY(LocationGroupId,LocationId)
)
GO