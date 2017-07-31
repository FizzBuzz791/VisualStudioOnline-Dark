Imports ReconcilorControls = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace Port
    Public Class PortShippingList
        Inherits PortListBase

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim shippingData As DataTable
            Dim shippingTable As ReconcilorControls.ReconcilorTable

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

            shippingData = DalReport.GetBhpbioShippingNomination(filterDateFrom, filterDateTo, filterLocationId)
            Try
                shippingData.Columns.Remove("BhpbioShippingNominationItemId")
                shippingData.Columns.Remove("HubLocationId")
                shippingData.Columns("HubLocationName").ColumnName = "Hub"
                shippingData.DefaultView.Sort = "DateOrder"
                shippingTable = New ReconcilorControls.ReconcilorTable(shippingData.DefaultView.ToTable())
            Finally
                If Not shippingData Is Nothing Then
                    shippingData.Dispose()
                    shippingData = Nothing
                End If
            End Try

            AddConfigurableColumns("Port_Shipping", shippingTable)
            FormatListingTable(shippingTable)

            ' Check that the column exists before formatting it
            If shippingTable.Columns.ContainsKey("OfficialFinishTime") Then
                shippingTable.Columns.Item("OfficialFinishTime").DateTimeFormat = Application("DateTimeFormat").ToString
            End If

            If shippingTable.Columns.ContainsKey("LastAuthorisedDate") Then
                shippingTable.Columns.Item("LastAuthorisedDate").DateTimeFormat = Application("DateFormat").ToString
            End If

            If shippingTable.Columns.ContainsKey("COA") Then
                shippingTable.Columns.Item("COA").DateTimeFormat = Application("DateTimeFormat").ToString
            End If

            shippingTable.ItemDataBoundCallback = AddressOf TableItemDataboundCallback

            shippingTable.DataBind()

            For Each column As String In shippingTable.Columns.Keys
                shippingTable.Columns.Item(column).TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                shippingTable.Columns.Item(column).HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
            Next

            'Add spacer between filter box and table.
            Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))

            'Add the control to the job queue table.
            Controls.Add(shippingTable)
        End Sub
    End Class
End Namespace
