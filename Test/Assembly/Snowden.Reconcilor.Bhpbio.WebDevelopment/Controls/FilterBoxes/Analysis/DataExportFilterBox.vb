Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.FilterBoxes
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Controls

Namespace ReconcilorControls.FilterBoxes.Analysis
    Public Class DataExportFilterBox
        Inherits ReconcilorFilterBox

        Public Shared ReadOnly Approved As String = "Standard"
        Public Shared ReadOnly Live As String = "LiveOnly"
        Public Shared ReadOnly CombinedApprovedLive As String = "ApprovalListing"

        Public Shared ReadOnly MonthlyBreakdown As String = "MONTH"
        Public Shared ReadOnly QuarterlyBreakdown As String = "QUARTER"

#Region "Properties"

        Private _lowestLocationTypeDescription As String
        Private _displayDateBreakDown As Boolean
        Private _displayApprovalStatus As Boolean
        Private _displayLumpFines As Boolean
        Private _displayProductPicker As Boolean
        Private _displayIncludeSublocations As Boolean
        Private _displayIncludeResourceClassifications As Boolean
        Private _groupBoxTitle As String = " Data Export "
        Private _startDateFilter As MonthQuarterFilter
        Private _endDateFilter As MonthQuarterFilter
        Private _locationSelect As Controls.ReconcilorLocationSelector = New Controls.ReconcilorLocationSelector()


        Private _locationId As Integer?
        Private _productId As Integer?
        Private _startDate As DateTime? = Nothing
        Private _endDate As DateTime? = Nothing
        Private _dateBreakdown As String
        Private _productTypeCode As String
        Private _approvalSelection As String
        Private _includeLumpFines As Boolean
        Private _includeSublocations As Boolean
        Private _includeResourceClassifications As Boolean

        Private _breakdownSelect As SelectBox = Nothing

        Public Property DalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility

        Public Property LowestLocationTypeDescription() As String
            Get
                Return _lowestLocationTypeDescription
            End Get
            Set(ByVal value As String)
                _lowestLocationTypeDescription = value
            End Set
        End Property

        Public Property DisplayDateBreakDown() As Boolean
            Get
                Return _displayDateBreakDown
            End Get
            Set(ByVal value As Boolean)
                _displayDateBreakDown = value
            End Set
        End Property

        Public Property DisplayApprovalStatus() As Boolean
            Get
                Return _displayApprovalStatus
            End Get
            Set(ByVal value As Boolean)
                _displayApprovalStatus = value
            End Set
        End Property

        Public Property DisplayLumpFines() As Boolean
            Get
                Return _displayLumpFines
            End Get
            Set(ByVal value As Boolean)
                _displayLumpFines = value
            End Set
        End Property
        Public Property DisplayProductPicker() As Boolean
            Get
                Return _displayProductPicker
            End Get
            Set(ByVal value As Boolean)
                _displayProductPicker = value
            End Set
        End Property

        Public Property DisplayIncludeResourceClassifications() As Boolean
            Get
                Return _displayIncludeResourceClassifications
            End Get
            Set(ByVal value As Boolean)
                _displayIncludeResourceClassifications = value
            End Set
        End Property

        Public Property DisplayIncludeSublocations() As Boolean
            Get
                Return _displayIncludeSublocations
            End Get
            Set(ByVal value As Boolean)
                _displayIncludeSublocations = value
            End Set
        End Property

        Public Property GroupBoxTitle() As String
            Get
                Return _groupBoxTitle
            End Get
            Set(ByVal value As String)
                _groupBoxTitle = value
            End Set
        End Property

        Public WriteOnly Property SubmitAction() As String
            Set(ByVal value As String)
                ServerForm.Action = value
            End Set
        End Property

        Public WriteOnly Property SubmitClientAction() As String
            Set(ByVal value As String)
                ServerForm.OnSubmit = value
            End Set
        End Property

        Public Property LocationId() As Integer?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Integer?)
                _locationId = value
            End Set
        End Property
        Public Property ProductTypeId() As Integer?
            Get
                Return _productId
            End Get
            Set(ByVal value As Integer?)
                _productId = value
            End Set
        End Property

        Public Property StartDate() As DateTime?
            Get
                Return _startDate
            End Get
            Set(ByVal value As DateTime?)
                _startDate = value
            End Set
        End Property

        Public Property EndDate() As DateTime?
            Get
                Return _endDate
            End Get
            Set(ByVal value As DateTime?)
                _endDate = value
            End Set
        End Property

        Public Property DateBreakdown() As String
            Get
                Return _dateBreakdown
            End Get
            Set(ByVal value As String)
                _dateBreakdown = value
            End Set
        End Property
        Public Property ProductTypeCode() As String
            Get
                Return _productTypeCode
            End Get
            Set(ByVal value As String)
                _productTypeCode = value
            End Set
        End Property

        Public Property ApprovalSelection() As String
            Get
                Return _approvalSelection
            End Get
            Set(ByVal value As String)
                _approvalSelection = value
            End Set
        End Property

        Public Property IncludeLumpFines() As Boolean
            Get
                Return _includeLumpFines
            End Get
            Set(ByVal value As Boolean)
                _includeLumpFines = value
            End Set
        End Property

        Public Property IncludeSublocations() As Boolean
            Get
                Return _includeSublocations
            End Get
            Set(ByVal value As Boolean)
                _includeSublocations = value
            End Set
        End Property

        Public Property IncludeResourceClassifications() As Boolean
            Get
                Return _includeResourceClassifications
            End Get
            Set(value As Boolean)
                _includeResourceClassifications = value
            End Set
        End Property

        Public Property DisplayUseForwardEstimates As Boolean = True
        Public Property UseForwardEstimates As Boolean = False

#End Region

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            With ServerForm
                .ID = "DataExportFilterForm"
                .Method = "POST"
            End With

            If DisplayProductPicker Then
                Me.SetupProductAndMonthFilterControls()
            Else
                Me.SetupLocationAndMonthFilterControls()
            End If

            If DisplayDateBreakDown Then
                Me.SetupDateBreakdownPicker()

                If Not _breakdownSelect Is Nothing Then
                    _startDateFilter.DateBreakdown = _breakdownSelect.SelectedValue
                    _endDateFilter.DateBreakdown = _breakdownSelect.SelectedValue
                End If
            End If

            If DisplayApprovalStatus Then
                Me.SetupReportApprovalContextPicker()
            End If

            If DisplayLumpFines Then
                Dim lumpFine = New CheckBox()
                lumpFine.ID = "lumpsFinesBreakdown"
                lumpFine.Checked = Me.IncludeLumpFines
                Me.AddTableRow("Display Lump/Fines:", lumpFine)
            End If

            If DisplayIncludeSublocations Then
                Dim sublocations = New CheckBox()
                sublocations.ID = "includeSublocations"
                sublocations.Checked = Me.IncludeSublocations
                Me.AddTableRow("Include Sublocations:", sublocations)
            End If

            If DisplayIncludeResourceClassifications Then
                Dim resourceClassifications = New CheckBox()
                resourceClassifications.ID = "includeResourceClassifications"
                resourceClassifications.Checked = Me.IncludeResourceClassifications
                Me.AddTableRow("Include Resource Classifications:", resourceClassifications)
            End If

            If DisplayUseForwardEstimates Then
                Dim forwardEstimates = New CheckBox()
                forwardEstimates.ID = "useForwardEstimates"
                forwardEstimates.Checked = Me.UseForwardEstimates
                Me.AddTableRow("Use Forward Estimates:", forwardEstimates)
            End If

            LayoutGroupBox.Title = GroupBoxTitle
            FilterButton.Text = " Generate "

        End Sub

        Protected Overrides Sub CompleteLayout()
            MyBase.CompleteLayout()

            If Not _breakdownSelect Is Nothing Then
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "DateHelpers.onDateChange('Start');DateHelpers.onDateChange('End');"))
            End If
        End Sub

        Private Sub SetupLocationAndMonthFilterControls()

            If Not String.IsNullOrEmpty(Me.LowestLocationTypeDescription) Then
                _locationSelect.LowestLocationTypeDescription = Me.LowestLocationTypeDescription
            End If
            If Not LocationId Is Nothing Then
                _locationSelect.LocationId = LocationId
            End If
            Me.AddTableRow(Nothing, _locationSelect)

            SetupMonthFilterControls()
        End Sub
        Private Sub SetupProductAndMonthFilterControls()
            ' Used in the Reconciliation Product Data Export Screen
            Dim _productTypeSelect As New ProductPicker(DalUtility)

            If Not String.IsNullOrEmpty(Me.ProductTypeCode) Then
                _productTypeSelect.SelectedValue = Me.ProductTypeCode
            End If

            Me.AddTableRow("Product:", _productTypeSelect)

            SetupMonthFilterControls()
        End Sub

        Private Sub SetupMonthFilterControls()
            _startDateFilter = New MonthQuarterFilter()
            If _startDate Is Nothing Then
                _startDateFilter.SelectedDate = DateTime.Now
            Else
                _startDateFilter.SelectedDate = _startDate
            End If
            _startDateFilter.Index = "Start" ' control's Index
            ' link up location and start date pickers to make location control date sensitive (for locations that change with time)
            _startDateFilter.OnSelectChangeCallback = "CheckMonthLocationReport();" ' JavaScript event handler for changing month/quarter
            _locationSelect.StartDate = _startDateFilter.SelectedDate
            _locationSelect.StartDateElementName = _startDateFilter.GetStartDateElements() ' JavaScript "magic" (i.e. spaghetti code): without these the JavaScript event handlers won't work
            _locationSelect.StartQuarterElementName = _startDateFilter.GetStartQuarterElements() ' Essentially it is the hard-coded IDs of month/quarter and year drop-downs prefixed with Index, which is "Start" for this control

            _endDateFilter = New MonthQuarterFilter()
            _endDateFilter.Index = "End"
            If _endDate Is Nothing Then
                _endDateFilter.SelectedDate = DateTime.Now
            Else
                _endDateFilter.SelectedDate = _endDate
            End If

            Me.AddTableRow("Date From:", _startDateFilter)
            Me.AddTableRow("Date To:", _endDateFilter)
        End Sub

        Private Sub SetupDateBreakdownPicker()
            Dim breakdownSelect = New SelectBox()
            breakdownSelect.ID = "dateBreakdown"
            breakdownSelect.Items.Add(New ListItem("Monthly", MonthlyBreakdown))
            breakdownSelect.Items.Add(New ListItem("Quarterly", QuarterlyBreakdown))

            breakdownSelect.OnSelectChange = "DateHelpers.onDateBreakdownChange();"

            If Not String.IsNullOrEmpty(Me.DateBreakdown) Then
                breakdownSelect.SelectedValue = Me.DateBreakdown
            End If

            Me.AddTableRow("Date Breakdown:", breakdownSelect)
            _breakdownSelect = breakdownSelect

        End Sub

        Private Sub SetupReportApprovalContextPicker()
            Dim approvalSelect = New SelectBox()
            approvalSelect.ID = "reportApprovalContext"
            approvalSelect.Items.Add(New ListItem("Approved", Approved))
            approvalSelect.Items.Add(New ListItem("Live", Live))
            approvalSelect.Items.Add(New ListItem("Combined", CombinedApprovedLive))
            If Not String.IsNullOrEmpty(Me.ApprovalSelection) Then
                approvalSelect.SelectedValue = Me.ApprovalSelection
            End If
            Me.AddTableRow("Approval Status:", approvalSelect)
        End Sub

        Private Sub AddTableRow(ByVal label As String, ByVal control As Control)
            Dim row = New TableRow()
            Dim labelCell = New TableCell()
            Dim controlCell = New TableCell()

            If Not label Is Nothing Then
                labelCell.Text = label
            End If
            controlCell.Controls.Add(control)

            If Not label Is Nothing Then
                row.Cells.Add(labelCell)
            End If
            row.Cells.Add(controlCell)
            LayoutTable.Rows.Add(row)
        End Sub
    End Class
End Namespace
