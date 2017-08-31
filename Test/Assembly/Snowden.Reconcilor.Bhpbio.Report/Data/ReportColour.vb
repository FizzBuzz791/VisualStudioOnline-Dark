Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Data
    Public NotInheritable Class ReportColour
        Private Sub New()
        End Sub

        Private Const _colorColumn As String = "PresentationColor"
        Private Const _lineStyleColumn As String = "PresentationLineStyle"
        Private Const _markerShapeColumn As String = "PresentationMarkerShape"


        Public Shared Sub AddLocationColor(ByVal session As Types.ReportSession, ByVal table As DataTable)
            If Not table.Columns.Contains("LocationColor") Then
                table.Columns.Add("LocationColor", GetType(String))
            End If

            AddLocationColor(session.DalUtility, table.AsEnumerable)
        End Sub

        Public Shared Sub AddLocationColor(dalUtility As IUtility, rows As IEnumerable(Of DataRow))
            Dim colors = dalUtility.GetBhpbioReportColorList(NullValues.String, True)
            Dim locationColors = colors.AsEnumerable.Where(Function(r) r.AsString("Description").Contains("Location")).ToList

            For Each row As DataRow In rows
                Dim locationId = row.AsInt("LocationId")
                Dim locationColor = locationColors.FirstOrDefault(Function(r) r.AsInt("TagId") = locationId)

                If locationColor IsNot Nothing AndAlso locationId > 0 Then
                    row("LocationColor") = locationColor.AsString("Color")
                End If
            Next

        End Sub
        Public Shared Sub AddCalculationColor(ByVal session As Types.ReportSession, ByVal data As Types.CalculationSet)
            AddPresentationColour(session, data)
        End Sub

        Public Shared Sub AddPresentationColour(ByVal session As Types.ReportSession, ByVal data As Types.CalculationSet)

            Dim colourList = GetColourList(session)
            For Each row In data
                If Not row.TagId Is Nothing AndAlso colourList.ContainsKey(row.TagId) Then
                    row.Tags.Add(New Types.CalculationResultTag("PresentationColor", GetType(String), colourList(row.TagId)))
                ElseIf Not row.CalcId Is Nothing AndAlso colourList.ContainsKey(row.CalcId) Then
                    row.Tags.Add(New Types.CalculationResultTag("PresentationColor", GetType(String), colourList(row.CalcId)))
                Else
                    row.Tags.Add(New Types.CalculationResultTag("PresentationColor", GetType(String), "Black"))
                End If
            Next
        End Sub

        Public Shared Sub MergePresentationColour(ByVal session As Types.ReportSession, _
         ByVal table As DataTable, ByVal tagIdColumn As String, ByVal colourColumn As String)
            Dim colourList = GetColourList(session)
            Dim row As DataRow

            For Each row In table.Rows
                If table.Columns.Contains(colourColumn) AndAlso table.Columns.Contains(tagIdColumn) _
                 AndAlso Not IsDBNull(row(tagIdColumn)) Then
                    row(colourColumn) = colourList(row(tagIdColumn).ToString)
                ElseIf table.Columns.Contains(colourColumn) Then
                    row(colourColumn) = DBNull.Value
                End If
            Next
        End Sub

        ' Retreieve the colour list data table into a dictionary look up. (only visible colours)
        Public Shared Function GetColourList(ByVal session As Types.ReportSession) As IDictionary(Of String, String)
            Return GetColourList(session, False)
        End Function

        ' Retreieve the colour list data table into a dictionary look up. (all colours)
        Public Shared Function GetColourList(ByVal session As Types.ReportSession, ByVal showVisible As Boolean) As IDictionary(Of String, String)
            Dim colourList As New Dictionary(Of String, String)
            Dim colourDT As DataTable = session.DalUtility.GetBhpbioReportColorList(NullValues.String, showVisible)

            For Each row As DataRow In colourDT.Rows
                colourList.Add(row("TagId").ToString, row("Color").ToString)
            Next

            Return colourList
        End Function

        Public Shared Sub MergePresentationColour(ByVal session As Types.ReportSession, _
         ByVal table As DataTable, ByVal tagIdColumn As String)
            Dim colourDT As DataTable = session.DalUtility.GetBhpbioReportColorList(NullValues.String, False)
            Dim colourList As New Dictionary(Of String, String)
            Dim lineStyleList As New Dictionary(Of String, String)
            Dim markerShapeList As New Dictionary(Of String, String)
            Dim row As DataRow

            For Each row In colourDT.Rows
                colourList.Add(row("TagId").ToString, row("Color").ToString)
                lineStyleList.Add(row("TagId").ToString, row("LineStyle").ToString)
                markerShapeList.Add(row("TagId").ToString, row("MarkerShape").ToString)
            Next

            For Each row In table.Rows

                Dim rowTagIdObject As Object = Nothing
                Dim productSizeObject As Object = Nothing
                Dim rowTagId As String = String.Empty
                Dim productSize As String = String.Empty

                If (table.Columns.Contains(tagIdColumn)) Then
                    rowTagIdObject = row(tagIdColumn)
                End If

                If (table.Columns.Contains(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE)) Then
                    productSizeObject = row.Item(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE)
                End If

                If (Not rowTagIdObject Is Nothing And Not rowTagIdObject Is DBNull.Value) Then
                    rowTagId = rowTagIdObject.ToString
                End If

                If (Not productSizeObject Is Nothing And Not productSizeObject Is DBNull.Value) Then
                    productSize = productSizeObject.ToString
                End If

                If (rowTagId.EndsWith(productSize) AndAlso productSize.Length > 0) Then
                    rowTagId = rowTagId.Substring(0, rowTagId.Length - productSize.Length)
                End If

                Dim colourString As String = Nothing
                Dim lineString As String = Nothing
                Dim markerString As String = Nothing

                colourList.TryGetValue(rowTagId, colourString)
                lineStyleList.TryGetValue(rowTagId, lineString)
                markerShapeList.TryGetValue(rowTagId, markerString)

                If table.Columns.Contains(_colorColumn) AndAlso Not colourString Is Nothing Then
                    row(_colorColumn) = colourString
                ElseIf table.Columns.Contains(_colorColumn) Then
                    row(_colorColumn) = DBNull.Value
                End If

                If table.Columns.Contains(_lineStyleColumn) AndAlso Not lineString Is Nothing Then
                    row(_lineStyleColumn) = lineString
                ElseIf table.Columns.Contains(_colorColumn) Then
                    row(_lineStyleColumn) = DBNull.Value
                End If

                If table.Columns.Contains(_markerShapeColumn) AndAlso Not markerString Is Nothing Then
                    row(_markerShapeColumn) = lineString
                ElseIf table.Columns.Contains(_colorColumn) Then
                    row(_markerShapeColumn) = DBNull.Value
                End If
            Next
        End Sub


        Public Shared Sub AddPresentationColour(ByVal session As Types.ReportSession, _
         ByVal table As DataTable, ByVal tagIdColumn As String)
            table.Columns.Add(New DataColumn(_colorColumn, GetType(String), ""))
            table.Columns.Add(New DataColumn(_lineStyleColumn, GetType(String), ""))
            table.Columns.Add(New DataColumn(_markerShapeColumn, GetType(String), ""))
            MergePresentationColour(session, table, tagIdColumn)
        End Sub

        Public Shared Sub AddThresholdColour(ByVal session As ReportSession, _
         ByVal table As DataTable)
            Dim colourList As IDictionary(Of String, String) = GetColourList(session)
            Dim lowThresholdColumnName As String = "LowThresholdColor"
            Dim medThresholdColumnName As String = "MediumThresholdColor"
            Dim highThresholdColumnName As String = "HighThresholdColor"
            Dim lowThreshold As String = Nothing
            Dim medThreshold As String = Nothing
            Dim highThreshold As String = Nothing

            If colourList.ContainsKey("RatioBad") Then
                highThreshold = colourList("RatioBad")
            End If

            If colourList.ContainsKey("RatioGood") Then
                lowThreshold = colourList("RatioGood")
            End If

            If colourList.ContainsKey("RatioOk") Then
                medThreshold = colourList("RatioOk")
            End If

            table.Columns.Add(New DataColumn(highThresholdColumnName, GetType(String), "'" & highThreshold & "'"))
            table.Columns.Add(New DataColumn(medThresholdColumnName, GetType(String), "'" & medThreshold & "'"))
            table.Columns.Add(New DataColumn(lowThresholdColumnName, GetType(String), "'" & lowThreshold & "'"))
        End Sub
    End Class
End Namespace
