IF NOT EXISTS(SELECT * FROM Staging.ChangeKey)
BEGIN
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('Site', 'The Site associated with the item of data changed')
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('Pit', 'The Pit associated with the item of data changed')
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('Bench', 'The Bench associated with the item of data changed')
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('ExternalSystemId', 'The External System Id of the Block associated with the change')
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('BlockFullName', 'The full name of the Block')
	INSERT INTO Staging.ChangeKey (ChangeKey, Description) VALUES ('BlockModelName', 'The name of the Block Model containing the change')
END