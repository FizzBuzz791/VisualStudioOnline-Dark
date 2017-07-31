Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports SideNavigationLinkItem = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem

Namespace ReconcilorControls.SideNavigationBoxes

    Public Class AnalysisSideNavigation
        Inherits Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.AnalysisSideNavigation

        Public Sub New()
            MyBase.New()
        End Sub

        Protected Overrides Sub PopulateNavigationItems(ByVal items As System.Collections.Generic.IDictionary(Of String, Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationItem))
            MyBase.PopulateNavigationItems(items)
            items.Add("ANALYSIS_RECON_DATA_EXPORT", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Analysis/ReconciliationDataExport.aspx", "", "Reconciliation Data Export"), New Tags.HtmlImageTag("../images/showAll.gif")))
            items.Add("ANALYSIS_PROD_RECON_DATA_EXPORT", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Analysis/ProdReconciliationExport.aspx", "", "Product Reconciliation Data Export"), New Tags.HtmlImageTag("../images/showAll.gif")))
            'items.Add("ANALYSIS_BLASTBLOCK_DATA_EXPORT", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Analysis/BlastblockDataExport.aspx", "", "Blastblock Data Export"), New Tags.HtmlImageTag("../images/showAll.gif")))
            items.Add("ANALYSIS_BLASTBLOCK_DATA_EXPORT_ORE_TYPE", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Analysis/BlastblockDataExportbyOreType.aspx", "", "Blastblock Data by Ore Type Export"), New Tags.HtmlImageTag("../images/showAll.gif")))
            items.Add("ANALYSIS_OUTLIER_ANALYSIS", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Analysis/OutlierAnalysisAdministration.aspx", "", "Outlier Analysis"), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class

End Namespace