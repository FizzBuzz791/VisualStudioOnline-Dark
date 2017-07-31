Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI

Namespace Utilities
    Public Class DefaultOutlierSeriesConfiguration
        Inherits WebpageTemplates.UtilitiesTemplate

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Outlier Series Configuration"))
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
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetDefaultOutlierSeriesList();"))
        End Sub

    End Class
End Namespace
