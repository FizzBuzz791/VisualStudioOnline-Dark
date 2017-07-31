
IF OBJECT_ID('dbo.GetBhpbioSiteMaps') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSiteMaps
GO 
  
CREATE PROCEDURE dbo.GetBhpbioSiteMaps
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @SiteLocatinTypeId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioSiteMaps',
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
	
	DECLARE @SiteList TABLE (
		SettingId Varchar(31) Collate Database_Default
	)
	DECLARE @SiteListNotExists TABLE (
		SettingId Varchar(31) Collate Database_Default
	)
	
	-- these locations ids need to be treated as a special case
	-- either always included or always excluded from the list
	-- of buttons on the homepage
	DECLARE @SpecialCaseLocationIds TABLE (
		LocationId Int,
		AlwaysInclude Bit,
		AlwaysExclude Bit
	)
	
	BEGIN TRY
	
		SELECT @SiteLocatinTypeId = Location_Type_Id 
		FROM LocationType 
		WHERE Description = 'Site'
		
		-- Yarrie has to always be excluded from the list of 
		-- buttons on the home page
		INSERT INTO @SpecialCaseLocationIds
			SELECT Location_Id, 0, 1
			FROM Location
			WHERE Name like '%Yarrie%'
		
		-- NJV has to always be included from the list of 
		-- buttons on the home page (even though it is not a
		-- site)
		INSERT INTO @SpecialCaseLocationIds
			SELECT Location_Id, 1, 0
			FROM Location
			WHERE Name = 'NJV' 
				AND Location_Type_Id = 2
			
		-- Get Current Site List
		INSERT INTO @SiteList
			SELECT 'BHPBIO_SITELIST_' + Replace(Name, ' ', '_') 
			FROM Location l
				LEFT JOIN @SpecialCaseLocationIds inc 
					ON inc.LocationId = l.Location_Id
				LEFT JOIN @SpecialCaseLocationIds exc 
					ON exc.LocationId = l.Location_Id 
						AND exc.AlwaysExclude = 1
			WHERE (Location_Type_Id = @SiteLocatinTypeId OR inc.LocationId IS NOT NULL)
				AND exc.LocationId IS NULL

		-- Check/Update/Insert Sites on Setting Table
		INSERT INTO @SiteListNotExists
			SELECT SettingId 
			FROM @SiteList AS A
			WHERE NOT EXISTS 
				(SELECT Setting_Id
				 FROM Setting 
				 WHERE A.SettingId = Setting.Setting_Id)

		-- Insert New Sites into Setting table
		INSERT INTO Setting
			SELECT SettingId, 'Link to the current Site Map', 'STRING', 1, 'http://snowdengroup.com', null 
			FROM @SiteListNotExists

		SELECT Setting_Id, Value 
		FROM Setting 
		WHERE Setting_Id like 'BHPBIO_SITELIST_%'
			AND Setting_Id in (SELECT SettingId FROM @SiteList)

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

GRANT EXECUTE ON dbo.GetBhpbioSiteMaps TO BhpbioGenericManager
GO
