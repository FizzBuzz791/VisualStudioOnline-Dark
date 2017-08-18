Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Website.Internal.SettingsModule
Imports System.Web.UI.WebControls

Namespace Utilities
    Public Class StratigraphyHierarchy
        Inherits WebpageTemplates.UtilitiesTemplate


        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Stratigraphy List"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("StratigraphyHierarchyContent"))
            End With

            MyBase.SetupPageLayout()
            ' *Must* add this script here so that it comes *after* common.js
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioCommon.js", String.Empty))
            'Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetSampleStations();"))

        End Sub

    End Class
End Namespace