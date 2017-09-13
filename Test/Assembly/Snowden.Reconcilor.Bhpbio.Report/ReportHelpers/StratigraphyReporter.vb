Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportHelpers
    Public Class StratigraphyReporter : Inherits Reporter : Implements IStratigraphyReporter
        Private Property LowestStratigraphyLevel As Integer

        Sub New(lowestStratigraphyLevel As Integer)
            Me.LowestStratigraphyLevel = lowestStratigraphyLevel
        End Sub

        Public Sub AddStratigraphyContextDataForF1OrF15(ByRef masterTable As DataTable, locationId As Integer, 
                                                        startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown) _
                                                        Implements IStratigraphyReporter.AddStratigraphyContextDataForF1OrF15

            ' Get all the "concrete"/factor rows. These have the data we need.
            Dim stratigraphyRows = masterTable.Rows.Cast (Of DataRow).Where(Function(r)
                ' ReSharper disable RedundantParentheses
                Return (r.AsString("CalcId") = ModelGradeControl.CalculationId Or
                        r.AsString("CalcId") = ModelGradeControlSTGM.CalculationId) And
                        r.AsInt(ColumnNames.STRAT_LEVEL) = LowestStratigraphyLevel
                ' ReSharper restore RedundantParentheses
            End Function).ToList()

            For Each stratRow In stratigraphyRows
                AddContextRowAsNonFactorRow(stratRow, masterTable, String.Empty, stratRow.AsDbl("AttributeValue"),
                                            stratRow.AsString(ColumnNames.STRAT_NUM), "Stratigraphy", "Stratigraphy",
                                            stratRow.AsString(ColumnNames.STRAT_NUM), 
                                            stratRow.AsString(ColumnNames.STRAT_NUM))
            Next

            Dim stratRows = masterTable.AsEnumerable.Where(Function(r) r.AsString("ContextCategory") = "Stratigraphy")
            CombineSmallSamplesIntoOtherCategory(stratRows)
        End Sub

        Public Sub AddStratigraphyContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, 
                                                       startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown) _
                                                       Implements IStratigraphyReporter.AddStratigraphyContextDataForF2OrF3
            Throw New NotImplementedException
        End Sub

        Private Shared Sub CombineSmallSamplesIntoOtherCategory(stratRows As IEnumerable(Of DataRow))
            Dim stratGroups = stratRows.GroupBy(Function(r) $"{r.AsString("Attribute")}-{r.AsDate("DateFrom"):yyyy-MM-dd}").ToList()

            For Each group in stratGroups
                Dim totalTonnes = group.Sum(Function(r) r.AsDblN("Tonnes"))

                For Each row In group
                    If row.AsDblN("Tonnes") / totalTonnes < 0.05 Then
                        row("ContextGrouping") = "Other"
                        row("ContextGroupingLabel") = "Other"
                        row("PresentationColor") = "#C0C0C0"
                    End If
                Next
            Next
        End Sub
    End Class
End NameSpace