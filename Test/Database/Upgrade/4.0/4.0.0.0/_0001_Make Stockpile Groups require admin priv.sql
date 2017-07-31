DECLARE @restrictedGroups VARCHAR(255)
SET @restrictedGroups = 'Port Train Rake,Post Crusher,ROM,Bene Fines,Bene Reject,Crusher Product,Bene Product,HUB Train Rake,ReportExclude,ReportExclude HvP,'
DECLARE @stockpilegroupfieldid VARCHAR(31)
SET @stockpilegroupfieldid ='ADMIN_EDITABLE_ONLY'

DECLARE @pos INT
SET @pos = 0
DECLARE @len INT
SET @len = 0

WHILE CHARINDEX(',', @restrictedGroups, @pos+1)>0
BEGIN
    set @len = CHARINDEX(',', @restrictedGroups, @pos+1) - @pos
	DECLARE @stockpile VARCHAR(32)
    set @stockpile = SUBSTRING(@restrictedGroups, @pos, @len)

	DECLARE @stockpileExists BIT
	SET  @stockpileExists = (SELECT CAST(COUNT(*) AS BIT) FROM [dbo].[StockpileGroup] WHERE [Stockpile_Group_Id]=@stockpile)

	PRINT @stockpile
	PRINT @stockpileExists
	IF(@stockpileExists=1)
	BEGIN
	    DECLARE @isAlreadySet BIT
        SET @isAlreadySet= (SELECT CAST(COUNT(*) AS BIT) FROM [dbo].[StockpileGroupNotes] WHERE (Stockpile_Group_Id=@stockpile AND Stockpile_Group_Field_Id=@stockpilegroupfieldid))

		IF(@isAlreadySet=0)
		BEGIN
			INSERT INTO [dbo].[StockpileGroupNotes] (Stockpile_Group_Id,Stockpile_Group_Field_Id,Notes) 
			SELECT @stockpile ,@stockpilegroupfieldid,'TRUE'
		END 
	END



    SET @pos = CHARINDEX(',', @restrictedGroups, @pos+@len) +1
END
GO



