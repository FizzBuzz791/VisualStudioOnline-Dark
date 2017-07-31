Imports ReconcilorControls = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace Port
    Public Class PortBalancesList
        Inherits PortListBase

        Const _portBalancesListHeight As Int32 = 200

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim PortBalancesData As DataTable
            Dim PortBalancesTable As ReconcilorControls.ReconcilorTable

            Dim filterDateFrom As DateTime
            Dim filterDateTo As DateTime
            Dim filterLocationId As Int32

            If DateFrom.HasValue Then
                filterDateFrom = DateFrom.Value
            Else
                filterDateFrom = NullValues.DateTime
            End If

            If DateTo.HasValue Then
                filterDateTo = DateTo.Value.AddDays(1)
            Else
                filterDateTo = NullValues.DateTime
            End If

            If LocationId.HasValue Then
                filterLocationId = LocationId.Value
            Else
                filterLocationId = NullValues.Int32
            End If

            Dim dateToStr As String = Resources.UserSecurity.GetSetting("Port_Filter_DateTo", Nothing)
            Dim dateFromStr As String = Resources.UserSecurity.GetSetting("Port_Filter_DateFrom", Nothing)

            Date.TryParse(dateToStr, filterDateTo)
            Date.TryParse(dateFromStr, filterDateFrom)

            'load the data
            PortBalancesData = DalReport.GetBhpbioPortBalance(filterDateFrom, filterDateTo, filterLocationId)
            PortBalancesData.Columns.Remove("BhpbioPortBalanceId")
            PortBalancesData.Columns.Remove("HubLocationId")
            PortBalancesData.Columns("HubLocationName").ColumnName = "Hub"
            PortBalancesData.Columns("BalanceDate").ColumnName = "Balance Date"

            PortBalancesTable = New ReconcilorControls.ReconcilorTable(PortBalancesData)
            AddConfigurableColumns("Port_Balances", PortBalancesTable)
            FormatListingTable(PortBalancesTable)

            PortBalancesTable.Columns.Item("Balance Date").DateTimeFormat = Application("DateFormat").ToString

            PortBalancesTable.ItemDataBoundCallback = AddressOf TableItemDataboundCallback

            PortBalancesTable.DataBind()

            For Each column As String In PortBalancesTable.Columns.Keys
                PortBalancesTable.Columns.Item(column).TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                PortBalancesTable.Columns.Item(column).HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                PortBalancesTable.Columns.Item(column).Width = Convert.ToInt32(Math.Round(PortBalancesTable.Columns.Item(column).Width * 1.5))
            Next

            'Add spacer between filter box and table.
            Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))

            'Add the control to the job queue table.
            Controls.Add(PortBalancesTable)
        End Sub
    End Class
End Namespace