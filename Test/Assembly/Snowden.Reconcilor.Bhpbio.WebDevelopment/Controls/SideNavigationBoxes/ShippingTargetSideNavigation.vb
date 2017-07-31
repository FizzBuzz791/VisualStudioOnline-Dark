Imports SideNavigationBox = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationBox
Imports SideNavigationLinkItem = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags

Namespace ReconcilorControls.SideNavigationBoxes

    Public Class ShippingTargetNavigationBox
        Inherits SideNavigationBox

        Public Sub New()
            MyBase.New()

            Title = "Shipping Targets"
            CheckSecurity = False
        End Sub

        Protected Overrides Sub PopulateNavigationItems(ByVal items As System.Collections.Generic.IDictionary(Of String, Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationItem))
            items.Add("UTILITIES_SHIPPINGTARGET_ADD",
                                                     New SideNavigationLinkItem(New Tags.HtmlAnchorTag("#", "", "Add New", "EditShippingTarget(0)"), New Tags.HtmlImageTag("../images/showAll.gif")))


        End Sub
    End Class

End Namespace