If OBJECT_ID('dbo.BhpbioCustomMessage') IS NOT NULL 
     DROP TABLE dbo.BhpbioCustomMessage
Go 

CREATE TABLE dbo.BhpbioCustomMessage 
(
	Name VARCHAR(63) COLLATE Database_Default NOT NULL,
	Text VARCHAR(MAX) COLLATE Database_Default NOT NULL,
	ExpirationDate DATETIME NULL,
	IsActive BIT NOT NULL,
	
	CONSTRAINT PK_BhpbioCustomMessage PRIMARY KEY CLUSTERED (Name)
) 
GO


UPDATE dbo.UserInterfaceListingField
SET Pixel_Width = 200
Where Field_Name = 'MaterialName'

-----------------------------------------------------------------------------------------------------------

IF OBJECT_ID('dbo.GetBhpbioApprovalOtherMaterial') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalOtherMaterial  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalOtherMaterial 
(
	@iMonthFilter DATETIME,
	@iLocationId INT,
	@iChildLocations BIT
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ActualId INT
	SET @ActualId = 88
	DECLARE @ActualName VARCHAR(40)
	SET @ActualName = 'Actual'

	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonthFilter)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		LocationId INT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type, LocationId)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		LocationType VARCHAR(255) NOT NULL,
		LocationName VARCHAR(31) NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
		
	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalOtherMaterial',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END

	BEGIN TRY
		-- Create Pivot Tables
		CREATE TABLE dbo.#Record
		(
			TagId VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			LocationId INT NOT NULL,
			LocationType VARCHAR(255) NOT NULL,
			LocationName VARCHAR(31) NOT NULL,
			MaterialTypeId INT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
			OrderNo INT NOT NULL,
			ParentMaterialTypeId INT NULL,
			Approved BIT NULL,
			SignOff VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			PRIMARY KEY (MaterialName, LocationId)
		)

		CREATE TABLE dbo.#RecordTonnes
		(
			MaterialTypeId INT NULL,
			LocationId INT NOT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			ModelName VARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
			Tonnes FLOAT NULL,
			OrderNo INT NULL,
			RootNode INT NULL
		)
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory('Designation') AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = mc.RootMaterialTypeId
		
		-- setup the Locations
		INSERT INTO @Location
			(LocationId, ParentLocationId, LocationName, LocationType)
		SELECT L.Location_Id, L.Parent_Location_Id, L.Name, LT.Description
		FROM dbo.Location AS L
			INNER JOIN dbo.LocationType as LT
				ON L.Location_Type_Id = LT.Location_Type_Id
		WHERE (@iChildLocations = 0 AND Location_Id = @iLocationId)
			OR (@iChildLocations = 1 AND Parent_Location_Id = @iLocationId)
		
		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
			(Type, CalendarDate, MaterialTypeId, Tonnes, LocationId)
		SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(Coalesce(Tonnes, 0.0)), 
			CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END AS LocationId
			FROM
				(	-- C - z + y
					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes, LocationId
					FROM dbo.GetBhpbioReportActualC(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
					UNION ALL
					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes, LocationId
					FROM dbo.GetBhpbioReportActualZ(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
					UNION ALL
					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value), LocationId
					FROM dbo.GetBhpbioReportActualY(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId, LocationId

		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
			(Type, BlockModelId, CalendarDate, MaterialTypeId, Tonnes, LocationId)
		SELECT bm.Name, bm.Block_Model_Id, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value),
			CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END AS LocationId
		FROM dbo.GetBhpbioReportModel(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations) AS m
			INNER JOIN dbo.BlockModel AS bm
				ON (m.BlockModelId = bm.Block_Model_Id)
			INNER JOIN @MaterialType AS mc
				ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
		WHERE m.Attribute = 0
		GROUP BY bm.Name, bm.Block_Model_Id, m.CalendarDate, mc.RootMaterialTypeId, LocationId

		-- Modified version from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		-- Put the block model tonnes in.
		INSERT INTO dbo.#RecordTonnes
			(MaterialName, ModelName, Tonnes, LocationId, OrderNo)
		SELECT mt.RootAbbreviation AS Material, t.Type, r.Tonnes, r.LocationId, Coalesce(T.BlockModelId, @ActualId)
		-- Get all types
		FROM ( SELECT DISTINCT t2.Type, t2.BlockModelId FROM @Tonnes as t2) AS t
		-- Cross joined with all material types
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
						INNER JOIN @Tonnes AS r2
							ON (r2.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
		-- Joined on tonnes
		INNER JOIN @Tonnes AS r
			ON (r.MaterialTypeId = mt.MaterialTypeId
				AND r.Type = t.Type)
		WHERE mt.RootAbbreviation NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
			AND mt.RootAbbreviation IS NOT NULL

		-- Add up the total ore and total waste.
		INSERT INTO dbo.#RecordTonnes
			(MaterialTypeId, MaterialName, ModelName, Tonnes, LocationId, OrderNo, RootNode)
		SELECT CMT.Parent_Material_Type_Id, 'Total ' + MT.Description, 
			ModelName, Sum(Tonnes), RT.LocationId, RT.OrderNo, CMT.Parent_Material_Type_Id
		FROM dbo.#RecordTonnes AS RT
			INNER JOIN dbo.MaterialType AS CMT
				ON RT.MaterialName = CMT.Description
					AND CMT.Material_Category_Id = @MaterialCategoryId
			INNER JOIN dbo.MaterialType AS MT
				ON CMT.Parent_Material_Type_Id = MT.Material_Type_Id
		WHERE CMT.Parent_Material_Type_Id IS NOT NULL
		GROUP BY ModelName, CMT.Parent_Material_Type_Id, MT.Description, RT.OrderNo, RT.LocationId

		-- Insert the required unpivoted rows based on the rows.
		INSERT INTO dbo.#Record
			(TagId, MaterialTypeId, MaterialName, OrderNo, ParentMaterialTypeId, LocationId, LocationName, LocationType)
		SELECT 
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				NULL 
			ELSE 
				'OtherMaterial_' + REPLACE(MT.Description, ' ', '_')
			END,
			Coalesce(Material_Type_Id, RT.MaterialTypeId), 
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				'Total ' + MT.Description
			ELSE 
				MT.Description
			END,
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				((MT.Material_Type_Id * 2) + 1) * 100
			ELSE 
				Coalesce(Parent_Material_Type_Id*2, RootNode*2 + 1) * 100 + Coalesce(Material_Type_Id, 0)
			END,
			Parent_Material_Type_Id, L.LocationId, L.LocationName, L.LocationType
		FROM dbo.MaterialType AS MT
			CROSS JOIN @Location AS L
			LEFT JOIN dbo.#RecordTonnes AS RT
				ON (MT.Material_Type_Id = RT.MaterialTypeId
					AND L.LocationId = RT.LocationId)
		WHERE MT.Material_Category_Id IN ('Designation', 'Classification')
			AND MT.Description NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
		GROUP BY Material_Type_Id, RT.MaterialName, MT.Description, Material_Type_Id, RT.MaterialTypeId, RootNode, 
			Parent_Material_Type_Id, L.LocationId, L.LocationName, L.LocationType

		-- Ensure all models/actual column show up.
		INSERT INTO dbo.#RecordTonnes
			(LocationId, ModelName, OrderNo)
		SELECT -1, Name, Block_Model_Id
		FROM dbo.BlockModel
		UNION
		SELECT -1, @ActualName, @ActualId
		
		
		-- Ensure all models/actual column values are not null.
		INSERT INTO dbo.#RecordTonnes
			(ModelName, LocationId, MaterialName, Tonnes, OrderNo)
		SELECT STUB.ModelName, L.LocationId, MT.MaterialName, 0, STUB.OrderNo--MUST INSERT SAME ORDER NO HERE
		--SELECT STUB.ModelName, RT.ModelName, L.LocationId, RT.LocationId, MT.MaterialName, RT.MaterialName, RT.*
		FROM (SELECT DISTINCT ModelName, OrderNo FROM dbo.#RecordTonnes WHERE MaterialName IS NULL) AS STUB
		CROSS JOIN @Location AS L
		CROSS JOIN (SELECT DISTINCT MaterialName FROM dbo.#Record) AS MT
		LEFT JOIN dbo.#RecordTonnes AS RT
			ON (RT.LocationId = L.LocationId
				AND RT.ModelName = STUB.ModelName
				AND RT.MaterialName = MT.MaterialName)
		WHERE RT.LocationId IS NULL
		--	and RT.ModelName = 'Grade Control'
		--	and RT.materialname = 'Pyritic Waste'
		order by L.LocationId
		
		
		-- Display zeros when a value is not present.
		UPDATE dbo.#RecordTonnes
		SET Tonnes = 0
		WHERE Tonnes IS NULL
		
				
		-- Pivot the blockmodel/actual tonnes into the material types
		EXEC dbo.PivotTable
			@iTargetTable = '#Record',
			@iPivotTable = '#RecordTonnes',
			@iJoinColumns = '#Record.MaterialName = #RecordTonnes.MaterialName AND #Record.LocationId = #RecordTonnes.LocationId',
			@iPivotColumn = 'ModelName',
			@iPivotValue = 'Tonnes',
			@iPivotType = 'FLOAT',
			@iPivotOrderColumn = 'OrderNo'
		
		SELECT TagId,
				LocationId,
				LocationType,
				LocationName,
				MaterialTypeId,
				MaterialName,
				OrderNo,
				ParentMaterialTypeId,
				Approved,
				SignOff,
				Geology,
				Mining,
				[Grade Control],
				Actual
		FROM dbo.#Record
		ORDER BY LocationName, OrderNo
		
		DROP TABLE dbo.#Record
		DROP TABLE dbo.#RecordTonnes

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioApprovalOtherMaterial TO BhpbioGenericManager
GO

--exec dbo.GetBhpbioApprovalOtherMaterial '1-nov-2009', 8, 1

------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('dbo.GetBhpbioApprovalDataRaw') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDataRaw
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDataRaw
(
	@iMonthFilter DATETIME,
	@iIgnoreUsers BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDataRaw',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
	
		IF @iIgnoreUsers = 1
		BEGIN
			-- Retrieves all the approvals for the month without any user information
			-- This is used by the Approval update page to quickly check which records to update
			SELECT TagId, LocationId, ApprovedMonth
			FROM dbo.BhpbioApprovalData
			WHERE (ApprovedMonth = @iMonthFilter OR @iMonthFilter IS NULL)
			GROUP BY TagId, LocationId, ApprovedMonth
		END
		ELSE
		BEGIN
			-- Retrieves all raw data from the approval table
			SELECT TagId, LocationId, ApprovedMonth, UserId, SignoffDate
			FROM dbo.BhpbioApprovalData
			WHERE (ApprovedMonth = @iMonthFilter OR @iMonthFilter IS NULL)
		END
		
			
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioApprovalDataRaw TO BhpbioGenericManager
GO


--EXEC dbo.GetBhpbioApprovalDataRaw '1-nov-2009'



DELETE FROM dbo.NotificationTypeRegistration

SET IDENTITY_INSERT dbo.NotificationType ON
INSERT INTO dbo.NotificationType
(
	TypeId, Name, Description
)
SELECT 9, 'Approval', 'Monthly & Quarterly Approvals'
SET IDENTITY_INSERT dbo.NotificationType OFF

EXEC DbaNotificationCreateTypeRegistrations 'Haulage'
EXEC DbaNotificationCreateTypeRegistrations 'Import'
EXEC DbaNotificationCreateTypeRegistrations 'Negative Stockpile'
EXEC DbaNotificationCreateTypeRegistrations 'Inconsistent Crusher Deliveries'
EXEC DbaNotificationCreateTypeRegistrations 'Inconsistent Plant Deliveries'
EXEC DbaNotificationCreateTypeRegistrations 'Recalc'
EXEC DbaNotificationCreateTypeRegistrations 'Audit'
EXEC DbaNotificationCreateTypeRegistrations 'Approval'

IF Object_Id('dbo.BhpbioNotificationInstanceApproval') IS NOT NULL
	DROP TABLE dbo.BhpbioNotificationInstanceApproval
GO

CREATE TABLE dbo.BhpbioNotificationInstanceApproval
(
	InstanceId INT NOT NULL,
	TagGroupId VARCHAR(124) COLLATE DATABASE_DEFAULT NULL,
	LocationId INT NULL,
	CONSTRAINT PK_BhpbioNotificationInstanceApproval PRIMARY KEY CLUSTERED (InstanceId),
	CONSTRAINT FK_BhpbioNotificationInstanceApproval_NotificationInstance FOREIGN KEY (InstanceId) 
		REFERENCES dbo.NotificationInstance (InstanceId),
	CONSTRAINT FK_BhpbioNotificationInstanceApproval_Location FOREIGN KEY (LocationId)
		REFERENCES dbo.Location (Location_Id)
)


CREATE NONCLUSTERED INDEX IX_BhpbioNotificationInstanceApproval_Lookup ON dbo.BhpbioNotificationInstanceApproval (TagGroupId, LocationId, InstanceId)
GO



INSERT INTO dbo.Setting
(
	Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values
)
SELECT 'BHPBIO_CONTACT_SUPPORT', 'Link to contact support', 'String', 1, '', NULL

UPDATE NotificationTypeRegistration
	Set DisplayOnUi = 0
WHERE TypeId <> 9

GO

IF OBJECT_ID('dbo.GetBhpbioCustomMessages') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioCustomMessages
GO 
  
CREATE PROCEDURE dbo.GetBhpbioCustomMessages
(
	@iName VARCHAR(63) = NULL
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioCustomMessages',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		SELECT *
		FROM dbo.BhpbioCustomMessage
		WHERE @iName = Name OR @iName IS NULL


		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioCustomMessages TO BhpbioGenericManager
GO

IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsGrades') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT,
	@iGrades XML
)
AS 
BEGIN
	-- for internal consumption only
	
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @HighGradeMaterialTypeId INT

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue FLOAT NULL,
		Tonnes FLOAT NULL,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, GradeId, Type)
	)
	
	DECLARE @Type TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		PRIMARY KEY CLUSTERED (Type)
	)

	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)

	DECLARE @Date TABLE
	(
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		CalendarDate DATETIME NOT NULL,
		PRIMARY KEY NONCLUSTERED (CalendarDate),
		UNIQUE CLUSTERED (DateFrom, DateTo, CalendarDate)
	)

	DECLARE @GradeLookup TABLE
	(
		GradeId SMALLINT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		OrderNo INT NOT NULL,
		PRIMARY KEY CLUSTERED (GradeId)
	)

	DECLARE @C TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @Y TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @Z TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @M TABLE
	(
		CalendarDate DATETIME NOT NULL,
		BlockModelId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsGrades',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END

	BEGIN TRY
		-- perform checks
		IF dbo.GetDateMonth(@iDateFrom) <> @iDateFrom
		BEGIN
			RAISERROR('The @iDateFrom parameter must be the first day of the month.', 16, 1)
		END

		IF (dbo.GetDateMonth(@iDateTo + 1) - 1) <> @iDateTo
		BEGIN
			RAISERROR('The @iDateTo parameter must be the last day of the month.', 16, 1)
		END

		IF NOT @iMaterialCategoryId IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('The Material Category parameter can only be Classification/Designation.', 16, 1)
		END

		-- load Grades
		IF @iGrades IS NULL
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT Grade_Id, Grade_Name, Order_No
			FROM dbo.Grade
		END
		ELSE
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT g.Grade.value('./@id', 'SMALLINT'), g2.Grade_Name, g2.Order_No
			FROM @iGrades.nodes('/Grades/Grade') AS g(Grade)
				INNER JOIN dbo.Grade AS g2
					ON (g2.Grade_Id = g.Grade.value('./@id', 'SMALLINT'))
		END

		-- load Block Model
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			VALUES
				('Actual', NULL)
		END

		IF (@iIncludeBlockModels = 1) AND (@iBlockModels IS NULL)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT Name, Block_Model_Id
			FROM dbo.BlockModel
		END
		ELSE IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT bm.Name, b.BlockModel.value('./@id', 'INT')
			FROM @iBlockModels.nodes('/BlockModels/BlockModel') AS b(BlockModel)
				INNER JOIN dbo.BlockModel AS bm
					ON (bm.Block_Model_Id = b.BlockModel.value('./@id', 'INT'))
		END
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)

		-- load the date range
		INSERT INTO @Date
			(DateFrom, DateTo, CalendarDate)
		SELECT DateFrom, DateTo, CalendarDate
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1)

		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @C
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Y
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Z
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT 'Actual', CalendarDate, RootMaterialTypeId, GradeId,
				SUM(Tonnes * GradeValue) / NULLIF(SUM(Tonnes), 0.0), SUM(Tonnes)
			FROM
				(
					-- High Grade = C - z(hg) + y(hg)
					-- All Grade  = y(non-hg)

					-- '+C' - all crusher removals
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId, SUM(t.Value) AS Tonnes,
						-- the following value is only valid as the data is always returned at the Site level
						-- above this level (Hub/WAIO) the aggregation will properly perform real aggregations
						SUM(g.Value * NULLIF(t.Value, 0.0)) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @C AS g
						INNER JOIN @C AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '-z(all)' - pre crusher stockpiles to crusher
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						-SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Z AS g
						INNER JOIN @Z AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '+y(hg)' - pit to pre-crusher stockpiles
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Y AS g
						INNER JOIN @Y AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
				) AS sub
			GROUP BY CalendarDate, RootMaterialTypeId, GradeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @M
				(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute,
				SUM(g.Value * t.Value) / SUM(t.Value), SUM(t.Value)
			FROM @M AS t
				INNER JOIN @M AS g
					ON (t.DesignationMaterialTypeId = g.DesignationMaterialTypeId
						AND t.BlockModelId = g.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
				INNER JOIN @Type AS bm
					ON (t.BlockModelId = bm.BlockModelId)
			WHERE t.Attribute = 0
				AND g.Attribute > 0
			GROUP BY bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
		END

		-- return the result	
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			g.GradeName, g.GradeId, SUM(r.GradeValue * r.Tonnes) / SUM(r.Tonnes) As GradeValue
		FROM
			-- display all dates
			@Date AS d
			-- display all elisted types (block models + actual)
			CROSS JOIN @Type AS t
			-- ensure material types are represented uniformly
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
				) AS mt
			-- ensure all grades are represented
			CROSS JOIN @GradeLookup AS g
			-- pivot in the results
			LEFT OUTER JOIN @Grade AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type
					AND g.GradeId = r.GradeId)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation , mt.RootMaterialTypeId ,
			g.GradeName, g.GradeId, g.OrderNo
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type, g.OrderNo

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

/* testing

EXEC dbo.GetBhpbioReportBaseDataAsGrades
	@iDateFrom = '01-APR-2010',
	@iDateTo = '30-JUN-2010',
	@iDateBreakdown = 'QUARTER',
	@iLocationId = 4,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL,
	@iGrades = NULL
*/ 

IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsTonnes') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT
)
AS 
BEGIN
	-- for internal consumption only

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type)
	)
	
	DECLARE @Type TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		PRIMARY KEY CLUSTERED (Type)
	)

	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)

	DECLARE @Date TABLE
	(
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		CalendarDate DATETIME NOT NULL,
		PRIMARY KEY NONCLUSTERED (CalendarDate),
		UNIQUE CLUSTERED (DateFrom, DateTo, CalendarDate)
	)

	DECLARE @Location Table
	(
		LocationId INT NOT NULL,
		PRIMARY KEY CLUSTERED (LocationId)
	)

	DECLARE @Crusher Table
	(
		CrusherId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		PRIMARY KEY CLUSTERED (CrusherId)
	)

	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsTonnes',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END

	BEGIN TRY
		-- perform checks
		IF dbo.GetDateMonth(@iDateFrom) <> @iDateFrom
		BEGIN
			RAISERROR('The @iDateFrom parameter must be the first day of the month.', 16, 1)
		END

		IF (dbo.GetDateMonth(@iDateTo + 1) - 1) <> @iDateTo
		BEGIN
			RAISERROR('The @iDateTo parameter must be the last day of the month.', 16, 1)
		END

		IF NOT @iMaterialCategoryId IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('The Material Category parameter can only be Classification/Designation.', 16, 1)
		END

		IF @iMaterialCategoryId NOT IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('Only "Classification" and "Designation" are supported as material categories.', 16, 1)
		END

		-- load Block Model
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			VALUES
				('Actual', NULL)
		END

		IF (@iIncludeBlockModels = 1) AND (@iBlockModels IS NULL)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT Name, Block_Model_Id
			FROM dbo.BlockModel
		END
		ELSE IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT bm.Name, b.BlockModel.value('./@id', 'INT')
			FROM @iBlockModels.nodes('/BlockModels/BlockModel') AS b(BlockModel)
				INNER JOIN dbo.BlockModel AS bm
					ON (bm.Block_Model_Id = b.BlockModel.value('./@id', 'INT'))
		END
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)

		-- load the date range
		INSERT INTO @Date
			(DateFrom, DateTo, CalendarDate)
		SELECT DateFrom, DateTo, CalendarDate
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1)


		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(NULLIF(Tonnes, 0.0))
			FROM
				(
					-- C - z + y

					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
					
					UNION ALL

					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId

					UNION ALL

					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value)
					FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT bm.Type, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value)
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL) AS m
				INNER JOIN @Type AS bm
					ON (m.BlockModelId = bm.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
			WHERE m.Attribute = 0
			GROUP BY bm.Type, m.CalendarDate, mc.RootMaterialTypeId
		END

		-- return the result		
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			Sum(r.Tonnes) As Tonnes
		FROM
			-- display all dates
			@Date AS d
			-- display all elisted types (block models + actual)
			CROSS JOIN @Type AS t
			-- ensure material types are represented uniformly
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
				) AS mt
			-- pivot in the results
			LEFT OUTER JOIN @Tonnes AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation, mt.RootMaterialTypeId
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

IF OBJECT_ID('dbo.IsBhpbioApprovalOtherMovementDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate  
GO 
    
CREATE PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oMovementsExist BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonth)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalOtherMovementDate',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		-- Updated the locations
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
		-- Obtain the Block Model XML
		SELECT @BlockModelXml = @BlockModelXml + '<BlockModel id="' + CAST(Block_Model_Id AS VARCHAR) + '"/>'
		FROM dbo.BlockModel
		SET @BlockModelXml = '<BlockModels>' + @BlockModelXml + '</BlockModels>'
		
		-- load the base data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @DateFrom,
			@iDateTo = @DateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = 1,
			@iBlockModels = @BlockModelXml,
			@iIncludeActuals = 1,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = NULL
			

		-- Put the block model tonnes in.
		IF (SELECT Sum(Tonnes)
			FROM @Tonnes AS T
			WHERE T.Material NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
				AND T.Material IS NOT NULL) > 0
		BEGIN
			SET @oMovementsExist = 1
		END
		ELSE
		BEGIN
			SET @oMovementsExist = 0
		END
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsBhpbioApprovalOtherMovementDate TO BhpbioGenericManager

GO


IF OBJECT_ID('dbo.IsBhpbioAllOtherMovementsApproved') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioAllOtherMovementsApproved  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioAllOtherMovementsApproved
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oAllApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @PitLocationTypeId TinyInt
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioAllOtherMovementsApproved',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		SET @MonthDate = dbo.GetDateMonth(@iMonth)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))
		SET @PitLocationTypeId = (SELECT Location_Type_Id FROM LocationType WHERE Description = 'Pit')
		
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
										
		-- If the block has been approved for on the month, return true
		IF EXISTS	(
					SELECT *
					FROM (
							SELECT dbo.GetLocationTypeLocationId(L.LocationId, @PitLocationTypeId) AS PitLocation
							FROM dbo.Digblock AS D
								INNER JOIN dbo.DigblockLocation AS DL
									ON (D.Digblock_Id = DL.Digblock_Id)
								INNER JOIN @Location AS L
									ON (L.LocationId = DL.Location_Id)
								INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
									ON (RM.DateFrom >= @MonthDate
										AND RM.DateTo <= @EndMonthDate
										AND DL.Location_Id = RM.BlockLocationId)
							) P
						LEFT JOIN dbo.BhpbioApprovalData AS BAD
							ON (P.PitLocation = BAD.LocationId
								AND BAD.ApprovedMonth = @MonthDate
								AND TagId IN (SELECT BRDT.TagId FROM dbo.BhpbioReportDataTags BRDT WHERE TagGroupId = 'OtherMaterial')
								)
					WHERE BAD.TagId Is Null
					)
		BEGIN
			SET @ReturnValue = 0
		END
		ELSE
		BEGIN
			SET @ReturnValue = 1
		END

		SET @oAllApproved = @ReturnValue

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsBhpbioAllOtherMovementsApproved TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioAllOtherMovementsApproved 3, '1-nov-2009', @TEST OUTPUT
SELECT @TEST
*/


/* testing

EXEC dbo.GetBhpbioReportBaseDataAsTonnes
	@iDateFrom = '01-APR-2008',
	@iDateTo = '30-JUN-2008',
	@iDateBreakdown = NULL,
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL
*/

IF OBJECT_ID('dbo.IsBhpbioAllF1Approved') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioAllF1Approved  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioAllF1Approved
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oAllApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @PitLocationTypeId TinyInt
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioAllF1Approved',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		SET @MonthDate = dbo.GetDateMonth(@iMonth)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))
		SET @PitLocationTypeId = (SELECT Location_Type_Id FROM LocationType WHERE Description = 'Pit')
		
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
							
		-- If the block has been approved for on the month, return true
		IF EXISTS	(
					SELECT *
					FROM (
							SELECT dbo.GetLocationTypeLocationId(L.LocationId, @PitLocationTypeId) AS PitLocation
							FROM dbo.Digblock AS D
								INNER JOIN dbo.DigblockLocation AS DL
									ON (D.Digblock_Id = DL.Digblock_Id)
								INNER JOIN @Location AS L
									ON (L.LocationId = DL.Location_Id)
								INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
									ON (RM.DateFrom >= @MonthDate
										AND RM.DateTo <= @EndMonthDate
										AND DL.Location_Id = RM.BlockLocationId)
							) P
						LEFT JOIN dbo.BhpbioApprovalData AS BAD
							ON (P.PitLocation = BAD.LocationId
								AND BAD.ApprovedMonth = @MonthDate
								AND TagId IN (SELECT BRDT.TagId FROM dbo.BhpbioReportDataTags BRDT WHERE TagGroupId = 'F1Factor')
								)
					WHERE BAD.TagId Is Null
					)
		BEGIN
			SET @ReturnValue = 0
		END
		ELSE
		BEGIN
			SET @ReturnValue = 1
		END

		SET @oAllApproved = @ReturnValue

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsBhpbioAllF1Approved TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioAllF1Approved 3, '1-nov-2009', @TEST OUTPUT
SELECT @TEST
*/


IF OBJECT_ID('dbo.IsBhpbioApprovalPitMovedDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalPitMovedDate  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioApprovalPitMovedDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oMovementsExist BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalPitMovedDate',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		SET @MonthDate = dbo.GetDateMonth(@iMonth)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))

		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)

		-- If the location/pit has movements
		IF EXISTS	(
					SELECT d.Digblock_Id
					FROM dbo.Digblock AS D
						INNER JOIN dbo.DigblockLocation AS DL
							ON (D.Digblock_Id = DL.Digblock_Id)
						INNER JOIN @Location AS L
							ON (L.LocationId = DL.Location_Id)
						INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
							ON (RM.DateFrom >= @MonthDate
								AND RM.DateTo <= @EndMonthDate
								AND DL.Location_Id = RM.BlockLocationId)
					)
		BEGIN
			SET @ReturnValue = 1
		END
		ELSE
		BEGIN
			SET @ReturnValue = 0
		END

		SET @oMovementsExist = @ReturnValue

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsBhpbioApprovalPitMovedDate TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioApprovalPitMovedDate 2615, '1-jan-2008', @TEST OUTPUT
SELECT @TEST
*/

IF OBJECT_ID('dbo.AddOrUpdateBhpbioCustomMessage') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioCustomMessage
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioCustomMessage
(
	@iName VARCHAR(63),
	@iUpdateText BIT,
	@iText VARCHAR(MAX),
	@iUpdateExpirationDate BIT,
	@iExpirationDate DATETIME,
	@iUpdateIsActive BIT,
	@iIsActive BIT
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioCustomMessage',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY

		
		IF NOT EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioCustomMessage
				WHERE Name = @iName
			)
		BEGIN
			INSERT INTO dbo.BhpbioCustomMessage
			(
				Name, Text, ExpirationDate, IsActive
			)
			SELECT @iName, @iText, @iExpirationDate, @iIsActive
		END
		ELSE
		BEGIN
			UPDATE CM
			SET Text = CASE WHEN @iUpdateText = 1 THEN @iText ELSE Text END,
				ExpirationDate = CASE WHEN @iUpdateExpirationDate = 1 THEN @iExpirationDate ELSE ExpirationDate END,
				IsActive = CASE WHEN @iUpdateIsActive = 1 THEN @iIsActive ELSE IsActive END
			FROM dbo.BhpbioCustomMessage AS CM
			WHERE Name = @iName
		END
		

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioCustomMessage TO BhpbioGenericManager
GO
