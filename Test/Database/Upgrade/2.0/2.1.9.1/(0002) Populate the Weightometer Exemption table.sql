
DECLARE @DataExceptionTypeId_MissingSamples INT

SELECT @DataExceptionTypeId_MissingSamples = Data_Exception_Type_Id
FROM [DataExceptionType]
WHERE [Name] = 'No sample information over a 24-hour period'

IF @DataExceptionTypeId_MissingSamples IS NOT NULL
BEGIN

	DELETE FROM [BhpbioWeightometerDataExceptionExemption]
	WHERE Data_Exception_Type_Id = @DataExceptionTypeId_MissingSamples

	INSERT INTO [BhpbioWeightometerDataExceptionExemption] (Data_Exception_Type_Id, Weightometer_Id, [Start_Date], End_Date) 
	SELECT @DataExceptionTypeId_MissingSamples, '18-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, '18-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, '25-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, '25-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'AC-PostCrusherToCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'AC-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'AC-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'AC-PostCrusherToTrainRake', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'JB-C1OutFlow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'JB-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'JB-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'JB-PostCrusherToTrainRake', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneFinesToBPF0-Corrected', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneFinesToBPF0-Raw', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneFinesToSYard-Corrected', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneFinesToSYard-Raw', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneOreRaw', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-BeneRejectRaw', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-C3OutFlowRaw', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-C3OutFlowToSP', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-M232-Corrected', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-M233-Corrected', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-PostCrusherToCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-PostCrusherToTrainRake', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-ThickToTail-Corrected', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-ICP_To_YD-Y2', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-IOWA_To_YD-Y2', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-MCP2Outflow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-MCP4Outflow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-MCP5Outflow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-PostCrusherToTrainRake', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YD-Y2_VirtualFlow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YR-CBOutFlow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YR-PostCrusherToPostCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YR-PostCrusherToPreCrusher', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'YR-PostCrusherToTrainRake', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-C2OutFlow', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'NJV-COSToOHP', '2009-04-01', NULL UNION
	SELECT @DataExceptionTypeId_MissingSamples, 'WB-C2OutFlow-CorrectedBCOnly', '2009-04-01', NULL	
	
END	

