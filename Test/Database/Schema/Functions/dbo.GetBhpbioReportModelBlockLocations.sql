
IF OBJECT_ID('dbo.GetBhpbioReportModelBlockLocations') IS NOT NULL
     DROP Function dbo.GetBhpbioReportModelBlockLocations
GO 

-- Returns a table of all the locations from ModelBlockLocation where a given Block_Model_id
-- but it handles a special case for the Grade Control STG Model. This model has no data associated
-- with it, it is just a copy of the Grade Control model but with the data removed where locations
-- that there is no STGM data for.
--
-- Nathan Reed, 2014-03-26
Create Function [dbo].[GetBhpbioReportModelBlockLocations]
(
	@BlockModelId INT
)
Returns @ModelBlockLocations Table
(
	Model_Block_Id Integer,
	Location_Type_Id Tinyint,
	Location_Id Integer,
	PRIMARY KEY (Model_Block_Id, Location_Type_Id)
)
Begin

	Declare @IsSTGMGradeControl Bit
	Declare @ShortTermGeologyModelId Integer
	Declare @GradeControlSTGMId Integer
	
	Set @IsSTGMGradeControl = 0
	Set @ShortTermGeologyModelId = 4
	Set @GradeControlSTGMId = 5
	
	If @BlockModelId = @GradeControlSTGMId Begin
		Set @IsSTGMGradeControl = 1
		Select Top(1) @BlockModelId = Block_Model_Id From BlockModel Where Name = 'Grade Control'
	End
	
	If @IsSTGMGradeControl = 0 Begin
	
		Insert into @ModelBlockLocations
			Select 
				mbl.Model_Block_Id,
				mbl.Location_Type_Id,
				mbl.Location_Id
			From dbo.ModelBlockLocation mbl
				Inner Join dbo.ModelBlock mb 
					On mb.Model_Block_Id = mbl.Model_Block_Id
			Where 
				mb.Block_Model_Id = @BlockModelId 
	 
		End 
		Else Begin
		
		-- the same as the above query, but only for locations that we have STGM data for
		Insert into @ModelBlockLocations
			Select 
				mbl.Model_Block_Id,
				mbl.Location_Type_Id,
				mbl.Location_Id
			From dbo.ModelBlockLocation mbl
				Inner Join dbo.ModelBlock mb 
					On mb.Model_Block_Id = mbl.Model_Block_Id
			Where 
				mb.Block_Model_Id = @BlockModelId and 
				mbl.Location_Id in (Select mbl.Location_Id From dbo.ModelBlockLocation mbl Inner Join dbo.ModelBlock mb On mb.Model_Block_Id = mbl.Model_Block_Id Where mb.Block_Model_Id = @ShortTermGeologyModelId)
			
		End

	Return
End
