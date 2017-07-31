Imports Snowden.Reconcilor.Bhpbio.Report.Types

Module DateBreakdownHelper
    Public Function GetEndDate(ByVal month As DateTime, ByVal dateBreakdown As Types.ReportBreakdown) As DateTime
        Dim monthOffset = 1

        If (dateBreakdown = ReportBreakdown.CalendarQuarter) Then
            monthOffset = 3
        ElseIf (dateBreakdown = ReportBreakdown.Yearly) Then
            monthOffset = 12
        End If

        Return month.AddMonths(monthOffset).AddDays(-1)
    End Function
End Module
