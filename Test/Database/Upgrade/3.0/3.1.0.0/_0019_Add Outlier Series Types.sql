

/*	FIRST STEP -- DELETE ANY EXISTING DATA */

	-- delete points from the related series
	DELETE sp 
	FROM DataSeries.Series s
	INNER JOIN DataSeries.SeriesPoint sp ON sp.SeriesId = s.Id
	INNER JOIN DataSeries.Series relatedSeries ON relatedSeries.Id = s.PrimaryRelatedSeriesId
	INNER JOIN DataSeries.SeriesType st ON st.Id = relatedSeries.SeriesTypeId
	INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
	WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'

	-- delete points from the primary series
	DELETE sp 
	FROM DataSeries.Series s
	INNER JOIN DataSeries.SeriesPoint sp ON sp.SeriesId = s.Id
	INNER JOIN DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
	INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
	WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'

	-- delete the attributes of the related series
	DELETE satt
	FROM DataSeries.Series s
	INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id
	INNER JOIN DataSeries.Series relatedSeries ON relatedSeries.Id = s.PrimaryRelatedSeriesId
	INNER JOIN DataSeries.SeriesType st ON st.Id = relatedSeries.SeriesTypeId
	INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
	WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'

	-- delete that attributes of the primary series
	DELETE satt
	FROM DataSeries.Series s
	INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id
	INNER JOIN DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
	INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
	WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'

	-- delete the related series type group memberships
	DELETE sg
	FROM
		(
		SELECT DISTINCT s.SeriesTypeId
		FROM DataSeries.Series s
		INNER JOIN DataSeries.Series relatedSeries ON relatedSeries.Id = s.PrimaryRelatedSeriesId
		INNER JOIN DataSeries.SeriesType st ON st.Id = relatedSeries.SeriesTypeId
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
		WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		) stypes
	INNER JOIN DataSeries.SeriesTypeGroupMembership sg ON sg.SeriesTypeId = stypes.SeriesTypeId

	-- delete the related series
	DELETE s 
	FROM DataSeries.Series s
	INNER JOIN DataSeries.Series relatedSeries ON relatedSeries.Id = s.PrimaryRelatedSeriesId
	INNER JOIN DataSeries.SeriesType st ON st.Id = relatedSeries.SeriesTypeId
	INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id
	WHERE gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'

	-- delete the primary series type group memberships
	DELETE sg
	FROM
		DataSeries.SeriesType st
		INNER JOIN DataSeries.SeriesTypeGroupMembership sg ON sg.SeriesTypeId = st.Id
	WHERE (st.Id like 'SITE_%' OR st.Id like 'HUB_%' OR st.Id like 'PIT_%' OR st.Id like 'WAIO_%' OR st.Name like '%by Hub%' OR st.Name like '%by Location%' OR st.Name like '%by Pit%' OR st.Name like '%by weightometer%' OR st.Name like '% (Density)%')
	
	-- delete the primary series
	DELETE s 
	FROM DataSeries.Series s
	INNER JOIN DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
	WHERE (st.Id like 'SITE_%' OR st.Id like 'HUB_%' OR st.Id like 'PIT_%' OR st.Id like 'WAIO_%' OR st.Name like '%by Hub%' OR st.Name like '%by Location%' OR st.Name like '%by Pit%' OR st.Name like '%by weightometer%' OR st.Name like '% (Density)%')

	-- delete the series type attributes
	DELETE satt
	FROM DataSeries.SeriesType st
	INNER JOIN DataSeries.SeriesTypeAttribute satt ON satt.SeriesTypeId = st.Id
	WHERE (st.Id like 'SITE_%' OR st.Id like 'HUB_%' OR st.Id like 'PIT_%' OR st.Id like 'WAIO_%' OR st.Name like '%by Hub%' OR st.Name like '%by Location%' OR st.Name like '%by Pit%' OR st.Name like '%by weightometer%' OR st.Name like '% (Density)%')

	-- delete the series types
	DELETE st
	FROM DataSeries.SeriesType st
	WHERE (st.Id like 'SITE_%' OR st.Id like 'HUB_%' OR st.Id like 'PIT_%' OR st.Id like 'WAIO_%' OR st.Name like '%by Hub%' OR st.Name like '%by Location%' OR st.Name like '%by Pit%' OR st.Name like '%by weightometer%' OR st.Name like '% (Density)%')

	GO

/* SECOND STEP - Insert Series Types -- */
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Fe_PS', N'BeneRatio Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Fe_PS_MT', N'BeneRatio Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Grade_PS', N'BeneRatio Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Grade_PS_MT', N'BeneRatio Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Tonnes_PS', N'BeneRatio Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'BeneRatio Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'ExPitToOreStockpile Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'ExPitToOreStockpile Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'ExPitToOreStockpile Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'ExPitToOreStockpile Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'ExPitToOreStockpile Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'ExPitToOreStockpile Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F15Factor_Fe_PS', N'F15Factor Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F15Factor_Grade_PS', N'F15Factor Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F15Factor_Tonnes_PS', N'F15Factor Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F1Factor_Fe_PS', N'F1Factor Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F1Factor_Grade_PS', N'F1Factor Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F1Factor_Tonnes_PS', N'F1Factor Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F25Factor_Fe_PS', N'F25Factor Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F25Factor_Grade_PS', N'F25Factor Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F25Factor_Tonnes_PS', N'F25Factor Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F2Factor_Fe_PS', N'F2Factor Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F2Factor_Grade_PS', N'F2Factor Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F2Factor_Tonnes_PS', N'F2Factor Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F3Factor_Fe_PS', N'F3Factor Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F3Factor_Grade_PS', N'F3Factor Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F3Factor_Tonnes_PS', N'F3Factor Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Fe_PS', N'GeologyModel Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Fe_PS_MT', N'GeologyModel Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Grade_PS', N'GeologyModel Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Grade_PS_MT', N'GeologyModel Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Tonnes_PS', N'GeologyModel Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'GeologyModel Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Fe_PS', N'GradeControlModel Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Fe_PS_MT', N'GradeControlModel Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Grade_PS', N'GradeControlModel Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Grade_PS_MT', N'GradeControlModel Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Tonnes_PS', N'GradeControlModel Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'GradeControlModel Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Fe_PS', N'GradeControlSTGM Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'GradeControlSTGM Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Grade_PS', N'GradeControlSTGM Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'GradeControlSTGM Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'GradeControlSTGM Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'GradeControlSTGM Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'HubPostCrusherStockpileDelta Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'HubPostCrusherStockpileDelta Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'HubPostCrusherStockpileDelta Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Fe_PS', N'MineProductionActuals Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'MineProductionActuals Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Grade_PS', N'MineProductionActuals Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'MineProductionActuals Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Tonnes_PS', N'MineProductionActuals Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'MineProductionActuals Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'MineProductionExpitEqulivent Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'MineProductionExpitEqulivent Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'MineProductionExpitEqulivent Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'MineProductionExpitEqulivent Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'MineProductionExpitEqulivent Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'MineProductionExpitEqulivent Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Fe_PS', N'MiningModel Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Fe_PS_MT', N'MiningModel Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Grade_PS', N'MiningModel Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Grade_PS_MT', N'MiningModel Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Tonnes_PS', N'MiningModel Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModel_Tonnes_PS_MT', N'MiningModel Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'MiningModelCrusherEquivalent Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'MiningModelCrusherEquivalent Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'MiningModelCrusherEquivalent Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'MiningModelCrusherEquivalent Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'MiningModelCrusherEquivalent Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'MiningModelCrusherEquivalent Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'MiningModelOreForRailEquivalent Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'MiningModelOreForRailEquivalent Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'MiningModelOreForRailEquivalent Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'MiningModelShippingEquivalent Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'MiningModelShippingEquivalent Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'MiningModelShippingEquivalent Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreForRail_Fe_PS', N'OreForRail Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreForRail_Grade_PS', N'OreForRail Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreForRail_Tonnes_PS', N'OreForRail Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreShipped_Fe_PS', N'OreShipped Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreShipped_Grade_PS', N'OreShipped Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'OreShipped_Tonnes_PS', N'OreShipped Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'PortBlendedAdjustment Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'PortBlendedAdjustment Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'PortBlendedAdjustment Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortStockpileDelta_Fe_PS', N'PortStockpileDelta Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortStockpileDelta_Grade_PS', N'PortStockpileDelta Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'PortStockpileDelta Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'PostCrusherStockpileDelta Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'PostCrusherStockpileDelta Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'PostCrusherStockpileDelta Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'ShortTermGeologyModel Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'ShortTermGeologyModel Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'ShortTermGeologyModel Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'ShortTermGeologyModel Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'ShortTermGeologyModel Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'ShortTermGeologyModel Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'SitePostCrusherStockpileDelta Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'SitePostCrusherStockpileDelta Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'SitePostCrusherStockpileDelta Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Fe_PS', N'StockpileToCrusher Fe by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'StockpileToCrusher Fe by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Grade_PS', N'StockpileToCrusher Grade by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'StockpileToCrusher Grade by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'StockpileToCrusher Tonnes by Location and Product Size', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'StockpileToCrusher Tonnes by Location, Product Size and Material Type', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'F2DensityFactor_Tonnes_PS', N'F2 (Density) - Total Hauled / Grade Control Model by Location', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'Recovery Factor (Density) - Total Hauled / Mining Model by Location', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'ActualMined_Tonnes_PS', N'Total Hauled ''H'' Value by Location', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'Weightometer_Tonnes_PS', N'Total tonnes moved by weightometer', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'Weightometer_Fe_PS', N'Fe value by weightometer', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'Weightometer_Grade_PS', N'Grade value by weightometer', 0, 1)
GO
INSERT [DataSeries].[SeriesType] ([Id], [Name], [IsDependant], [IsActive]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'Ratio of Haulage to Ore vs Haulage to Non-Ore Locations by Pit', 0, 1)
GO

/* Third Step - Add Group Memberships */
-- Add the Series Types to the Outlier Group
INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId, SeriesTypeGroupId)
SELECT st.Id, 'OutlierSeriesTypeGroup'
FROM DataSeries.SeriesType st
	LEFT JOIN DataSeries.SeriesTypeGroupMembership existG ON existG.SeriesTypeId = st.Id AND existG.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
WHERE existG.SeriesTypeId IS NULL AND (st.Name like '%by Location%' OR st.Name like '%by weightometer%' OR st.Name like '% (Density)%' OR st.Name like '%by Pit%')
GO

/* Fourth Step - Add Attributes */
-- Series Type Attributes excluding Outlier

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_Description', N'BeneRatio Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'ByProductSize', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_Description', N'BeneRatio Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_Description', N'BeneRatio Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_Description', N'BeneRatio Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_Description', N'BeneRatio Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'CalculationId', N'BeneRatio', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'BeneRatio Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'BeneRatio_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'CalculationId', N'ExPitToOreStockpile', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'ExPitToOreStockpile Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ExPitToOreStockpile_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'CalculationId', N'F15Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_Description', N'F15Factor Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_Priority', NULL, 2, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'CalculationId', N'F15Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_Description', N'F15Factor Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_Priority', NULL, 3, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'CalculationId', N'F15Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_Description', N'F15Factor Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 1, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F15Factor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'CalculationId', N'F1Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_Description', N'F1Factor Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_Priority', NULL, 2, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'CalculationId', N'F1Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_Description', N'F1Factor Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_Priority', NULL, 3, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'CalculationId', N'F1Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_Description', N'F1Factor Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 1, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F1Factor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'CalculationId', N'F25Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_Description', N'F25Factor Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_Priority', NULL, 2, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'CalculationId', N'F25Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_Description', N'F25Factor Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_Priority', NULL, 3, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'CalculationId', N'F25Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_Description', N'F25Factor Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 1, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F25Factor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'CalculationId', N'F2Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_Description', N'F2Factor Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_Priority', NULL, 2, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'CalculationId', N'F2Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_Description', N'F2Factor Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_Priority', NULL, 3, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'CalculationId', N'F2Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_Description', N'F2Factor Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 1, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2Factor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'CalculationId', N'F3Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_Description', N'F3Factor Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_Priority', NULL, 2, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'CalculationId', N'F3Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_Description', N'F3Factor Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_Priority', NULL, 3, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'CalculationId', N'F3Factor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_Description', N'F3Factor Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 1, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'RollingAverage', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F3Factor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_Description', N'GeologyModel Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_Description', N'GeologyModel Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_Description', N'GeologyModel Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_Description', N'GeologyModel Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_Description', N'GeologyModel Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'CalculationId', N'GeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'GeologyModel Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GeologyModel_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_Description', N'GradeControlModel Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_Description', N'GradeControlModel Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_Description', N'GradeControlModel Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_Description', N'GradeControlModel Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_Description', N'GradeControlModel Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'CalculationId', N'GradeControlModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'GradeControlModel Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlModel_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_Description', N'GradeControlSTGM Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_Description', N'GradeControlSTGM Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_Description', N'GradeControlSTGM Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_Description', N'GradeControlSTGM Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_Description', N'GradeControlSTGM Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'CalculationId', N'GradeControlSTGM', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'GradeControlSTGM Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'GradeControlSTGM_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'CalculationId', N'HubPostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Description', N'HubPostCrusherStockpileDelta Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'CalculationId', N'HubPostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Description', N'HubPostCrusherStockpileDelta Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'CalculationId', N'HubPostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Description', N'HubPostCrusherStockpileDelta Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HubPostCrusherStockpileDelta_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_Description', N'MineProductionActuals Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_Description', N'MineProductionActuals Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_Description', N'MineProductionActuals Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_Description', N'MineProductionActuals Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_Description', N'MineProductionActuals Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'CalculationId', N'MineProductionActuals', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'MineProductionActuals Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionActuals_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'CalculationId', N'MineProductionExpitEqulivent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'MineProductionExpitEqulivent Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MineProductionExpitEqulivent_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_Description', N'MiningModel Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_Description', N'MiningModel Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_Description', N'MiningModel Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_Description', N'MiningModel Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_Description', N'MiningModel Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'CalculationId', N'MiningModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'MiningModel Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModel_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'CalculationId', N'MiningModelCrusherEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'MiningModelCrusherEquivalent Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelCrusherEquivalent_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'CalculationId', N'MiningModelOreForRailEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_Description', N'MiningModelOreForRailEquivalent Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'CalculationId', N'MiningModelOreForRailEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_Description', N'MiningModelOreForRailEquivalent Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'CalculationId', N'MiningModelOreForRailEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_Description', N'MiningModelOreForRailEquivalent Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelOreForRailEquivalent_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'CalculationId', N'MiningModelShippingEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_Description', N'MiningModelShippingEquivalent Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'CalculationId', N'MiningModelShippingEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_Description', N'MiningModelShippingEquivalent Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'CalculationId', N'MiningModelShippingEquivalent', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_Description', N'MiningModelShippingEquivalent Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'MiningModelShippingEquivalent_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'CalculationId', N'OreForRail', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_Description', N'OreForRail Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'CalculationId', N'OreForRail', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_Description', N'OreForRail Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'CalculationId', N'OreForRail', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_Description', N'OreForRail Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreForRail_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'CalculationId', N'OreShipped', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_Description', N'OreShipped Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'CalculationId', N'OreShipped', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_Description', N'OreShipped Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'CalculationId', N'OreShipped', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_Description', N'OreShipped Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'OreShipped_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'CalculationId', N'PortBlendedAdjustment', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_Description', N'PortBlendedAdjustment Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'CalculationId', N'PortBlendedAdjustment', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_Description', N'PortBlendedAdjustment Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'CalculationId', N'PortBlendedAdjustment', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_Description', N'PortBlendedAdjustment Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortBlendedAdjustment_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'CalculationId', N'PortStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_Description', N'PortStockpileDelta Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'CalculationId', N'PortStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_Description', N'PortStockpileDelta Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'CalculationId', N'PortStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Description', N'PortStockpileDelta Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PortStockpileDelta_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'CalculationId', N'PostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Description', N'PostCrusherStockpileDelta Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'CalculationId', N'PostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Description', N'PostCrusherStockpileDelta Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'CalculationId', N'PostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Description', N'PostCrusherStockpileDelta Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'PostCrusherStockpileDelta_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'CalculationId', N'ShortTermGeologyModel', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'ShortTermGeologyModel Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ShortTermGeologyModel_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'CalculationId', N'SitePostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Description', N'SitePostCrusherStockpileDelta Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'CalculationId', N'SitePostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Description', N'SitePostCrusherStockpileDelta Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'CalculationId', N'SitePostCrusherStockpileDelta', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'LocationType', N'Hub and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Description', N'SitePostCrusherStockpileDelta Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'SitePostCrusherStockpileDelta_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_Description', N'StockpileToCrusher Fe by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_Description', N'StockpileToCrusher Fe by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_Priority', NULL, 5, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Fe_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_Description', N'StockpileToCrusher Grade by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_Description', N'StockpileToCrusher Grade by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_Priority', NULL, 6, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Grade_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_Description', N'StockpileToCrusher Tonnes by HUB and Product Size', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'ByMaterialType', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'CalculationId', N'StockpileToCrusher', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteEnd', NULL, NULL, NULL, CAST(N'2060-01-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_AbsoluteStart', NULL, NULL, NULL, CAST(N'2009-04-01 00:00:00.000' AS DateTime), NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_Description', N'StockpileToCrusher Tonnes by HUB, Product Size and Material Type', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_IsActive', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_MinimumDataPoints', NULL, 12, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_OutlierThreshold', NULL, NULL, NULL, NULL, 3)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_Priority', NULL, 4, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_ProjectedValueMethod', N'LinearProjection', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierConfiguration_RollingSeriesSize', NULL, 24, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'OutlierProcessRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.OutlierDetectionProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'StockpileToCrusher_Tonnes_PS_MT', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO


INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'ByProductSize', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'CalculationId', N'F2DensityFactor', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'F2DensityFactor_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'ByProductSize', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'CalculationId', N'RecoveryFactorDensity', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'RecoveryFactorDensity_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO


INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'CalculationId', N'ActualMined', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'LocationType', N'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'ActualMined_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.ReportSeriesDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO


INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'LocationType', 'Site and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Tonnes_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.WeightometerDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'Attribute', N'Fe', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'LocationType', 'Site and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Fe_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.WeightometerDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'Attribute', N'Grade', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'ByGrade', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'ByProductSize', NULL, NULL, 1, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'LocationType', 'Site and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'Weightometer_Grade_PS', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.WeightometerDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO

INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'Attribute', N'Tonnes', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'ByGrade', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'ByMaterialType', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'ByProductSize', NULL, NULL, 0, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'DataRetrievalRequest_ProcessorFullyQualifiedName', N'Snowden.Consulting.DataSeries.Processing.PointRetrievalProcessor, Snowden.Consulting.DataSeries.Processing', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'LocationType', 'Pit and above', NULL, NULL, NULL, NULL)
GO
INSERT [DataSeries].[SeriesTypeAttribute] ([SeriesTypeId], [Name], [StringValue], [IntegerValue], [BooleanValue], [DateTimeValue], [DoubleValue]) VALUES (N'HaulageToOreVsNonOre_Tonnes', N'RetrieverFullyQualifiedName', N'Snowden.Reconcilor.Bhpbio.DataSeries.HaulageToOreVsNonOreDataRetriever, Snowden.Reconcilor.Bhpbio.DataSeries', NULL, NULL, NULL, NULL)
GO


-- STEP 5 Delete existing outliner configuration
DELETE satt 
FROM DataSeries.SeriesTypeAttribute satt WHERE Name like 'OutlierConfiguration%'
GO

-- STEP 6 insert default configuration
INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue, IntegerValue, BooleanValue, DateTimeValue, DoubleValue)

		SELECT st.Id, 'OutlierConfiguration_AbsoluteEnd',null, null, null,  '2060-01-01 00:00:00.000', null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_AbsoluteStart',null, null, null,  '2009-04-01 00:00:00.000', null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_Description',st.Name, null, null, null,  null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_IsActive',null, null, 1, null, null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_MinimumDataPoints',null, 12, null, null, null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_OutlierThreshold',null, null, null, null, 3
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_Priority',null,  
			CASE WHEN st.Id like '%Factor%Tonnes%' THEN 1
				WHEN st.Id like '%Factor%Fe%' THEN 2
				WHEN st.Id like '%Factor%Grade%' THEN 3
				WHEN st.Id like '%Tonnes%' THEN 4
				WHEN st.Id like '%Fe%' THEN 5
				WHEN st.Id like '%Grade%' THEN 6
			ELSE 7
			END as Priority
			, null, null, null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_ProjectedValueMethod',
			-- for all tonnes series that are not factor series..linear projection.. for all else, rolling average
			CASE WHEN st.Id like '%Tonnes%' AND NOT st.Id like '%Factor%'  THEN 'LinearProjection' ELSE 'RollingAverage' END,
			null, null, null, null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
		
		UNION ALL
		
		SELECT st.Id, 'OutlierConfiguration_RollingSeriesSize',null, 24, null, null, null
		FROM DataSeries.SeriesType st 
			INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = st.Id and gm.SeriesTypeGroupId = 'OutlierSeriesTypeGroup'
GO
