Imports System.Text.RegularExpressions
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.Report
Imports System.Web.UI.WebControls
Imports ChartFX.WebForms
Imports ChartFX.WebForms.Annotation
Imports ChartFX.WebForms.DataProviders
Imports ChartFX.WebForms.Adornments

Namespace Home
    Public Class HomeList
        Inherits Reconcilor.Core.WebDevelopment.WebpageTemplates.ReconcilorAjaxPage


#Region " Properties "
        Private Const _startDateSetting As String = "SYSTEM_START_DATE"

        Private _disposed As Boolean
        Private _dalReport As Bhpbio.Database.SqlDal.SqlDalReport
        Private _dalUtility As IUtility
        Private _reportSession As New Types.ReportSession
        Private _period As String
        Private _dateFrom As DateTime = DoNotSetValues.DateTime
        Private _dateTo As DateTime = DoNotSetValues.DateTime
        Private _locationId As Integer = 0
        Private _digblockIdFilter As String
        Private _fData As DataTable
        Private _fChartData As DataTable
        Private _fFactorGrid As New System.Web.UI.WebControls.DataGrid
        Private _tonnesChart As New Chart
        Private _feChart As New Chart
        Private _pChart As New Chart
        Private _sio2Chart As New Chart
        Private _al203Chart As New Chart
        Private _loiChart As New Chart
        Private _chartTable As New Tags.HtmlTableTag
        Private _homescreenLinkImage As New Tags.HtmlAnchorTag
        Private _homescreenlink As New Tags.HtmlTableTag
        Private _fieldAttributes As New DataTable
        Private _showGraphs As Boolean
        Private _messageOnly As Boolean
        Private _isSite As Boolean = False
        Private _isPrintView As Boolean = False
        Private _printMap As New Image
        Private _grades As New Dictionary(Of String, Snowden.Reconcilor.Core.Grade)
        Private _siteId As Integer

        Public Property DalReport() As Bhpbio.Database.SqlDal.SqlDalReport
            Get
                Return _dalReport
            End Get
            Set(ByVal value As Bhpbio.Database.SqlDal.SqlDalReport)
                _dalReport = value
            End Set
        End Property

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property


        Public Property ReportSession() As Types.ReportSession
            Get
                Return _reportSession
            End Get
            Set(ByVal value As Types.ReportSession)
                _reportSession = value
            End Set
        End Property

        Public Property DateFrom() As DateTime
            Get
                Return _dateFrom
            End Get
            Set(ByVal value As DateTime)
                _dateFrom = value
            End Set
        End Property

        Public Property DateTo() As DateTime
            Get
                Return _dateTo
            End Get
            Set(ByVal value As DateTime)
                _dateTo = value
            End Set
        End Property

        Public Property Period() As String
            Get
                Return _period
            End Get
            Set(ByVal value As String)
                _period = value
            End Set
        End Property

        Public Property LocationId() As Integer
            Get
                Return _locationId
            End Get
            Set(ByVal value As Integer)
                _locationId = value
            End Set
        End Property

        Public Property FFactorGrid() As System.Web.UI.WebControls.DataGrid
            Get
                Return _fFactorGrid
            End Get
            Set(ByVal value As System.Web.UI.WebControls.DataGrid)
                _fFactorGrid = value
            End Set
        End Property

        Public Property TonnesChart() As Chart
            Get
                Return _tonnesChart
            End Get
            Set(ByVal value As Chart)
                _tonnesChart = value
            End Set
        End Property

        Public Property FeChart() As Chart
            Get
                Return _feChart
            End Get
            Set(ByVal value As Chart)
                _feChart = value
            End Set
        End Property


        Public Property PChart() As Chart
            Get
                Return _pChart
            End Get
            Set(ByVal value As Chart)
                _pChart = value
            End Set
        End Property

        Public Property SiO2Chart() As Chart
            Get
                Return _sio2Chart
            End Get
            Set(ByVal value As Chart)
                _sio2Chart = value
            End Set
        End Property

        Public Property Al2O3Chart() As Chart
            Get
                Return _al203Chart
            End Get
            Set(ByVal value As Chart)
                _al203Chart = value
            End Set
        End Property

        Public Property LOIChart() As Chart
            Get
                Return _loiChart
            End Get
            Set(ByVal value As Chart)
                _loiChart = value
            End Set
        End Property

        Public Property ChartTable() As Tags.HtmlTableTag
            Get
                Return _chartTable
            End Get
            Set(ByVal value As Tags.HtmlTableTag)
                If (Not value Is Nothing) Then
                    _chartTable = value
                End If
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


        Protected Property FieldAttributes() As DataTable
            Get
                Return _fieldAttributes
            End Get
            Set(ByVal value As DataTable)
                _fieldAttributes = value
            End Set
        End Property

        Protected Property ShowGraphs() As Boolean
            Get
                Return _showGraphs
            End Get
            Set(ByVal value As Boolean)
                _showGraphs = value
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

        Protected Property IsPrintView() As Boolean
            Get
                Return _isPrintView
            End Get
            Set(ByVal value As Boolean)
                _isPrintView = value
            End Set
        End Property

        Protected Property PrintMap() As Image
            Get
                Return _printMap
            End Get
            Set(ByVal value As Image)
                _printMap = value
            End Set
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalReport Is Nothing) Then
                            _dalReport.Dispose()
                            _dalReport = Nothing
                        End If

                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        If (Not _reportSession Is Nothing) Then
                            _reportSession.Dispose()
                            _reportSession = Nothing
                        End If

                        If (Not _fFactorGrid Is Nothing) Then
                            _fFactorGrid.Dispose()
                            _fFactorGrid = Nothing
                        End If

                        If (Not _tonnesChart Is Nothing) Then
                            _tonnesChart.Dispose()
                            _tonnesChart = Nothing
                        End If

                        If (Not _feChart Is Nothing) Then
                            _feChart.Dispose()
                            _feChart = Nothing
                        End If

                        If (Not _fChartData Is Nothing) Then
                            _fChartData.Dispose()
                            _fChartData = Nothing
                        End If

                        If (Not _pChart Is Nothing) Then
                            _pChart.Dispose()
                            _pChart = Nothing
                        End If

                        If (Not _sio2Chart Is Nothing) Then
                            _sio2Chart.Dispose()
                            _sio2Chart = Nothing
                        End If

                        If (Not _al203Chart Is Nothing) Then
                            _al203Chart.Dispose()
                            _al203Chart = Nothing
                        End If

                        If (Not _loiChart Is Nothing) Then
                            _loiChart.Dispose()
                            _loiChart = Nothing
                        End If

                        If (Not _chartTable Is Nothing) Then
                            _chartTable.Dispose()
                            _chartTable = Nothing
                        End If

                        If (Not _fieldAttributes Is Nothing) Then
                            _fieldAttributes.Dispose()
                            _fieldAttributes = Nothing
                        End If

                        If (Not _printMap Is Nothing) Then
                            _printMap.Dispose()
                            _printMap = Nothing
                        End If

                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _period = RequestAsString("HomePeriodFilter")
            _isPrintView = RequestAsBoolean("Print")
            If Not (Request("SiteId") Is Nothing) Then
                _siteId = RequestAsInt32("SiteId")
                MessageOnly = False
            Else
                MessageOnly = True
            End If
            ShowGraphs = RequestAsBoolean("HomeShowGraphsValue")
            LocationId = RequestAsInt32("HomeLocationID")

            If (Not MessageOnly) Then
                Dim daysInMonth As Integer
                Dim monthFromPart, monthToPart As Int32
                Dim quarterFromPart, quarterToPart As String
                Dim yearFrom, yearTo As Int32
                Dim reportBreakdown As New Snowden.Reconcilor.Bhpbio.Report.Types.ReportBreakdown
                Dim yearlyGraphs As Boolean
                Dim chartStartDate As DateTime

                ReportSession.SetupDal(Resources.ConnectionString)
                ReportSession.IncludeProductSizeBreakdown = False

                Int32.TryParse(RequestAsString("HomePeriodFromYear"), yearFrom)
                Int32.TryParse(RequestAsString("HomePeriodToYear"), yearTo)

                yearlyGraphs = False

                Select Case (Period)
                    Case "QUARTER"
                        quarterFromPart = RequestAsString("HomePeriodFromMonthQuarter")
                        quarterToPart = RequestAsString("HomePeriodToMonthQuarter")

                        monthFromPart = GetFirstMonthInQuarter(quarterFromPart)
                        monthToPart = GetLastMonthInQuarter(quarterToPart)

                        If Convert.ToInt32(monthFromPart) > 6 Then
                            yearFrom = yearFrom - 1
                        End If
                        If Convert.ToInt32(monthToPart) > 6 Then
                            yearTo = yearTo - 1
                        End If

                    Case "MONTH"
                        If Not Int32.TryParse(RequestAsString("HomePeriodFromMonthQuarter"), monthFromPart) Then
                            Throw New InvalidOperationException(String.Format("Failed to Convert: ""{0}"" to {1}", _
                             RequestAsString("HomePeriodFromMonth"), monthFromPart.ToString()))
                            monthFromPart = 1
                        End If
                        If Not Int32.TryParse(RequestAsString("HomePeriodToMonthQuarter"), monthToPart) Then
                            monthToPart = 1
                            Throw New InvalidOperationException(String.Format("Failed to Convert: ""{0}"" to {1}", _
                             RequestAsString("HomePeriodToMonth"), monthFromPart.ToString()))
                        End If

                    Case "YEAR"
                        monthFromPart = 1
                        monthToPart = 12

                    Case Else
                        monthFromPart = 1
                        monthToPart = 1
                End Select

                daysInMonth = Date.DaysInMonth(yearTo, monthToPart)

                'calculate the DateFrom/DateTo
                DateFrom = New DateTime(yearFrom, monthFromPart, 1)
                DateTo = New DateTime(yearTo, monthToPart, daysInMonth)

                'determine the Breakdown & the chart's start dates
                If (Period = "MONTH") Then
                    reportBreakdown = Report.Types.ReportBreakdown.Monthly
                    yearlyGraphs = False
                    chartStartDate = DateAdd(DateInterval.Month, -12, DateAdd(DateInterval.Day, 1, DateTo))
                ElseIf (Period = "QUARTER") Then
                    reportBreakdown = Report.Types.ReportBreakdown.CalendarQuarter
                    yearlyGraphs = False
                    chartStartDate = DateAdd(DateInterval.Quarter, -12, DateAdd(DateInterval.Day, 1, DateTo))
                ElseIf Period = "YEAR" And DateFrom >= Me.GetStartDate().Value Then
                    'when dealing with regular data only, use the YEARLY breakdown as the model
                    'will natively support this
                    reportBreakdown = Report.Types.ReportBreakdown.Yearly
                    yearlyGraphs = True
                    chartStartDate = DateAdd(DateInterval.Year, -12, DateAdd(DateInterval.Day, 1, DateTo))
                ElseIf Period = "YEAR" And DateFrom < Me.GetStartDate().Value Then
                    'anytime we hit historic data we need to switch back to quaterly data
                    'this works for this screen as it is able to aggregate the result anyway
                    reportBreakdown = Report.Types.ReportBreakdown.CalendarQuarter
                    yearlyGraphs = True
                    chartStartDate = DateAdd(DateInterval.Year, -12, DateAdd(DateInterval.Day, 1, DateTo))
                Else
                    'we should never see this error... just in case it's here which indicates a bug
                    'in the above if/elseif blocks or a new "PERIOD" has become available
                    Throw New InvalidOperationException("A problem has been found with the date range & period selected.")
                End If

                FieldAttributes = Data.GradeProperties.GetBhpbioFReportAttributeProperties(ReportSession, LocationId)

                ' ensure chart start date is first of month
                chartStartDate = New DateTime(chartStartDate.Year, chartStartDate.Month, 1)

                _fData = Report.ReportDefinitions.HomeScreenValues.GetHomeScreenFactors(ReportSession, LocationId, _
                 DateFrom, DateTo, reportBreakdown, ReportSession.GetSystemStartDate(), True, False)

                If ((LocationId <> 0) Or (ShowGraphs)) Then

                    ' force the chart start lookback
                    _fChartData = Report.ReportDefinitions.HomeScreenValues.GetHomeScreenValues(ReportSession, _
                     LocationId, chartStartDate, DateTo, reportBreakdown, ReportSession.GetSystemStartDate())
                End If
            End If
        End Sub

        Private Function GetFirstMonthInQuarter(ByVal quarter As String) As Int32
            Dim firstMonth As Int32 = 1

            Select Case (quarter)
                Case "Q1"
                    firstMonth = 7
                Case "Q2"
                    firstMonth = 10
                Case "Q3"
                    firstMonth = 1
                Case "Q4"
                    firstMonth = 4
            End Select

            Return firstMonth
        End Function

        Private Function GetLastMonthInQuarter(ByVal quarter As String) As Int32
            Dim firstMonth As Int32 = 1

            Select Case (quarter)
                Case "Q1"
                    firstMonth = 9
                Case "Q2"
                    firstMonth = 12
                Case "Q3"
                    firstMonth = 3
                Case "Q4"
                    firstMonth = 6
            End Select

            Return firstMonth
        End Function

        Private Function GetSystemMessagesBox() As System.Web.UI.Control
            Dim messageList As ReconcilorControls.ReconcilorTable
            'Write each one as a bulleted list.
            messageList = New ReconcilorControls.ReconcilorTable(GetSystemMessages, New String() { _
                                                                 "Message"})

            messageList.DataBind()
            messageList.Columns("Message").Width = 315
            messageList.Height = 75
            messageList.Width = 330
            messageList.IsExpandable = True

            messageList.IsExpandable = True
            Return messageList

        End Function

        Private Function ParseLinksInMessageText(ByVal messageText As String) As String
            Return Regex.Replace(messageText, "(\bhttp://[^ ]+\b)", "<a href=""$0"" target=""_blank"">$0</a>")
        End Function


        Private Function GetSystemMessages() As DataTable
            Dim uiAssistant As Bhpbio.Notification.UiAssistant
            Dim messageList As New DataTable
            Dim nextRow As DataRow
            messageList.Columns.Add("Message", GetType(String), Nothing)

            uiAssistant = New Bhpbio.Notification.UiAssistant(DirectCast(Application("CoreDependencyFactories"),  _
                                                    Reconcilor.Core.Extensibility.DependencyFactories), _
                                                        Resources.Connection)
            For Each r As DataRow In DalUtility.GetBhpbioCustomMessages().AsEnumerable(). _
                Where(Function(f) DirectCast(f.Item("ExpirationDate"), DateTime) > Now AndAlso DirectCast(f.Item("IsActive"), Boolean))
                nextRow = messageList.NewRow()
                nextRow("Message") = "- " & ParseLinksInMessageText(DirectCast(r.Item("Text"), String))
                messageList.Rows.Add(nextRow)
            Next



            For Each r As String In uiAssistant.GetNotificationSimpleUiMessages(Resources.UserSecurity.UserId.Value)
                nextRow = messageList.NewRow()
                nextRow("Message") = "- " & ParseLinksInMessageText(r)
                messageList.Rows.Add(nextRow)
            Next


            Return messageList
        End Function
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim tableLayout As New Tags.HtmlTableTag
            Dim valStr As String
            'load the grade data
            Dim grades As DataTable
            Dim grade As DataRow

            _grades = New Dictionary(Of String, Snowden.Reconcilor.Core.Grade)

            grades = DalUtility.GetGradeList(Snowden.Common.Database.DataAccessBaseObjects.NullValues.Int16)
            For Each grade In grades.Rows
                _grades.Add(DirectCast(grade("Grade_Name"), String), _
                 New Core.Grade(grade, DirectCast(Application("NumericFormat"), String)))
            Next

            Try


                valStr = ValidateData()

                If valStr = "" Then
                    _isSite = CheckIsSite()


                    tableLayout.CellPadding = 3
                    tableLayout.CellSpacing = 1

                    SetupFFactorTable()
                    tableLayout.AddCellInNewRow()

                    If (Not MessageOnly) Then

                        tableLayout.CurrentCell.Controls.Add(FFactorGrid)
                        tableLayout.CurrentCell.VerticalAlign = VerticalAlign.Top
                    End If


                    If Not (IsPrintView) Then
                        SetupHomescreenLink()

                        tableLayout.AddCell.Controls.Add(HomescreenLink)
                        tableLayout.CurrentCell.VerticalAlign = VerticalAlign.Top
                    End If

                    'Add message box 
                    tableLayout.AddCell.Controls.Add(GetSystemMessagesBox)
                    tableLayout.CurrentCell.VerticalAlign = VerticalAlign.Top

                    Controls.Add(tableLayout)

                    If (Not MessageOnly) Then

                        If ((LocationId <> 0) Or (ShowGraphs)) Then
                            SetUpChartTable()
                            Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                            Controls.Add(ChartTable)
                        ElseIf (IsPrintView) Then
                            With PrintMap
                                .ImageUrl = "../images/homescreenMap.gif"
                                .BorderStyle = BorderStyle.Solid
                                .BorderWidth = 2
                                .BorderColor = Drawing.Color.Black
                            End With

                            Controls.Add(PrintMap)
                        End If

                        Resources.UserSecurity.SetSetting("Home_Filter_Period", Period)
                        Resources.UserSecurity.SetSetting("Home_Filter_Date_From", DateFrom.ToString("O"))
                        Resources.UserSecurity.SetSetting("Home_Filter_Date_To", DateTo.ToString("O"))
                    End If
                Else
                    JavaScriptAlert(valStr, "Please fix the following errors:\n")
                End If

            Catch ea As Threading.ThreadAbortException
                Return
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error loading F Factor data\n")
            Finally
                If (Not tableLayout Is Nothing) Then
                    tableLayout.Dispose()
                    tableLayout = Nothing
                End If
            End Try


        End Sub


        Private Sub SetupHomescreenLink()
            Dim homescreenLinkBox As New ReconcilorControls.GroupBox

            'Homescreen button (if site/hub homepage)
            If ((LocationId = 0) And (Not ShowGraphs)) Then
                With _homescreenLinkImage
                    .Href = "./Default.aspx?ShowGraphs=true"
                    .InnerHtml = "<img src=""../images/viewF1F2F3graphs.gif"" style=""border: 1px solid black""/>"
                End With
                homescreenLinkBox.Title = " Graphs "
            Else
                With _homescreenLinkImage
                    .Href = "./Default.aspx"
                    .InnerHtml = "<img src=""../images/WAIOHomescreen.gif"" style=""border: 1px solid black""/>"
                End With
                homescreenLinkBox.Title = " WAIO "
            End If

            homescreenLinkBox.Controls.Add(_homescreenLinkImage)

            With HomescreenLink
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                .AddCellInNewRow.Controls.Add(homescreenLinkBox)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With


            If (Not homescreenLinkBox Is Nothing) Then
                homescreenLinkBox.Dispose()
                homescreenLinkBox = Nothing
            End If
        End Sub

        Private Sub SetupFFactorTable()



            AddHandler FFactorGrid.ItemDataBound, AddressOf SummaryGrid_ItemDataBound

            FFactorGrid.AutoGenerateColumns = False
            FFactorGrid.CellPadding = 3
            FFactorGrid.CellSpacing = 0
            FFactorGrid.GridLines = GridLines.None

            FFactorGrid.HeaderStyle.Font.Bold = True
            FFactorGrid.HeaderStyle.BorderStyle = BorderStyle.Solid
            FFactorGrid.HeaderStyle.BorderWidth = 1
            FFactorGrid.HeaderStyle.BorderColor = Drawing.Color.Black
            FFactorGrid.HeaderStyle.BackColor = Drawing.Color.White
            FFactorGrid.ItemStyle.BackColor = System.Drawing.Color.FromArgb(255, 245, 247, 248)
            FFactorGrid.BorderStyle = BorderStyle.Solid
            FFactorGrid.BorderWidth = 1
            FFactorGrid.BorderColor = Drawing.Color.Black

            Dim boundCol As New BoundColumn()
            Dim templateCol As New TemplateColumn()

            'Page Title
            Dim siteName As String = "WAIO"

            If (_siteId <> 0) Then
                Dim _locationData As DataTable = DalUtility.GetLocationList(1, DoNotSetValues.Int32, _siteId, DoNotSetValues.Int16)

                If (_locationData.Rows.Count > 0) Then
                    siteName = _locationData.Rows(0).Item("Description").ToString
                End If
            End If

            boundCol.HeaderText = siteName + " F1F2F3 RECONCILIATION"
            boundCol.DataField = "Description"
            boundCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Left
            boundCol.ItemStyle.Font.Bold = True
            boundCol.ItemStyle.HorizontalAlign = HorizontalAlign.Left
            FFactorGrid.Columns.Add(boundCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "Tonnes"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "Fe %"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "P %"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "SiO2 %"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "Al2O3 %"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            templateCol = New TemplateColumn()
            templateCol.HeaderText = "LOI %"
            templateCol.ItemStyle.Width = 50
            templateCol.HeaderStyle.HorizontalAlign = HorizontalAlign.Center
            FFactorGrid.Columns.Add(templateCol)

            FFactorGrid.DataSource = _fData
            FFactorGrid.DataBind()
        End Sub

        Private Sub SummaryGrid_ItemDataBound(ByVal sender As Object, ByVal e As DataGridItemEventArgs)

            If ((e.Item.ItemType = ListItemType.Item) Or (e.Item.ItemType = ListItemType.AlternatingItem)) Then
                Dim fDataRow As DataRow

                fDataRow = _fData.Rows(e.Item.ItemIndex)

                e.Item.Cells(0).Style.Add("border-right", "solid 1px black")

                e.Item.Cells(1).Controls.Add(GetImage("Tonnes", fDataRow))
                e.Item.Cells(2).Controls.Add(GetImage("Fe", fDataRow))
                e.Item.Cells(3).Controls.Add(GetImage("P", fDataRow))
                e.Item.Cells(4).Controls.Add(GetImage("SiO2", fDataRow))
                e.Item.Cells(5).Controls.Add(GetImage("Al2O3", fDataRow))
                e.Item.Cells(6).Controls.Add(GetImage("LOI", fDataRow))

                If ((_isSite) And (fDataRow.Item("TagId").ToString = "F3Factor")) Then
                    Dim overlay As New Tags.HtmlTableTag
                    overlay.AddCellInNewRow()
                    overlay.CurrentCell.BackColor = Drawing.Color.LightGray

                    e.Item.Cells(0).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(1).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(2).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(3).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(4).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(5).BackColor = Drawing.Color.LightGray
                    e.Item.Cells(6).BackColor = Drawing.Color.LightGray
                End If

                e.Item.Cells(0).Style.Add("color", fDataRow.Item("PresentationColor").ToString)
            ElseIf (e.Item.ItemType = ListItemType.Header) Then
                e.Item.Cells(0).Style.Add("border-right", "solid 1px black")
                e.Item.Cells(0).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(1).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(2).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(3).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(4).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(5).Style.Add("border-bottom", "solid 1px black")
                e.Item.Cells(6).Style.Add("border-bottom", "solid 1px black")
            End If
        End Sub

        Private Function GetImage(ByVal fieldName As String, ByVal data As DataRow) As Image
            Dim face As New Image
            Dim compareValue As Double
            Dim highThreshold, lowThreshold As Double
            Dim isAbsoluteThreshold As Boolean
            Dim threasholdTypeID As String
            Dim value As Double
            Dim factor As Double
            Dim toolTip As String
            Dim absoluteText As String

            threasholdTypeID = data.Item("TagId").ToString

            isAbsoluteThreshold = CheckAbsoluteThreshold(threasholdTypeID, fieldName)
            lowThreshold = GetLowerThreshold(threasholdTypeID, fieldName)
            highThreshold = GetHighThreshold(threasholdTypeID, fieldName)

            If Not IsDBNull(data.Item(fieldName)) Then
                factor = Convert.ToDouble(data.Item(fieldName))
            Else
                factor = 0
            End If

            If (isAbsoluteThreshold) Then
                If Not Double.TryParse(data.Item(fieldName & "Difference").ToString(), value) Then
                    value = 0
                End If
                compareValue = Math.Abs(value)
                absoluteText = "Absolute"
            Else
                value = factor

                'Calculate variation
                compareValue = Math.Abs(value - 1.0)
                absoluteText = "Relative"
            End If


            If factor = 0 Then
                face.ImageUrl = "../images/faceDisabled.gif"
            ElseIf (compareValue < lowThreshold) Then
                If ((_isSite) And (threasholdTypeID = "F3Factor")) Then
                    face.ImageUrl = "../images/faceGreenDisabled2.gif"
                Else
                    face.ImageUrl = "../images/faceGreen.gif"
                End If

            ElseIf (compareValue > lowThreshold And compareValue <= highThreshold) Then
                If ((_isSite) And (threasholdTypeID = "F3Factor")) Then
                    face.ImageUrl = "../images/faceOrangeDisabled.gif"
                Else
                    face.ImageUrl = "../images/faceOrange.gif"
                End If
            Else
                If ((_isSite) And (threasholdTypeID = "F3Factor")) Then
                    face.ImageUrl = "../images/faceRedDisabled.gif"
                Else
                    face.ImageUrl = "../images/faceRed.gif"
                End If
            End If

            If value = 0 And factor = 0 Then
                face.ToolTip = "No Data"
            Else
                toolTip = String.Format("Factor Value: {0}={1}{2}", fieldName, FormatNumber(factor, 2), Environment.NewLine)
                toolTip = toolTip & String.Format("{0} Difference: {1}=", absoluteText, fieldName)
                If isAbsoluteThreshold Then
                    If fieldName = "Tonnes" Then
                        toolTip = toolTip & String.Format("{0}", FormatNumber(Math.Abs(compareValue), 0))
                    Else
                        toolTip = toolTip & String.Format("{0}", _grades(fieldName).ToString(CSng(Math.Abs(compareValue)), False))
                    End If

                Else
                    toolTip = toolTip & String.Format("{0}", FormatNumber(compareValue, 2))
                End If

                toolTip = toolTip & String.Format("{0}", Environment.NewLine)
                toolTip = toolTip & String.Format("Green < {0} < Yellow < {1} < Red", lowThreshold, highThreshold)

                face.ToolTip = toolTip
            End If

            face.BorderStyle = BorderStyle.None
            Return face
        End Function

        Private Function CheckAbsoluteThreshold(ByVal thresholdTypeID As String, ByVal fieldName As String) As Boolean
            Dim isAbsolute As Boolean
            Dim rowResults() As DataRow

            rowResults = FieldAttributes.Select("ThresholdTypeID = '" & thresholdTypeID & "' AND FieldName = '" & fieldName & "'")

            If (rowResults.Length > 0) Then
                isAbsolute = Convert.ToBoolean(rowResults(0).Item("AbsoluteThreshold"))
            End If

            Return isAbsolute
        End Function

        Private Function GetLowerThreshold(ByVal thresholdTypeID As String, ByVal fieldName As String) As Double
            Dim lowThreshold As Double
            Dim rowResults() As DataRow
            Dim isAbsolute As Boolean

            rowResults = FieldAttributes.Select("ThresholdTypeID = '" & thresholdTypeID & "' AND FieldName = '" & fieldName & "'")

            If (rowResults.Length > 0) Then
                isAbsolute = Convert.ToBoolean(rowResults(0).Item("AbsoluteThreshold"))
                lowThreshold = Convert.ToDouble(rowResults(0).Item("LowThreshold"))

                If (Not isAbsolute) Then
                    If (lowThreshold <> 0) Then
                        lowThreshold = lowThreshold / 100
                    End If
                End If
            End If

            Return lowThreshold
        End Function

        Private Function GetHighThreshold(ByVal thresholdTypeID As String, ByVal fieldName As String) As Double
            Dim highThreshold As Double
            Dim rowResults() As DataRow
            Dim isAbsolute As Boolean

            rowResults = FieldAttributes.Select("ThresholdTypeID = '" & thresholdTypeID & "' AND FieldName = '" & fieldName & "'")

            If (rowResults.Length > 0) Then
                isAbsolute = Convert.ToBoolean(rowResults(0).Item("AbsoluteThreshold"))
                highThreshold = Convert.ToDouble(rowResults(0).Item("HighThreshold"))

                If (Not isAbsolute) Then
                    If (highThreshold <> 0) Then
                        highThreshold = highThreshold / 100
                    End If
                End If
            End If

            Return highThreshold
        End Function

        Private Function GetDecimalPlaces(ByVal thresholdTypeID As String, ByVal fieldName As String) As Integer
            Dim highThreshold As Integer
            Dim rowResults() As DataRow

            rowResults = FieldAttributes.Select("ThresholdTypeID = '" & thresholdTypeID & "' AND FieldName = '" & fieldName & "'")

            If (rowResults.Length > 0) Then
                highThreshold = Convert.ToInt32(rowResults(0).Item("DisplayPrecision"))
            End If

            Return highThreshold
        End Function


        Private Sub SetUpChartTable()

            Dim graphThresholds As DataTable
            Dim thresholdRow As DataRow


            graphThresholds = DalUtility.GetBhpbioReportThresholdList(DirectCast(IIf(LocationId > 0, LocationId, 1), Integer), "GraphThreshold", False, False)


            'Create charts
            thresholdRow = graphThresholds.Select("FieldName = 'Tonnes'")(0)
            TonnesChart = CreateChart("Tonnes", 0.7, 1.3, 0.1, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))
            thresholdRow = graphThresholds.Select("FieldName = 'Fe'")(0)
            FeChart = CreateChart("Fe", 0.97, 1.03, 0.01, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))
            thresholdRow = graphThresholds.Select("FieldName = 'P'")(0)
            PChart = CreateChart("P", 0.7, 1.3, 0.1, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))
            thresholdRow = graphThresholds.Select("FieldName = 'SiO2'")(0)
            SiO2Chart = CreateChart("SiO2", 0.7, 1.3, 0.1, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))
            thresholdRow = graphThresholds.Select("FieldName = 'Al2O3'")(0)
            Al2O3Chart = CreateChart("Al2O3", 0.7, 1.3, 0.1, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))
            thresholdRow = graphThresholds.Select("FieldName = 'LOI'")(0)
            LOIChart = CreateChart("LOI", 0.7, 1.3, 0.1, DirectCast(thresholdRow("LowThreshold"), Double), DirectCast(thresholdRow("HighThreshold"), Double))


            'Set up chart layout
            With ChartTable
                .CellPadding = 2
                .CellSpacing = 2

                .AddCellInNewRow.Controls.Add(TonnesChart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(FeChart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(PChart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCellInNewRow.Controls.Add(SiO2Chart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(Al2O3Chart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle

                .AddCell.Controls.Add(LOIChart)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.VerticalAlign = VerticalAlign.Middle
            End With

        End Sub

        Private Function CreateChart(ByVal fieldName As String, ByVal minValue As Double, ByVal maxValue As Double, ByVal axisScale As Double, ByVal lowThreshold As Double, ByVal highThreshold As Double) As Chart
            Dim homeChart As New Chart
            Dim reportColorList As New DataTable
            Dim color, lineStyle, markerShape As String
            Dim xAxis As String = "DateText"

            With homeChart
                .LegendBox.Visible = False
                .Gallery = Gallery.Lines
                .ToolBar.Visible = False
                .MenuBar.Visible = False
                .ImageSettings.Interactive = False

                .Background = New SolidBackground(Drawing.Color.White)
                .PlotAreaMargin.Left = 2
                .PlotAreaMargin.Bottom = 2

                .Titles.Add(New TitleDockable("<b>" & fieldName & "</b>"))
                .Titles(0).RichText = True


                'lowThreshold = 1 - GetHighThreshold("F1Factor", fieldName)
                'highThreshold = 1 + GetHighThreshold("F1Factor", fieldName)

                With .AxisY
                    .Title.Text = "Factor"
                    .Grids.Major.Visible = True
                    .LabelsFormat.Decimals = 2
                    .LabelsFormat.Format = AxisFormat.Number
                    .AutoScale = False
                End With

                With .AxisX
                    If (Period = "QUARTER") Then
                        .Title.Text = "Quarter"
                    ElseIf (Period = "YEAR") Then
                        .Title.Text = "Year"
                    Else
                        .Title.Text = "Month"
                    End If

                    .Grids.Major.Visible = False
                    .LabelAngle = 90
                    .Step = 1
                End With

                .RenderFormat = "PNG"

                Dim maxNoPoints, noPoints As Integer

                maxNoPoints = 0
                noPoints = _fChartData.Select("TagId = 'F1Factor'").Length

                If (noPoints > maxNoPoints) Then
                    maxNoPoints = noPoints
                End If

                noPoints = _fChartData.Select("TagId = 'F2Factor'").Length

                If (noPoints > maxNoPoints) Then
                    maxNoPoints = noPoints
                End If

                noPoints = _fChartData.Select("TagId = 'F3Factor'").Length

                If (noPoints > maxNoPoints) Then
                    maxNoPoints = noPoints
                End If

                .Data.Series = 3
                .Data.Points = maxNoPoints

                Dim index As Integer = 0
                For Each row As DataRow In _fChartData.Select("TagId = 'F1Factor'")
                    If Not IsDBNull(row.Item(fieldName)) AndAlso _
                     Convert.ToDouble(row.Item(fieldName)) <> 0 Then
                        .Data.Item(0, index) = Convert.ToDouble(row.Item(fieldName))
                        .Data.Labels(index) = row.Item(xAxis).ToString
                    End If
                    index += 1
                Next

                index = 0
                For Each row As DataRow In _fChartData.Select("TagId = 'F2Factor'")
                    If Not IsDBNull(row.Item(fieldName)) AndAlso _
                     Convert.ToDouble(row.Item(fieldName)) <> 0 Then
                        .Data.Item(1, index) = Convert.ToDouble(row.Item(fieldName))
                        .Data.Labels(index) = row.Item(xAxis).ToString
                    End If
                    index += 1
                Next

                index = 0
                For Each row As DataRow In _fChartData.Select("TagId = 'F3Factor'")
                    If Not IsDBNull(row.Item(fieldName)) AndAlso _
                     Convert.ToDouble(row.Item(fieldName)) <> 0 Then
                        .Data.Item(2, index) = Convert.ToDouble(row.Item(fieldName))
                        .Data.Labels(index) = row.Item(xAxis).ToString
                    End If
                    index += 1
                Next


                reportColorList = DalUtility.GetBhpbioReportColorList("F1Factor", True)
                markerShape = "Diamond"
                lineStyle = "Solid"
                color = "#169452"
                If (Not reportColorList Is Nothing) Then
                    If (reportColorList.Rows.Count > 0) Then
                        color = reportColorList.Rows(0).Item("Color").ToString
                        lineStyle = reportColorList.Rows(0).Item("LineStyle").ToString
                        markerShape = reportColorList.Rows(0).Item("MarkerShape").ToString
                    End If
                End If

                .Series(0).Color = GetSeriesColor(color)  'Drawing.Color.FromArgb(255, 22, 148, 82)
                .Series(0).MarkerShape = CType([Enum].Parse(GetType(MarkerShape), markerShape, True), MarkerShape)
                .Series(0).Line.Style = CType([Enum].Parse(GetType(Drawing.Drawing2D.DashStyle), lineStyle, True), Drawing.Drawing2D.DashStyle)

                .AxisY.DataFormat.Decimals = 2

                reportColorList = DalUtility.GetBhpbioReportColorList("F2Factor", True)
                markerShape = "Rect"
                lineStyle = "Solid"
                color = "#FD09FD"
                If (Not reportColorList Is Nothing) Then
                    If (reportColorList.Rows.Count > 0) Then
                        color = reportColorList.Rows(0).Item("Color").ToString
                        lineStyle = reportColorList.Rows(0).Item("LineStyle").ToString
                        markerShape = reportColorList.Rows(0).Item("MarkerShape").ToString
                    End If
                End If

                .Series(1).Color = GetSeriesColor(color) '  Drawing.Color.From Drawing.Color.FromArgb(255, 253, 9, 253)
                .Series(1).MarkerShape = CType([Enum].Parse(GetType(MarkerShape), markerShape, True), MarkerShape)
                .Series(1).Line.Style = CType([Enum].Parse(GetType(Drawing.Drawing2D.DashStyle), lineStyle, True), Drawing.Drawing2D.DashStyle)

                reportColorList = DalUtility.GetBhpbioReportColorList("F3Factor", True)
                markerShape = "Triangle"
                lineStyle = "Solid"
                color = "RoyalBlue"
                If (Not reportColorList Is Nothing) Then
                    If (reportColorList.Rows.Count > 0) Then
                        color = reportColorList.Rows(0).Item("Color").ToString
                        lineStyle = reportColorList.Rows(0).Item("LineStyle").ToString
                        markerShape = reportColorList.Rows(0).Item("MarkerShape").ToString
                    End If
                End If

                .Series(2).Color = GetSeriesColor(color) ' 'Drawing.Color.RoyalBlue
                .Series(2).MarkerShape = CType([Enum].Parse(GetType(MarkerShape), markerShape, True), MarkerShape)
                .Series(2).Line.Style = CType([Enum].Parse(GetType(Drawing.Drawing2D.DashStyle), lineStyle, True), Drawing.Drawing2D.DashStyle)


                Dim lowerThreshold As New CustomGridLine
                lowerThreshold.Value = lowThreshold
                lowerThreshold.ShowLine = True
                lowerThreshold.Color = Drawing.Color.Red
                lowerThreshold.Width = 1

                Dim higherThreshold As New CustomGridLine
                higherThreshold.Value = highThreshold
                higherThreshold.ShowLine = True
                higherThreshold.Color = Drawing.Color.Red
                higherThreshold.Width = 1

                .AxisY.CustomGridLines.Add(lowerThreshold)
                .AxisY.CustomGridLines.Add(higherThreshold)


                .AxisY.Step = axisScale

                .AxisY.Max = maxValue
                .AxisY.Min = minValue

                .Width = 320
                .Height = 240
            End With

            If (Not reportColorList Is Nothing) Then
                reportColorList.Dispose()
                reportColorList = Nothing
            End If

            Return homeChart
        End Function

        Private Function GetSeriesColor(ByVal colorString As String) As System.Drawing.Color
            Dim newColor As System.Drawing.Color
            Dim red, green, blue As Integer

            red = 0
            green = 0
            blue = 0

            If ((colorString.StartsWith("#")) And (colorString.Length = 7)) Then
                red = HexToInt(colorString.Substring(1, 2))
                green = HexToInt(colorString.Substring(3, 2))
                blue = HexToInt(colorString.Substring(5, 2))

                newColor = System.Drawing.Color.FromArgb(255, red, green, blue)
            Else
                newColor = System.Drawing.Color.FromName(colorString)
            End If

            Return newColor
        End Function

        Private Function HexToInt(ByVal hexStr As String) As Integer
            Dim hexInt, counter As Integer
            Dim hexArr() As Char

            hexInt = 0
            hexStr = hexStr.ToUpper()
            hexArr = hexStr.ToCharArray()

            For counter = 0 To hexArr.Length - 1
                If (hexArr(counter) >= "0") And (hexArr(counter) <= "9") Then
                    hexInt += (Convert.ToInt32(hexArr(counter)) - 48) * Convert.ToInt32((Math.Pow(16, hexArr.Length - 1 - counter)))
                Else
                    If (hexArr(counter) >= "A") And (hexArr(counter) <= "F") Then
                        hexInt += (Convert.ToInt32(hexArr(counter)) - 55) * Convert.ToInt32((Math.Pow(16, hexArr.Length - 1 - counter)))
                    Else
                        hexInt = 0
                    End If
                End If
            Next

            Return hexInt
        End Function

        Protected Overrides Function ValidateData() As String
            Dim returnStr As New System.Text.StringBuilder(MyBase.ValidateData())

            If (DateFrom > DateTo) Then
                returnStr.Append(" - Period From must be before the Period To")
            End If

            Dim dr As DataRow
            If (Not FieldAttributes Is Nothing AndAlso FieldAttributes.Rows.Count <> 0) Then
                Dim standardFactors = FieldAttributes.Select("ThresholdTypeId in ('F1Factor', 'F2Factor', 'F3Factor')")
                For Each dr In standardFactors
                    If dr("LowThreshold").Equals(DBNull.Value) Or dr("HighThreshold").Equals(DBNull.Value) _
                    Or dr("AbsoluteThreshold").Equals(DBNull.Value) Then
                        returnStr.Append("- Thresholds are missing for either F1, F2, or F3, please correct this in utilities.")
                        Exit For
                    End If
                Next
            End If

            Return returnStr.ToString
        End Function

        Protected Overrides Sub SetupDalObjects()
            If (DalReport Is Nothing) Then
                DalReport = New Bhpbio.Database.SqlDal.SqlDalReport(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Function CheckIsSite() As Boolean
            Dim isSite As Boolean = False
            Dim locationData As New DataTable

            locationData = DalUtility.GetLocationList(1, DoNotSetValues.Int32, LocationId, DoNotSetValues.Int16)

            If (locationData.Rows.Count > 0) Then
                If (locationData.Rows(0).Item("Location_Type_Description").ToString = "Site") Then
                    isSite = True
                End If
            End If

            If (Not locationData Is Nothing) Then
                locationData.Dispose()
                locationData = Nothing
            End If

            Return isSite
        End Function

        Private Function GetStartDate() As DateTime?
            Dim dalUtility As Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
            Dim startDate As DateTime

            dalUtility = New Snowden.Reconcilor.Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            Try
                If DateTime.TryParse(dalUtility.GetSystemSetting(_startDateSetting), startDate) Then
                    Return startDate
                Else
                    Return Nothing
                End If
            Finally
                If Not dalUtility Is Nothing Then
                    dalUtility.Dispose()
                    dalUtility = Nothing
                End If
            End Try
        End Function

    End Class
End Namespace
