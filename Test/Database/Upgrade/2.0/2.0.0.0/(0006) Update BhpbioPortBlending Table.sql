/*
   Tuesday, 4 June 20132:33:16 PM
   User: 
   Server: Reconcilor1\SQL2005
   Database: ReconcilorBhpbioV64
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.BhpbioPortBlending
	DROP CONSTRAINT FK_BhpbioPortBlending_MoveHubLocationId_Location
GO
ALTER TABLE dbo.BhpbioPortBlending
	DROP CONSTRAINT FK_BhpbioPortBlending_DestinationHubLocationId_Location
GO
ALTER TABLE dbo.BhpbioPortBlending
	DROP CONSTRAINT FK_BhpbioPortBlending_RakeHubLocationId_Location
GO
ALTER TABLE dbo.BhpbioPortBlending
	DROP CONSTRAINT FK_BhpbioPortBlending_LoadSiteLocationId_Location
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_BhpbioPortBlending
	(
	BhpbioPortBlendingId int NOT NULL IDENTITY (1, 1),
	SourceHubLocationId int NOT NULL,
	DestinationHubLocationId int NOT NULL,
	LoadSiteLocationId int NULL,
	StartDate datetime NOT NULL,
	EndDate datetime NOT NULL,
	SourceProductSize varchar(5) NULL,
	DestinationProductSize varchar(5) NULL,
	SourceProduct varchar(30) NULL,
	DestinationProduct varchar(30) NULL,
	Tonnes float(53) NOT NULL
	)  ON [PRIMARY]
GO
SET IDENTITY_INSERT dbo.Tmp_BhpbioPortBlending ON
GO
IF EXISTS(SELECT * FROM dbo.BhpbioPortBlending)
	 EXEC('INSERT INTO dbo.Tmp_BhpbioPortBlending (BhpbioPortBlendingId, SourceHubLocationId, DestinationHubLocationId, LoadSiteLocationId, StartDate, EndDate, Tonnes)
		SELECT BhpbioPortBlendingId, RakeHubLocationId, DestinationHubLocationId, LoadSiteLocationId, StartDate, EndDate, Tonnes FROM dbo.BhpbioPortBlending WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_BhpbioPortBlending OFF
GO
ALTER TABLE dbo.BhpbioPortBlendingGrade
	DROP CONSTRAINT FK_BhpbioPortBlendingGrade_BhpbioPortBlending
GO
DROP TABLE dbo.BhpbioPortBlending
GO
EXECUTE sp_rename N'dbo.Tmp_BhpbioPortBlending', N'BhpbioPortBlending', 'OBJECT' 
GO
ALTER TABLE dbo.BhpbioPortBlending ADD CONSTRAINT
	PK_BhpbioPortBlending PRIMARY KEY CLUSTERED 
	(
	BhpbioPortBlendingId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.BhpbioPortBlending ADD CONSTRAINT
	FK_BhpbioPortBlending_DestinationHubLocationId_Location FOREIGN KEY
	(
	DestinationHubLocationId
	) REFERENCES dbo.Location
	(
	Location_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BhpbioPortBlending ADD CONSTRAINT
	FK_BhpbioPortBlending_RakeHubLocationId_Location FOREIGN KEY
	(
	SourceHubLocationId
	) REFERENCES dbo.Location
	(
	Location_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BhpbioPortBlending ADD CONSTRAINT
	FK_BhpbioPortBlending_LoadSiteLocationId_Location FOREIGN KEY
	(
	LoadSiteLocationId
	) REFERENCES dbo.Location
	(
	Location_Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.BhpbioPortBlendingGrade ADD CONSTRAINT
	FK_BhpbioPortBlendingGrade_BhpbioPortBlending FOREIGN KEY
	(
	BhpbioPortBlendingId
	) REFERENCES dbo.BhpbioPortBlending
	(
	BhpbioPortBlendingId
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO

-- detect and remove duplicate records
declare @DupPortBlending table
(
	MaxBhpbioPortBlendingId int not null,
	MinBhpbioPortBlendingId int not null,
	SourceProduct varchar(31)  not null,
	DestinationProduct varchar(31) not null,
	SourceHubLocationId int not null,
	DestinationHubLocationId int not null,
	StartDate datetime not null,
	EndDate datetime not null,
	LoadSiteLocationId int not null,
	Tonnes int not null,

	primary key (MaxBhpbioPortBlendingId)
)

declare @DupPortBlendingGrade table
(
	MaxBhpbioPortBlendingId int not null,
	GradeId smallint not null,
	GradeValue real not null,

	primary key (MaxBhpbioPortBlendingId, GradeId)
)

insert into @DupPortBlending
select max(BhpbioPortBlendingId), min(BhpbioPortBlendingId), ISNULL(SourceProduct, ''), ISNULL(DestinationProduct, ''), 
	SourceHubLocationId, DestinationHubLocationId, StartDate, EndDate, LoadSiteLocationId, Sum(Tonnes)
from BhpbioPortBlending
group by SourceProduct, DestinationProduct, SourceHubLocationId, DestinationHubLocationId, StartDate, EndDate, LoadSiteLocationId
having count(*) > 1

insert into @DupPortBlendingGrade
select DPB.MaxBhpbioPortBlendingId, GradeId, SUM(BPBG.GradeValue * BPB.Tonnes)/SUM(BPB.Tonnes)
from @DupPortBlending DPB
inner join BhpbioPortBlending BPB
	on DPB.SourceProduct = ISNULL(BPB.SourceProduct, '')
	and DPB.DestinationProduct = ISNULL(BPB.DestinationProduct, '')
	and BPB.SourceHubLocationId = DPB.SourceHubLocationId
	and BPB.DestinationHubLocationId = DPB.DestinationHubLocationId
	and BPB.StartDate = DPB.StartDate
	and BPB.EndDate = DPB.EndDate
	and BPB.LoadSiteLocationId = DPB.LoadSiteLocationId
inner join BhpbioPortBlendingGrade BPBG
	on BPB.BhpbioPortBlendingId = BPBG.BhpbioPortBlendingId
group by DPB.MaxBhpbioPortBlendingId, GradeId

update BPBG
set GradeValue = DPBG.GradeValue
from BhpbioPortBlendingGrade BPBG
inner join @DupPortBlendingGrade DPBG 
	ON DPBG.MaxBhpbioPortBlendingId = BPBG.BhpbioPortBlendingId
	And DPBG.GradeId = BPBG.GradeId

update BPB
set Tonnes = DPB.Tonnes
from BhpbioPortBlending BPB
inner join @DupPortBlending DPB
	ON DPB.MaxBhpbioPortBlendingId = BPB.BhpbioPortBlendingId

delete BPBG
from BhpbioPortBlendingGrade BPBG
inner join @DupPortBlending DPB
	ON DPB.MinBhpbioPortBlendingId = BPBG.BhpbioPortBlendingId

delete BPB
from BhpbioPortBlending BPB
inner join @DupPortBlending DPB
	ON DPB.MinBhpbioPortBlendingId = BPB.BhpbioPortBlendingId

ALTER TABLE dbo.BhpbioPortBlending ADD CONSTRAINT
    UQ_BhpbioPortBlending_Candidate UNIQUE NONCLUSTERED
    (
		SourceHubLocationId, DestinationHubLocationId, SourceProduct, DestinationProduct, LoadSiteLocationId, StartDate, EndDate
    )


COMMIT
