Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Data
    Public NotInheritable Class MaterialType
        Private Sub New()
        End Sub

        Public Shared Function GetReportMaterialList(ByVal dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility) _
         As IDictionary(Of Int32, String)
            Dim list As New Generic.Dictionary(Of Int32, String)
            Dim materialList = dalUtility.GetBhpbioMaterialLookup("Designation", NullValues.Int16)
            Dim row As DataRow
            Dim id As Int32

            ' Add all the material types at the Desgination level.
            For Each row In materialList.Rows
                If Int32.TryParse(row("MaterialTypeId").ToString(), id) Then
                    If (Not list.ContainsKey(id)) Then
                        list.Add(id, row("Abbreviation").ToString())
                    End If
                End If
            Next
            '' Add Bene Product as it does not exist in the material type table.
            'list.Add(beneProductMaterialTypeId, beneProductMaterialTypeAbb)

            Return list
        End Function

        Public Shared Function GetMaterialType(ByVal session As ReportSession, ByVal description As String) As Int32
            Dim materialTypes As IDictionary(Of Int32, String) = session.GetReportMaterialList()

            Return GetMaterialType(materialTypes, description)
        End Function
        Public Shared Function GetMaterialType(ByVal materialTypes As IDictionary(Of Int32, String), ByVal description As String) As Int32
            Dim materialTypeId As Int32 = 0
            For Each material In materialTypes
                If material.Value.ToUpper() = description.ToUpper() Then
                    materialTypeId = material.Key
                End If
            Next
            Return materialTypeId
        End Function

    End Class
End Namespace
