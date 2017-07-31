Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI

Namespace Utilities
    Public Class RecalcLogViewer
        Inherits Core.Website.Utilities.RecalcLogViewer

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))
            End With
        End Sub
    End Class
End Namespace

