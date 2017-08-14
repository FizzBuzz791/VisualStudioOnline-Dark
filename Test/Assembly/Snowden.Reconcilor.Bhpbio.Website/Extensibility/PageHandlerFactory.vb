﻿Namespace Extensibility

    Public Class PageHandlerFactory
        Inherits Snowden.Reconcilor.Core.Website.Extensibility.PageHandlerFactory

        Private _pageListBhpbioParsed As Boolean

        Protected Overrides Sub SetupPageList()
            Dim assembly As String = "Snowden.Reconcilor.Bhpbio.Website"
            MyBase.SetupPageList()

            If Not _pageListBhpbioParsed Then
                _pageListBhpbioParsed = True
                AddPage("~/Home/Default.aspx", GetType(Home.DefaultHome))
                AddPage("~/Home/HomeList.aspx", GetType(Home.HomeList))

                AddPage("~/Analysis/DigblockSpatialAdministration.aspx", GetType(Analysis.DigblockSpatialAdministration))
                AddPage("~/Analysis/DigblockSpatialRender.aspx", GetType(Analysis.DigblockSpatialRender))
                AddPage("~/Analysis/DigblockSpatialVarianceSave.aspx", GetType(Analysis.DigblockSpatialVarianceSave))
                AddPage("~/Analysis/DigblockSpatialVarianceView.aspx", GetType(Analysis.DigblockSpatialVarianceView))
                AddPage("~/Analysis/DigblockSpatialView.aspx", GetType(Analysis.DigblockSpatialView))
                AddPage("~/Analysis/DigblockSpatialVarianceViewSetup.aspx", GetType(Analysis.DigblockSpatialVarianceViewSetup))
                AddPage("~/Analysis/DigblockSpatialAdministrationLegend.aspx", GetType(Analysis.DigblockSpatialAdministrationLegend))
                AddPage("~/Analysis/RecalcLogicList.aspx", GetType(Analysis.RecalcLogicList))
                AddPage("~/Analysis/ReconciliationDataExport.aspx", GetType(Analysis.ReconciliationDataExport))
                AddPage("~/Analysis/ProdReconciliationExport.aspx", GetType(Analysis.ProdReconciliationExport))
                AddPage("~/Analysis/BlastblockDataExport.aspx", GetType(Analysis.BlastblockDataExport))
                AddPage("~/Analysis/BlastblockDataExportbyOreType.aspx", GetType(Analysis.BlastblockDataExportOreType))
                AddPage("~/Analysis/OutlierAnalysisAdministration.aspx", GetType(Analysis.OutlierAnalysisAdministration))
                AddPage("~/Analysis/OutlierAnalysisGrid.aspx", GetType(Analysis.OutlierAnalysisGrid))
                AddPage("~/Analysis/OutlierAnalysisFilter.aspx", GetType(Analysis.OutlierAnalysisFilter))

                AddPage("~/Approval/Default.aspx", GetType(Approval.DefaultApproval))
                AddPage("~/Approval/ApprovalData.aspx", GetType(Approval.ApprovalSummary)) 'GetType(Approval.ApprovalData))
                AddPage("~/Approval/ApprovalDataList.aspx", GetType(Approval.ApprovalDataList))
                AddPage("~/Approval/ApprovalDataUpdate.aspx", GetType(Approval.ApprovalDataUpdate))
                AddPage("~/Approval/ApprovalDigblockList.aspx", GetType(Approval.ApprovalDigblockList))
                AddPage("~/Approval/ApprovalDigblockUpdate.aspx", GetType(Approval.ApprovalDigblockUpdate))
                AddPage("~/Approval/ApprovalOther.aspx", GetType(Approval.ApprovalOther))
                AddPage("~/Approval/ApprovalOtherList.aspx", GetType(Approval.ApprovalOtherList))
                AddPage("~/Approval/ApprovalDataReview.aspx", GetType(Approval.ApprovalDataReview))
                AddPage("~/Approval/ApprovalDataListNode.aspx", GetType(Approval.ApprovalDataListNode))
                AddPage("~/Approval/ApprovalOtherListNode.aspx", GetType(Approval.ApprovalOtherListNode))
                AddPage("~/Approval/ApprovalResourceClassification.aspx", GetType(Approval.ApprovalResourceClassification))
                AddPage("~/Approval/ApprovalBulk.aspx", GetType(Approval.BulkApproval))
                AddPage("~/Approval/ApprovalBulkSubmit.aspx", GetType(Approval.ApprovalBulkSubmit))
                AddPage("~/Approval/ApprovalProgress.aspx", GetType(Approval.ApprovalProgress))
                AddPage("~/Approval/ApprovalSummaryList.aspx", GetType(Approval.ApprovalSummaryList))
                AddPage("~/Approval/ApprovalNavigator.aspx", GetType(Approval.ApprovalNavigator))
                AddPage("~/Approval/ApprovalFactorList.aspx", GetType(Approval.ApprovalFactorList))
                AddPage("~/Approval/ApprovalFactorListTabPage.aspx", GetType(Approval.ApprovalFactorListTabPage))
                AddPage("~/Approval/ApprovalAssessmentList.aspx", GetType(Approval.ApprovalAssessmentList))


                AddPage("~/Internal/LocationPickerTree.aspx", GetType(Internal.LocationPickerTree))
                AddPage("~/Internal/LocationPickerTreeNode.aspx", GetType(Internal.LocationPickerTreeNode))
                AddPage("~/Internal/StockpileImageLoader.aspx", GetType(Internal.StockpileImageLoader))
                AddPage("~/Internal/StockpileImageLoaderPage.aspx", GetType(Internal.StockpileImageLoaderPage))

                AddPage("~/Reports/Default.aspx", GetType(Reports.DefaultReports))
                AddPage("~/Reports/ReportsView.aspx", GetType(Reports.ReportsView))
                AddPage("~/Reports/ReportsStandardRender.aspx", GetType(Reports.ReportsStandardRender))
                AddPage("~/Reports/ReportsRun.aspx", GetType(Reports.ReportsRun))
                AddPage("~/Reports/GetStockpilesByLocation.aspx", GetType(Reports.GetStockpilesByLocation))
                AddPage("~/Reports/GetLocationsByLocationType.aspx", GetType(Reports.GetLocationsByLocationType))
                AddPage("~/Reports/GetReconciliationDataExportReport.aspx", GetType(Reports.GetReconciliationDataExportReport))
                AddPage("~/Reports/GetBlastblockDataExportReport.aspx", GetType(Reports.GetBlastblockDataExportReport))
                AddPage("~/Reports/GetBlastblockOreTypeDataExportReport.aspx", GetType(Reports.GetBlastblockOreTypeDataExportReport))
                AddPage("~/Reports/GetAnnualReport.aspx", GetType(Reports.GetAnnualReport))
                AddPage("~/Reports/YearlyReconciliationReport.aspx", GetType(Reports.YearlyReconciliationReport))

                AddPage("~/Depletions/DepletionDigblockDetails.aspx", GetType(Depletions.DepletionDigblockDetails))

                AddPage("~/Digblocks/Default.aspx", GetType(Digblocks.DefaultDigblocks))
                AddPage("~/Digblocks/DigblockDetails.aspx", GetType(Digblocks.DigblockDetails))
                AddPage("~/Digblocks/DigblockHaulageList.aspx", GetType(Digblocks.DigblockHaulageList))
                AddPage("~/Digblocks/DigblockList.aspx", GetType(Digblocks.DigblockList))
                AddPage("~/Digblocks/DigblockTreeview.aspx", GetType(Digblocks.DigblockTreeview))
                AddPage("~/Digblocks/DigblockTreeviewGetNode.aspx", GetType(Digblocks.DigblockTreeviewGetNode))
                AddPage("~/Digblocks/DigblockPolygonMapper.aspx", GetType(Digblocks.DigblockPolygonMapper))

                AddPage("~/Port/Default.aspx", GetType(Port.DefaultPort))
                AddPage("~/Port/PortShippingList.aspx", GetType(Port.PortShippingList))
                AddPage("~/Port/PortBalancesList.aspx", GetType(Port.PortBalancesList))
                AddPage("~/Port/PortBlendingList.aspx", GetType(Port.PortBlendingList))

                AddPage("~/Stockpiles/Default.aspx", GetType(Stockpiles.DefaultStockpiles))
                AddPage("~/Stockpiles/StockpileDetails.aspx", GetType(Stockpiles.StockpileDetails))
                AddPage("~/Stockpiles/StockpileList.aspx", GetType(Stockpiles.StockpileList))
                AddPage("~/Stockpiles/StockpileManualAdjustmentAdministration.aspx", GetType(Stockpiles.StockpileManualAdjustmentAdministration))
                AddPage("~/Stockpiles/StockpileManualAdjustmentEdit.aspx", GetType(Stockpiles.StockpileManualAdjustmentEdit))
                AddPage("~/Stockpiles/StockpileManualAdjustmentList.aspx", GetType(Stockpiles.StockpileManualAdjustmentList))
                AddPage("~/Stockpiles/StockpileSurveyAdministration.aspx", GetType(Stockpiles.StockpileSurveyAdministration))
                AddPage("~/Stockpiles/StockpileSurveyList.aspx", GetType(Stockpiles.StockpileSurveyList))
                AddPage("~/Stockpiles/StockpileDetailsTabActivity.aspx", GetType(Stockpiles.StockpileDetailsTabActivity))
                AddPage("~/Stockpiles/StockpileDetailsTabAttribute.aspx", GetType(Stockpiles.StockpileDetailsTabAttribute))
                AddPage("~/Stockpiles/StockpileDetailsTabBalance.aspx", GetType(Stockpiles.StockpileDetailsTabBalance))
                AddPage("~/Stockpiles/StockpileDetailsTabCharting.aspx", GetType(Stockpiles.StockpileDetailsTabCharting))
                AddPage("~/Stockpiles/StockpileDetailsTabGenealogy.aspx", GetType(Stockpiles.StockpileDetailsTabGenealogy))

                AddPage("~/Utilities/Default.aspx", GetType(Utilities.DefaultUtilities))
                AddPage("~/Utilities/CustomFieldsColors.aspx", GetType(Utilities.CustomFieldsColors))
                AddPage("~/Utilities/CustomFieldsColorsSave.aspx", GetType(Utilities.CustomFieldsColorsSave))
                AddPage("~/Utilities/CustomFieldsConfiguration.aspx", GetType(Utilities.CustomFieldsConfiguration))
                AddPage("~/Utilities/CustomFieldsLocationColors.aspx", GetType(Utilities.CustomFieldsLocationColors))
                AddPage("~/Utilities/CustomFieldsLocations.aspx", GetType(Utilities.CustomFieldsLocations))
                AddPage("~/Utilities/CustomFieldsLocationsDetails.aspx", GetType(Utilities.CustomFieldsLocationsDetails))
                AddPage("~/Utilities/CustomFieldsLocationsDetailsSave.aspx", GetType(Utilities.CustomFieldsLocationsDetailsSave))
                AddPage("~/Utilities/CustomFieldsMessages.aspx", GetType(Utilities.CustomFieldsMessages))
                AddPage("~/Utilities/CustomFieldsMessagesDetails.aspx", GetType(Utilities.CustomFieldsMessagesDetails))
                AddPage("~/Utilities/CustomFieldsMessagesDetailsSave.aspx", GetType(Utilities.CustomFieldsMessagesDetailsSave))
                AddPage("~/Utilities/CustomFieldsMessagesDetailsEdit.aspx", GetType(Utilities.CustomFieldsMessagesDetailsEdit))
                AddPage("~/Utilities/CustomFieldsMessagesDetailsDelete.aspx", GetType(Utilities.CustomFieldsMessagesDetailsDelete))
                AddPage("~/Utilities/CustomFieldsMessagesDetailsActivate.aspx", GetType(Utilities.CustomFieldsMessagesDetailsActivate))
                AddPage("~/Utilities/CustomFieldsStockpile.aspx", GetType(Utilities.CustomFieldsStockpile))
                AddPage("~/Utilities/CustomFieldsStockpileDetails.aspx", GetType(Utilities.CustomFieldsStockpileDetails))
                AddPage("~/Utilities/CustomFieldsStockpileDetailsSave.aspx", GetType(Utilities.CustomFieldsStockpileDetailsSave))
                AddPage("~/Utilities/EventViewer.aspx", GetType(Utilities.EventViewer))
                AddPage("~/Utilities/HaulageAdministration.aspx", GetType(Utilities.HaulageAdministration))
                AddPage("~/Utilities/HaulageAdministrationDetails.aspx", GetType(Utilities.HaulageAdministrationDetails))
                AddPage("~/Utilities/HaulageAdministrationList.aspx", GetType(Utilities.HaulageAdministrationList))
                AddPage("~/Utilities/HaulageCorrection.aspx", GetType(Utilities.HaulageCorrection))
                AddPage("~/Utilities/HaulageCorrectionList.aspx", GetType(Utilities.HaulageCorrectionList))
                AddPage("~/Utilities/HaulageCorrectionNameResolution.aspx", GetType(Utilities.HaulageCorrectionNameResolution))
                AddPage("~/Utilities/GetHaulageAdministrationSourceByLocation.aspx", GetType(Utilities.GetHaulageAdministrationSourceByLocation))
                AddPage("~/Utilities/GetHaulageAdministrationDestinationByLocation.aspx", GetType(Utilities.GetHaulageAdministrationDestinationByLocation))
                AddPage("~/Utilities/GetHaulageCorrectionSourceByLocation.aspx", GetType(Utilities.GetHaulageCorrectionSourceByLocation))
                AddPage("~/Utilities/GetHaulageCorrectionDestinationByLocation.aspx", GetType(Utilities.GetHaulageCorrectionDestinationByLocation))
                AddPage("~/Utilities/NotificationAdministrationDelete.aspx", GetType(Utilities.NotificationAdministrationDelete))
                AddPage("~/Utilities/CustomFieldsLocationColorsDetails.aspx", GetType(Utilities.CustomFieldsLocationColorsDetails))
                AddPage("~/Utilities/CustomFieldsLocationColorsDetailsSave.aspx", GetType(Utilities.CustomFieldsLocationColorsDetailsSave))

				AddPage("~/Utilities/ImportAdministration.aspx", GetType(Utilities.ImportAdministration))
                AddPage("~/Utilities/ImportJobDetail.aspx", GetType(Utilities.ImportJobDetail))
                AddPage("~/Utilities/ImportList.aspx", GetType(Utilities.ImportList))
                AddPage("~/Utilities/ImportMessage.aspx", GetType(Utilities.ImportMessage))
                AddPage("~/Utilities/ImportMessageGrouping.aspx", GetType(Utilities.ImportMessageGrouping))
                AddPage("~/Utilities/ImportMessageGroupingExportXml.aspx", GetType(Utilities.ImportMessageGroupingExportXml))

				AddPage("~/Utilities/PurgeAdministration.aspx", GetType(Utilities.PurgeAdministration))
                AddPage("~/Utilities/PurgeAdministrationList.aspx", GetType(Utilities.PurgeAdministrationList))
                AddPage("~/Utilities/PurgeAdministrationAdd.aspx", GetType(Utilities.PurgeAdministrationAdd))
                AddPage("~/Utilities/PurgeAdministrationSave.aspx", GetType(Utilities.PurgeAdministrationSave))
                AddPage("~/Utilities/PurgeAdministrationCancel.aspx", GetType(Utilities.PurgeAdministrationCancel))
                AddPage("~/Utilities/PurgeAdministrationApprove.aspx", GetType(Utilities.PurgeAdministrationApprove))

                AddPage("~/Utilities/MonthlyApprovalAdministration.aspx", GetType(Utilities.MonthlyApprovalAdministration))
                AddPage("~/Utilities/MonthlyApprovalList.aspx", GetType(Utilities.MonthlyApprovalList))

                AddPage("~/ReconcilorExceptionBar.aspx", GetType(ReconcilorExceptionBar))

                AddPage("~/Utilities/DataExceptionAdministration.aspx", GetType(Utilities.DataExceptionAdministration))
                AddPage("~/Utilities/DataExceptionGetNode.aspx", GetType(Utilities.DataExceptionGetNode))
                AddPage("~/Utilities/DataExceptionList.aspx", GetType(Utilities.DataExceptionList))
                AddPage("~/Utilities/DataExceptionListDismissAll.aspx", GetType(Utilities.DataExceptionListDismissAll))

                AddPage("~/Utilities/RecalcLogViewer.aspx", GetType(Utilities.RecalcLogViewer))

                AddPage("~/Utilities/ReferenceInterfaceListingList.aspx", GetType(Utilities.ReferenceInterfaceListingList))
                AddPage("~/Utilities/ReferenceStockpileGroupDelete.aspx", GetType(Utilities.ReferenceStockpileGroupDelete))
                AddPage("~/Utilities/ReferenceStockpileGroupSave.aspx", GetType(Utilities.ReferenceStockpileGroupSave))
                AddPage("~/Utilities/ReferenceStockpileGroupEdit.aspx", GetType(Utilities.ReferenceStockpileGroupEdit))
                AddPage("~/Utilities/ReferenceStockpileGroupStockpileList.aspx", GetType(Utilities.ReferenceStockpileGroupStockpileList))
                AddPage("~/Utilities/ReferenceStockpileGroupAdministration.aspx", GetType(Utilities.ReferenceStockpileGroupAdministration))
                AddPage("~/Utilities/ReferenceMaterialHierarchyAdministration.aspx", GetType(Utilities.ReferenceMaterialHierarchyAdministration))
                AddPage("~/Utilities/ReferenceMaterialHierarchyList.aspx", GetType(Utilities.ReferenceMaterialHierarchyList))
                AddPage("~/Utilities/ReferenceMaterialHierarchyEdit.aspx", GetType(Utilities.ReferenceMaterialHierarchyEdit))
                AddPage("~/Utilities/ReferenceMaterialHierarchySave.aspx", GetType(Utilities.ReferenceMaterialHierarchySave))
                AddPage("~/Utilities/ReferenceBhpbioMaterialTypeLocationList.aspx", GetType(Utilities.ReferenceBhpbioMaterialTypeLocationList))
                AddPage("~/Utilities/RoleOptionEdit.aspx", GetType(Utilities.RoleOptionEdit))
                AddPage("~/Utilities/WeightometerSampleAdministration.aspx", GetType(Utilities.WeightometerSampleAdministration))
                AddPage("~/Utilities/WeightometerSampleList.aspx", GetType(Utilities.WeightometerSampleList))
                AddPage("~/Utilities/WeightometerSampleEdit.aspx", GetType(Utilities.WeightometerSampleEdit))
                AddPage("~/Utilities/SystemSettingsList.aspx", GetType(Utilities.SystemSettingsList))
                AddPage("~/Utilities/SystemSettingsEdit.aspx", GetType(Utilities.SystemSettingsEdit))
                AddPage("~/Utilities/HelpDocumentation.aspx", GetType(Utilities.HelpDocumentation))
                AddPage("~/Utilities/NotificationAdministration.aspx", GetType(Utilities.NotificationAdministration))
                AddPage("~/Utilities/NotificationAdministrationList.aspx", GetType(Utilities.NotificationAdministrationList))

                AddPage("~/Utilities/LocationFilterLoad.aspx", GetType(Utilities.LocationFilterLoad))
                AddPage("~/Utilities/DefaultLumpFinesAdministration.aspx", GetType(Utilities.DefaultLumpFinesAdministration))
                AddPage("~/Utilities/DefaultLumpFinesList.aspx", GetType(Utilities.DefaultLumpFinesList))
                AddPage("~/Utilities/DefaultLumpFinesEdit.aspx", GetType(Utilities.DefaultLumpFinesEdit))
                AddPage("~/Utilities/DefaultLumpFinesSave.aspx", GetType(Utilities.DefaultLumpFinesSave))
                AddPage("~/Utilities/DefaultLumpFinesDelete.aspx", GetType(Utilities.DefaultLumpFinesDelete))

                AddPage("~/Utilities/DefaultProductTypeAdministration.aspx", GetType(Utilities.DefaultProductTypeAdministration))
                AddPage("~/Utilities/DefaultProductTypeList.aspx", GetType(Utilities.DefaultProductTypeList))
                AddPage("~/Utilities/DefaultProductTypeDelete.aspx", GetType(Utilities.DefaultProductTypeDelete))
                AddPage("~/Utilities/DefaultProductTypeEdit.aspx", GetType(Utilities.DefaultProductTypeEdit))
                AddPage("~/Utilities/DefaultProductTypeSave.aspx", GetType(Utilities.DefaultProductTypeSave))

                AddPage("~/Utilities/DefaultDepositAdministration.aspx", GetType(Utilities.DefaultDepositAdministration))
                AddPage("~/Utilities/DefaultDepositList.aspx", GetType(Utilities.DefaultDepositList))
                AddPage("~/Utilities/DefaultDepositDelete.aspx", GetType(Utilities.DefaultDepositDelete))
                AddPage("~/Utilities/DefaultDepositEdit.aspx", GetType(Utilities.DefaultDepositEdit))
                AddPage("~/Utilities/DefaultDepositSave.aspx", GetType(Utilities.DefaultDepositSave))

                AddPage("~/Utilities/DefaultShippingTargetsAdministration.aspx", GetType(Utilities.DefaultShippingTargetsAdministration))
                AddPage("~/Utilities/DefaultshippingTargetList.aspx", GetType(Utilities.DefaultshippingTargetList))
                AddPage("~/Utilities/DefaultshippingTargetEdit.aspx", GetType(Utilities.DefaultshippingTargetEdit))
                AddPage("~/Utilities/DefaultshippingTargetSave.aspx", GetType(Utilities.DefaultShippingTargetSave))
                AddPage("~/Utilities/DefaultshippingTargetDelete.aspx", GetType(Utilities.DefaultshippingTargetDelete))

                AddPage("~/Utilities/OutlierSeriesConfiguration.aspx", GetType(Utilities.DefaultOutlierSeriesConfiguration))
                AddPage("~/Utilities/GetDefaultOutlierSeriesList.aspx", GetType(Utilities.DefaultOutlierSeriesConfigurationList))
                AddPage("~/Utilities/DefaultOutlierSeriesConfigurationEdit.aspx", GetType(Utilities.DefaultOutlierSeriesConfigurationEdit))
                AddPage("~/Utilities/DefaultOutlierSeriesConfigurationSave.aspx", GetType(Utilities.DefaultOutlierSeriesConfigurationSave))

                AddPage("~/Utilities/DefaultSampleStationsAdministration.aspx", GetType(Utilities.DefaultSampleStationsAdministration))
                AddPage("~/Utilities/DefaultSampleStationList.aspx", GetType(Utilities.DefaultSampleStationList))
                AddPage("~/Utilities/DefaultSampleStationDelete.aspx", GetType(Utilities.DefaultSampleStationDelete))
                AddPage("~/Utilities/DefaultSampleStationEdit.aspx", GetType(Utilities.DefaultSampleStationEdit))
                AddPage("~/Utilities/DefaultSampleStationSave.aspx", GetType(Utilities.DefaultSampleStationSave))
                AddPage("~/Utilities/DefaultSampleStationTargetEdit.aspx", GetType(Utilities.DefaultSampleStationTargetEdit))
                AddPage("~/Utilities/DefaultSampleStationTargetSave.aspx", GetType(Utilities.DefaultSampleStationTargetSave))
                AddPage("~/Utilities/DefaultSampleStationTargetDelete.aspx", GetType(Utilities.DefaultSampleStationTargetDelete))
            End If
        End Sub
    End Class
End Namespace
