
ALTER TABLE Staging.StageBlock 
	ALTER COLUMN BlockNumber Varchar(4) NULL

ALTER TABLE dbo.BhpbioImportReconciliationMovement 
	ALTER COLUMN BlockNumber Varchar(4) NOT NULL

ALTER TABLE dbo.BhpbioImportReconciliationMovementStage 
	ALTER COLUMN BlockNumber Varchar(4) NOT NULL
