Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.SideNavigationBoxes
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI

Namespace Utilities
    Public Class PurgeAdministration
        Inherits WebpageTemplates.UtilitiesTemplate

        Private _sideNavigation As SideNavigationBox
        Protected ReadOnly Property SideNavigation() As SideNavigationBox
            Get
                'lazy load
                If Me._sideNavigation Is Nothing Then
                    SyncLock GetType(PurgeAdministration)
                        If Me._sideNavigation Is Nothing Then
                            Me._sideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create("Purge", Resources), PurgeAdministrationSideNavigation)
                        End If
                    End SyncLock
                End If
                Return Me._sideNavigation
            End Get
        End Property

        Protected Overrides Sub HandlePageSecurity()
            'Ignores the base page security assertions
            If Not Resources.UserSecurity.HasAccess("PURGE_DATA") Then
                MyBase.ReportAccessDenied()
            End If
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            If Not Me.SideNavigation Is Nothing Then
                Me.SideNavigation.LoadItems()
                ReconcilorContent.SideNavigation = Me.SideNavigation
            End If

        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Purge Administration"))
            End With

            With ReconcilorContent.ContainerContent

                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag("itemList"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemDetail"))
            End With
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioPurge.js", ""))
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetPurgeAdministrationList();"))
        End Sub
    End Class
End Namespace