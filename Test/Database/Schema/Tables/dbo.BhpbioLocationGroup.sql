CREATE TABLE [dbo].[BhpbioLocationGroup]
( 
  [LocationGroupId]			INT			NOT NULL IDENTITY,
  [ParentLocationId]		INT			NOT NULL,
  [LocationGroupTypeName]	VARCHAR(31)	NOT NULL,
  [Name]					VARCHAR(31)	NOT NULL UNIQUE,
  [CreatedDate]				DATETIME	NOT NULL,
  CONSTRAINT [PK_BhpioLocationGroup] PRIMARY KEY CLUSTERED
  (
	[LocationGroupId] ASC
  )
)
GO