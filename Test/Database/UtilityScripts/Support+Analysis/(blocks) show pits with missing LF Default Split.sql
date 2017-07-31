--
-- If a pit doesn't have a default L/F record, it will show all zeros on the
-- F1F2F3 approval page. Currently these records don't get created automatically
-- when the pit is created. So it is necesary to audit this list every so often
-- and make sure nothing has been missed
--
select
	pl.Name as [Site],
	l.Name as Pit,
	lf.LumpPercent
from Location l
	inner join Location pl
		on pl.Location_Id = l.Parent_Location_Id
	Inner Join LocationType lt 
		On lt.Location_Type_Id = l.Location_Type_Id
	left join BhpbioDefaultLumpFines lf
		on lf.LocationId = l.Location_Id
where lt.[description] = 'Pit' 
	and lf.LumpPercent is null
	