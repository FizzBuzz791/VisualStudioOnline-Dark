

Partial Public Class ShippingSource
    Partial Class NominationDataTable

        Private Sub NominationDataTable_ColumnChanging(ByVal sender As System.Object, ByVal e As System.Data.DataColumnChangeEventArgs) Handles Me.ColumnChanging
            If (e.Column.ColumnName = Me.ShippedProductColumn.ColumnName) Then
                'Add user code here
            End If

        End Sub

    End Class

    Partial Class NominationParcelDataTable

        Private Sub NominationParcelDataTable_ColumnChanging(ByVal sender As System.Object, ByVal e As System.Data.DataColumnChangeEventArgs) Handles Me.ColumnChanging
            If (e.Column.ColumnName = Me.HubColumn.ColumnName) Then
                'Add user code here
            End If

        End Sub

    End Class

End Class
