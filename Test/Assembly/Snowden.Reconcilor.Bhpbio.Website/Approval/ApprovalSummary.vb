Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment

Namespace Approval
    Public Class ApprovalSummary
        Inherits WebpageTemplates.ApprovalTemplate

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With ReconcilorContent.ContainerContent
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                 Tags.ScriptLanguage.JavaScript, "", "LoadDefaultApprovalSummary();"))
            End With

            With HelpBox
                .Container.ID = "ApprovalHelpBox"
                .Content.ID = "ApprovalHelpBoxContent"
                .Title = "Approval Legend"
                .Visible = True
            End With
        End Sub
    End Class
End Namespace