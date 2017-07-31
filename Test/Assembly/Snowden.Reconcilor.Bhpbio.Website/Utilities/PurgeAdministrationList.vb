Imports Snowden.Reconcilor.Bhpbio.Database.Dtos
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class PurgeAdministrationList
        Inherits PurgeAdministrationTemplate

        Private _purgeRequests As IEnumerable(Of PurgeRequest)
        Public Property PurgeRequests() As IEnumerable(Of PurgeRequest)
            Get
                Return _purgeRequests
            End Get
            Private Set(ByVal value As IEnumerable(Of PurgeRequest))
                _purgeRequests = value
            End Set
        End Property


        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Me.PurgeRequests = Me.DalPurge.GetPurgeRequests(Nothing, Nothing, True).ToList()
            Controls.Add(CreateReturnTable())
        End Sub

        Protected Overridable Function CreateReturnTable() As ReconcilorControls.ReconcilorTable
            Dim table As DataTable = LoadRequests(AddColumns(New DataTable("PurgeAdministration")))
            Dim columns() As String = table.Columns.OfType(Of DataColumn).Select(Function(o) o.ColumnName).ToArray
            Dim returnTable As New ReconcilorControls.ReconcilorTable(table, columns)
            returnTable.DataBind()
            With returnTable
                With .Columns("RequestingUser")
                    .HeaderText = "Requesting User"
                    .Width = 125
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                End With
                With .Columns("ApprovingUser")
                    .HeaderText = "Approving User"
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                    .Width = 125
                End With
                With .Columns("Month")
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                    .Width = 80
                    .HeaderText = "Month"
                End With
                With .Columns("Status")
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                    .Width = 80
                End With
                With .Columns("Actions")
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                    .Width = 120
                    .HeaderText = ""
                End With
            End With
            Return returnTable
        End Function


        Protected Function GetColumns() As IEnumerable(Of DataColumn)
            Dim list As New List(Of DataColumn)
            list.Add(New DataColumn("Month", GetType(String)))
            list.Add(New DataColumn("Status", GetType(String)))
            list.Add(New DataColumn("RequestingUser", GetType(String)))
            list.Add(New DataColumn("ApprovingUser", GetType(String)))
            list.Add(New DataColumn("Actions", GetType(String)))
            Return list
        End Function

        Protected Overridable Function AddColumns(ByVal table As DataTable) As DataTable
            For Each column As DataColumn In GetColumns()
                table.Columns.Add(column)
            Next
            Return table
        End Function

        Protected Overridable Function LoadRequests(ByVal table As DataTable) As DataTable
            Dim currentUserId As Integer = Resources.UserSecurity.UserId.Value
            For Each item As PurgeRequest In PurgeRequests
                Dim row As DataRow = table.NewRow()
                row("Month") = item.Month.ToString("MMM yyyy")
                row("Status") = item.Status.ToString
                row("RequestingUser") = String.Format("{0} {1}", item.RequestingUser.FirstName, item.RequestingUser.LastName)
                If Not item.ApprovingUser Is Nothing Then
                    row("ApprovingUser") = String.Format("{0} {1}", item.ApprovingUser.FirstName, item.ApprovingUser.LastName)
                Else
                    row("ApprovingUser") = ""
                End If

                Dim list As New List(Of String)
                If item.IsReadyForApproval AndAlso currentUserId <> item.RequestingUser.Id Then
                    list.Add(String.Format("<a href='#' onclick='ApprovePurgeRequest({0});'>Approve</a>", item.Id))
                End If
                If item.Status = PurgeRequestState.Requested Or item.Status = PurgeRequestState.Approved Then
                    list.Add(String.Format("<a href='#' onclick='CancelPurgeRequestSubmission({0});'>Cancel</a>", item.Id))
                End If

                If (list.Count > 0) Then
                    row("Actions") = String.Join(" ", list.ToArray())
                Else
                    row("Actions") = ""
                End If

                table.Rows.Add(row)
            Next
            table.AcceptChanges()
            Return table
        End Function

    End Class
End Namespace
