Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace ReportDefinitions

    Public Class F1F2F3SingleCalculationReport
        Inherits ReportBase

        ' this assumes that the calculation parameters have already been set up in the session, so we don't
        ' have to pass them through
        Public Shared Function GetResourceClassificationByLocation(session As ReportSession, calculationId As String) As DataTable
            session.ClearCacheBlockModel()

            session.IncludeResourceClassification = True
            session.IncludeProductSizeBreakdown = False

            Dim calcSet As New Types.CalculationSet()
            Dim result = Calc.Calculation.Create(calculationId, session).Calculate()
            calcSet.Add(result)

            Dim table = calcSet.ToDataTable(session, New DataTableOptions With {.DateBreakdown = ReportBreakdown.None})

            ' delete any rows with no location set. We only want sublocations in this case
            table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId")).DeleteRows()

            ' we need to recalculate the differences now, so that we can get the factor tonnes out of the table
            ' this is ok to call even if there are no diff columns in the table (for example if we run this for
            ' with a factor in the CalcSet)
            F1F2F3SingleCalculationReport.RecalculateDifferences(table)

            ' the graphs that use this data need it to be unpivoted, so do that. Once we have it in this format
            ' we can add other fields in an easier way
            F1F2F3ReportEngine.AddLocationDataToTable(session, table, session.RequestParameter.LocationId.Value)
            F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)
            table = F1F2F3ReportEngine.UnpivotDataTable(table, maintainTonnes:=True)

            If table.Rows.Count > 0 Then
                ' add metal tonnes will fail if there are no rows, because the unpivot method
                ' will not have set things up properly, so we fix this by onlu running the
                ' method when there actually are rows
                AddMetalTonnes(table)
            End If

            ' we need to do this because the webservice doesn't handle nulls that well
            For Each row As DataRow In table.Rows
                If Not row.HasValue("ResourceClassification") Then
                    row("ResourceClassification") = "ResourceClassificationTotal"
                End If
            Next

            ' add colors
            AddResourceClassificationColor(table)

            Return table
        End Function

        Public Shared Function GetResourceClassificationCalculation(session As ReportSession, calculationId As String, locationId As Integer, dateFrom As Date, dateTo As Date, Optional productSize As String = Nothing) As DataTable
            session.IncludeResourceClassification = True
            session.IncludeProductSizeBreakdown = False

            If productSize IsNot Nothing Then
                session.ProductSizeFilterString = productSize
            End If

            session.Context = Types.ReportContext.ApprovalListing
            session.CalculationParameters(dateFrom, dateTo, Types.ReportBreakdown.Monthly, locationId, False)

            Dim calcSet As New Types.CalculationSet()
            Dim result = Calc.Calculation.Create(calculationId, session).Calculate()

            calcSet.Add(result)
            Dim table = calcSet.ToDataTable(True, False, True, False, session)

            ' we need to recalculate the differences now, so that we can get the factor tonnes out of the table
            RecalculateDifferences(table)
            AddFactorTonnes(table)

            ' we had to get all the rows bad from ToDataTable in order to recalculate the factors
            ' but we don't actually want them to go back to the caller, so filter them out here
            Dim unneededRows = table.AsEnumerable.Where(Function(r) r.AsString("CalcId") <> calculationId).ToList
            table.DeleteRows(unneededRows.AsEnumerable)

            Return table
        End Function

        Public Shared Sub AddDifferenceColumnsIfNeeded(ByRef table As DataTable)
            Dim attributeList = CalculationResultRecord.StandardGradeNames.ToList
            attributeList.Insert(0, "Tonnes")
            attributeList.Insert(1, "Volume")

            ' sometimes the difference columns don't get added properly, add them if they don't exist
            For Each attributeName In attributeList
                table.Columns.AddIfNeeded(attributeName + "Difference", GetType(Double))
            Next

        End Sub

        Public Shared Sub RecalculateDifferences(ByRef table As DataTable)
            Dim factorComponents = F1F2F3ReportEngine.GetFactorComponentList(True)

            AddDifferenceColumnsIfNeeded(table)

            For Each row As DataRow In table.Rows
                If Not row.IsFactorRow Then Continue For

                Dim components As String() = Nothing

                ' try to get the components of the factor given the Tag Id
                factorComponents.TryGetValue(row.AsString("ReportTagId"), components)

                If components Is Nothing Then
                    Throw New Exception(String.Format("Unknown factor ReportTagId '{0}'", row.AsString("ReportTagId")))
                End If

                If components.Length > 0 Then
                    ' components have been specified and the difference should be recalculated

                    Dim matchingRows = table.AsEnumerable.
                    GetOtherCalculationsForRow(row).
                    Where(Function(r) r.AsString("ResourceClassification") = row.AsString("ResourceClassification")).
                    ToList

                    Dim topRow = matchingRows.FirstOrDefault(Function(r) r.AsString("ReportTagId") = components(0))
                    Dim bottomRow = matchingRows.FirstOrDefault(Function(r) r.AsString("ReportTagId") = components(1))
                    row.RecalculateDifferences(topRow, bottomRow)
                End If
            Next

        End Sub

        ' just a temp method until the one developed by PP goes in
        Private Shared Sub AddResourceClassificationColor(ByRef table As DataTable)
            If Not table.Columns.Contains("PresentationColor") Then
                table.Columns.Add("PresentationColor", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                row("PresentationColor") = F1F2F3ReportEngine.GetResourceClassificationColor(row.AsString("ResourceClassification"))
            Next
        End Sub

        Private Shared Sub AddFactorTonnes(ByRef table As DataTable)
            ' use AddTonnesValuesToUnpivotedTable to get this data into the table. If it is a pivoted table
            ' then the field will already be there
            If Not table.Columns.Contains("Tonnes") Then
                Throw New Exception("This method requires the Tonnes column to have been added")
            End If

            ' for a Factor row the 'Tonnes' field will contain the value of the tonnes FACTOR, not the
            ' actual tonnes value. This contains the tonnes of the predicted value in the factor (ie the
            ' top value, ie the Grade Control value if we are talking about F1). 
            '
            ' The value can actually be back calculated from the Factor and the TonnesDifference, it isn't
            ' required to look up the value in a separate row. Of course this requires that the difference 
            ' columns are calculated properly, which is not always the case...
            If Not table.Columns.Contains("FactorTonnes") Then
                table.Columns.Add("FactorTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                If Not row.IsFactorRow Then Continue For

                Dim factorValue = row.AsDblN("Tonnes")
                Dim tonnesDifference = row.AsDblN("TonnesDifference")
                Dim factorTonnes = tonnesDifference / (1 - (1 / factorValue))

                If factorTonnes.HasValue Then
                    row("FactorTonnes") = factorTonnes.Value
                End If
            Next

        End Sub

        ' Add metal units to an unpivoted table. Already was doing this as part of the error contribution methods
        ' but somehow didn't have a stand alone method for this. Currently is in the Single Calculation Report class
        ' but should probably be moved out somewhere else
        Private Shared Sub AddMetalTonnes(ByRef table As DataTable)
            If Not table.IsUnpivotedTable Then
                Throw New NotSupportedException("Metal units can only be added to unpivoted tables")
            End If

            If Not table.Columns.Contains("Tonnes") Then
                Throw New Exception("Tonnes column required in order to calculate metal tonnes")
            End If

            If Not table.Columns.Contains("AttributeValueTonnes") Then
                table.Columns.Add("AttributeValueTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                Dim attributeName = row.AsString("Attribute")
                Dim attributeValue = row.AsDblN("AttributeValue")
                Dim tonnes = row.AsDblN("Tonnes")

                If tonnes Is Nothing Or attributeValue Is Nothing Then
                    row("AttributeValueTonnes") = 0.0
                ElseIf attributeName = "Tonnes" Or attributeName = "Volume" Then
                    row("AttributeValueTonnes") = tonnes
                Else
                    row("AttributeValueTonnes") = tonnes.Value * attributeValue.Value / 100.0
                End If

            Next

        End Sub

    End Class

    Module FactorDataTableExtensions

        ' finds the referenceRow in the DataTable with the tagId given. Will match on date, location, materialType, and productSize
        <Runtime.CompilerServices.Extension()>
        Public Function GetOtherCalculationsForRow(ByRef rows As IEnumerable(Of DataRow), ByVal referenceRow As DataRow) As List(Of DataRow)
            ' throw an exception if it finds more than one row. If it finds none, just return Nothing
            Dim matches = rows.Where(Function(r) _
                                r.AsDate("DateFrom") = referenceRow.AsDate("DateFrom") AndAlso
                                r.AsInt("LocationId") = referenceRow.AsInt("LocationId") AndAlso
                                r.AsInt("MaterialTypeId") = referenceRow.AsInt("MaterialTypeId") AndAlso
                                r("ProductSize").ToString = referenceRow("ProductSize").ToString AndAlso
                                r("ReportTagId").ToString <> referenceRow("ReportTagId").ToString
                            ).ToList
            Return matches
        End Function
    End Module

End Namespace

