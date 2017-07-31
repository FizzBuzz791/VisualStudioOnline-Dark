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
    Public Class BhpbioDataSetConverter
        Inherits DataSetConverter

        Public Overrides Sub WriteJson(writer As JsonWriter, value As Object, serializer As JsonSerializer)
            Dim DataSet As DataSet = CType(value, DataSet)
            Dim Resolver As DefaultContractResolver = CType(serializer.ContractResolver, DefaultContractResolver)

            Dim Converter As DataTableConverter = New BhpbioDataTableConverter()

            writer.WriteStartObject()

            For Each table As DataTable In DataSet.Tables
                Dim propertyName As String = Nothing

                If (Not Resolver.Equals(Nothing)) Then
                    propertyName = Resolver.GetResolvedPropertyName(table.TableName)
                Else
                    propertyName = table.TableName
                End If

                writer.WritePropertyName(propertyName)

                Converter.WriteJson(writer, table, serializer)
            Next

            writer.WriteEndObject()
        End Sub

        Public Overrides Function ReadJson(reader As JsonReader, objectType As Type, existingValue As Object, serializer As JsonSerializer) As Object

            If (reader.TokenType.Equals(JsonToken.Null)) Then
                Return Nothing
            End If

            ' handle typed datasets
            Dim ds As DataSet

            If (objectType.Equals(GetType(DataSet))) Then

                ds = New DataSet()
            Else

                ds = CType(Activator.CreateInstance(objectType), DataSet)
            End If

            Dim Converter As DataTableConverter = New BhpbioDataTableConverter()

            reader.Read()

            While (reader.TokenType.Equals(JsonToken.PropertyName))
                Dim dt As DataTable = ds.Tables(CStr(reader.Value))
                Dim exists As Boolean = (dt IsNot Nothing)

                Dim obj As Object = Converter.ReadJson(reader, GetType(DataTable), dt, serializer)
                dt = CType(obj, DataTable)

                If (Not exists) Then
                    ds.Tables.Add(dt)
                End If

                reader.Read()
            End While

            Return ds
        End Function

        Public Overrides Function CanConvert(valueType As Type) As Boolean
            Return GetType(DataSet).IsAssignableFrom(valueType)
        End Function


    End Class

End Namespace