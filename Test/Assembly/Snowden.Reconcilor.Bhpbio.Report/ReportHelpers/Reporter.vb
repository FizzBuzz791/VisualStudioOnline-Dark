Namespace ReportHelpers
    Public MustInherit Class Reporter
        Implements IReporter

        Public Function GetContextGroupingOrder(row As DataRow) As Integer Implements IReporter.GetContextGroupingOrder
            If row.AsString("ContextGrouping") = "Other" Then
                Return 4
            ElseIf row.AsString("ContextGrouping") = "StockpileContext" Then
                Return 5
            ElseIf row.AsString("LocationType") = "Pit" Then
                Return 1
            ElseIf row.AsString("LocationType") = "Stockpile" Then
                Return 2
            ElseIf row.AsString("LocationType") = "SampleCoverage" Then
                If row.AsString("ContextGrouping") = "Unsampled" Then
                    Return 5
                Else
                    Return 3
                End If
            Else
                Return 50
            End If
        End Function
    End Class
End Namespace