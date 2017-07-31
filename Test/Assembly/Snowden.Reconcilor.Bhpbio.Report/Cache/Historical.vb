Namespace Cache

    Public Class Historical
        Inherits Cache.DataCache

        Public Sub New(ByVal session As Types.ReportSession)
            MyBase.New(session)
        End Sub

        Protected Overrides Function AcquireFromDatabase(ByVal startDate As Date, _
         ByVal endDate As Date, ByVal dateBreakdownText As String, ByVal locationId As Integer, _
            ByVal childLocations As Boolean) As System.Data.DataSet
            Return Session.DalReport.GetBhpbioReportDataHistorical(startDate, endDate, _
             dateBreakdownText, locationId, childLocations)
        End Function

        Public Function GetHistoricalData(ByVal calcId As String) As DataSet
            Dim historicalData As DataSet = RetrieveData().Copy()
            Dim values As DataTable = historicalData.Tables("Value")
            Dim grades As DataTable = historicalData.Tables("Grade")
            Dim deleteValues As DataRow() = values.Select(String.Format("CalcId <> '{0}'", calcId))
            Dim deleteGrades As DataRow() = grades.Select(String.Format("CalcId <> '{0}'", calcId))
            Dim row As DataRow

            For Each row In deleteValues
                values.Rows.Remove(row)
            Next

            For Each row In deleteGrades
                grades.Rows.Remove(row)
            Next

            Return historicalData
        End Function

    End Class
End Namespace

