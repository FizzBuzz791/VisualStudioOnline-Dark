CREATE TABLE [dbo].[BhpbioWeathering]
(
	[Id] INT NOT NULL IDENTITY, 
    [Description] VARCHAR(100) NOT NULL, 
	[DisplayValue] int NOT NULL,
    [Colour] VARCHAR(25) NOT NULL,
	CONSTRAINT [PK_BhpbioWeathering] PRIMARY KEY CLUSTERED
	(
		[Id] ASC
	),
)

GO
CREATE NONCLUSTERED INDEX idx_BhpbioWeathering
ON dbo.[BhpbioWeathering]([DisplayValue])