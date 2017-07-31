Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Threading
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.Database.SqlDal

Namespace Approval
    Public Class ApprovalOtherListNode
        Inherits AnalysisAjaxTemplate

        Private dalUtility As IUtility
        Private _dalPurge As Database.DalBaseObjects.IPurge
        Private nodeLevel As Int32
        Private nodeRowId As String
        Private locationId As Int32
        Private approvalMonth As DateTime

        Public Property DalPurge() As Database.DalBaseObjects.IPurge
            Get
                Return _dalPurge
            End Get
            Set(ByVal value As Database.DalBaseObjects.IPurge)
                _dalPurge = value
            End Set
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Try
                nodeRowId = RequestAsString ("NodeRowId")
                nodeLevel = RequestAsInt32 ("NodeLevel")
                locationId = RequestAsInt32 ("LocationId")
                approvalMonth = RequestAsDateTime ("ApprovalMonth")
            Catch ex As Exception
                JavaScriptAlert (ex.Message, "Error retrieving location picker node request:\n")
            End Try
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                ProcessData()
            Catch ea As ThreadAbortException
                Return
            Catch ex As Exception
                JavaScriptAlert (ex.Message, "Error retrieving location picker tree:\n")
            End Try
        End Sub


        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Dim nodeData As DataTable
            Dim data As DataRow
            Dim returnTable As New HtmlTableTag
            Dim reportSession As New ReportSession(Resources.ConnectionString)
            reportSession.Context = ReportContext.ApprovalListing

            Dim userInterfaceColumns = ReconcilorTable.GetUserInterfaceColumns(dalUtility, "Approval_Other")
            Dim columns As List(Of String) = userInterfaceColumns.Select(Function(a) a.Key).ToList()

            ' Find out whether the month is purged
            Dim isMonthPurged As Boolean = _dalPurge.IsMonthPurged(approvalMonth)

            nodeData = ApprovalOtherListData.CreateApprovalDigblockList(reportSession, _
                                                                         approvalMonth, locationId, True, nodeRowId, _
                                                                         nodeLevel, Resources.UserSecurity.UserId.Value, _
                                                                         isMonthPurged)

            returnTable.ID = "StageTable"

            ' If there are no valid data for expanded row, Feed this back to user in a new row.
            If nodeData.Rows.Count = 0 Then
                data = nodeData.NewRow()
                data ("Description") = "<font color=red>No valid data under this location</font>"
                data ("nodeRowId") = String.Format ("{0}_NoData", nodeRowId)
                nodeData.Rows.Add (data)
            End If

            For Each data In nodeData.Rows
                AddNodeTableRow (returnTable, data, columns)
            Next

            Controls.Add (returnTable)

            'Add call to append nodes
            Controls.Add (New HtmlScriptTag (ScriptType.TextJavaScript, _
                                             ScriptLanguage.JavaScript, "", "AppendApprovalNodes('" & nodeRowId & "');"))
        End Sub

        Protected Overridable Sub AddNodeTableRow(ByVal returnTable As HtmlTableTag, _
                                                   ByVal data As DataRow, ByVal columns As ICollection(Of String))
            Dim tonnesFormat As String = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions.SetNumericFormatDecimalPlaces(2)
            Dim descriptionTable As Table
            Dim indentedRow As TableRow
            Dim indentedCell As TableCell
            Dim literal As LiteralControl
            Dim callback As ItemCallBack = AddressOf ApprovalOtherListData.OtherDisplayTable_ItemCallback

            descriptionTable = GetIndentedNodeTable(data, "MaterialName", nodeLevel, callback)
            indentedRow = TryCast(descriptionTable.Controls(0), TableRow)
            indentedCell = TryCast(indentedRow.Controls(indentedRow.Controls.Count - 1), TableCell)
            literal = TryCast(indentedCell.Controls(0), LiteralControl)
            returnTable.AddCellInNewRow().Controls.Add(descriptionTable)

            Dim columnsUpper = columns.Select(Function(a) a.ToUpper).ToList

            For Each column In columns
                If (New String() {"MaterialName", "ApprovedCheck", "SignOff", "Signoff"}).Contains(column) Then Continue For
                ProcessRow(returnTable, data, column, tonnesFormat, ReconcilorTableColumn.Alignment.Right, callback, columnsUpper)
            Next

            ProcessRow(returnTable, data, "ApprovedCheck", "", ReconcilorTableColumn.Alignment.Left, callback, columnsUpper) ' ApprovedCheck
            ProcessRow(returnTable, data, "SignOff", "", ReconcilorTableColumn.Alignment.Left, callback, columnsUpper) ' SignOff

            returnTable.CurrentRow.ID = data("nodeRowId").ToString()
        End Sub


        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If dalUtility Is Nothing Then
                dalUtility = New SqlDalUtility (Resources.Connection)
            End If

            If (DalPurge Is Nothing) Then
                DalPurge = New Database.SqlDal.SqlDalPurge(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace
