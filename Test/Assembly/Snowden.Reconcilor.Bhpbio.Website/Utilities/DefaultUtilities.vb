Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI

Namespace Utilities
    Public Class DefaultUtilities
        Inherits Core.Website.Utilities.DefaultUtilities

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            Dim controlRemoval As New ArrayList()

            If (Resources.UserSecurity.HasAccess("MANAGE_BHPBIO_CUSTOM_FIELDS_CONFIGURATION")) Then
                AddAdministrationItem("./CustomFieldsConfiguration.aspx", "Custom Fields Configuration")
            End If

            If (Resources.UserSecurity.HasAccess("PURGE_DATA")) Then
                AddAdministrationItem("./PurgeAdministration.aspx", "Purge Administration")
            End If

            If (Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_VIEW") Or
                Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_EDIT")) Then
                AddAdministrationItem("./DefaultLumpFinesAdministration.aspx", "Default Lump Fines")
            End If

            If (Resources.UserSecurity.HasAccess("UTILITIES_OUTLIER_SERIES")) Or
                (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                AddAdministrationItem("./OutlierSeriesConfiguration.aspx", "Outlier Series Configuration")
            End If

            With ReferenceData.Controls

                If (Resources.UserSecurity.HasAccess("UTILITIES_PRODUCT_TYPE")) Or
                (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                    .Add(New Tags.HtmlAnchorTag("./DefaultProductTypeAdministration.aspx", "", "Product Types"))
                    .Add(New Tags.HtmlBRTag)
                End If
                If (Resources.UserSecurity.HasAccess("UTILITIES_SHIPPING_TARGETS")) Or
                (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                    .Add(New Tags.HtmlAnchorTag("./DefaultShippingTargetsAdministration.aspx", "", "Shipping Targets"))
                    .Add(New Tags.HtmlBRTag)
                End If
                If (Resources.UserSecurity.HasAccess("UTILITIES_DEPOSITS")) Or
                (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                    .Add(New Tags.HtmlAnchorTag("./DefaultDepositAdministration.aspx", "", "Deposits"))
                    .Add(New Tags.HtmlBRTag)
                End If
                If (Resources.UserSecurity.HasAccess("UTILITIES_SAMPLE_STATIONS")) Or
                        (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                    .Add(New Tags.HtmlAnchorTag("./DefaultSampleStationsAdministration.aspx", "", "Sample Stations"))
                    .Add(New Tags.HtmlBRTag)
                End If
            End With

            RemoveLink(ReferenceData, "Waste Types")
            RemoveLink(ReferenceData, "Trucks")
            RemoveLink(ReferenceData, "Drill Rigs")
            RemoveLink(ReferenceData, "Object Notes")

            RenameLink("Monthly Approval", "Recalculation Start Date")

        End Sub

        Private Sub AddAdministrationItem(ByVal url As String, ByVal text As String)
            If Administration.Controls.Count > 0 AndAlso _
                (Not TypeOf (Administration.Controls(Administration.Controls.Count - 1)) Is Tags.HtmlBRTag) Then
                Administration.Controls.Add(New Tags.HtmlBRTag)
            End If

            Administration.Controls.Add(New Tags.HtmlAnchorTag(url, "", text))
            Administration.Controls.Add(New Tags.HtmlBRTag)
        End Sub

        Protected Sub RenameLink(linkText As String, newText As String)
            Dim control = Administration.Controls.OfType(Of Tags.HtmlAnchorTag).Where(Function(c) c.InnerText.ToUpper = linkText.ToUpper).FirstOrDefault
            If control IsNot Nothing Then control.InnerText = newText
        End Sub

        ' Removes a link from the group box.
        ' TODO: This code should probably be refactored, surely there is a better way of doing things??
        Protected Overridable Sub RemoveLink(ByVal group As GroupBox, ByVal item As String)
            Dim i As Integer
            Dim itemLocation As Integer?
            Dim control As Web.UI.Control
            Dim anchorControl As Tags.HtmlAnchorTag
            Dim controls As ControlCollection = group.Controls

            ' Cycle through all of the items in the group box and find the item requested.
            For i = 0 To controls.Count - 1
                control = controls(i)
                If TypeOf (control) Is Tags.HtmlAnchorTag Then
                    anchorControl = DirectCast(control, Tags.HtmlAnchorTag)
                    If anchorControl.InnerText.ToUpper = item.ToUpper Then
                        itemLocation = i
                    End If
                End If
            Next

            If itemLocation.HasValue Then
                ' Remove the item from the list.
                controls.RemoveAt(itemLocation.Value)
                ' Remove the following BR tag if it has one
                If controls.Count > (itemLocation.Value) AndAlso _
                 TypeOf (controls(itemLocation.Value)) Is Tags.HtmlBRTag Then
                    controls.RemoveAt(itemLocation.Value)
                End If
            End If


        End Sub

    End Class

End Namespace
