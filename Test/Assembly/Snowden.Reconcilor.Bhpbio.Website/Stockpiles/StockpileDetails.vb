Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Stockpiles
    Public Class StockpileDetails
        Inherits Core.Website.Stockpiles.StockpileDetails

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            StockpileDetailsFilter.TonnesTerm = "Reconciled Tonnes"

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioStockpiles.js", ""))
            End With
        End Sub

        Protected Overrides Sub SetupPageControls()
            Dim key As String
            MyBase.SetupPageControls()

            StockpileDetailsFilter.FromRequired = True
            StockpileDetailsFilter.ToRequired = True
            StockpileDetailsFilter.ShowAlerts = True

            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_ADD")

            Dim stockpileTerm As String = ReconcilorFunctions.GetSiteTerminology("Stockpile")

            ReconcilorContent.SideNavigation.AddItem("STOCKPILE_GROUP_MANAGE", New ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem(New Tags.HtmlAnchorTag("../Utilities/ReferenceStockpileGroupAdministration.aspx", "", "Manage " & stockpileTerm & " Groups", ""), New Tags.HtmlImageTag("../images/showAll.gif")))
            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_SURVEY_LIST")

            For Each key In New String() {"STOCKPILE_TRANSFER", "STOCKPILE_MANUAL_ADJUST_ADD", "STOCKPILE_ADMINISTER_BUILDS", _
                                          "STOCKPILE_DELETE", "STOCKPILE_EDIT", "STOCKPILE_SURVEY_LIST"}
                TasksSidebar.TryRemoveItem(key)
            Next
        End Sub

        Protected Overrides Sub SetupAttributesTabPage()
            MyBase.SetupAttributesTabPage()

            With AttributesTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileAttributeContent'); ClearStockpileDetailsFilterDates();" + AttributesTab.OnClickScript
            End With
        End Sub

        Protected Overrides Sub SetupBalancesTabPage()
            MyBase.SetupBalancesTabPage()

            With BalancesTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileBalanceContent'); ClearStockpileDetailsFilterDates();" + BalancesTab.OnClickScript
            End With
        End Sub

        Protected Overrides Sub SetupChartingTabPage()
            MyBase.SetupChartingTabPage()

            With ChartingTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileChartingContent'); ClearStockpileDetailsFilterDates();" + ChartingTab.OnClickScript
            End With
        End Sub

        Protected Overrides Sub SetupActivityTabPage()
            MyBase.SetupActivityTabPage()
            With ActivityTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileActivityContent'); ClearStockpileDetailsFilterDates();" + ActivityTab.OnClickScript
            End With
        End Sub

        Protected Overrides Sub SetupGenealogyTabPage()
            MyBase.SetupGenealogyTabPage()
            With GenealogyTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileGenealogyContent'); ClearStockpileDetailsFilterDates();" + GenealogyTab.OnClickScript
            End With
        End Sub

        Protected Overrides Sub SetupLocationTabPage()
            MyBase.SetupLocationTabPage()
            With LocationTab
                'Need to clear content to force postback - need to load data each tab click
                .OnClickScript = "ClearElement('StockpileLocationContent'); ClearStockpileDetailsFilterDates();" + LocationTab.OnClickScript

            End With
        End Sub


    End Class
End Namespace