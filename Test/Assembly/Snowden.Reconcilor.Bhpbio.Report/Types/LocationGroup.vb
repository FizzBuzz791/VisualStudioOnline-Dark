Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Types

    Public Class LocationGroup

        Public Property LocationGroupId As Integer
        Public Property ParentLocationId As Integer
        Public Property LocationGroupTypeName As String
        Public Property Name As String
        Public Property CreatedDate As Date
        Public Property LocationIds As List(Of Integer)

        Public Shared Function FromDataTable(ByRef table As DataTable) As List(Of LocationGroup)
            Dim result = New List(Of LocationGroup)
            Dim locationGroups = table.AsEnumerable.GroupBy(Function(r) r.AsInt("LocationGroupId"))

            For Each lgl In locationGroups
                Dim lg = lgl.First

                result.Add(New LocationGroup With {
                        .LocationGroupId = lg.AsInt("LocationGroupId"),
                        .ParentLocationId = lg.AsInt("ParentLocationId"),
                        .LocationGroupTypeName = lg.AsString("LocationGroupTypeName"),
                        .Name = lg.AsString("Name"),
                        .CreatedDate = lg.AsDate("CreatedDate"),
                        .LocationIds = lgl.Select(Function(r) r.AsInt("LocationId")).ToList
                    })
            Next

            Return result
        End Function

    End Class

End Namespace
