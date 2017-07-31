IF OBJECT_ID('dbo.GetBhpbioPitListWithBlockCounts') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioPitListWithBlockCounts 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioPitListWithBlockCounts
(
	@iLocationId INT,
	@iStartDate DATETIME,
	@iEndDate DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 

	SELECT 
		PitLocationId,
		COUNT(*) as BlockCount
	FROM dbo.GetBhpbioReportReconBlockLocations(@iLocationId, @iStartDate, @iEndDate, 0)
	GROUP BY PitLocationId

END 
GO

GRANT EXECUTE ON dbo.GetBhpbioPitListWithBlockCounts TO BhpbioGenericManager
GO
