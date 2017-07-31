Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Text

Namespace Digblocks
    Public Class DigblockHaulageList
        Inherits Core.Website.Digblocks.DigblockHaulageList

#Region "Properties"
        Private _hauledTonnesTerm As String = Reconcilor.Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Tonnes")
#End Region

        Protected Overrides Sub CreateReturnTable()

            Dim useColumns() As String = {"Haulage_Date", "Haulage_Shift", "Source", "Destination", "Haulage_Tonnes"}

            ReturnTable = New ReconcilorControls.ReconcilorTable(ListTable, useColumns)
            With ReturnTable
                .Columns.Add("Haulage_Date", New ReconcilorControls.ReconcilorTableColumn("Mined Date"))
                .Columns.Add("Haulage_Shift", New ReconcilorControls.ReconcilorTableColumn("Mined Shift"))
                .Columns.Add("Haulage_Tonnes", New ReconcilorControls.ReconcilorTableColumn(_hauledTonnesTerm))

                .DataBind()

            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            DigblockId = RequestAsString("DigblockId")
            FilterStartDate = RequestAsDateTime("HaulageDateFromText")
            FilterEndDate = RequestAsDateTime("HaulageDateToText")
            FilterNo = RequestAsInt32("FilterNo")

            Dim RequestText As String
            Dim dateFilter As DateTime

            'Date From
            RequestText = Trim(Request("HaulageDateFromText"))
            If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                FilterStartDate = dateFilter
            Else
                FilterStartDate = Date.Parse(Resources.UserSecurity.GetSetting("Digblock_Haulage_Date_From", Date.Now.ToString()))
            End If

            'Date To
            RequestText = Trim(Request("HaulageDateToText"))
            If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                FilterEndDate = dateFilter
            Else
                FilterEndDate = Date.Parse(Resources.UserSecurity.GetSetting("Digblock_Haulage_Date_To", Date.Now.ToString()))
            End If

            If (Trim(Request("HaulageDateToText")) = String.Empty And Trim(Request("HaulageDateFromText")) = String.Empty) Then
                Dim strPopulateDate As String = "setupDigblockFilterDates('" + FilterStartDate.ToString("dd-MMM-yyyy") + "', '" + FilterEndDate.ToString("dd-MMM-yyyy") + "');"
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, strPopulateDate))
            End If

        End Sub

        Protected Overrides Sub RunAjax()

            Resources.UserSecurity.SetSetting("Digblock_Haulage_Date_From", FilterStartDate.ToString("dd-MMM-yyyy"))
            Resources.UserSecurity.SetSetting("Digblock_Haulage_Date_To", FilterEndDate.ToString("dd-MMM-yyyy"))

            CreateListTable()
            CreateReturnTable()
            Controls.Add(ReturnTable)

        End Sub

    End Class
End Namespace

