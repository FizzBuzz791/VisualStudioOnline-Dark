IF OBJECT_ID('dbo.BhpbioGetImportJobLatestActivtyDate') IS NOT NULL
	DROP PROCEDURE dbo.BhpbioGetImportJobLatestActivtyDate
GO

CREATE PROCEDURE dbo.BhpbioGetImportJobLatestActivtyDate
(
	@iImportJobStatus Varchar(64),
	@iLookBackDate DateTime
) 

WITH ENCRYPTION
AS

BEGIN
	SET NOCOUNT ON

	SELECT MAX(ijsh.DateAdded) as StatusChangeDate
	FROM ImportJob ij WITH (NOLOCK)
		INNER JOIN ImportJobStatusHistory ijsh  WITH (NOLOCK)
			ON ijsh.ImportJobId = ij.ImportJobId
		INNER JOIN ImportJobStatus ijs
			On ijs.ImportJobStatusId = ijsh.ImportJobStatusId
	Where ijs.ImportJobStatusName = @iImportJobStatus
		And ijsh.DateAdded > @iLookBackDate
	
	
END
GO

GRANT EXECUTE ON dbo.BhpbioGetImportJobLatestActivtyDate TO BhpbioGenericManager
GO
