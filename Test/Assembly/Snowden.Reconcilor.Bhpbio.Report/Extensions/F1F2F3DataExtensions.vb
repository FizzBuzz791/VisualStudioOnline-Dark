Imports System.Runtime.CompilerServices
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Extensions
    ' These extension methods are specific to a DataTable produced from the Calculation classes ToDataTable method
    ' They are used by the methods above when the factors + differences need to be recalculated, as well as doing other
    ' useful things.
    Public Module F1F2F3DataExtensions
        <Extension>
        Public Function IsUnpivotedTable(table As DataTable) As Boolean
            Return table.Columns.Contains("AttributeValue")
        End Function

        <Extension>
        Public Sub RecalculateDifferences(resultRow As DataRow, ByRef firstRow As DataRow, ByRef secondRow As DataRow)
            Dim attributeNames = New List(Of String)(CalculationResultRecord.GradeNames.ToList)
            attributeNames.Insert(0, "Tonnes")
            attributeNames.Insert(1, "Volume")

            For Each attributeName In attributeNames
                resultRow.RecalculateAttributeDifference(firstRow, secondRow, attributeName)
            Next
        End Sub

        <Extension>
        Public Sub RecalculateAttributeDifference(resultRow As DataRow, ByRef firstRow As DataRow, ByRef secondRow As DataRow, attributeName As String)
            If resultRow Is Nothing OrElse firstRow Is Nothing OrElse secondRow Is Nothing Then
                Return
            End If

            If Not firstRow.HasColumn(attributeName) OrElse Not secondRow.HasColumn(attributeName) Then
                Return
            End If

            If Not resultRow.HasColumn(attributeName + "Difference") Then
                Return
            End If

            resultRow(attributeName + "Difference") = GetAttributeDifference(firstRow, secondRow, attributeName)
        End Sub

        Public Function GetAttributeDifference(ByRef firstRow As DataRow, ByRef secondRow As DataRow, attributeName As String) As Double
            If firstRow Is Nothing Then Throw New ArgumentNullException("firstRow")
            If secondRow Is Nothing Then Throw New ArgumentNullException("secondRow")

            If Not firstRow.HasValue(attributeName) AndAlso secondRow.HasValue(attributeName) Then
                Return 0.0 - secondRow.AsDbl(attributeName)
            ElseIf firstRow.HasValue(attributeName) AndAlso secondRow.HasValue(attributeName) Then
                Return firstRow.AsDbl(attributeName) - secondRow.AsDbl(attributeName)
            Else
                Return Nothing
            End If
        End Function

        <Extension>
        Public Sub RecalculateRatios(resultRow As DataRow, ByRef firstRow As DataRow, ByRef secondRow As DataRow)
            Dim attributeNames = New List(Of String)(CalculationResultRecord.GradeNames.ToList)
            attributeNames.Insert(0, "Tonnes")
            attributeNames.Insert(1, "Volume")

            For Each attributeName In attributeNames
                resultRow.RecalculateAttributeRatio(firstRow, secondRow, attributeName)
            Next
        End Sub


        <Extension>
        Public Sub RecalculateAttributeRatioUnpivoted(resultRow As DataRow, ByRef topRow As DataRow, ByRef bottomRow As DataRow)
            If topRow Is Nothing OrElse bottomRow Is Nothing Then
                resultRow("AttributeValue") = 0.0
            ElseIf topRow("Attribute").ToString <> bottomRow("Attribute").ToString Then
                Throw New Exception(String.Format("Cannot recalculate factor: attribute doesn't match ('{0}' and '{1}')", topRow("Attribute").ToString, bottomRow("Attribute").ToString))
            ElseIf topRow.AsDblN("AttributeValue") Is Nothing OrElse bottomRow.AsDblN("AttributeValue") Is Nothing _
                   OrElse topRow.AsDblN("AttributeValue") = 0 OrElse bottomRow.AsDblN("AttributeValue") = 0 Then
                resultRow("AttributeValue") = 0.0
            Else
                resultRow("AttributeValue") = topRow.AsDblN("AttributeValue") / bottomRow.AsDblN("AttributeValue")
            End If
        End Sub

        <Extension>
        Public Sub RecalculateAttributeRatio(resultRow As DataRow, ByRef firstRow As DataRow, ByRef secondRow As DataRow, attributeName As String)
            If Not (resultRow Is Nothing OrElse firstRow Is Nothing OrElse firstRow(attributeName) Is DBNull.Value OrElse secondRow Is Nothing OrElse secondRow(attributeName) Is DBNull.Value) Then
                resultRow(attributeName) = GetAttributeRatio(firstRow, secondRow, attributeName)
            End If
        End Sub

        Public Function GetAttributeRatio(ByRef firstRow As DataRow, ByRef secondRow As DataRow, attributeName As String) As Double
            If firstRow.Table.Columns.Contains(attributeName) AndAlso secondRow.Table.Columns.Contains(attributeName) AndAlso Math.Abs(secondRow.AsDbl(attributeName) - 0) > Double.Epsilon Then
                Return firstRow.AsDbl(attributeName) / secondRow.AsDbl(attributeName)
            Else
                Return Nothing
            End If
        End Function


        ' give a reference row, this will return all the other grades/attributes that match that rows. This only works on the unpivoted tables
        <Extension>
        Public Function GetCorrespondingRowsUnpivoted(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow) As IEnumerable(Of DataRow)
            If rows Is Nothing Or rows.Count = 0 Then Return rows

            Return rows.Where(Function(r) _
                                 r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                 r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                 r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                 r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                 r("ReportTagId").ToString = referenceRow("ReportTagId").ToString AndAlso
                                 ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                              ).ToList
        End Function

        <Extension>
        Public Function GetCorrespondingRowsForGroupUnpivoted(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow) As IEnumerable(Of DataRow)
            If rows Is Nothing Or rows.Count = 0 Then Return rows

            Return rows.Where(Function(r) _
                                 r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                 r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                 r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                 r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                 ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                              ).ToList
        End Function

        ' returns the matching rows across all resource classifications that match the passed in row
        <Extension>
        Public Function GetCorrespondingRowsForResourceClassificationsUnpivoted(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow) As IEnumerable(Of DataRow)
            If rows Is Nothing Or rows.Count = 0 Then Return rows

            Return rows.Where(Function(r) _
                                 r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                 r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                 r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                 r("ReportTagId").ToString = referenceRow("ReportTagId").ToString AndAlso
                                 r("Attribute").ToString = referenceRow("Attribute").ToString AndAlso
                                 r("LocationId").ToString = referenceRow("LocationId").ToString AndAlso
                                 Not String.IsNullOrEmpty(r("ResourceClassification").ToString)
                              ).ToList
        End Function

        ' returns the matching rows across all resource classifications that match the passed in row
        <Extension>
        Public Function GetCorrespondingRowsForResourceClassifications(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow) As IEnumerable(Of DataRow)
            If rows Is Nothing Or rows.Count = 0 Then Return rows

            Return rows.Where(Function(r) _
                                 r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                 r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                 r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                 r("ReportTagId").ToString = referenceRow("ReportTagId").ToString AndAlso
                                 r("LocationId").ToString = referenceRow("LocationId").ToString AndAlso
                                 Not String.IsNullOrEmpty(r("ResourceClassification").ToString)
                              ).ToList
        End Function

        ' returns the matching rows across all locations that match the passed in row
        <Extension>
        Public Function GetCorrespondingRowsForLocationsUnpivoted(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow, Optional ByVal parentLocationId As Integer = 0) As IEnumerable(Of DataRow)
            If rows Is Nothing Or rows.Count = 0 Then Return rows

            Return rows.Where(Function(r) _
                                 r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                 r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                 r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                 r("ReportTagId").ToString = referenceRow("ReportTagId").ToString AndAlso
                                 r("Attribute").ToString = referenceRow("Attribute").ToString AndAlso
                                 r("LocationId").ToString <> parentLocationId.ToString AndAlso
                                 ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                              ).ToList
        End Function

        <Extension>
        Public Function GetCorrespondingRowUnpivoted(ByRef rows As IEnumerable(Of DataRow), referenceRow As DataRow, reportTagId As String) As DataRow
            ' throw an exception if it finds more than one row. If it finds none, just return Nothing
            Dim matches = rows.Where(Function(r) _
                                        r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                        r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                        r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                        r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                        r("Attribute").ToString = referenceRow("Attribute").ToString AndAlso
                                        r("ReportTagId").ToString = reportTagId AndAlso
                                        ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                                     ).ToList

            If matches.Count > 1 Then
                Throw New DataException(String.Format("Mulitple matches found for DataRow TagId: {0}", reportTagId))
            Else
                Return matches.FirstOrDefault
            End If
        End Function

        ' finds the referenceRow in the DataTable with the tagId given. Will match on date, location, materialType, and productSize
        <Extension>
        Public Function GetCorrespondingRow(ByRef rows As IEnumerable(Of DataRow), tagId As String, referenceRow As DataRow) As DataRow
            ' throw an exception if it finds more than one row. If it finds none, just return Nothing
            Dim matches = rows.Where(Function(r) _
                                        r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                        r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                        r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                        r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                        r("TagId").ToString = tagId AndAlso
                                        ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                                     ).ToList

            If matches.Count > 1 Then
                Throw New DataException(String.Format("Mulitple matches found for DataRow TagId: {0}", tagId))
            Else
                Return matches.FirstOrDefault
            End If
        End Function

        <Extension>
        Public Function GetCorrespondingRowWithReportTagId(ByRef rows As IEnumerable(Of DataRow), reportTagId As String, referenceRow As DataRow, Optional ByVal ignoreDateFrom As Boolean = False, Optional ByVal overrideDateFromToMatch As Nullable(Of DateTime) = Nothing) As DataRow
            ' throw an exception if it finds more than one row. If it finds none, just return Nothing
            Dim matchDateFrom = DateTime.Now

            If (Not ignoreDateFrom) Then
                If (overrideDateFromToMatch.HasValue) Then
                    matchDateFrom = overrideDateFromToMatch.Value
                Else
                    matchDateFrom = referenceRow.AsDate("DateFrom")
                End If
            End If

            Dim matches = rows.Where(Function(r) _
                                        (ignoreDateFrom OrElse r.AsDate("DateFrom") = matchDateFrom) AndAlso
                                        r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                        r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                        r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                        r("ReportTagId").ToString = reportTagId AndAlso
                                        ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                                     ).ToList

            If matches.Count > 1 Then
                Throw New DataException(String.Format("Mulitple matches found for DataRow TagId: {0}", reportTagId))
            Else
                Return matches.FirstOrDefault
            End If

        End Function

        <Extension>
        Public Function FactorRows(ByRef rows As IEnumerable(Of DataRow)) As IEnumerable(Of DataRow)
            Return rows.Where(Function(r) r.IsFactorRow)
        End Function

        ' finds the referenceRow in the DataTable with the tagId given. Will match on date, location, materialType, and productSize
        '
        ' It would be good to do this in a generic way with the method above, but can't quite think how this would work?
        <Extension>
        Public Function GetCorrespondingRowWithProductSize(ByRef rows As IEnumerable(Of DataRow), productSize As String, referenceRow As DataRow) As DataRow
            Dim reportTagId = referenceRow.AsString("ReportTagId")

            If productSize = "TOTAL" Then
                If reportTagId.EndsWith("_AS") OrElse reportTagId.EndsWith("_AD") Then
                    reportTagId = reportTagId.Substring(0, reportTagId.Length - "_AS".Length)
                End If
            End If

            ' throw an exception if it finds more than one row. If it finds none, just return Nothing
            Dim matches = rows.Where(Function(r) _
                                        r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                        r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                        r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                        r("ProductSize").ToString = productSize AndAlso
                                        r("ReportTagId").ToString = reportTagId AndAlso
                                        ((Not referenceRow.HasColumn("ResourceClassification")) OrElse r("ResourceClassification").ToString = referenceRow("ResourceClassification").ToString)
                                     ).ToList

            If matches.Count > 1 Then
                Throw New DataException(String.Format("Mulitple matches found for DataRow TagId: {0}", referenceRow("TagId")))
            Else
                Return matches.FirstOrDefault
            End If
        End Function

        <Extension>
        Public Function HasTonnes(ByRef row As DataRow) As Boolean
            Return row.HasValue("Tonnes")
        End Function

        ' this method is only valid for F1F2F3 DataTables, so we don't want to make it generally available
        '
        ' If the 'Type' field is present (and it should always be), then we can use this to find out if the
        ' row is a factor or not. Type = 0 means it is a factor, Type = 1 means it is just a normal value
        <Extension>
        Public Function IsFactorRow(ByRef row As DataRow) As Boolean
            If row.Table.Columns.Contains("Type") Then
                Return row.AsInt("Type") = 0
            Else
                Return False
            End If
        End Function

        <Extension>
        Public Function IsGeometRow(ByRef row As DataRow) As Boolean
            If row.Table.Columns.Contains("ProductSize") Then
                Return row.AsString("ProductSize") = "GEOMET"
            Else
                Return False
            End If
        End Function

        <Extension>
        Public Function ClearValues(ByRef rows As IEnumerable(Of DataRow)) As IEnumerable(Of DataRow)

            For Each row In rows
                row.ClearValues()
            Next

            Return rows
        End Function

        ' the tonnes + volume numbers are multiplied by the adjustment factor. This is used to convert the
        ' geomet LUMP from As-Shipped to As-Dropped
        <Extension>
        Public Function AdjustTonnes(ByRef rows As IEnumerable(Of DataRow), adjustment As Double) As IEnumerable(Of DataRow)

            For Each row In rows
                If Not IsDBNull(row("Tonnes")) Then
                    row("Tonnes") = row.AsDbl("Tonnes") * adjustment
                End If

                If Not IsDBNull(row("Volume")) Then
                    row("Volume") = row.AsDbl("Volume") * adjustment
                End If
            Next

            Return rows
        End Function

        <Extension>
        Public Function WithProductSize(ByRef rows As IEnumerable(Of DataRow), productSize As String) As IEnumerable(Of DataRow)
            Const columnName = "ProductSize"
            If rows.Count = 0 Then Return rows

            If productSize Is Nothing Then
                Throw New ArgumentNullException("productSize")
            End If

            If Not rows.First.Table.Columns.Contains(columnName) Then
                Throw New Exception(String.Format("Could not filter, DataTable doesn't contain '{0}' column", columnName))
            End If

            Return rows.Where(Function(r) r.AsString(columnName).ToUpper = productSize.ToUpper)
        End Function

        ' makes a copy of a set of rows, and returns a list of them
        ' They will already be added to the DataTable
        <Extension>
        Public Function CloneFactorRows(ByRef rows As IEnumerable(Of DataRow), Optional ByVal withValues As Boolean = False) As List(Of DataRow)
            If rows.Count = 0 Then Return rows.ToList

            Dim table = rows.First.Table
            Dim newRows As New List(Of DataRow)

            For Each row In rows
                Dim newRow As DataRow
                If withValues Then
                    newRow = GenericDataTableExtensions.Copy(row)
                Else
                    newRow = row.CloneFactorRow(False)
                End If

                newRows.Add(newRow)
            Next

            For Each row In newRows
                table.Rows.Add(row)
            Next

            Return newRows
        End Function

        ' Makes a copy of the current row, and nulls out all the value fields, by default will be added to the
        ' current table
        <Extension>
        Public Function CloneFactorRow(ByRef row As DataRow, Optional ByVal addToTable As Boolean = True) As DataRow
            Dim newRow = GenericDataTableExtensions.Copy(row)
            newRow.ClearValues()

            If addToTable Then
                row.Table.Rows.Add(newRow)
            End If

            Return newRow
        End Function

        ' sets all the values (Tonnes, Fe etc) in the current row to null, leaves other information such as
        ' tagIds, product size unchanged
        <Extension>
        Public Sub ClearValues(ByRef row As DataRow)
            For Each attr In AttributeNames(tonnesAsWell:=True)
                row.SetNull(attr)
            Next
        End Sub

        Public Function AttributeNames(Optional ByVal tonnesAsWell As Boolean = False) As String()
            Dim gradeNames As List(Of String) = CalculationResultRecord.GradeNames.ToList
            Dim attributes = New List(Of String)(gradeNames)

            ' for the purposes of this method, attributes are all the grades, plus the grade difference tags
            For Each gradeName As String In gradeNames
                attributes.Add(gradeName + "Difference")
            Next

            If tonnesAsWell Then
                attributes.Add("Tonnes")
                attributes.Add("Volume")
                attributes.Add("TonnesDifference")
                attributes.Add("DodgyAggregateGradeTonnes")
            End If

            Return attributes.ToArray
        End Function

        <Extension>
        Public Function ToCalculationRecord(ByRef row As DataRow) As CalculationResultRow
            ' first the meta data
            ' then the actual values
            Dim result = New CalculationResultRow() With {
                    .ReportTagId = row.AsString("ReportTagId"),
                    .CalcId = row.AsString("CalcId"),
                    .Description = row.AsString("Description"),
                    .DateFrom = row.AsDate("DateFrom"),
                    .DateTo = row.AsDate("DateTo"),
                    .CalendarDate = row.AsDate("CalendarDate"),
                    .LocationId = row.AsInt("LocationId"),
                    .MaterialTypeId = row.AsInt("MaterialTypeId"),
                    .ProductSize = row.AsString("ProductSize"),
                    .Tonnes = row.AsDblN("Tonnes"),
                    .Volume = row.AsDblN("Volume")
                    }

            ' always use the grades list - this makes it easy to handle when we add new grades
            For Each grade In CalculationResultRecord.GradeNames
                result.SetGrade(grade, row.AsDblN(grade))
            Next

            Return result
        End Function

        <Extension>
        Public Function FromCalculationRecord(ByRef row As DataRow, ByRef resultRow As CalculationResultRow) As DataRow

            If row.AsString("CalcId") <> resultRow.CalcId Then
                Throw New Exception("Cannot set from Calculation Result - CalcIds do not match")
            End If

            row("Tonnes") = resultRow.Tonnes
            row("Volume") = resultRow.Volume

            For Each grade In CalculationResultRecord.GradeNames
                row(grade) = resultRow.GetGrade(grade)
            Next

            Return row
        End Function

        <Extension>
        Public Function GenerateTagId(ByRef row As DataRow) As String
            Dim productSize = row.AsString("ProductSize")
            If (productSize Is Nothing OrElse productSize = "TOTAL") Then
                Return row.AsString("ReportTagId")
            Else
                Return row.AsString("ReportTagId") + productSize
            End If
        End Function
    End Module
End NameSpace