Imports System.Runtime.CompilerServices
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Extensions
    Module CalculationResultRecordExtensions
        <Extension>
        Public Function Sum(calculationResults As IEnumerable(Of CalculationResultRecord)) As CalculationResultRecord
            Dim i = 0
            Dim totalResult As CalculationResultRecord = Nothing

            For Each row In calculationResults
                If Not row.Tonnes.HasValue Then Continue For

                If i = 0 Then
                    totalResult = calculationResults.First.Clone
                Else
                    totalResult += row
                End If

                i += 1
            Next

            Return totalResult
        End Function
    End Module
End NameSpace