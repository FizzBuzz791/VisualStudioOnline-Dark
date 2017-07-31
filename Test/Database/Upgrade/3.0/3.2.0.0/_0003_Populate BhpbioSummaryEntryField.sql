SET IDENTITY_INSERT  dbo.BhpbioSummaryEntryField ON

INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
VALUES (1, 'ResourceClassification1', 'ResourceClassification')

INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
VALUES (2, 'ResourceClassification2', 'ResourceClassification')

INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
VALUES (3, 'ResourceClassification3', 'ResourceClassification')

INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
VALUES (4, 'ResourceClassification4', 'ResourceClassification')

-- this will never be present in the field value table, but it is required in order to make the 
-- the joins work properly when getting the RC breakdown
INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
VALUES (5, 'ResourceClassificationUnknown', 'ResourceClassification')

GO

SET IDENTITY_INSERT  dbo.BhpbioSummaryEntryField OFF