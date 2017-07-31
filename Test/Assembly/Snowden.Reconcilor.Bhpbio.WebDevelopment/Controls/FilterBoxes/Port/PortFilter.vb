Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs

Namespace ReconcilorControls.FilterBoxes.Port
    Public Class PortFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

        Private _lowestLocationTypeDescription As String = "Hub"
        Private _resetButton As Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
        Private _disposed As Boolean
        Private _dalUtility As Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
        Private _locationSelector As Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
        Private _dateFrom As Common.Web.BaseHtmlControls.WebpageControls.DatePicker
        Private _dateTo As Common.Web.BaseHtmlControls.WebpageControls.DatePicker

        Public Property DalUtility() As Core.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _dalUtility = value
                End If
            End Set
        End Property

        Public ReadOnly Property ResetButton() As Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _resetButton
            End Get
        End Property

        Protected Overridable Overloads Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If Not _dateFrom Is Nothing Then
                            _dateFrom.Dispose()
                            _dateFrom = Nothing
                        End If

                        If Not _dateTo Is Nothing Then
                            _dateTo.Dispose()
                            _dateTo = Nothing
                        End If

                        If Not _locationSelector Is Nothing Then
                            _locationSelector.Dispose()
                            _locationSelector = Nothing
                        End If
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose()
            End Try
        End Sub

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            ButtonOnNewRow = False

            ID = "PortFilterBox"
            Attributes.Add("class", "show")

            With FilterButton
                .ID = "PortFilterButton"
            End With

            With LayoutGroupBox
                .Width = 700
                .Title = "Port Filter"
            End With
        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            Dim settingLocation As String
            Dim settingDateFrom As String
            Dim settingDateTo As String
            Dim dateValue As DateTime
            Dim locationId As Int32

            MyBase.SetupFormAndDatePickers()

            settingLocation = Resources.UserSecurity.GetSetting("Port_Filter_LocationId", Nothing)
            settingDateFrom = Resources.UserSecurity.GetSetting("Port_Filter_DateFrom", Nothing)
            settingDateTo = Resources.UserSecurity.GetSetting("Port_Filter_DateTo", Nothing)

            ServerForm.ID = "portForm"
            ServerForm.OnSubmit = "return ValidatePortFilterParameters();"

            'load the settings
            'set up the date controls
            If (settingDateFrom Is Nothing) OrElse (Not DateTime.TryParse(settingDateFrom, dateValue)) Then
                dateValue = DateTime.Today.AddDays(-7)
            End If
            DatePickers.Add("PortDateFrom", New WebpageControls.DatePicker("PortDateFrom", ServerForm.ID, dateValue))

            If (settingDateTo Is Nothing) OrElse (Not DateTime.TryParse(settingDateTo, dateValue)) Then
                dateValue = DateTime.Today
            End If
            DatePickers.Add("PortDateTo", New WebpageControls.DatePicker("PortDateTo", ServerForm.ID, dateValue))

            'set up the location picker
            _locationSelector = New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
            _locationSelector.ID = "LocationId"
            _locationSelector.LowestLocationTypeDescription = _lowestLocationTypeDescription
            If (settingLocation Is Nothing) OrElse Not Int32.TryParse(settingLocation, locationId) Then
                'there is no applicable default
                locationId = Nothing
            End If
            _locationSelector.LocationId = locationId
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            Dim row As WebControls.TableRow
            Dim cell As WebControls.TableCell
            Dim dateTable As WebControls.Table
            Dim locationTable As WebControls.Table

            'date table
            dateTable = New WebControls.Table()

            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Controls.Add(New LiteralControl("Date From: "))
            cell.VerticalAlign = VerticalAlign.Middle
            cell.HorizontalAlign = HorizontalAlign.Left
            row.Cells.Add(cell)

            cell = New WebControls.TableCell()
            cell.Controls.Add(DatePickers("PortDateFrom").ControlScript)
            cell.VerticalAlign = VerticalAlign.Middle
            cell.HorizontalAlign = HorizontalAlign.Left
            row.Cells.Add(cell)

            dateTable.Rows.Add(row)

            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Controls.Add(New LiteralControl("Date To: "))
            cell.VerticalAlign = VerticalAlign.Middle
            cell.HorizontalAlign = HorizontalAlign.Left
            row.Cells.Add(cell)

            cell = New WebControls.TableCell()
            cell.Controls.Add(DatePickers("PortDateTo").ControlScript)
            cell.VerticalAlign = VerticalAlign.Middle
            cell.HorizontalAlign = HorizontalAlign.Left
            row.Cells.Add(cell)

            dateTable.Rows.Add(row)

            'location table
            locationTable = New WebControls.Table

            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Controls.Add(_locationSelector)
            cell.VerticalAlign = VerticalAlign.Middle
            cell.HorizontalAlign = HorizontalAlign.Left
            row.Cells.Add(cell)

            cell = New WebControls.TableCell()
            row.Cells.Add(cell)

            locationTable.Rows.Add(row)

            'add to the full layout
            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Width = 220
            cell.Controls.Add(dateTable)
            row.Cells.Add(cell)

            cell = New WebControls.TableCell()
            cell.Controls.Add(locationTable)
            row.Cells.Add(cell)

            LayoutTable.Controls.Add(row)

            'add the reset button
            _resetButton = New Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
            _resetButton.ID = "PortFilterResetButton"
            _resetButton.Value = " Reset Filters "
            _resetButton.OnClientClick = "ResetPortFilters('" + _locationSelector.LocationDiv.ID + "', '" & _lowestLocationTypeDescription & "');"

            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Controls.Add(_resetButton)
            cell.Controls.Add(New LiteralControl("&nbsp;"))
            cell.HorizontalAlign = HorizontalAlign.Right
            row.Cells.Add(cell)

            LayoutTable.Controls.Add(row)
        End Sub

    End Class
End Namespace
