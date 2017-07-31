Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports OfficeOpenXml

Namespace Reports
    Public Class GetBlastblockOreTypeDataExportReport
        Inherits WebpageTemplates.ReportsAjaxTemplate

        Private _percentageFormat As String = "#,##0.00%"
        Private _dalApproval As Database.DalBaseObjects.IApproval

        Public Property DalApproval() As Database.DalBaseObjects.IApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As Database.DalBaseObjects.IApproval)
                _dalApproval = value
            End Set
        End Property

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            If (DalApproval Is Nothing) Then
                DalApproval = New Database.SqlDal.SqlDalApproval(Resources.Connection)
            End If
        End Sub

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
            Dim locationId = RequestAsInt32("locationId")
            Dim approvalSelection = RequestAsString("reportApprovalContext")
            Dim reportApprovalContext = Me.ReportContextFromString(approvalSelection)

            Dim dateFrom = GetReconciliationDataExportReport.GetMonthPickerDate(RequestAsString("MonthPickerMonthPartStart"), RequestAsString("MonthPickerYearPartStart"))
            Dim dateTo = GetReconciliationDataExportReport.GetMonthPickerDate(RequestAsString("MonthPickerMonthPartEnd"), RequestAsString("MonthPickerYearPartEnd"))

            Dim lumpFinesSelection = RequestAsBoolean("lumpsFinesBreakdown")

            Me.SaveUserSettings(locationId, dateFrom, dateTo, approvalSelection, lumpFinesSelection)

            Dim service As New Snowden.Reconcilor.Bhpbio.Report.WebService
            service.SetOverrideReportContext(reportApprovalContext)

            Dim data As DataTable = service.GetBlastblockByOretypeDataExportReport(locationId, dateFrom, dateTo, lumpFinesSelection)
            Dim locationName = service.GetLocationCommentByDate(locationId, dateFrom)

            Using package As New ExcelPackage()
                Dim dataWorkSheet = package.Workbook.Worksheets.Add("Data")
                dataWorkSheet.Cells("A1").LoadFromDataTable(data, True)

                Dim paramsWorkSheet = package.Workbook.Worksheets.Add("Parameters")
                paramsWorkSheet.Cells("A1").LoadFromDataTable(GetReconciliationDataExportReport.CreateParametersTable(locationName,
                    dateFrom, dateTo, approvalSelection, Nothing, lumpFinesSelection.ToString(), Nothing, Nothing), True)
                paramsWorkSheet.Cells(paramsWorkSheet.Dimension.Address).AutoFitColumns()

                ' now we need to make sure that everything is formatted correctly
                SetExcelFormats(dataWorkSheet, data)
                dataWorkSheet.Cells(dataWorkSheet.Dimension.Address).AutoFitColumns()

                Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream"
                Response.AppendHeader("Content-Disposition", String.Format("attachment; filename={0}", "Blastblock_Data_By_Ore_Type_Export.xlsx"))
                Response.BinaryWrite(package.GetAsByteArray())
            End Using
        End Sub

        Private Sub SaveUserSettings(ByVal locationId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal approvalStatus As String, ByVal lumpFinesSelection As Boolean)

            Resources.UserSecurity.SetSetting("Blastblock_OreTyepe_Data_Export_Location_Id", locationId.ToString)
            Resources.UserSecurity.SetSetting("Blastblock_OreTyepe_Data_Export_Date_From", dateFrom.ToString(Application("DateFormat").ToString))
            Resources.UserSecurity.SetSetting("Blastblock_OreTyepe_Data_Export_Date_To", dateTo.ToString(Application("DateFormat").ToString))
            Resources.UserSecurity.SetSetting("Blastblock_OreTyepe_Data_Export_Approval_Status", approvalStatus.ToString)
            Resources.UserSecurity.SetSetting("Blastblock_OreTyepe_Data_Export_Lump_Fines", lumpFinesSelection.ToString)

        End Sub

        Private Sub SetExcelFormats(ByRef workSheet As ExcelWorksheet, ByRef data As DataTable)
            Dim index As Integer = 1

            Dim dateFormat As String = CType(Application("DateFormat"), String)
            If dateFormat Is Nothing Then
                dateFormat = GetReconciliationDataExportReport.DataExportDateFormat
            End If

            ' we set the format of the column based off the datatype in the table; ideally should have all of these
            ' formats as system settings
            For Each column As DataColumn In data.Columns()
                If column.ColumnName.Contains("Percent") Then
                    workSheet.Column(index).Style.Numberformat.Format = _percentageFormat
                ElseIf column.DataType Is GetType(Double) Or column.DataType Is GetType(Integer) Then
                    workSheet.Column(index).Style.Numberformat.Format = GetReconciliationDataExportReport.DataExportNumericFormat
                ElseIf column.DataType Is GetType(DateTime) Then
                    workSheet.Column(index).Style.Numberformat.Format = dateFormat
                End If

                index += 1
            Next

        End Sub

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
