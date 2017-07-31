IF OBJECT_ID('dbo.GetBhpbioHaulageCorrectionListFilter') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioHaulageCorrectionListFilter
GO
CREATE PROCEDURE dbo.GetBhpbioHaulageCorrectionListFilter
(
	@iFilterType VARCHAR(31),
	@iLocationId INT = NULL
)

AS
/*-----------------------------------------------------------------------------
--  Name: GetBhpbioHaulageCorrectionListFilter
--  Purpose: Returns a list of all the Descriptions, Source or Destinations in 
--			 Haulage_Raw.
--  Parameters: @iFilterType - Type of filter. 
--					Valid: (Source | Destination | Description) 
-- 
--  Comments: -
--  
--  Created By:		Murray Hipper
--  Created Date: 	21 October 2006
--
--  Updated By:		Brian Acedo
--					Coding Standards Applied
------------------------------------------------------------------------------*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Filter_Table TABLE
	(
		Filter VARCHAR(255)
	)

	DECLARE @LocationTypeId TINYINT
	DECLARE @HaulageLocationTypeId TINYINT
	
	IF @iLocationId IS NULL OR @iLocationId = -1
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

	IF @iFilterType = 'Description'
	BEGIN
		INSERT INTO @Filter_Table 
		(
			Filter
		)
		SELECT DISTINCT hret.Description
		FROM dbo.HaulageRaw AS hr
			INNER JOIN dbo.HaulageRawError AS hre 
				ON hr.Haulage_Raw_Id = hre.Haulage_Raw_Id
			INNER JOIN dbo.HaulageRawErrorType AS hret 
				ON hre.Haulage_Raw_Error_Type_Id = hret.Haulage_Raw_Error_Type_Id
			LEFT JOIN dbo.HaulageRawNotes AS HRN
				ON HRN.Haulage_Raw_Id = HR.Haulage_Raw_Id
					AND HRN.Haulage_Raw_Field_Id = 'Site'
			LEFT JOIN dbo.Location AS L
				ON L.Name = HRN.Notes
					AND L.Location_Type_Id = @HaulageLocationTypeId
		WHERE Haulage_Raw_State_Id = 'E'
			AND ( dbo.GetLocationTypeLocationId(L.Location_Id, @LocationTypeId) = @iLocationId
					OR L.Location_Id IS NULL )
		ORDER BY Description
	END
	Else IF @iFilterType = 'Source'
	BEGIN
		INSERT INTO @Filter_Table 
		(
			Filter
		)
		SELECT DISTINCT HR.Source
		FROM dbo.HaulageRaw HR
			LEFT JOIN dbo.HaulageRawNotes AS HRN
				ON HRN.Haulage_Raw_Id = HR.Haulage_Raw_Id
					AND HRN.Haulage_Raw_Field_Id = 'Site'
			LEFT JOIN dbo.Location AS L
				ON L.Name = HRN.Notes
					AND L.Location_Type_Id = @HaulageLocationTypeId
		WHERE HR.Haulage_Raw_State_Id = 'E'
			AND (  dbo.GetLocationTypeLocationId(L.Location_Id, @LocationTypeId) = @iLocationId
					OR L.Location_Id IS NULL )
		ORDER BY Source
	END
	Else IF @iFilterType = 'Destination'
	BEGIN
		INSERT INTO @Filter_Table 
		(
			Filter
		)
		SELECT DISTINCT HR.Destination
		FROM dbo.HaulageRaw HR
			LEFT JOIN dbo.HaulageRawNotes AS HRN
				ON HRN.Haulage_Raw_Id = HR.Haulage_Raw_Id
					AND HRN.Haulage_Raw_Field_Id = 'Site'
			LEFT JOIN dbo.Location AS L
				ON L.Name = HRN.Notes
					AND L.Location_Type_Id = @HaulageLocationTypeId
		WHERE HR.Haulage_Raw_State_Id = 'E'
			AND (  dbo.GetLocationTypeLocationId(L.Location_Id, @LocationTypeId) = @iLocationId
					OR L.Location_Id IS NULL )
		ORDER BY Destination
	END

	SELECT Filter
	FROM @Filter_Table
END
GO
GRANT EXECUTE ON dbo.GetBhpbioHaulageCorrectionListFilter TO BhpbioGenericManager


/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioHaulageCorrectionListFilter">
 <Procedure>
	Returns a list of distinct Error type descriptions, Sources or Destinations for HaulageRaw records
	that are have an error.
	The @iFilterType determines which type of information is returned.
	Errors are not raised.
 </Procedure>
</TAG>
*/
 