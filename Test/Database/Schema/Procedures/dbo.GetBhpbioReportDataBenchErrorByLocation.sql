If OBJECT_ID('dbo.GetBhpbioReportDataBenchErrorByLocation') Is Not Null
     Drop Procedure dbo.GetBhpbioReportDataBenchErrorByLocation
Go 
 
-- This proc is meant to produce data for the 'Bench Error Distribution by Location Report'
--
-- It gets the difference between two models as a absolute error factor. Ie if Model1 / Model2 gives
-- the factor, then the factor error would be Abs(1 - Model1 / Model2). So a factor of 1.02 would have
-- an error of 0.02, as would a factor result of 0.98. These factor errors are then ranked so that
-- they can be visualized on a pareto chart
--
-- @MinimumTonnes: Any Benches (NOT Blocks) with tonnes below the minimum passed in are excluded from the calculation
--
-- In combined mode (ie. both @iIncludeLiveData & @iIncludeApprovedData are set), if a block has a summarized
-- value, then this value is used in preference to the live value.
--
-- @GroupOnSublocations: 
--  When this is turned on the GroupLocationId field will be the set to the sublocations of the one passed in
--  when not set it is the GroupLocationId and the Ranking will be done over the whole dataset
--
-- @SummarizeData: 
--  When true this summarizes the data up to the GroupLocationId level, so that there is only a single row
--  for each grade and location. If GroupOnSublocations is turned off, then there will only by a single row
--  for each grade.
--
-- (7 Oct 2014, Alex Barmouta)
-- @DesignationMaterialTypeId
-- Added paramter to filter on designation material type, which is a material type with material category of 'Designation'.
--
-- At the current time (July-2014) this stored proc is used by THREE different reports, so think carefully when making changes
--
Create Procedure dbo.GetBhpbioReportDataBenchErrorByLocation
(
	@DateFrom Datetime,
	@DateTo Datetime,
	@LocationId Int,
	@BlockModelId1 Int,
	@BlockModelId2 Int,
	@MinimumTonnes Float,
	@iIncludeLiveData Bit,
	@iIncludeApprovedData Bit,
	@GroupOnSublocations Bit = 1,
	@SummarizeData Bit = 0,
	@DesignationMaterialTypeId Int = 0,
	@LocationGrouping Varchar(31) = Null
)
With Encryption
As 
Begin
	
	Declare @BlockData Table
	(
		BlockLocationId Int Not Null,
		BlastLocationId Int Null,
		BenchLocationId Int Null,
		PitLocationId Int Null,
		SiteLocationId Int Null,
		HubLocationId Int Null,
		CompanyLocationId Int Null,
		BlockNumber VARCHAR(16),
		Pit VARCHAR(10),
		DateFrom Datetime Not Null,
		DateTo Datetime Not Null,
		MinedPercentage Float,
		Primary Key (BlockLocationId, DateTo, Pit, BlockNumber)
	)

	Declare @ModelResults Table
	(
		LocationId Int,
		GroupLocationId Int,
		BlockModelId Int,
		Tonnes Float,
		GradeId Int,
		Grade Varchar(32),
		GradeValue Float
	)
	
	Declare @ModelOneResult Table
	(
		LocationId Int,
		GroupLocationId Int,
		BlockModelId Int,
		GradeId Int,
		Grade Varchar(32),
		GradeValue Float
	)

	Declare @ModelTwoResult Table
	(
		LocationId Int,
		GroupLocationId Int,
		BlockModelId Int,
		GradeId Int,
		Grade Varchar(32),
		GradeValue Float
	)
	
	Declare @GradeControlBlockModelId Int
		
	Select @GradeControlBlockModelId = Block_Model_Id
	From BlockModel
	Where Name = 'Grade Control'
		
	Declare @GradeControlBenchTonnes Table (
		LocationId Int,
		MinedTonnes Float
	)
		
	Declare @GroupingLocationTypeName Varchar(64)
	Declare @DesignationMaterialCategory Varchar(31)
	
	Set @DesignationMaterialCategory = 'Designation'
	
	If @GroupOnSublocations = 1
	Begin
		If @LocationGrouping Is Null
		Begin
			-- we want to group the benches at the location under the one passed in, so we get the 
			-- first child of the passed in locations locationType
			Select Top 1 @GroupingLocationTypeName = [Description]
			From LocationType 
			Where Parent_Location_Type_Id = 
			(
				Select Location_Type_Id
				From Location
				Where Location_Id = @LocationId
			)
			-- make exception for Pit locations as it doesn't make sense to group by Bench in the context of this report (refer to Jira WREC163)
			If @GroupingLocationTypeName = 'Bench' And @SummarizeData = 0
			Begin
				Set @GroupingLocationTypeName = 'Pit'
			End
		End
		Else
		Begin
			Set @GroupingLocationTypeName = @LocationGrouping
		End
	End
	Else
	Begin
		Select Top 1 @GroupingLocationTypeName = [Description]
		From LocationType 
		Where Location_Type_Id = (Select Location_Type_Id From Location Where Location_Id = @LocationId)
	End


	If @iIncludeLiveData = 1
	Begin
	

		
		Declare @ExcludedLocations Table (
			LocationId Int,
			Primary Key (LocationId)
		)

		If @iIncludeApprovedData = 1
		Begin
			-- these locations have summary data for the given locations. We want to exclude them from the dataset
			-- (but only if the stored proc is being run in combined live/summary mode)
			Insert Into @ExcludedLocations
				Select Distinct(LocationId)
				From BhpbioSummaryEntry se
					Inner Join BhpbioSummary s 
						On s.SummaryId = se.SummaryId
					Inner Join BhpbioSummaryEntryType st 
						On st.SummaryEntryTypeId = se.SummaryEntryTypeId
				Where 
					s.SummaryMonth Between @DateFrom And @DateTo And
					st.AssociatedBlockModelId In (@BlockModelId1, @BlockModelId2) And st.Name like '%ModelMovement'

		End

		-- this table contains the raw depletion data for all the child blocks of the passed in location
		-- we can then use to get the tonnes + grade values
		Insert Into @BlockData
			Select BlockLocationId, BlastLocationId, BenchLocationId, PitLocationId, SiteLocationId, HubLocationId, CompanyLocationId, 
					BlockNumber, Pit, DateFrom, DateTo, MinedPercentage 
		From dbo.GetBhpbioReportReconBlockLocations(@LocationId, @DateFrom, @DateTo, 0)
		
		Delete From @GradeControlBenchTonnes
		Insert Into @GradeControlBenchTonnes
			Select
				bl.BenchLocationId,
				Sum(mbp.Tonnes * bl.MinedPercentage) as MinedTonnes
			From @BlockData bl
				Inner Join ModelBlockLocation mbl 
					On mbl.Location_Id = bl.BlockLocationId
				Inner Join ModelBlock mb 
					On mb.Model_Block_Id = mbl.Model_Block_Id
				Inner Join ModelBlockPartial mbp
					On mbp.Model_Block_Id = mb.Model_Block_Id
			Where mb.Block_Model_Id = @GradeControlBlockModelId
			Group By bl.BenchLocationId
		
		-- first we calculate just the tonnes...
		Insert Into @ModelResults
		(
			LocationId, GroupLocationId, BlockModelId, Tonnes, GradeId, Grade, GradeValue
		)
		Select
			bl.BenchLocationId,
			Null As GroupLocationId,
			mb.Block_Model_Id As BlockModelId,
			Sum(mbp.Tonnes * bl.MinedPercentage) as Tonnes,
			0,
			'Tonnes',
			Sum(mbp.Tonnes * bl.MinedPercentage)
		From @BlockData bl
			Inner Join ModelBlockLocation mbl 
				On mbl.Location_Id = bl.BlockLocationId
			Inner Join ModelBlock mb 
				On mb.Model_Block_Id = mbl.Model_Block_Id
			Inner Join ModelBlockPartial mbp
				On mbp.Model_Block_Id = mb.Model_Block_Id
			Inner Join dbo.GetMaterialsByCategory(@DesignationMaterialCategory) mt
				On mbp.Material_Type_Id = mt.MaterialTypeId
		Where mb.Block_Model_Id In (@BlockModelId1, @BlockModelId2)
			And bl.BlockLocationId Not In (Select LocationId from @ExcludedLocations) -- subselect here is MUCH faster than join...
			And (mt.RootMaterialTypeId = @DesignationMaterialTypeId Or @DesignationMaterialTypeId = 0) --filter on designation material type
		Group By mb.Block_Model_Id, bl.SiteLocationId, bl.BenchLocationId
		Having (
			Select gc.MinedTonnes 
			From @GradeControlBenchTonnes gc 
			Where gc.LocationId = bl.BenchLocationId
		) > @MinimumTonnes
			
		--- ...then the grades
		Insert Into @ModelResults
		(
			LocationId, GroupLocationId, BlockModelId, Tonnes, GradeId, Grade, GradeValue
		)
		Select
			bl.BenchLocationId,
			null As GroupLocationId,
			mb.Block_Model_Id As BlockModelId,
			Sum(mbp.Tonnes * bl.MinedPercentage),
			mbpg.Grade_Id,
			g.Grade_Name,
			Sum(mbpg.Grade_Value * mbp.Tonnes * bl.MinedPercentage) / Sum(mbp.Tonnes * bl.MinedPercentage)
		From @BlockData bl
			Inner Join ModelBlockLocation mbl 
				On mbl.Location_Id = bl.BlockLocationId
			Inner Join ModelBlock mb 
				On mb.Model_Block_Id = mbl.Model_Block_Id
			Inner Join ModelBlockPartial mbp 
				On mbp.Model_Block_Id = mb.Model_Block_Id
			Inner Join dbo.GetMaterialsByCategory(@DesignationMaterialCategory) mt
				On mbp.Material_Type_Id = mt.MaterialTypeId
			Inner Join ModelBlockPartialGrade mbpg 
				On mbpg.Model_Block_Id = mb.Model_Block_Id 
					And mbpg.Sequence_No = mbp.Sequence_No
			Inner Join Grade g 
				On g.Grade_Id = mbpg.Grade_Id
		Where mb.Block_Model_Id In (@BlockModelId1, @BlockModelId2)
			And bl.BlockLocationId Not In (Select LocationId from @ExcludedLocations) -- subselect here is MUCH faster than join...
			And (mt.RootMaterialTypeId = @DesignationMaterialTypeId Or @DesignationMaterialTypeId = 0) --filter on designation material type
		Group By 
			mb.Block_Model_Id,
			bl.SiteLocationId,
			bl.BenchLocationId,
			mbpg.Grade_Id,
			g.Grade_Name
		Having (
			Select gc.MinedTonnes 
			From @GradeControlBenchTonnes gc 
			Where gc.LocationId = bl.BenchLocationId
		) > @MinimumTonnes

	End

	If @iIncludeApprovedData = 1
	Begin

		
		Declare @Location Table
		(
			LocationId Int Not Null,
			ParentLocationId Int Null,
			IncludeStart Datetime Not Null,
			IncludeEnd Datetime Not Null
			Primary Key (LocationId, IncludeStart)
		)

		-- setup the valid location that we are looking for from the summary table.
		-- this is actually pretty slow, but I could find a better way to do it. I suppose
		-- we could just get the data for all locations and just filter later?
		Insert Into @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		Select LocationId, ParentLocationId, IncludeStart, IncludeEnd
		From dbo.GetBhpbioReportLocationBreakdownWithOverride(@LocationId, 0, NULL, @DateFrom, @DateTo)

		Delete From @GradeControlBenchTonnes
		Insert Into @GradeControlBenchTonnes
			Select
				dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null) As BenchLocationId,
				Sum(se.Tonnes) as Tonnes
			From dbo.BhpbioSummary s
				Inner Join dbo.BhpbioSummaryEntry se 
					on se.SummaryId = s.SummaryId
				Inner Join dbo.BhpbioSummaryEntryType st
					on st.SummaryEntryTypeId = se.SummaryEntryTypeId
			Where s.SummaryMonth between @DateFrom And @DateTo
				And se.ProductSize = 'TOTAL'
				And st.AssociatedBlockModelId = @GradeControlBlockModelId 
				And st.Name like '%ModelMovement'
			Group By dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null)
		
		-- first calculate the tonnes values
		Insert Into @ModelResults
		(
			LocationId, GroupLocationId, BlockModelId, Tonnes, GradeId, Grade, GradeValue
		)
		Select
			dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null) As LocationId,
			null As GroupLocationId,
			st.AssociatedBlockModelId As BlockModelId,
			Sum(se.Tonnes) as Tonnes,
			0 As GradeId,
			'Tonnes' As Grade,
			Sum(se.Tonnes) As GradeValue
		From dbo.BhpbioSummaryEntry se
			Inner Join dbo.BhpbioSummary s 
				On s.SummaryId = se.SummaryId
			Inner Join dbo.BhpbioSummaryEntryType st 
				On st.SummaryEntryTypeId = se.SummaryEntryTypeId
					And st.Name Like '%ModelMovement'
			Inner Join @Location l 
				On l.locationId = se.locationId
					And s.SummaryMonth Between l.IncludeStart And l.IncludeEnd
			Inner Join dbo.GetMaterialsByCategory(@DesignationMaterialCategory) mt
				On se.MaterialTypeId = mt.MaterialTypeId
		Where st.AssociatedBlockModelId In (@BlockModelId1, @BlockModelId2)
			And s.SummaryMonth Between @DateFrom And @DateTo
			And se.ProductSize = 'TOTAL'
			And (mt.RootMaterialTypeId = @DesignationMaterialTypeId Or @DesignationMaterialTypeId = 0) --filter on designation material type
		Group By 
			st.AssociatedBlockModelId,
			dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null)
		Having (
			Select gc.MinedTonnes 
			From @GradeControlBenchTonnes gc 
			Where gc.LocationId = dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null)
		) > @MinimumTonnes

		-- now insert the actual grades
		Insert Into @ModelResults
		(
			LocationId, GroupLocationId, BlockModelId, Tonnes, GradeId, Grade, GradeValue
		)
		Select
			dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null) As LocationId,
			null As GroupLocationId,
			st.AssociatedBlockModelId As BlockModelId,
			Sum(se.Tonnes) as Tonnes,
			g.Grade_Id,
			g.Grade_Name As Grade,
			Sum(se.Tonnes * seg.GradeValue) / Sum(se.Tonnes) As GradeValue
		From dbo.BhpbioSummaryEntry se
			Inner Join @Location l 
				On l.locationId = se.locationId
			Inner Join dbo.BhpbioSummary s 
				On s.SummaryId = se.SummaryId
			Inner Join dbo.BhpbioSummaryEntryType st 
				On st.SummaryEntryTypeId = se.SummaryEntryTypeId
					And st.Name Like '%ModelMovement'
			Inner Join dbo.BhpbioSummaryEntryGrade seg 
				On seg.SummaryEntryId = se.SummaryEntryId
			Inner Join dbo.Grade g 
				On g.Grade_Id = seg.GradeId
			Inner Join dbo.GetMaterialsByCategory(@DesignationMaterialCategory) mt
				On se.MaterialTypeId = mt.MaterialTypeId
		Where st.AssociatedBlockModelId In (@BlockModelId1, @BlockModelId2)
			And s.SummaryMonth Between @DateFrom And @DateTo
			And se.ProductSize = 'TOTAL'
			And (mt.RootMaterialTypeId = @DesignationMaterialTypeId Or @DesignationMaterialTypeId = 0) --filter on designation material type
		Group By 
			st.AssociatedBlockModelId,
			dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null), g.Grade_Id, g.Grade_Name
		Having (
			Select gc.MinedTonnes 
			From @GradeControlBenchTonnes gc 
			Where gc.LocationId = dbo.GetParentLocationByLocationType(se.LocationId, 'Bench', null)
		) > @MinimumTonnes

	End
	
	-- get the parent location for each bench of the appropriate location type. This location type
	-- will always be the child of the location that was passed in. Ie, if the @LocationId is a Site,
	Update @ModelResults 
		Set GroupLocationId = dbo.GetParentLocationByLocationType(LocationId, @GroupingLocationTypeName, @DateFrom)
	Where GroupLocationId Is Null
	
	If @SummarizeData = 1	
	Begin
	
		Insert Into @ModelOneResult
			Select 
				GroupLocationId as LocationId,
				GroupLocationId,
				BlockModelId,
				GradeId,
				Grade,
				CASE WHEN Grade = 'Tonnes' THEN Sum(Tonnes) ELSE Sum(GradeValue * Tonnes) / Sum(Tonnes) END
			From @ModelResults 
			Where BlockModelId = @BlockModelId1
			Group By GroupLocationId, BlockModelId, GradeId, Grade

		Insert Into @ModelTwoResult
			Select 
				GroupLocationId as LocationId,
				GroupLocationId,
				BlockModelId,
				GradeId,
				Grade,
				CASE WHEN Grade = 'Tonnes' THEN Sum(Tonnes) ELSE Sum(GradeValue * Tonnes) / Sum(Tonnes) END
			From @ModelResults 
			Where BlockModelId = @BlockModelId2
			Group By GroupLocationId, BlockModelId, GradeId, Grade
	End
	Else
	Begin
		-- split the model into separate tables based on the BlockModelId, then we can
		-- join them together and get the factor error etc. Probably we could join the
		-- @ModelResults table to itself and avoid using these tables, but it is much
		-- clearer this way, and doesn't seem to make a performance difference
		Insert Into @ModelOneResult
			Select LocationId, GroupLocationId, BlockModelId, GradeId, Grade, GradeValue From @ModelResults Where BlockModelId = @BlockModelId1

		Insert Into @ModelTwoResult
			Select LocationId, GroupLocationId, BlockModelId, GradeId, Grade, GradeValue From @ModelResults Where BlockModelId = @BlockModelId2	
	End

	-- take the data we have so far (either live or sumary), and get the factor 
	-- error between the benches. This is what gets returned to the report
	Select 
		LocationId,
		sl.Name As SiteName,
		pl.Name As PitName,
		bl.Name As BenchName,
		GroupLocationId,
		-- When the grouping location is Bench.. and the location passed in is NOT the Pit.. then the Bench name must be prefixed with the Pit name as Bench is not unique
		CASE WHEN @GroupingLocationTypeName like 'Bench' AND pl.Location_Id IS NOT NULL AND pl.Location_Id <> @LocationId
			THEN pl.Name + ' ' + b.GroupLocationName
			ELSE b.GroupLocationName
		END AS GroupLocationName,
		GradeId,
		Grade,
		@DateFrom As DateFrom,
		@DateTo As DateTo,
		BlockModelId1,
		BlockModelId2,
		bm1.Name as BlockModelName1,
		bm2.Name as BlockModelName2,
		FactorValue,
		FactorError,
		Rank() Over (Partition By GroupLocationId, GradeId Order By FactorError) As FactorRank,
		Count(*) Over (Partition By GroupLocationId, GradeId) As FactorGroupCount,
		Case When mt.Description Is Null
			Then 'All'
			Else mt.Description
		End As Designation
	From 
	(
		Select 
			m1.LocationId,
			m1.GroupLocationId,
			l.Name As GroupLocationName,
			m1.GradeId,
			m1.Grade,
			m1.BlockModelId as BlockModelId1,
			m2.BlockModelId as BlockModelId2,
			(m1.GradeValue / m2.GradeValue)	As FactorValue,
			Abs(1 - (m1.GradeValue / m2.GradeValue)) As FactorError
		From @ModelOneResult m1
			Inner Join @ModelTwoResult m2 
				On m1.LocationId = m2.LocationId And m1.GradeId = m2.GradeId
			Inner Join Location l 
				On l.Location_Id = m1.GroupLocationId
		Where m2.GradeValue != 0
	) b
		Inner Join BlockModel bm1 
			On bm1.Block_Model_Id = b.BlockModelId1
		Inner Join BlockModel bm2
			On bm2.Block_Model_Id = b.BlockModelId2
		Left Join Location bl
			On b.LocationId = bl.Location_Id and (@SummarizeData = 0 OR @GroupingLocationTypeName like 'Bench')
		Left Join Location pl
			On pl.Location_Id = bl.Parent_Location_Id and (@SummarizeData = 0 OR @GroupingLocationTypeName like 'Bench')
		Left Join Location sl
			On sl.Location_Id = pl.Parent_Location_Id and (@SummarizeData = 0 OR @GroupingLocationTypeName like 'Bench')
		Left Join dbo.MaterialType mt
			On mt.Material_Type_Id = @DesignationMaterialTypeId
		
	Order By GroupLocationId, GradeId, FactorError
End 
Go

Grant Execute On dbo.GetBhpbioReportDataBenchErrorByLocation To BhpbioGenericManager
Go
		
/*
-- Usage:

exec dbo.GetBhpbioReportDataBenchErrorByLocation
		@DateFrom = '2013-01-01',
		@DateTo = '2013-01-31',
		@LocationId = 9,
		@BlockModelId1 = 2,
		@BlockModelId2 = 1,
		@MinimumTonnes = 0,
		@iIncludeLiveData = 1,
		@iIncludeApprovedData = 0,
		@GroupOnSublocations = 1,
		@SummarizeData  = 0,
		@DesignationMaterialTypeId  = 3,
		@LocationGrouping = 'BENCH'
*/
