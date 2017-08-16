Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys

Namespace Utilities
    Public Class DefaultProductTypeAdministration
        Inherits WebpageTemplates.UtilitiesTemplate
        Private _addButton As New InputButtonFormless
        Private _cancelButton As New InputButtonFormless
        Private _productTypeSideNavigation As Bhpbio.WebDevelopment.ReconcilorControls.SideNavigationBoxes.ProductTypeNavigationBox
        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)
        End Sub
        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            _productTypeSideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.ProductType.ToString, Resources),
                WebDevelopment.ReconcilorControls.SideNavigationBoxes.ProductTypeNavigationBox)
            _productTypeSideNavigation.LoadItems()
            ReconcilorContent.SideNavigation = _productTypeSideNavigation

        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))


            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Product Type Configuration"))
            End With

            Dim itemDiv As New Tags.HtmlDivTag("itemDetail")
            itemDiv.StyleInline = "width:500px;"

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(itemDiv)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))

                .Controls.Add(New Tags.HtmlDivTag("itemList"))
            End With
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetDefaultProductTypeList();"))
        End Sub
    End Class
End Namespace
