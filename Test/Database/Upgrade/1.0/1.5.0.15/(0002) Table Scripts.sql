If Object_id('dbo.BhpbioLocationOverride') Is Not Null 
     Drop Table dbo.BhpbioLocationOverride
GO 

CREATE TABLE [dbo].[BhpbioLocationOverride](
	[Location_Override_Id]	INT IDENTITY(1,1) NOT NULL,
	[Location_Id]			INT			NOT NULL,
	[Location_Type_Id]		TINYINT		NOT NULL,
	[Parent_Location_Id]	INT			NULL,
	[FromMonth]				DATETIME	NULL,
	[ToMonth]				DATETIME	NULL,
 CONSTRAINT [PK_LOCATION_OVERRIDE] PRIMARY KEY CLUSTERED 
(
	[Location_Override_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'The unique identifier of this location override.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'Location_Override_Id'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'The location identifer to provide overriden hierarchy mappings.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'Location_Id'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'The type of location as defined in LocationType.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'Location_Type_Id'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'If this location is a non-root member of a hierarchy, then the parent is listed here.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'Parent_Location_Id'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'The starting month that a location is re-parented for.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'FromMonth'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'The ending month that a location is re-parented for.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride', @level2type=N'COLUMN',@level2name=N'ToMonth'
GO

EXEC sys.sp_addextendedproperty @name=N'DD_Description', @value=N'Stores date centric override of hierarchical location information.  Contains entries for period of time that a location is re-parented' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BhpbioLocationOverride'
GO

ALTER TABLE [dbo].[BhpbioLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK1_BHPBIOLOCATIONOVERRIDE] FOREIGN KEY([Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationOverride] CHECK CONSTRAINT [FK1_BHPBIOLOCATIONOVERRIDE]
GO

ALTER TABLE [dbo].[BhpbioLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK2_BHPBIOLOCATIONOVERRIDE] FOREIGN KEY([Location_Type_Id])
REFERENCES [dbo].[LocationType] ([Location_Type_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationOverride] CHECK CONSTRAINT [FK2_BHPBIOLOCATIONOVERRIDE]
GO

ALTER TABLE [dbo].[BhpbioLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK3_BHPBIOLOCATIONOVERRIDE] FOREIGN KEY([Parent_Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationOverride] CHECK CONSTRAINT [FK3_BHPBIOLOCATIONOVERRIDE]
GO


If Object_id('dbo.BhpbioLocationDate') Is Not Null 
     Drop Table dbo.BhpbioLocationDate
GO 

CREATE TABLE [dbo].[BhpbioLocationDate](
	[Location_Id]			INT			NOT NULL,
	[Period_Order]			INT			NOT NULL,
	[Location_Type_Id]		TINYINT		NOT NULL,
	[Parent_Location_Id]	INT			NULL,
	[Start_Date]			DATETIME	NOT NULL,
	[End_Date]				DATETIME	NULL,
	[Is_Override]			BIT			NOT NULL,
	[Date_Created]			DATETIME	NOT NULL,
	CONSTRAINT [PK_LOCATION_DATE] PRIMARY KEY CLUSTERED 
(
	Location_Id, Period_Order
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_BhpbioLocationDate] ON [BhpbioLocationDate] 
(
	Parent_Location_Id ASC,
	Location_Id ASC
)

ALTER TABLE [dbo].[BhpbioLocationDate]  WITH CHECK ADD  CONSTRAINT [FK1_BHPBIOLOCATIONDATE] FOREIGN KEY([Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationDate] CHECK CONSTRAINT [FK1_BHPBIOLOCATIONDATE]
GO

ALTER TABLE [dbo].[BhpbioLocationDate]  WITH CHECK ADD  CONSTRAINT [FK2_BHPBIOLOCATIONDATE] FOREIGN KEY([Location_Type_Id])
REFERENCES [dbo].[LocationType] ([Location_Type_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationDate] CHECK CONSTRAINT [FK2_BHPBIOLOCATIONDATE]
GO

ALTER TABLE [dbo].[BhpbioLocationDate]  WITH CHECK ADD  CONSTRAINT [FK3_BHPBIOLOCATIONDATE] FOREIGN KEY([Parent_Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioLocationDate] CHECK CONSTRAINT [FK3_BHPBIOLOCATIONDATE]
GO

CREATE NONCLUSTERED INDEX [IX_Location_Date_Start_Date] ON [dbo].[BHPbioLocationDate] 
(
      [Start_Date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Location_Date_End_Date] ON [dbo].[BHPbioLocationDate] 
(
      [End_Date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[BhpbioStockpileLocationOverride]    ******/

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK1_STOCKPILE_LOCATION_OVERRIDE]') AND parent_object_id = OBJECT_ID(N'[dbo].[BhpbioStockpileLocationOverride]'))
ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] DROP CONSTRAINT [FK1_STOCKPILE_LOCATION_OVERRIDE]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK2_STOCKPILE_LOCATION_OVERRIDE]') AND parent_object_id = OBJECT_ID(N'[dbo].[BhpbioStockpileLocationOverride]'))
ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] DROP CONSTRAINT [FK2_STOCKPILE_LOCATION_OVERRIDE]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK3_STOCKPILE_LOCATION_OVERRIDE]') AND parent_object_id = OBJECT_ID(N'[dbo].[BhpbioStockpileLocationOverride]'))
ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] DROP CONSTRAINT [FK3_STOCKPILE_LOCATION_OVERRIDE]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioStockpileLocationOverride]') AND type in (N'U'))
DROP TABLE [dbo].[BhpbioStockpileLocationOverride]
GO



CREATE TABLE [dbo].[BhpbioStockpileLocationOverride](
	[Stockpile_Location_Override_Id]	INT IDENTITY(1,1) NOT NULL,
	[Stockpile_Id]						INT NOT NULL,
	[Location_Type_Id]					TINYINT NOT NULL,
	[Location_Id]						INT NOT NULL,
	[FromMonth]							DATETIME NOT NULL,
	[ToMonth]							DATETIME NULL,
 CONSTRAINT [PK_STOCKPILE_LOCATION_OVERRIDE_ID] PRIMARY KEY CLUSTERED 
(
	[Stockpile_Location_Override_Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[BhpbioStockpileLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK1_STOCKPILE_LOCATION_OVERRIDE] FOREIGN KEY([Stockpile_Id])
REFERENCES [dbo].[Stockpile] ([Stockpile_Id])
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] CHECK CONSTRAINT [FK1_STOCKPILE_LOCATION_OVERRIDE]
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK2_STOCKPILE_LOCATION_OVERRIDE] FOREIGN KEY([Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] CHECK CONSTRAINT [FK2_STOCKPILE_LOCATION_OVERRIDE]
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationOverride]  WITH CHECK ADD  CONSTRAINT [FK3_STOCKPILE_LOCATION_OVERRIDE] FOREIGN KEY([Location_Type_Id])
REFERENCES [dbo].[LocationType] ([Location_Type_Id])
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationOverride] CHECK CONSTRAINT [FK3_STOCKPILE_LOCATION_OVERRIDE]
GO


/*
	dbo.BhpbioStockpileLocationDate
*/

If Object_id('dbo.BhpbioStockpileLocationDate') Is Not Null 
     Drop Table dbo.BhpbioStockpileLocationDate
GO 


CREATE TABLE [dbo].[BhpbioStockpileLocationDate](
	[Stockpile_Id]			INT			NOT NULL,
	[Location_Id]			INT			NOT NULL,
	[Period_Order]			INT			NOT NULL,
	[Start_Date]			DATETIME	NOT NULL,
	[End_Date]				DATETIME	NULL,
	[Is_Override]			BIT			NOT NULL,
	[Date_Created]			DATETIME	NOT NULL,
	CONSTRAINT [PK_STOCKPILE_LOCATION_DATE] PRIMARY KEY CLUSTERED 
(
	Stockpile_Id,Location_Id, Period_Order
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_BhpbioStockpileLocationDate] ON [BhpbioStockpileLocationDate] 
(
	Location_Id ASC,
	Stockpile_Id ASC
)


ALTER TABLE [dbo].[BhpbioStockpileLocationDate]  WITH CHECK ADD  CONSTRAINT [FK1_BHPBIOSTOCKPILELOCATIONDATE] FOREIGN KEY([Stockpile_Id])
REFERENCES [dbo].[Stockpile] ([Stockpile_Id])
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationDate] CHECK CONSTRAINT [FK1_BHPBIOSTOCKPILELOCATIONDATE]
GO


ALTER TABLE [dbo].[BhpbioStockpileLocationDate]  WITH CHECK ADD  CONSTRAINT [FK2_BHPBIOSTOCKPILELOCATIONDATE] FOREIGN KEY([Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioStockpileLocationDate] CHECK CONSTRAINT [FK2_BHPBIOSTOCKPILELOCATIONDATE]
GO

CREATE NONCLUSTERED INDEX [IX_StockpileLocationStartDate] ON [dbo].[BhpbioStockpileLocationDate] 
(
      [Start_Date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_StockpileLocationEndDate] ON [dbo].[BhpbioStockpileLocationDate] 
(
      [End_Date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
