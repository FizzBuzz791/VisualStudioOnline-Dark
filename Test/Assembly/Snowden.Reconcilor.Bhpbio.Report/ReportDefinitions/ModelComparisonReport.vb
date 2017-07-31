Namespace ReportDefinitions

    '** Design Note
    ' due to the nature of reporting services being able to only represent a flat data structure
    ' many of these calls are performed twice or more
    ' a good performance improvement will be to provide a caching proxy pattern during successive calls with the same parameters
    ' obviously they will need to expire quickly (< 5 seconds??) as it will quickly become stale due to Recalc changes, underlying data, etc
    ' in an ideal world each subsystem will report when changes occur so things like this can intelligently decide whether to
    ' discard its cache.  oh well!

    Public Class ModelComparisonReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal session As Types.ReportSession, _
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As String, _
         ByVal locationId As Int32, ByVal includeBlockModels As Boolean, _
         ByVal blockModels As String, ByVal includeActuals As Boolean, _
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean, _
         ByVal includeTonnes As Boolean, ByVal grades As String, _
         ByVal lumpFinesBreakdown As Boolean) As DataSet

            Dim result As DataSet
            Dim graph As DataTable
            Dim summary As DataTable
            Dim row As DataRow

            result = session.DalReport.GetBhpbioModelComparisonReport(dateFrom, dateTo, dateBreakdown, _
             locationId, Convert.ToInt16(includeBlockModels), blockModels, _
             Convert.ToInt16(includeActuals), designationMaterialTypeId, includeDesignationMaterialTypeId, _
             Convert.ToInt16(includeTonnes), grades, _
             session.ShouldIncludeLiveData, session.ShouldIncludeApprovedData, _
             lumpFinesBreakdown)

            graph = result.Tables("Graph")
            summary = result.Tables("Summary")

            graph.Columns.Add("ModelTagExtended", GetType(String))

            For Each row In graph.Rows()
                Select Case DirectCast(row("ModelTag"), String)
                    Case "Actual" : row("ModelTagExtended") = "MineProductionActuals"
                    Case "Geology" : row("ModelTagExtended") = "GeologyModel"
                    Case "Grade Control" : row("ModelTagExtended") = "GradeControlModel"
                    Case "Mining" : row("ModelTagExtended") = "MiningModel"
                    Case "Short Term Geology" : row("ModelTagExtended") = "ShortTermGeologyModel"
                    Case Else : row("ModelTagExtended") = DBNull.Value
                End Select
            Next

            summary.Columns.Add("ModelTagExtended", GetType(String))

            For Each row In summary.Rows()
                Select Case DirectCast(row("ModelTag"), String)
                    Case "Actual" : row("ModelTagExtended") = "MineProductionActuals"
                    Case "Geology" : row("ModelTagExtended") = "GeologyModel"
                    Case "Grade Control" : row("ModelTagExtended") = "GradeControlModel"
                    Case "Mining" : row("ModelTagExtended") = "MiningModel"
                    Case "Short Term Geology" : row("ModelTagExtended") = "ShortTermGeologyModel"
                    Case Else : row("ModelTagExtended") = DBNull.Value
                End Select
            Next

            Data.ReportColour.AddPresentationColour(session, graph, "ModelTagExtended")
            Data.ReportColour.AddPresentationColour(session, summary, "ModelTagExtended")

            graph.Columns.Remove("ModelTagExtended")
            summary.Columns.Remove("ModelTagExtended")

            Data.DateBreakdown.AddDateText(graph, Types.ReportBreakdown.None, "CalendarDate", "DateText")

            F1F2F3ReportEngine.FixModelNames(graph)
            F1F2F3ReportEngine.FixModelNames(summary)
            result.AcceptChanges()

            Return result
        End Function
    End Class
End Namespace
