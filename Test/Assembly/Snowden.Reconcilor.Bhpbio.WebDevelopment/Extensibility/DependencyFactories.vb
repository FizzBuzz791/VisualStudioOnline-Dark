Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Controls.FilterBoxes.Utilities
Imports Snowden.Reconcilor.Core.WebDevelopment.Extensibility

Namespace Extensibility

    Public Class DependencyFactories
        Inherits Core.WebDevelopment.Extensibility.DependencyFactories

        Protected Overrides Sub ConfigureSideNavigationFactory(ByVal factory As SideNavigationFactory)
            MyBase.ConfigureSideNavigationFactory(factory)
            factory.Register(SideNavigationKeys.CustomFields.ToString, GetType(ReconcilorControls.SideNavigationBoxes.CustomFieldsNavigationBox))
            factory.Register(SideNavigationKeys.ProductType.ToString, GetType(ReconcilorControls.SideNavigationBoxes.ProductTypeNavigationBox))
            factory.Register(SideNavigationKeys.Deposit.ToString, GetType(ReconcilorControls.SideNavigationBoxes.DepositSideNavigationBox))
            factory.Register(SideNavigationKeys.ShippingTarget.ToString, GetType(ReconcilorControls.SideNavigationBoxes.ShippingTargetNavigationBox))
            factory.Register(SideNavigationKeys.Approval.ToString, GetType(ReconcilorControls.SideNavigationBoxes.ApprovalSideNavigation))
            factory.Register(SideNavigationKeys.Port.ToString, GetType(ReconcilorControls.SideNavigationBoxes.PortSideNavigationBox))
            factory.Register(SideNavigationKeys.Purge.ToString, GetType(ReconcilorControls.SideNavigationBoxes.PurgeAdministrationSideNavigation))
            factory.Register(SideNavigationKeys.Analysis.ToString, GetType(ReconcilorControls.SideNavigationBoxes.AnalysisSideNavigation))
            factory.Register(SideNavigationKeys.SampleStation.ToString, GetType(ReconcilorControls.SideNavigationBoxes.SampleStationSideNavigation))
        End Sub

        Protected Overrides Sub ConfigureNotificationPartFactory(ByVal factory As Core.WebDevelopment.Extensibility.NotificationPartFactory)
            MyBase.ConfigureNotificationPartFactory(factory)

            factory.Register("Approval", GetType(Bhpbio.WebDevelopment.ReconcilorControls.NotificationParts.ApprovalNotificationUI))
        End Sub

        Protected Overrides Sub ConfigureFilterBoxFactory(ByVal factory As Core.WebDevelopment.Extensibility.FilterBoxFactory)
            MyBase.ConfigureFilterBoxFactory(factory)

            'override core filter boxes
            factory.Register("DigblockSpatial", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Analysis.DigblockSpatialFilterBox))
            factory.Register("MiningTab", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.MiningTabFilterBox))
            factory.Register("TransactionsTab", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.TransactionsFilterBox))
            factory.Register("Digblock", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.DigblockFilterBox))
            factory.Register("StockpileDetails", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileDetailsFilterBox))
            factory.Register("Stockpile", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileFilterBox))
            factory.Register("StockpileManualAdjustment", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileManualAdjustmentFilterBox))
            factory.Register("DataException", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.DataExceptionFilter))
            factory.Register("EventViewer", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.EventViewerFilter))
            factory.Register("HaulageAdministration", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageAdministrationFilter))
            factory.Register("HaulageCorrection", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageCorrectionFilter))
            factory.Register("RecalcLogViewer", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.RecalcLogViewerFilter))
            factory.Register("WeightometerSample", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.WeightometerSampleFilter))

            'add new BHP filter boxes
            factory.Register("ApprovalF1F2F3", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Approval.ApprovalF1F2F3Filter))
            factory.Register("Approval", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Approval.ApprovalFilter))
            factory.Register("Home", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Home.HomeFilter))
            factory.Register("Port", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Port.PortFilter))
            factory.Register("Site", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.SiteFilter))
            factory.Register("DefaultLumpFines", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.DefaultLumpFinesFilterBox))
            'factory.Register("Deposit", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.DepositFilterBox))
            factory.Register("AnalysisDataExport", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Analysis.DataExportFilterBox))
            factory.Register("ImportsFilterBox", GetType(ImportsFilterBox))
            factory.Register("AnnualReportFilterBox", GetType(WebDevelopment.ReconcilorControls.FilterBoxes.Report.AnnualReportFilterBox))
        End Sub
    End Class

End Namespace
