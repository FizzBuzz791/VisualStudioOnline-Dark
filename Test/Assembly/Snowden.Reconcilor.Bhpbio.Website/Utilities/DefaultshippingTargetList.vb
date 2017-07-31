Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls

Imports Snowden.Reconcilor.Bhpbio.Report.GenericDataTableExtensions

Namespace Utilities
    Public Class DefaultshippingTargetList
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _dalUtility As IUtility
        Private _dalShippingTarget As IShippingTarget
        Private _returnTable As ReconcilorTable
        Private _locationId As Int32? = Nothing
        Private _locationTypeId As Int32? = Nothing
        Private _submitRefresh As New InputButton
        Private _editForm As New HtmlFormTag
        Private _layoutTable As New HtmlTableTag
        Private _layoutBox As New GroupBox
        'Private _addButton As New InputButtonFormless
        Private _selectedMonth As DateTime = DateTime.Today
        Private _productType As Integer = 0
        Private _gridmonth As New InputHidden
        Private _showactives As Boolean = False

        Private Const _defaultNumericFormat As String = "N2"

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property
        Protected Property ShowActives() As Boolean
            Get
                Return _showactives
            End Get
            Set(ByVal value As Boolean)
                _showactives = value
            End Set
        End Property
        Protected Property GridMonth() As InputHidden
            Get
                Return _gridmonth
            End Get
            Set(ByVal value As InputHidden)
                _gridmonth = value
            End Set
        End Property
        Protected Property DalShippingTarget() As IShippingTarget
            Get
                Return _dalShippingTarget
            End Get
            Set(ByVal value As IShippingTarget)
                _dalShippingTarget = value
            End Set
        End Property

        Protected Property ReturnTable() As ReconcilorTable
            Get
                Return _returnTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _returnTable = value
            End Set
        End Property
        Public Property EditForm() As HtmlFormTag
            Get
                Return _editForm
            End Get
            Set(ByVal value As HtmlFormTag)
                If (Not value Is Nothing) Then
                    _editForm = value
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

        Public Property SubmitRefresh() As InputButton
            Get
                Return _submitRefresh
            End Get
            Set(ByVal value As InputButton)
                If (Not value Is Nothing) Then
                    _submitRefresh = value
                End If
            End Set
        End Property
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                SetupFormControls()
                Controls.Add(EditForm)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Function GetData() As DataTable

            Dim dataTable As DataTable = Nothing

            If ShowActives Then
                dataTable = DalShippingTarget.GetBhpbioShippingTargets(_productType, _selectedMonth)
            Else
                dataTable = DalShippingTarget.GetBhpbioShippingTargets(_productType, NullValues.DateTime)
            End If

            Return dataTable
        End Function

        Protected Overridable Sub SetupFormControls()
            Dim dropdown As SelectBox
            Dim month = New MonthFilter()
            Dim rowIndex, cellIndex As Integer
            Dim grades = New DataTable
            Dim checkbox = New CheckBox()

            SubmitRefresh.ID = "DefaultShippingTargetSubmit"
            SubmitRefresh.Text = " Refresh "
            EditForm.ID = "DefaultShippingTargetsForm"
            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'itemList', './DefaultShippingTargetList.aspx',false, CleanShippingTargetDetail());"
            checkbox.ID = "chkActiveTargets"

            GridMonth.ID = "GridMonth"
            GridMonth.Value = _selectedMonth.ToString("MM-dd-yyyy HH:mm:ss")

            With LayoutTable
                .ID = "DefautlShippingTargetLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                'Product filter
                dropdown = New ProductPicker(DalUtility, True)



                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)

                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Product:"))

                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(dropdown)

                    Dim filterCell As New TableCell
                    filterCell.ColumnSpan = 2
                    cellIndex = .Cells.Add(filterCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl())
                End With

                'Date filter
                EditForm.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(checkbox)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Only show targets active in:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(month)
                End With
                EditForm.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                'Refresh Button
                EditForm.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                rowIndex = .Rows.Add(New TableRow)

                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell())
                    .Cells(cellIndex).Controls.Add(SubmitRefresh)
                End With

            End With

            With LayoutBox
                .Title = "Filter"
                .Width = Unit.Percentage(100)
                .Controls.Add(LayoutTable)
            End With

            With EditForm
                .Controls.Add(LayoutBox)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
            End With
            
            dropdown.SelectedValue = _productType.ToString()
            checkbox.Checked = ShowActives
            month.SelectedDate = _selectedMonth

            Dim dataTable = GetData()

            'Clones datatable and Replaces the 0 (from database decimal field) value for the "n/a" string
            Dim displayTable As DataTable = dataTable.Clone()
            Dim canEdit = Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_EDIT")

            Dim stringColumns = New String() {"Attribute_Neg1", "Attribute_Neg2", "Attribute_5"}

            For Each columnId In stringColumns
                displayTable.Columns(columnId).DataType = GetType(String)
            Next

            displayTable.Load(dataTable.CreateDataReader())

            If canEdit Then
                With displayTable.Columns
                    .Add(New DataColumn("Copy"))
                    .Add(New DataColumn("Edit"))
                    .Add(New DataColumn("Delete"))
                End With

                For Each dr As DataRow In displayTable.Rows
                    Dim rowHasControls = dr("ValueType").ToString() = "Upper Control"

                    If rowHasControls Then
                        Dim isoDateFormat = "yyyy-MM-dd HH:mm:ss"
                        Dim productTypeId = Convert.ToInt32(dr("ProductTypeId"))
                        Dim dateFrom = Date.Parse(dr("EffectiveFromDateTime").ToString()).ToString(isoDateFormat)

                        dr("Copy") = String.Format("<a href=""#"" onclick=""EditShippingTargetGrid({0}, '{1}', true)"">Copy</a>", productTypeId, dateFrom)
                        dr("Edit") = String.Format("<a href=""#"" onclick=""EditShippingTargetGrid({0}, '{1}')"">Edit</a>", productTypeId, dateFrom)
                        dr("Delete") = String.Format("<a href=""#"" onclick=""DeleteShippingTarget({0})"">Delete</a>", dr("ShippingTargetPeriodId").ToString())
                    End If
                Next
            End If

            For Each dr As DataRow In displayTable.Rows

                If dr("ValueType").ToString() = "Lower Control" Then
                    dr("Attribute_Neg1") = "n/a"
                    dr("Attribute_Neg2") = "n/a"
                End If

				If Not dr("ValueType").ToString() = "Upper Control" Then
                    dr("ProductTypeCode") = ""
                End If

                ' for H2O the value is only valid for the target, not the upper and lower controls
                If dr("ValueType").ToString.ToUpper <> "TARGET" Then
                    dr("Attribute_5") = "n/a"
                End If

                ' if the value of these columns if *not* n/a, then we need to do the
                ' number formatting manually, since the ReconcilorTable can't handle it
                ' properly when the dataType is string
                For Each columnId In stringColumns
                    Dim value = dr(columnId).ToString
                    If Not String.IsNullOrEmpty(value) AndAlso value <> "n/a" Then
                        dr(columnId) = String.Format("{0:N2}", Convert.ToDouble(value))
                    End If
                Next

            Next

            ' Dynamic populated grid to match existing Grades
            Dim dateFormat As String = "dd-MMM-yyyy"
            If Not Application("DateFormat") Is Nothing Then
                dateFormat = Application("DateFormat").ToString
            End If
            grades = DalUtility.GetGradeList(1)
            'ReturnTable = New ReconcilorTable(dataTable)
            ReturnTable = New ReconcilorTable(displayTable)

            Dim usecolumns = New List(Of String)

            usecolumns.Add("ProductTypeCode")
            usecolumns.Add("EffectiveFromDateTime")
            usecolumns.Add("EffectiveToDateTime")
            usecolumns.Add("ValueType")

            Dim precisiondt As DataTable = DalUtility.GetBhpbioAttributeProperties()
            For Each dr As DataRow In grades.Rows
                Dim columnText = dr("grade_name").ToString()
                Dim columnId As String = "Attribute_" + dr("grade_id").ToString()
                Dim column = New ReconcilorTableColumn(columnText)
                Dim numericprecision As String = _defaultNumericFormat

                If precisiondt IsNot Nothing Then
                    Dim attributeRow = precisiondt.AsEnumerable.FirstOrDefault(Function(r) r.AsString("AttributeName") = columnText)

                    If attributeRow IsNot Nothing Then
                        numericprecision = "N" & attributeRow.AsString("DisplayPrecision")
                    End If

                End If

                column.NumericFormat = numericprecision
                ReturnTable.Columns.Add(columnId, column)
                usecolumns.Add(columnId)
            Next

            usecolumns.Add("Attribute_Neg1")
            usecolumns.Add("Attribute_Neg2")
            usecolumns.Add("Copy")
            usecolumns.Add("Edit")
            usecolumns.Add("Delete")

            With ReturnTable
                .Columns.Add("ProductTypeCode", New ReconcilorTableColumn("Product"))
                .Columns.Add("EffectiveFromDateTime", New ReconcilorTableColumn("Effective From"))
                .Columns.Add("EffectiveToDateTime", New ReconcilorTableColumn("Effective To"))
                .Columns.Add("ValueType", New ReconcilorTableColumn(""))
                .Columns.Add("Attribute_Neg1", New ReconcilorTableColumn("Oversize"))
                .Columns.Add("Attribute_Neg2", New ReconcilorTableColumn("Undersize"))

                .Columns("EffectiveFromDateTime").DateTimeFormat = dateFormat
                .Columns("EffectiveToDateTime").DateTimeFormat = dateFormat
                .Columns("Attribute_Neg1").NumericFormat = _defaultNumericFormat
                .Columns("Attribute_Neg2").NumericFormat = _defaultNumericFormat
                .UseColumns = usecolumns.ToArray
                .ID = "ReturnTable"
                .DataBind()
            End With

            EditForm.Controls.Add(ReturnTable)
            EditForm.Controls.Add(GridMonth)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If

            If _dalShippingTarget Is Nothing Then
                _dalShippingTarget = New SqlDalShippingTarget(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Request("MonthPickerMonthPart") IsNot Nothing Then
                If DateTime.TryParse(Request("MonthPickerMonthPart").ToString() + "-01-" + Request("MonthPickerYearPart").ToString(), _selectedMonth) Then
                    _selectedMonth = Date.Parse("01-" + Request("MonthPickerMonthPart").ToString() + "-" + Request("MonthPickerYearPart").ToString())
                    Resources.UserSecurity.SetSetting("Shipping_Targets_Filter_Date", _selectedMonth.ToString("yyyy-MM-dd HH:mm:ss"))
                End If
            Else
                If Not Date.TryParse(Resources.UserSecurity.GetSetting("Shipping_Targets_Filter_Date"), _selectedMonth) Then
                    _selectedMonth = Date.Today
                End If
            End If

            If Not String.IsNullOrEmpty(Request("productTypeCode")) Then
                _productType = RequestAsInt32("productTypeCode")
                Resources.UserSecurity.SetSetting("ProductTypeId", _productType.ToString)
            Else
                If Not Integer.TryParse(Resources.UserSecurity.GetSetting("ProductTypeId"), _productType) Then
                    _productType = -1
                End If
            End If

            If Not Request("chkActiveTargets") = Nothing Then
                ShowActives = True
            End If

        End Sub
    End Class
End Namespace

