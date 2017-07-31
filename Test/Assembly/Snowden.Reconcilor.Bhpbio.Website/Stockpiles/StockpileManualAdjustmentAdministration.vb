Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Stockpiles
    Public Class StockpileManualAdjustmentAdministration
        Inherits Core.Website.Stockpiles.StockpileManualAdjustmentAdministration

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioStockpiles.js", ""))

            End With

            Dim stockpileTerm As String = ReconcilorFunctions.GetSiteTerminology("Stockpile")

            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_ADD")
            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_SURVEY_LIST")
            ReconcilorContent.SideNavigation.AddItem("STOCKPILE_GROUP_MANAGE", New ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Utilities/ReferenceStockpileGroupAdministration.aspx", "", "Manage " & stockpileTerm & " Groups", ""), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class
End Namespace
