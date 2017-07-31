Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Stockpiles

    Public Class StockpileDetailsTabBalance
        Inherits Core.Website.Stockpiles.StockpileDetailsTabBalance

        Protected Overrides Sub RunAjax()

            TonnesTerm = "Reconciled Tonnes"
            MyBase.RunAjax()

        End Sub

        Protected Overrides Sub RetrieveRequestData()

            Dim RequestText As String
            Dim dateFilter As DateTime

            StockpileId = RequestAsInt32("StockpileId")

            RequestText = Trim(Request("StockpileDateFromText"))

            If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                StartDate = dateFilter
            Else
                StartDate = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_From", Date.Now.ToString()))
            End If

            RequestText = Trim(Request("StockpileDateToText"))

            If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                EndDate = dateFilter
            Else
                EndDate = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_To", Date.Now.ToString()))
            End If

            If (Trim(Request("StockpileDateFromText")) = String.Empty And Trim(Request("StockpileDateToText")) = String.Empty) Then
                Dim strPopulateDate As String = "SetupStockpileDetailsFilterDates('" + StartDate.ToString("dd-MMM-yyyy") + "', '" + EndDate.ToString("dd-MMM-yyyy") + "');"
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, strPopulateDate))
            End If

            SaveStockpileDetailsFilterValues()

        End Sub

        Protected Overrides Sub SetupPageControls()

            Dim useColumns As New Text.StringBuilder("Transaction_Date,Tonnes")
            Dim gradeName As String
            Dim totalColumns As New Text.StringBuilder("Tonnes")
            Dim balanceTables() As ReconcilorControls.ReconcilorTable = {AdditionsTable, RemovalsTable, BalanceTable}

            GetTransactionData()

            For Each gradeName In Grades.Keys
                useColumns.Append(",")
                useColumns.Append(gradeName)

                totalColumns.Append(",")
                totalColumns.Append(gradeName)

                TransactionData.Columns.Add(New Data.DataColumn("Weighted_" & gradeName, GetType(Single), gradeName & " * Tonnes "))
            Next

            For Each reconcilorTable As ReconcilorControls.ReconcilorTable In balanceTables
                With reconcilorTable

                    .DataSource = TransactionData

                    .ContainerPadding += 200 'Container padding on tabs
                    .UseColumns = useColumns.ToString.Split(","c)
                    .TotalColumns = totalColumns.ToString.Split(","c)

                    For Each grade In Grades.Values
                        If grade.IsVisible Then
                            .Columns.Add(grade.Name, New ReconcilorControls.ReconcilorTableColumn(grade.Name))
                        End If
                    Next

                    .ItemDataBoundCallback = AddressOf ReturnTable_ItemDataboundCallback

                    If reconcilorTable.Equals(AdditionsTable) Then
                        .DisplayGrandTotal = True
                        .GrandTotalItemCallback = AddressOf AdditionsTable_SummedItemCallback
                        .Filter = AdditionsFilter
                    ElseIf reconcilorTable.Equals(RemovalsTable) Then
                        .DisplayGrandTotal = True
                        .GrandTotalItemCallback = AddressOf RemovalsTable_SummedItemCallback
                        .Filter = RemovalsFilter
                    Else
                        .DisplayGrandTotal = False
                        .Filter = BalancesFilter
                    End If

                    .Columns.Add("Transaction_Date", New ReconcilorControls.ReconcilorTableColumn("Date"))
                    .Columns.Add("Tonnes", New ReconcilorControls.ReconcilorTableColumn(TonnesTerm))
                    .Columns("Transaction_Date").DateTimeFormat = Application("DateFormat").ToString
                    .DataBind()

                    .Columns("Transaction_Date").Width = 80
                End With
            Next

            With AdditionsGroup
                .Title = "Additions to " & ReconcilorFunctions.GetSiteTerminology("Stockpile")
                .Controls.Add(AdditionsTable)
                .Controls.Add(New LiteralControl("* Indicates Reconciled Figure"))
            End With

            With RemovalsGroup
                .Title = "Removals from " & ReconcilorFunctions.GetSiteTerminology("Stockpile")
                .Controls.Add(RemovalsTable)
                .Controls.Add(New LiteralControl("* Indicates Reconciled Figure"))
            End With

            With BalanceGroup
                .Title = "Closing Balances for " & ReconcilorFunctions.GetSiteTerminology("Stockpile")
                .Controls.Add(BalanceTable)
                .Controls.Add(New LiteralControl("* Indicates Reconciled Figure"))
            End With

            Dim asterisk As String = " *"

            For Each reconcilorTable As ReconcilorControls.ReconcilorTable In balanceTables
        
                reconcilorTable.Columns("Tonnes").HeaderText = "Tonnes" + asterisk
                reconcilorTable.Columns("P").Width = 80
                reconcilorTable.Columns("P").HeaderText = reconcilorTable.Columns("P").HeaderText + asterisk
                reconcilorTable.Columns("P").Width = 80
                reconcilorTable.Columns("Al2O3").HeaderText = reconcilorTable.Columns("Al2O3").HeaderText + asterisk
                reconcilorTable.Columns("Al2O3").Width = 80
                reconcilorTable.Columns("LOI").HeaderText = reconcilorTable.Columns("LOI").HeaderText + asterisk
                reconcilorTable.Columns("LOI").Width = 80
                reconcilorTable.Columns("SiO2").HeaderText = reconcilorTable.Columns("SiO2").HeaderText + asterisk
                reconcilorTable.Columns("SiO2").Width = 80
                reconcilorTable.Columns("Fe").HeaderText = reconcilorTable.Columns("Fe").HeaderText + asterisk
                reconcilorTable.Columns("Fe").Width = 80
                reconcilorTable.Columns("H2O").HeaderText = reconcilorTable.Columns("H2O").HeaderText + asterisk
                reconcilorTable.Columns("H2O").Width = 80
            Next
        End Sub

    End Class
End Namespace
