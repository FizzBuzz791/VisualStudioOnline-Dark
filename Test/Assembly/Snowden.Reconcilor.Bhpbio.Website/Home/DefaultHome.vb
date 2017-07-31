Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Home
    Public Class DefaultHome
        Inherits Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates.HomeTemplate

#Region " Properties "
        Protected Const reportName As String = "F1F2F3HUBReconciliationReport"

        Private _disposed As Boolean
        Private _siteId As Integer

        Private _dalUtility As IUtility
        Private _dalReport As IReport
        Private _homeForm As New Tags.HtmlFormTag
        Private _backgroundDiv As New Tags.HtmlDivTag

        Private _layoutTable As New Tags.HtmlTableTag
        Private _headerDiv As New Tags.HtmlDivTag()
        Private _homeFilter As FilterBoxes.Home.HomeFilter
        Private _map As New ImageMap
        Private _showGraphs As Boolean
        Private _showGraphsValue As New HtmlControls.HtmlInputHidden

        Private _messageOnly As Boolean
        Private _messageOnlyValue As New HtmlControls.HtmlInputHidden

        Private _siteFilterSelect As New ReconcilorControls.InputTags.SelectBox
        Private _siteFilter As New Tags.HtmlTableTag
        Private _sitefilterButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)

        Private _homescreenLinkImage As New Tags.HtmlAnchorTag
        Private _homescreenlink As New Tags.HtmlTableTag

        Private _homescreenViewBox As New ReconcilorControls.GroupBox
        Private _homescreenView As New Tags.HtmlTableTag
        Private _printButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _processMapButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)

        Private _reportsTable As New Tags.HtmlTableTag
        Private _actionRegisterCurrentButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _actionRegisterHistoricalButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _technicalSummaryCurrentButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _technicalSummaryHistoricalButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _reconSummaryCurrentButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
        Private _reconSummaryHistoricalButton As New ReconcilorControls.InputTags.InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)

        Private _siteMapsTable As New Tags.HtmlTableTag

        Private _hubData As DataTable
        Private _locationData As DataTable
        Private _showSiteFilter As Boolean = False

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Property DalReport() As IReport
            Get
                Return _dalReport
            End Get
            Set(ByVal value As IReport)
                _dalReport = value
            End Set
        End Property

        Protected Property SiteID() As Integer
            Get
                Return _siteId
            End Get
            Set(ByVal value As Integer)
                _siteId = value
            End Set
        End Property

        Protected Property BackgroundDiv() As Tags.HtmlDivTag
            Get
                Return _backgroundDiv
            End Get
            Set(ByVal value As Tags.HtmlDivTag)
                _backgroundDiv = value
            End Set
        End Property

        Protected Property HeaderDiv() As Tags.HtmlDivTag
            Get
                Return _headerDiv
            End Get
            Set(ByVal value As Tags.HtmlDivTag)
                _headerDiv = value
            End Set
        End Property

        Protected Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                If (Not value Is Nothing) Then
                    _layoutTable = value
                End If
            End Set
        End Property

        Protected ReadOnly Property HomeFilter() As FilterBoxes.Home.HomeFilter
            Get
                Return _homeFilter
            End Get
        End Property

        Protected ReadOnly Property Map() As ImageMap
            Get
                Return _map
            End Get
        End Property


        Protected Property ShowGraphs() As Boolean
            Get
                Return _showGraphs
            End Get
            Set(ByVal value As Boolean)
                _showGraphs = value
            End Set
        End Property

        Protected Property ShowGraphsValue() As HtmlControls.HtmlInputHidden
            Get
                Return _showGraphsValue
            End Get
            Set(ByVal value As HtmlControls.HtmlInputHidden)
                If (Not value Is Nothing) Then
                    _showGraphsValue = value
                End If
            End Set
        End Property

        Protected Property MessageOnly() As Boolean
            Get
                Return _messageOnly
            End Get
            Set(ByVal value As Boolean)
                _messageOnly = value
            End Set
        End Property

        Protected Property MessageOnlyValue() As HtmlControls.HtmlInputHidden
            Get
                Return _messageOnlyValue
            End Get
            Set(ByVal value As HtmlControls.HtmlInputHidden)
                If (Not value Is Nothing) Then
                    _messageOnlyValue = value
                End If
            End Set
        End Property
        Protected ReadOnly Property SiteFilterSelect() As ReconcilorControls.InputTags.SelectBox
            Get
                Return _siteFilterSelect
            End Get
        End Property

        Protected Property SiteFilter() As Tags.HtmlTableTag
            Get
                Return _siteFilter
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                _siteFilter = value
            End Set
        End Property

        Protected ReadOnly Property SiteFilterButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _sitefilterButton
            End Get
        End Property

        Protected Property HomescreenLinkImage() As Tags.HtmlAnchorTag
            Get
                Return _homescreenLinkImage
            End Get
            Set(ByVal value As Tags.HtmlAnchorTag)
                _homescreenLinkImage = value
            End Set

        End Property

        Protected Property HomescreenLink() As Tags.HtmlTableTag
            Get
                Return _homescreenlink
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                _homescreenlink = value
            End Set
        End Property

        Protected Property HomescreenView() As Tags.HtmlTableTag
            Get
                Return _homescreenView
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                If (Not value Is Nothing) Then
                    _homescreenView = value
                End If
            End Set
        End Property

        Protected Property HomescreenViewBox() As ReconcilorControls.GroupBox
            Get
                Return _homescreenViewBox
            End Get
            Set(ByVal value As ReconcilorControls.GroupBox)
                If (Not value Is Nothing) Then
                    _homescreenViewBox = value
                End If
            End Set
        End Property

        Protected Property PrintButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _printButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _printButton = value
                End If
            End Set
        End Property

        Protected Property ProcessMapButton() As Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _processMapButton
            End Get
            Set(ByVal value As Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _processMapButton = value
                End If
            End Set
        End Property

        Protected Property ActionRegisterCurrentButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _actionRegisterCurrentButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _actionRegisterCurrentButton = value
                End If
            End Set
        End Property

        Protected Property ActionRegisterHistoricalButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _actionRegisterHistoricalButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _actionRegisterHistoricalButton = value
                End If
            End Set
        End Property

        Protected Property TechnicalSummaryCurrentButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _technicalSummaryCurrentButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _technicalSummaryCurrentButton = value
                End If
            End Set
        End Property

        Protected Property TechnicalSummaryHistoricalButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _technicalSummaryHistoricalButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _technicalSummaryHistoricalButton = value
                End If
            End Set
        End Property

        Protected Property ReconSummaryCurrentButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _reconSummaryCurrentButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _reconSummaryCurrentButton = value
                End If
            End Set
        End Property

        Protected Property ReconSummaryHistoricalButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _reconSummaryHistoricalButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                If (Not value Is Nothing) Then
                    _reconSummaryHistoricalButton = value
                End If
            End Set
        End Property

        Protected Property ReportsTable() As Tags.HtmlTableTag
            Get
                Return _reportsTable
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                If (Not value Is Nothing) Then
                    _reportsTable = value
                End If
            End Set
        End Property
        Protected Property SiteMapsTable() As Tags.HtmlTableTag
            Get
                Return _siteMapsTable
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                If (Not value Is Nothing) Then
                    _siteMapsTable = value
                End If
            End Set
        End Property

#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        If (Not _dalReport Is Nothing) Then
                            _dalReport.Dispose()
                            _dalReport = Nothing
                        End If

                        If (Not _homeForm Is Nothing) Then
                            _homeForm.Dispose()
                            _homeForm = Nothing
                        End If

                        If Not (_layoutTable Is Nothing) Then
                            _layoutTable.Dispose()
                            _layoutTable = Nothing
                        End If

                        If (Not _headerDiv Is Nothing) Then
                            _headerDiv.Dispose()
                            _headerDiv = Nothing
                        End If

                        If (Not _backgroundDiv Is Nothing) Then
                            _backgroundDiv.Dispose()
                            _backgroundDiv = Nothing
                        End If

                        If (Not _homeFilter Is Nothing) Then
                            _homeFilter.Dispose()
                            _homeFilter = Nothing
                        End If

                        If (Not _map Is Nothing) Then
                            _map.Dispose()
                            _map = Nothing
                        End If

                        If (Not _siteFilter Is Nothing) Then
                            _siteFilter.Dispose()
                            _siteFilter = Nothing
                        End If

                        If (Not _siteFilterSelect Is Nothing) Then
                            _siteFilterSelect.Dispose()
                            _siteFilterSelect = Nothing
                        End If

                        If (Not _sitefilterButton Is Nothing) Then
                            _sitefilterButton.Dispose()
                            _sitefilterButton = Nothing
                        End If

                        If (Not _homescreenLinkImage Is Nothing) Then
                            _homescreenLinkImage.Dispose()
                            _homescreenLinkImage = Nothing
                        End If

                        If (Not _homescreenlink Is Nothing) Then
                            _homescreenlink.Dispose()
                            _homescreenlink = Nothing
                        End If

                        If (Not _homescreenViewBox Is Nothing) Then
                            _homescreenViewBox.Dispose()
                            _homescreenViewBox = Nothing
                        End If

                        If (Not _homescreenView Is Nothing) Then
                            _homescreenView.Dispose()
                            _homescreenView = Nothing
                        End If

                        If (Not _showGraphsValue Is Nothing) Then
                            _showGraphsValue.Dispose()
                            _showGraphsValue = Nothing
                        End If

                        If (Not _printButton Is Nothing) Then
                            _printButton.Dispose()
                            _printButton = Nothing
                        End If

                        If (Not _processMapButton Is Nothing) Then
                            _processMapButton.Dispose()
                            _processMapButton = Nothing
                        End If

                        If (Not _actionRegisterCurrentButton Is Nothing) Then
                            _actionRegisterCurrentButton.Dispose()
                            _actionRegisterCurrentButton = Nothing
                        End If

                        If (Not _actionRegisterHistoricalButton Is Nothing) Then
                            _actionRegisterHistoricalButton.Dispose()
                            _actionRegisterHistoricalButton = Nothing
                        End If

                        If (Not _technicalSummaryCurrentButton Is Nothing) Then
                            _technicalSummaryCurrentButton.Dispose()
                            _technicalSummaryCurrentButton = Nothing
                        End If

                        If (Not _technicalSummaryHistoricalButton Is Nothing) Then
                            _technicalSummaryHistoricalButton.Dispose()
                            _technicalSummaryHistoricalButton = Nothing
                        End If

                        If (Not _reconSummaryCurrentButton Is Nothing) Then
                            _reconSummaryCurrentButton.Dispose()
                            _reconSummaryCurrentButton = Nothing
                        End If


                        If (Not _reconSummaryHistoricalButton Is Nothing) Then
                            _reconSummaryHistoricalButton.Dispose()
                            _reconSummaryHistoricalButton = Nothing
                        End If

                        If (Not _reportsTable Is Nothing) Then
                            _reportsTable.Dispose()
                            _reportsTable = Nothing
                        End If

                        If (Not _siteMapsTable Is Nothing) Then
                            _siteMapsTable.Dispose()
                            _siteMapsTable = Nothing
                        End If

                        If (Not _hubData Is Nothing) Then
                            _hubData.Dispose()
                            _hubData = Nothing
                        End If

                        If (Not _locationData Is Nothing) Then
                            _locationData.Dispose()
                            _locationData = Nothing
                        End If

                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not (Request("SiteId") Is Nothing) Then
                SiteID = Convert.ToInt32(Request("SiteId"))
            Else
                SiteID = 0
            End If

            If Not (Request("ShowGraphs") Is Nothing) Then
                ShowGraphs = Convert.ToBoolean(Request("ShowGraphs"))
            End If

            MessageOnly = (SiteID = 0 Or SiteID = Nothing) And (ShowGraphs = False Or ShowGraphs = Nothing)
        End Sub

        Protected Overridable Function GetPrintReportId() As Int32
            Dim table = DalReport.GetReportList()
            Dim reportId As Int32

            For Each row As DataRow In table.Rows
                If row("Name").ToString().ToUpper() = reportName.ToUpper() Then
                    Int32.TryParse(row("Report_Id").ToString(), reportId)
                End If
            Next

            Return reportId
        End Function

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            'Home Form
            _homeForm.ID = "homeForm"

            'Page Title
            Dim siteName As String = "WAIO"

            If (SiteID <> 0) Then
                _locationData = DalUtility.GetLocationList(1, DoNotSetValues.Int32, SiteID, DoNotSetValues.Int16)

                If (_locationData.Rows.Count > 0) Then
                    siteName = _locationData.Rows(0).Item("Description").ToString
                End If
            End If

            'set background
            With ReconcilorContent.ContainerContent
                If (siteName.ToLower() = "yandi") Then
                    .StyleClass = "yandiBackground"
                ElseIf (siteName.ToLower() = "area c") Then
                    .StyleClass = "areaCBackground"
                ElseIf (siteName.ToLower() = "njv") Then
                    .StyleClass = "njvBackground"
                ElseIf (siteName.ToLower() = "yarrie") Then
                    .StyleClass = "yarrieBackground"
                End If
            End With

            'Filter
            HomeFilter.Resources = Resources
            HomeFilter.LocationId = SiteID
            HomeFilter.SiteId = SiteID

            'Homescreen View
            HomescreenViewBox.Title = "  Homescreen View  "

            ShowGraphsValue.ID = "HomeShowGraphsValue"
            ShowGraphsValue.Value = ShowGraphs.ToString()

            MessageOnlyValue.ID = "HomeMessageOnlyValue"
            MessageOnlyValue.Value = MessageOnly.ToString()

            PrintButton.Text = "  Print  "
            PrintButton.OnClientClick = String.Format("PrintFFactorReport({0});", GetPrintReportId())

            ProcessMapButton.Text = " Process Map/Production Figures "
            ProcessMapButton.Disabled = True

            'Site Filter 
            SetHubSites()
            SiteFilter.Visible = _showSiteFilter

            With SiteFilterButton
                .Text = "Evaluate"
                .OnClientClick = "return SelectSite();"
            End With

            'Map (if default home page)
            If (SiteID = 0) Then
                GetHubs()

                Dim site1 As New System.Web.UI.WebControls.RectangleHotSpot
                With site1
                    .NavigateUrl = "./Default.aspx?SiteId=" & GetLocationID("Yarrie")
                    .Left = 860
                    .Top = 33
                    .Right = 1075
                    .Bottom = 100
                End With

                Dim site2 As New System.Web.UI.WebControls.RectangleHotSpot
                With site2
                    .NavigateUrl = "./Default.aspx?SiteId=" & GetLocationID("Yandi")
                    .Left = 265
                    .Top = 195
                    .Right = 534
                    .Bottom = 275
                End With

                Dim site3 As New System.Web.UI.WebControls.RectangleHotSpot
                With site3
                    .NavigateUrl = "./Default.aspx?SiteId=" & GetLocationID("AreaC")
                    .Left = 220
                    .Top = 295
                    .Right = 490
                    .Bottom = 375
                End With

                Dim site4 As New System.Web.UI.WebControls.RectangleHotSpot
                With site4
                    .NavigateUrl = "./Default.aspx?SiteId=" & GetLocationID("NJV")
                    .Left = 480
                    .Top = 460
                    '.Right = 990
                    .Right = 880
                    .Bottom = 570
                End With

                Dim site5 As New System.Web.UI.WebControls.RectangleHotSpot
                With site5
                    .NavigateUrl = "./Default.aspx?SiteId=" & GetLocationID("Jimblebar")
                    .Left = 880
                    .Top = 460
                    .Right = 990
                    .Bottom = 570
                End With

                With Map
                    .ImageUrl = "../images/homescreenMap.gif"
                    .BorderStyle = BorderStyle.Solid
                    .BorderWidth = 2
                    .BorderColor = Drawing.Color.Black

                    .HotSpotMode = HotSpotMode.Navigate
                    .HotSpots.Add(site1)
                    .HotSpots.Add(site2)
                    .HotSpots.Add(site3)
                    .HotSpots.Add(site4)
                    .HotSpots.Add(site5)
                End With
            End If

            'Homescreen button (if site/hub homepage)
            With HomescreenLinkImage
                .Href = "./Default.aspx"
                .InnerHtml = "<img src=""../images/WAIOHomescreen.jpg"" border=""0""/>"
            End With

            'Reports
            With ActionRegisterCurrentButton
                .Text = "  Action Register Current  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_ACTION_REGISTER_CURRENT")
            End With

            With ActionRegisterHistoricalButton
                .Text = "  Action Register Historical  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_ACTION_REGISTER_HISTORICAL")
            End With

            With TechnicalSummaryCurrentButton
                .Text = "  Technical Summary Report Current  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_TECHNICAL_SUMMARY_REPORT_CURRENT")
            End With

            With TechnicalSummaryHistoricalButton
                .Text = "  Technical Summary Report Historical  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_TECHNICAL_SUMMARY_REPORT_HISTORICAL")
            End With

            With ReconSummaryCurrentButton
                .Text = "  Reconciliation Summary Report Current  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_RECONCILIATION_SUMMARY_REPORT_CURRENT")
            End With

            With ReconSummaryHistoricalButton
                .Text = "  Reconciliation Summary Report Historical  "
                .Style.Add("width", "100%")
                .OnClientClick = GetReportLink("BHPBIO_RECONCILIATION_SUMMARY_REPORT_HISTORICAL")
            End With

        End Sub

        Private Function GetReportLink(ByVal reportName As String) As String
            Dim link As String = ""
            Dim reportPath As String

            reportPath = DalUtility.GetSystemSetting(reportName)

            link = "window.open('" & reportPath.Replace("\", "\\") & "');"

            Return link
        End Function
        Private Function GetSiteMapLink(ByVal url As String) As String
            Return "window.open('" & url.Replace("\", "\\") & "');"
        End Function

        Private Function GetLocationID(ByVal locationName As String) As String
            Dim locationID As String = ""
            Dim rows() As DataRow

            rows = _hubData.Select("Name = '" + locationName + "'")

            If (rows.Length > 0) Then
                locationID = rows(0).Item("Location_Id").ToString()
            End If

            Return locationID
        End Function

        ''' <summary>
        ''' Determines the data table to use for the parent location. 
        ''' </summary>
        ''' <remarks>Could use the locationdata already stored if it is at the hub level, or if it is at the site then retrieve the parent.</remarks>
        Private Function GetHubLocationData() As DataTable
            Dim returnTable As DataTable = _locationData
            Dim locationType As String = ""
            Dim row As DataRow = Nothing
            Dim locationId As Int32

            If Not returnTable Is Nothing AndAlso returnTable.Rows.Count > 0 Then
                row = returnTable.Rows(0)
            End If

            If Not row Is Nothing Then
                locationType = row.Item("Location_Type_Description").ToString()
                Int32.TryParse(row.Item("Parent_Location_Id").ToString(), locationId)
            End If

            If locationType.ToLower() <> "hub" Then
                returnTable = DalUtility.GetLocationList(1, DoNotSetValues.Int32, locationId, DoNotSetValues.Int16)
            End If

            Return returnTable
        End Function

        ''' <summary>
        ''' Add in the Top ListItems to the select box.
        ''' </summary>
        Private Sub AddParentLocationListItem(ByVal locationTable As DataTable,
         ByVal selectBox As ReconcilorControls.InputTags.SelectBox)
            Dim locationType As String = ""
            Dim locationDescription As String = ""
            Dim locationId As Int32

            If Not locationTable Is Nothing AndAlso locationTable.Rows.Count > 0 Then
                With locationTable.Rows(0)
                    Int32.TryParse(.Item("Location_Id").ToString(), locationId)
                    locationDescription = .Item("Description").ToString()
                    locationType = .Item("Location_Type_Description").ToString()
                End With
            End If

            If (locationType.ToLower() <> "company") Then
                _siteFilterSelect.Items.Insert(0, New ListItem(locationDescription, locationId.ToString))
                _siteFilterSelect.Items.Insert(1, New ListItem("-------------------", ""))
            End If
        End Sub

        ''' <summary>
        ''' Setups the Select Box for Site Drilldown.
        ''' </summary>
        Private Sub SetHubSites()
            Dim siteData As New DataTable
            Dim locationId As Int32
            Dim parentData As DataTable = GetHubLocationData()

            ' Retrieve the 
            If Not parentData Is Nothing AndAlso parentData.Rows.Count > 0 Then
                Int32.TryParse(parentData.Rows(0).Item("Location_Id").ToString(), locationId)
            End If

            'Get children for this location (Sites)
            siteData = DalUtility.GetLocationList(2, locationId, DoNotSetValues.Int32, DoNotSetValues.Int16)

            'Exclude Yarrie from sites list
            For Each row As DataRow In siteData.Select("Name = 'Yarrie'")
                siteData.Rows.Remove(row)
            Next

            siteData.AcceptChanges()

            If (siteData.Rows.Count > 1) Then
                _siteFilterSelect.ID = "HomeSiteFilter"
                _siteFilterSelect.DataTextField = "Description"
                _siteFilterSelect.DataValueField = "Location_Id"
                _siteFilterSelect.DataSource = siteData
                _siteFilterSelect.DataBind()

                ' Add the extra rows at the top for the parent (Hub)
                AddParentLocationListItem(parentData, _siteFilterSelect)

                _siteFilterSelect.SelectedValue = SiteID.ToString
                _showSiteFilter = True
            Else
                _showSiteFilter = False
            End If

            If Not (siteData Is Nothing) Then
                siteData.Dispose()
                siteData = Nothing
            End If
        End Sub

        Private Sub GetHubs()
            Dim _locationTypeData As DataTable
            Dim _locationResultData As DataTable
            Dim hubLocationTypeID, siteLocationTypeID As Short
            Dim row() As DataRow

            _hubData = New DataTable()

            'Get location type data
            _locationTypeData = DalUtility.GetLocationTypeList(DoNotSetValues.Int16)

            'Get location type id for hubs
            row = _locationTypeData.Select("Description = 'Hub'")

            If (row.Length > 0) Then
                hubLocationTypeID = CShort(row(0).Item("Location_Type_Id"))
            End If

            'Get all hubs
            _hubData = DalUtility.GetLocationList(1, DoNotSetValues.Int32, DoNotSetValues.Int32, hubLocationTypeID)

            'Get location type id for sites
            row = _locationTypeData.Select("Description = 'Site'")

            If (row.Length > 0) Then
                siteLocationTypeID = CShort(row(0).Item("Location_Type_Id"))
            End If


            'Get all sites
            _locationResultData = DalUtility.GetLocationList(1, DoNotSetValues.Int32, DoNotSetValues.Int32, siteLocationTypeID)

            row = _locationResultData.Select("Name = 'Yarrie'")

            If (row.Length > 0) Then
                Dim yarrieDataRow As DataRow
                yarrieDataRow = _hubData.NewRow

                With yarrieDataRow
                    For i As Integer = 0 To (_hubData.Columns.Count - 1)
                        .Item(i) = row(0).Item(i)
                    Next
                End With

                _hubData.Rows.Add(yarrieDataRow)
            End If

            If Not (_locationTypeData Is Nothing) Then
                _locationTypeData.Dispose()
                _locationTypeData = Nothing
            End If

            If Not (_locationResultData Is Nothing) Then
                _locationResultData.Dispose()
                _locationResultData = Nothing
            End If
        End Sub

        Protected Overrides Sub SetupPageLayout()
            Dim summaryLayout As New Tags.HtmlTableTag
            Dim mainTable As New Tags.HtmlTableTag

            Dim contactSupport As New ReconcilorControls.InputTags.InputButtonFormless

            With contactSupport
                .Text = "  Contact Support  "
                .OnClientClick = GetReportLink("BHPBIO_CONTACT_SUPPORT")
            End With

            MyBase.SetupPageLayout()

            SetupHomescreenViewLayout()
            SetupReportsLayout()
            SetupSiteMapsLayout()
            SetupSiteFilterLayout()

            With LayoutTable
                .HorizontalAlign = HorizontalAlign.Center

                .CellPadding = 2
                .CellSpacing = 2

                .AddCellInNewRow.Controls.Add(HeaderDiv)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(HomeFilter)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCell.Controls.Add(HomescreenView)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                'Add support link
                .AddCell.Controls.Add(contactSupport)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCell.Controls.Add(ShowGraphsValue)
                .CurrentCell.Controls.Add(MessageOnlyValue)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(SiteFilter)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                .AddCellInNewRow.Controls.Add(New Tags.HtmlDivTag("fFactorList"))
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(summaryLayout)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                If ((SiteID = 0) And (Not ShowGraphs)) Then
                    .AddCellInNewRow.Controls.Add(Map)
                    .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                    .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle
                End If

                .AddCellInNewRow.Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(ReportsTable)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(SiteMapsTable)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle
            End With

            mainTable.Width = WebControls.Unit.Percentage(100)
            mainTable.AddCellInNewRow.Controls.Add(LayoutTable)
            mainTable.CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Center
            mainTable.CurrentCell.VerticalAlign = WebControls.VerticalAlign.Middle

            _homeForm.Controls.Add(mainTable)
            _homeForm.Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            _homeForm.Controls.Add(New Tags.HtmlDivTag("itemList"))

            BackgroundDiv.Controls.Add(_homeForm)

            With ReconcilorContent.ContainerContent
                .Controls.Add(BackgroundDiv)
            End With
        End Sub

        Private Sub SetupHomescreenViewLayout()
            Dim homescreenViewTable As New Tags.HtmlTableTag
            Dim homescreenViewBox As New ReconcilorControls.GroupBox
            Dim monthPickerStartMonth As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim monthPickerStartYear As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim monthPickerEndMonth As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim monthPickerEndYear As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim quarterPickerStartQuarter As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim quarterPickerEndQuarter As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim quarterPickerStartYear As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim quarterPickerEndYear As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim dateBreakdown As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim locationId As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim completeReport As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim withoutHeaderFooter As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()
            Dim onlyTables As New Core.WebDevelopment.ReconcilorControls.InputTags.InputHidden()

            monthPickerStartMonth.ID = "MonthPickerMonthPartStartDate"
            monthPickerStartYear.ID = "MonthPickerYearPartStartDate"
            monthPickerEndMonth.ID = "MonthPickerMonthPartEndDate"
            monthPickerEndYear.ID = "MonthPickerYearPartEndDate"

            quarterPickerStartQuarter.ID = "DateFromQuarterSelect"
            quarterPickerEndQuarter.ID = "DateToQuarterSelect"
            quarterPickerStartYear.ID = "DateFromYearSelect"
            quarterPickerEndYear.ID = "DateToYearSelect"

            locationId.ID = "LocationId"
            dateBreakdown.ID = "DateBreakdown"

            completeReport.ID = "CompleteReport"
            completeReport.Value = "True"
            withoutHeaderFooter.ID = "WithoutHeaderFooter"
            withoutHeaderFooter.Value = "False"
            onlyTables.ID = "OnlyTables"
            onlyTables.Value = "False"

            With homescreenViewTable
                .Height = WebControls.Unit.Percentage(100)
                .Width = WebControls.Unit.Percentage(100)
                .CellPadding = 6
                .CellSpacing = 2

                .AddCellInNewRow.Controls.Add(PrintButton)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .CurrentCell.Controls.Add(dateBreakdown)
                .CurrentCell.Controls.Add(monthPickerStartMonth)
                .CurrentCell.Controls.Add(monthPickerStartYear)
                .CurrentCell.Controls.Add(monthPickerEndMonth)
                .CurrentCell.Controls.Add(monthPickerEndYear)
                .CurrentCell.Controls.Add(quarterPickerStartQuarter)
                .CurrentCell.Controls.Add(quarterPickerEndQuarter)
                .CurrentCell.Controls.Add(quarterPickerStartYear)
                .CurrentCell.Controls.Add(quarterPickerEndYear)
                .CurrentCell.Controls.Add(completeReport)
                .CurrentCell.Controls.Add(withoutHeaderFooter)
                .CurrentCell.Controls.Add(onlyTables)
                .CurrentCell.Controls.Add(dateBreakdown)

                If SiteID > 0 Then
                    locationId.Value = SiteID.ToString()
                    .CurrentCell.Controls.Add(locationId)
                End If

                .AddCell.Controls.Add(ProcessMapButton)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            homescreenViewBox.Title = " Homescreen View "
            homescreenViewBox.Controls.Add(homescreenViewTable)

            With HomescreenView
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(homescreenViewBox)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            If (Not homescreenViewTable Is Nothing) Then
                homescreenViewTable.Dispose()
                homescreenViewTable = Nothing
            End If

            If (Not homescreenViewBox Is Nothing) Then
                homescreenViewBox.Dispose()
                homescreenViewBox = Nothing
            End If
        End Sub

        Private Sub SetupSiteFilterLayout()
            Dim siteFilterTable As New Tags.HtmlTableTag
            Dim siteFilterBox As New ReconcilorControls.GroupBox

            With siteFilterTable
                ' .Height = WebControls.Unit.Percentage(100)
                '.Width = WebControls.Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                .AddCellInNewRow.Controls.Add(SiteFilterSelect)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(SiteFilterButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            siteFilterBox.Title = " Site DrillDown "
            siteFilterBox.Controls.Add(siteFilterTable)

            With SiteFilter
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(siteFilterBox)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            If (Not siteFilterTable Is Nothing) Then
                siteFilterTable.Dispose()
                siteFilterTable = Nothing
            End If

            If (Not siteFilterBox Is Nothing) Then
                siteFilterBox.Dispose()
                siteFilterBox = Nothing
            End If
        End Sub
        Private Sub SetupSiteMapsLayout()
            Dim siteMapsLayout As New Tags.HtmlTableTag
            Dim siteMapsBox As New ReconcilorControls.GroupBox

            ' Invoke Procedure to Check Sites and Update Setting table
            Dim table As DataTable = _dalUtility.CheckUpdateSiteMapList()
            Dim i As Integer = 0
            Dim buttonsPerRow As Integer = 7

            With siteMapsLayout
                .Width = WebControls.Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                For Each row As DataRow In table.Rows
                    Dim smp As New InputButtonFormless(ReconcilorControls.InputTags.InputButtonFormless.ButtonSize.Small)
                    Dim siteName As String = row("setting_id").ToString().Replace("BHPBIO_SITELIST_", "").Replace("_", " ")

                    With smp
                        .Text = String.Format(" {0} ", siteName)
                        .Style.Add("width", "100%")
                        .OnClientClick = GetSiteMapLink(row("value").ToString())
                    End With

                    If (i Mod buttonsPerRow = 0) Then
                        .AddCellInNewRow.Controls.Add(smp)
                    Else
                        .AddCell.Controls.Add(smp)
                    End If

                    .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                    .CurrentCell.VerticalAlign = VerticalAlign.Top

                    i += 1
                Next

            End With

            siteMapsBox.Title = " Site/Hub Maps "
            siteMapsBox.Controls.Add(siteMapsLayout)

            With SiteMapsTable
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(siteMapsBox)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            If (Not siteMapsLayout Is Nothing) Then
                siteMapsLayout.Dispose()
                siteMapsLayout = Nothing
            End If

            If (Not siteMapsBox Is Nothing) Then
                siteMapsBox.Dispose()
                siteMapsBox = Nothing
            End If
        End Sub
        Private Sub SetupReportsLayout()
            Dim reportsLayout As New Tags.HtmlTableTag
            Dim reportsBox As New ReconcilorControls.GroupBox

            With reportsLayout
                .Width = WebControls.Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                .AddCellInNewRow.Controls.Add(ReconSummaryCurrentButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(TechnicalSummaryCurrentButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(ActionRegisterCurrentButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle


                .AddCellInNewRow.Controls.Add(ReconSummaryHistoricalButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(TechnicalSummaryHistoricalButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(ActionRegisterHistoricalButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            reportsBox.Title = " Reports "
            reportsBox.Controls.Add(reportsLayout)

            With ReportsTable
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(reportsBox)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

            If (Not reportsLayout Is Nothing) Then
                reportsLayout.Dispose()
                reportsLayout = Nothing
            End If

            If (Not reportsBox Is Nothing) Then
                reportsBox.Dispose()
                reportsBox = Nothing
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            If (DalReport Is Nothing) Then
                DalReport = New Database.SqlDal.SqlDalReport(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)

            _homeFilter = CType(Resources.DependencyFactories.FilterBoxFactory.Create("Home", Resources),  _
             WebDevelopment.ReconcilorControls.FilterBoxes.Home.HomeFilter)
            _homeFilter.SetServerForm(_homeForm)
        End Sub

        Protected Overrides Sub SetupFinalJavascriptCalls()
            If (MessageOnly) Then
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetMessageOnly();"))
            Else
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetFFactorData('" + SiteID.ToString() + "');"))
            End If

            MyBase.SetupFinalJavaScriptCalls()
        End Sub
    End Class
End Namespace
