DELETE stgm
FROM DataSeries.SeriesTypeGroup sg
	INNER JOIN DataSeries.SeriesTypeGroupMembership stgm ON stgm.SeriesTypeGroupId = sg.Id
WHERE sg.ContextKey = 'OutlierAnalysisGroup'
GO

DELETE sg
FROM DataSeries.SeriesTypeGroup sg
WHERE sg.ContextKey = 'OutlierAnalysisGroup'
GO

INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisActualMined','Actual Mined (H)','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisBeneRatio','Bene Ratio','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisExPitToOreStockpile','Ex-pit to Ore Stockpile','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF15Factor','F1.5 Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF1Factor','F1 Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF25Factor','F2.5 Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF2DensityFactor','F2 Density Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF2Factor','F2 Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF3Factor','F3 Factor and Contributing Data','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisGeologyModel','Geology Model','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisGradeControlModel','Grade Control Model','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisGradeControlSTGM','Grade Control with STGM','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisHubPostCrusherStockpileDelta','Hub Post Crusher Stockpile Delta','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMineProductionActuals','Mine Production Actuals','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMineProductionExpitEqulivent','Mine Production Expit Equivalent','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMiningModel','Mining Model','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMiningModelCrusherEquivalent','Mining Model Crusher Equivalent','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMiningModelOreForRailEquivalent','Mining Model Ore For Rail Equivalent','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisMiningModelShippingEquivalent','Mining Model Shipping Equivalent','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisOreForRail','Ore for Rail','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisOreShipped','Ore Shipped','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisPortBlendedAdjustment','Port Blended Adjustment','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisPortStockpileDelta','Port Stockpile Delta','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisPostCrusherStockpileDelta','Post Crusher Stockpile Delta','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisRecoveryFactorDensity','Recovery Factor Density','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisShortTermGeologyModel','Short Term Geology Model','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisSitePostCrusherStockpileDelta','Site Post Crusher Stockpile Delta','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisStockpileToCrusher','Stockpile to Crusher','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF15FactorOnly','F1.5 Factor Only','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF1FactorOnly','F1 Factor Only','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF25FactorOnly','F2.5 Factor Only','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF2DensityFactorOnly','F2 Density Factor Only','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF2FactorOnly','F2 Factor Only','OutlierAnalysisGroup')
INSERT INTO DataSeries.SeriesTypeGroup(Id,Name,ContextKey) VALUES ('OutlierAnalysisF3FactorOnly','F3 Factor Only','OutlierAnalysisGroup')
GO


INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ActualMined_Tonnes_PS','OutlierAnalysisActualMined')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Fe_PS','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Fe_PS_MT','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Grade_PS','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Grade_PS_MT','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Tonnes_PS','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('BeneRatio_Tonnes_PS_MT','OutlierAnalysisBeneRatio')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Fe_PS','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Fe_PS_MT','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Grade_PS','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Grade_PS_MT','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Tonnes_PS','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ExPitToOreStockpile_Tonnes_PS_MT','OutlierAnalysisExPitToOreStockpile')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Fe_PS','OutlierAnalysisF15Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Grade_PS','OutlierAnalysisF15Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Tonnes_PS','OutlierAnalysisF15Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Fe_PS','OutlierAnalysisF1Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Grade_PS','OutlierAnalysisF1Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Tonnes_PS','OutlierAnalysisF1Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Fe_PS','OutlierAnalysisF25Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Grade_PS','OutlierAnalysisF25Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Tonnes_PS','OutlierAnalysisF25Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2DensityFactor_Tonnes_PS','OutlierAnalysisF2DensityFactor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Fe_PS','OutlierAnalysisF2Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Grade_PS','OutlierAnalysisF2Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Tonnes_PS','OutlierAnalysisF2Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Fe_PS','OutlierAnalysisF3Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Grade_PS','OutlierAnalysisF3Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Tonnes_PS','OutlierAnalysisF3Factor')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Fe_PS','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Fe_PS_MT','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Grade_PS','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Grade_PS_MT','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Tonnes_PS','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GeologyModel_Tonnes_PS_MT','OutlierAnalysisGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Fe_PS','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Fe_PS_MT','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Grade_PS','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Grade_PS_MT','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Tonnes_PS','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlModel_Tonnes_PS_MT','OutlierAnalysisGradeControlModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Fe_PS','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Fe_PS_MT','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Grade_PS','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Grade_PS_MT','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Tonnes_PS','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('GradeControlSTGM_Tonnes_PS_MT','OutlierAnalysisGradeControlSTGM')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('HubPostCrusherStockpileDelta_Fe_PS','OutlierAnalysisHubPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('HubPostCrusherStockpileDelta_Grade_PS','OutlierAnalysisHubPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('HubPostCrusherStockpileDelta_Tonnes_PS','OutlierAnalysisHubPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Fe_PS','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Fe_PS_MT','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Grade_PS','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Grade_PS_MT','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Tonnes_PS','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionActuals_Tonnes_PS_MT','OutlierAnalysisMineProductionActuals')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Fe_PS','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Fe_PS_MT','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Grade_PS','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Grade_PS_MT','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Tonnes_PS','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MineProductionExpitEqulivent_Tonnes_PS_MT','OutlierAnalysisMineProductionExpitEqulivent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Fe_PS','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Fe_PS_MT','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Grade_PS','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Grade_PS_MT','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Tonnes_PS','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModel_Tonnes_PS_MT','OutlierAnalysisMiningModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Fe_PS','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Fe_PS_MT','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Grade_PS','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Grade_PS_MT','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Tonnes_PS','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelCrusherEquivalent_Tonnes_PS_MT','OutlierAnalysisMiningModelCrusherEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelOreForRailEquivalent_Fe_PS','OutlierAnalysisMiningModelOreForRailEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelOreForRailEquivalent_Grade_PS','OutlierAnalysisMiningModelOreForRailEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelOreForRailEquivalent_Tonnes_PS','OutlierAnalysisMiningModelOreForRailEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelShippingEquivalent_Fe_PS','OutlierAnalysisMiningModelShippingEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelShippingEquivalent_Grade_PS','OutlierAnalysisMiningModelShippingEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('MiningModelShippingEquivalent_Tonnes_PS','OutlierAnalysisMiningModelShippingEquivalent')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreForRail_Fe_PS','OutlierAnalysisOreForRail')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreForRail_Grade_PS','OutlierAnalysisOreForRail')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreForRail_Tonnes_PS','OutlierAnalysisOreForRail')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreShipped_Fe_PS','OutlierAnalysisOreShipped')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreShipped_Grade_PS','OutlierAnalysisOreShipped')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('OreShipped_Tonnes_PS','OutlierAnalysisOreShipped')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortBlendedAdjustment_Fe_PS','OutlierAnalysisPortBlendedAdjustment')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortBlendedAdjustment_Grade_PS','OutlierAnalysisPortBlendedAdjustment')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortBlendedAdjustment_Tonnes_PS','OutlierAnalysisPortBlendedAdjustment')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortStockpileDelta_Fe_PS','OutlierAnalysisPortStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortStockpileDelta_Grade_PS','OutlierAnalysisPortStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PortStockpileDelta_Tonnes_PS','OutlierAnalysisPortStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PostCrusherStockpileDelta_Fe_PS','OutlierAnalysisPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PostCrusherStockpileDelta_Grade_PS','OutlierAnalysisPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('PostCrusherStockpileDelta_Tonnes_PS','OutlierAnalysisPostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('RecoveryFactorDensity_Tonnes_PS','OutlierAnalysisRecoveryFactorDensity')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Fe_PS','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Fe_PS_MT','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Grade_PS','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Grade_PS_MT','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Tonnes_PS','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('ShortTermGeologyModel_Tonnes_PS_MT','OutlierAnalysisShortTermGeologyModel')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('SitePostCrusherStockpileDelta_Fe_PS','OutlierAnalysisSitePostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('SitePostCrusherStockpileDelta_Grade_PS','OutlierAnalysisSitePostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('SitePostCrusherStockpileDelta_Tonnes_PS','OutlierAnalysisSitePostCrusherStockpileDelta')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Fe_PS','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Fe_PS_MT','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Grade_PS','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Grade_PS_MT','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Tonnes_PS','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('StockpileToCrusher_Tonnes_PS_MT','OutlierAnalysisStockpileToCrusher')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Fe_PS','OutlierAnalysisF15FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Grade_PS','OutlierAnalysisF15FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F15Factor_Tonnes_PS','OutlierAnalysisF15FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Fe_PS','OutlierAnalysisF1FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Grade_PS','OutlierAnalysisF1FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F1Factor_Tonnes_PS','OutlierAnalysisF1FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Fe_PS','OutlierAnalysisF25FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Grade_PS','OutlierAnalysisF25FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F25Factor_Tonnes_PS','OutlierAnalysisF25FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2DensityFactor_Tonnes_PS','OutlierAnalysisF2DensityFactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Fe_PS','OutlierAnalysisF2FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Grade_PS','OutlierAnalysisF2FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F2Factor_Tonnes_PS','OutlierAnalysisF2FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Fe_PS','OutlierAnalysisF3FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Grade_PS','OutlierAnalysisF3FactorOnly')
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) VALUES ('F3Factor_Tonnes_PS','OutlierAnalysisF3FactorOnly')
GO


INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF1Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisGradeControlModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF1Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF15Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisGradeControlModelSTGM' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF15Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisShortTermGeologyModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisGradeControlModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisActualMined' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisF2DensityFactor' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMineProductionActuals' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMineProductionExpitEqulivent' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisExPitToOreStockpile' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF2Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisStockpileToCrusher' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModelOreForRailEquivalent' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisOreForRail' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModelCrusherEquivalent' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisExPitToOreStockpile' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisStockpileToCrusher' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMineProductionActuals' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisBeneRatio' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisSitePostCrusherStockpileDelta' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF25Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisHubPostCrusherStockpileDelta' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisPortStockpileDelta' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisPortBlendedAdjustment' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisOreShipped' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModelShippingEquivalent' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModelCrusherEquivalent' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMiningModel' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisExPitToOreStockpile' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisStockpileToCrusher' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisMineProductionActuals' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisBeneRatio' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisSitePostCrusherStockpileDelta' AND NOT stgm.SeriesTypeId like '%Factor%'
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId) SELECT stgm.SeriesTypeId,'OutlierAnalysisF3Factor' FROM DataSeries.SeriesTypeGroupMembership stgm WHERE stgm.SeriesTypeGroupId = 'OutlierAnalysisHubPostCrusherStockpileDelta' AND NOT stgm.SeriesTypeId like '%Factor%'
GO
