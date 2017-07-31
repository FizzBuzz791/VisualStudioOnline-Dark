--
-- We insert a data exception exemption for the new OHP4-Corrected weightometer so it doesn't
-- flood the system with useless alarms
--
Declare @StartDate DateTime
Declare @ExceptionId Int

-- Set Id to 'No sample information over a 24-hour period'. It would be good to pull this ID from the table
-- but there is no reliable way to do this without just matching on the description string, which I think is
-- even worse than just hardcoding the PK Id
Set @ExceptionId = 19 

-- This should be the start date of the weightometer - which is going to be the enddate of the old one + one day
-- (As weightometer flow period has no field for start_date, so we cannot store this data directly)
Select @StartDate = DateAdd(d, 1, End_Date) From WeightometerFlowPeriod Where Weightometer_Id = 'NJV-OHPOutflow'

Insert Into BhpbioWeightometerDataExceptionExemption (Data_Exception_Type_Id, Weightometer_Id, Start_Date, End_Date)
	Select @ExceptionId, 'NJV-OHP4OutflowCorrected', @StartDate, Null
