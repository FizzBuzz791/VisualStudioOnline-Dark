﻿IF OBJECT_ID('dbo.BhpbioApprovalStatusByMonth') IS NOT NULL 
     DROP VIEW dbo.BhpbioApprovalStatusByMonth
GO


CREATE VIEW dbo.BhpbioApprovalStatusByMonth
WITH ENCRYPTION
AS
-- considering all locations that are hubs
WITH hubLocations AS
(
      SELECT l.Location_Id
      FROM dbo.Location l WITH (NOLOCK)
            INNER JOIN dbo.LocationType lt WITH (NOLOCK)
                  ON lt.Location_Type_Id = l.Location_Type_Id
      WHERE lt.Description = 'Hub'
), 
-- considering all months that have had approvals
monthsToConsider AS
(
      SELECT DISTINCT bad.ApprovedMonth
      FROM dbo.BhpbioApprovalData bad WITH (NOLOCK)
)
-- considering all F3 tags (these are the approval types that must be met for all hubs)
, f3Tags AS
(
      SELECT rdt.TagId
      FROM dbo.BhpbioReportDataTags rdt WITH (NOLOCK)
      WHERE rdt.TagGroupId = 'F3Factor'
), result AS
(
-- get all months where there are no missing approvals
SELECT mtc.ApprovedMonth
FROM monthsToConsider mtc
WHERE NOT EXISTS
      ( 
            SELECT *
            FROM monthsToConsider mtc2 WITH (NOLOCK)
                  CROSS JOIN f3Tags ft 
                  CROSS JOIN hubLocations hl WITH (NOLOCK)
                  LEFT JOIN dbo.BhpbioApprovalData bad WITH (NOLOCK)
                        ON bad.LocationId = hl.Location_Id
                        AND bad.TagId = ft.TagId
                        AND bad.ApprovedMonth = mtc2.ApprovedMonth
            WHERE bad.LocationId IS NULL
                  AND mtc2.ApprovedMonth = mtc.ApprovedMonth
      )
)
SELECT
	d.Start_Date AS [Month],
	ISNULL(CONVERT(BIT,r.ApprovedMonth),0) AS Approved
FROM dbo.GetDateRangeList(
		(
			-- the earliest approved month or the system start date, whichever is the earliest
			SELECT MIN(ApprovedMonth) FROM 
			(SELECT ApprovedMonth FROM result UNION ALL 
			SELECT CONVERT(DATETIME,Value) FROM dbo.Setting WITH (NOLOCK) WHERE Setting_Id = 'SYSTEM_START_DATE') a
		 )
		,GETDATE(),'Month',1) d
	LEFT JOIN result r 
		ON d.Start_Date = r.ApprovedMonth

GO

GRANT SELECT ON dbo.BhpbioApprovalStatusByMonth TO BhpbioGenericManager
GO