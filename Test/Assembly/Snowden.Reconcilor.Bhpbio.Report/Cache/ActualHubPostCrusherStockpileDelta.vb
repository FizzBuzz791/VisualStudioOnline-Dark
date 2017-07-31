﻿Namespace Cache

    Public Class ActualHubPostCrusherStockpileDelta
        Inherits Cache.DataCache

        Public Sub New(ByVal session As Types.ReportSession)
            MyBase.New(session)
        End Sub

        Protected Overrides Function AcquireFromDatabase(ByVal startDate As Date, _
         ByVal endDate As Date, ByVal dateBreakdownText As String, ByVal locationId As Integer, _
            ByVal childLocations As Boolean) As System.Data.DataSet
            Return Session.DalReport.GetBhpbioReportDataHubPostCrusherStockpileDelta(startDate, endDate, _
             dateBreakdownText, locationId, childLocations, _
             Session.ShouldIncludeLiveData, Session.ShouldIncludeApprovedData)
        End Function
    End Class

End Namespace
