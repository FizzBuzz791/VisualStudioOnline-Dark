Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Stockpiles
    Public Class StockpileManualAdjustmentEdit
        Inherits Core.Website.Stockpiles.StockpileManualAdjustmentEdit

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim stockpileTerm As String = ReconcilorFunctions.GetSiteTerminology("Stockpile")

            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_ADD")
            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_SURVEY_LIST")
            ReconcilorContent.SideNavigation.AddItem("STOCKPILE_GROUP_MANAGE", New ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Utilities/ReferenceStockpileGroupAdministration.aspx", "", "Manage " & stockpileTerm & " Groups", ""), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class
End Namespace