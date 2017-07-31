Namespace Data

    Public NotInheritable Class BlockModels
        Private Sub New()
        End Sub

        Public Shared Function FormatBlockModelsTable(ByVal blockModelsTable As DataTable) As DataTable
            Dim blockModelRows As DataRow()
            Dim formattedDataTable As DataTable

            formattedDataTable = blockModelsTable.Copy()
            formattedDataTable.Clear()

            blockModelRows = blockModelsTable.Select("", "Block_Model_Type_Id DESC")

            For Each dRow As DataRow In blockModelRows
                formattedDataTable.ImportRow(FormatBlockModelText(dRow))
            Next

            Return formattedDataTable

        End Function

        Private Shared Function FormatBlockModelText(ByVal rowToFormat As DataRow) As DataRow

            Dim descriptionValue As String = rowToFormat.ItemArray().GetValue(4).ToString()
            Dim formattedRow As DataRow = rowToFormat
            Dim updatedDescription As String = Nothing

            updatedDescription = FormatBlockModelDescription(descriptionValue)

            If Not updatedDescription Is Nothing Then
                formattedRow.Item(4) = updatedDescription
            End If

            Return formattedRow

        End Function

        Public Shared Function FormatBlockModelDescription(ByVal blockModelName As String) As String
            Dim result = blockModelName

            Select Case blockModelName
                Case "Grade Control Model"
                    result = "Grade Control"
                Case "Geological Model"
                    result = "Geology Model"
                Case "Short Term Geology"
                    result = Calc.ModelShortTermGeology.CalculationDescription
            End Select

            Return result
        End Function

    End Class

End Namespace

