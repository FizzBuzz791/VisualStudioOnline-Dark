Public Module DataTypesExtensions

    Private Const MAX_DECIMAL_PLACES As Integer = 8

    <System.Runtime.CompilerServices.Extension()> _
    Public Function GetErrorReport(ByVal dataset As DataSet) As String
        'collates the errors into a long string
        'this can then be dumped into a log file for further analysis

        Dim table As DataTable
        Dim errors As Text.StringBuilder = Nothing
        Dim row As DataRow

        'instantiate a new error string builder
        If dataset.HasErrors Then
            errors = New Text.StringBuilder()

            errors.AppendLine("-----------------------")
            errors.AppendLine("-- Data Set: " & dataset.DataSetName)
            errors.AppendLine("-----------------------")

            For Each table In dataset.Tables
                If table.HasErrors Then
                    errors.AppendLine()
                    errors.AppendLine("-----------------------")
                    errors.AppendLine("-- Table: " & table.TableName)
                    errors.AppendLine("-----------------------")

                    'collect information about each row and append
                    For Each row In table.GetErrors()
                        errors.Append("ROW::: ")
                        For Each col As DataColumn In table.Columns
                            errors.Append(col.ColumnName)
                            errors.Append(":[")
                            errors.Append(row(col.ColumnName))
                            errors.Append("] ")
                        Next
                        errors.Append(" ***ERROR: ")
                        errors.AppendLine(row.RowError)
                    Next
                End If
            Next

            Return errors.ToString()
        Else
            Return Nothing
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadStringWithDbNull(ByVal input As String) As Object
        If String.IsNullOrEmpty(input) Then
            Return DBNull.Value
        Else
            Return input
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadStringAsDoubleWithDbNull(ByVal input As String) As Object
        Dim converted As Double

        If String.IsNullOrEmpty(input) Then
            Return DBNull.Value
        Else
            If Double.TryParse(input, converted) Then
                Return Math.Round(converted, MAX_DECIMAL_PLACES)
            Else
                Return DBNull.Value
            End If
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadStringAsBoolean(ByVal input As String) As Boolean
        Dim converted As Boolean

        If String.IsNullOrEmpty(input) Then
            Return False
        Else
            If Boolean.TryParse(input, converted) Then
                Return converted
            Else
                Return False
            End If
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadStringAsInt32WithDbNull(ByVal input As String) As Object
        Dim converted As Int32

        If String.IsNullOrEmpty(input) Then
            Return DBNull.Value
        ElseIf Int32.TryParse(input, converted) Then
            Return converted
        Else
            Return DBNull.Value
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadStringAsInt32WithDbNull(ByVal input As String, ByVal nullSentinel As Int32) As Object
        Dim converted As Int32

        If String.IsNullOrEmpty(input) Then
            Return DBNull.Value
        ElseIf Int32.TryParse(input, converted) Then
            If converted = nullSentinel Then
                Return DBNull.Value
            Else
                Return converted
            End If
        Else
            Return input
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadAsDoubleWithDbNull(ByVal input As Decimal, ByVal isSpecified As Boolean) As Object
        Dim parsed As Double

        If isSpecified Then
            If Double.TryParse(input.ToString, parsed) Then
                ' prevent excessive decimal places causing SQL overflow errors, round to eight places maximum
                Return Math.Round(parsed, MAX_DECIMAL_PLACES)
            Else
                Return DBNull.Value
            End If
        Else
            Return DBNull.Value
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadAsDoubleWithDefault(ByVal input As Decimal, ByVal isSpecified As Boolean, ByVal defaultValue As Double) As Object
        If isSpecified Then
            ' prevent excessive decimal places causing SQL overflow errors, round to eight places maximum
            Return Math.Round(Convert.ToDouble(input), MAX_DECIMAL_PLACES)
        Else
            Return defaultValue
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadAsDoubleWithDbNull(ByVal input As Decimal, ByVal isSpecified As Boolean, ByVal nullSentinel As Decimal) As Object
        If isSpecified Then
            If input = nullSentinel Then
                Return DBNull.Value
            Else
                ' prevent excessive decimal places causing SQL overflow errors, round to eight places maximum
                Return Math.Round(Convert.ToDouble(input), MAX_DECIMAL_PLACES)
            End If
        Else
            Return DBNull.Value
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadAsDateTimeWithDbNull(ByVal input As Date, ByVal isSpecified As Boolean) As Object
        If isSpecified Then
            Return input.ToLocalTime
        Else
            Return DBNull.Value
        End If
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadAsDateWithDbNull(ByVal input As Date, ByVal isSpecified As Boolean) As Object
        If isSpecified Then
            ' Convert to local time before extracting the date to be consistent with ReadAsDateTimeWithDbNull behaviour
            Return input.ToLocalTime.Date
        Else
            Return DBNull.Value
        End If
    End Function

End Module
