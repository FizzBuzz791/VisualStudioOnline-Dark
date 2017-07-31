If Object_ID('GetBhpbioReportLocationBreakdownWithNames') Is Not Null 
     Drop Procedure [GetBhpbioReportLocationBreakdownWithNames]
Go 

Create Procedure [dbo].[GetBhpbioReportLocationBreakdownWithNames]
(
	@iLocationId Int,
	@iGetChildLocations Bit,
	@iDateTime DateTime,
	@iLowestLocationTypeDescription Varchar(31) = 'Pit'
)
As
Begin
	
	Select 
		ls.LocationId as Location_Id,
		l.Location_Type_Id,
		l.Parent_Location_Id,
		lt.Description as Location_Type_Description,
		l.Name,
		sl.Name as SiteName,
		hl.Name as HubName
	From [dbo].[GetBhpbioReportLocationBreakdownWithOverride](@iLocationId, 0, @iLowestLocationTypeDescription, @iDateTime, @iDateTime) ls
		Inner Join Location l 
			On l.Location_Id = ls.LocationId
		Inner Join LocationType lt
			On lt.Location_Type_Id = l.Location_Type_Id
		Left Outer Join Location sl
			On sl.Location_id = dbo.GetParentLocationByLocationType(l.Location_Id, 'Site', @iDateTime)
		Left Outer Join Location hl
			On hl.Location_id = dbo.GetParentLocationByLocationType(l.Location_Id, 'Hub', @iDateTime)
	Order By Location_Type_Id
End
Go

Grant Execute On dbo.GetBhpbioReportLocationBreakdownWithNames To BhpbioGenericManager

GO