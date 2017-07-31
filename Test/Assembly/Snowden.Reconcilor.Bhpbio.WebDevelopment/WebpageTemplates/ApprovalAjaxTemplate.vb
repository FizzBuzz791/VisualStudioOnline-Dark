Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace WebpageTemplates
    Public Class ApprovalAjaxTemplate
        Inherits ReconcilorAjaxPage

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_GRANT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)
            MyBase.OnInit(e)

            EventLogAuditTypeName = "Approval UI Event"
            EventLogDescription = "Approval UI Event"
        End Sub
    End Class
End Namespace