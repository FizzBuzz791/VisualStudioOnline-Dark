Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.Reports
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Linq
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility

Namespace Reports
    Public Class ReportsRun
        Inherits Snowden.Reconcilor.Core.Website.Reports.ReportsRun

        ' this is a list of all the reports that were present at the start of 2.0. We can use this list to exclude these
        ' reports from any new generic logic for report processing, reducing the risk of regressions
        Private Shared _oldReports As String() = {"BhpbioDesignationAttributeReport", "BhpbioModelComparisonReport",
                                      "BhpbioMovementRecoveryReport", "F1F2F3HUBReconciliationReport",
                                      "BhpbioF1F2F3ReconciliationAttributeReport", "BhpbioBlastByBlastReconciliationReport",
                                      "BhpbioRecoveryAnalysisReport", "BhpbioF1F2F3ReconciliationComparisonReport",
                                      "BhpbioF1F2F3ReconciliationLocationComparisonReport", "BhpbioF1F2F3OverviewReconReport",
                                      "BhpbioLiveVersusSummaryReport", "Bhpbio_Core_Stockpile_Balance_Report",
                                      "Bhpbio_Core_Haulage_vs_Plant_Report"}

#Region " Properties "
        Private _blockModelsList As String
        Private _gradesList As String
        Private _factorsList As String
        Private _attributesList As String
        Private _resourceClassificationList As String
        Private _dateFromMonthPart As String
        Private _dateFromYearPart As String
        Private _dateToMonthPart As String
        Private _dateToYearPart As String
        Private _includeActuals As Boolean
        Private _includeBlockModels As Boolean
        Private _includeTonnes As Boolean
        Private _includeVolume As Boolean
        Private _includeDesignationMaterialTypeID As Boolean
        Private _comparison1IsActuals As Boolean
        Private _comparison2IsActuals As Boolean
        Private _locationId As Int32?
        Private _datePeriod As String = String.Empty
        Private _locations As String
        Private _singleSource As String
        Private _productType As String
        Private _productTypeId As String


        Private _DalUtilityBhpbio As Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility

        Public Property LocationId() As Int32?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32?)
                _locationId = value
            End Set
        End Property

        Public Property LocationGroupId As Integer = -1

        Protected Property BlockModelsList() As String
            Get
                Return _blockModelsList
            End Get
            Set(ByVal value As String)
                _blockModelsList = value
            End Set
        End Property

        Protected Property GradesList() As String
            Get
                Return _gradesList
            End Get
            Set(ByVal value As String)
                _gradesList = value
            End Set
        End Property
        Protected Property ProductTypeList() As String
            Get
                Return _productType
            End Get
            Set(ByVal value As String)
                _productType = value
            End Set
        End Property

        Protected Property FactorsList() As String
            Get
                Return _factorsList
            End Get
            Set(ByVal value As String)
                _factorsList = value
            End Set
        End Property

        Protected Property AttributesList() As String
            Get
                Return _attributesList
            End Get
            Set(ByVal value As String)
                _attributesList = value
            End Set
        End Property

        Protected Property ResourceClassificationList() As String
            Get
                Return _resourceClassificationList
            End Get
            Set(ByVal value As String)
                _resourceClassificationList = value
            End Set
        End Property

        Protected Property ProductsList() As String

        Protected Property ContextSelectionList() As String

        Protected Property Locations() As String
            Get
                Return _locations
            End Get
            Set(ByVal value As String)
                _locations = value
            End Set
        End Property

        Protected Property DateFromMonthPart() As String
            Get
                Return _dateFromMonthPart
            End Get
            Set(ByVal value As String)
                _dateFromMonthPart = value
            End Set
        End Property

        Protected Property DateFromYearPart() As String
            Get
                Return _dateFromYearPart
            End Get
            Set(ByVal value As String)
                _dateFromYearPart = value
            End Set
        End Property

        Protected Property DateToMonthPart() As String
            Get
                Return _dateToMonthPart
            End Get
            Set(ByVal value As String)
                _dateToMonthPart = value
            End Set
        End Property

        Protected Property DateToYearPart() As String
            Get
                Return _dateToYearPart
            End Get
            Set(ByVal value As String)
                _dateToYearPart = value
            End Set
        End Property

        Protected Property IncludeActuals() As Boolean
            Get
                Return _includeActuals
            End Get
            Set(ByVal value As Boolean)
                _includeActuals = value
            End Set
        End Property

        Protected Property IncludeBlockModels() As Boolean
            Get
                Return _includeBlockModels
            End Get
            Set(ByVal value As Boolean)
                _includeBlockModels = value
            End Set
        End Property

        Protected Property IncludeTonnes() As Boolean
            Get
                Return _includeTonnes
            End Get
            Set(ByVal value As Boolean)
                _includeTonnes = value
            End Set
        End Property

        Protected Property IncludeVolume() As Boolean
            Get
                Return _includeVolume
            End Get
            Set(ByVal value As Boolean)
                _includeVolume = value
            End Set
        End Property



        Protected Property SingleSource() As String
            Get
                Return _singleSource
            End Get
            Set(ByVal value As String)
                _singleSource = value
            End Set
        End Property
        Protected Property ProductTypeId() As String
            Get
                Return _productTypeId
            End Get
            Set(ByVal value As String)
                _productTypeId = value
            End Set
        End Property

        Protected Property Comparison1IsActuals() As Boolean
            Get
                Return _comparison1IsActuals
            End Get
            Set(ByVal value As Boolean)
                _comparison1IsActuals = value
            End Set
        End Property

        Protected Property Comparison2IsActuals() As Boolean
            Get
                Return _comparison2IsActuals
            End Get
            Set(ByVal value As Boolean)
                _comparison2IsActuals = value
            End Set
        End Property

        Protected Property IncludeDesignationMaterialTypeID() As Boolean
            Get
                Return _includeDesignationMaterialTypeID
            End Get
            Set(ByVal value As Boolean)
                _includeDesignationMaterialTypeID = value
            End Set
        End Property

        Public ReadOnly Property DalUtilityBhpbio() As Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility
            Get
                If _DalUtilityBhpbio Is Nothing AndAlso Not DalUtility Is Nothing Then
                    _DalUtilityBhpbio = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(DalUtility.DataAccess.DataAccessConnection)
                End If

                Return _DalUtilityBhpbio
            End Get
        End Property

        Public Property LowestStratigraphyLevel As Integer = 0

#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim dateFormat As String = Context.Application("DateFormat").ToString

            Dim locationIdFilter As Int32
            Dim RequestText As String = String.Empty
            Dim dateFromUserSetting As DateTime
            Dim dateToUserSetting As DateTime

            'Location
            If Not Request("LocationId") Is Nothing Then
                RequestText = Request("LocationId").Trim
            ElseIf Not Request("BlastLocationId") Is Nothing Then
                RequestText = Request("BlastLocationId").Trim
            End If

            ' this location is a locationid with a locationgroupid, so we need to split them out, in order for the report
            ' to process properly
            If RequestText.Contains("G") Then
                Dim locationComponents = RequestText.Split("G")
                LocationId = Convert.ToInt32(locationComponents(0))
                LocationGroupId = Convert.ToInt32(locationComponents(1))
                Resources.UserSecurity.SetSetting("Report_Filter_LocationId", LocationId.ToString)
            Else
                If (RequestText <> String.Empty) AndAlso (RequestText <> "-1") AndAlso Int32.TryParse(RequestText, locationIdFilter) Then
                    LocationId = locationIdFilter
                    Resources.UserSecurity.SetSetting("Report_Filter_LocationId", RequestText)
                Else
                    LocationId = Nothing
                End If
            End If

            If Not Request("DisplayOptions") = Nothing Then
                RequestText = Request("DisplayOptions")
                Resources.UserSecurity.SetSetting("Report_Display_Options", RequestText)
            Else
                Resources.UserSecurity.SetSetting("Report_Display_Options", "CompleteReport")
            End If

            RequestText = Request("DateBreakdown")
            If (RequestText = String.Empty) Then
                RequestText = Request("nonParameterDateBreakdown")
            End If

            If Not String.IsNullOrEmpty(RequestText) Then
                _datePeriod = RequestText
                Resources.UserSecurity.SetSetting("Report_Filter_Period", RequestText)

                Select Case _datePeriod.ToLower()
                    Case "quarter"
                        If Not Request("DateFromQuarterSelect") = Nothing Then
                            dateFromUserSetting = DateBreakdown.GetDateFromUsingQuarter(RequestAsString("DateFromQuarterSelect"), RequestAsString("DateFromYearSelect"))
                        End If
                        If Not Request("DateToQuarterSelect") = Nothing Then
                            dateToUserSetting = DateBreakdown.GetDateToUsingQuarter(RequestAsString("DateToQuarterSelect"), RequestAsString("DateToYearSelect"))
                        End If

                    Case "month"
                        'supports DateFrom or StartDate
                        If Not Request("MonthPickerMonthPartDateFrom") = Nothing Then
                            dateFromUserSetting = DateTime.Parse(DateBreakdown.GetDateFromUsingMonth(RequestAsString("MonthPickerMonthPartDateFrom"), RequestAsString("MonthPickerYearPartDateFrom")))
                        End If
                        If Not Request("MonthPickerMonthPartStartDate") = Nothing Then
                            dateFromUserSetting = DateTime.Parse(DateBreakdown.GetDateFromUsingMonth(RequestAsString("MonthPickerMonthPartStartDate"), RequestAsString("MonthPickerYearPartStartDate")))
                        End If

                        'supports DateTo or EndDate
                        If Not Request("MonthPickerMonthPartDateTo") = Nothing Then
                            dateToUserSetting = DateTime.Parse(DateBreakdown.GetDateToUsingMonth(RequestAsString("MonthPickerMonthPartDateTo"), RequestAsString("MonthPickerYearPartDateTo")))
                        End If
                        If Not Request("MonthPickerMonthPartEndDate") = Nothing Then
                            dateToUserSetting = DateTime.Parse(DateBreakdown.GetDateToUsingMonth(RequestAsString("MonthPickerMonthPartEndDate"), RequestAsString("MonthPickerYearPartEndDate")))
                        End If
                End Select

                If (dateFromUserSetting <> Nothing) Then
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_From", dateFromUserSetting.ToString(dateFormat))
                End If

                If (dateToUserSetting <> Nothing) Then
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_To", dateToUserSetting.ToString(dateFormat))
                End If
            Else
                Resources.UserSecurity.SetSetting("Report_Filter_Period", String.Empty)

                If RequestAsString("StartDateText") <> Nothing And RequestAsString("EndDateText") <> Nothing Then
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_From", RequestAsString("StartDateText"))
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_To", RequestAsString("EndDateText"))
                End If

                If RequestAsString("iStartDateText") <> Nothing And RequestAsString("iEndDateText") <> Nothing Then
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_From", RequestAsString("iStartDateText"))
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_To", RequestAsString("iEndDateText"))
                End If

                If RequestAsString("StartDayText") <> Nothing And RequestAsString("EndDayText") <> Nothing Then
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_From", RequestAsDateTime("StartDayText").ToString(dateFormat))
                    Resources.UserSecurity.SetSetting("Report_Filter_Date_To", RequestAsDateTime("EndDayText").ToString(dateFormat))
                End If
            End If

            Resources.UserSecurity.SetSetting("Report_Filter_Is_Visible", RequestAsBoolean("IsVisible").ToString())
            Resources.UserSecurity.SetSetting("Report_Filter_Summary", RequestAsBoolean("ISummary").ToString())

            If Request("ViewDataWarnings") <> Nothing Then
                Resources.UserSecurity.SetSetting("Report_Filter_Data_Warnings", RequestAsBoolean("ViewDataWarnings").ToString())
            Else
                Resources.UserSecurity.SetSetting("Report_Filter_Data_Warnings", RequestAsBoolean("IViewDataWarnings").ToString())
            End If

            If Request("MinimumTonnes") <> Nothing Then
                Resources.UserSecurity.SetSetting("Minimum_Tonnes", RequestAsString("MinimumTonnes"))
            End If

            If Request("ProductTypeId") <> Nothing Then
                Resources.UserSecurity.SetSetting("ProductTypeId", RequestAsString("ProductTypeId"))
            End If

            If Request("LocationBreakdown") IsNot Nothing Then
                Resources.UserSecurity.SetSetting("Report_Location_Breakdown", RequestAsString("LocationBreakdown"))
            End If

            SingleSource = RequestAsString("SingleSource")
            Locations = RequestAsString("LocationIds")

            'Single Source
            Resources.UserSecurity.SetSetting("Report_Filter_SingleSource", SingleSource)
        End Sub

        Protected Overrides Sub SetupPageControls()

            SetupReport()

            'Swapped to be called before ProcessFormKeys otherwise the boolean fields
            'on the custom reports get set to false
            ProcessMissingBooleans()

            ProcessFormKeys()

            ReportRender()

        End Sub


        Protected Overrides Sub ReportRender()
            Dim format As Snowden.Common.Web.Reports.ReportExportFormat

            format = DirectCast(RequestAsInt32("ExportFormat"), Snowden.Common.Web.Reports.ReportExportFormat)

            PreRenderHook(format)

            Try
                Report.Render(format, Response)
            Catch ex As System.Web.Services.Protocols.SoapException
                Dim errorText = String.Format("Reporting services encountered an error: {0}", ex.ShortMessage.Truncate(410))
                Dim errorJavascript = String.Format("DisplayErrorForSSRS(""{0}"");", errorText)
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, errorJavascript))
            Catch ex As Exception
                Dim errorText = String.Format("Reporting services encountered an error: {0}", ex.Message.Truncate(410))
                Dim errorJavascript = String.Format("DisplayErrorForSSRS(""{0}"");", errorText)
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, errorJavascript))
            End Try

        End Sub

        Protected Overrides Sub ProcessFormKeys()
            Dim valStr As String
            Dim value As Common.Web.ReportExecution2005.ParameterValue
            Dim param As Common.Web.Reports.ReportingServicesReportParameter2005

            ' Process all Form and QueryString keys (the BHPB IO version processes querystring and form keys)
            For Each key As String In Request.Form.AllKeys.Union(Request.QueryString.AllKeys)
                valStr = RequestAsString(key)
                If valStr = Nothing Then valStr = String.Empty

                'Handle Date params
                If key.EndsWith("Text") AndAlso Report.Parameters.ContainsKey(key.Replace("Text", String.Empty)) Then
                    key = key.Replace("Text", String.Empty)
                End If

                'Handle Location Params
                If key.ToLower.Contains("locationid") And valStr = "-1" Then
                    valStr = String.Empty
                End If

                If (Report.Name = "Bhpbio_Core_Haulage_vs_Plant_Report" Or
                   Report.Name = "Bhpbio_Core_Stockpile_Balance_Report") Or
                   Report.Name = "BhpbioOutlierAnalysisChart" Then
                    If Report.Parameters.ContainsKey(key) Then
                        param = Report.Parameters(key)

                        If param.RSParameter.Type <> Common.Web.ReportingService2005.ParameterTypeEnum.Boolean Then
                            value = New Common.Web.ReportExecution2005.ParameterValue()
                            value.Name = key

                            If valStr = String.Empty AndAlso param.RSParameter.Nullable Then
                                value.Value = Nothing
                            Else
                                value.Value = valStr
                            End If

                            Report.Parameters(key).RSValue = value
                        End If
                    End If
                End If

                'Handle Bhpbio custom reports
                If Report.Name = "F1F2F3HUBReconciliationReport" Or Report.Name.StartsWith("Bhpbio") Then

                    Select Case (key.ToLower())
                        Case "locationid"
                            SetParameterValue(key, LocationId.ToString)
                        Case "locationgroupid"
                            SetParameterValue(key, LocationGroupId.ToString)
                        Case "datebreakdown", "blastlocationid"
                            SetParameterValue(key, valStr)
                        Case "designationmaterialtypeid"
                            If (valStr <> String.Empty) Then
                                IncludeDesignationMaterialTypeID = True
                                SetParameterValue(key, valStr)
                            Else
                                SetParameterValue(key, "0")
                            End If
                        Case "blastlocationname"
                            If (Report.Name = "BhpbioBlastByBlastReconciliationReport") Then
                                If (Request.Form.Item("blastlocationid") <> Nothing) Then
                                    SetParameterValue(key, GetLocationComment(Convert.ToInt32(Request.Form.Item("blastlocationid"))))
                                Else
                                    SetParameterValue(key, String.Empty)
                                End If
                            End If
                        Case "comparison1blockmodelid"
                            If (valStr = "Actuals") Then
                                Comparison1IsActuals = True
                                valStr = String.Empty
                            End If

                            If (valStr <> String.Empty) Then
                                SetParameterValue(key, valStr)
                            End If

                        Case "comparison2blockmodelid"
                            If (valStr = "Actuals") Then
                                Comparison2IsActuals = True
                                valStr = String.Empty
                            End If

                            If (valStr <> String.Empty) Then
                                SetParameterValue(key, valStr)
                            End If
                        Case "displayoptions"
                            If (valStr = "CompleteReport") Then
                                SetParameterValueBoolean("CompleteReport", True)
                            ElseIf (valStr = "WithoutHeaderFooter") Then
                                SetParameterValueBoolean("WithoutHeaderFooter", True)
                            ElseIf (valStr = "OnlyGraphs") Then
                                SetParameterValueBoolean("OnlyGraphs", True)
                            ElseIf (valStr = "OnlyTables") Then
                                SetParameterValueBoolean("OnlyTables", True)
                            End If

                            ' these reports are a special case - we don't want to save it if they have been run for graphs only
                            If Report.Name.StartsWith("BhpbioBenchErrorBy") AndAlso valStr.ToLower = "onlygraphs" Then
                                Resources.UserSecurity.SetSetting("Report_Display_Options", "CompleteReport")
                            End If
                        Case Else
                            Dim keyLower As String

                            keyLower = key.ToLower()

                            'Date From / Date To

                            If RequestAsString("nonParameterDateBreakdown") = "MONTH" Or RequestAsString("DateBreakdown") = "MONTH" Then
                                If (key.Contains("MonthPickerMonthPart")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromMonthPart = valStr
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToMonthPart = valStr
                                    End If
                                ElseIf (key.Contains("MonthPickerYearPart")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromYearPart = valStr
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToYearPart = valStr
                                    End If
                                End If


                            ElseIf RequestAsString("nonParameterDateBreakdown") = "QUARTER" Or RequestAsString("DateBreakdown") = "QUARTER" Then

                                If (key.Contains("QuarterSelect")) Then

                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate") Or keyLower.Contains("startandend")) Then
                                        DateFromMonthPart = DateBreakdown.ResolveDateFrom(valStr)
                                    End If

                                    If (keyLower.Contains("dateto") Or keyLower.Contains("enddate") Or keyLower.Contains("startandend")) Then
                                        DateToMonthPart = DateBreakdown.ResolveDateTo(valStr)
                                    End If

                                ElseIf (key.Contains("YearSelect")) Then

                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate") Or keyLower.Contains("startandend")) Then

                                        If DateTime.Parse("01-" + DateFromMonthPart + "-08").Month > 6 Then
                                            DateFromYearPart = (Convert.ToInt32(valStr) - 1).ToString()
                                        Else
                                            DateFromYearPart = valStr
                                        End If
                                    End If

                                    If (keyLower.Contains("dateto") Or keyLower.Contains("enddate") Or keyLower.Contains("startandend")) Then

                                        If DateTime.Parse("01-" + DateToMonthPart + "-08").Month > 6 Then
                                            DateToYearPart = (Convert.ToInt32(valStr) - 1).ToString()
                                        Else
                                            DateToYearPart = valStr
                                        End If

                                    End If
                                End If

                            Else

                                If (key.Contains("MonthPickerMonthPart")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromMonthPart = valStr
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToMonthPart = valStr
                                    End If
                                ElseIf (key.Contains("MonthPickerYearPart")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromYearPart = valStr
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToYearPart = valStr
                                    End If
                                ElseIf (key.Contains("QuarterSelect")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromMonthPart = DateBreakdown.ResolveDateFrom(valStr)
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToMonthPart = DateBreakdown.ResolveDateTo(valStr)
                                    End If
                                ElseIf (key.Contains("YearSelect")) Then
                                    If (keyLower.Contains("datefrom") Or keyLower.Contains("startdate")) Then
                                        DateFromYearPart = valStr
                                    ElseIf (keyLower.Contains("dateto") Or keyLower.Contains("enddate")) Then
                                        DateToYearPart = valStr
                                    End If
                                End If

                            End If

                            'Source
                            If (key.Contains("chkSource_")) Then
                                Dim blockModelId As String

                                If (key.Contains("MineProductionActuals")) Then
                                    IncludeActuals = True
                                Else
                                    IncludeBlockModels = True

                                    blockModelId = key.Replace("chkSource_", String.Empty)

                                    BlockModelsList &= "<BlockModel id=""" & blockModelId & """/>"
                                End If
                            End If

                            'Product Type
                            If (key.Contains("chkProductType")) Then
                                Dim productTypeId As String = key.Replace("chkProductType_", String.Empty)

                                If (Not String.IsNullOrEmpty(productTypeId)) Then
                                    If (Not String.IsNullOrEmpty(ProductTypeList)) Then
                                        ProductTypeList &= ","
                                    End If
                                    ProductTypeList &= productTypeId
                                End If
                            End If

                            ' context selection
                            If (key.Contains("chkContext_")) Then
                                Dim contextId As String = key.Replace("chkContext_", String.Empty)

                                If (Not String.IsNullOrEmpty(contextId)) Then
                                    If (Not String.IsNullOrEmpty(ContextSelectionList)) Then
                                        ContextSelectionList += ","
                                    End If

                                    ContextSelectionList += contextId
                                End If
                            End If

                            ' Stratigraphy Selection
                            If key.Contains("cmbStrat") Then
                                LowestStratigraphyLevel = RequestAsInt32("cmbStrat")
                            End If

                            'Grades
                            If ((key.Contains("chkGrade_"))) Then
                                Dim gradeID As String

                                If (key.Contains("Tonnes")) Then
                                    IncludeTonnes = True
                                ElseIf (key.Contains("Volume")) Then
                                    IncludeVolume = True
                                Else
                                    gradeID = key.Replace("chkGrade_", String.Empty)

                                    GradesList &= "<Grade id=""" & gradeID & """/>"
                                End If
                            End If

                            'Attributes
                            If (key.Contains("chkAttribute_")) Then
                                Dim attributeID, attributeName As String
                                Dim attParts() As String

                                attParts = key.Replace("chkAttribute_", String.Empty).Split(CChar("_"))

                                If (attParts.Length > 1) Then
                                    attributeID = attParts(0)
                                    attributeName = attParts(1)
                                    If Report.Name.StartsWith("BhpbioFactorsVsTime") Then
                                        If String.IsNullOrEmpty(AttributesList) Then
                                            AttributesList &= attributeName
                                        Else
                                            AttributesList &= String.Format(",{0}", attributeName)
                                        End If
                                    Else
                                        AttributesList &= String.Format("<Attribute id=""{0}"" name=""{1}""/>", attributeID, attributeName)
                                    End If
                                End If
                            End If

                            'Resource Classifications
                            If (key.Contains(ReportsStandardRender.CHK_RESOURCE_CLASSIFICATION)) Then
                                Dim resourceClassificationName As String

                                resourceClassificationName = key.Replace(ReportsStandardRender.CHK_RESOURCE_CLASSIFICATION, String.Empty)

                                If Report.Name.StartsWith("BhpbioFactorsVsTime") Then
                                    If String.IsNullOrEmpty(ResourceClassificationList) Then
                                        ResourceClassificationList &= resourceClassificationName
                                    Else
                                        ResourceClassificationList &= String.Format(",{0}", resourceClassificationName)
                                    End If
                                Else
                                    ResourceClassificationList &= String.Format("<RESOURCECLASSIFICATION id=""{0}"" name=""{0}""/>", resourceClassificationName)
                                End If
                            End If

                            'Products
                            If (key.Contains("chkProduct_")) Then
                                Dim productId, productName As String
                                Dim productParts() As String

                                productParts = key.Replace("chkProduct_", String.Empty).Split(CChar("_"))

                                If (productParts.Length > 1) Then
                                    productId = productParts(0)
                                    productName = productParts(1)

                                    ProductsList &= String.Format("<Product id=""{0}"" name=""{1}""/>", productId, productName)
                                End If
                            End If

                            'Factors
                            If (key.Contains("chkFactor_")) Then
                                Dim factorId As String = key.Replace("chkFactor_", String.Empty)

                                ' for these newer reports, we just use a comma separated list for the factors, not the xml as 
                                ' with the older ones
                                If Report.Name.StartsWith("BhpbioFactorsVsTime") Or Report.Name = "BhpbioDensityAnalysisReport" Then
                                    Select Case factorId
                                        Case "RecoveryFactorDensity"
                                            factorId = "RFD"
                                        Case "RecoveryFactorMoisture"
                                            factorId = "RFM"
                                        Case Else
                                            factorId = factorId.Replace("Factor", String.Empty)
                                    End Select
                                    If String.IsNullOrEmpty(FactorsList) Then
                                        FactorsList = factorId
                                    Else
                                        FactorsList &= String.Format(",{0}", factorId)
                                    End If
                                Else
                                    FactorsList &= String.Format("<Factor id=""{0}""/>", factorId)
                                End If
                            End If

                    End Select
                End If
            Next

            Select Case (Report.Name)
                '
                ' This case statement is from the orginal report development, you generally shouldn't need to add anything 
                ' to it, unless the report has some special parameters. Most of the time the parameter values should be
                ' sent through automatically, as long as the have the correct name
                '
                'Model Compartion Report / Grade Recovery Report
                Case "BhpbioModelComparisonReport", "BhpbioDesignationAttributeReport"
                    BlockModelsList = "<BlockModels>" & BlockModelsList & "</BlockModels>"
                    GradesList = "<Grades>" & GradesList & "</Grades>"

                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValueBoolean("IncludeActuals", IncludeActuals)

                    If (Report.Name = "BhpbioModelComparisonReport") Then
                        SetParameterValueBoolean("Tonnes", IncludeTonnes)
                    Else
                        SetParameterValueBoolean("IncludeTonnes", IncludeTonnes)
                        SetParameterValueBoolean("IncludeVolume", IncludeVolume)
                    End If

                    SetParameterValueBoolean("IncludeBlockModels", IncludeBlockModels)
                    SetParameterValueBoolean("IncludeDesignationMaterialTypeId", IncludeDesignationMaterialTypeID)
                    SetParameterValue("BlockModels", BlockModelsList)
                    SetParameterValue("Grades", GradesList)

                'F1F2F3 Hub Reconciliation Report
                Case "F1F2F3HUBReconciliationReport"
                    SetParameterValue("StartDate", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("EndDate", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))

                'Movement Recovery Report
                Case "BhpbioMovementRecoveryReport"
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValue("DateBreakdown", _datePeriod)
                    SetParameterValueBoolean("Comparison1IsActual", Comparison1IsActuals)
                    SetParameterValueBoolean("Comparison2IsActual", Comparison2IsActuals)

                'F1F3F3 Reconciliation by Attribute Report
                Case "BhpbioF1F2F3ReconciliationAttributeReport"
                    FactorsList = "<Factors>" & FactorsList & "</Factors>"
                    GradesList = "<Attributes>" & GradesList & "</Attributes>"
                    AttributesList = "<Attributes>" & AttributesList & "</Attributes>"

                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValue("Attributes", AttributesList)
                    SetParameterValue("Factors", FactorsList)

                'F1F3F3 Reconciliation by Reconciliation Comparison Report
                'F1F3F3 Reconciliation by Attribute Report
                Case "BhpbioF1F2F3ReconciliationLocationComparisonReport"
                    FactorsList = "<Factors>" & FactorsList & "</Factors>"
                    GradesList = "<Attributes>" & GradesList & "</Attributes>"
                    AttributesList = "<Attributes>" & AttributesList & "</Attributes>"

                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValue("Attributes", AttributesList)
                    SetParameterValue("Factors", FactorsList)

                'F1F3F3 Reconciliation by Reconciliation Comparison Report
                Case "BhpbioF1F2F3ReconciliationComparisonReport"
                    GradesList = "<Attributes>" & GradesList & "</Attributes>"
                    AttributesList = "<Attributes>" & AttributesList & "</Attributes>"

                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValue("Attributes", AttributesList)
                    SetParameterValue("LocationIds", Locations)
                    SetParameterValue("SingleSource", SingleSource)

                'Recovery Analysis Report
                Case "BhpbioRecoveryAnalysisReport"
                    BlockModelsList = "<BlockModels>" & BlockModelsList & "</BlockModels>"

                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValueBoolean("IncludeActuals", IncludeActuals)
                    SetParameterValueBoolean("IncludeBlockModels", IncludeBlockModels)
                    SetParameterValueBoolean("IncludeDesignationMaterialTypeId", IncludeDesignationMaterialTypeID)
                    SetParameterValue("BlockModels", BlockModelsList)

                'F1F2F3 Overview Recon Report
                Case "BhpbioF1F2F3OverviewReconReport", "BhpbioF1F2F3OverviewReconContributionReport"
                    SetParameterValue("StartDate", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("EndDate", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))

                Case "BhpbioLiveVersusSummaryReport"
                    SetParameterValue("StartDate", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("EndDate", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))

                Case "BhpbioRiskProfileReport"
                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))

                Case "BhpbioSupplyChainMonitoringReport", "BhpbioBenchErrorByAttributeReport", "BhpbioBenchErrorByLocationReport", "BhpbioReconciliationRangeReport"
                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))

                Case "BhpbioQuarterlySiteReconciliationReport", "BhpbioQuarterlyHubReconciliationReport"
                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))

                Case "BhpbioMonthlySiteReconciliationReport"
                    Dim dateFromString = DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart)
                    Dim dateToString = Date.Parse(dateFromString).AddMonths(1).AddDays(-1).ToString("O")
                    SetParameterValue("DateFrom", dateFromString)
                    SetParameterValue("DateTo", dateToString)

                Case "BhpbioFactorsVsTimeDensityReport", "BhpbioFactorsVsTimeMoistureReport", "BhpbioFactorsVsTimeVolumeReport"
                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                    SetParameterValue("Factors", FactorsList)

                Case "BhpbioYearlyReconciliationReport"
                    Dim dateFromString = DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart)
                    Dim dateToString = Date.Parse(dateFromString).AddMonths(1).AddDays(-1).ToString("yyyy-MM-dd")
                    SetParameterValue("DateFrom", dateFromString)
                    SetParameterValue("DateTo", dateToString)
            End Select

            If Report.Name = "BhpbioQuarterlyHubReconciliationReport" And Report.Parameters.ContainsKey("LocationIds") Then
                ' example: "<Locations><Location id='5'/></Locations>"
                SetParameterValue("LocationIds", Me.GetChildLocationsXml(Report))
            End If

            ' the date needs to be the start of the *next* period for this report. This is a hassle to do in js, so
            ' we do it here. This will be passed through to the RDL and then through to the datasource, so it should
            ' be a pretty safe way of doing it
            If Report.Name = "BhpbioRiskProfileReport" Or Report.Name = "BhpbioForwardErrorContributionContextReport" Then
                Dim selectedDate = Date.Parse(DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))

                If _datePeriod = "MONTH" Then
                    selectedDate = selectedDate.AddMonths(1)
                ElseIf _datePeriod = "QUARTER" Then
                    selectedDate = selectedDate.AddMonths(3)
                End If

                SetParameterValue("DateFrom", selectedDate.ToString("yyyy-MM-dd"))
            End If

            If Report.Name = "BhpbioForwardErrorContributionContextReport" Then
                ' this is a linked report, so we need to set the dateTo as well. Set it to the same as the dateFrom
                SetParameterValue("DateTo", Report.Parameters("DateFrom").RSValue.Value)
            End If

            ' if we have some attribute values, and the parameter has not been set, then set it. This is a fallthrough
            ' if it hasn't already been set above as a special case
            If Report.Name.ToLower.StartsWith("bhpbio") Or Report.Name = "F1F2F3HUBReconciliationReport" Then
                If HasAttributesParameter() Then
                    If AttributesList Is Nothing Then AttributesList = ""

                    ' ultrafines has a different name and description. due to the way the reports work, the easiest way to do this is to just
                    ' normalize the attribute name here
                    AttributesList = AttributesList.Replace("Ultrafines-in-fines", "Ultrafines")

                    If Report.Name.StartsWith("BhpbioFactorsVsTime") Then
                        SetParameterValue("Attributes", AttributesList)
                    Else
                        SetParameterValue("Attributes", "<Attributes>" & AttributesList & "</Attributes>")
                    End If

                    If Report.Name.Equals("BhpbioFactorsVsTimeResourceClassificationReport") Then
                        If ResourceClassificationList Is Nothing Then ResourceClassificationList = ""
                        SetParameterValue("ResourceClassifications", ResourceClassificationList)
                    End If

                End If

                    If Not String.IsNullOrEmpty(ProductTypeList) AndAlso Report.Parameters("ProductTypeIds").RSValue Is Nothing Then
                    SetParameterValue("ProductTypeIds", ProductTypeList)
                End If

                If Not FactorsList Is Nothing AndAlso FactorsList.Length > 0 AndAlso Report.Parameters("Factors").RSValue Is Nothing Then
                    If FactorsList.StartsWith("<Factor ") Then FactorsList = "<Factors>" + FactorsList + "</Factors>"
                    SetParameterValue("Factors", FactorsList)
                End If

                If Not BlockModelsList Is Nothing AndAlso BlockModelsList.Length > 0 _
                    AndAlso Report.Parameters("BlockModels").RSValue Is Nothing Then
                    SetParameterValue("BlockModels", "<BlockModels>" & BlockModelsList & "</BlockModels>")
                End If

                If Report.Parameters.ContainsKey("ContextSelection") Then
                    If Not String.IsNullOrEmpty(ContextSelectionList) AndAlso Report.Parameters("ContextSelection").RSValue Is Nothing Then
                        SetParameterValue("ContextSelection", ContextSelectionList)
                    Else
                        SetParameterValue("ContextSelection", "")
                    End If
                End If

                If Report.Parameters.ContainsKey(NameOf(LowestStratigraphyLevel)) Then
                    SetParameterValue(NameOf(LowestStratigraphyLevel), LowestStratigraphyLevel.ToString())
                End If

                ' have the dates been set yet? if not assume it is the standard case with the date
                If Report.Parameters.Keys.Contains("DateFrom") AndAlso Report.Parameters("DateFrom").RSValue Is Nothing Then
                    SetParameterValue("DateFrom", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                End If

                If Report.Parameters.Keys.Contains("DateTo") AndAlso Report.Parameters("DateTo").RSValue Is Nothing Then
                    SetParameterValue("DateTo", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                End If

                If Report.Parameters.Keys.Contains("StartDate") AndAlso Report.Parameters("StartDate").RSValue Is Nothing Then
                    SetParameterValue("StartDate", DateBreakdown.GetDateFromUsingMonth(DateFromMonthPart, DateFromYearPart))
                End If

                If Report.Parameters.Keys.Contains("EndDate") AndAlso Report.Parameters("EndDate").RSValue Is Nothing Then
                    SetParameterValue("EndDate", DateBreakdown.GetDateToUsingMonth(DateToMonthPart, DateToYearPart))
                End If

                If Report.Parameters.Keys.Contains("StartDay") AndAlso Report.Parameters("StartDay").RSValue Is Nothing Then
                    SetParameterValue("StartDay", RequestAsDateTime("StartDayText").ToString("yyyy-MM-dd"))
                End If

                If Report.Parameters.Keys.Contains("EndDay") AndAlso Report.Parameters("EndDay").RSValue Is Nothing Then
                    SetParameterValue("EndDay", RequestAsDateTime("EndDayText").ToString("yyyy-MM-dd"))
                End If

                If Report.Parameters.Keys.Contains("ReportContext") AndAlso Report.Parameters("ReportContext").RSValue Is Nothing Then
                    Dim parameterValue = RequestAsString("ReportContext")
                    If parameterValue IsNot Nothing Then
                        SetParameterValue("ReportContext", parameterValue)
                    End If
                End If

                ' the location group id needs to be separately, because it is set on the paramters page by the locationId picker
                If Report.Parameters.Keys.Contains("LocationGroupId") AndAlso Report.Parameters("LocationGroupId").RSValue Is Nothing Then
                    SetParameterValue("LocationGroupId", LocationGroupId.ToString)
                End If

            End If

            ' protect this block to only run with the new reports - really it should run by default for everything, like it 
            ' does in Core. But I don't have time to test all that now...
            If Not _oldReports.Contains(Report.Name) Then

                ' maybe there are some parameters that aren't mentioned specifically about - we want to loop through
                ' the form fields again and copy them across
                For Each key As String In Request.Form.AllKeys
                    valStr = RequestAsString(key)
                    If valStr = Nothing Then valStr = String.Empty

                    ' if the parameter for that form field exists, and it hasn't been set yet, then set the value
                    ' Note that SetParameterValue will do nothing if the value is a boolean - these get set somewhere
                    ' else
                    If Report.Parameters.ContainsKey(key) AndAlso Report.Parameters(key).RSValue Is Nothing Then
                        SetParameterValue(key, valStr)
                    End If
                Next
            End If

            ' sometimes with the product type reports, we need to set the location_id
            If LocationIdComesFromProductType(Report.Name) AndAlso Report.Parameters("ProductTypeId").RSValue IsNot Nothing Then
                Dim productTypeId = Convert.ToInt32(Report.Parameters("ProductTypeId").RSValue.Value)

                ' if the ID is not zero, then we assume that they user has set it, and it needs to be transferred over
                If productTypeId > 0 Then
                    Dim productTypes = Types.ProductType.FromDataTable(DalUtilityBhpbio.GetBhpbioProductTypesWithLocationIds())
                    Dim productType = productTypes.FirstOrDefault(Function(r) r.ProductTypeID = productTypeId)
                    If productType Is Nothing Then Throw New Exception("Unknown ProductType with ID - " + productTypeId.ToString)
                    SetParameterValue("LocationId", productType.LocationId.ToString)
                End If
            End If

            ' somtimes a report has a product type id parameter for the linked reports that use it, but when the
            ' report is run directly, we want it to always have a default value
            If MustResetProductTypeId(Report.Name) And Report.Parameters.ContainsKey("ProductTypeId") Then
                Dim productTypeId = -1
                SetParameterValue("ProductTypeId", productTypeId.ToString)
            End If

        End Sub

        ' these reprots have a ProductTypeId because it is needed by the linked reports that call them, but
        ' it needs to be set to -1 when the NON linked reports are run, so that the report knows its not in
        ' product type mode.
        '
        ' This used to be done with the default parameter values, but this was dangerous because the default
        ' keeps getting changed back durning development, introducing regressions
        Private Function MustResetProductTypeId(reportName As String) As Boolean
            Dim reportList = New String() {
                "BhpbioSupplyChainMonitoringReport",
                "BhpbioF1F2F3ReconciliationAttributeReport"
            }

            Return reportList.Contains(reportName)
        End Function

        Private Function LocationIdComesFromProductType(reportName As String) As Boolean
            Dim reportList = New String() {
                "BhpbioF1F2F3ProductReconContributionReport",
                "BhpbioF1F2F3ReconciliationProductAttributeReport",
                "BhpbioFactorsByLocationVsShippingTargetsReport",
                "BhpbioFactorsVsShippingTargetsReport"
            }

            Return reportList.Contains(reportName)
        End Function

        Private Function HasAttributesParameter() As Boolean
            Return Report.Parameters.Where(Function(kv) kv.Key = "Attributes" Or kv.Key.StartsWith("Attributes" & ReportsStandardRender.ParameterWithMarker)).Count() > 0
        End Function

        Private Function GetChildLocationsXml(ByVal report As ReportingServicesReport2005) As String

            Dim locationId As Integer = Integer.Parse(report.Parameters("LocationId").RSValue.Value)
            Dim dateFrom As DateTime = DateTime.Parse(report.Parameters("DateFrom").RSValue.Value)
            Dim dateTo As DateTime = DateTime.Parse(report.Parameters("DateTo").RSValue.Value)

            Return Me.GetChildLocationsXml(locationId, dateFrom, dateTo)
        End Function

        Private Function GetChildLocationsXml(ByVal locationId As Integer, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As String
            Dim locationIds = DalUtilityBhpbio.GetBhpbioLocationChildrenNameWithOverride(locationId, dateFrom, dateTo)
            Dim locationIdsXml As String = ""

            For Each row As DataRow In locationIds.Rows
                locationIdsXml += String.Format("<Location id=""{0}"" />", Convert.ToInt32(row("Location_Id")))
            Next

            ' example: "<Locations><Location id='5'/></Locations>"
            Return String.Format("<Locations>{0}</Locations>", locationIdsXml)
        End Function


        Private Function GetLocationComment(ByVal locationId As Integer) As String
            Dim session As New ReportSession(Resources.ConnectionString)
            Dim result As String

            Try
                result = Data.ReportDisplayParameter.GetLocationComment(session, locationId)
            Finally
                If Not (session Is Nothing) Then
                    session.Dispose()
                    session = Nothing
                End If
            End Try

            Return result
        End Function

        Protected Overridable Sub SetParameterValue(ByVal key As String, ByVal value As String)
            Dim parameterValue As Common.Web.ReportExecution2005.ParameterValue
            Dim param As Common.Web.Reports.ReportingServicesReportParameter2005 = Nothing

            ' if the parameters starts with "<key>_with_" then we match it to "<key>" this is so we can have list parameters with
            ' default items that are always included
            For Each p As Common.Web.Reports.ReportingServicesReportParameter2005 In Report.Parameters.Values
                If (p.RSParameter.Name = key OrElse p.RSParameter.Name.StartsWith(key + ReportsStandardRender.ParameterWithMarker)) Then
                    param = p
                    Exit For
                End If
            Next

            If (param Is Nothing) Then
                Throw New ArgumentException("A parameter matching the specified key was not found", "key")
            End If

            If param.RSParameter.Type <> Common.Web.ReportingService2005.ParameterTypeEnum.Boolean Then
                parameterValue = New Common.Web.ReportExecution2005.ParameterValue()
                parameterValue.Name = param.RSParameter.Name

                If value = String.Empty AndAlso param.RSParameter.Nullable Then
                    parameterValue.Value = Nothing
                Else
                    parameterValue.Value = value
                End If

                param.RSValue = parameterValue
            End If
        End Sub

        Protected Overridable Sub SetParameterValueBoolean(ByVal key As String, ByVal value As Boolean)
            Dim parameterValue As Common.Web.ReportExecution2005.ParameterValue
            Dim param As Common.Web.Reports.ReportingServicesReportParameter2005

            param = Report.Parameters(key)

            If param.RSParameter.Type = Common.Web.ReportingService2005.ParameterTypeEnum.Boolean Then
                parameterValue = New Common.Web.ReportExecution2005.ParameterValue()
                parameterValue.Name = key
                parameterValue.Value = value.ToString()
                Report.Parameters(key).RSValue = parameterValue
            End If
        End Sub

    End Class


End Namespace
