IF OBJECT_ID('dbo.GetBhpbioStockpileListByGroups') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioStockpileListByGroups
GO

CREATE PROCEDURE dbo.GetBhpbioStockpileListByGroups
(
	@iGroup_By_Stockpile_Groups BIT = 1,
	@iStockpile_Group_Id VARCHAR(31) = NULL,
	@iStockpile_Name VARCHAR(31) = NULL,
	@iIs_Visible BIT = NULL,
	@iIs_Completed BIT = NULL,
	@iMaterial_Type_Id INT = NULL,
	@iSort_Type INT = NULL, --Between 1-4 Defined (see final result return set for definition)
	@iInclude_Grades BIT = 1, --If used = Performance Loss when many stockpiles and/or many grades exist in client system.
	@iFilterStartDate	DATETIME = NULL,
	@iFilterEndDate DATETIME = NULL,
	@iGrade_Visibility Bit = 1,
	@iTransactionStartDate DATETIME = NULL,
	@iTransactionEndDate DATETIME = NULL,
	@iLocationId INT = NULL,
	@iRecordLimit INT = NULL,
	@iStockpileGroupsXml Xml = null,
	@iIncludeLocationsBelow BIT = NULL -- If True then include all stockpiles UNDER this location, not just AT this location
)
WITH ENCRYPTION AS
BEGIN
	SET NOCOUNT ON
	
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
		
	--Main Result SET
	CREATE TABLE dbo.#StockpileList 
	(
		Stockpile_Id INT NOT NULL, 
		Stockpile_Name VARCHAR(31) COLLATE Database_Default NULL,
		Description VARCHAR(255) COLLATE Database_Default NULL,
		Material_Type_Id INT NULL,
		Is_Completed BIT NOT NULL,
		Approved_Added_Tonnes_This_Month FLOAT NULL,
		Unapproved_Added_Tonnes_This_Month FLOAT NULL, 
		Stockpile_Added_Tonnes_This_Month FLOAT NULL,
		Removed_Tonnes_This_Month FLOAT NULL,
		Current_Tonnes FLOAT NULL, 
		Last_Adjustment_Date DATETIME,
		Last_Adjustment_Description VARCHAR(255) COLLATE Database_Default NULL,

		PRIMARY KEY (Stockpile_Id)
	)

	--For Grade Pivoting
	CREATE TABLE dbo.#StockpileListGrade 
	(
		Stockpile_Id INT NOT NULL, 
		Grade_Name VARCHAR(31) COLLATE Database_Default NOT NULL,
		Grade_Value REAL NULL,

		PRIMARY KEY (Stockpile_Id, Grade_Name)
	)
	
	--Used to enable a single lookup FROM DPT
	CREATE TABLE dbo.#TransactionSummary 
	(
		Stockpile_Id INT NOT NULL,
		Code CHAR(3) COLLATE Database_Default NOT NULL,
		Tonnes FLOAT NULL,

		PRIMARY KEY (Stockpile_Id, Code)
	)

	--Used to enable a single lookup FROM Data Process Stockpile Balance
	CREATE TABLE dbo.#BalanceSummary
	(
		Data_Process_Stockpile_Balance_Id BIGINT NOT NULL,
		Stockpile_Id INT NOT NULL,
		Tonnes FLOAT NOT NULL,

		PRIMARY KEY (Data_Process_Stockpile_Balance_Id, Stockpile_Id)
	)

	DECLARE @MonthStartDate DATETIME
	DECLARE @MonthEndDate DATETIME

	IF @iTransactionStartDate IS NOT NULL
	BEGIN
		SET @MonthStartDate = @iTransactionStartDate
	END
	ELSE
	BEGIN
		--Define the inclusive month boundary
		SET @MonthStartDate = dbo.GetDateMonth(GetDate())
	END
		
	IF @iTransactionEndDate IS NOT NULL
	BEGIN
		SET @MonthEndDate = @iTransactionEndDate
	END
	ELSE
	BEGIN
		--Define the inclusive month boundary
		SET @MonthEndDate = DateAdd(DD, -1, DateAdd(MM, 1, @MonthStartDate))
	END
	
	--Set Sort Type to default of 1 when NULL or out of range sort type is indicated
	IF Coalesce(@iSort_Type, -1) NOT BETWEEN 1 AND 4
	BEGIN 
		SET @iSort_Type = 1
	END
	
	--Ensure stockpile grouping is on when a group filter is in use, The alternative doesn't make sense, 
	IF @iStockpile_Group_Id IS NOT NULL 
	BEGIN
		SET @iGroup_By_Stockpile_Groups = 1
	END	
	INSERT INTO dbo.#StockpileList
	(
		Stockpile_Id, Stockpile_Name, Description, Material_Type_Id, Is_Completed
	)
	SELECT s.Stockpile_Id, s.Stockpile_Name, s.Description, s.Material_Type_Id, 
		CASE 
			WHEN Count(csb.Build_Id) = 0 THEN 
				1 
			ELSE 
				0 
			END AS Is_Completed
	FROM dbo.Stockpile AS s
	WITH (NOLOCK)	
		LEFT OUTER JOIN dbo.StockpileBuild AS csb
			ON (s.Stockpile_Id = csb.Stockpile_Id
				AND csb.Stockpile_State_Id <> 'CLOSED')
		LEFT OUTER JOIN 
		(
			-- WILL THIS WORK PROPERLY WITH SET ROWCOUNT IN USE???
			SELECT sp.Stockpile_Id, IsNull(spl.Location_Id, 0) AS Location_Id
			FROM dbo.Stockpile AS sp
			WITH (NOLOCK)
				LEFT OUTER JOIN dbo.BhpbioStockpileLocationDate AS spl
					ON (sp.Stockpile_Id = spl.Stockpile_Id)		
					AND	(spl.[Start_Date] BETWEEN @MonthStartDate AND @MonthEndDate
						OR spl.End_Date BETWEEN @MonthStartDate AND @MonthEndDate
						OR (spl.[Start_Date] < @MonthStartDate AND spl.End_Date >@MonthEndDate))
		) AS l
			ON (s.Stockpile_Id = l.Stockpile_Id)
		LEFT JOIN StockpileGroupStockpile SG
			On SG.Stockpile_Id = s.Stockpile_Id
	WHERE s.Is_Visible = ISNULL(@iIs_Visible, s.Is_Visible)
		AND (s.Material_Type_Id = IsNull(@iMaterial_Type_Id, s.Material_Type_Id))
		AND (s.Stockpile_Name LIKE IsNull('%' + @iStockpile_Name + '%', s.Stockpile_Name))
		AND (@iStockpile_Group_Id IS NULL
			OR sg.Stockpile_Group_Id = @iStockpile_Group_Id
			)
		AND ((csb.Start_Date >= IsNull(@iFilterStartDate, csb.Start_Date))
			OR csb.Start_Date IS NULL)
		AND ((csb.Start_Date <= IsNull(@iFilterEndDate, csb.Start_Date))
			OR csb.Start_Date IS NULL)
		AND 
			(				
				@iLocationId IS NULL
					OR (
							l.Location_Id = @iLocationId 
							AND @iIncludeLocationsBelow = 0
						)
					OR (
							l.Location_Id IN 
								(	
									SELECT Location_Id
									FROM dbo.GetLocationSubtree(@iLocationId)
								)
							AND @iIncludeLocationsBelow = 1
						)
			)
		AND 
		(
			(
				ISNULL(sg.Stockpile_Group_id, 'Stockpiles NOT Grouped') IN
					(
						SELECT col.value('GroupId[1]', 'varchar(31)')
						FROM @iStockpileGroupsXml.nodes('//StockpileGroups') AS tab(col)
					)
			)
			OR
			(
				SELECT COUNT(1)
				FROM @iStockpileGroupsXml.nodes('//StockpileGroups') AS tab(col)
			) = 0
		)
	GROUP BY s.Stockpile_Id, s.Stockpile_Name, s.Description, s.Material_Type_Id
	HAVING (@iIs_Completed = 1 AND Count(csb.Build_Id) = 0)  --SB is the count of stockpile
		OR (@iIs_Completed = 0 AND Count(csb.Build_Id) > 0)  --builds for this stockpile that arent closed
		OR (@iIs_Completed IS NULL)

	--Summarise DPT Data for the various tonnes balances required		
	INSERT INTO dbo.#TransactionSummary
	(
		Stockpile_Id, Code, Tonnes
	)	
	--Data that IS based ON the Stockpile being the Destination
	SELECT sl.Stockpile_Id, 
		CASE 
			WHEN dpt.Source_Digblock_Id IS NOT NULL AND dtt.Is_Approved = 1 THEN 
				'APP' --Approved Tonnes
			WHEN dpt.Source_Digblock_Id IS NOT NULL THEN 
				'UNA' --Unapproved Tonnes
			WHEN dpt.Source_Stockpile_Id IS NOT NULL THEN 
				'ADD' --Added Tonnes
			ELSE 'N/A' -- Unknown, shouldn't get anything here but just in case not returned to UI anyway
		END	AS Code,
		Sum(dpt.Tonnes) AS Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.DataProcessTransaction AS dpt --JOIN to Dest
			ON (sl.Stockpile_Id = dpt.Destination_Stockpile_Id)
		INNER JOIN dbo.DataTransactionTonnes AS dtt		
			ON (dtt.Data_Transaction_Tonnes_Id = dpt.Data_Transaction_Tonnes_Id)
	WHERE dpt.Data_Process_Transaction_Date Between @MonthStartDate AND @MonthEndDate 
		AND dpt.Stockpile_Adjustment_Id IS NULL
	GROUP BY sl.Stockpile_Id, 
		CASE 
			WHEN dpt.Source_Digblock_Id IS NOT NULL AND dtt.Is_Approved = 1 THEN 
				'APP' --Approved Tonnes
			WHEN dpt.Source_Digblock_Id IS NOT NULL THEN 
				'UNA' --Unapproved Tonnes
			WHEN dpt.Source_Stockpile_Id IS NOT NULL THEN 
				'ADD' --Added Tonnes
			ELSE 
				'N/A' -- Unknown, shouldn't get anything here but just in case not returned to UI anyway
		END
	UNION ALL
	--Data that IS based ON the Stockpile being the Source
	SELECT sl.Stockpile_Id, 'REM' AS Code, Sum(dpt.Tonnes) AS Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.DataProcessTransaction AS dpt --Join to Source
			ON (sl.Stockpile_Id = dpt.Source_Stockpile_Id)
	WHERE dpt.Data_Process_Transaction_Date BETWEEN @MonthStartDate AND @MonthEndDate 
		AND dpt.Stockpile_Adjustment_Id IS NULL	
	GROUP BY sl.Stockpile_Id		

	DELETE SL
	FROM dbo.#StockpileList SL
		LEFT JOIN dbo.#TransactionSummary AS dpt 
			ON (dpt.Stockpile_Id = sl.Stockpile_Id)
	WHERE dpt.Stockpile_Id IS NULL
		AND @iTransactionEndDate IS NOT NULL
		
	IF @iRecordLimit IS NOT NULL
	BEGIN
		DELETE SL
		FROM dbo.#StockpileList SL
		WHERE SL.Stockpile_Id Not In (SELECT TOP (@iRecordLimit) Stockpile_Id
										FROM dbo.#StockpileList
										ORDER BY Stockpile_Id)
	END
	
	-- Obtain the Approved for the month		
	UPDATE sl
	SET Approved_Added_Tonnes_This_Month = dpt.Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.#TransactionSummary AS dpt 
			ON (dpt.Stockpile_Id = sl.Stockpile_Id
				AND dpt.Code = 'APP')

	-- Obtain the Unapproved for the month
	UPDATE sl
	SET Unapproved_Added_Tonnes_This_Month = dpt.Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.#TransactionSummary AS dpt 
			ON (dpt.Stockpile_Id = sl.Stockpile_Id
				AND dpt.Code = 'UNA')

	-- Obtain the Stockpile Added Tonnes for the month
	UPDATE sl
	SET Stockpile_Added_Tonnes_This_Month = dpt.Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.#TransactionSummary AS dpt 
			ON (dpt.Stockpile_Id = sl.Stockpile_Id
				AND dpt.Code = 'ADD')

	-- Obtain the Removed Tonnes for the month
	UPDATE sl
	SET Removed_Tonnes_This_Month = dpt.Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.#TransactionSummary AS dpt 
			ON (dpt.Stockpile_Id = sl.Stockpile_Id
				AND dpt.Code = 'REM')	--Get the key Records for Stockpile Balance that will be used for current tonnes and grade pivoting

	--Retrieve the balance records that are used, in order to get the current tonnes
	--and also retrieve grades IF requested to (reason for the key being stored)
	INSERT INTO dbo.#BalanceSummary
	(
		Data_Process_Stockpile_Balance_Id, Stockpile_Id, Tonnes
	)
	SELECT d.Data_Process_Stockpile_Balance_Id, sl.Stockpile_Id, d.Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.StockpileBuild AS b
			ON (sl.Stockpile_Id = b.Stockpile_Id)
		INNER JOIN dbo.DataProcessStockpileBalance AS d
			ON (
					b.Stockpile_Id = d.Stockpile_Id
					AND b.Build_Id = d.Build_Id
					AND
					(
						CASE WHEN @iTransactionEndDate IS NOT NULL
							AND @iTransactionEndDate < b.Last_Recalc_Date THEN
							@iTransactionEndDate
						ELSE
							b.Last_Recalc_Date
						END
					) = d.Data_Process_Stockpile_Balance_Date 
					AND
					(
						CASE WHEN @iTransactionEndDate IS NOT NULL
							AND @iTransactionEndDate < b.Last_Recalc_Date THEN
							dbo.GetLastShiftType()
						ELSE
							b.Last_Recalc_Shift 
						END
					) = d.Data_Process_Stockpile_Balance_Shift
				)

	-- Get the Current Tonnes Value by Regrouping the data
	UPDATE sl
	SET Current_Tonnes = dsb.Current_Tonnes
	FROM dbo.#StockpileList AS sl
		INNER JOIN
		(
			SELECT bs.Stockpile_Id,
				Sum(bs.Tonnes) AS Current_Tonnes
			FROM dbo.#BalanceSummary AS bs
			GROUP BY bs.Stockpile_Id
		
		) dsb
		ON dsb.Stockpile_Id = sl.Stockpile_Id
		
	-- Add the last adjustment date AND description
	UPDATE sl
	SET sl.Last_Adjustment_Date = 
		(
			SELECT TOP 1 sa.Adjustment_Date
			FROM dbo.StockpileAdjustment AS sa
				INNER JOIN dbo.ShiftType AS st
					ON (sa.Adjustment_Shift = st.Shift)
			WHERE sa.Stockpile_Id = sl.Stockpile_Id
				AND sa.Adjustment_Date < @MonthEndDate
			ORDER BY sa.Adjustment_Date DESC, st.Order_No DESC
		),
		sl.Last_Adjustment_Description = 
		(
			SELECT Top 1 sa.Description
			FROM dbo.StockpileAdjustment AS sa
				INNER JOIN dbo.ShiftType AS st
					ON (sa.Adjustment_Shift = st.Shift)
			WHERE sa.Stockpile_Id = sl.Stockpile_Id
				AND sa.Adjustment_Date < @MonthEndDate
			ORDER BY sa.Adjustment_Date DESC, st.Order_No DESC
		)
	FROM dbo.#StockpileList AS sl
							
	--Only Pivot Grades if Required to
	IF @iInclude_Grades = 1
	BEGIN
	
		--EXTRACT GRADES FROM BALANCE DATA

		--Now Populate the stockpile grades table using the balance details collected
		INSERT INTO dbo.#StockpileListGrade
		(
			Stockpile_Id, Grade_Name, 
			Grade_Value
		)
		SELECT BS.Stockpile_Id, G.Grade_Name, 
			Sum(BS.Tonnes * DPSBG.Grade_Value) / NullIf(Sum(BS.Tonnes), .00) AS Grade_Value
		FROM dbo.#BalanceSummary AS BS
			INNER JOIN dbo.DataProcessStockpileBalanceGrade AS DPSBG
				ON DPSBG.Data_Process_Stockpile_Balance_Id = BS.Data_Process_Stockpile_Balance_Id
			INNER JOIN dbo.Grade AS G
				ON DPSBG.Grade_Id = G.Grade_Id
		WHERE (G.Is_Visible = @iGrade_Visibility 
			OR @iGrade_Visibility IS NULL)
		GROUP BY BS.Stockpile_Id, G.Grade_Name

		UNION ALL

		--Dummy Grade Values Ensure All Grade are Pivoted
		SELECT -1 AS Stockpile_Id, G.Grade_Name, Null AS Grade_Value
		FROM dbo.Grade AS G
		WHERE (G.Is_Visible = @iGrade_Visibility 
			OR @iGrade_Visibility IS NULL)

		--Pivot Grades Onto Main table
		EXEC dbo.PivotTable
			@iTargetTable='#StockpileList',
			@iPivotTable='#StockpileListGrade',
			@iJoinColumns='#StockpileList.Stockpile_Id = #StockpileListGrade.Stockpile_Id',
			@iPivotColumn='Grade_Name',
			@iPivotValue='Grade_Value',
			@iPivotType='REAL'			
	END				
	
	-- Return the dataset with its stockpile groups if they exist (denormalised dataset here with many groups potentially)
	SELECT Coalesce(sg.Stockpile_Group_Id, 'Stockpiles NOT Grouped') AS Stockpile_Group_Id,
		sl.*, --May Include Grades
		mt.Description AS Material_Type_Description,
		mt.Native_Alternative,		
		mt.Abbreviation,		
		mtg.Order_No,		
		mt.Is_Waste			
	FROM dbo.#StockpileList AS sl
		INNER JOIN dbo.MaterialType AS mt
			ON (mt.Material_Type_Id = sl.Material_Type_Id)
		INNER JOIN dbo.MaterialTypeGroup AS mtg
			ON (mt.Material_Type_Group_Id = mtg.Material_Type_Group_Id)
		LEFT OUTER JOIN dbo.StockpileGroupStockpile AS sgs 
			INNER JOIN dbo.StockpileGroup AS sg
				ON (sgs.Stockpile_Group_Id = sg.Stockpile_Group_Id
					--Stockpile Ggroup Requires refiltering here, otherwise if a specific stockpile group is filtered for ealier
					--AND stockpile belongs to that group and another, the extra groups will also be returned
					AND sg.Stockpile_Group_Id = IsNull(@iStockpile_Group_Id, sg.Stockpile_Group_Id))
			--Only JOIN To stockpile GROUP IF indicated BY filter options
			ON (sgs.Stockpile_Id = CASE
									WHEN @iGroup_By_Stockpile_Groups = 0
										THEN NULL --Do not join to Stockpile group No stockpile Groups/Duplicates will be returned
									ELSE sl.Stockpile_Id --Each stockpile will be listed with each group to which it belongs
								END)
	-- Sort Type Ordering Configuration
	-- 1 = ORDER BY Coalesce(sg.Order_No, 10000), sl.Stockpile_Name
	-- 2 = ORDER BY Coalesce(sg.Order_No, 10000), mt.Native_Alternative, sl.Stockpile_Name
	-- 3 = ORDER BY Coalesce(sg.Order_No, 10000), sl.Description
	-- 4 = ORDER BY Coalesce(sg.Order_No, 10000), sl.Order_No, mt.Is_Waste, mt.Abbreviation, sl.Description
	
	WHERE 
		(
			ISNULL(sg.Stockpile_Group_id, 'Stockpiles NOT Grouped') IN
				(
					SELECT col.value('GroupId[1]', 'varchar(31)')
					FROM @iStockpileGroupsXml.nodes('//StockpileGroups') AS tab(col)
				)
		)
		OR
		(
			SELECT COUNT(1)
			FROM @iStockpileGroupsXml.nodes('//StockpileGroups') AS tab(col)
		) = 0
	ORDER BY Coalesce(sg.Order_No, 10000), --sort position 1
		CASE @iSort_Type --sort position 2
			WHEN 1 THEN sl.Stockpile_Name
			WHEN 2 THEN mt.Native_Alternative
			WHEN 3 THEN sl.Description
			WHEN 4 THEN Cast(mtg.Order_No AS VARCHAR)
			ELSE '0' --no further sort defined 
		END,
		CASE @iSort_Type --sort position 3
			WHEN 2 THEN sl.Stockpile_Name
			WHEN 4 THEN Cast(mt.Is_Waste AS VARCHAR)
			ELSE '0' --no further sort defined 
		END,
		CASE @iSort_Type --sort position 4
			WHEN 4 THEN mt.Abbreviation
			ELSE '0' --no further sort defined 
		END,
		CASE @iSort_Type --sort position 5
			WHEN 4 THEN sl.Description
			ELSE '0' --no further sort defined 
		END		
	
	DROP TABLE dbo.#StockpileList
	DROP TABLE dbo.#TransactionSummary
	DROP TABLE dbo.#BalanceSummary
	DROP TABLE dbo.#StockpileListGrade

	COMMIT TRANSACTION	
END

GO
GRANT EXECUTE ON dbo.GetBhpbioStockpileListByGroups TO CoreStockpileManager
GO
/*
<TAG Name="Data Dictionary" ProcedureName="GetStockpileList">
 <Procedure>
  Returns the list of stockpile details.
 </Procedure>
</TAG>
*/