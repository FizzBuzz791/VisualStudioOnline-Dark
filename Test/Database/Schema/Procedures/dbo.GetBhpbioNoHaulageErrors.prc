 If object_id('dbo.GetBhpbioNoHaulageErrors') is not Null 
     Drop Procedure dbo.GetBhpbioNoHaulageErrors 
Go 
  
Create Procedure dbo.GetBhpbioNoHaulageErrors 
( 
	@iLocationId INT = NULL,
    @NoErrors INT OUTPUT
) 
With Encryption
As 
Begin 
    Set NoCount On 
  
  	DECLARE @LocationTypeId TINYINT
	DECLARE @HaulageLocationTypeId TINYINT
	
	IF @iLocationId IS NULL
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
  
    Select @NoErrors = Count(*)
	FROM dbo.HaulageRawError E
		INNER JOIN dbo.HaulageRaw HR
			On HR.Haulage_Raw_Id = E.Haulage_Raw_Id
		LEFT JOIN dbo.HaulageRawLocation AS HRL
			ON HRL.HaulageRawId = HR.Haulage_Raw_Id
		LEFT JOIN dbo.Location AS L
			ON L.Location_Id = HRL.SourceLocationId
	WHERE HR.Haulage_Raw_State_Id = 'E'
		AND (  dbo.GetLocationTypeLocationId(L.Location_Id, @LocationTypeId) = @iLocationId
				OR L.Location_Id IS NULL )
	
End 
Go	
GRANT EXECUTE ON dbo.GetBhpbioNoHaulageErrors TO BhpbioGenericManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioNoHaulageErrors">
 <Procedure>
	Returns the number of Haulage Raw Errors.
 </Procedure>
</TAG>
*/