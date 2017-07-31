Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class ReferenceStockpileGroupAdministration
        Inherits Core.Website.Utilities.ReferenceStockpileGroupAdministration

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))
            End With

        End Sub

    End Class
End Namespace
