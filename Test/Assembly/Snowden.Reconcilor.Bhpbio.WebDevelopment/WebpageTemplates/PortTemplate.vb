Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace WebpageTemplates
    Public Class PortTemplate
        Inherits ReconcilorWebpage

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("PORT_GRANT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioPort.js"))
            End With

            ReconcilorHeader.SiteNavigation.KeySelected = "Port"
            EventLogAuditTypeName = ReconcilorFunctions.GetSiteTerminology("Port") & " UI Event"
            EventLogDescription = ReconcilorFunctions.GetSiteTerminology("Port") & " UI Event"

            With ReconcilorContent
                .HasSideNavigation = True
                .SideNavigation = Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.Port.ToString, Resources)
                .SideNavigation.LoadItems()
            End With
        End Sub
    End Class
End Namespace
