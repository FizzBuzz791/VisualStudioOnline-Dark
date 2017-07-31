IF OBJECT_ID('dbo.UpdateBhpbioDataExceptionLocations') IS NOT NULL 
     DROP PROCEDURE dbo.UpdateBhpbioDataExceptionLocations 
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioDataExceptionLocations
AS
BEGIN 
    SET NOCOUNT ON 
 
	DECLARE @NewExceptions TABLE
	(
	  DataExceptionId INT,
	  Details_XML XML,
	  PRIMARY KEY (DataExceptionId)
	)

	DELETE BDEL
	FROM BhpbioDataExceptionLocation BDEL
	LEFT JOIN DataException DE ON DE.Data_Exception_Id = BDEL.DataExceptionId
	WHERE DE.Data_Exception_Id IS NULL

	INSERT INTO @NewExceptions (DataExceptionId, Details_XML)
	SELECT DE.Data_Exception_Id, DE.Details_XML
	FROM DataException DE
	LEFT JOIN BhpbioDataExceptionLocation BDEL ON BDEL.DataExceptionId = DE.Data_Exception_Id
	WHERE BDEL.DataExceptionId IS NULL AND DE.Data_Exception_Status_Id <> 'R' AND DE.Details_XML IS NOT NULL

	IF EXISTS (SELECT TOP 1 1 FROM @NewExceptions)
	  BEGIN
		-- Searching for Stockpile Id Column
		/* Data Exceptions:
    		"Negative_Stockpile",
    		"Stockpile_Opening_Grades_Not_Specified",
    		"Source_Or_Destination_Stockpile_Balance_Exception_Record",
    		"Given_Moisture_Scaling_Adjustment_Error",
    		"Stockpile_Survey_In_Circular_Reference",
    		"Stockpile_Group_Designation"
		*/
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, SL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN StockpileLocation SL ON SL.Stockpile_Id = DE.Details_XML.value('(/DocumentElement/*/Stockpile_Id/text())[1]', 'INT')
		WHERE DE.Details_XML.value('(/DocumentElement/Negative_Stockpile)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    		OR DE.Details_XML.value('(/DocumentElement/Stockpile_Opening_Grades_Not_Specified)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    		OR DE.Details_XML.value('(/DocumentElement/Source_Or_Destination_Stockpile_Balance_Exception_Record)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    		OR DE.Details_XML.value('(/DocumentElement/Given_Moisture_Scaling_Adjustment_Error)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    		OR DE.Details_XML.value('(/DocumentElement/Stockpile_Survey_In_Circular_Reference)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    		OR DE.Details_XML.value('(/DocumentElement/Stockpile_Group_Designation)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    
		-- Searching for Digblock Id Column
		/* Data Exceptions:
    		"Digblock_Grades_Not_Defined",
		*/
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, DL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN DigblockLocation DL ON DL.Digblock_Id = DE.Details_XML.value('(/DocumentElement/*/Digblock_Id/text())[1]', 'VARCHAR(52)')
		WHERE DE.Details_XML.value('(/DocumentElement/Digblock_Grades_Not_Defined)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    
		-- Searching for Crusher Id Column
		/* Data Exceptions:
    		"Inconsistent_Crusher_Deliveries_and_Removals",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, CL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN CrusherLocation CL ON CL.Crusher_Id = DE.Details_XML.value('(/DocumentElement/*/Crusher_Id/text())[1]', 'VARCHAR(31)')
		WHERE DE.Details_XML.value('(/DocumentElement/Inconsistent_Crusher_Deliveries_and_Removals)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    					
		-- Searching for Source Crusher Id Column
		/* Data Exceptions:
    		"No_Crusher_Inflow_Movements",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, CL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN CrusherLocation CL ON CL.Crusher_Id = DE.Details_XML.value('(/DocumentElement/*/Source_Crusher_Id/text())[1]', 'VARCHAR(31)')
		WHERE DE.Details_XML.value('(/DocumentElement/No_Crusher_Inflow_Movements)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    
		-- Searching for Weightometer Id Column
		/* Data Exceptions:
    		"Weightometer_Record_Source_Or_Destination_Not_Defined",
		  "Missing_Samples"
		*/  
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, WL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN WeightometerLocation WL ON WL.Weightometer_Id = DE.Details_XML.value('(/DocumentElement/*/Weightometer_Id/text())[1]', 'VARCHAR(52)')
		WHERE DE.Details_XML.value('(/DocumentElement/Weightometer_Record_Source_Or_Destination_Not_Defined)[1]', 'NVARCHAR(MAX)') IS NOT NULL
		  OR DE.Details_XML.value('(/DocumentElement/Missing_Samples)[1]', 'NVARCHAR(MAX)') IS NOT NULL

		  -- Searching for Target Weightometer Id Column
		/* Data Exceptions:
    		"Insufficient_Sample_Information"
		*/  
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, WL.Location_Id
		FROM @NewExceptions DE
		INNER JOIN WeightometerLocation WL ON WL.Weightometer_Id = DE.Details_XML.value('(/DocumentElement/*/TargetWeightometer_Id/text())[1]', 'VARCHAR(31)')
		WHERE DE.Details_XML.value('(/DocumentElement/Insufficient_Sample_Information)[1]', 'NVARCHAR(MAX)') IS NOT NULL
    
		-- Searching for Mill Id Column
		/* Data Exceptions:
    		"Inconsistent_Plant_Deliveries_And_Removals",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation (DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, M.Location_Id
		FROM @NewExceptions DE
		INNER JOIN MillLocation M ON M.Mill_Id = DE.Details_XML.value('(/DocumentElement/*/Mill_Id/text())[1]', 'VARCHAR(52)')
		WHERE DE.Details_XML.value('(/DocumentElement/Inconsistent_Plant_Deliveries_And_Removals)[1]', 'NVARCHAR(MAX)') IS NOT NULL			 
	  END
	
END 
GO 
GRANT EXECUTE ON dbo.UpdateBhpbioDataExceptionLocations TO BhpbioGenericManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetDataExceptionCount">
 <Procedure>
	Outputs the number of active data exceptions in the system
 </Procedure>
</TAG>
*/	