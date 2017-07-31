Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

Namespace ReportDefinitions
    Public Class ErrorContributionEngine
        ''' <summary>
        ''' Prepare a datatable to store additional error contribution information
        ''' </summary>
        ''' <param name="table">table to be appended</param>
        Private Shared Sub AddAndPrepareErrorContributionColumns(ByRef table As DataTable)
            If Not table.IsUnpivotedTable Then Throw New Exception("This method is only valid on unpivoted tables")

            ' use AddTonnesValuesToUnpivotedTable to get this data into the table
            If Not table.Columns.Contains("Tonnes") Then
                Throw New Exception("This method requires the Tonnes column to have been added")
            End If

            If Not table.Columns.Contains("TonnesDifference") Then
                Throw New Exception("Factor difference columns (such as TonnesDifference) are required to calculate error contribution")
            End If

            ' this gives the error contribution in tonnes or metal units for that row
            If Not table.Columns.Contains("FactorErrorContribution") Then
                table.Columns.Add("FactorErrorContribution", GetType(Double))
            End If

            ' this gives the error contribution in tonnes or metal units for that row; but only for rows where the contribution should not be included in the aggregation of contributors
            ' this is used for parent rows; however this value may be copied over to FactorErrorContribution where there are no other contributors
            If Not table.Columns.Contains("FactorErrorContributionReserve") Then
                table.Columns.Add("FactorErrorContributionReserve", GetType(Double))
            End If

            ' this is the error contribution as a percent of the total error. So it is the FactorErrorContribution
            ' for this location, on the sum of the FactorErrorContribution for the parent location (maybe later this
            ' method will support calculating the error contribution with other breakdowns, but at the moment it only
            ' supports doing this on a per location basis)
            If Not table.Columns.Contains("FactorErrorContributionPct") Then
                table.Columns.Add("FactorErrorContributionPct", GetType(Double))
            End If

            ' this contains the total metal tonnes for all the locations in the grouping (for that grade). This will
            ' allow converting the error contribution tonnes into a percentage later on
            If Not table.Columns.Contains("TotalTonnes") Then
                table.Columns.Add("TotalTonnes", GetType(Double))
            End If

            ' this is the total of FactorErrorContribution for all locations
            If Not table.Columns.Contains("TotalAbsoluteErrorTonnes") Then
                table.Columns.Add("TotalAbsoluteErrorTonnes", GetType(Double))
            End If

            ' for a Factor row the 'Tonnes' field will contain the value of the tonnes FACTOR, not the
            ' actual tonnes value. This contains the tonnes of the predicted value in the factor (ie the
            ' bottom value, ie the Mining Model value if we are talking about F1). 
            '
            ' The value can actually be back calculated from the Factor and the TonnesDifference, it isn't
            ' required to look up the value in a separate row. Of course this requires that the difference 
            ' columns are calculated properly, which is not always the case...
            If Not table.Columns.Contains("FactorTonnes") Then
                table.Columns.Add("FactorTonnes", GetType(Double))
            End If

            ' This is the same as the FactorTonnes field, but it contains the grade, instead of the Tonnes like
            ' the FactorTonnes field.
            If Not table.Columns.Contains("FactorGradeValue") Then
                table.Columns.Add("FactorGradeValue", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                row("TotalTonnes") = 0
                row("FactorErrorContribution") = 0
                row("TotalAbsoluteErrorTonnes") = 0
                row("FactorErrorContributionPct") = 0

                row("FactorTonnes") = 0
                row("FactorGradeValue") = 0
            Next
        End Sub

        ' Calculate error contribution values by Resource Classification and append to a result table.... This allows the error contribution of the data to be plotted
        '
        ' These fields are only applicable to Factor rows (not normal calculations), but this method will
        ' still run no matter what is in the table - the non-factor rows will be ignored.
        '
        ' Foris a description on the justification behind the error contribution calculation, and how the 
        ' calculation  made, please see the one note documentation on the subject.
        '
        Public Shared Sub AddErrorContributionByResourceClassification(ByRef table As DataTable)

            AddAndPrepareErrorContributionColumns(table)
            AddErrorContributionCommon(table)

            ' On the second run through the table we can calculate the error totals, and use this to calculate the 
            ' error contribution percentages (which are needed by the report to work out how big the stacked bars
            ' should be)
            For Each row As DataRow In table.Rows
                If row.AsDblN("FactorErrorContribution") Is Nothing OrElse row.AsDblN("FactorErrorContribution") = 0 Then
                    row("FactorErrorContributionPct") = row("FactorErrorContribution")
                    Continue For
                End If

                If Not row.IsFactorRow Then Continue For

                Dim errorContribution = row.AsDbl("FactorErrorContribution")
                Dim subRows = table.AsEnumerable.GetCorrespondingRowsForResourceClassificationsUnpivoted(row)
                Dim totalErrorTonnes = subRows.
                    Select(Function(r) Math.Abs(r.AsDbl("FactorErrorContribution"))).
                    Sum()

                ' this is the total predicted tonnes for the factor (ie for F1 this would be GC)
                Dim attributeName = row.AsString("Attribute")

                Dim totalMetalTonnesRows = subRows.Select(Function(r) r.AsDblN("FactorTonnes") * r.AsDblN("FactorGradeValue") / 100.0)
                Dim totalMetalTonnes = totalMetalTonnesRows.Sum

                If totalMetalTonnes.HasValue AndAlso totalMetalTonnes > 0 Then
                    row("TotalTonnes") = totalMetalTonnes
                End If

                If totalErrorTonnes > 0 Then
                    row("TotalAbsoluteErrorTonnes") = totalErrorTonnes
                    row("FactorErrorContributionPct") = errorContribution / totalErrorTonnes
                End If
            Next

            ' remove the temporary column no longer required
            table.Columns.Remove("FactorErrorContributionReserve")

        End Sub


        ' Calculate error contribution values by location and append to a result table.... This allows the error contribution of the data to be plotted
        '
        ' These fields are only applicable to Factor rows (not normal calculations), but this method will
        ' still run no matter what is in the table - the non-factor rows will be ignored.
        '
        ' For a description on the justification behind the error contribution calculation, and how the 
        ' calculation is made, please see the one note documentation on the subject.
        '
        Public Shared Sub AddErrorContributionByLocation(ByRef table As DataTable, ByVal parentLocationId As Integer)

            AddAndPrepareErrorContributionColumns(table)
            AddErrorContributionCommon(table, parentLocationId)

            ' On the second run through the table we can calculate the error totals, and use this to calculate the 
            ' error contribution percentages (which are needed by the report to work out how big the stacked bars
            ' should be)
            For Each row As DataRow In table.Rows

                Dim isParentRow = (row.AsInt("LocationId") = parentLocationId)

                If isParentRow Then
                    ' if no data for parent row
                    If row.AsDblN("FactorErrorContributionReserve") Is Nothing OrElse row.AsDblN("FactorErrorContributionReserve") = 0 Then
                        row("FactorErrorContributionPct") = row("FactorErrorContributionReserve")
                        Continue For ' skip
                    End If
                Else
                    ' if no data for child row
                    If row.AsDblN("FactorErrorContribution") Is Nothing OrElse row.AsDblN("FactorErrorContribution") = 0 Then
                        row("FactorErrorContributionPct") = row("FactorErrorContribution")
                        Continue For ' skip
                    End If
                End If

                If Not row.IsFactorRow Then Continue For

                Dim locationRows = table.AsEnumerable.GetCorrespondingRowsForLocationsUnpivoted(row, parentLocationId)

                If isParentRow Then
                    If locationRows.Count > 0 Then
                        ' there are child rows and this is a parent row... skip it (the child rows are where the 
                        ' contribution results will be calculated And displayed)
                        row("FactorErrorContributionPct") = 0
                        Dim totalTonnes = locationRows.Select(Function(r) r.AsDblN("FactorTonnes") * r.AsDblN("FactorGradeValue") / 100.0).Sum()
                        If totalTonnes.HasValue AndAlso totalTonnes > 0 Then row("TotalTonnes") = totalTonnes

                        Continue For ' skip to next row
                    Else
                        ' this is a parent row with no child rows... treat this parent row as the only contributor
                        ' use the error contribution stored in the reserve column and add this row as if it were a child contributor
                        row("FactorErrorContribution") = row("FactorErrorContributionReserve")
                        Dim newLocationRows = New List(Of DataRow)
                        newLocationRows.Add(row)
                        locationRows = newLocationRows
                    End If
                End If

                ' work out the total error based on all matched location rows
                Dim totalErrorTonnes = locationRows.
                                            Select(Function(r) Math.Abs(r.AsDbl("FactorErrorContribution"))).
                                            Sum()

                ' get the contribution of this row
                Dim errorContribution = row.AsDbl("FactorErrorContribution")

                ' this is the total predicted tonnes for the factor (ie for F1 this would be GC)
                Dim attributeName = row.AsString("Attribute")
                Dim totalMetalTonnesRows = locationRows.Select(Function(r) r.AsDblN("FactorTonnes") * r.AsDblN("FactorGradeValue") / 100.0)
                Dim totalMetalTonnes = totalMetalTonnesRows.Sum

                If totalMetalTonnes.HasValue AndAlso totalMetalTonnes > 0 Then
                    row("TotalTonnes") = totalMetalTonnes
                End If

                If totalErrorTonnes > 0 Then
                    row("TotalAbsoluteErrorTonnes") = totalErrorTonnes
                    row("FactorErrorContributionPct") = errorContribution / totalErrorTonnes
                End If
            Next

            ' remove the temporary column no longer required
            table.Columns.Remove("FactorErrorContributionReserve")

        End Sub

        '
        ' This will add the error values in tonnes to the factor DataTable, as well as some other helpful rows. It does
        ' not calculate the error contribution percentages - this is done later, as it depends on which grouping is 
        ' required for the reports
        '
        ' See the GetErrorContributionTonnes method for details on the error contribution formula, but using F1 as an
        ' example it would be like this:
        '
        ' Given:
        '   F1 = GC / MM
        '   Diff = GC - MM
        '
        ' Then the error tonnes are:
        '   Error[Tonnes] = GC[Tonnes] - MM[Tonnes]
        '   Error[Fe] = (Diff[Fe] * MM[Tonnes]) + (0.5 * Diff[Fe] * Diff[Tonnes])
        '
        ' And the Error Percentages for a group would be:
        '   ErrorPct[Fe] = Error[Fe] / SUM(ABS(Error[Fe]))
        '
        Public Shared Sub AddErrorContributionCommon(ByRef table As DataTable, Optional ByVal parentLocationId As Integer = -1)
            Dim byResourceClassification = parentLocationId < 0
            Const factorErrorContributionColumn = "FactorErrorContribution"
            Const factorErrorContributionReserveColumn = "FactorErrorContributionReserve"

            ' we have to loop through the factor rows twice, once to calculate the error contribution, and then again to
            ' calculate any totals - these totals are now calculated in a separate method
            For Each row As DataRow In table.Rows
                Dim attributeName = row.AsString("Attribute")
                Dim factorErrorContributionColumnForThisRow = factorErrorContributionColumn

                If Not row.IsFactorRow Then Continue For
                If Not table.Columns.Contains(attributeName + "Difference") Then Continue For
                If byResourceClassification AndAlso String.IsNullOrEmpty(row.AsString("ResourceClassification")) Then
                    Continue For
                End If

                ' for the location grouping we need to do some special stuff with the error contribution when calculating
                ' it for the parent location, in this case we will store the error contribution data in a different field
                If Not byResourceClassification Then
                    If row.AsInt("LocationId") = parentLocationId Then
                        factorErrorContributionColumnForThisRow = factorErrorContributionReserveColumn
                    End If
                End If

                ' this formula recalculates the tonnes using the factor and the tonnes difference
                ' it can be changed to get either the top or the bottom value of the factor formula
                ' see the OneNote document "How-to Aggregate Factors" for more details on this formula
                '
                ' Example for F1:
                '
                '   MM = difference / (F1 - 1)
                '   GC = difference / (1 - 1 / F1)
                '
                Dim factorTonnes = row.AsDblN("TonnesDifference") / (row.AsDblN("Tonnes") - 1)
                Dim factorGradeValue = GetFactorGradeValue(row, attributeName)
                Dim errorContributionTonnes = GetErrorContributionTonnes(row, attributeName)

                If factorTonnes.HasValue Then
                    row("FactorTonnes") = factorTonnes
                End If

                If factorGradeValue.HasValue Then
                    row("FactorGradeValue") = factorGradeValue
                End If

                If errorContributionTonnes.HasValue Then
                    row(factorErrorContributionColumnForThisRow) = errorContributionTonnes
                End If
            Next
        End Sub

        '
        ' Recalculate the grade value of the factor - either the top or bottom term in the factor calculation
        ' This can be used to calculate the metal units for the row. The formula for the recalculation is the 
        ' same as for tonnes. ee the tomments on GetErrorContributionTonnes or in OneNote under 'How-To Aggregate
        ' Factors' for details on how this works.
        '
        Public Shared Function GetFactorGradeValue(row As DataRow, attributeName As String) As Double?
            If Not row.IsFactorRow Then
                Throw New ArgumentException("Grade value recalculation is only possible on factor rows", "row")
            End If

            If attributeName = "Tonnes" Then
                ' the 'grade' of tonnes is always 100 %, so that when we mulitply it by the tonnes, we will
                ' get the original value
                Return 100.0
            ElseIf attributeName = "Volume" Then
                ' So Volume is a special case because it already stores its value in total units, not as a grade (the
                ' grade would be Density I guess?), so it needs to be stored a bit differently. Later on the Metal units
                ' are calculated by FactorTonnes * FactorGradeValue, we need to make sure that this calculation will 
                ' give the inital volume when its calcuated.
                '
                ' The formula below will calculate a m3/t grade for volume that can be used the same as any other grade to 
                ' calculate error contributions. (This is the same 'inverted density' grade that is used elsewhere in the
                ' app when carrying density grades through the calculations)
                '
                Dim factorBottomTonnes = row.AsDblN("TonnesDifference") / (row.AsDblN("Tonnes") - 1)
                Dim factorVolume = row.AsDblN(attributeName + "Difference") / (row.AsDblN("AttributeValue") - 1)
                Return (factorVolume / factorBottomTonnes) * 100
            Else
                Return row.AsDblN(attributeName + "Difference") / (row.AsDblN("AttributeValue") - 1)
            End If
        End Function

        Public Shared Function GetErrorContributionTonnes(row As DataRow, attributeName As String) As Double?
            If Not row.IsFactorRow Then
                Throw New ArgumentException("error contribution calculation is only possible on factor rows", "row")
            End If

            Dim tonnesDifference = row.AsDblN("TonnesDifference")
            Dim attributeDifference = row.AsDblN(attributeName + "Difference")

            ' this formula recalculates the tonnes using the factor and the tonnes difference
            ' it can be changed to get either the top or the bottom value of the factor formula
            ' see the OneNote document "How-to Aggregate Factors" for more details on this formula
            '
            ' Example for F1:
            '
            '   F1 = GC / MM
            '   MM = difference / (F1 - 1)
            '   GC = difference / (1 - 1 / F1)
            '
            Dim factorBottomTonnes = tonnesDifference / (row.AsDblN("Tonnes") - 1)

            If attributeName <> "Tonnes" AndAlso attributeName <> "Volume" Then
                ' error contribution is the grade error on the factor tonnes + half the grade error on the error in tonnes
                Return ((attributeDifference * factorBottomTonnes) + (0.5 * attributeDifference * tonnesDifference)) / 100
            Else
                Return attributeDifference
            End If
        End Function
    End Class

End Namespace

