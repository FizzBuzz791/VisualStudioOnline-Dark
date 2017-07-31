-- UI security options

Insert Into dbo.SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
Select 'BHPBIO_DEFAULT_LUMP_FINES_VIEW', 'Utilities', 'REC', 'Access to view Default Lump Fines', 99 Union All
Select 'BHPBIO_DEFAULT_LUMP_FINES_EDIT', 'Utilities', 'REC', 'Access to edit Default Lump Fines', 99
Go

Insert Into dbo.SecurityRoleOption
(
	Role_Id, Application_Id, Option_Id
)
Select 'BHP_AREAC', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'BHP_JIMBLEBAR', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'BHP_NJV', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'BHP_WAIO', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'BHP_YANDI', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'BHP_YARRIE', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'REC_PURGE', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'REC_VIEW', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_VIEW' Union All
Select 'REC_ADMIN', 'REC', 'BHPBIO_DEFAULT_LUMP_FINES_EDIT'
Go

-- pre-populate with values supplied by client (Steve Loach)
DECLARE @StartDate DateTime

SELECT @StartDate = S.Value
FROM Setting S
WHERE S.Setting_Id = 'SYSTEM_START_DATE'

DECLARE @ltCompany INT
DECLARE @ltHub INT
DECLARE @ltSite INT
DECLARE @ltPit INT

SET @ltCompany = 1
SET @ltHub = 2
SET @ltSite = 3
SET @ltPit = 4

DECLARE @DefaultLumpRatios TABLE
(
	LocationTypeId INT NOT NULL,
	Name VARCHAR(30) NOT NULL,
	LumpPercent DECIMAL(5,4) NOT NULL
)

-- company wide
INSERT INTO @DefaultLumpRatios VALUES(@ltCompany, 'WAIO', .45)
-- hub defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'Jingbao', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'Yandi', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'AreaC', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'Jimblebar', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'NJV', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltHub, 'Yarrie', .45)
-- site defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'Yandi', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'AreaC', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'Jimblebar', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'Newman', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'OB23/25', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'OB18', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltSite, 'Yarrie', .45)
-- Yandi pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C1', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C5', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'E1', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'E2', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'E3', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W1', 0)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4', 0)
-- AreaC pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'BU', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'CC', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'CE', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'CW', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'DU', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'EE', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'FU', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'P3', .45)
-- Jimblebar pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'JB', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W11A', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W11B', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W11C', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22A', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22B', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22C', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22D', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22E', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22F', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W22G', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W33E', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W33W', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4CP', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4EP', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4NE', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4NP', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4SP', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'W4WP', .45)
-- Newman pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'WB', .5)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '29', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '30', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '35', .4)
-- Eastern Ridge pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '23P1', .4)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '24E1', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '24E2', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '25P1', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '25P3', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '25P4', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '25PE', .45)
-- OB18 pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '18NP', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, '18SP', .45)
-- Yarrie pit defaults
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C01', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C02', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C31', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'C41', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'CGW', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'Y10', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'Y4A', .45)
INSERT INTO @DefaultLumpRatios VALUES(@ltPit, 'Y6C', .45)

-- delete any existing data
DELETE FROM BhpbioDefaultLumpFines

-- insert default ratios
INSERT INTO BhpbioDefaultLumpFines (
	IsNonDeletable,
	LocationId,
	LumpPercent,
	StartDate
)
SELECT 1, L.Location_Id, DLR.LumpPercent, @StartDate
FROM @DefaultLumpRatios DLR
INNER JOIN Location L 
	ON DLR.Name = L.Name
	AND DLR.LocationTypeId = L.Location_Type_Id
	
	