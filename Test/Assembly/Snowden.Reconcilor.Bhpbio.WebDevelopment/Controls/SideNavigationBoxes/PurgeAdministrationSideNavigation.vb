Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes
Imports Snowden.Common.Web.BaseHtmlControls
Namespace ReconcilorControls.SideNavigationBoxes
    Public Class PurgeAdministrationSideNavigation
        Inherits SideNavigationBox
        Public Sub New()
            MyBase.New()
            Title = "Purge Administration"
            Width = 195
        End Sub
        Protected Overrides Sub PopulateNavigationItems(ByVal items As IDictionary(Of String, SideNavigationItem))
            items.Add("PURGE_DATA", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("./PurgeAdministration.aspx", "", "Purge List"), New Tags.HtmlImageTag("../images/showAll.gif")))
            ' We only have one security option for the purging functionality
            ' We are using the default security option for the second item
            ' It seems unnatural to hook security options by literal string to the side navigation link items
            ' Brandon Driesen - 23 Dec 2010
            items.Add("REC_GRANT", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("javascript:ShowPurgeRequestAddForm();", "", "Add Purge Request"), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class
End Namespace
