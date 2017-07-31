If Object_ID('GetParentLocationByLocationType') Is Not Null
     Drop Function GetParentLocationByLocationType
Go 

-- Returns the location id of a parent location of the given type
-- if such a location doesn't exist in the parent heirachy, then we
-- just return null

Create Function GetParentLocationByLocationType
(
	-- Add the parameters for the function here
	@LocationId Int,
	@ParentLocationTypeName nvarchar(32),
	@LocationDate Datetime
)
Returns Int
As
Begin
Declare @result Int
	Declare @currentLocationId int
	Declare @parentLocationId int
	Declare @currentLocationTypeId int
	Declare @targetLocationTypeId int
	
	Set @currentLocationId = @LocationId
	-- Set @LocationDate = Coalesce(@LocationDate, Getdate())
	
	-- the user passes in a description for the target location type. We need to 
	-- convert this to an id for easy comparision
	Select @targetLocationTypeId = Location_Type_Id
	From LocationType
	Where Description = @ParentLocationTypeName
	
	-- get the location type and parent id of the current location (ie, the id that was passed in)
	Select 
		@parentLocationId = Coalesce(lo.Parent_Location_Id, l.Parent_Location_Id),
		@currentLocationTypeId = Coalesce(lo.Location_Type_Id, l.Location_Type_Id)
	From Location l
		Left Join BhpbioLocationOverride lo 
			On lo.Location_Id = l.Location_Id 
				And @LocationDate Between lo.FromMonth And lo.ToMonth
	Where l.Location_Id = @currentLocationId
	
	-- the current location is the same as the target type. Return the current location id
	-- This is maybe not always what we want, but oh well
	If @currentLocationTypeId = @targetLocationTypeId
		Return @currentLocationId
	
	Set @currentLocationId = @parentLocationId

	-- loop through the heirachy until we reach the target type, then return that id
	-- if we don't find the target type before reaching the top, then just return null
	-- we will know we have reached the top, because that location will have a parent 
	-- location id of null
	While @currentLocationId Is Not Null
	Begin

		Select 
			@parentLocationId = Coalesce(lo.Parent_Location_Id, l.Parent_Location_Id),
			@currentLocationTypeId = Coalesce(lo.Location_Type_Id, l.Location_Type_Id)
		From Location l
			Left Join BhpbioLocationOverride lo 
				On lo.Location_Id = l.Location_Id 
					And @LocationDate Between lo.FromMonth And lo.ToMonth
		Where l.Location_Id = @currentLocationId
		
		If @currentLocationTypeId = @targetLocationTypeId
		Begin
			Set @result = @currentLocationId
			Break
		End
		
		Set @currentLocationId = @parentLocationId
		
	End

	Return @result
End
Go

