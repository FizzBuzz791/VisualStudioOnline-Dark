Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Core.WebDevelopment


Namespace Stockpiles
    Public Class StockpileDetailsTabAttribute
        Inherits Core.Website.Stockpiles.StockpileDetailsTabAttribute

        Protected Overrides Sub RunAjax()
            TonnesTerm = "Reconciled Tonnes"
            MyBase.RunAjax()
        End Sub

        Protected Overrides Sub RetrieveRequestData()

            Dim RequestText As String
            Dim dateFilter As DateTime

            Try
                RequestText = Trim(Request("StockpileId"))

                If ((Not RequestText = "") AndAlso (IsNumeric(RequestText))) Then
                    StockpileId = Convert.ToInt32(ReconcilorFunctions.ParseNumeric(RequestText))
                End If

                RequestText = Trim(Request("BuildId"))

                If ((Not RequestText = "") AndAlso (IsNumeric(RequestText))) Then
                    BuildId = Convert.ToInt32(ReconcilorFunctions.ParseNumeric(RequestText))
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

                SaveStockpileDetailsFilterValues()
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error loading stockpile activity request:\n")
            End Try
        End Sub

        Protected Overrides Sub SetupGrades()
            Const maxGradesPerRow As Integer = 3
            Const spacerWidth As Integer = 30
            Const valueWidth As Integer = 80

            Dim GradeRow As DataRow
            Dim GradeList As DataTable = DalUtility.GetGradeList(Convert.ToInt16(True))
            Dim SelectedRows() As DataRow
            Dim Row As TableRow
            Dim Cell As TableCell
            Dim i As Integer = 0
            'Formating Variables
            Dim GradeObj As Reconcilor.Core.Grade
            Dim ValueString As String

            GradesGroup.Title = "Current " & TonnesTerm & " & " & ReconcilorFunctions.GetSiteTerminologyPlural("Grade")

            'Add Tonnes to the Box
            Row = New TableRow
            i += 1

            'Add Label
            Cell = New TableCell
            Cell.Controls.Add(New LiteralControl("Tonnes: "))
            Row.Cells.Add(Cell)

            'Add The Value 
            If StockpileData.Rows(0)("Tonnes") Is DBNull.Value Then
                ValueString = ""
            Else
                ValueString = Convert.ToDouble(StockpileData.Rows(0)("Tonnes")).ToString(Application("NumericFormat").ToString)
            End If

            Cell = New TableCell
            Cell.Width = valueWidth
            Cell.HorizontalAlign = HorizontalAlign.Right
            Cell.Text = ValueString
            Row.Cells.Add(Cell)

            For Each GradeRow In GradeList.Rows
                i += 1

                If ((i - 1) Mod maxGradesPerRow = 0) Then
                    Row = New TableRow
                Else
                    Cell = New TableCell
                    Cell.Width = spacerWidth
                    Row.Cells.Add(Cell)
                End If

                'Add Label
                Cell = New TableCell
                Cell.Wrap = True

                Dim gradeName As String = GradeRow("Grade_Name").ToString()
                Cell.Controls.Add(New LiteralControl(gradeName & ": "))
                Row.Cells.Add(Cell)

                'Add The Value 
                Cell = New TableCell
                Cell.Width = valueWidth
                Cell.Wrap = True
                Cell.HorizontalAlign = HorizontalAlign.Right

                ValueString = ""
                SelectedRows = GradeData.Select("Grade_ID = '" & GradeRow("Grade_ID").ToString & "'")

                If SelectedRows.Length > 0 Then
                    GradeObj = New Grade(GradeRow, Application("NumericFormat").ToString)

                    If (Not SelectedRows(0)("Grade_Value") Is DBNull.Value) Then
                        ValueString = GradeObj.ToString(Convert.ToSingle(SelectedRows(0)("Grade_Value")), True)
                    End If
                End If

                Cell.Controls.Add(New LiteralControl(ValueString))
                Row.Cells.Add(Cell)

                If i Mod maxGradesPerRow = 0 Then
                    GradesTable.Rows.Add(Row)
                End If
            Next

            'Last row wasnt added
            If i Mod maxGradesPerRow <> 0 Then
                GradesTable.Rows.Add(Row)
            End If

            GradesGroup.Controls.Add(GradesTable)
        End Sub
 
    End Class
End Namespace

 
