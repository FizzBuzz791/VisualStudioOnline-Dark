Partial Class StockpileAdjustmentSource
    Partial Class StockpileAdjustmentDataTable

        Private Sub StockpileAdjustmentDataTable_ColumnChanging(ByVal sender As System.Object, ByVal e As System.Data.DataColumnChangeEventArgs) Handles Me.ColumnChanging
            If (e.Column.ColumnName = Me.MineColumn.ColumnName) Then
                'Add user code here
            End If

        End Sub

    End Class

End Class
