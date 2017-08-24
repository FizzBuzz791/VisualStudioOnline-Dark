IF OBJECT_ID('dbo.BhpbioWeathering') IS NOT NULL 
	DROP TABLE dbo.BhpbioWeathering
GO 

CREATE TABLE [dbo].[BhpbioWeathering]
(
	[Id] INT NOT NULL IDENTITY, 
	[Description] VARCHAR(100) NOT NULL, 
	[DisplayValue] int NOT NULL,
	[Colour] VARCHAR(25) NOT NULL,
	CONSTRAINT [PK_BhpbioWeathering] PRIMARY KEY CLUSTERED
	(
		[Id] ASC
	)
)

GO
CREATE NONCLUSTERED INDEX idx_BhpbioWeathering
ON dbo.[BhpbioWeathering]([DisplayValue])
GO
INSERT INTO [dbo].[SecurityOption] VALUES ('REC', 'UTILITIES_WEATHERING', 'Utilities', 'Access to Weathering Reference Screen', 99)
INSERT INTO [dbo].[SecurityRoleOption] VALUES ('REC_VIEW', 'REC', 'UTILITIES_WEATHERING')
GO
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Undefined', -9, 'Grey')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Fresh (UNALTERED)', 0, 'SandyBrown')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Transition (Transition/SEMICAP)', 1, 'Chocolate')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Weathered - HARDCAP', 2, 'SaddleBrown')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Ferricrete-Silicate (Carapace/Ferricrete)', 3, 'PeachPuff')
GO
