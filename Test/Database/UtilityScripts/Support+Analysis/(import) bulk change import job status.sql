--
-- Use this script to bulk cancel or queue jobs, to they don't have to be done one by one
-- in the UI. The standard proc will be used to change the status, so a history record
-- etc will be added as usual
--

--
-- All the jobs for the import @ImportName, with the status @ImportStatus
-- will be changed to @ToImportStatus
--
declare @ImportName varchar(64) = 'Blocks'
declare @ImportStatus varchar(64) = 'PENDING'
declare @ToImportStatus varchar(64) = 'CANCELLED'

---
------------------------------
---
declare @ToImportStatusId int
select @ToImportStatusId = ImportJobStatusId from ImportJobStatus where ImportJobStatusName = @ToImportStatus

declare @ImportJobs table (
	RowNumber int, 
	ImportJobId int
)	

select
	j.ImportJobId,
	i.ImportName,
	s.ImportJobStatusName 
from ImportJob j
	inner join Import i 
		on i.ImportId = j.importId
	inner join ImportJobStatus s 
		on s.ImportJobStatusId = j.ImportJobStatusId
where i.ImportName = @ImportName
	and s.ImportJobStatusName = @ImportStatus

insert into @ImportJobs
	select
		row_number() over (order by j.ImportJobId) as RowNumber,
		j.ImportJobId
	from ImportJob j
		inner join Import i 
			on i.ImportId = j.importId
		inner join ImportJobStatus s 
			on s.ImportJobStatusId = j.ImportJobStatusId
	where i.ImportName = @ImportName
		and s.ImportJobStatusName = @ImportStatus

declare @i int = 1
declare @max int
declare @ImportJobId int
select @max = MAX(RowNumber) from @ImportJobs

while @i <= @max
begin
	select @ImportJobId = ImportJobId 
	from @ImportJobs 
	where RowNumber = @i
	
	if @ToImportStatus = 'CANCELLED'
		exec dbo.DeleteImportJob @ImportJobId
	else
		exec dbo.UpdateImportJobStatus @ImportJobId, @ToImportStatusId
		
	print 'updating job ' + convert(varchar(64), @ImportJobId) + ' to status ' + @ToImportStatus	
	set @i = @i + 1
end
