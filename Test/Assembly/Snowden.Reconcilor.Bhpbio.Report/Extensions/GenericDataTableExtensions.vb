Imports System.Runtime.CompilerServices

Namespace Extensions
    ' this contains extensions methods for the datatables that could be used with any DataTable. This should maybe be moved
    ' to somewhere in the solution where anything can access it.
    Public Module GenericDataTableExtensions

        ' converts a filtered set of rows into their own datatable
        <Extension>
        Public Function ToDataTable(rows As IEnumerable(Of DataRow)) As DataTable
            If rows.Count = 0 Then
                Return Nothing
            End If

            Dim table = rows.First.Table
            Dim result = table.Clone()

            For Each row In rows
                result.Rows.Add(row.ItemArray)
            Next

            Return result
        End Function

        <Extension>
        Public Function DeleteRows(ByRef table As DataTable, ByRef rows As IEnumerable(Of DataRow)) As DataTable

            For Each row In rows.ToArray
                row.Delete()
            Next

            table.AcceptChanges()

            Return table
        End Function

        <Extension>
        Public Function DeleteRows(ByRef table As DataTable, ByRef rows As List(Of DataRow)) As DataTable
            Return table.DeleteRows(rows.AsEnumerable)
        End Function

        <Extension>
        Public Sub DeleteRows(ByRef rows As IEnumerable(Of DataRow))
            If rows Is Nothing Or rows.Count = 0 Then
                Return
            End If

            Dim table = rows.FirstOrDefault.Table

            ' need to convert to a concrete list to get a copy of the rows, if we
            ' have only got passed a query or something
            Dim rowsToDelete = rows.ToList()
            table.DeleteRows(rowsToDelete)
        End Sub

        ' sorts the table by the columnName provided, and (unlike most of the other methods)
        ' returns a NEW table sorted by that column
        <Extension>
        Public Function SortBy(ByRef table As DataTable, columnName As String) As DataTable
            If Not table.Columns.Contains(columnName) Then
                Throw New Exception($"Cannot sort table by '{columnName}' - column does not exist")
            End If

            table.DefaultView.Sort = columnName
            Return table.DefaultView.ToTable()
        End Function

        <Extension>
        Public Function SetField(ByRef rows As IEnumerable(Of DataRow), columnName As String, predicate As Func(Of DataRow, Object)) As IEnumerable(Of DataRow)

            If predicate Is Nothing Then
                Return rows.SetFieldValue(columnName, Nothing)
            End If

            For Each row In rows
                Dim result = predicate(row)
                If result Is Nothing Then
                    row(columnName) = DBNull.Value
                Else
                    row(columnName) = result
                End If

            Next

            Return rows
        End Function
        <Extension>
        Public Function SetFieldValue(ByRef rows As IEnumerable(Of DataRow), columnName As String, value As Object) As IEnumerable(Of DataRow)
            For Each row In rows
                If value Is Nothing Then
                    row(columnName) = DBNull.Value
                Else
                    row(columnName) = value
                End If
            Next

            Return rows
        End Function

        <Extension>
        Public Function SetField(ByRef rows As IEnumerable(Of DataRow), columnName As String, value As Object) As IEnumerable(Of DataRow)
            Return rows.SetFieldValue(columnName, value)
        End Function

        <Extension>
        Public Function SetFieldIfNull(ByRef rows As IEnumerable(Of DataRow), columnName As String, value As Object) As IEnumerable(Of DataRow)
            Return rows.Where(Function(r) r.IsNull(columnName)).SetField(columnName, value)
        End Function

        <Extension>
        Public Sub SetNull(ByRef row As DataRow, columnName As String)
            If row.Table.Columns.Contains(columnName) Then
                row(columnName) = DBNull.Value
            End If
        End Sub

        ' Makes a copy of the current row. We need this in order to add the offset rows etc
        <Extension>
        Public Function Copy(ByRef row As DataRow) As DataRow
            Dim destRow = row.Table.NewRow()
            destRow.ItemArray = CType(row.ItemArray.Clone(), Object())
            Return destRow
        End Function

        <Extension>
        Public Function HasColumn(ByRef row As DataRow, columnName As String) As Boolean
            Return row.Table IsNot Nothing AndAlso row.Table.Columns.Contains(columnName)
        End Function

        <Extension>
        Public Function HasValue(ByRef row As DataRow, columnName As String) As Boolean
            Return Not IsDBNull(row(columnName))
        End Function

        <Extension>
        Public Function AsDblN(ByRef row As DataRow, columnName As String) As Double?
            If IsDBNull(row(columnName)) Then
                Return Nothing
            Else
                Return CType(row(columnName), Double).RemoveNaNs()
            End If

        End Function


        <Extension>
        Public Function RemoveNaNs(n As Double) As Double
            If Double.IsNaN(n) Then
                Return 0.0
            Else
                Return n
            End If
        End Function

        ''' <summary>
        ''' Get the row value as a Double.
        ''' </summary>
        ''' <param name="row"></param>
        ''' <param name="columnName"></param>
        ''' <returns>Row value as a Double. WARNING: Will return 0 if row value is DBNull or NaN.</returns>
        <Extension>
        Public Function AsDbl(ByRef row As DataRow, columnName As String) As Double
            If IsDBNull(row(columnName)) Then
                Return Nothing ' VB.Net sucks, this shouldn't be possible as the return type isn't nullable. This actually returns 0 in this scenario.
            Else
                Return CType(row(columnName), Double).RemoveNaNs()
            End If
        End Function

        <Extension>
        Public Function AsDate(ByRef row As DataRow, columnName As String) As Date
            If IsDBNull(row(columnName)) Then
                Return DateTime.MinValue
            Else
                Return CType(row(columnName), Date)
            End If
        End Function

        <Extension>
        Public Function AsBool(ByRef row As DataRow, columnName As String) As Boolean
            If IsDBNull(row(columnName)) Then
                Return False
            Else
                Return CType(row(columnName), Boolean)
            End If
        End Function

        ''' <summary>
        ''' Get the row value as an Integer.
        ''' </summary>
        ''' <param name="row"></param>
        ''' <param name="columnName"></param>
        ''' <returns>Row value as an integer. WARNING: Will return 0 if row value is DBNull.</returns>
        <Extension>
        Public Function AsInt(ByRef row As DataRow, columnName As String) As Integer
            If IsDBNull(row(columnName)) Then
                Return Nothing ' VB.Net sucks, this shouldn't be possible as the return type isn't nullable. This actually returns 0 in this scenario.
            Else
                Return CType(row(columnName), Integer)
            End If
        End Function

        <Extension>
        Public Function AsIntN(ByRef row As DataRow, columnName As String) As Integer?
            If IsDBNull(row(columnName)) Then
                Return Nothing
            Else
                Return CType(row(columnName), Integer)
            End If
        End Function

        <Extension>
        Public Function AsString(ByRef row As DataRow, columnName As String) As String
            If IsDBNull(row(columnName)) Then
                Return Nothing
            Else
                Return CType(row(columnName), String)
            End If
        End Function
    End Module
End NameSpace