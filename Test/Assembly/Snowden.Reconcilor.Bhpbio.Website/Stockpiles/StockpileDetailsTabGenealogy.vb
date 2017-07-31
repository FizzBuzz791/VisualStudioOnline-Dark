Imports System.Text
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Stockpiles

    Public Class StockpileDetailsTabGenealogy
        Inherits Core.Website.Stockpiles.StockpileDetailsTabGenealogy

        Private _asterisk As String = " *"

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Controls.Add(New LiteralControl("* Indicates Reconciled Figure"))
        End Sub

        Protected Overrides Sub CreateReturnTable()
            MyBase.CreateReturnTable()

            ReturnTable.Columns("Tonnes").HeaderText = "Tonnes" + _asterisk
            ReturnTable.Columns("Tonnes").Width = 60
            ReturnTable.Columns("P").HeaderText = ReturnTable.Columns("P").HeaderText + _asterisk
            ReturnTable.Columns("P").Width = 60
            ReturnTable.Columns("Al2O3").HeaderText = ReturnTable.Columns("Al2O3").HeaderText + _asterisk
            ReturnTable.Columns("Al2O3").Width = 60
            ReturnTable.Columns("LOI").HeaderText = ReturnTable.Columns("LOI").HeaderText + _asterisk
            ReturnTable.Columns("LOI").Width = 60
            ReturnTable.Columns("SiO2").HeaderText = ReturnTable.Columns("SiO2").HeaderText + _asterisk
            ReturnTable.Columns("SiO2").Width = 60
            ReturnTable.Columns("Fe").HeaderText = ReturnTable.Columns("Fe").HeaderText + _asterisk
            ReturnTable.Columns("Fe").Width = 60
            ReturnTable.Columns("H2O").HeaderText = ReturnTable.Columns("H2O").HeaderText + _asterisk
            ReturnTable.Columns("H2O").Width = 60

        End Sub

        Protected Overrides Sub CreateReturnTableComposition()

            Dim excludeColumns() As String = {"ID"}
            Dim GradeName As String

            ReturnTableComposition = New ReconcilorControls.ReconcilorTable(ListTableComposition)
            With ReturnTableComposition
                .ExcludeColumns = excludeColumns
                .ContainerPadding += 200 'Container padding on tabs

                .Columns.Add("Tonnes", New ReconcilorControls.ReconcilorTableColumn(TonnesTerm))
                .Columns.Add("Percentage_Value", New ReconcilorControls.ReconcilorTableColumn("% of Total"))
                .Columns.Add("Percentage_Digblock", New ReconcilorControls.ReconcilorTableColumn("% of<br>" & ReconcilorFunctions.GetSiteTerminology("Digblock")))
                .Columns.Add("Original_Source", New ReconcilorControls.ReconcilorTableColumn("Original Source"))
                .Columns("Original_Source").Width = 150

                'Prevent Auto Name formating of the grades
                For Each GradeName In Grades.Keys
                    .Columns.Add(GradeName, New ReconcilorControls.ReconcilorTableColumn(GradeName))
                    .Columns(GradeName).TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Right
                Next

                .ItemDataBoundCallback = AddressOf ReturnTable_ItemDataboundCallback

                .DataBind()
            End With

            ReturnTableComposition.Columns("Tonnes").HeaderText = "Tonnes" + _asterisk
            ReturnTableComposition.Columns("Tonnes").Width = 60
            If ReturnTableComposition.Columns.ContainsKey("P") Then
                ReturnTableComposition.Columns("P").HeaderText = ReturnTableComposition.Columns("P").HeaderText + _asterisk
                ReturnTableComposition.Columns("P").Width = 60
            End If
            If ReturnTableComposition.Columns.ContainsKey("Al2O3") Then
                ReturnTableComposition.Columns("Al2O3").HeaderText = ReturnTableComposition.Columns("Al2O3").HeaderText + _asterisk
                ReturnTableComposition.Columns("Al2O3").Width = 60
            End If
            If ReturnTableComposition.Columns.ContainsKey("LOI") Then
                ReturnTableComposition.Columns("LOI").HeaderText = ReturnTableComposition.Columns("LOI").HeaderText + _asterisk
                ReturnTableComposition.Columns("LOI").Width = 60
            End If
            If ReturnTableComposition.Columns.ContainsKey("SiO2") Then
                ReturnTableComposition.Columns("SiO2").HeaderText = ReturnTableComposition.Columns("SiO2").HeaderText + _asterisk
                ReturnTableComposition.Columns("SiO2").Width = 60
            End If
            If ReturnTableComposition.Columns.ContainsKey("Fe") Then
                ReturnTableComposition.Columns("Fe").HeaderText = ReturnTableComposition.Columns("Fe").HeaderText + _asterisk
                ReturnTableComposition.Columns("Fe").Width = 60
            End If
            If ReturnTableComposition.Columns.ContainsKey("H2O") Then
                ReturnTableComposition.Columns("H2O").HeaderText = ReturnTableComposition.Columns("H2O").HeaderText + _asterisk
                ReturnTableComposition.Columns("H2O").Width = 60
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            Dim requestText As String

            requestText = Trim(Request("StockpileDateFromText"))

            If ((Not requestText = "") AndAlso (IsDate(requestText))) Then
                [Date] = Convert.ToDateTime(requestText)
            Else
                [Date] = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_To", Date.Now.ToString()))
            End If

            If (Trim(Request("StockpileDateFromText")) = String.Empty) Then
                Dim strPopulateDate As String = "SetupStockpileDetailsFilterDates('" + [Date].ToString("dd-MMM-yyyy") + "', '');"
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, strPopulateDate))
            End If

            If (Not Request("StockpileShiftFrom") Is Nothing) Then
                Shift = Request("StockpileShiftFrom").Trim
            End If

            requestText = Request("StockpileId").Trim

            If (ReconcilorFunctions.IsNumeric(requestText)) Then
                StockpileId = Convert.ToInt32(ReconcilorFunctions.ParseNumeric(requestText))
            End If

            If (Not Request("BuildId") Is Nothing) AndAlso (Request("BuildId").Trim <> "") Then
                BuildId = Convert.ToInt32(Request("BuildId").Trim)
            Else
                ' For multi builds default to Build 1
                BuildId = 1
            End If

            SaveStockpileDetailsFilterValues()
        End Sub


    End Class
End Namespace
