Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.Reports
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Location = Snowden.Reconcilor.Bhpbio.Report.Data.Location
Imports ReportingServicesReport2005 = Snowden.Reconcilor.Core.WebDevelopment.Reports.ReportingServicesReport2005
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility


Namespace Reports
    Public Class ReportsStandardRender
        Inherits Core.Website.Reports.ReportsStandardRender

#Region "Constants"
        Public Const ParameterWithMarker As String = "_with_"
        Private Const _additionalParameterDelimiter As String = "_"
        Private ReadOnly _attributesToExcludeUnlessExplicitlyAdded As String() = New String() {"H2O", "Volume", "Density", "H2O-As-Shipped", "H2O-As-Dropped"}
        Public Const CHK_RESOURCE_CLASSIFICATION = "chkResourceClassifications_"
#End Region

#Region " Properties "
        Public Const HiddenFieldPrompt As String = "hidefield"
        Private Const StockpileControlId As String = "iStockpile_Id"
        Private Const SingleQuarterSelectControlId As String = "QuarterSelectStartAndEnd"
        Private Const SingleYearSelectControlId As String = "YearSelectStartAndEnd"
        Dim _reportSession As New ReportSession
        Dim _startDateElementName As String = String.Empty
        Dim _startQuarterElementName As String = String.Empty

        Protected Property ReportSession() As ReportSession
            Get
                Return _reportSession
            End Get
            Set(ByVal value As ReportSession)
                _reportSession = value
            End Set
        End Property

        Protected ReadOnly Property ReportDescription() As String
            Get
                If ReportGroup IsNot Nothing Then
                    Return ReportGroup.Title
                Else
                    Return Nothing
                End If
            End Get
        End Property

        Public ReadOnly Property DalUtilityBhpbio() As Database.DalBaseObjects.IUtility
            Get
                Return DirectCast(DalUtility, Database.DalBaseObjects.IUtility)
            End Get
        End Property
#End Region

#Region " Destructors "

        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (disposing) Then
                    If (Not _reportSession Is Nothing) Then
                        _reportSession.Dispose()
                        _reportSession = Nothing
                    End If
                End If
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub

#End Region

        Protected Overrides Sub SetupDalObjects()
            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            ReportForm.Target = Nothing
            Dim footerText = GetParameterPageDisclaimer(Report.Name)

            If footerText IsNot Nothing Then
                ReportGroup.Controls.Add(New LiteralControl(footerText))
            End If
        End Sub

        Protected Function GetParameterPageDisclaimer(reportName As String) As String
            If reportName = "BhpbioFactorsByLocationVsShippingTargetsReport" OrElse reportName = "BhpbioFactorsVsShippingTargetsReport" Then
                Return "* No sources will be plotted on oversize And undersize charts as suitable data Is Not available"
            ElseIf reportName = "BhpbioBlockoutSummaryReport" Or reportName = "BhpbioForwardErrorContributionContextReport" Then
                Return "* Note: this report shows live data only"
            Else
                Return Nothing
            End If

        End Function

        'Override this function if you want to modify your 
        Protected Overrides Sub SetupPageLayout()
            Dim parameter As ReportingServicesReportParameter2005

            'Populate Param's Controls with standard rendered control
            'Moved to here to make it easier to override in inherited render classes
            Report.StandardControlRender()

            'Add the validate Java
            AddJavascriptValidation()

            'Add the Export Format Drop down
            AddExportFormatDropdown(LayoutTable)
            Dim startDateParameter As ReportingServicesReportParameter2005

            If (Report.Name.Contains("Core")) Then
                startDateParameter = (From p In Report.Parameters.Values Where (p.RSParameter.Type = Common.Web.ReportingService2005.ParameterTypeEnum.DateTime AndAlso (p.RSParameter.Name.ToLower() = "startdate" OrElse p.RSParameter.Name.ToLower() = "istartdate"))).FirstOrDefault()

                If (Not startDateParameter Is Nothing) Then
                    _startDateElementName = startDateParameter.RSParameter.Name & "Text"
                End If
            Else
                Dim dateFromNames = New String() {"startdate", "datefrom", "startday"}
                Dim dateParameters = Report.Parameters.Values.Where(Function(p) p.RSParameter.Type = Common.Web.ReportingService2005.ParameterTypeEnum.DateTime)
                startDateParameter = dateParameters.FirstOrDefault(Function(p) dateFromNames.Contains(p.RSParameter.Name.ToLower()))

                If (startDateParameter Is Nothing) Then
                    startDateParameter = (From p In Report.Parameters.Values Where (p.RSParameter.Type = Common.Web.ReportingService2005.ParameterTypeEnum.DateTime AndAlso (p.RSParameter.Name.ToLower() = "dateto"))).FirstOrDefault()
                ElseIf startDateParameter.RSParameter.Name = "StartDay" Then
                    _startDateElementName = "StartDayText"
                Else
                    If Report.Name.ToLower.StartsWith("bhpbioquarterly") Then
                        _startQuarterElementName = String.Format("{0},{1}", SingleQuarterSelectControlId, SingleYearSelectControlId)
                    Else
                        _startQuarterElementName = "DateFromQuarterSelect,DateFromYearSelect"
                    End If
                End If

                If startDateParameter IsNot Nothing AndAlso String.IsNullOrEmpty(_startDateElementName) Then
                    _startDateElementName = "MonthPickerMonthPart" & startDateParameter.RSParameter.Name & ",MonthPickerYearPart" & startDateParameter.RSParameter.Name

                    If (String.IsNullOrEmpty(_startQuarterElementName)) Then
                        If Report.Name.ToLower.StartsWith("bhpbioquarterly") Then
                            _startQuarterElementName = String.Format("{0},{1}", SingleQuarterSelectControlId, SingleYearSelectControlId)
                        Else
                            _startQuarterElementName = "DateToQuarterSelect,DateToYearSelect"
                        End If
                    End If
                End If
            End If

            'Render each param in the collection to the layouttable
            For Each parameter In Report.Parameters.Values
                RenderParameter(parameter)
            Next

            'Add the Submit Row
            AddSubmitRow(LayoutTable)
        End Sub

        Protected Function IsPowerPointReport() As Boolean
            Return Report.Name.ToLower.StartsWith("bhpbioquarterly") Or Report.Name.ToLower.StartsWith("bhpbiomonthly")
        End Function

        Protected Overrides Sub AddExportFormatDropdown(ByVal targetTable As HtmlTableTag)

            With ReportFormatDropdown
                .ID = "ExportFormat"

                If IsPowerPointReport() Then
                    'only provide PowerPoint format for Quarterly (Company/Hub/Site) Reconciliation Reports
                    .Items.Add(New ListItem("PPT - PowerPoint 97-2007 Presentation",
                        Convert.ToInt32(ReportExportFormat.Ppt).ToString))
                    .Items.Add(New ListItem("PPTX - PowerPoint Presentation",
                        Convert.ToInt32(ReportExportFormat.Pptx).ToString))
                Else
                    .Items.Add(New ListItem("Adobe PDF File (best for printing and emailing)",
                        Convert.ToInt32(ReportExportFormat.Pdf).ToString))
                    .Items.Add(New ListItem("Microsoft Excel File (Formatted)",
                        Convert.ToInt32(ReportExportFormat.MicrosoftExcel).ToString))
                    .Items.Add(New ListItem("XML File (data only)",
                        Convert.ToInt32(ReportExportFormat.Xml).ToString))
                    .Items.Add(New ListItem("TIFF Image for Printing (best for image manipulation)",
                        Convert.ToInt32(ReportExportFormat.Tiff).ToString))
                End If

            End With

            'Add to target table
            targetTable.AddCellInNewRow().Controls.Add(New LiteralControl("Report Format:"))
            targetTable.AddCell().Controls.Add(New LiteralControl("&nbsp"))
            targetTable.AddCell().Controls.Add(ReportFormatDropdown)
        End Sub

        Protected Overrides Sub AddJavascriptValidation()
            Dim validateFunction As String = String.Empty
            ReportSession.SetupDal(Resources.ConnectionString)

            Dim validateScript As New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript)
            Dim parsedHistoricalDate As DateTime
            Dim historicalStartDate As String
            Dim systemStartDate As String = Convert.ToDateTime(DalUtility.GetSystemSetting("SYSTEM_START_DATE")).ToString("MM-dd-yyyy")

            ' Obtain the Historical Start Date.
            If DateTime.TryParse(DalUtility.GetSystemSetting("HISTORICAL_START_DATE"), parsedHistoricalDate) Then
                historicalStartDate = parsedHistoricalDate.ToString("MM-dd-yyyy")
            Else
                historicalStartDate = systemStartDate
            End If

            ' get the lump fines cutover date from the settings. If its not there then we use a default of 
            ' Sept-2014
            Dim lumpFinesCutoverDate = Date.Parse("2014-09-01")
            Dim lumpFinesCutoverString = lumpFinesCutoverDate.ToString("MM-dd-yyyy")

            If DateTime.TryParse(DalUtility.GetSystemSetting("LUMP_FINES_CUTOVER_DATE"), lumpFinesCutoverDate) Then
                lumpFinesCutoverString = lumpFinesCutoverDate.ToString("MM-dd-yyyy")
            End If

            Dim defaultValidateFunction As String = " alert('No report validation has been setup.'); return false;"

            Select Case (Report.Name)
                Case "BhpbioModelComparisonReport", "BhpbioDesignationAttributeReport"
                    validateFunction = "return BhpbioValidateReport('','','','','','" + systemStartDate + "');"
                Case "BhpbioRecoveryAnalysisReport"
                    validateFunction = "return BhpbioValidateRecoveryAnalysisReport('" + systemStartDate + "');"
                Case "BhpbioMovementRecoveryReport"
                    validateFunction = "return BhpbioValidateMovementRecoveryReport('" + systemStartDate + "');"
                Case "BhpbioBlastByBlastReconciliationReport"
                    validateFunction = "return BhpbioValidateLocation('BlastLocationId', false, '" + systemStartDate +
                                       "');"
                Case "F1F2F3HUBReconciliationReport"
                    validateFunction = "return BhpbioValidateHubReconciliationReport('LocationId', false, '" +
                                       historicalStartDate + "', '" + systemStartDate + "', '" + historicalStartDate +
                                       "');"
                Case "BhpbioF1F2F3HUBGeometReconciliationReport"
                    validateFunction = String.Format("return BhpbioValidateHubReconciliationReportWithLumpFines('LocationId', false, '{0}', '{1}', '{2}', '{3}');", historicalStartDate, systemStartDate, historicalStartDate, lumpFinesCutoverString)

                Case "BhpbioF1F2F3ReconciliationAttributeReport"
                    validateFunction &= " return BhpbioValidateF1F2F3ByAttributeReport('" + historicalStartDate + "', '" +
                                        systemStartDate + "', '" + historicalStartDate + "');"

                Case "BhpbioF1F2F3ReconciliationProductAttributeReport"
                    validateFunction &= " return BhpbioValidateF1F2F3ByAttributeReportWithLumpFines('" + historicalStartDate + "', '" +
                                        systemStartDate + "', '" + historicalStartDate + "', false, '" + lumpFinesCutoverString + "');"

                Case "BhpbioF1F2F3GeometReconciliationAttributeReport"
                    validateFunction &= String.Format(" return BhpbioValidateF1F2F3GeometByAttributeReport('{0}', '{1}', '{2}', false, '{3}');", historicalStartDate, systemStartDate, historicalStartDate, lumpFinesCutoverString)

                Case "BhpbioFactorsVsTimeDensityReport", "BhpbioFactorsVsTimeMoistureReport", "BhpbioFactorsVsTimeVolumeReport"
                    validateFunction &= String.Format(" return BhpbioValidateF1F2F3ByAttributeReport('{0}', '{1}', '{2}', true);", historicalStartDate, systemStartDate, historicalStartDate)

                Case "BhpbioDensityAnalysisReport"
                    ' Provide an override message when factor selection is missing for the Density Analysis Report (refer to source rather than 'Factor' in this case given that this report now only allows selection of specific components rather than overall factors
                    validateFunction &= String.Format(" return BhpbioValidateF1F2F3ByAttributeReport('{0}', '{1}', '{2}', true, '{3}');", historicalStartDate, systemStartDate, historicalStartDate, "Please select at least one source.")
                Case "BhpbioFactorsVsTimeProductReport"
                    validateFunction &= String.Format(" return BhpbioValidateF1F2F3ByAttributeReportWithLumpFines('{0}', '{1}', '{2}', false,'{3}');", historicalStartDate, systemStartDate, historicalStartDate, lumpFinesCutoverString)

                Case "Bhpbio_Core_Stockpile_Balance_Report"
                    validateFunction &= " return BhpbioValidateStockpileBalanceReport('" + systemStartDate + "');"

                Case "Bhpbio_Core_Haulage_vs_Plant_Report"
                    validateFunction &= String.Format(" return BhpbioValidateHaulageVsPlantReport('{0}');", systemStartDate)

                Case "BhpbioBlockoutSummaryReport"
                    validateFunction &= String.Format(" return BhpbioValidateHaulageVsPlantReport('{0}', true);", systemStartDate)

                Case "BhpbioF1F2F3ReconciliationComparisonReport"
                    validateFunction &= String.Format("return BhpbioValidateF1F2F3ReconciliationComparison('{0}', '{1}', '{2}');", historicalStartDate, systemStartDate, historicalStartDate)

                Case "BhpbioFactorsByLocationVsShippingTargetsReport", "BhpbioFactorsVsShippingTargetsReport"
                    validateFunction &= String.Format("return BhpbioValidateShippingTargetReport('{0}', '{1}', '{2}', '{3}');", historicalStartDate, systemStartDate, historicalStartDate, lumpFinesCutoverString)

                Case "BhpbioF1F2F3ReconciliationLocationComparisonReport"
                    validateFunction &= " return BhpbioValidateF1F2F3ByAttributeReport('" + historicalStartDate + "', '" +
                                        systemStartDate + "', '" + historicalStartDate + "');"

                Case "BhpbioF1F2F3GeometOverviewReconContributionReport"
                    validateFunction &= String.Format(" return BhpbioValidateF1F2F3OverviewReconReport('{0}', {1}, '{2}', '{3}', '{4}', '{5}');", "LocationId", "false", historicalStartDate, systemStartDate, historicalStartDate, lumpFinesCutoverString)

                Case "BhpbioF1F2F3OverviewReconReport", "BhpbioF1F2F3OverviewReconContributionReport"
                    validateFunction = "return BhpbioValidateF1F2F3OverviewReconReport('LocationId', false, '" +
                                       historicalStartDate + "', '" + systemStartDate + "', '" + historicalStartDate +
                                       "');"
                Case "BhpbioF1F2F3ProductReconContributionReport", "BhpbioHUBProductReconciliationReport"

                    validateFunction = "return BhpbioF1F2F3ProductReconContributionReport('" + lumpFinesCutoverString + "','LocationId', false, '" +
                                       historicalStartDate + "', '" + systemStartDate + "', '" + historicalStartDate +
                                       "');"

                Case "BhpbioLiveVersusSummaryReport"
                    validateFunction = "return BhpbioValidateLiveVersusSummaryReport('LocationId', false, '" +
                                       historicalStartDate + "', '" + systemStartDate + "', '" + historicalStartDate +
                                       "');"
                Case "BhpbioBenchErrorByAttributeReport"
                    validateFunction = String.Format("return BhpbioValidateErrorDistributionReport('{0}');", systemStartDate)
                Case "BhpbioSupplyChainMonitoringReport"
                    validateFunction = String.Format("return BhpbioValidateSupplyChainMonitoringReport('{0}');", systemStartDate)
                Case "BhpbioProductSupplyChainMonitoringReport"
                    validateFunction = String.Format("return BhpbioValidateProductSupplyChainMonitoringReport('{0}','{1}');", lumpFinesCutoverString, systemStartDate)
                Case "BhpbioBenchErrorByLocationReport"
                    validateFunction = String.Format("return BhpbioValidateErrorDistributionByLocationReport('{0}');", systemStartDate)
                Case "BhpbioReconciliationRangeReport"
                    validateFunction = String.Format("return BhpbioValidateErrorDistributionRangeReport('{0}');", systemStartDate)
                Case "BhpbioRiskProfileReport"
                    validateFunction = String.Format("return BhpbioValidateRiskProfileReport('{0}');", systemStartDate)
                Case "BhpbioQuarterlySiteReconciliationReport", "BhpbioMonthlySiteReconciliationReport"
                    validateFunction = String.Format("return BhpbioValidateQuarterlyReconciliationReport('Site', '{0}');", Report.Name)
                Case "BhpbioQuarterlyHubReconciliationReport"
                    validateFunction = String.Format("return BhpbioValidateQuarterlyReconciliationReport('Hub,Company', '{0}');", Report.Name)
                Case "BhpbioSupplyChainMoistureReport", "BhpbioDensityReconciliationReport", "BhpbioSampleCoverageReport"
                    validateFunction = "return BhpbioValidateReportLocationAndDateOnly();"
                Case "BhpbioErrorContributionContextReport", "BhpbioForwardErrorContributionContextReport"
                    validateFunction = "return ValidateErrorContributionReport();"
                Case "BhpbioFactorAnalysisReport"
                    validateFunction = "return ValidateFactorAnalysisContextReport();"
                Case "BhpbioFactorsVsTimeResourceClassificationReport"
                    validateFunction = "return ValidateBhpbioFactorsVsTimeResourceClassificationReport();"

                Case Else
                    validateFunction &= defaultValidateFunction
            End Select

            If validateFunction = defaultValidateFunction AndAlso Report.Name.ToLower.StartsWith("bhpbio") Then
                ' just use a default, if the report starts with the bhpbio prefix, so we don't have to change the code
                ' here everytime.
                validateFunction = "return true;"
            End If

            If (validateFunction <> String.Empty) Then
                Dim str = ReportingServicesReport2005.BaseValidateScript
                str = str.Replace("%VALIDATECONDITIONS%", validateFunction)
                validateScript.InnerScript = str

                Controls.Add(validateScript)
            End If


            'F3 Factor should be hidden for these reports if selected breakdown = month
            'Since we dont have the location dropdown this need to be done here.
            If Report.Name = "BhpbioFactorsVsTimeProductReport" Or Report.Name = "BhpbioErrorContributionContextReport" Or Report.Name = "BhpbioForwardErrorContributionContextReport" Then
                Dim hideF3Script As New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript)
                hideF3Script.InnerScript = "HideF3FactoronMonth();"
                Controls.Add(hideF3Script)
            ElseIf Report.Name = "BhpbioFactorsByLocationVsShippingTargetsReport" Or Report.Name = "BhpbioFactorAnalysisReport" Then
                Dim hideF3Script As New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript)
                hideF3Script.InnerScript = "HideF3FactoronMonthRadio();"
                Controls.Add(hideF3Script)
                ' Hide Several Sources for the BhpbioF1F2F3ReconciliationProductAttributeReport if datebreakdown = MONTH
            ElseIf Report.Name = "BhpbioF1F2F3ReconciliationProductAttributeReport" Or Report.Name = "BhpbioFactorsVsShippingTargetsReport" Then
                Dim hideF3Script As New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript)
                hideF3Script.InnerScript = "HideProdReconAttributeMonth();"
                Controls.Add(hideF3Script)
            End If

            If Report.Name = "BhpbioFactorAnalysisReport" Then
                Controls.Add(New HtmlScriptTag().JavaScript("$('input[name=SingleSource]').click(FilterContextForFactorType); FilterContextForFactorType();"))
            End If

        End Sub

        Private Function GetValidLocationTypeList(ByVal maxLocation As String, ByVal minLocation As String) As String
            Dim validLocationTypes As IList
            Dim sb As New StringBuilder

            validLocationTypes = Location.GetLocationParentDescriptionList(maxLocation, minLocation, ReportSession)

            For Each value As String In validLocationTypes
                sb.Append(value)
                sb.Append("|")
            Next

            Return sb.ToString()
        End Function

        Protected Overridable Sub DisplayDateBreakdownControl(ByVal dateKeyDateTo As String, ByVal dateKeyEndDate As String)
            Dim nonParameterControl As Control

            With LayoutTable
                If Not Report.Parameters.ContainsKey("DateBreakdown") Then
                    If Report.Parameters.ContainsKey(dateKeyDateTo) Or Report.Parameters.ContainsKey(dateKeyEndDate) _
                        Then

                        nonParameterControl = RenderBhpbioCustomDatebreakdown("nonParameterDateBreakdown")

                        .AddCellInNewRow().Controls.Add(New LiteralControl("Date Breakdown :"))
                        .CurrentCell.VerticalAlign = VerticalAlign.Top

                        .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                        .CurrentCell.Width = 10

                        .AddCell.Controls.Add(nonParameterControl)
                        .CurrentCell.VerticalAlign = VerticalAlign.Top

                    End If
                End If
            End With
        End Sub

        ''' <summary>
        ''' Adjusting dates if the dateValue is in the last 6 months of the year then increment
        ''' Refactored out of GetYearSelectBox
        ''' </summary>
        ''' <param name="dateValue"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function GetFinancialYear(ByVal dateValue As DateTime) As Integer
            Return If(dateValue.Month <= 6, dateValue.Year, dateValue.Year + 1)
        End Function

        Protected Overridable Function GetYearSelectBox(ByVal systemStartDate As DateTime) As Control
            Dim i As Integer
            Dim financialYearSystemStartDate As Integer
            Dim financialYearCurrentDate As Integer
            Dim yearSelectBox As New SelectBox

            financialYearSystemStartDate = GetFinancialYear(systemStartDate)
            financialYearCurrentDate = GetFinancialYear(DateTime.Now)

            With yearSelectBox

                For i = 0 To financialYearCurrentDate - financialYearSystemStartDate
                    Dim yearToAdd As String = (financialYearSystemStartDate + i).ToString()
                    .Items.Add(New ListItem(yearToAdd, yearToAdd))
                Next i

                'Set Default for SelectBox
                Dim selectedYearListItem As New ListItem
                selectedYearListItem.Text = GetFinancialYear(DateTime.Now).ToString
                selectedYearListItem.Value = GetFinancialYear(DateTime.Now).ToString

                .SelectedIndex = .Items.IndexOf(selectedYearListItem)

            End With

            Return yearSelectBox
        End Function

        Protected Overrides Sub DisplayParameter(ByVal parameter As ReportingServicesReportParameter2005)
            Dim label As String

            If parameter.RSParameter.Prompt <> String.Empty Then
                label = parameter.RSParameter.Prompt
            Else
                label = parameter.RSParameter.Name
            End If

            With LayoutTable

                'If it's a radio control and prompt is string.empty show no label
                If TypeOf (parameter.Control) Is InputRadio And parameter.RSParameter.Prompt = String.Empty Then
                    .AddCellInNewRow().Controls.Add(New LiteralControl(" "))
                Else
                    .AddCellInNewRow().Controls.Add(New LiteralControl(label & ":"))
                End If

                .CurrentCell.VerticalAlign = VerticalAlign.Top
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .CurrentCell.Width = 10

                If TypeOf (parameter.Control) Is DatePicker Then
                    AddDatePickerControl(.AddCell(), parameter)
                ElseIf parameter.RSParameter.Name.ToLower() = StockpileControlId.ToLower() Then
                    Dim stockpileListDiv As New HtmlDivTag
                    stockpileListDiv.ID = "stockpileListDiv"
                    stockpileListDiv.Style.Item("width") = "200px"
                    stockpileListDiv.Controls.Add(DirectCast(parameter.Control, Control))
                    .AddCell.Controls.Add(stockpileListDiv)
                Else
                    .AddCell.Controls.Add(DirectCast(parameter.Control, Control))
                End If

                .CurrentCell.VerticalAlign = VerticalAlign.Top
            End With
        End Sub

        Protected Overridable Sub DisplayQuarterDateControl(ByVal dateControlId As String,
                                                             ByVal systemStartDate As DateTime)
            Dim quarterSelectBox As SelectBox
            Dim yearSelectBox As SelectBox

            Dim periodUserSetting As String
            Dim dateUserSetting As String = String.Empty
            Dim displaySetting As String = "none"

            Dim dateToSet As DateTime

            If Report.Name.ToLower.StartsWith("bhpbioquarterly") Then
                periodUserSetting = "quarter"
            Else
                periodUserSetting = Resources.UserSecurity.GetSetting("Report_Filter_Period", Nothing)
            End If

            quarterSelectBox = DateBreakdown.GetQuarterList(DateTime.Now)
            yearSelectBox = DirectCast(GetYearSelectBox(systemStartDate), SelectBox)

            If Not periodUserSetting Is Nothing Then
                periodUserSetting = periodUserSetting.ToLower()

                If periodUserSetting = "quarter" Then
                    displaySetting = "inline"

                    If dateControlId = "DateFrom" Then
                        dateUserSetting = Resources.UserSecurity.GetSetting("Report_Filter_Date_From", Nothing)
                    ElseIf dateControlId = "DateTo" Then
                        dateUserSetting = Resources.UserSecurity.GetSetting("Report_Filter_Date_To", Nothing)
                    End If

                    If Not dateUserSetting Is Nothing Then
                        Dim dateValue As Date
                        If Date.TryParse(dateUserSetting, dateValue) Then
                            dateToSet = dateValue
                        Else
                            dateToSet = Date.Now
                        End If

                        quarterSelectBox.SelectedValue = DateBreakdown.GetDateToQuarter(dateToSet.Month.ToString())
                        yearSelectBox.SelectedValue = DateBreakdown.ResolveYear(dateToSet).Year.ToString()
                    End If
                End If
            End If

            With quarterSelectBox
                .ID = dateControlId + "QuarterSelect"
                .Style.Item("display") = displaySetting
            End With

            With yearSelectBox
                .ID = dateControlId + "YearSelect"
                .Style.Item("display") = displaySetting
            End With

            With LayoutTable
                If Report.Name.ToLower.StartsWith("bhpbioquarterly") Then
                    'Quarterly (Company/Hub/Site) Reconciliation reports contain only a single quarter selection control and no date break-down control
                    .AddCellInNewRow().Controls.Add(New LiteralControl("Quarter:"))
                    .CurrentCell.VerticalAlign = VerticalAlign.Top

                    .AddCell().Controls.Add(GetHiddenDateBreakdown("QUARTER"))

                    quarterSelectBox.ID = SingleQuarterSelectControlId
                    yearSelectBox.ID = SingleYearSelectControlId

                    .CurrentCell.Width = 10
                    .AddCell.Controls.Add(quarterSelectBox)
                Else
                    .CurrentRow.Cells(2).Controls.Add(quarterSelectBox)
                End If

                .CurrentRow.Cells(2).Controls.Add(yearSelectBox)
            End With
        End Sub

        Private Function GetHiddenDateBreakdown(ByVal breakdown As String) As Control
            Dim nonParamDateBreakdown As HiddenField = New HiddenField()
            nonParamDateBreakdown.ID = "nonParameterDateBreakdown"
            nonParamDateBreakdown.Value = breakdown
            Return nonParamDateBreakdown
        End Function

        ''' <summary>
        ''' Checks if the Report is an F1F2F3 Report
        ''' Refactored out of RenderParameter.
        ''' </summary>
        ''' <param name="reportName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function IsF1F2F3Report(ByVal reportName As String) As Boolean
            If _
                (reportName = "F1F2F3HUBReconciliationReport" Or
                 reportName = "BhpbioF1F2F3ReconciliationAttributeReport" Or
                 reportName = "BhpbioF1F2F3OverviewReconReport" Or
                 reportName = "BhpbioLiveVersusSummaryReport" Or
                 reportName = "BhpbioF1F2F3ReconciliationComparisonReport" Or
                 reportName = "BhpbioF1F2F3OverviewReconContributionReport") Then
                Return True
            Else
                Return False
            End If
        End Function

        ''' <summary>
        ''' Returns the HISTORICAL_START_DATE if it's a valid date and the report is a F1F2F3 Report, otherwise returns SYSTEM_START_DATE
        ''' Refactored out of RenderParameter.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function GetHistoricalStartDate() As DateTime
            Dim systemStartDate As DateTime = Convert.ToDateTime(DalUtility.GetSystemSetting("SYSTEM_START_DATE"))
            Dim historicalDate As String = DalUtility.GetSystemSetting("HISTORICAL_START_DATE")

            Dim parsedHistoricalDate As DateTime
            If IsF1F2F3Report(Report.Name) AndAlso DateTime.TryParse(historicalDate, parsedHistoricalDate) Then
                Return parsedHistoricalDate
            Else
                Return systemStartDate
            End If
        End Function

        Private Sub RenderCoreParameters(ByVal parameter As ReportingServicesReportParameter2005)
            If (parameter.RSParameter.Name.ToLower() = "locationid") Then
                parameter.Control = RenderLocation(parameter)
                parameter.UseCustomRendering = True
                parameter.RSParameter.Prompt = "Location"

                DisplayParameter(parameter)
            ElseIf parameter.RSParameter.Name.ToLower = "isvisible" Then
                Dim visibleCheckBox As InputCheckBox =
                        DirectCast(parameter.Control, InputCheckBox)
                visibleCheckBox.Checked =
                    Boolean.Parse(Resources.UserSecurity.GetSetting("Report_Filter_Is_Visible", "true"))
                MyBase.RenderParameter(parameter)
            ElseIf parameter.RSParameter.Name.ToLower = "isummary" Then
                Dim visibleCheckBox As InputCheckBox =
                        DirectCast(parameter.Control, InputCheckBox)
                visibleCheckBox.Checked =
                    Boolean.Parse(Resources.UserSecurity.GetSetting("Report_Filter_Summary", "true"))
                MyBase.RenderParameter(parameter)
            ElseIf parameter.RSParameter.Name.ToLower = "viewdatawarnings" Or
                   parameter.RSParameter.Name.ToLower = "iviewdatawarnings" Then
                Dim visibleCheckBox As InputCheckBox =
                        DirectCast(parameter.Control, InputCheckBox)
                visibleCheckBox.Checked =
                    Boolean.Parse(Resources.UserSecurity.GetSetting("Report_Filter_Data_Warnings", "true"))
                MyBase.RenderParameter(parameter)
            ElseIf parameter.RSParameter.Name.ToLower = "startdate" Or
                   parameter.RSParameter.Name.ToLower = "istartdate" Then
                Dim startDate As DatePicker = DirectCast(parameter.Control, DatePicker)
                startDate.DateSet = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_From", Date.Now)
                MyBase.RenderParameter(parameter)
            ElseIf parameter.RSParameter.Name.ToLower = "enddate" Or
                   parameter.RSParameter.Name.ToLower = "ienddate" Then
                Dim startDate As DatePicker = DirectCast(parameter.Control, DatePicker)
                startDate.DateSet = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_To", Date.Now)
                MyBase.RenderParameter(parameter)
            Else
                MyBase.RenderParameter(parameter)
            End If
        End Sub

        Private Sub RenderBhpbioParameters(ByVal parameter As ReportingServicesReportParameter2005)
            Dim historicalStartDate As DateTime = GetHistoricalStartDate()

            Dim parameterNameForComparison = parameter.RSParameter.Name.ToLower()
            Dim additionalAttributes As String() = Nothing

            ' if there is a _with_ marker within the parameter name used to include other attributes
            If parameterNameForComparison.Contains(ParameterWithMarker) Then
                ' strip all text from that point out of the name for the purposes of determining how to render
                parameterNameForComparison = parameterNameForComparison.Substring(0, parameter.RSParameter.Name.IndexOf(ParameterWithMarker))

                ' build an array of additional attribute information
                additionalAttributes = parameter.RSParameter.Name.Substring(parameter.RSParameter.Name.IndexOf(ParameterWithMarker) + ParameterWithMarker.Length).Split(New String() {_additionalParameterDelimiter}, StringSplitOptions.RemoveEmptyEntries)
            ElseIf parameterNameForComparison = "attributes" Then
                ' there is nothing in the parameter name for additional attributes, but maybe we have some
                ' hardcoded here in this class as well. GetAdditionalAttributes will return a list of these
                additionalAttributes = GetAdditionalAttributes(Report.Name).ToArray
            End If

            ' some of the downstream methods need attitionalAttr to be null if there is no items
            ' the won't always handle an empty list properly
            If additionalAttributes IsNot Nothing AndAlso additionalAttributes.Count = 0 Then
                additionalAttributes = Nothing
            End If

            Select Case parameterNameForComparison
                Case "tonnes", "includetonnes", "includevolume", "includeblockmodels", "includeactuals",
                    "includedesignationmaterialtypeid", "comparison1isactual",
                    "comparison2isactual", "blastlocationname", "controlmodel", "controllimit"
                    'Do nothing
                Case "datefrom", "startdate"
                    parameter.UseCustomRendering = True
                    If Report.Name.ToLower.StartsWith("bhpbioquarterly") Then
                        'render DateFrom param as quarter selection for Quarterly (Company/Hub/Site) Recon Reports: it will be calculated
                        DisplayQuarterDateControl("DateFrom", historicalStartDate)
                    ElseIf Report.Name.ToLower.StartsWith("bhpbiomonthly") Then
                        parameter.Control = RenderBhpbioMonthRange(parameter, historicalStartDate)
                        LayoutTable.AddCell().Controls.Add(GetHiddenDateBreakdown("MONTH"))
                        DisplayParameter(parameter)
                    Else
                        parameter.Control = RenderBhpbioMonthRange(parameter, historicalStartDate)
                        DisplayDateBreakdownControl("DateFrom", "StartDate")
                        DisplayParameter(parameter)
                        DisplayQuarterDateControl("DateFrom", historicalStartDate)
                    End If
                Case "dateto", "enddate"
                    If Not Report.Name.ToLower.StartsWith("bhpbioquarterly") And Not Report.Name.ToLower.StartsWith("bhpbiomonthly") Then
                        'do not render DateTo param for Quarterly (Company/Hub/Site) Recon Reports: it will be calculated
                        parameter.Control = RenderBhpbioMonthRange(parameter, historicalStartDate)
                        parameter.UseCustomRendering = True

                        If (Report.Name = "BhpbioMovementRecoveryReport") Then
                            DisplayDateBreakdownControl("DateTo", "EndDate")
                        End If

                        DisplayParameter(parameter)
                        DisplayQuarterDateControl("DateTo", historicalStartDate)
                    End If
                Case "startday"
                    Dim startDate As DatePicker = DirectCast(parameter.Control, DatePicker)
                    startDate.DateSet = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_From", Date.Now)
                    MyBase.RenderParameter(parameter)
                Case "endday"
                    Dim startDate As DatePicker = DirectCast(parameter.Control, DatePicker)
                    startDate.DateSet = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_To", Date.Now)
                    MyBase.RenderParameter(parameter)
                Case "locationid"
                    parameter.Control = RenderLocation(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Location"
                    DisplayParameter(parameter)
                Case "datebreakdown"
                    parameter.Control = RenderDateBreakdown(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "designationmaterialtypeid"
                    parameter.Control = RenderBhpbioDesignation(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Designation"
                    DisplayParameter(parameter)
                Case "blockmodels"
                    parameter.Control = RenderBhpbioSource(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Sources"
                    DisplayParameter(parameter)
                Case "grades"
                    parameter.Control = RenderBhpbioGradesTonnes(parameter, additionalAttributes)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Attributes"
                    DisplayParameter(parameter)
                Case "attributes"
                    parameter.Control = RenderBhpbioAttributes(parameter, parameterNameForComparison, additionalAttributes)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Attributes"
                    DisplayParameter(parameter)
                Case "comparison1blockmodelid"
                    parameter.Control = RenderComparisonSelect(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Comparison A"
                    DisplayParameter(parameter)
                Case "comparison2blockmodelid"
                    parameter.Control = RenderComparisonSelect(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Comparison B"
                    DisplayParameter(parameter)
                Case "blastlocationid"
                    parameter.Control = RenderLocation(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Location"
                    DisplayParameter(parameter)
                Case "factors"
                    parameter.Control = RenderBhpbioFactors(parameter)
                    parameter.UseCustomRendering = True
                    parameter.RSParameter.Prompt = "Sources"
                    DisplayParameter(parameter)
                Case "completereport", "withoutheaderfooter", "onlygraphs", "onlytables"
                    parameter.Control = RenderReportFormat(parameter)
                    parameter.UseCustomRendering = True

                    'Only set the prompt on "completereport", then set to string.empty

                    Dim prompt As String = String.Empty
                    If parameter.RSParameter.Name.ToLower() = "completereport" Then
                        prompt = "Display"
                    End If

                    parameter.RSParameter.Prompt = prompt
                    DisplayParameter(parameter)
                Case "singlesource"
                    parameter.Control = RenderSourceRadioList(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "resourceclassifications"
                    parameter.Control = RenderBhpbioResourceClassificationList(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "locationids"
                    parameter.Control = RenderBhpbioLocationSelection(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "producttypeids"
                    parameter.Control = RenderBhpbioProductTypeSelection(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "producttypeid"
                    parameter.Control = RenderBhpbioProductTypeId(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "minimumtonnes"
                    Dim controlTextBox As InputText = DirectCast(parameter.Control, InputText)
                    controlTextBox.Text = Resources.UserSecurity.GetSetting("Minimum_Tonnes", "10000")
                    DisplayParameter(parameter)
                Case "locationbreakdown"
                    Dim locationBreakdown = DirectCast(parameter.Control, SelectBox)
                    locationBreakdown.SelectedValue = Resources.UserSecurity.GetSetting("Report_Location_Breakdown", "4")
                    DisplayParameter(parameter)
                Case "contextselection"
                    parameter.Control = RenderBhpbioContextSelection(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case "blockmodelid1", "blockmodelid2"
                    Dim items = DirectCast(parameter.Control, SelectBox).Items
                    For Each item As ListItem In items
                        item.Text = BlockModels.FormatBlockModelDescription(item.Text)
                    Next
                    MyBase.RenderParameter(parameter)
                Case "reportcontext"
                    'If (Resources.UserSecurity.HasAccess("ADMIN_ROLE")) Then
                    MyBase.RenderParameter(parameter)
                    'End If
                Case "factoroption", "automaticcontentselectionmode"
                    parameter.Control = RenderRadioButton(parameter)
                    parameter.UseCustomRendering = True
                    DisplayParameter(parameter)
                Case Else
                    MyBase.RenderParameter(parameter)
            End Select




        End Sub

        Private Function RenderBhpbioResourceClassificationList(parameter As ReportingServicesReportParameter2005) As Object
            Dim resourceClassifications As List(Of String)
            Dim reportLayout As New HtmlTableTag
            Dim resourceClassificationsHidden As New InputHidden

            resourceClassifications = ResourceClassifcation.ResourceClassificationDescriptions()

            For Each resourceClassification As String In resourceClassifications
                Dim resourceOption = New InputCheckBox

                With resourceOption
                    .ID = CHK_RESOURCE_CLASSIFICATION & resourceClassification
                    .Text = " " & resourceClassification
                End With

                reportLayout.AddCellInNewRow.Controls.Add(resourceOption)

            Next

            With resourceClassificationsHidden
                .ID = parameter.RSParameter.Name
            End With
            reportLayout.AddCellInNewRow.Controls.Add(CreateCheckboxLinks(CHK_RESOURCE_CLASSIFICATION, parameter.RSParameter.Name))
            reportLayout.AddCell.Controls.Add(resourceClassificationsHidden)
            parameter.Control = reportLayout

            Return reportLayout
        End Function

        Protected Overrides Sub RenderParameter(ByVal parameter As ReportingServicesReportParameter2005)

            If IsParameterHidden(parameter) Then
                Return
            ElseIf (Report.Name.Contains("Core")) Then
                RenderCoreParameters(parameter)
            Else
                RenderBhpbioParameters(parameter)
            End If

        End Sub

        Protected Overridable Function IsParameterHidden(parameter As ReportingServicesReportParameter2005) As Boolean
            If parameter.RSParameter.Prompt.ToLower = HiddenFieldPrompt.ToLower Then
                ' it is kind of crazy to go hiding the paramters this way based on the prompt, but unfortunately
                ' the Core ReportingServices classes don't pass through a property to show if a parameter is hidden
                ' or not. So we check this based off the report prompt - if it is the right keyword then we don't
                ' render the parameter on the form.
                Return True
            Else
                Return False
            End If
        End Function

        ' these attional attributes can be passed in the parameter name, but you can also return them from this function
        ' based off the report name
        Protected Overridable Function GetAdditionalAttributes(reportName As String) As IEnumerable(Of String)
            If reportName = "BhpbioFactorsVsShippingTargetsReport" Or reportName = "BhpbioFactorsByLocationVsShippingTargetsReport" Then
                Return New String() {"H2O", "Oversize", "Undersize"}
            ElseIf reportName = "BhpbioErrorContributionContextReport" Or reportName = "BhpbioForwardErrorContributionContextReport" Or reportName = "BhpbioFactorAnalysisReport" Then
                Return New String() {"H2O"}
            ElseIf reportName = "BhpbioF1F2F3GeometReconciliationAttributeReport" Or
                   reportName = "BhpbioF1F2F3ReconciliationProductAttributeReport" Then
                Return New String() {"Ultrafines-in-fines"}
            Else
                Return New String() {}
            End If
        End Function

        Protected Function RenderSourceRadioList(ByVal parameter As ReportingServicesReportParameter2005) As RadioButtonList
            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioFactors was null.")
            End If

            Dim sourceRadioList As New RadioButtonList
            sourceRadioList.ID = parameter.RSParameter.Name

            For Each value As KeyValuePair(Of String, String) In FactorList.GetFactors(Report.Name)
                If value.Key <> "MiningModelCrusherEquivalent" And
                   value.Key <> "SitePostCrusherStockpileDelta" And
                   value.Key <> "HubPostCrusherStockpileDelta" And
                   value.Key <> "PostCrusherStockpileDelta" And
                   value.Key <> "PortStockpileDelta" Then

                    sourceRadioList.Items.Add(New ListItem(value.Value, value.Key))
                End If
            Next

            ' maybe there is some setting saved with the previous value?
            Dim singleSourceSetting = Resources.UserSecurity.GetSetting("Report_Filter_" & parameter.RSParameter.Name, Nothing)
            Dim selection = sourceRadioList.Items.FindByValue(singleSourceSetting)
            If selection IsNot Nothing Then
                sourceRadioList.SelectedIndex = sourceRadioList.Items.IndexOf(selection)
            Else
                sourceRadioList.SelectedIndex = 0
            End If

            Return sourceRadioList
        End Function

        Protected Overridable Function RenderReportFormat(ByVal parameter As ReportingServicesReportParameter2005) _
            As InputRadio

            Dim displayOptionsInputRadio As New InputRadio
            Dim displayOptionUserSetting As String = Resources.UserSecurity.GetSetting("Report_Display_Options", Nothing)

            'set completereport to checked, then check usersetting for saved settings
            If Not String.IsNullOrEmpty(displayOptionUserSetting) Then

                ' the bench error reports are a special case - the default is not completereport, but onlygraphs. This is not
                ' ideal, and is likely to cause confusion in the future, but it was requested by the client
                If displayOptionUserSetting.ToLower() = "completereport" AndAlso Report.Name.StartsWith("BhpbioBenchErrorBy") Then
                    displayOptionUserSetting = "onlygraphs"
                End If

                If parameter.RSParameter.Name.ToLower() = displayOptionUserSetting.ToLower() Then
                    displayOptionsInputRadio.Checked = True
                End If
            ElseIf (parameter.RSParameter.Name.ToLower() = "completereport") Then
                displayOptionsInputRadio.Checked = True
            End If

            displayOptionsInputRadio.ID = parameter.RSParameter.Name
            displayOptionsInputRadio.GroupName = "DisplayOptions"
            displayOptionsInputRadio.Text = parameter.RSParameter.Prompt

            Return displayOptionsInputRadio
        End Function

        Protected Overridable Function RenderRadioButton(ByVal parameter As ReportingServicesReportParameter2005) As HtmlTableTag
            Dim reportLayout As New HtmlTableTag
            Dim radioControl As New InputRadio

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderRadioButton was null.")
            End If

            If (Not parameter.Control.GetType Is GetType(SelectBox)) Then
                Throw New ArgumentNullException("parameter", "Wrong parameter type passed To RenderRadioButton.")
            End If

            Dim parameterControl = TryCast(parameter.Control, SelectBox)

            If (parameterControl.Items.Count = 0) Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderRadioButton has no values.")
            End If

            For Each item As ListItem In parameterControl.Items
                If IsPowerPointReport() And Report.Name.Contains("Site") Then
                    If item.Value = "F1,F2,F3" Then Continue For
                End If

                radioControl = New InputRadio()
                radioControl.ID = parameter.RSParameter.Name & "_" & item.Value.Replace(" ", "")
                radioControl.GroupName = parameter.RSParameter.Name
                radioControl.Text = item.Text
                radioControl.Value = item.Value
                radioControl.Checked = item.Selected
                reportLayout.AddCellInNewRow().Controls.Add(radioControl)
            Next

            Return reportLayout
        End Function

        Protected Overridable Function RenderBhpbioMonthRange(ByVal parameter As ReportingServicesReportParameter2005,
                                                               ByVal systemStartDate As DateTime) As MonthFilter

            Dim monthRange As New MonthFilter
            Dim periodUserSetting As String
            Dim dateUserSetting As Date = Date.Now
            Dim displayControl As String = "inline"
            Dim controlId As String = parameter.RSParameter.Name

            monthRange.StartYear = systemStartDate.Year
            If Report.Name.ToLower.StartsWith("bhpbiomonthly") Then
                periodUserSetting = "month"
            Else
                periodUserSetting = Resources.UserSecurity.GetSetting("Report_Filter_Period", "MONTH")
            End If

            If Not String.IsNullOrEmpty(periodUserSetting) Then
                If periodUserSetting.ToLower() = "month" Then
                    If controlId = "DateFrom" Or controlId = "StartDate" Then
                        dateUserSetting = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_From", Date.Now)
                    ElseIf controlId = "DateTo" Or controlId = "EndDate" Then
                        dateUserSetting = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_To", Date.Now)
                        Dim dateFromSetting = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_From", Date.Now)

                        ' since there are now some reports that only have one date setting, there can be circumstances
                        ' where the saved settings will put the dateFrom after the dateTo. If we detect this, then just
                        ' change things so that the to date is just after the from
                        If dateFromSetting > dateUserSetting Then
                            dateUserSetting = dateFromSetting.AddMonths(1).AddDays(-1)
                        End If
                    End If
                Else
                    displayControl = "none"
                End If
            End If

            monthRange.SelectedDate = dateUserSetting

            With monthRange
                .ID = controlId
                .Index = controlId
                .Style.Item("display") = displayControl
            End With

            Return monthRange
        End Function

        Protected Overridable Function RenderBhpbioDesignation(ByVal parameter As ReportingServicesReportParameter2005) _
            As SelectBox
            Dim dropdown As New SelectBox

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioMonthRange was null.")
            End If

            With dropdown
                .ID = parameter.RSParameter.Name
                .DataSource =
                    DalUtility.GetMaterialTypeList(DoNotSetValues.Int16, DoNotSetValues.Int16, DoNotSetValues.Int32,
                                                    "Designation", DoNotSetValues.Int32)
                .DataTextField = "Description"
                .DataValueField = "Material_Type_Id"
                .DataBind()

                If parameter.RSParameter.Nullable Or parameter.RSParameter.AllowBlank Then
                    .Items.Insert(0, New ListItem("All", String.Empty))
                End If
            End With

            parameter.Control = dropdown

            Return dropdown
        End Function

        Protected Overridable Function RenderDateBreakdown(ByVal parameter As ReportingServicesReportParameter2005) _
            As SelectBox
            Dim dropdown As New SelectBox
            Dim settingBreakdown As String = Resources.UserSecurity.GetSetting("Report_Filter_Period", Nothing)
            Dim onSelectChangeJavascript As String = "toggleQuarterDropList();"

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderDateBreakdown was null.")
            End If

            If Report.Name = "BhpbioF1F2F3ReconciliationAttributeReport" Or Report.Name = "BhpbioF1F2F3GeometReconciliationAttributeReport" Then
                onSelectChangeJavascript += "CheckFormatFactorControls();"
            ElseIf Report.Name = "BhpbioF1F2F3ReconciliationLocationComparisonReport" Then
                onSelectChangeJavascript += "CheckFormatFactorControlsForF1F2F3();"
                'These functions below are used to Hide some Sources in case the selected date breakdown equals MONTH
            ElseIf Report.Name = "BhpbioFactorsVsTimeProductReport" Or Report.Name = "BhpbioErrorContributionContextReport" Or Report.Name = "BhpbioForwardErrorContributionContextReport" Then
                onSelectChangeJavascript += " HideF3FactoronMonth();"
            ElseIf Report.Name = "BhpbioF1F2F3ReconciliationProductAttributeReport" Or Report.Name = "BhpbioFactorsVsTimeProductReport" Or Report.Name = "BhpbioFactorsVsShippingTargetsReport" Then
                onSelectChangeJavascript += "HideProdReconAttributeMonth();"
            ElseIf Report.Name = "BhpbioFactorsByLocationVsShippingTargetsReport" OrElse Report.Name = "BhpbioFactorAnalysisReport" Then
                onSelectChangeJavascript += "HideF3FactoronMonthRadio();"
            Else
                onSelectChangeJavascript += "CheckMonthLocationReport();"
            End If

            With dropdown
                .ID = parameter.RSParameter.Name

                .Items.Insert(0, New ListItem("Month", "MONTH"))
                .Items.Insert(1, New ListItem("Quarter", "QUARTER"))

                .SelectedValue = settingBreakdown
                .OnSelectChange = onSelectChangeJavascript
            End With

            parameter.Control = dropdown

            Return dropdown
        End Function

        Protected Overridable Function RenderBhpbioCustomDatebreakdown(ByVal customDateBreakdownId As String) _
            As Control
            Dim dropdown As New SelectBox
            Dim settingBreakdown As String = Resources.UserSecurity.GetSetting("Report_Filter_Period", Nothing)
            Dim onSelectChangeJavascript As String = "toggleQuarterDropList();"

            If Report.Name = "BhpbioF1F2F3ReconciliationAttributeReport" Or Report.Name = "BhpbioF1F2F3GeometReconciliationAttributeReport" Then
                onSelectChangeJavascript += "CheckFormatFactorControls();"
            Else
                onSelectChangeJavascript += "CheckMonthLocationReport();"
            End If

            With dropdown
                .ID = customDateBreakdownId

                .Items.Insert(0, New ListItem("Month", "MONTH"))
                .Items.Insert(1, New ListItem("Quarter", "QUARTER"))

                .SelectedValue = settingBreakdown
                .OnSelectChange = onSelectChangeJavascript
            End With

            Return dropdown
        End Function
        Protected Overridable Function RenderBhpbioProductTypeSelection(ByVal parameter As ReportingServicesReportParameter2005) _
            As HtmlTableTag
            Dim productType As DataTable = New DataTable()
            Dim reportLayout As New HtmlTableTag
            Dim sourceOption As InputCheckBox

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioProductType was null.")
            End If

            productType = DalUtilityBhpbio.GetBhpbioProductTypeList()

            For Each row As DataRow In productType.Rows
                sourceOption = New InputCheckBox

                With sourceOption
                    .ID = String.Format("chkProductType_{0}", row("ProductTypeId"))
                    .Text = String.Format("{0} ({1})", row("Description"), row("ProductTypeCode"))
                End With

                reportLayout.AddCellInNewRow.Controls.Add(sourceOption)
            Next

            reportLayout.AddCellInNewRow.Controls.Add(CreateCheckboxLinks("chkProductType_", parameter.RSParameter.Name))
            parameter.Control = reportLayout

            Return reportLayout
        End Function
        Protected Overridable Function RenderBhpbioProductTypeId(ByVal parameter As ReportingServicesReportParameter2005) _
            As HtmlTableTag
            Dim reportLayout As New HtmlTableTag
            Dim settingSelected As String = Resources.UserSecurity.GetSetting("ProductTypeID", Nothing)
            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioProductType was null.")
            End If

            Dim dropdown = New ProductPicker(DalUtilityBhpbio, True)

            ' we need to change the default ID so that it matches the parameter name, otherwise
            ' the value doesn't get mapped properly
            dropdown.ID = "ProductTypeId"

            If settingSelected <> "" Then
                dropdown.SelectedValue = settingSelected
            End If

            reportLayout.AddCellInNewRow.Controls.Add(dropdown)
            parameter.Control = reportLayout

            Return reportLayout
        End Function
        Protected Overridable Function RenderBhpbioSource(ByVal parameter As ReportingServicesReportParameter2005) _
            As HtmlTableTag
            Dim blockModels As DataTable
            Dim blockModelsHidden As New InputHidden
            Dim reportLayout As New HtmlTableTag
            Dim sourceOption As InputCheckBox
            Dim formattedBlockModels As DataTable
            Dim addActualsSelection As Boolean = CType(IIf(Report.Name <> "BhpbioBenchErrorByAttributeReport" AndAlso Report.Name <> "BhpbioReconciliationRangeReport", True, False), Boolean)
            Dim removeGradeControlSelection As Boolean = CType(IIf(Report.Name = "BhpbioBenchErrorByAttributeReport", True, False), Boolean)

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioSource was null.")
            End If

            blockModels = DalBlockModel.GetBlockModelList(DoNotSetValues.Int32, DoNotSetValues.String, DoNotSetValues.Int16)

            formattedBlockModels = Bhpbio.Report.Data.BlockModels.FormatBlockModelsTable(blockModels)

            ' The ‘Grade Control’ model shouldn’t be shown as an option when selecting which models should be compared. 
            ' This is because it doesn’t make sense to compare GC model against itself (‘By Attribute’ Report only)
            If removeGradeControlSelection Then
                For Each row As DataRow In formattedBlockModels.Rows
                    If row.Item("Name").ToString = "Grade Control" Then
                        formattedBlockModels.Rows.Remove(row)
                        Exit For
                    End If
                Next
            End If
            formattedBlockModels.AcceptChanges()

            For Each drRow As DataRow In formattedBlockModels.Rows
                sourceOption = New InputCheckBox

                With sourceOption
                    .ID = "chkSource_" & drRow.Item("Block_Model_Id").ToString
                    .Text = " " & drRow.Item("Description").ToString
                End With

                reportLayout.AddCellInNewRow.Controls.Add(sourceOption)
            Next

            If addActualsSelection Then
                sourceOption = New InputCheckBox
                With sourceOption
                    .ID = "chkSource_MineProductionActuals"
                    .Text = " Mine Production (Actuals)"
                End With
                reportLayout.AddCellInNewRow.Controls.Add(sourceOption)
            End If

            With blockModelsHidden
                .ID = parameter.RSParameter.Name
            End With

            reportLayout.AddCellInNewRow.Controls.Add(CreateCheckboxLinks("chkSource_", parameter.RSParameter.Name))
            reportLayout.AddCell.Controls.Add(blockModelsHidden)
            parameter.Control = reportLayout

            If (Not blockModels Is Nothing) Then
                blockModels.Dispose()
            End If

            Return reportLayout
        End Function

        Protected Overridable Function RenderBhpbioGradesTonnes(ByVal parameter As ReportingServicesReportParameter2005, ByVal additionalAttributes As String()) _
            As HtmlTableTag
            Dim grades As DataTable
            Dim gradesHidden As New InputHidden
            Dim reportLayout As New HtmlTableTag
            Dim sourceOption As InputCheckBox

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed To RenderBhpbioAttributes was null.")
            End If

            grades = DalUtility.GetGradeList(NullValues.Int16)

            sourceOption = New InputCheckBox

            With sourceOption
                .ID = "chkGrade_Tonnes"
                .Text = " Tonnes"
                '   .InputAttributes.Add("onClick", String.Format("BhpbioElementSelected('{0}', '{1}')", parameter.RSParameter.Name, "GradeTonnes"))
            End With

            reportLayout.AddCellInNewRow.Controls.Add(sourceOption)

            If ((Not additionalAttributes Is Nothing) AndAlso additionalAttributes.Contains("Volume")) Then
                sourceOption = New InputCheckBox

                With sourceOption
                    .ID = "chkGrade_Volume"
                    .Text = " Volume"
                End With

                reportLayout.AddCellInNewRow.Controls.Add(sourceOption)
            End If


            For Each drRow As DataRow In grades.Rows
                ' determine the default visibility of this grade
                Dim include As Boolean = (Not _attributesToExcludeUnlessExplicitlyAdded.Contains(drRow.Item("Grade_Name").ToString) _
                                        AndAlso (Not drRow.Item("Is_Visible").ToString = "False"))

                If (include = False AndAlso (Not additionalAttributes Is Nothing) AndAlso additionalAttributes.Contains(drRow.Item("Grade_Name").ToString)) Then
                    include = True
                End If

                If (include) Then
                    sourceOption = New InputCheckBox

                    With sourceOption
                        .ID = "chkGrade_" & drRow.Item("Grade_Id").ToString
                        .Text = " " & drRow.Item("Description").ToString
                    End With

                    reportLayout.AddCellInNewRow.Controls.Add(sourceOption)
                End If
            Next


            With gradesHidden
                .ID = parameter.RSParameter.Name
            End With

            reportLayout.AddCellInNewRow.Controls.Add(CreateCheckboxLinks("chkGrade_", parameter.RSParameter.Name))
            reportLayout.AddCell.Controls.Add(gradesHidden)

            parameter.Control = reportLayout

            If (Not grades Is Nothing) Then
                grades.Dispose()
            End If

            Return reportLayout
        End Function

        Protected Overridable Function RenderBhpbioAttributes(ByVal parameter As ReportingServicesReportParameter2005, ByVal rawParameterName As String, ByVal additionalAttributes As String()) _
            As HtmlTableTag
            Dim allAttributes As IDictionary(Of Short, String)
            Dim visibleAttributes As IDictionary(Of Short, String)
            Dim attributesHidden As New InputHidden
            Dim reportLayout As New HtmlTableTag
            Dim attributeOption As InputCheckBox
            Dim localReportSession As New ReportSession

            localReportSession.SetupDal(Resources.ConnectionString)

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed to RenderBhpbioAttributes was null.")
            End If

            allAttributes = GradeProperties.GetAttributes(localReportSession, True)
            visibleAttributes = GradeProperties.GetAttributes(localReportSession, False)

            ' these should really be returned by the GetAttributes call, but due to the ids overlapping we
            ' will hardcode them for now
            If Report.Name.Contains("ShippingTargets") Then
                allAttributes.Add(-100, "Oversize")
                allAttributes.Add(-201, "Undersize")
            End If

            ' Dirty hack because this uses the Grade_Name and not the Grade_Description
            If allAttributes(10) IsNot Nothing Then
                allAttributes(10) = "Ultrafines-in-fines"
            End If

            For Each value As KeyValuePair(Of Short, String) In allAttributes
                Dim attributeId = value.Key

                ' we need to treat undersize and oversize as a special case and get the attribute_id through the
                ' report engine. This will have to be refactored later on
                If attributeId <= -100 Then
                    attributeId = Convert.ToInt16(F1F2F3ReportEngine.GetAttributeId(value.Value))
                End If

                Dim includeAttribute As Boolean = Not _attributesToExcludeUnlessExplicitlyAdded.Contains(value.Value)

                If (Not visibleAttributes.ContainsKey(attributeId)) Then
                    ' the attribute is not visible by default
                    includeAttribute = False
                End If

                If (Not includeAttribute) Then
                    ' if not included by default test if the attribute should be explicitly included for this report parameter as a special case
                    ' remove spaces from the attribute name for comparison
                    If ((Not additionalAttributes Is Nothing) AndAlso additionalAttributes.Contains(value.Value.Replace(" ", ""))) Then
                        includeAttribute = True
                    End If
                End If

                If includeAttribute AndAlso ExcludeAttributeSelection(Report.Name, value.Value) Then
                    includeAttribute = False
                End If

                ' if including... create the required checkbox
                If (includeAttribute) Then
                    attributeOption = New InputCheckBox

                    With attributeOption
                        .ID = "chkAttribute_" & attributeId & "_" & value.Value
                        .Text = " " & value.Value
                        ' .InputAttributes.Add("onClick", String.Format("BhpbioElementSelected('{0}', '{1}')", parameter.RSParameter.Name, "chkAttribute_" & value.Key))
                    End With

                    reportLayout.AddCellInNewRow.Controls.Add(attributeOption)
                End If
            Next

            With attributesHidden
                .ID = rawParameterName
            End With

            reportLayout.AddCellInNewRow.Controls.Add(CreateCheckboxLinks("chkAttribute_", rawParameterName))
            reportLayout.AddCell.Controls.Add(attributesHidden)

            parameter.Control = reportLayout

            If (Not localReportSession Is Nothing) Then
                localReportSession.Dispose()
            End If

            Return reportLayout
        End Function

        ' if this returns true for a given report and attribute combination, then that attribute checkbox will not
        ' be shown to the user
        '
        ' This will only get called if the report includes the 'Attributes' parameter
        Protected Function ExcludeAttributeSelection(ByVal reportName As String, ByVal attributeName As String) As Boolean
            If reportName Is Nothing Then Throw New ArgumentNullException("reportName")
            If attributeName Is Nothing Then Throw New ArgumentNullException("attributeName")

            If reportName = "BhpbioFactorsByLocationVsShippingTargetsReport" AndAlso attributeName = "Tonnes" Then
                Return True
            ElseIf reportName = "BhpbioFactorsVsShippingTargetsReport" AndAlso attributeName = "Tonnes" Then
                Return True
            Else
                Return False
            End If
        End Function

        Protected Overridable Function RenderBhpbioFactors(ByVal parameter As ReportingServicesReportParameter2005) _
            As HtmlTableTag
            Dim factors As IDictionary(Of String, String)
            Dim factorsHidden As New InputHidden
            Dim reportLayout As New HtmlTableTag
            Dim factorOption As InputCheckBox

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed to RenderBhpbioFactors was null.")
            End If

            factors = FactorList.GetFactors(Report.Name)

            ' these reports need the list of factors to be handled in a special way
            Dim specialFactorReports = New String() {"BhpbioF1F2F3ReconciliationLocationComparisonReport",
                                                     "BhpbioFactorsVsTimeDensityReport", "BhpbioFactorsVsTimeVolumeReport", "BhpbioFactorsVsTimeMoistureReport",
                                                     "BhpbioFactorsVsTimeProductReport", "BhpbioErrorContributionContextReport",
                                                     "BhpbioForwardErrorContributionContextReport"}

            If specialFactorReports.Contains(Report.Name) Then
                Dim newFactorList As New Dictionary(Of String, String)

                Dim factorKeys As List(Of String) = New List(Of String)
                factorKeys.AddRange(New String() {"F1Factor", "F15Factor", "F2Factor", "F25Factor", "F3Factor"})

                ' The FvT reports have some special factors. They Density + Volume reports don't
                ' have F2.5 or F3, because the results are not valid at this level. The Density and
                ' Moisture reports have their special RecoveryFactor factors
                If Report.Name = "BhpbioFactorsVsTimeDensityReport" Or Report.Name = "BhpbioDensityAnalysisReport" Then
                    factorKeys.Remove("F2Factor")
                    factorKeys.Remove("F25Factor")
                    factorKeys.Remove("F3Factor")

                    factorKeys.Add("RecoveryFactorDensity")
                    factorKeys.Add("F2DensityFactor")
                ElseIf Report.Name = "BhpbioFactorsVsTimeMoistureReport" Then
                    factorKeys.Add("RecoveryFactorMoisture")
                ElseIf Report.Name = "BhpbioFactorsVsTimeVolumeReport" Then
                    factorKeys.Remove("F2Factor")
                    factorKeys.Remove("F25Factor")
                    factorKeys.Remove("F3Factor")
                ElseIf Report.Name = "BhpbioFactorsVsTimeProductReport" Or Report.Name = "BhpbioErrorContributionContextReport" Or Report.Name = "BhpbioForwardErrorContributionContextReport" Then
                    factorKeys.Remove("F25Factor")
                ElseIf Report.Name = "BhpbioFactorsVsTimeResourceClassificationReport" Then
                    factorKeys.Remove("F25Factor")
                    factorKeys.Add("F0.0")
                    factorKeys.Add("F0.5")
                End If

                For Each kvp As KeyValuePair(Of String, String) In factors
                    If (factorKeys.Contains(kvp.Key)) Then
                        newFactorList.Add(kvp.Key, kvp.Value)
                    End If
                Next kvp
                factors.Clear()
                factors = newFactorList
            End If

            For Each value As KeyValuePair(Of String, String) In factors
                factorOption = New InputCheckBox

                With factorOption
                    .ID = "chkFactor_" & value.Key
                    .Text = " " & value.Value
                End With

                Dim factorOptionCell As TableCell = reportLayout.AddCellInNewRow
                factorOptionCell.Controls.Add(factorOption)
                factorOptionCell.ID = value.Key
            Next

            With factorsHidden
                .ID = parameter.RSParameter.Name
            End With

            reportLayout.AddCellInNewRow.Controls.Add(CreateFactorCheckboxLinks("chkFactor_", parameter.RSParameter.Name))
            reportLayout.AddCell.Controls.Add(factorsHidden)

            parameter.Control = reportLayout

            Return reportLayout
        End Function

        ' displays a list of checkboxes to allow the user to optionally add extra sections to the report
        Protected Overridable Function RenderBhpbioContextSelection(ByVal parameter As ReportingServicesReportParameter2005) As HtmlTableTag
            'Report param name: ContextSelection

            Dim contexts As New Dictionary(Of String, String)
            Dim control As New HtmlTableTag

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed to RenderBhpbioContext was null.")
            End If

            If Report.Name = "BhpbioFactorAnalysisReport" Then
                contexts.Add("ResourceClassification", "Resource Classification")
                contexts.Add("HaulageContext", "Haulage Context")
                contexts.Add("SampleCoverage", "Sample Coverage")
                contexts.Add("SampleRatio", "Tonnes/Sample")
                contexts.Add("Stratigraphy", "Stratigraphy Context")
                contexts.Add("Weathering", "Weathering Context")
            Else
                contexts.Add("ResourceClassification", "Resource Classification")
            End If

            For Each value As KeyValuePair(Of String, String) In contexts
                Dim contextOption = New InputCheckBox With {
                    .ID = "chkContext_" & value.Key,
                    .Text = " " & value.Value
                }

                Dim contextOptionCell As TableCell = control.AddCellInNewRow
                contextOptionCell.Controls.Add(contextOption)
                contextOptionCell.ID = value.Key
            Next

            parameter.Control = control
            Return control
        End Function

        Protected Overridable Function RenderBhpbioLocationSelection(ByVal parameter As ReportingServicesReportParameter2005) As HtmlDivTag
            Dim divName As String = parameter.RSParameter.Name & "Div"
            Dim renderDiv As New HtmlDivTag(divName)
            Dim containerDiv As New HtmlDivTag
            Dim parameterValue As New InputHidden
            Dim initialiseScript As New HtmlScriptTag(ScriptType.TextJavaScript)

            renderDiv.Controls.Add(New LiteralControl("Please select a location and location checkboxes will load."))

            parameterValue.ID = parameter.RSParameter.Name
            parameterValue.Value = parameter.RSParameter.DefaultValues(0)

            containerDiv.Controls.Add(renderDiv)
            containerDiv.Controls.Add(parameterValue)
            containerDiv.Controls.Add(initialiseScript)

            Return containerDiv
        End Function

        Private Function CreateCheckboxLinks(ByVal key As String, ByVal listId As String) As HtmlTableTag
            Dim checkTable As New HtmlTableTag
            Dim checkAll As New LinkButton
            Dim uncheckAll As New LinkButton

            checkAll.Text = "[Check All]"
            checkAll.OnClientClick = "return CheckAll('" & key & "','" & listId & "');"

            uncheckAll.Text = "[Un-check All]"
            uncheckAll.OnClientClick = "return UncheckAll('" & key & "','" & listId & "');"

            With checkTable
                .CellPadding = 2
                .AddCellInNewRow.Controls.Add(checkAll)
                .AddCell.Controls.Add(uncheckAll)
            End With

            Return checkTable
        End Function

        Private Function CreateFactorCheckboxLinks(ByVal key As String, ByVal listId As String) As HtmlTableTag
            Dim checkTable As New HtmlTableTag
            Dim checkAll As New LinkButton
            Dim uncheckAll As New LinkButton

            checkAll.Text = "[Check All]"
            checkAll.OnClientClick = "return CheckAllFactors('" & key & "','" & listId & "');"

            uncheckAll.Text = "[Un-check All]"
            uncheckAll.OnClientClick = "return UncheckAllFactors('" & key & "','" & listId & "');"

            With checkTable
                .CellPadding = 2
                .AddCellInNewRow.Controls.Add(checkAll)
                .AddCell.Controls.Add(uncheckAll)
            End With

            Return checkTable
        End Function

        Public Overridable Function RenderComparisonSelect(ByVal parameter As ReportingServicesReportParameter2005) _
            As SelectBox
            Dim comparionsSelect As New SelectBox
            Dim blockModels As DataTable
            Dim formattedBlockModels As DataTable

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed to RenderComparisonSelect was null.")
            End If

            blockModels =
                DalBlockModel.GetBlockModelList(DoNotSetValues.Int32, DoNotSetValues.String, DoNotSetValues.Int16)

            formattedBlockModels =
                Bhpbio.Report.Data.BlockModels.FormatBlockModelsTable(blockModels)

            With comparionsSelect
                .ID = parameter.RSParameter.Name
                .DataSource = formattedBlockModels
                .DataTextField = "Description"
                .DataValueField = "Block_Model_Id"
                .DataBind()

                .Items.Add(New ListItem("Mine Production (Actuals)", "Actuals"))
            End With

            Return comparionsSelect
        End Function

        Public Overridable Function GetParentLocationInRange(ByVal userSettingLocationId As Integer,
                                                              ByVal lowestDescription As String) As Integer

            Dim validLocationIdToSet As Integer = userSettingLocationId

            Dim parentLocations As DataTable = DalUtility.GetLocationParentHeirarchy(userSettingLocationId)

            For Each dr As DataRow In parentLocations.Rows
                If (lowestDescription.ToLower() = dr("Location_Type_Description").ToString().ToLower()) Then
                    Integer.TryParse(dr("Location_Id").ToString(), validLocationIdToSet)
                End If
            Next

            Return validLocationIdToSet

        End Function

        Private Function GetLowestLocationTypeDescriptionForReport(ByVal reportName As String) As String
            Select Case (reportName)
                Case "BhpbioQuarterlyHubReconciliationReport", "BhpbioYearlyReconciliationReport"
                    Return "HUB"
                Case "Bhpbio_Core_Haulage_vs_Plant_Report", "Bhpbio_Core_Stockpile_Balance_Report", "BhpbioF1F2F3OverviewReconReport",
                "BhpbioF1F2F3ReconciliationComparisonReport", "BhpbioLiveVersusSummaryReport", "BhpbioF1F2F3OverviewReconContributionReport",
                "BhpbioSupplyChainMonitoringReport", "BhpbioQuarterlySiteReconciliationReport", "BhpbioMonthlySiteReconciliationReport",
                "BhpbioSampleCoverageReport", "BhpbioProductSupplyChainMonitoringReport", "BhpbioF1F2F3GeometOverviewReconContributionReport"
                    Return "SITE"
                Case "BhpbioErrorContributionContextReport", "BhpbioForwardErrorContributionContextReport"
                    Return "BENCH"
                Case "BhpbioBlastByBlastReconciliationReport"
                    Return "BLAST"
                Case Else
                    Return "PIT"
            End Select

            Return String.Empty
        End Function

        Private Function GetMaxLocationForReport(ByVal reportName As String) As String
            If (reportName = "BhpbioBlastByBlastReconciliationReport") Then
                Return "Blast"
            Else
                Return "Company"
            End If
        End Function

        Private Function GetMinLocationForReport(ByVal reportName As String) As String
            Select Case (reportName)
                Case "BhpbioF1F2F3OverviewReconReport", "BhpbioF1F2F3OverviewReconContributionReport", "BhpbioF1F2F3ReconciliationComparisonReport", "BhpbioLiveVersusSummaryReport", "BhpbioF1F2F3GeometOverviewReconContributionReport"
                    Return "Site"
                Case "BhpbioErrorContributionContextReport", "BhpbioForwardErrorContributionContextReport"
                    Return "Bench"
                Case "BhpbioBlastByBlastReconciliationReport"
                    Return "Blast"
                Case Else
                    Return "Pit"
            End Select
        End Function

        Public Overridable Function RenderLocation(ByVal parameter As ReportingServicesReportParameter2005) _
            As HtmlTableTag
            Dim locationTable As New HtmlTableTag
            Dim locationSelector As New WebDevelopment.Controls.ReconcilorLocationSelector
            Dim hidMinLocation As New InputHidden
            Dim hidMaxLocation As New InputHidden
            Dim hidMaxLocationActuals As New InputHidden
            Dim hidValidLocationTypeList As New InputHidden
            Dim hidValidLocationTypeActualsList As New InputHidden
            Dim settingLocation As String
            Dim locationId As Int32

            If parameter Is Nothing Then
                Throw New ArgumentNullException("parameter", "Parameter passed to RenderDigblockList was null.")
            End If

            hidMinLocation.ID = "LocationTypeMin"
            hidMaxLocationActuals.ID = "LocationTypeMinActuals"
            hidMaxLocation.ID = "LocationTypeMax"
            hidValidLocationTypeList.ID = "LocationValidTypesList"
            hidValidLocationTypeActualsList.ID = "LocationValidTypesActualsList"

            locationSelector.ID = parameter.RSParameter.Name
            locationSelector.ShowCaptions = False
            locationSelector.LocationDiv.ID = parameter.RSParameter.Name & "Div"

            settingLocation = Resources.UserSecurity.GetSetting("Report_Filter_LocationId", Nothing)

            If (settingLocation Is Nothing) OrElse Not Int32.TryParse(settingLocation, locationId) Then
                'there is no applicable default
                locationId = Nothing
            End If

            If (Not String.IsNullOrEmpty(_startDateElementName)) Then
                locationSelector.StartDate = Resources.UserSecurity.GetDateSetting("Report_Filter_Date_From", Date.Now)
                locationSelector.StartDateElementName = _startDateElementName
            End If

            If (Not String.IsNullOrEmpty(_startQuarterElementName)) Then
                locationSelector.StartQuarterElementName = _startQuarterElementName
            End If

            locationSelector.LocationId = locationId

            Select Case (Report.Name)
                Case "Bhpbio_Core_Haulage_vs_Plant_Report", "Bhpbio_Core_Stockpile_Balance_Report",
                    "BhpbioQuarterlyHubReconciliationReport", "BhpbioQuarterlySiteReconciliationReport",
                    "BhpbioMonthlySiteReconciliationReport"
                    locationSelector.LowestLocationTypeDescription = GetLowestLocationTypeDescriptionForReport(Report.Name)
                Case Else
                    locationSelector.LowestLocationTypeDescription = GetLowestLocationTypeDescriptionForReport(Report.Name)
                    hidMaxLocation.Value = GetMaxLocationForReport(Report.Name)
                    hidMinLocation.Value = GetMinLocationForReport(Report.Name)
                    hidValidLocationTypeList.Value = GetValidLocationTypeList(hidMaxLocation.Value, hidMinLocation.Value)
                    locationSelector.LocationId = GetParentLocationInRange(locationId, locationSelector.LowestLocationTypeDescription)
            End Select

            Select Case (Report.Name)
                Case "BhpbioModelComparisonReport", "BhpbioDesignationAttributeReport", "BhpbioRecoveryAnalysisReport",
                    "BhpbioMovementRecoveryReport"
                    hidMaxLocationActuals.Value = "Site"
                    hidValidLocationTypeActualsList.Value = GetValidLocationTypeList(hidMaxLocation.Value, hidMaxLocationActuals.Value)
                Case "BhpbioF1F2F3ReconciliationAttributeReport", "BhpbioFactorsVsTimeDensityReport",
                    "BhpbioFactorsVsTimeMoistureReport", "BhpbioFactorsVsTimeVolumeReport", "BhpbioF1F2F3GeometReconciliationAttributeReport"
                    locationSelector.OnChange = "FormatFactorControls();"
                Case "BhpbioF1F2F3ReconciliationLocationComparisonReport"
                    locationSelector.OnChange = "FormatFactorControlsForF1F2F3();"
                Case "BhpbioF1F2F3ReconciliationComparisonReport"
                    locationSelector.OnChange = String.Format("RenderLocationCheckboxes('{0}', '{1}');", "LocationIdsDiv", "LocationIdDynamic")
                    locationSelector.OnChange += "FilterSourceForLocationOnF1F2F3ComparisonReport();"
                Case "BhpbioFactorAnalysisReport"
                    locationSelector.OnChange = "FilterSourceForFactorContextReport();"
                Case "BhpbioDensityAnalysisReport"
                    locationSelector.OnChange = "FormatFactorControlsForDensityAnalysis();"
            End Select

            ' if it contains a 'Factors' parameter, and we haven't already connected it to the location selector
            ' manually, then just wire it up using the default method
            If Report.Parameters.ContainsKey("Factors") AndAlso String.IsNullOrEmpty(locationSelector.OnChange) Then
                locationSelector.OnChange = "FormatFactorControls();"
            End If

            If Report.Parameters.ContainsKey("LocationGroupId") Then
                locationSelector.ShowLocationGroups = True
            End If

            With locationTable
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(locationSelector)
                .CurrentCell.Controls.Add(hidMaxLocation)
                .CurrentCell.Controls.Add(hidMinLocation)
                .CurrentCell.Controls.Add(hidMaxLocationActuals)
                .CurrentCell.Controls.Add(hidValidLocationTypeList)
                .CurrentCell.Controls.Add(hidValidLocationTypeActualsList)
            End With

            Return locationTable
        End Function



    End Class

End Namespace
