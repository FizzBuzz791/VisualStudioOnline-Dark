
--
-- We want to remove the DateTo parameter from the scheduled run for the
-- Recon movements - this is causing it to only import data up to the end of the 
-- previous day, making things slow to come through from BH5.
--
-- If we leave this parameter blank, it will default to the end of the current day
-- instead
--
declare @ParameterId int

Select
	@ParameterId = pp.ImportAutoQueueProfileParameterId
From ImportAutoQueueProfileParameter pp
	inner join ImportAutoQueueProfile p on p.ImportAutoQueueProfileId = pp.ImportAutoQueueProfileId
	inner join Import i on i.ImportId = p.ImportId
	inner join ImportParameter ip on ip.ImportParameterId = pp.ImportParameterId
Where i.ImportName = 'Recon Movements' and ip.ParameterName = 'DateTo'

-- Make sure to set the Null flag as well, otherwise the blank value will get 
-- overwritten by the default
Update ImportAutoQueueProfileParameter 
Set ParameterValue = '', InsertParameterValueEvenWhenNull = 1 
Where ImportAutoQueueProfileParameterId = @ParameterId
