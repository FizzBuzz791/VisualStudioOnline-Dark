BEGIN TRANSACTION 

INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('HaulageToOreVsNonOre','Haulage to ore vs non-ore','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('HaulageToOreVsNonOre_Tonnes','HaulageToOreVsNonOre')

COMMIT TRANSACTION
GO

