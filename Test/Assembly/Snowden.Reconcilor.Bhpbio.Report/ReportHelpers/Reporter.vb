Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace ReportHelpers
    Public MustInherit Class Reporter
        Implements IReporter

        Public Function GetContextGroupingOrder(row As DataRow) As Integer Implements IReporter.GetContextGroupingOrder
            If row.AsString("ContextGrouping") = "Other" Then
                Return 4
            ElseIf row.AsString("ContextGrouping") = "StockpileContext" Then
                Return 5
            ElseIf row.AsString("LocationType") = "Pit" Then
                Return 1
            ElseIf row.AsString("LocationType") = "Stockpile" Then
                Return 2
            ElseIf row.AsString("LocationType") = "SampleCoverage" Then
                If row.AsString("ContextGrouping") = "Unsampled" Then
                    Return 5
                ElseIf row.AsString("ContextGrouping") = "SampledPercentage" Then
                    Return 6
                Else
                    Return 3
                End If
            ElseIf {"Stratigraphy", "Weathering"}.Contains(row.AsString("LocationType")) Then
                Dim contextGrouping = row.AsString("ContextGrouping")
                If contextGrouping = "SP to Crusher"
                    Return 50
                ElseIf contextGrouping = "Undef" Then
                    Return 5
                ElseIf contextGrouping = "H-Cap" Then
                    Return 4
                ElseIf contextGrouping = "Silcrete" Then
                    Return 3
                ElseIf contextGrouping = "Trans" Then
                    Return 2
                ElseIf contextGrouping = "Fresh" Then
                    Return 1
                Else 
                    Return 1 ' This "else" branch covers the Stratigraphy "ordering".
                End If
            Else
                Return 50
            End If
        End Function

        ''' <summary>
        ''' Convert a context row to a factor row (a.k.a. standard row) and add to the master table.
        ''' </summary>
        ''' <param name="sourceRow">Row to convert.</param>
        ''' <param name="masterTable">Table to add converted row to.</param>
        ''' <param name="presentationColor">Color to display on the report. If null or empty, LocationName will be converted to
        '''                                 a color.</param>
        ''' <param name="tonnes">Tonnes to display on the report.</param>
        ''' <param name="contextGrouping">Field to group the context on.</param>
        ''' <param name="locationType">Location Type to assign.</param>
        ''' <param name="contextCategory">Category of the context.</param>
        ''' <param name="contextGroupingLabel">Label for the context grouping.</param>
        Public Sub AddContextRowAsNonFactorRow(sourceRow As DataRow, ByRef masterTable As DataTable, presentationColor As String,
                                               tonnes As Double, contextGrouping As String, locationType As String,
                                               contextCategory As String, contextGroupingLabel As String,
                                               locationName As String) _
                                               Implements IReporter.AddContextRowAsNonFactorRow

            ' If *only* Coverage has been chosen, these rows won't exist in the master table.
            masterTable.Columns.AddIfNeeded("LocationName", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationType", GetType(String)).SetDefault(String.Empty)
            masterTable.Columns.AddIfNeeded("LocationColor", GetType(String)).SetDefault(String.Empty)

            Dim row As DataRow
            If masterTable.AsEnumerable.Any Then
                row = masterTable.AsEnumerable.First.CloneFactorRow(addToTable:=False)
            Else
                row = masterTable.NewRow()
            End If

            row("CalendarDate") = sourceRow("DateFrom")
            row("DateFrom") = sourceRow("DateFrom")
            row("DateTo") = sourceRow("DateTo")
            row("DateText") = CType(sourceRow("DateFrom"), DateTime).ToString("MMMM-yy") ' .AsDate breaks Re# *only* here. NFI why.

            If sourceRow.HasColumn(ColumnNames.LOCATION_ID) Then
                row(ColumnNames.LOCATION_ID) = sourceRow(ColumnNames.LOCATION_ID)
            Else
                row(ColumnNames.LOCATION_ID) = sourceRow(ColumnNames.PARENT_LOCATION_ID)
            End If
            row("LocationName") = locationName
            row("LocationType") = locationType

            row("ContextCategory") = contextCategory
            row("ContextGrouping") = contextGrouping
            row("ContextGroupingLabel") = contextGroupingLabel
            row("PresentationColor") = IIf(String.IsNullOrEmpty(presentationColor), row.AsString("LocationName").AsColor, presentationColor)
            row("LocationColor") = DBNull.Value

            If sourceRow.HasColumn("Grade_Name") Then
                row("Attribute") = sourceRow("Grade_Name")
            Else
                row("Attribute") = sourceRow("Attribute")
            End If
            row("AttributeValue") = 0.0

            row("Type") = 1 ' this means a non-factor row
            row("Tonnes") = tonnes
            If sourceRow.HasColumn("Grade_Value") Then
                row("FactorGradeValueBottom") = sourceRow("Grade_Value")
            Else
                If sourceRow.AsString("Attribute") = "Tonnes" Then
                    row("FactorGradeValueBottom") = 100
                Else
                    row("FactorGradeValueBottom") = sourceRow("AttributeValue")
                End If
            End If
            row("FactorTonnesBottom") = tonnes

            If row.AsString("ContextCategory") = "HaulageContext" AndAlso row.AsString("ContextGroupingLabel").Length > 5 Then
                Dim ln = 5
                Dim s = row.AsString("ContextGroupingLabel").Trim()
                Dim label = s.Substring(s.Length - ln, ln)

                If label.StartsWith("-", StringComparison.Ordinal) OrElse label.StartsWith("_", StringComparison.Ordinal) Then
                    label = label.Substring(1)
                End If

                row("ContextGroupingLabel") = label
            End If

            masterTable.Rows.Add(row)
        End Sub
    End Class
End Namespace