  
If Exists (Select * From dbo.sysobjects Where id = object_id(N'[dbo].[GetBhpbioHaulageCorrectionList]') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure [dbo].[GetBhpbioHaulageCorrectionList]
GO

CREATE Procedure [dbo].[GetBhpbioHaulageCorrectionList]
(
	@iFilter_Source Varchar(63) = Null,
	@iFilter_Destination Varchar(63) = Null,
	@iFilter_Description Varchar(255) = Null,
	@iTop Bit = 0,
	@iRecordLimit Int = Null,
	@iLocationId Int = Null
)


As
/*-----------------------------------------------------------------------------
--  Name: GetBhpbioHaulageCorrectionList
--  Purpose: Returns a list of the haulage in HALUAGE_RAW table with filters applied.
--  Parameters: @iFilter_Source - Returned haulage records must have this source unless null.
--				@iFilter_Destination - Returned haulage records must have this destination unless null.
--				@iFilter_Description - Returned haulage records must have this description unless null.
--				@iTop - If flagged only return the top X number of records.
-- 
--  Comments: The @iTop filter allows only a smaller subset of data to be returned
--			   to the UI to reduce processing and load time.
--  
--  Created By:		Murray Hipper
--  Created Date: 	25 October 2006
--
------------------------------------------------------------------------------*/

Begin
	Set Nocount On

	Declare @Haulage_Error_List Table 
	(
		Haulage_Raw_Id Int,
		Haulage_Date Datetime,
		Haulage_Shift_Str Varchar(63), 
		Source Varchar(255),
		Destination Varchar(255),
		Description Varchar(255)
	)

	Declare @Total_Records Int
	Declare @Top_Records Int
	DECLARE @LocationTypeId TINYINT
	DECLARE @HaulageLocationTypeId TINYINT
	
	IF @iLocationId IS NULL Or @iLocationId = -1
	BEGIN
		SELECT @iLocationId = Location_Id
		FROM Location L
			INNER JOIN LocationType LT
				On L.Location_Type_Id = LT.Location_Type_Id
		WHERE LT.Description = 'Company'
	END		
	
	SELECT @LocationTypeId = Location_Type_Id
	FROM Location
	Where Location_Id = @iLocationId
	
	SELECT @HaulageLocationTypeId = Location_Type_Id
	FROM LocationType
	Where Description = 'Site'
	
	/* Get the full list of haulage errors */
	Insert Into @Haulage_Error_List
	Select HR.Haulage_Raw_Id, HR.Haulage_Date,
		dbo.GetShiftTypeName(HR.Haulage_Shift), 
		HR.Source, HR.Destination, HRET.Description
	From HaulageRaw HR
		Inner Join HaulageRawError HRE 
			On HR.Haulage_Raw_Id = HRE.Haulage_Raw_Id
		Inner Join HaulageRawErrorType HRET 
			On HRE.Haulage_Raw_Error_Type_Id = HRET.Haulage_Raw_Error_Type_Id
		LEFT JOIN dbo.HaulageRawLocation AS HRL
			ON HRL.HaulageRawId = HR.Haulage_Raw_Id
		LEFT JOIN dbo.Location AS L
			ON L.Location_Id = HRL.SourceLocationId
	Where HR.Haulage_Raw_State_Id = 'E'
		And ((@iFilter_Source Is Null) Or (@iFilter_Source = HR.Source))
		And ((@iFilter_Destination Is Null) Or (@iFilter_Destination = HR.Destination))
		And ((@iFilter_Description Is Null) Or (@iFilter_Description = HRET.Description))
		AND (  dbo.GetLocationTypeLocationId(L.Location_Id, @LocationTypeId) = @iLocationId
					OR L.Location_Id IS NULL )
	Order By HR.Haulage_Date, dbo.GetShiftTypeOrderNo(HR.Haulage_Shift)
 
	Set @Top_Records = @iRecordLimit
	Select @Total_Records = Count(*) 
	From @Haulage_Error_List

	If @iTop = 1 And @Total_Records > @Top_Records
	Begin

		Set Rowcount @Top_Records
		
		Select * 
		From @Haulage_Error_List
		Union All
		Select -1, 0, '...' + Cast(@Total_Records - @Top_Records As Varchar) + ' more.', '', '', ''
		
		Set Rowcount 0

	End
	Else
	Begin
		Select * 
		From @Haulage_Error_List
	End
	
End
GO
GRANT EXECUTE ON dbo.GetBhpbioHaulageCorrectionList TO BhpbioGenericManager


/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioHaulageCorrectionList">
 <Procedure>
	Returns a list of the haulage in HALUAGE_RAW table with filters applied.
	The @iTop filter allows only a smaller subset of data to be returned
	to the UI to reduce processing and load time.
	Errors are not raised.
 </Procedure>
</TAG>
*/

