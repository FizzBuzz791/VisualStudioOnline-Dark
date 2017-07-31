Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Stockpiles

    Public Class StockpileDetailsTabActivity
        Inherits Core.Website.Stockpiles.StockpileDetailsTabActivity

        Protected Overrides Sub RunAjax()
            TonnesTerm = "Reconciled Tonnes"
            MyBase.RunAjax()
        End Sub

        Protected Overrides Sub RetrieveRequestData()

            Dim RequestText As String
            Dim dateFilter As DateTime

            Try
                If (Not Request("ActivityType") Is Nothing) AndAlso (Request("ActivityType").Trim <> "") Then
                    ActivityType = Convert.ToInt16(Request("ActivityType").Trim)
                End If

                If (Not Request("StockpileId") Is Nothing) AndAlso (Request("StockpileId").Trim <> "") Then
                    StockpileId = Convert.ToInt32(Request("StockpileId").Trim)
                End If

                If (Not Request("BuildId") Is Nothing) AndAlso (Request("BuildId").Trim <> "") Then
                    BuildId = Convert.ToInt32(Request("BuildId").Trim)
                End If

                'Date From
                RequestText = Trim(Request("StockpileDateFromText"))
                If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                    DateFrom = dateFilter
                Else
                    DateFrom = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_From", Date.Now.ToString()))
                End If

                'Date To
                RequestText = Trim(Request("StockpileDateToText"))
                If RequestText <> "" AndAlso DateTime.TryParse(RequestText, dateFilter) Then
                    DateTo = dateFilter
                Else
                    DateTo = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_To", Date.Now.ToString()))
                End If

                If (Trim(Request("StockpileDateFromText")) = String.Empty And Trim(Request("StockpileDateToText")) = String.Empty) Then
                    Dim strPopulateDate As String = "SetupStockpileDetailsFilterDates('" + DateFrom.ToString("dd-MMM-yyyy") + "', '" + DateTo.ToString("dd-MMM-yyyy") + "');"
                    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, strPopulateDate))
                End If
                If (Not Request("GroupActivity") Is Nothing) AndAlso (Request("GroupActivity").Trim.ToLower = "on") Then
                    GroupActivity = True
                End If

                SaveStockpileDetailsFilterValues()
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error loading stockpile activity request:\n")
            End Try
        End Sub

    End Class
End Namespace
