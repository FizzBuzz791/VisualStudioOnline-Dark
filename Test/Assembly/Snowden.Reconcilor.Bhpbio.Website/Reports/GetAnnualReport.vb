Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports OfficeOpenXml
Imports OfficeOpenXml.Drawing
Imports OfficeOpenXml.Style
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Reports
    Public Class GetAnnualReport
        Inherits WebpageTemplates.ReportsAjaxTemplate
        Private _context As ReportContext = ReportContext.Standard

        Private resultrows As Integer = 0

        Private _percentageFormat As String = "#,##0.00%"
        Private ReadOnly DataExportNumericFormat As String = "#,##0.00"
        Private ReadOnly DataExportDateFormat As String = "dd-MMM-yyyy"

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                Using session = GetReportSession()
                    Me.GenerateReport(session)
                End Using

            Catch ex As Exception
                Dim message = String.Format("Error generating report: {0}", ex.Message)
                Dim script = String.Format("alert('{0}');{1};", message.Replace("'", "\'"), "window.history.back()")
                Dim r = String.Format("<script type='text/javascript'>{0}</script>", script)

                Response.Write(r)
            End Try

            Response.Flush()
            Response.End()
        End Sub

        Private Function GetReportSession() As ReportSession
            Dim session = New ReportSession()
            session.SetupDal(Resources.ConnectionString)
            session.Context = ReportContext.Standard
            Return session
        End Function


        Private Sub GenerateReport(session As ReportSession)

            ' load the parameters from the request
            Dim dateFrom = DateBreakdown.GetDateFromUsingQuarter(RequestAsString("QuarterPickerPartStart"), RequestAsString("MonthPickerYearPartStart"))
            Dim dateTo = DateBreakdown.GetDateToUsingQuarter(RequestAsString("QuarterPickerPartEnd"), RequestAsString("MonthPickerYearPartEnd"))

            Me.SaveUserSettings(1, dateFrom, dateTo)
            Dim hubs As DataTable = session.DalUtility.GetBhpbioLocationChildrenNameWithOverride(1, dateFrom, dateTo)
            Dim period As String = dateFrom.ToString("dd-MMM-yy") & " to " & dateTo.ToString("dd-MMM-yy")

            Using package As New ExcelPackage()

                ''Parameters
                Dim paramsWorkSheet = package.Workbook.Worksheets.Add("Parameters")
                paramsWorkSheet.Cells("A1").Value = "Parameters"
                paramsWorkSheet.Cells("A1:B1").Merge = True
                paramsWorkSheet.Cells("A1:B1").Style.HorizontalAlignment = ExcelHorizontalAlignment.Center
                paramsWorkSheet.Cells("A2").Value = "Report Format: "
                paramsWorkSheet.Cells("B2").Value = "Microsoft Excel File (Formatted)"
                paramsWorkSheet.Cells("A3").Value = "Date Breakdown: "
                paramsWorkSheet.Cells("B3").Value = "Quarter"
                paramsWorkSheet.Cells("A4").Value = "Date From:"
                paramsWorkSheet.Cells("B4").Value = "Quarter" & RequestAsString("QuarterPickerPartStart").Replace("Q", " ") & " " & RequestAsString("MonthPickerYearPartStart")
                paramsWorkSheet.Cells("A5").Value = "Date To:"
                paramsWorkSheet.Cells("B5").Value = "Quarter" & RequestAsString("QuarterPickerPartEnd").Replace("Q", " ") & " " & RequestAsString("MonthPickerYearPartEnd")
                paramsWorkSheet.Cells("A1:B1").Style.Border.Top.Style = ExcelBorderStyle.Thick
                paramsWorkSheet.Cells("A1:B1").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
                paramsWorkSheet.Cells("A5:B5").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
                paramsWorkSheet.Cells("A1:A5").Style.Border.Left.Style = ExcelBorderStyle.Thick
                paramsWorkSheet.Cells("A1:A5").Style.Border.Right.Style = ExcelBorderStyle.Medium
                paramsWorkSheet.Cells("B1:B5").Style.Border.Right.Style = ExcelBorderStyle.Thick
                paramsWorkSheet.Cells(paramsWorkSheet.Dimension.Address).AutoFitColumns()

                'Yearly WAIO
                Dim dtw As DataTable = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(session, 1, dateFrom, dateTo, "QUARTER", False)
                Dim waioYearlyWorkSheet = package.Workbook.Worksheets.Add("WAIO - Yearly Reconciliation")

                'Border and Style
                Dim headerRowCount = 2
                Dim tableReport As DataTable = CreateYearlyReport(period, dtw)
                Dim tableSide As DataTable = CreateSideTableNumbers("WAIO Overall", tableReport)
                SetExcelFormats(waioYearlyWorkSheet, tableSide, 1)
                SetExcelFormats(waioYearlyWorkSheet, tableReport, 9)
                FormatYearlyTables(waioYearlyWorkSheet, tableReport.Rows.Count + headerRowCount, "WAIO")

                waioYearlyWorkSheet.Cells("A2").LoadFromDataTable(tableReport, True)
                waioYearlyWorkSheet.Cells("I2").LoadFromDataTable(tableSide, True)
                PaintCell(session, waioYearlyWorkSheet, dtw, 1)

                waioYearlyWorkSheet.Cells(waioYearlyWorkSheet.Dimension.Address).AutoFitColumns()

                ' this is to make sure that the F3 mining model is included
                If Not session.OptionalCalculationTypesToInclude.Contains(Calc.CalcType.ModelMiningBene) Then
                    session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.ModelMiningBene)
                End If


                ''Yearly per Hub
                For Each locationRow As DataRow In hubs.Rows
                    Dim locationId = locationRow.AsInt("Location_Id")
                    Dim locationName = locationRow.AsString("Name")

                    Dim dty As DataTable = Nothing
                    Dim dth As DataTable = Nothing

                    Using dataSession = GetReportSession()
                        dty = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(dataSession, locationId, dateFrom, dateTo, "QUARTER", False)
                        dth = ReconciliationDataExportReport.GetF1F2F3AllLocationsReconciliationReportData(dataSession, locationId, dateFrom, dateTo, "QUARTER", False)
                    End Using

                    Dim hubYearlyWorkSheet = package.Workbook.Worksheets.Add(locationName & " - Yearly Reconciliation")

                    'Border and Style
                    Dim tableReporthub As DataTable = CreateYearlyReport(period, dty)
                    'Dim tableSidehub As DataTable = CreateSideTableNumbers(row(1).ToString(), tableReporthub, Int32.Parse(row(0).ToString()))
                    Dim tableSidehub As DataTable = CreateSideTableNumbers(locationName, tableReporthub)
                    hubYearlyWorkSheet.Cells("A2").LoadFromDataTable(tableReporthub, True)
                    hubYearlyWorkSheet.Cells("I2").LoadFromDataTable(tableSidehub, True)

                    PaintCell(session, hubYearlyWorkSheet, dty, locationId)

                    SetExcelFormats(hubYearlyWorkSheet, tableReporthub, 1)
                    SetExcelFormats(hubYearlyWorkSheet, tableReporthub, 9)
                    FormatYearlyTables(hubYearlyWorkSheet, tableReporthub.Rows.Count + headerRowCount, locationName)
                    hubYearlyWorkSheet.Cells(hubYearlyWorkSheet.Dimension.Address).AutoFitColumns()

                    ''Historical per Hub
                    If dth IsNot Nothing Then
                        Dim hubHistoricalWorkSheet = package.Workbook.Worksheets.Add(locationName & " - Historical Recoveries")

                        'Handles NJV specific rules
                        If locationName = "NJV" Then

                            Dim startIndex = resultrows + 5

                            'Inject data into tables
                            hubHistoricalWorkSheet.Cells("A2").LoadFromDataTable(CreateHistoricalReport(period, dth, "F1MiningModel"), True)
                            hubHistoricalWorkSheet.Cells("J2").LoadFromDataTable(CreateHistoricalReport(period, dth, "F2MineProductionExpitEqulivent"), True)
                            hubHistoricalWorkSheet.Cells(hubHistoricalWorkSheet.Dimension.Address).AutoFitColumns()

                            SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F1MiningModel"), 1)
                            SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F2MineProductionExpitEqulivent"), 10)

                            'hubHistoricalWorkSheet.Cells("A" & startIndex + 1).LoadFromDataTable(CreateHistoricalReport(period, dth, "F3MiningModel"), True)
                            'hubHistoricalWorkSheet.Cells("J" & startIndex + 1).LoadFromDataTable(CreateHistoricalReport(period, dth, "F2MineProductionActuals"), True)

                            'SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F3MiningModel"), 1)
                            'SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F2MineProductionActuals"), 10)

                            'hubHistoricalWorkSheet.Cells("A" & startIndex & ":H" & startIndex).Value = "Mining Model (Total Ore includes Bene Product)"
                            'hubHistoricalWorkSheet.Cells("J" & startIndex & ":Q" & startIndex).Value = "Actual (Total Ore includes Bene Product)"

                            'Border and Style
                            FormatHistoricalTables(hubHistoricalWorkSheet, startIndex)
                            hubHistoricalWorkSheet.Cells("A1:H1").Value = "Mining Model (Total Ore includes Bene Feed)"
                            hubHistoricalWorkSheet.Cells("J1:Q1").Value = "Actual (Total Ore includes Bene Feed)"

                        Else 'Handles other Hubs
                            'Add Actual Content
                            hubHistoricalWorkSheet.Cells("A2").LoadFromDataTable(CreateHistoricalReport(period, dth, "F1MiningModel"), True)
                            hubHistoricalWorkSheet.Cells("J2").LoadFromDataTable(CreateHistoricalReport(period, dth, "F2MineProductionExpitEqulivent"), True)
                            hubHistoricalWorkSheet.Cells(hubHistoricalWorkSheet.Dimension.Address).AutoFitColumns()
                            SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F1MiningModel"), 1)
                            SetExcelFormats(hubHistoricalWorkSheet, CreateHistoricalReport(period, dth, "F2MineProductionExpitEqulivent"), 10)
                            'Border and Style
                            FormatHistoricalTables(hubHistoricalWorkSheet, 0)
                        End If

                    End If
                Next
                Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream"
                Response.AppendHeader("Content-Disposition", String.Format("attachment; filename={0}", "Annual_Report_Data_Export.xlsx"))
                Response.BinaryWrite(package.GetAsByteArray())
            End Using
        End Sub

        Private Sub SaveUserSettings(ByVal locationId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime)
            Resources.UserSecurity.SetSetting("AnnualReport_Export_Date_From", dateFrom.ToString(Application("DateFormat").ToString))
            Resources.UserSecurity.SetSetting("AnnualReport_Export_Date_To", dateTo.ToString(Application("DateFormat").ToString))
        End Sub

        Private Sub FormatHistoricalTables(ByRef workSheet As ExcelWorksheet, ByRef startindex As Integer)

            workSheet.Cells("A1:H1").Value = "Mining Model"
            workSheet.Cells("J1:Q1").Value = "Actual"

            workSheet.Cells("A1:H1").Merge = True
            workSheet.Cells("A1:H1").Style.HorizontalAlignment = ExcelHorizontalAlignment.Center
            workSheet.Cells("J1:Q1").Merge = True
            workSheet.Cells("J1:Q1").Style.HorizontalAlignment = ExcelHorizontalAlignment.Center
            workSheet.Cells("A1:H1").Style.Border.Top.Style = ExcelBorderStyle.Thick
            workSheet.Cells("A1:H1").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("J1:Q1").Style.Border.Top.Style = ExcelBorderStyle.Thick
            workSheet.Cells("A" & resultrows + 2 & ":H" & resultrows + 2).Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("J" & resultrows + 2 & ":Q" & resultrows + 2).Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("J1:Q1").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("H1:H" & resultrows + 2).Style.Border.Right.Style = ExcelBorderStyle.Thick
            workSheet.Cells("A1:A" & resultrows + 2).Style.Border.Left.Style = ExcelBorderStyle.Thick
            workSheet.Cells("J1:J" & resultrows + 2).Style.Border.Left.Style = ExcelBorderStyle.Thick
            workSheet.Cells("Q1:Q" & resultrows + 2).Style.Border.Right.Style = ExcelBorderStyle.Thick

            For i As Integer = 2 To resultrows + 2
                workSheet.Cells("A" & i.ToString() & ":G" & i.ToString()).Style.Border.Right.Style = ExcelBorderStyle.Medium
                workSheet.Cells("J" & i.ToString() & ":P" & i.ToString()).Style.Border.Right.Style = ExcelBorderStyle.Medium
            Next

        End Sub

        Private Sub FormatYearlyTables(ByRef workSheet As ExcelWorksheet, ByRef totalrows As Integer, ByRef hubTitle As String)

            workSheet.Cells("A1:G1").Style.Border.Top.Style = ExcelBorderStyle.Thick
            workSheet.Cells("A1:G1").Merge = True
            workSheet.Cells("A2:G2").Style.Border.Top.Style = ExcelBorderStyle.Medium
            workSheet.Cells("A2:G2").Style.Border.Bottom.Style = ExcelBorderStyle.Medium
            workSheet.Cells("A2:A" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("A1:A" & totalrows).Style.Border.Left.Style = ExcelBorderStyle.Thick
            workSheet.Cells("B2:B" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("C2:C" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("D2:D" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("E2:E" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("F2:F" & totalrows).Style.Border.Right.Style = ExcelBorderStyle.Medium
            workSheet.Cells("A" & totalrows + 1 & ":G" & totalrows + 1).Style.Border.Top.Style = ExcelBorderStyle.Thick
            workSheet.Cells("H1:H" & totalrows).Style.Border.Left.Style = ExcelBorderStyle.Thick
            workSheet.Cells("A1").Value = hubTitle
            'Side tables
            workSheet.Cells("I2:O2").Style.Border.Top.Style = ExcelBorderStyle.Thick
            workSheet.Cells("I2:O2").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("I5:O5").Style.Border.Bottom.Style = ExcelBorderStyle.Thick
            workSheet.Cells("I2:I5").Style.Border.Left.Style = ExcelBorderStyle.Thick
            workSheet.Cells("O2:O5").Style.Border.Right.Style = ExcelBorderStyle.Thick
            For i As Integer = 3 To 5
                workSheet.Cells("I" & i.ToString() & ":N" & i.ToString()).Style.Border.Right.Style = ExcelBorderStyle.Medium
            Next

        End Sub
        Private Sub SetExcelFormats(ByRef workSheet As ExcelWorksheet, ByRef data As DataTable, ByRef index As Integer)

            Dim dateFormat As String = CType(Application("DateFormat"), String)
            If dateFormat Is Nothing Then
                dateFormat = DataExportDateFormat
            End If

            For Each column As DataColumn In data.Columns()
                If column.ColumnName.Contains("Percent") Then
                    workSheet.Column(index).Style.Numberformat.Format = _percentageFormat
                ElseIf column.ColumnName.Contains("tonnes") Then
                    workSheet.Column(index).Style.Numberformat.Format = DataExportNumericFormat
                ElseIf column.DataType Is GetType(Double) Or column.DataType Is GetType(Integer) Then
					Dim gradeName = column.ColumnName.Replace(" %", "")
					Dim format = F1F2F3ReportEngine.GetAttributeValueFormat(gradeName, gradeName.ToUpper() = "FE")
					Dim decimals As Integer

					If (Integer.TryParse(format.Replace("N", ""), decimals) AndAlso decimals > 0) Then
						workSheet.Column(index).Style.Numberformat.Format = "#,##0." & (New String("0"c, decimals))
					Else
						workSheet.Column(index).Style.Numberformat.Format = DataExportNumericFormat
					End If

                ElseIf column.DataType Is GetType(DateTime) Then
                    workSheet.Column(index).Style.Numberformat.Format = dateFormat
                End If

                index += 1
            Next

        End Sub

        Private Sub CheckThreshold(ByRef thresholds As DataTable, ByRef workSheet As ExcelWorksheet, ByVal row As DataRow, ByVal cell As String)

            Dim range As ExcelRange = workSheet.Cells(cell)

            For Each attributeName In New String() {"Tonnes", "Fe", "P", "SiO2", "Al2O3", "LOI"}
                range.Style.Fill.PatternType = ExcelFillStyle.Solid

                Dim thresholdValue = F1F2F3ReportEngine.GetThresholdValue(row, thresholds, attributeName)

                If thresholdValue IsNot Nothing Then
                    If thresholdValue = "Low" Then
                        range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Green)
                    ElseIf thresholdValue = "Medium" Then
                        range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Orange)
                    ElseIf thresholdValue = "High" Then
                        range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Red)
                    End If
                End If

                range = workSheet.Cells(range.Offset(0, 1).Address)
            Next
        End Sub

        Private Sub PaintCell(ByRef session As ReportSession, ByRef workSheet As ExcelWorksheet, ByRef table As DataTable, ByVal locationId As Integer)
            Dim thresholds = Data.GradeProperties.GetFAttributeProperties(session, locationId)

            For Each row As DataRow In table.Rows
                Dim calcId = row.AsString("CalcId")

                If calcId = "F1Factor" Then
                    CheckThreshold(thresholds, workSheet, row, "J3")
                ElseIf calcId = "F2Factor" Then
                    CheckThreshold(thresholds, workSheet, row, "J4")
                ElseIf calcId = "F3Factor" Then
                    CheckThreshold(thresholds, workSheet, row, "J5")
                End If
            Next
        End Sub
        Private Function CreateSideTableNumbers(ByVal hubname As String, ByVal table As DataTable) As DataTable
            Dim resultTable As New DataTable()

            resultTable = table.Clone()
            Dim tagid() As String = {"F1 - Grade Control Model / Mining Model", "F2 - Mine Production (Expit) / Grade Control Model", "F3 - Ore Shipped / Mining Model Shipping Equivalent"}

            For Each s As String In tagid
                For Each row As DataRow In table.Rows
                    If row(0).ToString() = s Then
                        resultTable.ImportRow(row)
                    End If
                Next
            Next
            resultTable.Columns(0).Caption = hubname
            Return resultTable

        End Function
        Private Function CreateYearlyReport(ByVal period As String, ByVal table As DataTable) As DataTable

            Dim yearlyReportTagIds = New String() {
                "GeologyModel",
                "MiningModel",
                "GradeControlModel",
                "MineProductionExpitEqulivent",
                "MiningModelCrusherEquivalent",
                "SitePostCrusherStockpileDelta",
                "HubPostCrusherStockpileDelta",
                "PostCrusherStockpileDelta",
                "PortStockpileDelta",
                "PortBlendedAdjustment",
                "MiningModelShippingEquivalent",
                "OreShipped",
                "F1Factor",
                "F2Factor",
                "F3Factor"
            }

            Dim resultTable As New DataTable()
            resultTable.Columns.Add(period, GetType(String))
            resultTable.Columns.Add("kTonnes", GetType(Double))
            Dim gradeNamesForExport() As String = CalculationResultRecord.GradeNames.Where(Function(name) Not CalculationResultRecord.GradeNamesNotApplicableForReconciliationExport.Contains(name)).ToArray()
            Dim gradeNamesForGradeTonnesExport() As String = gradeNamesForExport.Where(Function(name) Not CalculationResultRecord.GradeNamesNotApplicableForGradeTonnesCalculation.Contains(name)).ToArray()

            For Each gradeName As String In From gradeName1 In gradeNamesForExport Where gradeName1 <> "H2O" And gradeName1 <> "Density"
                resultTable.Columns.Add(gradeName + " %", GetType(Double))
            Next

            For Each row As DataRow In table.Rows()
                ' not all the rows go into the table, only the standard set of calculations
                ' (these come from a GLD maybe?)
                If Not yearlyReportTagIds.Contains(row.AsString("CalcId")) OrElse row.AsString("Description").Contains("All Materials") Then
                    Continue For
                End If

                Dim newRow = resultTable.NewRow()
                newRow(period) = row("Description")

                Dim tonnes As Double = 0
                If row.HasValue("Tonnes") Then
                    tonnes = row.AsDbl("Tonnes") 'Double.Parse(row("Tonnes").ToString())
                End If

                If Not row.IsFactorRow AndAlso Not row.IsGeometRow Then
                    tonnes /= 1000
                End If

                newRow("kTonnes") = tonnes
                For Each gradeItem In gradeNamesForExport
                    If gradeItem <> "H2O" And gradeItem <> "Density" Then
                        If row.HasValue(gradeItem) Then
                            newRow(gradeItem + " %") = row.AsDblN(gradeItem)
                        End If
                    End If
                Next
                resultTable.Rows.Add(newRow)
            Next
            Return resultTable
        End Function
        Private Function CreateHistoricalReport(ByVal period As String, ByVal table As DataTable, ByVal type As String) As DataTable

            Dim resultTable As New DataTable()

            resultTable.Columns.Add("Quarter", GetType(String))
            resultTable.Columns.Add("Mwt", GetType(Double))
            resultTable.Columns.Add("kTonnes", GetType(Double))
            Dim gradeNamesForExport() As String = CalculationResultRecord.GradeNames.Where(Function(name) Not CalculationResultRecord.GradeNamesNotApplicableForReconciliationExport.Contains(name)).ToArray()

            For Each gradeName As String In From gradeName1 In gradeNamesForExport Where gradeName1 <> "H2O" And gradeName1 <> "Density"
                resultTable.Columns.Add(gradeName + " %", GetType(Double))
            Next

            For Each row As DataRow In table.Rows()
                Dim newRow = resultTable.NewRow()
                If row("ReportTagId").ToString() = type Then
					
                    newRow("Quarter") = (Date.Parse(row(11).ToString())).ToString("dd-MMM-yy") & " To " & (Date.Parse(row(12).ToString())).ToString("dd-MMM-yy")

                    Dim tonnes As Double = 0
                    If Not IsDBNull(row("Tonnes")) Then
                        tonnes = Double.Parse(row("Tonnes").ToString())
                    End If
                    If Not row.IsFactorRow AndAlso Not row.IsGeometRow Then
                        tonnes /= 1000
                    End If
                    newRow("kTonnes") = tonnes
                    newRow("Mwt") = (tonnes / 1000)
                    For Each gradeItem In gradeNamesForExport
                        If gradeItem <> "H2O" And gradeItem <> "Density" Then
                            If Not IsDBNull(row(gradeItem)) Then
                                Dim val = CType(row(gradeItem), Double)
                                newRow(gradeItem + " %") = val
                            End If
                        End If
                    Next
                    resultTable.Rows.Add(newRow)
                End If
            Next

			If(resultTable.Rows.Count > 0)Then
				Dim totalRow = resultTable.NewRow()
				Dim totalTonnes = resultTable.AsEnumerable.Sum(Function(r) r.Field(Of Double?)("kTonnes"))
				
				totalRow("Quarter") = "Total"
				totalRow("kTonnes") = totalTonnes
				totalRow("Mwt") = (totalTonnes / 1000)
				
                For Each gradeItem In gradeNamesForExport
                    If resultTable.Columns.Contains(gradeItem + " %") Then
                        Dim val = resultTable.AsEnumerable.Sum(Function(r) r.Field(Of Double?)("kTonnes") * r.Field(Of Double?)(gradeItem + " %") / totalTonnes)
                        totalRow(gradeItem + " %") = val
                    End If
                Next

				resultTable.Rows.Add(totalRow)
			End If

            resultrows = resultTable.Rows.Count
            Return resultTable
        End Function
    End Class
End Namespace
