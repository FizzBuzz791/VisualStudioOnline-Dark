Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags

Namespace ReconcilorControls.SideNavigationBoxes
    Public Class SampleStationSideNavigation
        Inherits SideNavigationBox

        Public Sub New()
            MyBase.New()
            Title = "Sample Stations"
            CheckSecurity = False
        End Sub

        Protected Overrides Sub PopulateNavigationItems(items As IDictionary(Of String, SideNavigationItem))
            items.Add("UTILITIES_SAMPLE_STATION_ADD",
                      New SideNavigationLinkItem(New Tags.HtmlAnchorTag("#", "", "Add New", "AddDefaultSampleStation()"),
                                                 New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub
    End Class
End Namespace