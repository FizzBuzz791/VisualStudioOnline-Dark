IF OBJECT_ID('dbo.BhpbioWeightometerGroupWeightometer') IS NULL
BEGIN

CREATE TABLE dbo.BhpbioWeightometerGroupWeightometer
(
	Weightometer_Group_Id VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
	Weightometer_Id VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
	[Start_Date] DATETIME NOT NULL,
	End_Date DATETIME NULL

	CONSTRAINT PK_BhpbioWeightometerGroupWeightometer
		PRIMARY KEY (Weightometer_Group_Id, Weightometer_Id, [Start_Date]),
		
	CONSTRAINT FK_PK_BhpbioWeightometerGroupWeightometer_WeightometerGroup
		FOREIGN KEY (Weightometer_Group_Id)
		REFERENCES dbo.WeightometerGroup (Weightometer_Group_Id),
		
	CONSTRAINT FK_PK_BhpbioWeightometerGroupWeightometer_Weightometer
		FOREIGN KEY (Weightometer_Id)
		REFERENCES dbo.Weightometer (Weightometer_Id)		
)
END

GO

