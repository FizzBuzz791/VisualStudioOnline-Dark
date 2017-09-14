Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Types

    Public Class ProductType

        Public Const DefaultTopLevelLocationId As Integer = 1

        Public Property ProductTypeID As Integer
        Public Property ProductTypeCode As String
        Public Property Description As String
        Public Property ProductSize As String
        Public Property LocationIds As List(Of Integer)

        ' ok, this is not the right way to handle the location ids, as a product type can hold more than
        ' one Hub, however for the purposes of the initial development we just assume there is one hub
        ' and hardcode NBLL as an exception
        Public ReadOnly Property LocationId As Integer
            Get
                If LocationIds Is Nothing OrElse LocationIds.Count = 0 Then
                    Throw New Exception(String.Format("ProductType '{0}' has no assigned locations", ProductTypeCode))
                ElseIf LocationIds.Count = 1 Then
                    Return LocationIds.First
                ElseIf LocationIds.Count > 1 Then
                    ' there is more than one location_id, set the location_id to WAIO (and later logic will filter to the specific hubs
                    Return DefaultTopLevelLocationId
                End If
            End Get
        End Property

        Public Sub New()
            LocationIds = New List(Of Integer)
        End Sub

        Public Sub New(ByRef rows As IEnumerable(Of DataRow))
            If rows Is Nothing Then Throw New ArgumentNullException("rows")
            If rows.Count = 0 Then Throw New ArgumentException("rows was empty")

            Dim row = rows.FirstOrDefault
            Dim locations = rows.Select(Function(r) r.AsInt("LocationId")).Distinct

            ProductTypeID = row.AsInt("ProductTypeID")
            ProductTypeCode = row.AsString("ProductTypeCode")
            Description = row.AsString("Description")
            ProductSize = row.AsString("ProductSize")
            LocationIds = locations.ToList

        End Sub

        Public Shared Function FromDataTable(ByRef table As DataTable) As List(Of ProductType)
            Dim result = New List(Of ProductType)
            Dim productTypeIds = table.AsEnumerable.Select(Function(r) r.AsInt("ProductTypeId")).Distinct.ToList

            For Each id In productTypeIds
                Dim rows = table.AsEnumerable.Where(Function(r) r.AsInt("ProductTypeId") = id).ToList
                result.Add(New ProductType(rows.AsEnumerable))
            Next

            Return result
        End Function

    End Class

End Namespace
