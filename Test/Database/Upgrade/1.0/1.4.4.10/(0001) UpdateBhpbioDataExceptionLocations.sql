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
		LEFT JOIN DataException DE
			On DE.Data_Exception_Id = BDEL.DataExceptionId
	WHERE DE.Data_Exception_Id IS NULL

	INSERT INTO @NewExceptions
	(DataExceptionId, Details_XML)
	SELECT DE.Data_Exception_Id, DE.Details_XML
	FROM DataException DE
		LEFT JOIN BhpbioDataExceptionLocation BDEL
			ON BDEL.DataExceptionId = DE.Data_Exception_Id
	WHERE BDEL.DataExceptionId IS NULL
		AND DE.Data_Exception_Status_Id <> 'R'

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
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, SL.Location_Id
		FROM @NewExceptions DE
			INNER JOIN StockpileLocation SL
				ON SL.Stockpile_Id = DE.Details_XML.value('(/DocumentElement/*/Stockpile_Id)[1]', 'INT')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"Negative_Stockpile", "Stockpile_Opening_Grades_Not_Specified", "Source_Or_Destination_Stockpile_Balance_Exception_Record",
		"Given_Moisture_Scaling_Adjustment_Error", "Stockpile_Survey_In_Circular_Reference", "Stockpile_Group_Designation"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL

		-- Searching for Digblock Id Column
		/* Data Exceptions:
			"Digblock_Grades_Not_Defined",
		*/
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, DL.Location_Id
		FROM @NewExceptions DE
			INNER JOIN DigblockLocation DL
				ON DL.Digblock_Id = DE.Details_XML.value('(/DocumentElement/*/Digblock_Id)[1]', 'Varchar(52)')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"Digblock_Grades_Not_Defined"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL


		-- Searching for Crusher Id Column
		/* Data Exceptions:
			"Inconsistent_Crusher_Deliveries_and_Removals",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, CL.Location_Id
		FROM @NewExceptions DE
			INNER JOIN CrusherLocation CL
				ON CL.Crusher_Id = DE.Details_XML.value('(/DocumentElement/*/Crusher_Id)[1]', 'Varchar(31)')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"Inconsistent_Crusher_Deliveries_and_Removals"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL
							
		-- Searching for Crusher Id Column
		/* Data Exceptions:
			"No_Crusher_Inflow_Movements",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, CL.Location_Id
		FROM @NewExceptions DE
			INNER JOIN CrusherLocation CL
				ON CL.Crusher_Id = DE.Details_XML.value('(/DocumentElement/*/Source_Crusher_Id)[1]', 'Varchar(31)')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"No_Crusher_Inflow_Movements"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL

		-- Searching for Weightometer Id Column
		/* Data Exceptions:
			"Weightometer_Record_Source_Or_Destination_Not_Defined",
		*/  
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, WL.Location_Id
		FROM @NewExceptions DE
			INNER JOIN WeightometerLocation WL
				ON WL.Weightometer_Id = DE.Details_XML.value('(/DocumentElement/*/Weightometer_Id)[1]', 'Varchar(52)')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"Weightometer_Record_Source_Or_Destination_Not_Defined"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL


		-- Searching for Mill Id Column
		/* Data Exceptions:
			"Inconsistent_Plant_Deliveries_And_Removals",
		*/ 
		INSERT INTO BhpbioDataExceptionLocation
		(DataExceptionId, LocationId)
		SELECT DE.DataExceptionId, M.Location_Id
		FROM @NewExceptions DE
			INNER JOIN MillLocation M
				ON M.Mill_Id = DE.Details_XML.value('(/DocumentElement/*/Mill_Id)[1]', 'Varchar(52)')
		WHERE Details_XML.query('
					 for $node in /descendant::node()[local-name() = 
		(
		"Inconsistent_Plant_Deliveries_And_Removals"
		)
					] 
					 return <node>
							<namespace>{ namespace-uri($node) }</namespace>
							<localname>{ local-name($node) }</localname>
							<parent>{ local-name($node/..) }</parent>
							</node>').value('(/node/localname)[1]', 'Varchar(255)') IS NOT NULL
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