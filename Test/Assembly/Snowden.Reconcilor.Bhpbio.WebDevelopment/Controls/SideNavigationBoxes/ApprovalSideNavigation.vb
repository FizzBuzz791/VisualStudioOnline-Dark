Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes
Imports SideNavigationLinkItem = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem

Namespace ReconcilorControls.SideNavigationBoxes
    Public Class ApprovalSideNavigation
        Inherits SideNavigationBox

        Public Sub New()
            MyBase.New()

            Width = 400 '200
            Title = "Approvals Menu"
        End Sub

        Protected Overrides Sub PopulateNavigationItems(ByVal items As IDictionary(Of String, SideNavigationItem))
            items.Add("APPROVAL_SUMMARY", New BhpbioApprovalSummarySideNavigationItem())

            Dim hrSideNavigationItem As New SideNavigationItem(New LiteralControl("<hr/>")) With {
                .CheckSecurity = False
            }

            items.Add("HORIZONTALLINE", hrSideNavigationItem) 'Approach copied from 'C:\Snowden\Src\Reconcilor_Core\Test\Assembly\Snowden.Reconcilor.Core.WebDevelopment\ReconcilorControls\SideNavigationBoxes\UtilitiesSideNavigation.vb'
            items.Add("APPROVAL_BULK", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("./ApprovalBulk.aspx", "", "Bulk Approval & Unapproval"), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class
End Namespace