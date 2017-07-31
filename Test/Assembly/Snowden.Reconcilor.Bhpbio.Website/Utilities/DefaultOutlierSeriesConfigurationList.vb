Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility


Namespace Utilities
    Public Class DefaultOutlierSeriesConfigurationList
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate
        Private Property ReturnTable As ReconcilorTable

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim excludeColumns() As String = {"id"}

            ReturnTable = New ReconcilorTable(OutlierHelper.ReturnOutlierSeriesDataTable(Resources.ConnectionString, True))
            With ReturnTable
                .ItemDataBoundCallback = AddressOf ItemDataBoundCallbackEventHandler
                .Columns.Add("isActive", New ReconcilorTableColumn("Is " & vbCrLf & "Active"))
                .Columns.Add("Name", New ReconcilorTableColumn("Name"))
                .Columns.Add("byAttribute", New ReconcilorTableColumn("By " & vbCrLf & "Attribute"))
                .Columns.Add("locationGranularity", New ReconcilorTableColumn("Location" & vbCrLf & " Granularity"))
                .Columns.Add("byMaterialType", New ReconcilorTableColumn("By " & vbCrLf & "Material Type"))
                .Columns.Add("byProductSize", New ReconcilorTableColumn("By" & vbCrLf & " Product Size"))
                .Columns.Add("priority", New ReconcilorTableColumn("Priority"))
                .Columns.Add("projectedValueMethod", New ReconcilorTableColumn("Projected" & vbCrLf & "Value Method"))
                .Columns.Add("outlierThresholdValue", New ReconcilorTableColumn("Outlier Threshold " & vbCrLf & " (Std.Dev)"))

                .Columns("outlierThresholdValue").NumericFormat = "N1"
                .ExcludeColumns = excludeColumns
                .ID = "ReturnTable"
                .DataBind()
            End With

            Controls.Add(ReturnTable)
        End Sub
        Private Function ItemDataBoundCallbackEventHandler(ByVal textData As String, ByVal columnName As String,
           ByVal row As DataRow) As String
            Dim cellContent As String = textData

            If columnName.ToUpper() = "PROJECTEDVALUEMETHOD" Then
                Select Case textData
                    Case "RollingAverage"
                        cellContent = "Rolling Average"
                    Case "LinearProjection"
                        cellContent = "Linear Projection"
                End Select
            End If

            Return cellContent
        End Function
    End Class
End Namespace

