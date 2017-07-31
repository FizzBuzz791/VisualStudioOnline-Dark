
Namespace ReportDefinitions

    Public Class SampleCoverageReport

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
           ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal groupBy As String) As DataTable

            Dim reportData As DataTable

            reportData = session.DalReport.GetBhpbioSampleCoverageReport(locationId, dateFrom, dateTo, groupBy)

            reportData.TableName = "SampleCoverage"

            Return reportData
        End Function
    End Class

End Namespace
