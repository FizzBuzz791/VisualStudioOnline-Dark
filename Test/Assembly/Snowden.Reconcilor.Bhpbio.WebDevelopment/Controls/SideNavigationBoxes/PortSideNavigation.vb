Imports SideNavigationBox = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationBox
Imports SideNavigationLinkItem = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags

Namespace ReconcilorControls.SideNavigationBoxes

    Public Class PortSideNavigationBox
        Inherits SideNavigationBox

        Public Sub New()
            MyBase.New()

            Title = "Port"
        End Sub

        Protected Overrides Sub PopulateNavigationItems(ByVal items As System.Collections.Generic.IDictionary(Of String, Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationItem))
            items.Add("PORT_GRANT", New SideNavigationLinkItem( _
             New Tags.HtmlAnchorTag("./Default.aspx", "", "Port Details", ""), _
             New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class

End Namespace