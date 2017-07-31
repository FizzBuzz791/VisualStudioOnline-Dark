Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Utilities

    Public Class DefaultShippingTargetsAdministration
        Inherits WebpageTemplates.UtilitiesTemplate

        Private _shippingTargetSideNavigation As Bhpbio.WebDevelopment.ReconcilorControls.SideNavigationBoxes.ShippingTargetNavigationBox
        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Shipping Target Configuration"))
            End With

            Dim itemDiv As New Tags.HtmlDivTag("itemList")
            itemDiv.StyleInline = "width:500px;"

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(itemDiv)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemDetail"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))

            End With
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetDefaultshippingTargetList();"))

        End Sub
        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            _shippingTargetSideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create("ShippingTarget", Resources),
                                Bhpbio.WebDevelopment.ReconcilorControls.SideNavigationBoxes.ShippingTargetNavigationBox)
            _shippingTargetSideNavigation.LoadItems()
            ReconcilorContent.SideNavigation = _shippingTargetSideNavigation

        End Sub

    End Class
End Namespace
