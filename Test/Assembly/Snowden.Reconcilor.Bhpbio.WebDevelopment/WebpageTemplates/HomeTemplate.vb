Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace WebpageTemplates
    Public Class HomeTemplate
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.HomeTemplate

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             Tags.ScriptLanguage.JavaScript, "../js/BhpbioHome.js", ""))
        End Sub
    End Class
End Namespace