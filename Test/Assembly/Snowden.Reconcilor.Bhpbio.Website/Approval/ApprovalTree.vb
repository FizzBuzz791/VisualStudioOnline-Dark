Imports System.Data
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core

Namespace Approval

    Delegate Function ItemCallBack(ByVal textData As String, _
         ByVal columnName As String, ByVal row As DataRow) As String

    Module ApprovalTree

        Public Sub ProcessRowGrade(ByVal table As HtmlTableTag, ByVal row As DataRow, ByVal columnName As String, _
         ByVal grades As Generic.Dictionary(Of String, Grade), ByVal callback As ItemCallBack, _
         ByVal tableColumns As ICollection(Of String))
            Dim format As String = ReconcilorFunctions.SetNumericFormatDecimalPlaces(grades(columnName).Precision)
            ProcessRow(table, row, columnName, format, ReconcilorTableColumn.Alignment.Right, callback, tableColumns)
        End Sub

        Public Sub ProcessRow(ByVal table As HtmlTableTag, ByVal row As DataRow,
         ByVal text As String, ByVal alignment As ReconcilorTableColumn.Alignment)
            Dim literal As New LiteralControl(text)
            table.AddCell.Controls.Add(literal)
        End Sub

        Public Sub ProcessRow(ByVal table As HtmlTableTag, ByVal row As DataRow, _
         ByVal columnName As String, ByVal format As String, ByVal alignment As ReconcilorTableColumn.Alignment, _
         ByVal callback As ItemCallBack, ByVal tableColumns As ICollection(Of String))
            If (tableColumns.Contains(columnName.ToUpper())) Then
                ' Only add the column if the table has this column enabled in user interface listing.
                table.AddCell.Controls.Add(FormatDataColumn(row, columnName, format, alignment, callback))
            End If
        End Sub

        ' Extracted from ReconcilorFunctionContainer
        Public Function FormatDataColumn(ByVal row As DataRow, ByVal columnName As String, _
         ByVal formatString As String, ByVal alignment As ReconcilorTableColumn.Alignment, _
         ByVal callback As ItemCallBack) As Web.UI.Control
            Dim textData As String
            Dim column As DataColumn
            Dim data As Object

            If row Is Nothing Then
                Throw New ArgumentNullException("row", "Row parameter pass to format data column was null.")
            End If

            column = row.Table.Columns(columnName)
            data = row(columnName)

            If (column.DataType Is GetType(DateTime)) AndAlso (Not data Is DBNull.Value) Then
                textData = Convert.ToDateTime(data).ToString(formatString)
            ElseIf ("int32, int16, int64, single, double").Contains(column.DataType.Name.ToLower) _
             AndAlso (Not data Is DBNull.Value) Then 'If its numeric
                textData = Convert.ToDouble(data).ToString(formatString).Trim()
            Else
                textData = data.ToString
            End If

            Return FormatText(row, columnName, textData, alignment, callback)
        End Function


        Public Function FormatText(ByVal row As DataRow, ByVal columnName As String, _
         ByVal innerHTML As String, ByVal alignment As ReconcilorTableColumn.Alignment, _
         ByVal callback As ItemCallBack) As Web.UI.Control
            Dim textData As String
            Dim textDatapadding As New Text.StringBuilder("")
            Const columnLeadingSpaces As Integer = 3 'From ReconcilorTable

            'textData = ApprovalOtherListData.OtherDisplayTable_ItemCallback(innerHTML, columnName, row)
            textData = callback(innerHTML, columnName, row)

            For i As Integer = 1 To columnLeadingSpaces
                textDatapadding.Append("&nbsp;")
            Next

            Select Case alignment
                Case ReconcilorTableColumn.Alignment.Left
                    textData = textDatapadding.ToString() & textData
                Case ReconcilorTableColumn.Alignment.Right
                    textData &= textDatapadding.ToString()
            End Select

            Return New LiteralControl(textData)
        End Function

        ' Extracted from ReconcilorFunctionContainer
        Public Function GetIndentedNodeTable(ByVal darow As DataRow, _
         ByVal columnName As String, ByVal currentNodeLevel As Integer, ByVal callback As ItemCallBack) As Table
            Dim returnTable As New Table
            Dim row As TableRow
            Dim cell As TableCell
            Dim expandData As Object = darow(columnName)

            If expandData Is Nothing Then
                Throw New ArgumentNullException("expandData", "Expansion data for the node passed in was null.")
            End If

            row = New TableRow()

            'Indent for each node level
            For i As Integer = 1 To currentNodeLevel
                cell = New TableCell
                cell.Controls.Add(New LiteralControl("&nbsp;"))
                cell.Width = Unit.Pixel(20)
                row.Cells.Add(cell)
            Next

            'Use the column expression column to decide what is actually in this cell
            cell = New TableCell
            cell.Controls.Add(New LiteralControl(callback(expandData.ToString, columnName, darow)))
            If Not IsDBNull(darow("CalcBlockMid")) Then
                cell.Style.Add("border-left", "buttonshadow 1px solid")
            End If
            If Not IsDBNull(darow("CalcBlockTop")) Then
                cell.Style.Add("border-top", "buttonshadow 1px solid")
            End If
            row.Cells.Add(cell)

            returnTable.Rows.Add(row)

            Return returnTable
        End Function



    End Module
End Namespace
