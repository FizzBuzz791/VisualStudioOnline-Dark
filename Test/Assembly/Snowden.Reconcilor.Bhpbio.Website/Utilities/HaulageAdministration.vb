Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class HaulageAdministration
        Inherits Core.Website.Utilities.HaulageAdministration

        Sub New()
            LocationId = Nothing
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            ' Remove the Bulk Edit and New Record links on the side menu
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_BULK_EDIT")
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_NEW_RECORD")
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioUtilities.js"))
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/haulageadministrationbulkedit.js"))
            End With

            ' Hookup callback for when the layout of the filter box is complete
            HaulageAdministrationFilter.CompleteLayoutCallback = AddressOf CompleteLayoutCallback
        End Sub

        Protected Sub CompleteLayoutCallback()
            'Change the text of the filter button
            HaulageAdministrationFilter.LocationFilterButton.Text = "Location Filter"
        End Sub

        Protected Overrides Sub RetrieveRequestData()

            LocationId = Convert.ToInt32(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Location", DoNotSetValues.Int32.ToString()))
            If Not Request("lid") Is Nothing Then
                LocationId = RequestAsInt32("lid")
            End If
        End Sub

    
    End Class
End Namespace
