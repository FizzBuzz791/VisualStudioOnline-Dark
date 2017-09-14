Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace ReportDefinitions

    Public Class F1F2F3HubReconciliationReport
        Inherits ReportBase

        Public Shared Function GetF1F2F3HubWithGeometReportData(ByVal session As Types.ReportSession,
                                                      ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
                                                      ByVal dateBreakdown As String, ByVal f25Required As Boolean, Optional ByVal productTypeIds As String = Nothing,
                                                      Optional ByVal RFGMRequired As Boolean = False, Optional ByVal RFMMRequired As Boolean = False,
                                                      Optional ByVal RFSTMRequired As Boolean = False) As DataTable

            If session.GeometReportingEnabled Or productTypeIds IsNot Nothing Then
                'session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.ModelMiningBene)
                session.IncludeGeometData = session.IncludeProductSizeBreakdown
            End If

            ' the AS models should only be included in the normal geomet hub report
            ' not the HUB one
            If session.IncludeGeometData AndAlso productTypeIds Is Nothing Then
                session.IncludeAsShippedModelsInHubSet = True
            End If

            If RFGMRequired Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFGM)
            End If

            If RFMMRequired Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFMM)
            End If

            If RFSTMRequired Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFSTM)
            End If

            Dim table = GetF1F2F3HubReportData(session, locationId, dateFrom, dateTo, dateBreakdown, f25Required, productTypeIds)

            ' if we have lump/fines in the table, then we want to have geomet as well
            If session.IncludeProductSizeBreakdown AndAlso session.GeometReportingEnabled AndAlso productTypeIds Is Nothing Then
                Dim geomet = New F1F2F3GeometDataHelper(session)
                table = geomet.AddGeometData(table)
                F1F2F3GeometDataHelper.RemoveMoistureData(table)
            End If

            If productTypeIds IsNot Nothing Then
                table = F1F2F3ReportEngine.AddTagOrderNo(table)
            End If

            Return table
        End Function

        '
        ' WARNING: This method is used by mulitple reports, so think hard when making changes to it
        '
        Public Shared Function GetF1F2F3HubReportData(ByVal session As Types.ReportSession,
                                                      ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
                                                      ByVal dateBreakdown As String, ByVal f25Required As Boolean, Optional ByVal productTypeIds As String = Nothing,
                                                      Optional RFGMRequired As Boolean = False, Optional RFMMRequired As Boolean = False, Optional RFSTMRequired As Boolean = False) As DataTable

            If Not (dateBreakdown = "MONTH" Or dateBreakdown = "QUARTER") Then
                Throw New NotSupportedException("Only MONTH/QUARTER are supported for this report.")
            End If

            If (locationId > 0 AndAlso Not String.IsNullOrEmpty(productTypeIds)) Then
                Throw New NotSupportedException("Either a location or one or more product types must be specified, however both must not be specified at the same time.")
            End If

            If (session.IncludeProductSizeBreakdown AndAlso Not String.IsNullOrEmpty(productTypeIds)) Then
                Throw New NotSupportedException("Product Size breakdown is not supported when reporting by Product Size.")
            End If

            Dim resultTable As DataTable = Nothing

            If String.IsNullOrEmpty(productTypeIds) Then
                resultTable = F1F2F3ReportEngine.GetFactorsExtendedForLocation(session, locationId, dateFrom, dateTo)

                Dim dummyProductType As New ProductType()
                dummyProductType.ProductTypeID = 0
                dummyProductType.ProductTypeCode = String.Empty
                dummyProductType.Description = String.Empty

                ' to make report definition easier, always include the product type columns even when no product type reporting is included
                F1F2F3ReportEngine.AddProductTypeColumns(resultTable, dummyProductType)
            Else
                resultTable = F1F2F3ReportEngine.GetFactorsForProductTypes(session, dateFrom, dateTo, productTypeIds, False)
                resultTable.DefaultView.Sort = "Order_No"
                resultTable = resultTable.DefaultView.ToTable()
            End If

            AddFlags(resultTable)
            Return resultTable

        End Function

        Public Shared Sub AddFlags(ByRef table As DataTable)
            If (Not table.Columns.Contains("HasMoisture")) Then
                table.Columns.Add("HasMoisture", GetType(Boolean))
            End If

            If (Not table.Columns.Contains("HasGrades")) Then
                table.Columns.Add("HasGrades", GetType(Boolean))
            End If

            If (Not table.Columns.Contains("HasUltrafines")) Then
                table.Columns.Add("HasUltrafines", GetType(Boolean))
            End If

            For Each row As DataRow In table.Rows
                row("HasMoisture") = Not FactorList.IsCellNA(row("ReportTagId").ToString, "H2O", row("ProductSize").ToString)
                row("HasUltrafines") = Not FactorList.IsCellNA(row("ReportTagId").ToString(), "Ultrafines", row("ProductSize").ToString())
                row("HasGrades") = FactorList.HasGrades(row.AsString("ReportTagId"), row.AsString("ProductSize"))
            Next
        End Sub
    End Class
End Namespace