Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports System.Web.UI.WebControls

Namespace ReconcilorControls.FilterBoxes.Home

    Public Class HomeFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

        Private Const _startDateSetting As String = "HISTORICAL_START_DATE"

        Private _disposed As Boolean
        Private _periodFilter As New InputTags.SelectBox
        Private _locationId As Integer
        Private _locationValue As New InputTags.InputHidden

        Private _yearFromList As New InputTags.SelectBox
        Private _yearToList As New InputTags.SelectBox
        Private _monthQuarterFromList As New InputTags.SelectBox
        Private _monthQuarterToList As New InputTags.SelectBox

        Private _onPeriodSelectChange As String
        Private _siteId As Integer
        Private _selectedPeriod As String  'stores the loaded selected period (from the user settings)

        Public Property SiteId() As Integer
            Get
                Return _siteId
            End Get
            Set(ByVal value As Integer)
                _siteId = value
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

        Public ReadOnly Property LocationValue() As InputTags.InputHidden
            Get
                Return _locationValue
            End Get
        End Property

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()

            ServerForm.ID = "homeForm"
            ServerForm.OnSubmit = "return GetFFactorData('" + SiteId.ToString() + "');"
        End Sub

        Protected Overrides Sub CompleteLayout()
            Dim RowIndex, CellIndex As Int32
            Dim outerTable As New Tags.HtmlTableTag

            With LayoutTable
                .Height = WebControls.Unit.Percentage(100)
                .Width = WebControls.Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                .AddCell().Controls.Add(FilterButton)
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.VerticalAlign = ButtonVerticalAlignment
            End With

            LayoutGroupBox.Controls.Add(LayoutTable)

            With outerTable
                .CssClass = "FilterBoxOuterTable"
                .CellPadding = 0
                .CellSpacing = 0

                RowIndex = .Rows.Add(New WebControls.TableRow)
                With .Rows(RowIndex)
                    CellIndex = .Cells.Add(New TableCell)
                    With .Cells(CellIndex)
                        .Controls.Add(LayoutGroupBox)
                    End With
                End With
            End With

            'in this case we know we have been provided a form
            Controls.Add(outerTable)

            'force an initial refresh of the date controls
            'pass through the defaults
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             GetRenderHomePeriodWithDefaultsJs(_selectedPeriod)))
        End Sub

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

        Protected Overrides Sub SetupControls()
            _selectedPeriod = Resources.UserSecurity.GetSetting("Home_Filter_Period", "QUARTER")

            ButtonOnNewRow = False

            _periodFilter.ID = "HomePeriodFilter"
            _periodFilter.OnSelectChange = "javascript:" & _
             GetRenderHomePeriodWithDefaultsJs(_selectedPeriod)
            'load the default entries
            _periodFilter.Items.Insert(0, New ListItem("Calendar Month", "MONTH"))
            _periodFilter.Items.Insert(1, New ListItem("Financial Quarter", "QUARTER"))
            _periodFilter.Items.Insert(2, New ListItem("Calendar Year", "YEAR"))
            _periodFilter.SelectedValue = _selectedPeriod

            'from items
            _monthQuarterFromList.ID = "HomePeriodFromMonthQuarter"
            _yearFromList.ID = "HomePeriodFromYear"
            _yearFromList.OnSelectChange = "javascript:RenderHomePeriodMonthQuarter(null, null, null, null);"

            'to items
            _monthQuarterToList.ID = "HomePeriodToMonthQuarter"
            _yearToList.ID = "HomePeriodToYear"
            _yearToList.OnSelectChange = "javascript:RenderHomePeriodMonthQuarter(null, null, null, null);"

            _locationValue.ID = "HomeLocationID"
            _locationValue.Value = LocationId.ToString()

            FilterButton.ID = "HomeFilterButton"
            FilterButton.Text = "Refresh"
            FilterButton.CssClass = "inputButtonSmall"

            LayoutGroupBox.Title = "Filter Options"
        End Sub

        Private Function GetQuarter(ByVal calenderDate As DateTime) As String
            Select Case calenderDate.Month
                Case 1, 2, 3
                    GetQuarter = "Q3"
                Case 4, 5, 6
                    GetQuarter = "Q4"
                Case 7, 8, 9
                    GetQuarter = "Q1"
                Case Else
                    GetQuarter = "Q2"
            End Select
        End Function

        Private Function GetQuarterYear(ByVal calenderDate As DateTime) As String
            Select Case calenderDate.Month
                Case 1, 2, 3, 4, 5, 6
                    GetQuarterYear = calenderDate.Year.ToString()
                Case Else
                    GetQuarterYear = DateAdd(DateInterval.Year, 1, calenderDate).Year.ToString()
            End Select
        End Function

        Private Function GetRenderHomePeriodWithDefaultsJs(ByVal defaultPeriod As String) As String
            Dim defaultDateFrom, defaultDateTo As DateTime
            Dim dateParsed As DateTime
            Dim dateSetting As String
            Dim result As String

            'load the settings from the user settings
            defaultDateFrom = DateAdd(DateInterval.Quarter, -1, Now)
            defaultDateFrom = GetDefaultFromDate(defaultDateFrom)
            defaultDateTo = GetDefaultToDate(defaultDateFrom)

            dateSetting = Resources.UserSecurity.GetSetting("Home_Filter_Date_From", defaultDateFrom.ToString("dd-MMM-yyyy"))
            If DateTime.TryParse(dateSetting, dateParsed) Then
                defaultDateFrom = dateParsed
            End If

            dateSetting = Resources.UserSecurity.GetSetting("Home_Filter_Date_To", defaultDateTo.ToString("dd-MMM-yyyy"))
            If DateTime.TryParse(dateSetting, dateParsed) Then
                defaultDateTo = dateParsed
            End If

            'provide the defaults for the controls
            result = "RenderHomePeriodYear('{0}', '{1}', '{2}', '{3}');"
            Select Case defaultPeriod
                Case "MONTH"
                    result = String.Format(result, _
                     defaultDateFrom.Year.ToString(), defaultDateTo.Year.ToString(), _
                     defaultDateFrom.Month.ToString(), defaultDateTo.Month.ToString())
                Case "QUARTER"
                    result = String.Format(result, _
                     GetQuarterYear(defaultDateFrom), GetQuarterYear(defaultDateTo), _
                     GetQuarter(defaultDateFrom), GetQuarter(defaultDateTo))
                Case "YEAR"
                    result = String.Format(result, _
                     defaultDateFrom.Year.ToString(), defaultDateTo.Year.ToString(), _
                     "null", "null")
                Case Else
                    result = String.Format(result, "null", "null", "null", "null")
            End Select

            Return result
        End Function

        Private Function GetDefaultFromDate(ByVal quarterDate As DateTime) As DateTime
            Dim firstDate As New DateTime
            Dim quarterMonth As Integer

            Select Case (quarterDate.Month)
                Case 1, 2, 3
                    quarterMonth = 1
                Case 4, 5, 6
                    quarterMonth = 4
                Case 7, 8, 9
                    quarterMonth = 7
                Case 10, 11, 12
                    quarterMonth = 10
            End Select

            firstDate = New DateTime(quarterDate.Year, quarterMonth, 1)

            Return firstDate
        End Function

        Private Function GetDefaultToDate(ByVal quarterDate As DateTime) As DateTime
            Dim lastDate As New DateTime
            Dim quarterMonth As Integer

            Select Case (quarterDate.Month)
                Case 1, 2, 3
                    quarterMonth = 3
                Case 4, 5, 6
                    quarterMonth = 6
                Case 7, 8, 9
                    quarterMonth = 9
                Case 10, 11, 12
                    quarterMonth = 12
            End Select

            lastDate = New DateTime(quarterDate.Year, quarterMonth, Date.DaysInMonth(quarterDate.Year, quarterMonth))

            Return lastDate
        End Function

        Private Shared Function GetMonthText(ByVal month As Int32) As String
            Select Case month
                Case 1 : Return "January"
                Case 2 : Return "February"
                Case 3 : Return "March"
                Case 4 : Return "April"
                Case 5 : Return "May"
                Case 6 : Return "June"
                Case 7 : Return "July"
                Case 8 : Return "August"
                Case 9 : Return "September"
                Case 10 : Return "October"
                Case 11 : Return "November"
                Case 12 : Return "December"
                Case Else : Return "N/A"
            End Select
        End Function

        Private Sub AddCalendarMonths(ByVal startDate As DateTime, ByVal endDate As DateTime, _
         ByVal controls As Web.UI.ControlCollection)
            Dim script As String
            Dim currentDate As DateTime

            'register all valid Calendar Months
            'adds in the format of: '2006', '2006', '1', 'January'
            script = "AddCalendarMonth('{0}', '{1}', '{2}', '{3}');"
            currentDate = New DateTime(startDate.Year, startDate.Month, 1)
            While currentDate <= endDate
                controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                 String.Format(script, _
                 currentDate.Year.ToString(), currentDate.Year.ToString(), _
                 currentDate.Month.ToString(), GetMonthText(currentDate.Month))))

                currentDate = currentDate.AddMonths(1)
            End While
        End Sub

        Private Sub AddFinancialQuarters(ByVal startDate As DateTime, ByVal endDate As DateTime, _
         ByVal controls As Web.UI.ControlCollection)

            Dim previousQuarter As String
            Dim currentQuarter As String
            Dim currentQuarterText As String
            Dim currentDate As DateTime
            Dim script As String

            'register all valid Financial Quarters
            'adds in the format of: '2006', '2006', 'Q1', 'Quarter 1'
            script = "AddFinancialQuarter('{0}', '{1}', '{2}', '{3}');"

            previousQuarter = Nothing
            currentDate = startDate
            While currentDate <= endDate
                'convert the DATE/TIME into a FY format
                currentQuarter = GetQuarter(currentDate)

                Select Case currentQuarter
                    Case "Q1" : currentQuarterText = "Quarter 1"
                    Case "Q2" : currentQuarterText = "Quarter 2"
                    Case "Q3" : currentQuarterText = "Quarter 3"
                    Case "Q4" : currentQuarterText = "Quarter 4"
                    Case Else : currentQuarterText = "N/A"
                End Select

                If currentQuarter <> previousQuarter Then
                    'note: adjust the year forward by 1 if it falls into the next financial year
                    controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                     String.Format(script, _
                     IIf(currentDate.Month >= 7, currentDate.Year + 1, currentDate.Year).ToString(), _
                     IIf(currentDate.Month >= 7, currentDate.Year + 1, currentDate.Year).ToString(), _
                     currentQuarter, currentQuarterText)))
                End If

                currentDate = currentDate.AddMonths(3)
                previousQuarter = currentQuarter
            End While
        End Sub

        Protected Overrides Sub SetupLayout()
            Dim columnTable As New Tags.HtmlTableTag

            Dim periodFromLayout As New Tags.HtmlTableTag
            Dim periodToLayout As New Tags.HtmlTableTag

            Dim startDate As DateTime?
            Dim endDate As DateTime

            MyBase.SetupLayout()

            startDate = GetStartDate().Value
            If Not startDate.HasValue Then
                Throw New InvalidOperationException(String.Format("The system setting '{0}' is not valid.", _startDateSetting))
            End If
            endDate = DateTime.Today()

            AddCalendarMonths(startDate.Value, endDate, Controls)
            AddFinancialQuarters(startDate.Value, endDate, Controls)

            With columnTable
                .CellPadding = 3
                'Period Type
                .AddCellInNewRow().Controls.Add(New LiteralControl("Period:"))
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .AddCell().Controls.Add(_periodFilter)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                'Period From
                .AddCell().Controls.Add(New LiteralControl("From:"))
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                With periodFromLayout
                    .CellPadding = 1
                    .CellSpacing = 0
                    .AddCellInNewRow.Controls.Add(_monthQuarterFromList)
                    .AddCell.Controls.Add(_yearFromList)
                End With

                .AddCell().Controls.Add(periodFromLayout)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                'Period To
                .AddCell().Controls.Add(New LiteralControl("To:"))
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                With periodToLayout
                    .CellPadding = 1
                    .CellSpacing = 0
                    .AddCellInNewRow.Controls.Add(_monthQuarterToList)
                    .AddCell.Controls.Add(_yearToList)
                End With

                .AddCell().Controls.Add(periodToLayout)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                .AddCell().Controls.Add(LocationValue)
            End With

            With LayoutTable
                .AddCellInNewRow().Controls.Add(columnTable)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
            End With

            periodFromLayout.Dispose()
            periodToLayout.Dispose()
            periodFromLayout = Nothing
            periodToLayout = Nothing
        End Sub
    End Class

End Namespace
