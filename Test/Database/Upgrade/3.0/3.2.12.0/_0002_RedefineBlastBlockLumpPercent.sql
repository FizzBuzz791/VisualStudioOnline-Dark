BEGIN TRANSACTION
	-- copy the old data
	PRINT 'Copying existing Lump Percent data'

	SELECT * INTO dbo.BhpbioBlastBlockLumpPercent_Old FROM BhpbioBlastBlockLumpPercent

	PRINT 'Redefining Lump Percent table'

	-- drop the old definition
	DROP TABLE BhpbioBlastBlockLumpPercent
COMMIT TRANSACTION
GO

-- create the new definition
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioBlastBlockLumpPercent]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioBlastBlockLumpPercent]
	(
		[ModelBlockId] [int] NOT NULL,
		[SequenceNo] [int] NOT NULL,
		[LumpPercent] [decimal](7,6) NOT NULL, -- increase the size of this field to handle the precision provided for grade control blocks
		
		CONSTRAINT [PK_BhpbioBlastBlockLumpPercent]
			PRIMARY KEY CLUSTERED ([ModelBlockId] ASC, [SequenceNo] ASC),

		CONSTRAINT FK__BhpbioBlastBlockLumpPercent__MODEL_BLOCK FOREIGN KEY (ModelBlockId)
			REFERENCES dbo.ModelBlock (Model_Block_Id)
	)
END
GO

PRINT 'Populating Redefined table'

-- move the old data back into the new table definition
INSERT INTO [BhpbioBlastBlockLumpPercent](ModelBlockId, SequenceNo, LumpPercent)
SELECT mbp.Model_Block_Id, mbp.Sequence_No, o.LumpPercent
FROM ModelBlockPartial mbp
INNER JOIN dbo.BhpbioBlastBlockLumpPercent_Old o ON o.ModelBlockId = mbp.Model_Block_Id
GO

PRINT 'Population Complete'
GO