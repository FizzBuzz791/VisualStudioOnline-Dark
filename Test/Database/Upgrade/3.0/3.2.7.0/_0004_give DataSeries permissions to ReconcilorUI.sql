-- give reconcilorUI permissions to the DataSeries schema
--
-- this shouldn't be required, because we already gave these grants individually, but no
-- matter what we do with those scripts the outlier stuff errors out with giving these
-- permissions
-- 
GRANT CONTROL ON SCHEMA :: DataSeries TO ReconcilorUI
GO
