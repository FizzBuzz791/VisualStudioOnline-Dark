Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class ReferenceInterfaceListingList
        Inherits Core.Website.Utilities.ReferenceInterfaceListingList

        Protected Overrides Sub CreateReturnTable()
            Dim UseColumns() As String = {"Display_Name", "Edit Columns"}

            ReturnTable = New ReconcilorControls.ReconcilorTable(ListTable, UseColumns)
            With ReturnTable

                Dim listingReconcilorColumn As ReconcilorControls.ReconcilorTableColumn = _
                New ReconcilorControls.ReconcilorTableColumn("Listing")

                listingReconcilorColumn.Width = 200

                .Columns.Add("Display_Name", listingReconcilorColumn)
                .DataBind()

                .Height = 220
            End With
        End Sub

    End Class
End Namespace
