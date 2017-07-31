ALTER TABLE dbo.BhpbioMetBalancing
ADD ProductSize VARCHAR(5) NULL
GO

ALTER TABLE BhpbioMetBalancing DROP CONSTRAINT UQ_BhpbioMetBalancing

ALTER TABLE BhpbioMetBalancing
	ADD CONSTRAINT UQ_BhpbioMetBalancing UNIQUE (SiteCode, CalendarDate, PlantName, StreamName, ProductSize)
GO