Imports System.Globalization
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Converters
Imports Newtonsoft.Json.Serialization
Imports Newtonsoft.Json.Utilities

' Use these versions as Reconcilor won't work if there is a dataset with a table(s) with no data
' This is due to the .Select(filterQuery) logic throwing an exception when a rehydrated table
' has no columns due to being empty using the out of the box Newtonsoft.JSON implementation.


#Region "License"

' Copyright (c) 2007 James Newton-King
'
' Permission Is hereby granted, free of charge, to any person
' obtaining a copy of this software And associated documentation
' files (the "Software"), to deal in the Software without
' restriction, including without limitation the rights to use,
' copy, modify, merge, publish, distribute, sublicense, And/Or sell
' copies of the Software, And to permit persons to whom the
' Software Is furnished to do so, subject to the following
' conditions:
'
' The above copyright notice And this permission notice shall be
' included in all copies Or substantial portions of the Software.
'
' THE SOFTWARE Is PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
' EXPRESS Or IMPLIED, INCLUDING BUT Not LIMITED TO THE WARRANTIES
' OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE And
' NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS Or COPYRIGHT
' HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES Or OTHER LIABILITY,
' WHETHER IN AN ACTION OF CONTRACT, TORT Or OTHERWISE, ARISING
' FROM, OUT OF Or IN CONNECTION WITH THE SOFTWARE Or THE USE Or
' OTHER DEALINGS IN THE SOFTWARE.
#End Region

Namespace SqlDal.JSONConverters
    Public Class BhpbioDataTableConverter
        Inherits DataTableConverter

        Public Const COLUMNS = "Columns"
        Public Const ROWS = "Rows"
        Public Const NAME = "Name"
        Public Const TYPE = "Type"

        ''' <summary>
        ''' Writes the JSON representation of the object.
        ''' </summary>
        ''' <param name="writer">The <see cref="JsonWriter"/> to write to.</param>
        ''' <param name="value">>The value.</param>
        ''' <param name="serializer">The calling serializer.</param>
        Public Overrides Sub WriteJson(writer As JsonWriter, value As Object, serializer As JsonSerializer)
            Dim table As DataTable = CType(value, DataTable)
            Dim Resolver As DefaultContractResolver = CType(serializer.ContractResolver, DefaultContractResolver)
            Dim tableName As String = Nothing

            Dim converter As DataTableConverter = New DataTableConverter()

            If (Resolver IsNot Nothing) Then
                tableName = Resolver.GetResolvedPropertyName(table.TableName)
            Else
                tableName = table.TableName
            End If
            writer.WriteStartObject()

            writer.WritePropertyName(COLUMNS)
            writer.WriteStartArray()
            For Each col As DataColumn In table.Columns
                writer.WriteStartObject()
                Dim columnName As String = Nothing
                If (Resolver IsNot Nothing) Then
                    columnName = Resolver.GetResolvedPropertyName(col.ColumnName)
                Else
                    columnName = col.ColumnName
                End If
                writer.WritePropertyName(NAME)
                serializer.Serialize(writer, columnName)
                writer.WritePropertyName(TYPE)
                serializer.Serialize(writer, col.DataType)
                writer.WriteEnd()

            Next
            writer.WriteEndArray()
            writer.WritePropertyName(ROWS)
            writer.WriteStartArray()

            For Each row As DataRow In table.Rows
                writer.WriteStartObject()

                For Each col As DataColumn In row.Table.Columns
                    Dim columnValue As Object = row(col)

                    If (serializer.NullValueHandling.Equals(NullValueHandling.Ignore) And
                        (columnValue Is Nothing Or columnValue.Equals(DBNull.Value))) Then
                        Continue For
                    End If
                    Dim propertyName As String = Nothing
                    If (Resolver IsNot Nothing) Then
                        propertyName = Resolver.GetResolvedPropertyName(col.ColumnName)
                    Else
                        propertyName = col.ColumnName
                    End If
                    writer.WritePropertyName(propertyName)
                    serializer.Serialize(writer, columnValue)
                Next

                writer.WriteEndObject()
            Next
            writer.WriteEndArray()

            writer.WriteEndObject()


        End Sub

        Public Overrides Function ReadJson(reader As JsonReader, objectType As Type, existingValue As Object, serializer As JsonSerializer) As Object
            If (reader.TokenType.Equals(JsonToken.Null)) Then
                Return Nothing
            End If

            Dim dt As DataTable = CType(existingValue, DataTable)

            If (dt Is Nothing) Then
                ' handle typed datasets
                If (objectType.Equals(GetType(DataTable))) Then
                    dt = New DataTable()
                Else
                    dt = CType(Activator.CreateInstance(objectType), DataTable)
                End If
            End If

            ' DataTable Is inside a DataSet
            ' populate the name from the property name
            If (reader.TokenType.Equals(JsonToken.PropertyName)) Then

                dt.TableName = CType(reader.Value, String)
                reader.Read()

                If (reader.TokenType.Equals(JsonToken.Null)) Then
                    Return dt
                End If
            End If

            If (Not reader.TokenType.Equals(JsonToken.StartObject)) Then
                Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected StartObject, got {0}.", reader.TokenType))
            End If
            reader.Read()

            If (Not reader.TokenType.Equals(JsonToken.PropertyName)) Then
                Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected PropertyName, got {0}.", reader.TokenType))
            End If
            If (reader.Value.Equals(COLUMNS)) Then
                reader.Read()
                If (Not reader.TokenType.Equals(JsonToken.StartArray)) Then
                    Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected StartArray, got {0}.", reader.TokenType))
                End If
                reader.Read()

                While (Not reader.TokenType.Equals(JsonToken.EndArray))
                    Dim ColName As String
                    Dim colType As Type
                    If (Not reader.TokenType.Equals(JsonToken.StartObject)) Then
                        Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected StartObject, got {0}.", reader.TokenType))
                    End If

                    reader.Read()
                    If (Not reader.TokenType.Equals(JsonToken.PropertyName)) Then
                        Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected PropertyName, got {0}.", reader.TokenType))
                    End If

                    reader.Read()
                    If (reader.TokenType.Equals(JsonToken.String)) Then
                        ColName = reader.Value.ToString()
                    Else
                        Throw New Exception("Didn't find column name")
                    End If

                    reader.Read()
                    If (Not reader.TokenType.Equals(JsonToken.PropertyName)) Then
                        Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected PropertyName, got {0}.", reader.TokenType))
                    End If

                    reader.Read()
                    If (reader.TokenType.Equals(JsonToken.String)) Then
                        colType = System.Type.GetType(reader.Value.ToString)
                    Else
                        Throw New Exception("Didn't find column name")
                    End If
                    reader.Read()
                    While (Not reader.TokenType.Equals(JsonToken.EndObject))
                        reader.Read()
                    End While

                    Dim dc As DataColumn = New DataColumn(ColName, colType)

                    dt.Columns.Add(dc)
                    reader.Read()
                End While
                reader.Read()
            End If

            If (Not reader.TokenType.Equals(JsonToken.PropertyName)) Then
                Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected PropertyName, got {0}.", reader.TokenType))
            End If
            If (reader.Value.Equals(ROWS)) Then
                reader.Read()

                If (Not reader.TokenType.Equals(JsonToken.StartArray)) Then
                    Throw New Exception(String.Format("Unexpected JSON token when reading DataTable. Expected StartArray, got {0}.", reader.TokenType))
                End If

                reader.Read()

                While (Not reader.TokenType.Equals(JsonToken.EndArray))
                    CreateRow(reader, dt, serializer)
                    reader.Read()
                End While
                reader.Read()
            End If

            Return dt
        End Function

        ''' <summary>
        ''' Determines whether this instance can convert the specified value type
        ''' </summary>
        ''' <param name="valueType">Type of the value.</param>
        ''' <returns><c>true</c> if this instance can convert the specified value type; oterwise <c>false</c></returns>
        Public Overrides Function CanConvert(valueType As Type) As Boolean
            Return GetType(DataTable).IsAssignableFrom(valueType)
        End Function

        Private Sub CreateRow(reader As JsonReader, dt As DataTable, serializer As JsonSerializer)
            Dim dr As DataRow = dt.NewRow()
            reader.read()

            While (reader.TokenType.Equals(JsonToken.PropertyName))
                Dim columnName As String = CStr(reader.Value)

                reader.Read()

                Dim column As DataColumn = dt.Columns(columnName)
                Dim columnType As Type
                If (column Is Nothing) Then

                    columnType = GetColumnDataType(reader)
                    column = New DataColumn(columnName, columnType)
                    dt.Columns.Add(column)
                Else
                    columnType = column.DataType
                End If

                If (column.DataType.Equals(GetType(DataTable))) Then
                    If (reader.TokenType.Equals(JsonToken.StartArray)) Then

                        reader.Read()
                    End If

                    Dim nestedDt As DataTable = New DataTable()

                    While (Not reader.TokenType.Equals(JsonToken.EndArray))

                        CreateRow(reader, nestedDt, serializer)

                        reader.Read()
                    End While

                    dr(columnName) = nestedDt

                ElseIf (column.DataType.IsArray And (Not column.DataType.Equals(GetType(Byte())))) Then

                    If (reader.TokenType.Equals(JsonToken.StartArray)) Then
                        reader.Read()
                    End If

                    Dim o As List(Of Object) = New List(Of Object)

                    While (Not reader.TokenType.Equals(JsonToken.EndArray))
                        o.Add(reader.Value)
                        reader.Read()
                    End While

                    Dim destinationArray As Array = Array.CreateInstance(column.DataType.GetElementType(), o.Count)
                    CType(o, IList).CopyTo(destinationArray, 0)

                    dr(columnName) = destinationArray
                Else
                    Dim columnValue As Object
                    If (reader.Value IsNot Nothing) Then
                        columnValue = serializer.Deserialize(reader, column.DataType)
                        If (columnValue Is Nothing) Then
                            columnValue = DBNull.Value
                        End If
                    Else
                        columnValue = DBNull.Value
                    End If

                    dr(columnName) = columnValue
                End If

                reader.Read
            End While

            dr.EndEdit()
            dt.Rows.Add(dr)
        End Sub

        Private Function GetColumnDataType(reader As JsonReader) As Type

            Dim tokenType As JsonToken = reader.TokenType
            Dim retVal As Type = Nothing

            Select Case (tokenType)
                Case JsonToken.Integer
                Case JsonToken.Boolean
                Case JsonToken.Float
                Case JsonToken.String
                Case JsonToken.Date
                Case JsonToken.Bytes
                    retVal = reader.ValueType
                Case JsonToken.Null
                Case JsonToken.Undefined
                    Return GetType(String)
                Case JsonToken.StartArray
                    reader.Read()
                    If (reader.TokenType.Equals(JsonToken.StartObject)) Then
                        retVal = GetType(DataTable) ' nested datatable
                    End If

                    Dim arrayType As Type = GetColumnDataType(reader)
                    retVal = arrayType.MakeArrayType()
                Case Else
                    Throw New Exception(String.Format("Unexpected JSON token when reading DataTable: {0}", tokenType))
            End Select

            Return retVal
        End Function

    End Class
End Namespace
