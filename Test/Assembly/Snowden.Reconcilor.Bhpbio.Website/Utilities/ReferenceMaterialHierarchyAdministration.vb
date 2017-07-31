Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class ReferenceMaterialHierarchyAdministration
        Inherits Core.Website.Utilities.ReferenceMaterialHierarchyAdministration

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))
            End With

        End Sub
    End Class
End Namespace