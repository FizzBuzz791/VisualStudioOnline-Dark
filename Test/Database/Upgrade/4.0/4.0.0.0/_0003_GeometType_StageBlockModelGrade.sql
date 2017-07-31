ALTER TABLE Staging.StageBlockModelGrade
	ADD [GeometType] [varchar](15) NOT NULL DEFAULT('NA')
GO

ALTER TABLE Staging.StageBlockModelGrade
	DROP CONSTRAINT [PK_StageBlockModelGrade]
GO

INSERT INTO Staging.StageBlockModelGrade
(BlockModelId, GeometType, GradeName, GradeValue, LumpValue, FinesValue)
SELECT BlockModelId, 'As-Shipped', GradeName, GradeValue, LumpValue, FinesValue
FROM Staging.StageBlockModelGrade
WHERE GeometType = 'NA'
AND NOT GradeName like 'As-Dropped'
GO

ALTER TABLE Staging.StageBlockModelGrade
	ADD CONSTRAINT [PK_StageBlockModelGrade] PRIMARY KEY CLUSTERED 
	(
		[BlockModelId] ASC,
		[GradeName] ASC,
		[GeometType] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

SELECT name
FROM   sys.key_constraints
WHERE  [type] = 'PK'
       AND [parent_object_id] = Object_id('Staging.StageBlockModelGrade');