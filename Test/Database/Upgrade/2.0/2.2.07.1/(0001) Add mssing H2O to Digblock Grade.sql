-- INSERT 0 values into DigblockGrade for H2O type grades, where no current record exists
--	NOTE: This script is safe to be run multiple times
INSERT INTO DigblockGrade(Digblock_Id, Grade_Id, Grade_Value)
SELECT d.Digblock_Id, g.Grade_Id, 0
FROM Digblock d
CROSS JOIN (SELECT g1.Grade_Id FROM Grade g1 WHERE g1.Grade_Name like 'H2O%') g
LEFT JOIN DigblockGrade dg ON dg.Digblock_Id = d.Digblock_Id AND dg.Grade_Id = g.Grade_Id
WHERE dg.Digblock_Id IS NULL
