Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs

Namespace ReconcilorControls.FilterBoxes.Approval
    Public Class ApprovalFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

#Region " Properties "
        Private _disposed As Boolean
        Private _monthFilter As New MonthFilter
		Private _locationSelector As New Controls.ReconcilorLocationSelector
		Private _limitRecords As New InputTags.InputCheckBoxFormless
        Private _showLimit As Boolean = True
        Private _columnTable As New Tags.HtmlTableTag

        Public ReadOnly Property MonthFilter() As MonthFilter
            Get
                Return _monthFilter
            End Get
        End Property

        Public ReadOnly Property LocationSelector() As Controls.ReconcilorLocationSelector
            Get
                Return _locationSelector
            End Get
        End Property

        Protected ReadOnly Property LimitRecords() As InputTags.InputCheckBoxFormless
            Get
                Return _limitRecords
            End Get
        End Property

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
				Dispose()
            End Try
        End Sub
#End Region

        Protected Overrides Sub SetupControls()
            Dim approvalMonth As DateTime
            Dim locationId As Int32
            Dim settingDate As String = Resources.UserSecurity.GetSetting("Approval_Filter_Date", DateTime.Now.ToString("O"))
            Dim settingLocation As String = Resources.UserSecurity.GetSetting("Approval_Filter_LocationId", "0")

            With LocationSelector
                .ID = "ApprovalFilterLocationId" 'Prevent any conflicts with the ApprovalNavigator
                .LowestLocationTypeDescription = "PIT"
                If (.LocationId Is Nothing Or .LocationId < 0) AndAlso Int32.TryParse(settingLocation, locationId) AndAlso locationId > 0 Then
                    .LocationId = locationId
                End If

                If ShowLimit Then
                    .OnChange = "ChangedLocationApprovalBlockList"
                Else
                    .OnChange = "ClearApprovalList"
				End If
            End With

            With MonthFilter
                .Index = "ApprovalFilter" 'Prevent any conflicts with the ApprovalNavigator

                If (.SelectedDate Is Nothing Or .SelectedDate.Equals(DateTime.MinValue)) AndAlso DateTime.TryParse(settingDate, approvalMonth) Then
                    .SelectedDate = approvalMonth
                End If
            End With

            LocationSelector.StartDate = MonthFilter.SelectedDate
            MonthFilter.OnSelectChangeCallback = $"CheckMonthLocationApproval({MonthFilter.Index});"

            With LimitRecords
                .ID = "LimitRecords"
                .Checked = True
            End With

            With FilterButton
                .ID = "ApprovalFilterButton"
                .Text = "Refresh"
                .CssClass = "inputButtonSmall"
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
