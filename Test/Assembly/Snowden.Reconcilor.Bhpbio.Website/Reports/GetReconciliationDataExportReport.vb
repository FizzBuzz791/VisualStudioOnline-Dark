Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports OfficeOpenXml
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.F1F2F3DataExtensions

Namespace Reports
    Public Class GetReconciliationDataExportReport
        Inherits WebpageTemplates.ReportsAjaxTemplate

        Public Shared ParameterNameColumn As String = "Parameter Name"
        Public Shared ParameterValueColumn As String = "Parameter Value"

        Public Shared ReadOnly DataExportNumericFormat As String = "#,##0.00"
        Public Shared ReadOnly DataExportDateFormat As String = "dd-MMM-yyyy"

        Public Property UseForwardEstimates As Boolean = False

        Public Shared Function GetMonthPickerDate(ByVal monthPart As String, ByVal yearPart As String) As DateTime
            Dim dateString As String = String.Format("1-{0}-{1}", monthPart, yearPart)

            Dim data As DateTime

            If DateTime.TryParse(dateString, data) Then
                Return data
            Else
                Throw New ArgumentException(String.Format("Date {0} could not be parsed.", dateString))
            End If
        End Function

        Public Shared Function CreateParametersTable(ByVal locationName As String, ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
            ByVal approvalSelection As String, ByVal dateBreakdown As String, ByVal lumpsFinesBreakdown As String,
            ByVal includeSublocations As String, ByVal productTypeCode As String, Optional ByVal includeResourceClassifications As String = Nothing) As DataTable

            Dim paramsTable As DataTable = New DataTable()

            paramsTable.Columns.Add(GetReconciliationDataExportReport.ParameterNameColumn)
            paramsTable.Columns.Add(GetReconciliationDataExportReport.ParameterValueColumn)

            Dim row As DataRow = paramsTable.NewRow()

            If Not String.IsNullOrEmpty(locationName) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Location"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = locationName
                paramsTable.Rows.Add(row)
            End If

            If Not String.IsNullOrEmpty(productTypeCode) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Product Type"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = productTypeCode
                paramsTable.Rows.Add(row)
            End If

            row = paramsTable.NewRow()
            row(GetReconciliationDataExportReport.ParameterNameColumn) = "Start Month"
            row(GetReconciliationDataExportReport.ParameterValueColumn) = dateFrom.ToString(DataExportDateFormat)
            paramsTable.Rows.Add(row)

            row = paramsTable.NewRow()
            row(GetReconciliationDataExportReport.ParameterNameColumn) = "End Month"
            row(GetReconciliationDataExportReport.ParameterValueColumn) = dateTo.ToString(DataExportDateFormat)
            paramsTable.Rows.Add(row)

            Dim approval As String
            Select Case approvalSelection
                Case DataExportFilterBox.Approved
                    approval = "Approved Only"
                Case DataExportFilterBox.Live
                    approval = "Live Only"
                Case DataExportFilterBox.CombinedApprovedLive
                    approval = "Combined"
                Case Else
                    approval = "Unspecified"
            End Select

            row = paramsTable.NewRow()
            row(GetReconciliationDataExportReport.ParameterNameColumn) = "Approval Status"
            row(GetReconciliationDataExportReport.ParameterValueColumn) = approval
            paramsTable.Rows.Add(row)

            If Not String.IsNullOrEmpty(dateBreakdown) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Date Breakdown"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = dateBreakdown
                paramsTable.Rows.Add(row)
            End If

            If Not String.IsNullOrEmpty(lumpsFinesBreakdown) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Include Lump/Fines"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = lumpsFinesBreakdown
                paramsTable.Rows.Add(row)
            End If

            If Not String.IsNullOrEmpty(includeSublocations) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Include Sublocations"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = includeSublocations
                paramsTable.Rows.Add(row)
            End If

            If Not String.IsNullOrEmpty(includeResourceClassifications) Then
                row = paramsTable.NewRow()
                row(GetReconciliationDataExportReport.ParameterNameColumn) = "Include Resource Classifications"
                row(GetReconciliationDataExportReport.ParameterValueColumn) = includeResourceClassifications
                paramsTable.Rows.Add(row)
            End If


            Return paramsTable
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                Me.GenerateReport()
            Catch ex As Exception
                Dim message = String.Format("Error generating report: {0}", ex.Message)
                Dim script = String.Format("alert('{0}');{1};", message.Replace("'", "\'"), "window.history.back()")
                Dim r = String.Format("<script type='text/javascript'>{0}</script>", script)

                Response.Write(r)
            End Try

            Response.Flush()
            Response.End()
        End Sub

        Private Sub GenerateReport()
            ' load the parameters from the request
            Dim productTypeCode = RequestAsString("productTypeCode")
            Dim locationId = RequestAsInt32("locationId")
            Dim dateFrom = DateTime.Parse(RequestAsString("MonthValueStart"))
            Dim dateTo = DateTime.Parse(RequestAsString("MonthValueEnd"))

            ' for some reason the end date cane come through as the start of the month, instead of the end
            ' probably to make the js easier to write. We detect this case and handle it
            If dateTo.Day = 1 Then
                dateTo = dateTo.AddMonths(1).AddDays(-1)
            End If

            Dim dateBreakdown = RequestAsString("dateBreakdown")
            Dim lumpsFinesBreakdown = RequestAsBoolean("lumpsFinesBreakdown")
            Dim includeSublocations = RequestAsBoolean("includeSublocations")
            Dim includeResourceClassifications = RequestAsBoolean("includeResourceClassifications")
            Dim approvalStatus As String = RequestAsString("reportApprovalContext")
            Dim reportApprovalContext = Me.ReportContextFromString(approvalStatus)
            Me.UseForwardEstimates = RequestAsBoolean("useForwardEstimates")

            Me.SaveUserSettings(locationId, dateFrom, dateTo, dateBreakdown, lumpsFinesBreakdown, includeSublocations, approvalStatus, productTypeCode, includeResourceClassifications)
            Me.GenerateReport(productTypeCode, locationId, dateFrom, dateTo, dateBreakdown, lumpsFinesBreakdown, includeSublocations, reportApprovalContext, includeResourceClassifications)
        End Sub

        Private Sub GenerateReport(ByVal productTypeCode As String, ByVal locationId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As String, ByVal lumpsFinesBreakdown As Boolean, ByVal includeSublocations As Boolean, ByVal reportApprovalContext As Report.Types.ReportContext, ByVal includeResourceClassifications As Boolean)

            Dim approvalStatus As String = RequestAsString("reportApprovalContext")
            Dim service As New Snowden.Reconcilor.Bhpbio.Report.WebService
            service.SetOverrideReportContext(reportApprovalContext)

            If locationId > 0 Then
                ' the location changes during the reporting peroid. In this case we want to throw an exception
                ' and alert the user. There might be mulitple location changes, but we will only alert them about
                ' the first one. This will be the one with the 'lowest' location_type_id (ie, closest to the root)
                Dim locationChanges = service.GetLocationChanges(locationId, dateFrom, dateTo)
                If locationChanges.Rows.Count > 0 Then
                    Dim changeRow = locationChanges.Rows(0)
                    ' get the date that the location changed, by comparing it to the period start and end date
                    Dim changeDate = If(changeRow.AsDate("IncludeStart") <> dateFrom, changeRow.AsDate("IncludeStart"), changeRow.AsDate("IncludeEnd"))
                    Dim changeMessage = String.Format("{0} moved in the location hierarchy on {1}.", changeRow("Name"), changeDate.ToString("dd-MMM-yyyy"))
                    Throw New Exception(changeMessage)
                End If
            End If

            Dim attributes = service.GetAttributes() ' get the number formats etc
            Dim data = service.GetBhpbioReconciliationDataExportDataExcelReady(productTypeCode, locationId, dateFrom, dateTo, dateBreakdown, lumpsFinesBreakdown, includeSublocations, includeResourceClassifications, UseForwardEstimates)
            Dim locationName = service.GetLocationCommentByDate(locationId, dateFrom)
            Dim fileName = "Reconciliation_Data_Export.xlsx"

            If productTypeCode IsNot Nothing Then
                'This is a Product Reconciliation Data Export 
                fileName = "Product_" & fileName
                If data.Columns("ProductSize") IsNot Nothing Then
                    data.Columns.Remove("ProductSize")
                End If
                If data.Columns("Density") IsNot Nothing Then
                    data.Columns.Remove("Density")
                End If
                If data.Columns("Volume k(m3)") IsNot Nothing Then
                    data.Columns.Remove("Volume k(m3)")
                End If
            End If

            Using package As New ExcelPackage()
                Dim dataWorkSheet = package.Workbook.Worksheets.Add("Data")
                dataWorkSheet.Cells("A1").LoadFromDataTable(data, True)

                Dim paramsWorkSheet = package.Workbook.Worksheets.Add("Parameters")
                paramsWorkSheet.Cells("A1").LoadFromDataTable(CreateParametersTable(locationName, dateFrom, dateTo, approvalStatus,
                    dateBreakdown, lumpsFinesBreakdown.ToString, includeSublocations.ToString, productTypeCode, includeResourceClassifications.ToString), True)
                paramsWorkSheet.Cells(paramsWorkSheet.Dimension.Address).AutoFitColumns()

                ' now we need to make sure that everything is formatted correctly
                SetExcelFormats(dataWorkSheet, data, attributes)
                dataWorkSheet.Cells(dataWorkSheet.Dimension.Address).AutoFitColumns()

                Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream"
                Response.AppendHeader("Content-Disposition", String.Format("attachment; filename={0}", fileName))
                Response.BinaryWrite(package.GetAsByteArray())
            End Using
        End Sub

        Private Sub SaveUserSettings(ByVal locationId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As String,
            ByVal includeLumpFines As Boolean, ByVal includeSublocations As Boolean, ByVal approvalStatus As String, ByVal productTypeCode As String, ByVal includeResourceClassifications As Boolean)

            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Date_From", dateFrom.ToString(Application("DateFormat").ToString))
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Date_To", dateTo.ToString(Application("DateFormat").ToString))
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Date_Breakdown", dateBreakdown)
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Approval_Status", approvalStatus.ToString)
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Lump_Fines", includeLumpFines.ToString)
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Sublocations", includeSublocations.ToString)
            Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Resource_Classifications", includeResourceClassifications.ToString)

            If locationId > 0 Then
                Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_Location_Id", locationId.ToString)
            End If

            If productTypeCode IsNot Nothing Then
                Resources.UserSecurity.SetSetting("Reconciliation_Data_Export_ProductPicker", productTypeCode.ToString)
            End If

        End Sub

        Private Sub SetExcelFormats(ByRef ws As ExcelWorksheet, ByRef data As DataTable, Optional ByRef attributes As DataTable = Nothing)
            Dim i As Integer = 1
            Dim excludedAttributes = New String() {"Tonnes", "Volume"}

            Dim dateFormat As String = CType(Application("DateFormat"), String)
            If dateFormat Is Nothing Then
                dateFormat = DataExportDateFormat
            End If

            ' we set the format of the column based off the datatype in the table. suprised that it
            ' doesn't do this automatically already, but oh well
            For Each c As DataColumn In data.Columns()
                If c.DataType Is GetType(Double) Or c.DataType Is GetType(Integer) Then
                    Dim numberFormat As String = DataExportNumericFormat

                    ' maybe there was something passed in for this column in the attr table? In this case we want to use
                    ' this to generate the number format
                    If (Not attributes Is Nothing AndAlso Not excludedAttributes.Contains(c.ColumnName)) Then
                        Dim attr As DataRow = attributes.Select(String.Format("AttributeName = '{0}'", c.ColumnName)).FirstOrDefault()
                        If Not attr Is Nothing Then
                            Dim precision As Integer = CType(attr("DisplayPrecision"), Integer)
                            numberFormat = Me.GetExcelNumberFormatString(precision)
                        End If
                    End If

                    If c.ColumnName.ToUpper = "FE" Then numberFormat = Me.GetExcelNumberFormatString(3)

                    ws.Column(i).Style.Numberformat.Format = numberFormat
                ElseIf c.DataType Is GetType(DateTime) Then
                    ws.Column(i).Style.Numberformat.Format = dateFormat
                End If

                i = i + 1
            Next

        End Sub

        ' Execl uses a different number format to the stand .net librarys, so we can't use codes like 'N2', 'D1', 'P1'
        ' etc. We need to convert to the excel format, which looks like this: '#,##0.00'
        Private Function GetExcelNumberFormatString(ByVal displayPrecision As Integer) As String
            Dim baseFormat = "#,##0"

            If (displayPrecision > 0) Then
                baseFormat += "."
                For i As Integer = 0 To displayPrecision - 1
                    baseFormat += "0"
                Next
            End If

            Return baseFormat
        End Function

        ' probably this exists as some sort of library function somewhere, but I couldn't find it
        ' so quicker just to reimplement it here
        Private Function ReportContextFromString(ByVal reportContextString As String) As Report.Types.ReportContext
            If reportContextString = "ApprovalListing" Then
                Return Report.Types.ReportContext.ApprovalListing
            ElseIf reportContextString = "LiveOnly" Then
                Return Report.Types.ReportContext.LiveOnly
            Else
                Return Report.Types.ReportContext.Standard
            End If
        End Function

    End Class
End Namespace
