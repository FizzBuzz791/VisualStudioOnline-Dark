--
-- These imports need to be run in a particular order in order to minimize validation
-- errors. We now use the TimeOfDay field to do this ordering.
--

-- a delay should be introduced that is larger than the tick interval for the agent itself




update p
	set p.TimeOfDay = '2015-01-01 22:00:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'ReconBlockInsertUpdate'

update p
	set p.TimeOfDay = '2015-01-01 22:01:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Recon Movements'

update p
	set p.TimeOfDay = '2015-01-01 22:02:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Stockpile'

update p
	set p.TimeOfDay = '2015-01-01 22:04:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Stockpile Adjustment'

update p
	set p.TimeOfDay = '2015-01-01 22:06:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Haulage'

update p
	set p.TimeOfDay = '2015-01-01 22:08:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Production'

update p
	set p.TimeOfDay = '2015-01-01 22:10:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Shipping'

update p
	set p.TimeOfDay = '2015-01-01 22:12:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'PortBalance'

update p
	set p.TimeOfDay = '2015-01-01 22:14:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'PortBlending'

update p
	set p.TimeOfDay = '2015-01-01 22:16:00'
 from dbo.ImportAutoQueueProfile p
	inner join import i on i.ImportId = p.ImportId
where i.ImportName = 'Met Balancing'

