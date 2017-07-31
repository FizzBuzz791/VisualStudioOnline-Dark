Partial Public Class ProductionSource
    Partial Class TransactionGradeDataTable

        Private Sub TransactionGradeDataTable_ColumnChanging(ByVal sender As System.Object, ByVal e As System.Data.DataColumnChangeEventArgs) Handles Me.ColumnChanging
            If (e.Column.ColumnName = Me.SourceColumn.ColumnName) Then
                'Add user code here
            End If

        End Sub

    End Class

End Class
