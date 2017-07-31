Namespace Cache

    Public Class ActualExpitToStockpile
        Inherits Cache.DataCache

        Public Sub New(ByVal session As Types.ReportSession)
            MyBase.New(session)
        End Sub

        Protected Overrides Function AcquireFromDatabase(ByVal startDate As Date, _
         ByVal endDate As Date, ByVal dateBreakdownText As String, ByVal locationId As Integer, _
            ByVal childLocations As Boolean) As System.Data.DataSet

            Dim data As DataSet = Session.DalReport.GetBhpbioReportDataActualExpitToStockpile(startDate, endDate, _
                dateBreakdownText, locationId, childLocations, _
                Session.ShouldIncludeLiveData, Session.ShouldIncludeApprovedData)

            ' the Actual-Y doesn't have a H2O grade, so we need to null those out
            ' we could get these grades from the db, by looking for the type 'moisture', but leave this
            ' refactoring for later
            Dim MoistureGrades As String() = New String() {"H2O", "H2O-As-Dropped", "H2O-As-Shipped"}
            For Each row As DataRow In data.Tables("Grade").AsEnumerable.Where(Function(r As DataRow) MoistureGrades.Contains(r("GradeName").ToString)).ToArray()
                row("GradeValue") = DBNull.Value
            Next

            Return data
        End Function
    End Class

End Namespace
