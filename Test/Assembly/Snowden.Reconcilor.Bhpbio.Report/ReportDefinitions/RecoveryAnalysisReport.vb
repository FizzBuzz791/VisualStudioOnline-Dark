Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace ReportDefinitions

    Public Class RecoveryAnalysisReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal session As Types.ReportSession, _
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
         ByVal dateBreakdown As Types.ReportBreakdown, ByVal locationId As Int32, ByVal includeBlockModels As Boolean, _
         ByVal blockModels As String, ByVal includeActuals As Boolean, _
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean) As DataSet

            Dim result As DataSet
            Dim graph As DataTable
            Dim summary As DataTable
            Dim row As DataRow

            result = session.DalReport.GetBhpbioRecoveryAnalysisReport(dateFrom, dateTo, Types.ReportSession.ConvertReportBreakdown(dateBreakdown), _
             locationId, Convert.ToInt16(includeBlockModels), blockModels, Convert.ToInt16(includeActuals), _
             designationMaterialTypeId, includeDesignationMaterialTypeId, _
            session.ShouldIncludeLiveData, session.ShouldIncludeApprovedData)

            graph = result.Tables("Graph")
            summary = result.Tables("Summary")

            graph.Columns.Add("ComparisonTypeExtended", GetType(String))
            For Each row In graph.Rows()
                Select Case DirectCast(row("ComparisonType"), String)
                    Case "Actual - Grade Control" : row("ComparisonTypeExtended") = "CompareActual/GradeControl"
                    Case "Actual - Mining" : row("ComparisonTypeExtended") = "CompareActual/Mining"
                    Case "Grade Control - Mining" : row("ComparisonTypeExtended") = "CompareGradeControl/Mining"
                    Case "Mining - Geology" : row("ComparisonTypeExtended") = "CompareMining/Geology"
                    Case "Grade Control - Short Term Geology"
                        row("ComparisonType") = "Grade Control - Short Term"
                        row("ComparisonTypeExtended") = "CompareGradeControl/ShortTermGeology"
                    Case Else : row("ComparisonTypeExtended") = DBNull.Value
                End Select
            Next

            summary.Columns.Add("ComparisonTypeExtended", GetType(String))
            For Each row In summary.Rows()
                Select Case DirectCast(row("ComparisonType"), String)
                    Case "Actual - Grade Control" : row("ComparisonTypeExtended") = "CompareActual/GradeControl"
                    Case "Actual - Mining" : row("ComparisonTypeExtended") = "CompareActual/Mining"
                    Case "Grade Control - Mining" : row("ComparisonTypeExtended") = "CompareGradeControl/Mining"
                    Case "Mining - Geology" : row("ComparisonTypeExtended") = "CompareMining/Geology"
                    Case "Grade Control - Short Term Geology"
                        row("ComparisonType") = "Grade Control - Short Term"
                        row("ComparisonTypeExtended") = "CompareGradeControl/ShortTermGeology"
                    Case Else : row("ComparisonTypeExtended") = DBNull.Value
                End Select
            Next

            Data.ReportColour.AddPresentationColour(session, graph, "ComparisonTypeExtended")
            Data.ReportColour.AddPresentationColour(session, summary, "ComparisonTypeExtended")

            graph.Columns.Remove("ComparisonTypeExtended")
            summary.Columns.Remove("ComparisonTypeExtended")

            Data.DateBreakdown.AddDateText(graph, dateBreakdown, "CalendarDate", "DateText")

            result.AcceptChanges()

            Return result
        End Function
    End Class
End Namespace
