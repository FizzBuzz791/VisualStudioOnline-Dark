Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.Database

Namespace Analysis
    Public Class RecalcLogicList
        Inherits Snowden.Reconcilor.Core.Website.Analysis.RecalcLogicList

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            DalRecalc = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalRecalc(Resources.Connection)
        End Sub
        Protected Overrides Function ValidateData() As String
            Dim retStr As New Text.StringBuilder()
            Return retStr.ToString
        End Function

        Protected Overrides Sub ProcessData()

            Dim recalcLogicData As DataTable
            Dim useColumns As String() = {"Expand", "Date", "Shift", "Transaction_Type", "Original_Source", _
             "Original_Destination", "Orig_Tonnes", "New_Tonnes", "View"}
            Dim colExpression As Text.StringBuilder
            Dim imgStr As String

            recalcLogicData = DirectCast(DalRecalc, Bhpbio.Database.SqlDal.SqlDalRecalc).GetRecalcLogicHistoryTransactionLevel0(StartDate, StartShift, EndDate, EndShift, _
            Source, Destination, TransactionType, Convert.ToInt16(IncludeGrades), SourceType)

            'Build expression for expand column
            colExpression = New Text.StringBuilder("")

            imgStr = _
             "'<img src=""%IMAGELOCATION%"" id=""Image_%TRANSACTIONID%"" " & _
             "onclick=""ToggleRecalcLogicNode(''Node_%TRANSACTIONID%'', 1, ''%RECORDID%'', ''%TRANSACTIONTYPE%'', %INCLUDEGRADES%);"" />' " & _
             " + Action "

            imgStr = imgStr.Replace("%IMAGELOCATION%", "../images/plus.png")
            imgStr = imgStr.Replace("%RECORDID%", "' + Record_Id + '")
            imgStr = imgStr.Replace("%TRANSACTIONID%", "' + Transaction_List_Id + '")
            imgStr = imgStr.Replace("%TRANSACTIONTYPE%", "' + Transaction_Type + '")
            imgStr = imgStr.Replace("%INCLUDEGRADES%", IncludeGrades.ToString().ToLower())

            With colExpression
                .Append("IIF(Record_Id Is Null, Action, ")
                .Append(imgStr)
                .Append(")")
            End With

            'Add additional columns
            recalcLogicData.Columns.Add(New DataColumn("Expand", GetType(String), colExpression.ToString()))
            recalcLogicData.Columns.Add(New DataColumn("View", GetType(String), ""))
            recalcLogicData.Columns.Add(New DataColumn("NodeId", GetType(String), "'Node_' + Transaction_List_Id")) 'Column for RowId

            RecalcLogicTree = New ReconcilorControls.ReconcilorTable(recalcLogicData, useColumns)
            With RecalcLogicTree
                .ID = "RecalcLogicTree"
                .RowIdColumn = "NodeId"
                .IsSortable = False
                .CanExportCsv = False

                .Columns.Add("Expand", New ReconcilorControls.ReconcilorTableColumn("", 190))
                .Columns("Expand").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Left

                .Columns.Add("Date", New ReconcilorControls.ReconcilorTableColumn("Date"))
                .Columns("Date").DateTimeFormat = Application("DateFormat").ToString

                .DataBind()
            End With

            Controls.Add(RecalcLogicTree)
        End Sub

    End Class
End Namespace

