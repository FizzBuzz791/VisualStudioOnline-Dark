Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs

Namespace ReconcilorControls.FilterBoxes.Approval
    Public Class ApprovalF1F2F3Filter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

#Region " Properties "
        Private _disposed As Boolean
        Private _monthFilter As New MonthFilter
		Private _locationSelector As New Controls.ReconcilorLocationSelector
        Private _limitRecords As New InputTags.InputCheckBoxFormless
		'Private _locationPicker As New LocationPicker("LocationTreeId")
        Private _showLimit As Boolean = True
        Private _columnTable As New Tags.HtmlTableTag

		Protected ReadOnly Property MonthFilter() As MonthFilter
			Get
				Return _monthFilter
			End Get
		End Property

		Protected ReadOnly Property LocationSelector() As Controls.ReconcilorLocationSelector
			Get
				Return _locationSelector
			End Get
		End Property

        Protected ReadOnly Property LimitRecords() As InputTags.InputCheckBoxFormless
            Get
                Return _limitRecords
            End Get
        End Property

		'Protected ReadOnly Property LocationPicker() As LocationPicker
		'	Get
		'		Return _locationPicker
		'	End Get
		'End Property

        Public Property ShowLimit() As Boolean
            Get
                Return _showLimit
            End Get
            Set(ByVal value As Boolean)
                _showLimit = value
            End Set
        End Property

        Public ReadOnly Property ColumnTable() As Tags.HtmlTableTag
            Get
                Return _columnTable
            End Get
        End Property
#End Region

#Region " Destructors "
        Protected Overridable Overloads Sub Dispose(ByVal disposing As Boolean)
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
                MyBase.Dispose()
            End Try
        End Sub
#End Region

        Protected Overrides Sub SetupControls()
            Dim approvalMonth As DateTime
            Dim locationId As Int32
            Dim settingDate As String = Resources.UserSecurity.GetSetting("Approval_Filter_Date", DateTime.Now.ToString("O"))
            Dim settingLocation As String = Resources.UserSecurity.GetSetting("Approval_Filter_LocationId", "0")

            With LocationSelector
                .ID = "LocationId"
                .LowestLocationTypeDescription = "PIT"
                If Int32.TryParse(settingLocation, locationId) AndAlso locationId > 0 Then
                    .LocationId = locationId
                End If

                If ShowLimit Then
                    .OnChange = "ChangedLocationApprovalBlockList"
                Else
                    .OnChange = "ClearApprovalList"
				End If

                '.DalSecurity = DalSecurity
                'LocationFilter.LocationLabelCellWidth = LocationCellWidth
                'If locationId <> DoNotSetValues.Int32 Then
                '    LocationFilter.LocationId = locationId
                'End If
			End With

			If DateTime.TryParse(settingDate, approvalMonth) Then
				MonthFilter.SelectedDate = approvalMonth
				LocationSelector.StartDate = approvalMonth
			End If

			MonthFilter.OnSelectChangeCallback = "CheckMonthLocationApproval();"

            With LimitRecords
                .ID = "LimitRecords"
                .Checked = True
            End With

            With FilterButton
                .ID = "ApprovalFilterButton"
                .Text = "Refresh"
                .CssClass = "inputButtonSmall"
                .OnClientClick = "return GetApprovalDataList();"
            End With

            With LayoutGroupBox
                .Title = "Validation Filter"
            End With

            ButtonOnNewRow = True
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            With ColumnTable
                ' Month Picker
                .AddCellInNewRow().Controls.Add(New LiteralControl("Month:"))
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .AddCell().Controls.Add(MonthFilter)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                ' Limit Rows Filter
                .AddCellInNewRow()
                If ShowLimit Then
                    .CurrentCell.Controls.Add(LimitRecords)
                    .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                    .CurrentCell.Controls.Add(New LiteralControl("Limit Records"))
                    .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                End If
            End With

            With LayoutTable
                ' New Location Picker
                '.AddCellInNewRow().Controls.Add(New LiteralControl("Location:"))
                '.CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                '.AddCell().Controls.Add(LocationPicker)
                '.CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                .AddCellInNewRow().Controls.Add(ColumnTable)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top

                ' Old Location Picker
                .AddCell().Controls.Add(LocationSelector)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.Width = 500

            End With
        End Sub

    
    End Class
End Namespace
