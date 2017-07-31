Imports ReconcilorControls = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace Port
    Public Class PortBlendingList
        Inherits PortListBase

        Const _portBlendingListHeight As Int32 = 200

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim PortBlendingData As DataTable
            Dim PortBlendingTable As ReconcilorControls.ReconcilorTable

            Dim filterDateFrom As DateTime
            Dim filterDateTo As DateTime
            Dim filterLocationId As Int32

            If DateFrom.HasValue Then
                filterDateFrom = DateFrom.Value
            Else
                filterDateFrom = NullValues.DateTime
            End If

            If DateTo.HasValue Then
                filterDateTo = DateTo.Value
            Else
                filterDateTo = NullValues.DateTime
            End If

            If LocationId.HasValue Then
                filterLocationId = LocationId.Value
            Else
                filterLocationId = NullValues.Int32
            End If

            PortBlendingData = DalReport.GetBhpbioPortBlending(filterDateFrom, filterDateTo, filterLocationId)
            PortBlendingData.Columns.Remove("BhpbioPortBlendingId")
            PortBlendingData.Columns.Remove("SourceHubLocationId")
            PortBlendingData.Columns.Remove("DestinationHubLocationId")
            PortBlendingData.Columns("StartDate").ColumnName = "Start Date"
            PortBlendingData.Columns("EndDate").ColumnName = "End Date"
            PortBlendingData.Columns("DestinationHubLocationName").ColumnName = "Destination Hub"
            PortBlendingData.Columns("SourceHubLocationName").ColumnName = "Rake Hub"
            PortBlendingData.Columns("LoadSiteLocationName").ColumnName = "Load Site"

            PortBlendingTable = New ReconcilorControls.ReconcilorTable(PortBlendingData)
            AddConfigurableColumns("Port_Blending", PortBlendingTable)
            FormatListingTable(PortBlendingTable)

            PortBlendingTable.Columns.Item("Start Date").DateTimeFormat = Application("DateFormat").ToString
            PortBlendingTable.Columns.Item("End Date").DateTimeFormat = Application("DateFormat").ToString

            PortBlendingTable.ItemDataBoundCallback = AddressOf TableItemDataboundCallback

            PortBlendingTable.DataBind()

            For Each column As String In PortBlendingTable.Columns.Keys
                PortBlendingTable.Columns.Item(column).TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                PortBlendingTable.Columns.Item(column).HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
            Next

            'Add spacer between filter box and table.
            Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))

            'Add the control to the job queue table.
            Controls.Add(PortBlendingTable)
        End Sub
    End Class
End Namespace