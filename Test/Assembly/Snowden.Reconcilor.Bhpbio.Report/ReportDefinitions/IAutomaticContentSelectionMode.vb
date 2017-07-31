Imports Snowden.Reconcilor.Core

Public Interface IAutomaticContentSelectionMode

    Function GetDataTable(ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factorOption As String, automaticContentSelectionMode As String) As DataTable
End Interface
