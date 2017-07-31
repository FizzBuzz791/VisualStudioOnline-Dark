-- each RC / Model Block combination should only appear once

CREATE UNIQUE NONCLUSTERED INDEX [unique_BlockModelId_ResourceClassification] ON [Staging].[StageBlockModelResourceClassification] 
(
	[BlockModelId] ASC,
	[ResourceClassification] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

GO


