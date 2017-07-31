-- Recalc Correction Scripts for new Grades

DECLARE @processDate DATETIME
SET @processDate = '2009-04-01'

-- SET THIS TO THE DATE THE BALANCE RECORDS ARE TO BE CORRECTED TO
DECLARE @endDate DATETIME
SET @endDate = GetDate()

-- SET THIS TO THE ID OF THE NEW GRADE
DECLARE @newGradeId INTEGER
SET @newGradeId = 10

DECLARE @countForGrade INTEGER

WHILE @processDate <= @endDate
BEGIN
	print 'Processing Date: ' + convert(varchar,@processDate,103)
	
	SET @countForGrade = 0

	SELECT @countForGrade = COUNT(*) FROM DataProcessStockpileBalanceGrade dpsg
		INNER JOIN DataProcessStockpileBalance sb ON sb.Data_Process_Stockpile_Balance_Id = dpsg.Data_Process_Stockpile_Balance_Id
		WHERE sb.Data_Process_Stockpile_Balance_Date = @processDate
		AND dpsg.Grade_Id = @newGradeId
	
	IF @countForGrade = 0
	BEGIN
		print 'Inserting Records for Date: ' + convert(varchar,@processDate,103)
		INSERT INTO DataProcessStockpileBalanceGrade(Data_Process_Stockpile_Balance_Id, Grade_Id, Grade_Value)
		SELECT dpsg.Data_Process_Stockpile_Balance_Id, @newGradeId as Grade_Id, 0 as Grade_Value
		FROM DataProcessStockpileBalanceGrade dpsg
			INNER JOIN DataProcessStockpileBalance sb ON sb.Data_Process_Stockpile_Balance_Id = dpsg.Data_Process_Stockpile_Balance_Id
			WHERE sb.Data_Process_Stockpile_Balance_Date = @processDate
			AND dpsg.Grade_Id = 1 -- add a GradeId = @newGradeId record for each record that has a Grade Id = 1
	END

	SET @processDate = DATEADD(day,1, @processDate )
END

IF NOT EXISTS (SELECT 1 FROM dbo.DataTransactionTonnesGrade WHERE Grade_Id = @newGradeId)
BEGIN
	INSERT INTO  dbo.DataTransactionTonnesGrade (Data_Transaction_Tonnes_Id, Grade_Id, Grade_Value)
	SELECT d.Data_Transaction_Tonnes_Id, @newGradeId, 0
	FROM dbo.DataTransactionTonnesGrade d
	WHERE d.Grade_Id = 1
END

IF NOT EXISTS (SELECT 1 FROM dbo.DataProcessTransactionGrade WHERE Grade_Id = @newGradeId)
BEGIN
	INSERT INTO  dbo.DataProcessTransactionGrade (Data_Process_Transaction_Id, Grade_Id, Grade_Value)
	SELECT d.Data_Process_Transaction_Id, @newGradeId, 0
	FROM dbo.DataProcessTransactionGrade d
	WHERE d.Grade_Id = 1
END

INSERT INTO DigblockGrade(Digblock_Id, Grade_Id, Grade_Value)
SELECT d.Digblock_Id, @newGradeId, 0
FROM Digblock d
LEFT JOIN DigblockGrade dg ON dg.Digblock_Id = d.Digblock_Id AND dg.Grade_Id = @newGradeId
WHERE dg.Digblock_Id IS NULL

INSERT INTO dbo.StockpileBuildComponentGrade(Stockpile_Id, Build_Id, Component_Id, Grade_Id, Grade_Value)
SELECT sbc.Stockpile_Id, sbc.Build_Id, sbc.Component_Id, @newGradeId, 0
FROM dbo.StockpileBuildComponent sbc
	LEFT JOIN dbo.StockpileBuildComponentGrade g ON g.Stockpile_Id = sbc.Stockpile_Id AND g.Build_Id = sbc.Build_Id AND g.Component_Id = sbc.Component_Id AND g.Grade_Id = @newGradeId
WHERE g.Stockpile_Id IS NULL
