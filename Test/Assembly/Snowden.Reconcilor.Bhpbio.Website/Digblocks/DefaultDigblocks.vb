Imports Snowden.Common.Web.BaseHtmlControls

Namespace Digblocks
    Public Class DefaultDigblocks
        Inherits Core.Website.Digblocks.DefaultDigblocks

        Public Sub New()
            MyBase.New()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioAnalysis.js", ""))
            End With

            ReconcilorContent.SideNavigation.TryRemoveItem("DIGBLOCK_ADD")
        End Sub

    End Class
End Namespace