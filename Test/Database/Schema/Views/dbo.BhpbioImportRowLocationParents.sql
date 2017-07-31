
IF Object_Id('dbo.BhpbioImportRowLocationParents') IS NOT NULL
	DROP VIEW dbo.BhpbioImportRowLocationParents
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Extends the BhpbioImportRowLocation by merging locationIds of the parents of this import


CREATE VIEW [dbo].BhpbioImportRowLocationParents
AS
SELECT
	RootImportSyncRowId,
	ImportSyncRowId,
	PitLocationId,
	SiteLocationId,
	HubLocationId,
	L2.Parent_Location_Id AS CompanyLocationId 
	FROM
		(SELECT 
			RootImportSyncRowId,
			ImportSyncRowId,
			RL.Location_Id as PitLocationId,
			SiteLocationId,
			L1.Parent_Location_Id AS HubLocationId
		FROM [BhpbioImportRowLocation] RL 
		INNER JOIN 
		Location L1 ON RL.SiteLocationId =  L1.Location_Id) AS A
		INNER JOIN Location L2 ON A.HubLocationId = L2.Location_Id


GO
