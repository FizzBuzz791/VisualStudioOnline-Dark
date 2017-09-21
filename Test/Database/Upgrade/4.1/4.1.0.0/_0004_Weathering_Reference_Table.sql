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
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Undef', -9, '#BFBFBF')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Fresh', 0, '#B3DE68')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Trans', 1, '#FAB636')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('H-Cap', 2, '#E65400')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Silcrete', 3, '#FDE2AF')
GO
