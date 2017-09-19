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
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Undef', -9, '#BEBEBE')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Fresh', 0, '#8EB2E2')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Trans', 1, '#FDD4B6')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('H-Cap', 2, '#E36C08')
INSERT INTO [dbo].[BhpbioWeathering] ([Description], [DisplayValue], [Colour]) VALUES ('Silcrete', 3, '#FFF2CC')
GO
