Imports System.Text
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility
Namespace Analysis

    Public Class OutlierAnalysisFilter
        Inherits Core.WebDevelopment.WebpageTemplates.AnalysisAjaxTemplate

#Region "Properties"

        Private _analysisGroup As New SelectBox
        Private _productTypeProductSize As New SelectBox
        Private _locationSelector As New WebDevelopment.Controls.ReconcilorLocationSelector
        Private _layoutTable As New HtmlTableTag
        Private _layoutBox As New GroupBox
        Private _outlierForm As New HtmlFormTag
        Private _submit As New InputButton
        Private _cancel As New InputButton
        Private _deviations As New SelectBox
        Private _attributeRadio As New Generic.Dictionary(Of Int16, InputRadio)
        Private _dalUtility As IUtility
        Private _startDate As DateTime? = Nothing
        Private _endDate As DateTime? = Nothing
        Private _startDateFilter As MonthFilter = New MonthFilter()
        Private _endDateFilter As MonthQuarterFilter = New MonthQuarterFilter()
        Public Property OutlierForm() As HtmlFormTag
            Get
                Return _outlierForm
            End Get
            Set(ByVal value As HtmlFormTag)
                If (Not value Is Nothing) Then
                    _outlierForm = value
                End If
            End Set
        End Property

        Public Property LayoutBox() As GroupBox
            Get
                Return _layoutBox
            End Get
            Set(ByVal value As GroupBox)
                If (Not value Is Nothing) Then
                    _layoutBox = value
                End If
            End Set
        End Property

        Public Property LayoutTable() As HtmlTableTag
            Get
                Return _layoutTable
            End Get
            Set(ByVal value As HtmlTableTag)
                If (Not value Is Nothing) Then
                    _layoutTable = value
                End If
            End Set
        End Property

        Public Property Submit() As InputButton
            Get
                Return _submit
            End Get
            Set(ByVal value As InputButton)
                If (Not value Is Nothing) Then
                    _submit = value
                End If
            End Set
        End Property

        Public Property Cancel() As InputButton
            Get
                Return _cancel
            End Get
            Set(ByVal value As InputButton)
                _cancel = value
            End Set
        End Property
        Protected ReadOnly Property LocationSelector() As WebDevelopment.Controls.ReconcilorLocationSelector
            Get
                Return _locationSelector
            End Get
        End Property
        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property
#End Region
        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SetupFormControls()

            If Not String.IsNullOrEmpty(RequestAsString("AnalysisGroup")) Then
                _startDate = RequestAsDateTime("MonthStart")
                _endDate = RequestAsDateTime("MonthEnd")

                _analysisGroup.SelectedValue = RequestAsString("AnalysisGroup")
                _startDateFilter.SelectedDate = _startDate
                _endDateFilter.SelectedDate = _endDate
                _productTypeProductSize.SelectedValue = RequestAsString("ProductSize")
                LocationSelector.LocationId = RequestAsInt32("Locationid")
            Else
                Dim locationId As Integer
                If Integer.TryParse(Resources.UserSecurity.GetSetting("AnalysisOutlier_LocationId"), locationId) Then
                    LocationSelector.LocationId = locationId
                End If

                If Resources.UserSecurity.GetSetting("AnalysisOutlier_AnalysisGroup") <> "" Then
                    _analysisGroup.SelectedValue = Resources.UserSecurity.GetSetting("AnalysisOutlier_AnalysisGroup").ToString()
                End If

                Dim startDate As DateTime
                If DateTime.TryParse(Resources.UserSecurity.GetSetting("AnalysisOutlier_MonthValueStart"), startDate) Then
                    _startDate = startDate
                End If

                Dim endDate As DateTime
                If DateTime.TryParse(Resources.UserSecurity.GetSetting("AnalysisOutlier_MonthValueEnd"), endDate) Then
                    _endDate = endDate
                End If

                If Resources.UserSecurity.GetSetting("AnalysisOutlier_productTypeProductSize") <> "" Then
                    _productTypeProductSize.SelectedValue = Resources.UserSecurity.GetSetting("AnalysisOutlier_productTypeProductSize").ToString()
                End If

                If Resources.UserSecurity.GetSetting("AnalysisOutlier_deviations") <> "" Then
                    _deviations.SelectedValue = Resources.UserSecurity.GetSetting("AnalysisOutlier_deviations").ToString()
                End If

                If Resources.UserSecurity.GetSetting("AnalysisOutlier_AttributeFilter") <> "" Then
                    Dim value = Resources.UserSecurity.GetSetting("AnalysisOutlier_AttributeFilter").ToString()
                    For Each attributeSelector In _attributeRadio.Values
                        attributeSelector.Checked = (attributeSelector.Value = value)
                    Next
                End If
            End If

            If _startDate Is Nothing Then
                _startDate = New Date(Date.Now.Year, Date.Now.Month, 1)
            End If

            If _endDate Is Nothing Then
                _endDate = _startDate
            End If

            If _startDate IsNot Nothing Then
                _startDateFilter.SelectedDate = _startDate
                LocationSelector.StartDate = _startDate
            End If

            If _endDate IsNot Nothing Then
                _endDateFilter.SelectedDate = _endDate
            End If

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                ' SetupFormControls()
                Controls.Add(OutlierForm)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex, cellIndex As Integer
            Submit.ID = "OutlierAnalysisSubmit"
            Submit.Text = " Filter "

            Cancel.ID = "CancelSubmit"
            Cancel.Text = " Reset Filters "
            Cancel.OnClientClick = String.Format("return ClearOutlierAnalysisFilter({0}, '{1}')", LocationSelector.LocationLabelCellWidth, LocationSelector.LocationDiv.ID)

            LocationSelector.ID = "location"
            LocationSelector.LowestLocationTypeDescription = "PIT"

            _analysisGroup.ID = "AnalysisGroup"
            _productTypeProductSize.ID = "ProductSize"
            SetupAnalysisGroup()
            LayoutTable.AddCellInNewRow.Controls.Add(LocationSelector)
            SetupMonthFilterControls()
            SetupProductSize()
            SetupAttribute()
            SetupDeviations()
            With LayoutTable
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Only include outliers that differ by at least "))
                    .Cells(cellIndex).Controls.Add(_deviations)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(" standard deviations"))
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex) 'Submit
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(Cancel)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    .Cells(cellIndex).Controls.Add(Submit)
                    .Cells(cellIndex).HorizontalAlign = HorizontalAlign.Right
                End With
            End With

            With LayoutBox
                .Title = "Filter"
                .Width = Unit.Percentage(100)
                .Controls.Add(LayoutTable)
                .Controls.Add(New LiteralControl("</br>"))
            End With
            With OutlierForm
                .ID = "outlierForm"
                .Controls.Add(LayoutBox)
                .OnSubmit = "return GetOutlierAnalysisGrid();"

            End With

            OutlierForm.Controls.Add(LayoutBox)
        End Sub
        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        ' note: I don't think this code is actually ever called, as the validation seems to be done 
        ' totally on the client side, however I don't want to remove it, because it might get trigger 
        ' in strange circumstances - for example when the page is linked to from the approval page
        Protected Overrides Function ValidateData() As String
            Dim retStr As New StringBuilder(MyBase.ValidateData())

            If (_startDate > _endDate) Then
                retStr.Append(" - The start date is greater than the end date.\n")
            End If

            If (_startDate > Date.Now) Then
                retStr.Append(" - The start date is greater than the current date.\n")
            End If

            If (_endDate > Date.Now) Then
                retStr.Append(" - The end date is greater than the current date.\n")
            End If

            Return retStr.ToString
        End Function

        Private Sub SetupAnalysisGroup()
            Dim dt As DataTable = OutlierHelper.GetAnalysisGroups(Resources.ConnectionString)
            With _analysisGroup
                .ID = "AnalysisGroup"
                .DataSource = dt
                .DataValueField = "Id"
                .DataTextField = "Name"
                .DataBind()
                .Items.Insert(0, New ListItem(Nothing, "All"))
            End With
            Me.AddTableRow("Analysis Group:", _analysisGroup)

        End Sub

        Private Sub SetupDeviations()
            With _deviations
                .ID = "deviations"
                For int As Double = 10 To 0 Step -0.5
                    .Items.Insert(0, New ListItem(int.ToString("N1"), int.ToString()))
                Next
            End With
        End Sub
        Private Sub SetupProductSize()
            With _productTypeProductSize
                .ID = "productTypeProductSize"
                .Items.Insert(0, New ListItem("ALL", "All"))
                .Items.Insert(1, New ListItem("TOTAL", "TOTAL"))
                .Items.Insert(2, New ListItem("LUMP", "LUMP"))
                .Items.Insert(3, New ListItem("FINES", "FINES"))
            End With

            Me.AddTableRow("Product Size:", _productTypeProductSize)
        End Sub

        Private Sub SetupAttribute()
            CreateAttributes()
            Dim attributeSelector As InputRadio
            Dim row = New WebControls.TableRow()
            Dim cell As WebControls.TableCell
            Dim counter As Integer
            cell = New WebControls.TableCell()
            cell.Controls.Add(New LiteralControl("Attribute: "))
            row.Cells.Add(cell)
            counter = 0
            For Each attributeSelector In _attributeRadio.Values
                If counter > 0 Then
                    cell = New TableCell()
                    cell.Controls.Add(New LiteralControl("&nbsp;"))
                    row.Cells.Add(cell)
                End If

                cell = New WebControls.TableCell()
                cell.Controls.Add(attributeSelector)
                row.Cells.Add(cell)
                counter += 1
                If counter Mod 5 = 0 Then
                    LayoutTable.Rows.Add(row)
                    row = New WebControls.TableRow()
                End If
            Next
            If counter Mod 5 > 0 Then
                LayoutTable.Rows.Add(row)
            End If
        End Sub
        Private Sub CreateAttributes()
            Dim gradeData As DataTable
            Dim attributeSelector As InputRadio

            attributeSelector = New InputRadio()
            attributeSelector.ID = "All"
            attributeSelector.GroupName = "AttributeFilter"
            attributeSelector.Value = "All"
            attributeSelector.Text = "All"
            attributeSelector.Checked = True
            _attributeRadio.Add(99, attributeSelector)

            attributeSelector = New InputRadio()
            attributeSelector.ID = "Tonnes"
            attributeSelector.GroupName = "AttributeFilter"
            attributeSelector.Value = "Tonnes"
            attributeSelector.Text = "Tonnes"
            _attributeRadio.Add(98, attributeSelector)

            attributeSelector = New InputRadio()
            attributeSelector.ID = "Density"
            attributeSelector.GroupName = "AttributeFilter"
            attributeSelector.Value = "Density"
            attributeSelector.Text = "Density"
            _attributeRadio.Add(97, attributeSelector)

            'add the attributes: grades
            gradeData = DalUtility.GetGradeList(Convert.ToInt16(True))
            For Each gradeRow As DataRow In gradeData.Select("", "Order_No")
                ' Create the Input Radio Button
                attributeSelector = New InputRadio()
                attributeSelector.ID = gradeRow("Grade_Name").ToString
                attributeSelector.GroupName = "AttributeFilter"
                attributeSelector.Value = gradeRow("Grade_Name").ToString
                attributeSelector.Text = gradeRow("Grade_Name").ToString
                _attributeRadio.Add(DirectCast(gradeRow("Grade_Id"), Int16), attributeSelector)
            Next

            attributeSelector = New InputRadio()
            attributeSelector.ID = "Ultrafines"
            attributeSelector.GroupName = "AttributeFilter"
            attributeSelector.Value = "Ultrafines"
            attributeSelector.Text = "Ultrafines-in-fines"
            _attributeRadio.Add(10, attributeSelector)
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

        Private Sub SetupMonthFilterControls()
            _startDateFilter.Index = "Start"
            _startDateFilter.OnSelectChangeCallback = "CheckMonthLocationPartStart();"
            LocationSelector.StartDateElementName = _startDateFilter.GetStartDateElements()

            _endDateFilter.Index = "End"
            Me.AddTableRow("Date From:", _startDateFilter)
            Me.AddTableRow("Date To:", _endDateFilter)
        End Sub
    End Class

End Namespace
