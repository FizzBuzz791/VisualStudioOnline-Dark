Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Controls.FilterBoxes.Utilities
	Public Class ImportsFilterBox
		Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

		Private _dateFrom As Date = Nothing
        Private _monthFilter As New MonthFilter
        Private _locationSelector As New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
        Private _disposed As Boolean
        Private _defaultDate As Date

        Const TAG_PAGE_WIDTH As Integer = 640
        Const LOCATION_CELL_WIDTH As Integer = 100
        Const LOWEST_DESCRIPTION As String = "BLOCK"

        Protected ReadOnly Property MonthFilter As MonthFilter
            Get
                Return _monthFilter
            End Get
        End Property

        Protected ReadOnly Property LocationSelector As Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
            Get
                Return _locationSelector
            End Get
        End Property

        Protected ReadOnly Property ResetButton As InputButtonFormless = New InputButtonFormless

		Protected ReadOnly Property DateFromRadio As InputRadio = New InputRadio

		Protected ReadOnly Property MonthLocationRadio As InputRadio = New InputRadio

        Public Sub SetDateFrom(dateFrom As Date)
            _dateFrom = dateFrom
        End Sub

        Public Sub SetMonth(month As Date)
            _monthFilter.SelectedDate = month
        End Sub

        Public Sub SetLocation(locationId As Integer)
            _locationSelector.LocationId = locationId
        End Sub

        Public Sub SetFilter(useMonthLocation As Boolean)
            DateFromRadio.Checked = Not useMonthLocation
            MonthLocationRadio.Checked = useMonthLocation
        End Sub

        Public Sub SetDefaultDate(defaultDate As Date)
            _defaultDate = defaultDate
        End Sub

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            ID = "ImportsFilterBox"
            Attributes.Add("class", "show")

            FilterButton.ID = "ImportsFilterButton"
            ButtonOnNewRow = False

            With LayoutGroupBox
                .Width = TAG_PAGE_WIDTH
                .Title = "Filter Validation Errors"
            End With

            With LocationSelector
                .ID = "LocationId"
                .LocationLabelCellWidth = LOCATION_CELL_WIDTH
                .LowestLocationTypeDescription = LOWEST_DESCRIPTION
            End With

            With MonthFilter
                .ID = "MonthFilter"
                If .SelectedDate Is Nothing Then
                    .SelectedDate = DateTime.Today
                End If
            End With

            With ResetButton
                .ID = "ImportsFilterResetButton"
                .Value = String.Format("Reset Filters")
                .OnClientClick = String.Format("ResetImportsFilters('{0}', {1}, '{2}', '{3:dd-MMM-yyyy}');", LocationSelector.LocationDiv.ID, LOCATION_CELL_WIDTH.ToString(), LOWEST_DESCRIPTION, _defaultDate)
            End With

            With DateFromRadio
                .ID = "DateFromRadio"
                .Value = "DateFromSelected"
                .GroupName = "ImportsFilterRadioGroup"
                .Attributes.Add("onchange", "SetFilterControlsStates(true);")
            End With

            With MonthLocationRadio
                .ID = "MonthLocationRadio"
                .Value = "MonthLocationSelected"
                .GroupName = "ImportsFilterRadioGroup"
                .Attributes.Add("onchange", "SetFilterControlsStates(false);")
            End With
        End Sub

        Public Sub ResetFilters()
            LocationSelector.LocationId = Convert.ToInt32(Resources.UserSecurity.GetSetting("Stockpile_Filter_Locations", Int32.MinValue.ToString()))
        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()

            Dim initialiseDate = If (_dateFrom = Nothing, DateTime.Today.AddDays(-1), _dateFrom)
            Dim datePicker = New WebpageControls.DatePicker("ImportDateFrom", ServerForm.ID, initialiseDate)
            DatePickers.Add("ImportDateFrom", datePicker)

            FilterButton.OnClientClick = "return GetBhpbioImportsTabContent();"
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            Dim rowIndex As Integer
            Dim cellIndex As Integer

            With LayoutTable
                .ID = "ImportsLayoutTable"

                ' Date From row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    ' Radio
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(DateFromRadio)
                    End With

                    ' Label
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(New LiteralControl("Date&nbsp;From: "))
                    End With

                    ' Control
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(DatePickers("ImportDateFrom").ControlScript)
                    End With

                    ' wtf?
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Width = Unit.Percentage(100)
                    End With
                End With

                ' Month row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)

                    ' Radio
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(MonthLocationRadio)
                        .RowSpan = 2
                    End With

                    ' Label
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(New LiteralControl("Transaction&nbsp;Month: "))
                    End With

                    ' Control
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(MonthFilter)
                    End With
                End With

                ' Location row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .ColumnSpan = 6
                        .Controls.Add(LocationSelector)
                    End With
                End With

                ' Reset Button
                rowIndex = .Rows.Add(New TableRow())
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .Controls.Add(ResetButton)
                        .Controls.Add(New LiteralControl("&nbsp;"))
                        .HorizontalAlign = HorizontalAlign.Right
                    End With
                End With
            End With
        End Sub

        Protected Overridable Overloads Sub Dispose(disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If Not _monthFilter Is Nothing Then
                            _monthFilter.Dispose()
                            _monthFilter = Nothing
                        End If

                        If Not _locationSelector Is Nothing Then
                            _locationSelector.Dispose()
                            _locationSelector = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                Dispose()
            End Try
        End Sub
	End Class
End Namespace