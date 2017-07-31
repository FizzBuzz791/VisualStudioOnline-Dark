DELETE FROM [dbo].[MetBalancingGrade]
GO
DELETE FROM [dbo].[MetBalancing]
GO
DELETE FROM [dbo].[PortBalanceGrade]
GO
DELETE FROM [dbo].[PortBalance]
GO
DELETE FROM [dbo].[PortBlendingGrade]
GO
DELETE FROM [dbo].[PortBlending]
GO
DELETE FROM [dbo].[ShippingNominationItemHubGrade]
GO
DELETE FROM [dbo].[ShippingNominationItemHub]
GO
DELETE FROM [dbo].[ShippingNominationItem]
GO
DELETE FROM [dbo].[ShippingNomination]
GO

--Covers test case "Port Balances - INSERT": Step 1
INSERT INTO [dbo].[PortBalance]
(
	Hub, BalanceDate, Tonnes, TargetProduct, ProductSize
)
SELECT 'MAC', '2013-08-31 16:00', 416033, 'NHGZ', 'LUMP' UNION ALL -- AreaC hub
SELECT 'YND', '2013-08-31 16:00', 453664, 'NHGZ', 'LUMP' UNION ALL -- Yandi hub
SELECT 'NHG', '2013-08-31 16:00', 968420, 'NHGZ', 'LUMP' UNION ALL -- NJV hub
SELECT 'JMB', '2013-08-31 16:00', 358420, 'NHGZ', 'LUMP' -- Jimblebar hub
GO

INSERT INTO [dbo].[PortBalanceGrade]
(
	PortBalanceId, GradeName, HeadValue
)
SELECT PortBalanceId, 'H2O', 4.79 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'Fe', 58.37 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'P', 0.0552 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'SiO2', 7.0 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'Al2O3', 3.85 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'LOI', 54.77 FROM [dbo].[PortBalance] UNION ALL
SELECT PortBalanceId, 'GradeToIgnore', 358.36 FROM [dbo].[PortBalance]
GO

--Covers test case "MET Balancing - INSERT": Step 1
INSERT INTO [dbo].[MetBalancing]
(
	[Site], [StartDate], [EndDate], [PlantName], [StreamName], [Weightometer], [ProductSize], [DryTonnes], [WetTonnes], [SplitCycle], [SplitPlant]
)
SELECT 'WB Bene', '2013-08-01 06:00:00', '2013-08-02 05:59:59', 'Cyclones', 'Cyclone Product (M227)', '227', 'LUMP', 16.3081, 17.9278, 45.8745, 15.7892 UNION ALL
SELECT 'WB Bene', '2013-07-01 06:00:00', '2013-07-02 05:59:59', 'Desliming', 'Slimes to Thickener', 'Thick to tail', 'FINES', 2.789, NULL, 0.0125, 0.0001
GO

INSERT INTO [dbo].[MetBalancingGrade]
(
	MetBalancingId, GradeName, HeadValue
)
SELECT MetBalancingId, 'Fe', 58.37 FROM [dbo].[MetBalancing] UNION ALL
SELECT MetBalancingId, 'P', 0.0552 FROM [dbo].[MetBalancing] UNION ALL
SELECT MetBalancingId, 'SiO2', 7.0 FROM [dbo].[MetBalancing] UNION ALL
SELECT MetBalancingId, 'Al2O3', 3.85 FROM [dbo].[MetBalancing] UNION ALL
SELECT MetBalancingId, 'LOI', 54.77 FROM [dbo].[MetBalancing] UNION ALL
SELECT MetBalancingId, 'GradeToIgnore', 358.36 FROM [dbo].[MetBalancing]
GO

-- Covers test case "Port Blending - INSERT": Step 1
INSERT INTO [dbo].[PortBlending]
(
	[SourceHub], [DestinationHub], [StartDate], [EndDate], [LoadSites], [SourceProduct], [DestinationProduct], [SourceProductSize], [DestinationProductSize], [Tonnes]
)
SELECT 'MAC', 'MAC', '2013-08-01 06:00:00', '2013-08-02 05:59:59', 'AC', 'GWYF', 'ZEYF', 'FINES', 'LUMP', 1675.3081 UNION ALL
SELECT 'YND', 'YND', '2013-08-02 06:00:00', '2013-08-03 05:59:59', 'YD', 'ZEYF', 'GWYG', 'LUMP', 'FINES', 2754.789 UNION ALL
SELECT 'NHG', 'NHG', '2013-08-03 06:00:00', '2013-08-04 05:59:59', 'MW', 'ZEYF', 'GWYG', 'LUMP', 'FINES', 2754.789
GO

INSERT INTO [dbo].[PortBlendingGrade]
(
	PortBlendingId, GradeName, HeadValue
)
SELECT PortBlendingId, 'H2O', 4.77 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'Fe', 58.37 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'P', 0.0552 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'SiO2', 7.0 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'Al2O3', 3.85 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'LOI', 54.77 FROM [dbo].[PortBlending] UNION ALL
SELECT PortBlendingId, 'GradeToIgnore', 358.36 FROM [dbo].[PortBlending]
GO


Declare @Id Int

-- One complete record with grades
Insert Into dbo.ShippingNomination
(
	NominationKey, VesselName
)
Select '123456', 'Iron Ore Titanic'

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItem
(
	ShippingNominationId, ItemNo, CustomerNo, CustomerName, LastAuthorisedDate, OfficialFinishTime, Oversize, Undersize, COA, ShippedProduct, ShippedProductSize
)
Select @Id, '10', '333777', 'JIANGSU SHAGANG GROUP COMPANY LTD', '2014-08-01', '2014-08-01 08:34:23', 28.32, 5.54, '2014-08-02  10:45:43', 'JMBF', 'FINES'

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItemHub
(
	Hub, HubProduct, HubProductSize, Tonnes, ShippingNominationItemId
)
Select 'JMB', 'JMBF', 'FINES', 1234.56, @Id

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItemHubGrade
(
	ShippingNominationItemHubId, GradeName, FinesValue, HeadValue, LumpValue, SampleValue
)
Select @Id, 'Fe', 63.25, 63.25, 63.25, 63.25 Union All
Select @Id, 'P', 0.987, 0.987, 0.987, 0.987 Union All
Select @Id, 'SiO2', 3.333, 3.333, 3.333, 3.333 Union All
Select @Id, 'Al2O3', 2.221, 2.221, 2.221, 2.221 Union All
Select @Id, 'LOI', 5.578, 5.578, 5.578, 5.578 Union All
Select @Id, 'H2O', 6.74, 6.74, 6.74, 6.74


-- Second complete record with grades
Insert Into dbo.ShippingNomination
(
	NominationKey, VesselName
)
Select '654321', 'Big Dream Goodbye'

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItem
(
	ShippingNominationId, ItemNo, CustomerNo, CustomerName, LastAuthorisedDate, OfficialFinishTime, Oversize, Undersize, COA, ShippedProduct, ShippedProductSize
)
Select @Id, '10', '333777', 'DE JA VU CORPORATION LTD', '2014-08-02', '2014-08-02 18:21:59', 28.32, 5.54, '2014-08-03  13:41:14', 'MACF', 'FINES'

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItemHub
(
	Hub, HubProduct, HubProductSize, Tonnes, ShippingNominationItemId
)
Select 'MAC', 'MACF', 'FINES', 7777.77, @Id

Set @Id = SCOPE_IDENTITY()

Insert Into dbo.ShippingNominationItemHubGrade
(
	ShippingNominationItemHubId, GradeName, FinesValue, HeadValue, LumpValue, SampleValue
)
Select @Id, 'Fe', 65.25, 65.25, 65.25, 65.25 Union All
Select @Id, 'P', 0.876, 0.876, 0.876, 0.876 Union All
Select @Id, 'SiO2', 4.444, 4.444, 4.444, 4.444 Union All
Select @Id, 'Al2O3', 3.1, 3.1, 3.1, 3.1 Union All
Select @Id, 'LOI', 4.578, 4.578, 4.578, 4.578 Union All
Select @Id, 'H2O', 5.247, 5.247, 5.247, 5.247