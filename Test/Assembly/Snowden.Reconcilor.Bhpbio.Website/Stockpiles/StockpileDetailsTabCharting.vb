Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Stockpiles

    Public Class StockpileDetailsTabCharting
        Inherits Core.Website.Stockpiles.StockpileDetailsTabCharting

        Protected Overrides Sub RunAjax()

            TonnesTerm = "Reconciled Tonnes"
            RetrieveGradeFormats()

            If LeftAxisOptions.Count = 0 And RightAxisOptions.Count = 0 Then
                Dim warningDiv As New Tags.HtmlDivTag("warningDiv")

                warningDiv.Controls.Add(New Tags.HtmlBRTag)
                warningDiv.Controls.Add(New Web.UI.LiteralControl("Please select at least one attribute to render on the graph."))
                warningDiv.Style("Width") = "440px"
                Controls.Add(warningDiv)
            Else
                CreateChart()

                If Print Then
                    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "window.print();"))
                End If
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()

            Dim RequestText, Key As String

            Suffix = Trim(Request("Suffix"))


            RequestText = Trim(Request("StockpileId" & Suffix))

            If ((Not RequestText = "") AndAlso (IsNumeric(RequestText))) Then
                StockpileId = Convert.ToInt32(ReconcilorFunctions.ParseNumeric(RequestText))
            End If

            RequestText = Trim(Request("BuildId" & Suffix))

            If ((Not RequestText = "") AndAlso (IsNumeric(RequestText))) Then
                BuildId = Convert.ToInt32(ReconcilorFunctions.ParseNumeric(RequestText))
            End If


            RequestText = Trim(Request("StockpileDateFrom" & Suffix & "Text"))

            If ((Not RequestText = "") AndAlso (IsDate(RequestText))) Then
                DateFrom = Convert.ToDateTime(RequestText)
            Else
                DateFrom = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_From", Date.Now.ToString()))
            End If

            RequestText = Trim(Request("StockpileDateTo" & Suffix & "Text"))

            If ((Not RequestText = "") AndAlso (IsDate(RequestText))) Then
                DateTo = Convert.ToDateTime(RequestText)
            Else
                DateTo = Date.Parse(Resources.UserSecurity.GetSetting("Stockpile_Details_Filter_Date_To", Date.Now.ToString()))
            End If

            If (Trim(Request("StockpileDateFrom" & Suffix & "Text")) = String.Empty And Trim(Request("StockpileDateTo" & Suffix & "Text")) = String.Empty) Then
                Dim strPopulateDate As String = "SetupStockpileDetailsFilterDates('" + DateFrom.ToString("dd-MMM-yyyy") + "', '" + DateTo.ToString("dd-MMM-yyyy") + "');"
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, strPopulateDate))
            End If

            For Each Key In Request.Form.Keys
                If ((Key.StartsWith("left_")) AndAlso (Request(Key) = "on")) Then
                    LeftAxisOptions.Add(Key.Replace("left_", "").Replace("|", " "))
                ElseIf ((Key.StartsWith("right_")) AndAlso (Request(Key) = "on")) Then
                    RightAxisOptions.Add(Key.Replace("right_", "").Replace("|", " "))
                End If
            Next

            If LCase(Trim(Request("Print"))) = "true" Then
                Print = True
            End If

            SaveStockpileDetailsFilterValues()
        End Sub



    End Class
End Namespace

