-- Big-ish index, but greatly improves the speed of the GetBhpbioApprovalSummary procedure, which is extremely useful for BulkApproval
SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [Haulage_SourceDigblock_Id_Date_ForApprovalSummary] ON [dbo].[Haulage]
(
	[Source_Digblock_Id] ASC,
	[Haulage_Id] ASC,
	[Haulage_Date] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO