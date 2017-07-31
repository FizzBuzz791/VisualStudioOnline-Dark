Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace ReportDefinitions

    Public Class GradeRecoveryReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal session As Types.ReportSession, _
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
         ByVal locationId As Int32, ByVal includeBlockModels As Boolean, _
         ByVal blockModels As String, ByVal includeActuals As Boolean, _
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean, _
         ByVal includeTonnes As Boolean, ByVal includeVolume As Boolean, ByVal grades As String, _
         ByVal lumpFinesBreakdown As Boolean) As DataSet

            Dim result As DataSet
            Dim graph As DataTable
            Dim summary As DataTable
            Dim row As DataRow

            result = session.DalReport.GetBhpbioGradeRecoveryReport(dateFrom, dateTo, _
             locationId, Convert.ToInt16(includeBlockModels), blockModels, _
             Convert.ToInt16(includeActuals), designationMaterialTypeId, _
            includeDesignationMaterialTypeId, _
            Convert.ToInt16(includeTonnes), Convert.ToInt16(includeVolume), grades, _
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
                    Case "Actual - Grade Control" : row("ModelTagExtended") = "CompareActual/GradeControl"
                    Case "Actual - Mining" : row("ModelTagExtended") = "CompareActual/Mining"
                    Case "Grade Control - Mining" : row("ModelTagExtended") = "CompareGradeControl/Mining"
                    Case "Grade Control - Short Term Geology" : row("ModelTagExtended") = "CompareGradeControl/ShortTermGeology"
                    Case Else : row("ModelTagExtended") = DBNull.Value
                End Select
            Next

            summary.Columns.Add("ModelTagExtended", GetType(String))

            For Each row In summary.Rows()
                Select Case DirectCast(row("Model"), String)
                    Case "Actual" : row("ModelTagExtended") = "MineProductionActuals"
                    Case "Geology" : row("ModelTagExtended") = "GeologyModel"
                    Case "Grade Control" : row("ModelTagExtended") = "GradeControlModel"
                    Case "Mining" : row("ModelTagExtended") = "MiningModel"
                    Case "Short Term Geology" : row("ModelTagExtended") = "ShortTermGeologyModel"
                    Case "Actual - Grade Control" : row("ModelTagExtended") = "CompareActual/GradeControl"
                    Case "Actual - Mining" : row("ModelTagExtended") = "CompareActual/Mining"
                    Case "Grade Control - Mining" : row("ModelTagExtended") = "CompareGradeControl/Mining"
                    Case "Grade Control - Short Term Geology" : row("ModelTagExtended") = "CompareGradeControl/ShortTermGeology"
                    Case Else : row("ModelTagExtended") = DBNull.Value
                End Select
            Next

            Data.ReportColour.AddPresentationColour(session, graph, "ModelTagExtended")
            Data.ReportColour.AddPresentationColour(session, summary, "ModelTagExtended")

            graph.Columns.Remove("ModelTagExtended")
            summary.Columns.Remove("ModelTagExtended")

            F1F2F3ReportEngine.FixModelNames(graph)
            F1F2F3ReportEngine.FixModelNames(summary)

            result.AcceptChanges()
            Return result
        End Function

    End Class
End Namespace
