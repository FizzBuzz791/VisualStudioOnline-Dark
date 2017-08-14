Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys

Namespace WebpageTemplates
    Public Class ApprovalTemplate
        Inherits ReconcilorWebpage

        Private _helpBox As SideNavigationBoxes.AdhocSideNavigation

        Protected ReadOnly Property HelpBox() As SideNavigationBoxes.AdhocSideNavigation
            Get
                Return _helpBox
            End Get
        End Property

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_GRANT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioApproval.js"))
                .Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioLocationControl.js"))
            End With

            'With PageHeader.LinkTags
            '    .Add(New Tags.HtmlLinkTag("stylesheet", Tags.LinkType.TextCss, "", "../css/LocationPicker.css"))
            'End With

            ReconcilorHeader.SiteNavigation.KeySelected = "Approval"
            EventLogAuditTypeName = ReconcilorFunctions.GetSiteTerminology("Approval") & " UI Event"
            EventLogDescription = ReconcilorFunctions.GetSiteTerminology("Approval") & " UI Event"

            With ReconcilorContent
                .HasSideNavigation = True
                .SideNavigation = Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.Approval.ToString, Resources)
                .SideNavigation.LoadItems()
            End With

            With _helpBox
                .Width = 250
                .Title = "Help"
            End With

            With ReconcilorContent.SideContainerContent
                .Controls.Add(New LiteralControl("<br>"))
                .Controls.Add(New LiteralControl("<br>"))
                .Controls.Add(HelpBox)
            End With
        End Sub

        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)

            _helpBox = New SideNavigationBoxes.AdhocSideNavigation(Resources)
        End Sub
    End Class
End Namespace
