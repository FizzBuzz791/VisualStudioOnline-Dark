Imports SideNavigationBox = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationBox
Imports SideNavigationLinkItem = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags

Namespace ReconcilorControls.SideNavigationBoxes

    Public Class DepositSideNavigationBox
        Inherits SideNavigationBox

        Public Sub New()
            MyBase.New()
            Title = "Deposit"
            CheckSecurity = False
        End Sub

        Protected Overrides Sub PopulateNavigationItems(ByVal items As System.Collections.Generic.IDictionary(Of String, Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationItem))
            items.Add("UTILITIES_DEPOSITS", New SideNavigationLinkItem(New Tags.HtmlAnchorTag("#", "", "Add New", "AddDefaultDeposit()"), New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class

End Namespace