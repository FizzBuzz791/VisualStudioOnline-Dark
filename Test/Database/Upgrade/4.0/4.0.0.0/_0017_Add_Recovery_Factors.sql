-- Update table to allow bigger/better descriptions
ALTER TABLE dbo.BhpbioReportThresholdType ALTER COLUMN Description NVARCHAR(100) NOT NULL

-- Update existing threshold types
UPDATE dbo.BhpbioReportThresholdType SET Description = 'RFMMH2O - Actual C / Mining Model (Dropped)' WHERE ThresholdTypeId = 'RecoveryFactorMoisture'
UPDATE dbo.BhpbioReportThresholdType SET Description = 'RFMMD - Total Hauled /  Mining Model' WHERE ThresholdTypeId = 'RecoveryFactorDensity'

-- Add new threshold types
INSERT INTO dbo.BhpbioReportThresholdType (ThresholdTypeId, Description) 
	VALUES ('RFGM','RFGM - Mine Production (Expit) / Geology Model'),
		   ('RFMM','RFMM - Mine Production (Expit) / Mining Model'),
		   ('RFSTM','RFSTM - Mine Production (Expit) / Short Term Model'),
		   ('F0Factor','F0.0 Factor'),
		   ('F05Factor','F0.5 Factor')

-- Add new threshold configurations
INSERT INTO dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	VALUES (1,-1,'RFGM',5,10,0),		-- Volume
		   (1,0,'RFGM',5,10,0),			-- Tonnes
		   (1,1,'RFGM',0.3,0.6,1),		-- Fe
		   (1,2,'RFGM',5,10,0),			-- P
		   (1,3,'RFGM',5,10,0),			-- SiO2
		   (1,4,'RFGM',5,10,0),			-- Al2O3
		   (1,5,'RFGM',5,10,0),			-- LOI
		   (1,6,'RFGM',5,10,0),			-- Density
		   (1,7,'RFGM',5,10,0),			-- H2O
		   (1,8,'RFGM',5,10,0),			-- H2O-As-Dropped
		   (1,9,'RFGM',5,10,0),			-- H2O-As-Shipped
		   (1,10,'RFGM',5,10,0),		-- Ultrafines
		   
		   (1,-1,'RFMM',5,10,0),		-- Volume
		   (1,0,'RFMM',5,10,0),			-- Tonnes
		   (1,1,'RFMM',0.3,0.6,1),		-- Fe
		   (1,2,'RFMM',5,10,0),			-- P
		   (1,3,'RFMM',5,10,0),			-- SiO2
		   (1,4,'RFMM',5,10,0),			-- Al2O3
		   (1,5,'RFMM',5,10,0),			-- LOI
		   (1,6,'RFMM',5,10,0),			-- Density
		   (1,7,'RFMM',5,10,0),			-- H2O
		   (1,8,'RFMM',5,10,0),			-- H2O-As-Dropped
		   (1,9,'RFMM',5,10,0),			-- H2O-As-Shipped
		   (1,10,'RFMM',5,10,0),		-- Ultrafines

		   (1,-1,'RFSTM',5,10,0),		-- Volume
		   (1,0,'RFSTM',5,10,0),		-- Tonnes
		   (1,1,'RFSTM',0.3,0.6,1),		-- Fe
		   (1,2,'RFSTM',5,10,0),		-- P
		   (1,3,'RFSTM',5,10,0),		-- SiO2
		   (1,4,'RFSTM',5,10,0),		-- Al2O3
		   (1,5,'RFSTM',5,10,0),		-- LOI
		   (1,6,'RFSTM',5,10,0),		-- Density
		   (1,7,'RFSTM',5,10,0),		-- H2O
		   (1,8,'RFSTM',5,10,0),		-- H2O-As-Dropped
		   (1,9,'RFSTM',5,10,0),		-- H2O-As-Shipped
		   (1,10,'RFSTM',5,10,0),		-- Ultrafines

		   (1,-1,'F0Factor',5,10,0),	-- Volume
		   (1,0,'F0Factor',5,10,0),		-- Tonnes
		   (1,1,'F0Factor',0.3,0.6,1),	-- Fe
		   (1,2,'F0Factor',5,10,0),		-- P
		   (1,3,'F0Factor',5,10,0),		-- SiO2
		   (1,4,'F0Factor',5,10,0),		-- Al2O3
		   (1,5,'F0Factor',5,10,0),		-- LOI
		   (1,6,'F0Factor',5,10,0),		-- Density
		   (1,7,'F0Factor',5,10,0),		-- H2O
		   (1,8,'F0Factor',5,10,0),		-- H2O-As-Dropped
		   (1,9,'F0Factor',5,10,0),		-- H2O-As-Shipped
		   (1,10,'F0Factor',5,10,0),	-- Ultrafines

		   (1,-1,'F05Factor',5,10,0),	-- Volume
		   (1,0,'F05Factor',5,10,0),	-- Tonnes
		   (1,1,'F05Factor',0.3,0.6,1),	-- Fe
		   (1,2,'F05Factor',5,10,0),	-- P
		   (1,3,'F05Factor',5,10,0),	-- SiO2
		   (1,4,'F05Factor',5,10,0),	-- Al2O3
		   (1,5,'F05Factor',5,10,0),	-- LOI
		   (1,6,'F05Factor',5,10,0),	-- Density
		   (1,7,'F05Factor',5,10,0),	-- H2O
		   (1,8,'F05Factor',5,10,0),	-- H2O-As-Dropped
		   (1,9,'F05Factor',5,10,0),	-- H2O-As-Shipped
		   (1,10,'F05Factor',5,10,0)	-- Ultrafines