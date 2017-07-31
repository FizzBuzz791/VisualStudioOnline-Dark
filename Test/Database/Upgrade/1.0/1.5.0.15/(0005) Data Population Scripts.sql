/*
	--Insert Jimblebar SITE
*/
INSERT INTO Location (Name, Location_Type_ID, Parent_Location_ID, Description)
SELECT	'Jimblebar'
,		(SELECT Location_Type_Id FROM LocationType WHERE Description='Hub')
,		(SELECT Location_Id FROM Location WHERE Name='WAIO')
,		'Jimblebar'
WHERE not exists (SELECT 1	FROM Location 
				  WHERE		Name='Jimblebar' 
				  AND		Location_Type_Id=(SELECT Location_Type_Id FROM LocationType WHERE Description='Hub'))
GO

/*
	-- Create override for Jimblebar for old NJV parent
*/
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id
,		(SELECT L.Location_Id FROM Location L 
		 INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
		 WHERE L.Name='NJV' 
		 AND LT.Description='Hub')
,		'1900-01-01','2012-09-30'
FROM	Location 
WHERE	Name = 'Jimblebar' 
AND		Location_Type_Id = (SELECT Location_Type_Id FROM LocationType WHERE Description='Site')
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name='Jimblebar' 
				 INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id AND LT.Description='Site' AND BLO.Location_Type_Id = LT.Location_Type_Id
				 WHERE BLO.Parent_Location_Id IN (
					SELECT L.Location_Id FROM Location L 
					INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
					WHERE L.Name='NJV' 
					AND LT.Description='Hub'))
GO

/*
	-- Change Parent of Jimblebar SITE from NJV HUB to Jimblebar HUB
*/
UPDATE	Location 
SET		Parent_Location_Id = 
		(SELECT L.Location_ID
		 FROM	Location L INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
		 WHERE  L.Name = 'Jimblebar'
		 AND	LT.Description = 'Hub')
WHERE   Name='Jimblebar' AND Location_Type_Id = 
		(SELECT Location_Type_Id 
		 FROM	LocationType
		 WHERE	Description = 'Site')
GO


/*
	-- Create override for Jimblebar W4CP PITS to old Jimblebar Site (the previous linkage)
*/
DECLARE @PitName varchar(20)
DECLARE @PitLocationTypeID int
DECLARE @OldParentLocationID int
set @PitLocationTypeID = (SELECT Location_Type_Id FROM LocationType WHERE Description='Pit')
set @OldParentLocationID = (SELECT L.Location_Id FROM Location L 
					INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
					WHERE L.Name='Jimblebar' 
					AND LT.Description='Site')

set @PitName = 'W4CP'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)
--GO

set @PitName = 'W4EP'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)

set @PitName = 'W4NE'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)

set @PitName = 'W4NP'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)

set @PitName = 'W4SP'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)

set @PitName = 'W4WP'
			
insert into BhpbioLocationOverride(Location_ID, Location_Type_ID, Parent_Location_id, FromMonth,ToMonth)
SELECT	Location_Id, Location_Type_Id, @OldParentLocationID AS Parent_Location_Id
,		'1900-01-01' AS FromMonth,'2012-09-30' AS ToMonth
FROM	Location 
WHERE	Name = @PitName 
AND		Location_Type_Id = @PitLocationTypeID
AND NOT EXISTS(select 1 from BhpbioLocationOverride BLO
				 INNER JOIN Location L ON BLO.Location_Id = L.Location_Id AND L.Name=@PitName AND L.Location_Type_Id = @PitLocationTypeID
				 WHERE BLO.Parent_Location_Id = @OldParentLocationID)

GO

/*
	-- Change Parent of Jimblebar PIT's to OB18 SITE 
*/
DECLARE @JimblebarSite int
DECLARE @OB18Site int
DECLARE @PitLocationTypeID int

set @PitLocationTypeID = (SELECT Location_Type_Id FROM LocationType WHERE Description='Pit')
set @OB18Site = (SELECT L.Location_Id FROM Location L 
					INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
					WHERE L.Name='OB18' 
					AND LT.Description='Site')
set @JimblebarSite = (SELECT L.Location_Id FROM Location L 
					INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
					WHERE L.Name='Jimblebar' 
					AND LT.Description='Site')

UPDATE	Location 
SET		Parent_Location_Id = @OB18Site
WHERE   [Name] IN ('W4CP','W4EP','W4NE','W4NP','W4SP','W4WP' )
		AND Location_Type_Id = @PitLocationTypeID
		AND Parent_Location_Id = @JimblebarSite
		
GO

/*
	--Insert PIT's into Site Jimblebar
*/
DECLARE @PitLocationTypeID int
DECLARE @JimblebarSite int
set @PitLocationTypeID = (SELECT Location_Type_Id FROM LocationType WHERE Description='Pit')
set @JimblebarSite = (SELECT L.Location_Id FROM Location L 
					INNER JOIN LocationType LT ON L.Location_Type_Id = LT.Location_Type_Id
					WHERE L.Name='Jimblebar' 
					AND LT.Description='Site')

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W11A',@PitLocationTypeID, @JimblebarSite, 'W11A' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W11A' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W11B',@PitLocationTypeID, @JimblebarSite, 'W11B' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W11B' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W11C',@PitLocationTypeID, @JimblebarSite, 'W11C' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W11C' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W22B',@PitLocationTypeID, @JimblebarSite, 'W22B' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W22B' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W22D',@PitLocationTypeID, @JimblebarSite, 'W22D' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W22D' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W22E',@PitLocationTypeID, @JimblebarSite, 'W22E' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W22E' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W22F',@PitLocationTypeID, @JimblebarSite, 'W22F' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W22F' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

INSERT INTO Location (Name,Location_Type_Id, Parent_Location_Id, [Description])
SELECT  'W22G',@PitLocationTypeID, @JimblebarSite, 'W22G' 
WHERE NOT EXISTS (	select 1 FROM Location 
					WHERE	[Name]='W22G' AND Location_Type_Id=@PitLocationTypeID AND Parent_Location_Id=@JimblebarSite)

GO


/*
	Freshen the Location Date Table used to build Hierarchy
*/
EXEC dbo.UpdateBhpbioLocationDate		 
GO



/*
	-- Create override for Stockpiles pointed to Jimblebar prior to Oct 1
*/
INSERT	INTO BhpbioStockpileLocationOverride (Stockpile_Id, Location_Type_Id, Location_Id, FromMonth, ToMonth)
SELECT	SL.Stockpile_Id, SL.Location_Type_Id, SL.Location_Id, '1900-01-01','2012-09-30'
FROM	StockpileLocation SL
INNER	JOIN Stockpile S ON SL.Stockpile_Id = S.Stockpile_Id
WHERE	SL.Location_Id = (SELECT	Location_Id 
						  FROM		Location 
						  WHERE		Name = 'Jimblebar' 
						  AND		Location_Type_Id = (SELECT	Location_Type_Id 
													    FROM	LocationType 
													    WHERE	Description = 'Site'))
AND		S.Stockpile_Name NOT IN ('JB-LG-JBW3-10','JB-LG-JBW3RD-02'
			,'JB-WS-JBW2RD-01','JB-WS-JBW2RD-02','JB-WS-JBW2RD-03','JB-WS-JBW2RD-04'
			,'JB-WS-JBW3PAD-01'
			,'JB-WS-JBW3RD-01','JB-WS-JBW3RD-02','JB-WS-JBW3RD-03'
			,'JB-WS-THIESS-C1','JB-WS-THIESS-C2','JB-WS-THIESS-C3'
		)
AND NOT EXISTS (SELECT 1 FROM BhpbioStockpileLocationOverride BSLO
				WHERE  BSLO.Stockpile_Id = SL.Stockpile_Id
				AND	   BSLO.Location_Id  = SL.Location_Id
				AND    BSLO.FromMonth = '1900-01-01'
				AND    BSLO.ToMonth   = '2012-09-30')		
GO

/*
	-- Create new fixed mapping for StockpileLocation from Jimblebar to OB18
*/


UPDATE	StockpileLocation
SET		Location_Id =  (SELECT	Location_Id 
						FROM	location 
						WHERE	Name = 'OB18'
						AND		Location_Type_Id = (SELECT	Location_Type_Id 
												    FROM	LocationType 
												    WHERE	Description = 'Site'))
WHERE	Location_Id = (SELECT	Location_Id 
						  FROM		Location 
						  WHERE		Name = 'Jimblebar' 
						  AND		Location_Type_Id = (SELECT	Location_Type_Id 
													    FROM	LocationType 
													    WHERE	Description = 'Site'))
AND		Stockpile_Id NOT IN (SELECT S.Stockpile_Id FROM Stockpile S WHERE S.Stockpile_Name IN ('JB-LG-JBW3-10','JB-LG-JBW3RD-02'
			,'JB-WS-JBW2RD-01','JB-WS-JBW2RD-02','JB-WS-JBW2RD-03','JB-WS-JBW2RD-04'
			,'JB-WS-JBW3PAD-01'
			,'JB-WS-JBW3RD-01','JB-WS-JBW3RD-02','JB-WS-JBW3RD-03'
			,'JB-WS-THIESS-C1','JB-WS-THIESS-C2','JB-WS-THIESS-C3')
		)
GO


/*
	Freshen the Stockpile Location Date Table
*/
EXEC dbo.UpdateBhpbioStockpileLocationDate		 
GO
