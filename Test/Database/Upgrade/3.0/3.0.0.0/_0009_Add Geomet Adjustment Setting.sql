
-- This is the adjustment to the tonnes for some of the Model in the Geomet report. It is applied only
-- to the LUMP tonnes, and has the affect of increasing the Lump % of these models
Insert Into Setting 
	Values ('GEOMET_AS_DROPPED_ADJUSTMENT', 'Geomet As-Dropped Adjustment Factor', 'REAL', 1, '0.86', NULL) 

-- when this setting is set to true, a geomet section will be in the HUB report, and the excel export when 
-- in Lump Fines mode
Insert Into Setting 
	Values ('GEOMET_REPORTING_ENABLED', 'Geomet data appears in reports', 'BOOLEAN', 1, 'FALSE', 'TRUE,FALSE') 
