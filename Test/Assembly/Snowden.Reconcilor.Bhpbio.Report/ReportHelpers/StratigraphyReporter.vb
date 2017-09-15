Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
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
        End Sub

        Public Sub AddStratigraphyContextDataForF2OrF3(ByRef masterTable As DataTable, locationId As Integer, 
                                                       startDate As Date, endDate As Date, dateBreakdown As ReportBreakdown, 
                                                       dalReport As ISqlDalReport, includeChildLocations As Boolean,
                                                       includeLiveData As Boolean, includeApprovedData As Boolean, 
                                                       attributeList As String()) _
                                                       Implements IStratigraphyReporter.AddStratigraphyContextDataForF2OrF3

            ' x: Ex-pit Direct To Crusher
            Dim xStratData = dalReport.GetBhpbioReportDataActualDirectFeed(startDate, endDate, dateBreakdown.ToParameterString(), 
                                                                           locationId, includeChildLocations, includeLiveData, 
                                                                           includeApprovedData, LowestStratigraphyLevel)
            ' z: Stockpile To Crusher (makes up the remainder of the F2/F3)
            Dim zData = dalReport.GetBhpbioReportDataActualStockpileToCrusher(startDate, endDate, 
                                                                              dateBreakdown.ToParameterString(), locationId, 
                                                                              includeChildLocations, includeLiveData, 
                                                                              includeApprovedData)

            Dim contextData As New DataTable

            Dim tonnesData = xStratData.Tables(0)
            ' Update some rows to fit the expected data better. Avoids having to mess with the stored proc and anything that 
            ' might rely on it.
            tonnesData.Columns.Add("Grade_Name", GetType(String)).SetDefault("Tonnes")
            tonnesData.Columns.Add("Grade_Value", GetType(Double)).SetDefault(100)

            Dim zTonnes = zData.Tables(0)
            ' Update some rows to fit the expected data better. Avoids having to mess with the stored proc and anything that 
            ' might rely on it.
            zTonnes.Columns.Add("Grade_Name", GetType(String)).SetDefault("Tonnes")
            zTonnes.Columns.Add("Grade_Value", GetType(Double)).SetDefault(100)
            zTonnes.Columns.Add(ColumnNames.STRAT_NUM, GetType(String)).SetDefault("SP to Crusher")
            zTonnes.Columns.Add(ColumnNames.STRAT_LEVEL, GetType(Integer)).SetDefault(LowestStratigraphyLevel)
            tonnesData.Merge(zTonnes)
            contextData.Merge(tonnesData)

            Dim gradesData = xStratData.Tables(1)
            gradesData.Columns.Item("GradeName").ColumnName = "Grade_Name"
            gradesData.Columns.Item("GradeValue").ColumnName = "Grade_Value"
            gradesData.Columns.Add("Tonnes", GetType(Double))
            gradesData.Columns.Add(ColumnNames.DATE_FROM, GetType(DateTime))
            gradesData.Columns.Add(ColumnNames.DATE_TO, GetType(DateTime))

            Dim zGrades = zData.Tables(1)
            zGrades.Columns.Item("GradeName").ColumnName = "Grade_Name"
            zGrades.Columns.Item("GradeValue").ColumnName = "Grade_Value"
            zGrades.Columns.Add("Tonnes", GetType(Double))
            zGrades.Columns.Add(ColumnNames.DATE_FROM, GetType(DateTime))
            zGrades.Columns.Add(ColumnNames.DATE_TO, GetType(DateTime))
            zGrades.Columns.Add(ColumnNames.STRAT_NUM, GetType(String)).SetDefault("SP to Crusher")
            zGrades.Columns.Add(ColumnNames.STRAT_LEVEL, GetType(Integer)).SetDefault(LowestStratigraphyLevel)
            gradesData.Merge(zGrades)

            ' Need to do a bit of data massaging to get the tonnes sorted without messing with the stored proc results directly.
            For Each row As DataRow In gradesData.Rows
                Dim referenceRow = tonnesData.Rows.Cast (Of DataRow).SingleOrDefault(Function (r)
                    Return r.AsDate(ColumnNames.DATE_CAL).Equals(row.AsDate(ColumnNames.DATE_CAL)) _
                        And r.AsString(ColumnNames.PRODUCT_SIZE) = row.AsString(ColumnNames.PRODUCT_SIZE) _
                        And r.AsString(ColumnNames.STRAT_NUM) = row.AsString(ColumnNames.STRAT_NUM)
                End Function)

                row("Tonnes") = referenceRow.AsDbl("Tonnes")
                row(ColumnNames.DATE_FROM) = referenceRow.AsDate(ColumnNames.DATE_FROM)
                row(ColumnNames.DATE_TO) = referenceRow.AsDate(ColumnNames.DATE_TO)
            Next
            contextData.Merge(gradesData)

            For Each row In contextData.Rows.Cast (Of DataRow).Where(
                    Function(r)
                        Return r.AsInt(ColumnNames.STRAT_LEVEL) = LowestStratigraphyLevel _
                            And attributeList.Contains(r.AsString("Grade_Name")) _
                            And r.AsString(ColumnNames.PRODUCT_SIZE) = CalculationConstants.PRODUCT_SIZE_TOTAL
                    End Function)

                AddContextRowAsNonFactorRow(row, masterTable, String.Empty, row.AsDbl("Tonnes"), 
                                            row.AsString(ColumnNames.STRAT_NUM), "Stratigraphy", "Stratigraphy", 
                                            row.AsString(ColumnNames.STRAT_NUM), row.AsString(ColumnNames.STRAT_NUM))
            Next
        End Sub
    End Class
End NameSpace