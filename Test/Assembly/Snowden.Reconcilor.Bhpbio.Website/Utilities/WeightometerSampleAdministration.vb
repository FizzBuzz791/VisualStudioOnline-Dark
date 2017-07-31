Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class WeightometerSampleAdministration
        Inherits Core.Website.Utilities.WeightometerSampleAdministration

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_WEIGHTOMETER_SAMPLE_ADD")

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))
            End With
        End Sub
    End Class
End Namespace
