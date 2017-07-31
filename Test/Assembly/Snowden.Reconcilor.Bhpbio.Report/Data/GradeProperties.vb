Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Data
    Public NotInheritable Class GradeProperties
        Private Sub New()
        End Sub

        Public Shared Function GetBhpbioFReportAttributeProperties(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32) As DataTable

            Return session.DalReport.GetBhpbioReportFactorProperties(locationId)
        End Function

        Public Shared Function GetFAttributeProperties(ByVal session As ReportSession, _
         ByVal locationId As Int32) As DataTable
            Dim table As DataTable = session.DalReport.GetBhpbioReportFactorProperties(locationId)
            ReportColour.AddThresholdColour(session, table)
            table.TableName = "Attributes"
            Return table
        End Function

        Public Shared Function GetAttributesTable(ByVal session As ReportSession) As DataTable
            Dim tbl As DataTable = session.DalReport.GetBhpbioReportAttributeProperties()
            tbl.TableName = "Attributes"
            Return tbl
        End Function

        Public Shared Sub AddGradePrecisionToNormalizedTable(ByVal session As Types.ReportSession, _
         ByVal table As DataTable)
            Dim columnName As String = "PresentationAttributePrecision"
            Dim attributeColumnName As String = "Attribute"
            Dim grades As IDictionary(Of String, Int32) = GetAttributesPrecision(session)
            Dim row As DataRow
            table.Columns.Add(New DataColumn(columnName, GetType(Int32), ""))

            For Each row In table.Rows
                If Not IsDBNull(row(attributeColumnName)) AndAlso _
                 grades.ContainsKey(row(attributeColumnName).ToString()) Then
                    row(columnName) = grades(row(attributeColumnName).ToString())
                End If
            Next
        End Sub

        Public Shared Sub AddGradeColourToNormalizedTable(ByVal session As Types.ReportSession, _
         ByVal table As DataTable)
            Dim columnName As String = "AttributeColour"
            Dim attributeColumnName As String = "Attribute"
            Dim grades As IDictionary(Of String, String) = GetAttributesColour(session)
            Dim row As DataRow
            table.Columns.Add(New DataColumn(columnName, GetType(String), ""))

            For Each row In table.Rows
                If Not IsDBNull(row(attributeColumnName)) AndAlso _
                 grades.ContainsKey(row(attributeColumnName).ToString()) Then
                    row(columnName) = grades(row(attributeColumnName).ToString())
                End If
            Next
        End Sub


        ' TODO: Try roll this up into better calls.
        Public Shared Function GetAttributesPrecision(ByVal session As Types.ReportSession) _
         As IDictionary(Of String, Int32)
            Dim list As New Dictionary(Of String, Int32)
            Dim table As DataTable = session.DalReport.GetBhpbioReportAttributeProperties()
            Dim row As DataRow
            Dim attributePrecision As String = "DisplayPrecision"
            Dim attributeName As String = "AttributeName"

            For Each row In table.Rows
                If table.Columns.Contains(attributeName) And table.Columns.Contains(attributePrecision) _
                 AndAlso Not IsDBNull(row(attributePrecision)) And Not IsDBNull(row(attributeName)) Then
                    list.Add(row(attributeName).ToString, Convert.ToInt32(row(attributePrecision)))
                End If
            Next

            Return list
        End Function

        Public Shared Function GetAttributesColour(ByVal session As Types.ReportSession) _
         As IDictionary(Of String, String)
            Dim list As New Dictionary(Of String, String)
            Dim table As DataTable = session.DalReport.GetBhpbioReportAttributeProperties()
            Dim row As DataRow
            Dim attributeColour As String = "AttributeColor" ' have to use american spelling - thats what it is in the db
            Dim attributeName As String = "AttributeName"

            For Each row In table.Rows
                If table.Columns.Contains(attributeName) And table.Columns.Contains(attributeColour) _
                 AndAlso Not IsDBNull(row(attributeColour)) And Not IsDBNull(row(attributeName)) Then
                    list.Add(row(attributeName).ToString, Convert.ToString(row(attributeColour)))
                End If
            Next

            Return list
        End Function

        Public Shared Function GetAttributes(ByVal session As ReportSession, Optional ByVal includeHidden As Boolean = False) As IDictionary(Of Int16, String)
            Dim list As New Dictionary(Of Int16, String)
            Dim table As DataTable = session.DalReport.GetBhpbioReportAttributeProperties()
            Dim row As DataRow
            Dim attributeId As String = "AttributeId"
            Dim attributeName As String = "AttributeName"

            For Each row In table.Rows
                If table.Columns.Contains(attributeName) And table.Columns.Contains(attributeId) _
                 AndAlso Not IsDBNull(row(attributeId)) And Not IsDBNull(row(attributeName)) _
                 AndAlso (Convert.ToBoolean(row("IsVisible")) Or includeHidden) Then
                    list.Add(Convert.ToInt16(row(attributeId)), row(attributeName).ToString)
                End If
            Next

            Return list
        End Function

    End Class
End Namespace

