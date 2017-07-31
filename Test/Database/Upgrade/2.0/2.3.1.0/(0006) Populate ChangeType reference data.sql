IF NOT EXISTS(SELECT * FROM Staging.ChangeType)
BEGIN
	INSERT INTO Staging.ChangeType (Id, Description) VALUES ('StageBlock', 'A change to a StageBlock or related data')
	INSERT INTO Staging.ChangeType (Id, Description) VALUES ('StageBlockModel', 'A change to a StageBlockModel record or related data')
END
