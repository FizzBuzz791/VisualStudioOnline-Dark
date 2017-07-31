
-- In order for Density to be tracked correctly through the system it must be inverted...
-- It is supplied in the form tonnes / m3...   however must be translated to the form m3 / tonnes
-- values can be inverted by dividing 1 by the value
-- In long form this could be written as 
--
--	(tonnes / value) 
--   --------------
--      tonnes
--
--  However the tonnes in the top and bottom can be cancelled out to the form
--
--	(1 / value) 


-- Invert Density Grade Values in ALL tables except the Holding tables used to support LOAD from source systems 
--	(ie.  [BhpbioBlastBlockModelGradeHolding]  in this case the inversion will be performed as part of the Sync..  
-- this ensures that the values stored in sync tables are the non-inverted values

BEGIN TRANSACTION

	-- NOTE: Do this operation within a transaction...  if we lose track of whether we have inverted values or not we could be in trouble...

	DECLARE @densityGradeId AS Integer
	SELECT @densityGradeId = Grade_Id FROM Grade WHERE Grade_Name = 'Density'

	UPDATE [DataProcessTransactionGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [DataProcessStockpileBalanceGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [DataProcessTransactionLeftGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [DigblockGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [StockpileBuildComponentGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [StockpileAdjustmentGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [WeightometerSampleGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [MinePlanPeriodGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [HaulageGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [StockpileSurveySampleGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [StockpileMonthlyResetGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [ModelBlockPartialGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [ParcelGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [HaulageRawGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [DigblockSurveySampleGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [DataTransactionTonnesGrade] SET Grade_Value = 1 / Grade_Value WHERE Grade_Id = @densityGradeId AND Grade_Value > 0 AND NOT Grade_Value IS NULL
	UPDATE [BhpbioShippingNominationItemParcelGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL
	UPDATE [BhpbioPortBlendingGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL
	UPDATE [BhpbioPortBalanceGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL
	UPDATE [BhpbioMetBalancingGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL
	UPDATE [StockpileBalanceRawGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL
	UPDATE [BhpbioSummaryEntryGrade] SET GradeValue = 1 / GradeValue WHERE GradeId = @densityGradeId AND GradeValue > 0 AND NOT GradeValue IS NULL

	-- write a message to the support log...this will provide a chance to work out whether the grade values have been inverted or not (and if so how many times)
	-- re-running this script will invert values back to their original values
	INSERT INTO dbo.SupportLog(LogTypeId, Added, Component, Description, Details, Exception)
		VALUES (1, GetDate(), 'Database Upgrade Scripts', 'Density Grade Values Inverted', null, null)

COMMIT TRANSACTION