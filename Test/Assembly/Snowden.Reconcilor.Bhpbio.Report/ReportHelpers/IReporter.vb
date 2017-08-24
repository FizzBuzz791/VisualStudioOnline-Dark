Namespace ReportHelpers
    Public Interface IReporter
        Function GetContextGroupingOrder(row As DataRow) As Integer
        Sub AddContextRowAsNonFactorRow(dataRow As DataRow, ByRef masterTable As DataTable, presentationColor As String,
                                        tonnes As Double, contextGrouping As String, locationType As String,
                                        contextCategory As String, contextGroupingLabel As String, locationName As String)
    End Interface
End Namespace