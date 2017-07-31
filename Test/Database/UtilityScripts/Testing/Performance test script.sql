Set NoCount On

Declare @Procedures Table
(
	ProcName Varchar(200),
	Args Varchar(1000) Default '',
	IsFunction Bit Default 0,
	RunTime Int Default 0
)

----------------
-- Procedures --
----------------
Insert Into @Procedures (ProcName, Args) Values ('dbo.AddBhpbioPortBlending',						'@iSourceHubLocationId = {iSourceHubLocationId}, @iDestinationHubLocationId = {iDestinationHubLocationId}, @iStartDate = {iDateFrom}, @iEndDate = {iDateTo}, @iLoadSiteLocationId = {iLocationId}, @iTonnes = {iTonnes}, @oBhpbioPortBlendingId = @oBhpbioPortBlendingId, @iSourceProductSize = {iProductSize}, @iDestinationProductSize = {iProductSize}, @iDestinationProduct = {iProductCode}, @iSourceProduct = {iProductCode}' ) 
Insert Into @Procedures (ProcName, Args) Values ('dbo.AddBhpbioShippingTransactionNomination',		'@iNominationKey = {iNominationKey}, @iNomination = {iNomination}, @iOfficialFinishTime = {iOfficialFinishTime}, @iLastAuthorisedDate = {iLastAuthorisedDate}, @iVesselName = {iVesselName}, @iCustomerNo = {iCustomerNo}, @iCustomerName = {iCustomerName}, @iProductCode = {iProductCode}, @iProductSize = {iProductSize}, @iCOA = {iCOA}, @iH2O = {iH2O}, @iUndersize = {iUndersize}, @iOversize = {iOversize}, @oBhpbioShippingTransactionNominationId = @oBhpbioShippingTransactionNominationId')
Insert Into @Procedures (ProcName, Args) Values ('dbo.AddOrUpdateBhpbioLumpFinesRecord',			'@iBhpbioDefaultLumpFinesId = {iBhpbioDefaultLumpFinesId}, @iLocationId = {iLocationId}, @iStartDate = {iDateFrom}, @iLumpPercent = {iLumpPercent}, @iValidateOnly = {iValidateOnly}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.AddOrUpdateBhpbioShippingTransactionNominationParcelGrade', '@iSourceHubLocationId = {iSourceHubLocationId}, @iDestinationHubLocationId = {iDestinationHubLocationId}, @iStartDate = {iDateFrom}, @iEndDate = {iDateTo}, @iLoadSiteLocationId = {iLoadSiteLocationId}, @iTonnes = {iTonnes}, @iNominationKey = {iNominationKey}, @iNomination = {iNomination}, @oBhpbioPortBlendingId = @oBhpbioPortBlendingId') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.BhpbioTryDeleteLocation',						'@iLocationId = {iLocationId}, @iName = {iName}, @iLocationTypeId = {iLocationTypeId}, @iParentLocationName = {iParentLocationName},@oIsError = @oIsError , @oErrorMessage = @oErrorMessage') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.DeleteBhpbioLumpFinesRecord',					'@iBhpbioDefaultLumpFinesId = {iBhpbioDefaultLumpFinesId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioDefaultLumpFinesList',				'@iLocationId = {iLocationId}, @iLocationTypeId = {iLocationTypeId}, @iNoOfRecords = {iNoOfRecords}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioDefaultLumpFinesRecord',				'@iBhpbioDefaultLumpFinesId = {iBhpbioDefaultLumpFinesId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioHaulageManagementList',				'@iFilter_Start_Date = {iDateFrom}, @iFilter_Start_Shift = {iFilter_Start_Shift}, @iFilter_End_Date = {iDateTo}, @iFilter_End_Shift = {iFilter_End_Shift}, @iFilter_Source = {iFilter_Source}, @iFilter_Destination = {iFilter_Destination}, @iFilter_Truck = {iFilter_Truck}, @iShowHaulageWithApprovedChild = {iShowHaulageWithApprovedChild}, @iTop = {iTop}, @iRecordLimit = {iRecordLimit}, @iLocation_Id = {iLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioModelComparisonReport',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iIncludeBlockModels = {iIncludeBlockModels}, @iBlockModels = {iBlockModels}, @iIncludeActuals = {iIncludeActuals}, @iDesignationMaterialTypeId = {iDesignationMaterialTypeId}, @iTonnes = {iTonnes}, @iGrades = {iGrades}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioMovementRecoveryReport',				'@iDateTo = {iDateTo}, @iLocationId = {iLocationId}, @iComparison1IsActual = {iComparison1IsActual}, @iComparison1BlockModelId = {iComparison1BlockModelId}, @iComparison2IsActual = {iComparison2IsActual}, @iComparison2BlockModelId = {iComparison2BlockModelId}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioPortBalance',						'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iLocationId = {iLocationId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioPortBlending',						'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iLocationId = {iLocationId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportBaseDataAsGrades',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iIncludeBlockModels = {iIncludeBlockModels}, @iBlockModels = {iBlockModels}, @iIncludeActuals = {iIncludeActuals}, @iMaterialCategoryId = {iMaterialCategoryId}, @iRootMaterialTypeId = {iRootMaterialTypeId}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}, @iGrades = {iGrades}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportBaseDataAsTonnes',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iIncludeBlockModels = {iIncludeBlockModels}, @iBlockModels = {iBlockModels}, @iIncludeActuals = {iIncludeActuals}, @iMaterialCategoryId = {iMaterialCategoryId}, @iRootMaterialTypeId = {iRootMaterialTypeId}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataActualBeneProduct',		'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataActualExpitToStockpile',	'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataActualMineProduction',		'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataActualStockpileToCrusher',	'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataBlockModel',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}, @iBlockModelName = {iBlockModelName}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataHistorical',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta','@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataPortBlendedAdjustment',	'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataPortOreShipped',			'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataPortStockpileDelta',		'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataReview',					'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iLocationId = {iLocationId}, @iTagId = {iTagId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta','@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iDateBreakdown = {iDateBreakdown}, @iLocationId = {iLocationId}, @iChildLocations = {iChildLocations}, @iIncludeLiveData = {iIncludeLiveData}, @iIncludeApprovedData = {iIncludeApprovedData}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioShippingTransaction',				'@iDateFrom = {iDateFrom}, @iDateTo = {iDateTo}, @iLocationId = {iLocationId}') 
Insert Into @Procedures (ProcName, Args) Values ('dbo.GetBhpbioShippingTransactionById',			'@iBhpbioShippingTransactionNominationId = {iBhpbioShippingTransactionNominationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.SummariseBhpbioActualBeneProduct',			'@iSummaryMonth = {iSummaryMonth}, @iSummaryLocationId = {iSummaryLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.SummariseBhpbioActualC',						'@iSummaryMonth = {iSummaryMonth}, @iSummaryLocationId = {iSummaryLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.SummariseBhpbioPortBlendedAdjustment',		'@iSummaryMonth = {iSummaryMonth}, @iSummaryLocationId = {iSummaryLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.SummariseBhpbioPortStockpileDelta',			'@iSummaryMonth = {iSummaryMonth}, @iSummaryLocationId = {iSummaryLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.SummariseBhpbioShippingTransaction',			'@iSummaryMonth = {iSummaryMonth}, @iSummaryLocationId = {iSummaryLocationId}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.UpdateBhpbioPortBlending',					'@iBhpbioPortBlendingId = {iBhpbioPortBlendingId}, @iTonnes = {iTonnes}')
Insert Into @Procedures (ProcName, Args) Values ('dbo.UpdateBhpbioShippingTransactionNomination',	'@iBhpbioShippingTransactionNominationId = {iBhpbioShippingTransactionNominationId}, @iNominationKey = {iNominationKey}, @iNomination = {iNomination}, @iOfficialFinishTime = {iOfficialFinishTime}, @iLastAuthorisedDate = {iLastAuthorisedDate}, @iVesselName = {iVesselName}, @iCustomerNo = {iCustomerNo}, @iCustomerName = {iCustomerName}, @iHubLocationId = {iHubLocationId}, @iProductCode = {iProductCode}, @iTonnes = {iTonnes}, @iCOA = {iCOA}, @iH2O = {iH2O}, @iUndersize = {iUndersize}, @iOversize = {iOversize}')



---------------
-- Functions --
---------------
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioDataExceptionLocationIgnoreList', 1, '{iLocationId}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioDefaultLumpFinesRatios', 1, '{iLocationId}, {iTransactionDate}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioExcludeHubLocation', 1, '{iExclusionType}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioReportActualC', 1, '{iDateFrom}, {iDateTo}, {iDateBreakdown}, {iLocationId}, {iGetChildLocations}, {iIncludeLiveData}, {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioReportActualY', 1, '{iDateFrom}, {iDateTo}, {iDateBreakdown}, {iLocationId}, {iGetChildLocations}, {iIncludeLiveData}, {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioReportActualZ', 1, '{iDateFrom}, {iDateTo}, {iDateBreakdown}, {iLocationId}, {iGetChildLocations}, {iIncludeLiveData}, {iIncludeApprovedData}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioSummaryGradeBreakdown', 1, '{iDateFrom}, {iDateTo}, {iDateBreakdown}, {iSummaryEntryTypeName}, {iIgnoreMaterialTypes}, {iUseAbsoluteTonnesAtIndividualRows}, {iUseAbsoluteTonnesAtGradeSummary}')
Insert Into @Procedures (ProcName, IsFunction, Args) Values ('dbo.GetBhpbioSummaryTonnesBreakdown', 1, '{iDateFrom}, {iDateTo}, {iDateBreakdown}, {iSummaryEntryTypeName}, {iIgnoreMaterialTypes}')



--------------------------
-- Set parameter values --
--------------------------
Update @Procedures Set Args = Replace(Args, '{iBhpbioDefaultLumpFinesId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iBhpbioPortBlendingId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iBhpbioShippingTransactionNominationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iBlockModelName}', 'NULL')
Update @Procedures Set Args = Replace(Args, '{iBlockModels}', '''<BlockModels><BlockModel id="1"></BlockModel><BlockModel id="2"></BlockModel><BlockModel id="3"></BlockModel></BlockModels>''')
Update @Procedures Set Args = Replace(Args, '{iChildLocations}', '1')
Update @Procedures Set Args = Replace(Args, '{iCOA}', '''2013-01-20''')
Update @Procedures Set Args = Replace(Args, '{iComparison1BlockModelId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iComparison1IsActual}', '1')
Update @Procedures Set Args = Replace(Args, '{iComparison2BlockModelId}', '''2''')
Update @Procedures Set Args = Replace(Args, '{iComparison2IsActual}', '1')
Update @Procedures Set Args = Replace(Args, '{iCustomerName}', '''Henry''')
Update @Procedures Set Args = Replace(Args, '{iCustomerNo}', '5')
Update @Procedures Set Args = Replace(Args, '{iDateBreakdown}', '''MONTH''')
Update @Procedures Set Args = Replace(Args, '{iDateFrom}', '''2009-04-01''')
Update @Procedures Set Args = Replace(Args, '{iDateTo}', '''2009-04-30''')
Update @Procedures Set Args = Replace(Args, '{iDesignationMaterialTypeId}', 'Null')
Update @Procedures Set Args = Replace(Args, '{iDestinationHubLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iExclusionType}', 'NULL')
Update @Procedures Set Args = Replace(Args, '{iFilter_Destination}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iFilter_End_Shift}', '''Y''')
Update @Procedures Set Args = Replace(Args, '{iFilter_Source}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iFilter_Start_Shift}', '''Y''')
Update @Procedures Set Args = Replace(Args, '{iFilter_Truck}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iGetChildLocations}', '1')
Update @Procedures Set Args = Replace(Args, '{iGrades}', '''<Grades><Grade>1</Grade><Grade>2</Grade></Grades>''')
Update @Procedures Set Args = Replace(Args, '{iH2O}', '2.0')
Update @Procedures Set Args = Replace(Args, '{iHubLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iIgnoreMaterialTypes}', '0')
Update @Procedures Set Args = Replace(Args, '{iIncludeActuals}', '1')
Update @Procedures Set Args = Replace(Args, '{iIncludeApprovedData}', '0')
Update @Procedures Set Args = Replace(Args, '{iIncludeBlockModels}', '1')
Update @Procedures Set Args = Replace(Args, '{iIncludeLiveData}', '1')
Update @Procedures Set Args = Replace(Args, '{iLastAuthorisedDate}', '''2013-01-10''')
Update @Procedures Set Args = Replace(Args, '{iLoadSiteLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iLocationId}', '''8''')
Update @Procedures Set Args = Replace(Args, '{iLocationTypeId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iLumpPercent}', '0.40')
Update @Procedures Set Args = Replace(Args, '{iMaterialCategoryId}', '''Classification''')
Update @Procedures Set Args = Replace(Args, '{iMoveHubLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iName}', '''Barney''')
Update @Procedures Set Args = Replace(Args, '{iNominationKey}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iNomination}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iNoOfRecords}', '1000')
Update @Procedures Set Args = Replace(Args, '{iOfficialFinishTime}', '''2013-02-01''')
Update @Procedures Set Args = Replace(Args, '{iOversize}', '''0.5''')
Update @Procedures Set Args = Replace(Args, '{iParentLocationName}', '''''')
Update @Procedures Set Args = Replace(Args, '{iProductCode}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iProductSize}', '''LUMP''')
Update @Procedures Set Args = Replace(Args, '{iRecordLimit}', '1000')
Update @Procedures Set Args = Replace(Args, '{iRootMaterialTypeId}', '1')
Update @Procedures Set Args = Replace(Args, '{iShowHaulageWithApprovedChild}', '1')
Update @Procedures Set Args = Replace(Args, '{iSourceHubLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iSummaryEntryTypeName}', '''GradeControlModelMovement''')
Update @Procedures Set Args = Replace(Args, '{iSummaryLocationId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iSummaryMonth}', '''2013-01-01''')
Update @Procedures Set Args = Replace(Args, '{iTagId}', '''1''')
Update @Procedures Set Args = Replace(Args, '{iTonnes}', '1')
Update @Procedures Set Args = Replace(Args, '{iTop}', '1')
Update @Procedures Set Args = Replace(Args, '{iTransactionDate}', '''2013-01-01''')
Update @Procedures Set Args = Replace(Args, '{iUndersize}', '0.5')
Update @Procedures Set Args = Replace(Args, '{iUseAbsoluteTonnesAtGradeSummary}', '1')
Update @Procedures Set Args = Replace(Args, '{iUseAbsoluteTonnesAtIndividualRows}', '1')
Update @Procedures Set Args = Replace(Args, '{iValidateOnly}', '0')
Update @Procedures Set Args = Replace(Args, '{iVesselName}', '''VesselName''')

-------------------
-- Run the tests --
-------------------
Declare
	@SQL Varchar(4000),
	@ProcName Varchar(200),
	@Args Varchar(1000),
	@StartTime DateTime, @EndTime DateTime,
	@IsFunction Bit

Declare ProcCursor Cursor For
	Select ProcName, Args, IsFunction From @Procedures
	For Read Only

Open ProcCursor

Fetch Next From ProcCursor Into @ProcName, @Args, @IsFunction

While @@FETCH_STATUS = 0
Begin
	Print '---- ' + @ProcName + ' ----'
	
	If @IsFunction = 1
	BEGIN
		Select @SQL = 'Select * From ' + @ProcName + '(' + @Args + ')'
	END
	ELSE
	BEGIN
		-- Run procedure. With the right inputs.
		Select @SQL = '		DECLARE @oBhpbioPortBlendingId Int
		DECLARE @oBhpbioShippingTransactionNominationId Int
		DECLARE @oIsError Bit
		DECLARE @oErrorMessage Varchar(255)
		DECLARE @oCountRecords int
		DECLARE @oCountSourceStockpile int
		DECLARE @oCountSourceDigblock int
		DECLARE @oCountSourceMill int
		DECLARE @oCountDestinationStockpile int
		DECLARE @oCountDestinationCrusher int
		DECLARE @oCountDestinationMill int
		DECLARE @oSumTonnes float
		Exec ' + @ProcName + '
		' + @Args
	END
		
	Select @StartTime = getdate()
	
	BEGIN TRAN
		BEGIN TRY
			Exec (@SQL)
		END TRY
		BEGIN CATCH
			Print @SQL
			Print ERROR_MESSAGE()
			Raiserror('Error, see above.', 16, 1)
		END CATCH
	ROLLBACK
	
	Select @EndTime = getdate()
	
	Update @Procedures Set RunTime = Datepart(millisecond, @EndTime - @StartTime) Where ProcName = @ProcName
	
	Fetch Next From ProcCursor Into @ProcName, @Args, @IsFunction
End

Close ProcCursor

Select ProcName As [Procedure], RunTime As [Run time in ms] From @Procedures

