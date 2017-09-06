Imports System.Drawing
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions


Namespace Utilities

    Public Class DefaultshippingTargetEdit
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"

        Private _isNew As Boolean = True
        Private _shippingTargetPeriodId As New InputHidden
        Private _gridmonth As New InputHidden
        Private _defaultProductType As New InputHidden
        Private _attribute_ As New InputText
        Private _attribute_Neg1 As New InputText
        Private _attribute_Neg2 As New InputText
        Private _dalShippingTarget As IShippingTarget
        Private _productTypeDescriptionBox As New InputText
        Private _productTypeProductSize As New SelectBox
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _editForm As New HtmlFormTag
        Private _layoutBox As New GroupBox
        Private _layoutTable As New HtmlTableTag
        Private _productTable As New HtmlTableTag
        Private _submitEdit As New InputButton
        Private _cancelEdit As New InputButton
        Private _returnTable As ReconcilorTable
        Private _grades As DataTable = Nothing

        ' parameters
        Private _productTypeId As Integer = -1
        Private _shippingTargetDate As Date = Nothing
        Private _isCopy As Boolean = False

        Protected Property IsNew() As Boolean
            Get
                Return _isNew
            End Get
            Set(ByVal value As Boolean)
                _isNew = value
            End Set
        End Property

        Protected Property ShippingTargetPeriodId() As InputHidden
            Get
                Return _shippingTargetPeriodId
            End Get
            Set(ByVal value As InputHidden)
                _shippingTargetPeriodId = value
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
        Protected Property ProductType() As InputHidden
            Get
                Return _defaultProductType
            End Get
            Set(ByVal value As InputHidden)
                _defaultProductType = value
            End Set
        End Property
        Protected Property Attribute_Neg1() As InputText
            Get
                Return _attribute_Neg1
            End Get
            Set(ByVal value As InputText)
                _attribute_Neg1 = value
            End Set
        End Property
        Protected Property Attribute_Neg2() As InputText
            Get
                Return _attribute_Neg2
            End Get
            Set(ByVal value As InputText)
                _attribute_Neg2 = value
            End Set
        End Property
        Protected Property Attribute_() As InputText
            Get
                Return _attribute_
            End Get
            Set(ByVal value As InputText)
                _attribute_ = value
            End Set
        End Property

        Protected Property DescriptionBox() As InputText
            Get
                Return _productTypeDescriptionBox
            End Get
            Set(ByVal value As InputText)
                _productTypeDescriptionBox = value
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

        Protected Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
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
        Public Property ProductTable() As HtmlTableTag
            Get
                Return _productTable
            End Get
            Set(ByVal value As HtmlTableTag)
                If (Not value Is Nothing) Then
                    _productTable = value
                End If
            End Set
        End Property

        Public Property SubmitEdit() As InputButton
            Get
                Return _submitEdit
            End Get
            Set(ByVal value As InputButton)
                If (Not value Is Nothing) Then
                    _submitEdit = value
                End If
            End Set
        End Property

        Public Property CancelEdit() As InputButton
            Get
                Return _cancelEdit
            End Get
            Set(ByVal value As InputButton)
                _cancelEdit = value
            End Set
        End Property

#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not String.IsNullOrEmpty(Request("ShippingTargetPeriodId")) Then
                Dim periodId = RequestAsInt32("ShippingTargetPeriodId")
                ShippingTargetPeriodId.Value = periodId.ToString
                IsNew = (periodId = 0)
            End If

            If Not String.IsNullOrEmpty(Request("ProductTypeId")) Then
                _productTypeId = RequestAsInt32("ProductTypeId")
                ProductType.Value = _productTypeId.ToString
                IsNew = False
            End If

            If Not String.IsNullOrEmpty(Request("ShippingTargetDate")) Then
                ' parse and then convert back to a string to make sure its in the right format
                _shippingTargetDate = RequestAsDateTime("ShippingTargetDate")
                GridMonth.Value = _shippingTargetDate.ToString("MM-dd-yyyy HH:mm:ss")
                IsNew = False
            End If

            If Not String.IsNullOrEmpty(Request("ShouldCopy")) Then
                _isCopy = (RequestAsInt32("ShouldCopy") = 1)
            End If

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                SetupFormControls()
                Controls.Add(EditForm)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex, cellIndex As Integer
            Dim boxTitle As String = "Shipping Targets"
            Dim recordDataTable = New DataTable()

            Dim dropdown As SelectBox
            Dim month = New MonthFilter()

            Dim litcopy = New LiteralControl

            ProductType.ID = "ProductTypeCode"
            SubmitEdit.ID = "ShippingTargetPeriodSubmit"
            SubmitEdit.Text = " Save "
            CancelEdit.ID = "CancelSubmit"
            CancelEdit.Text = " Cancel "
            CancelEdit.OnClientClick = "return CleanShippingTargetDetail();"
            EditForm.ID = "ShippingTargetPeriodEditForm"
            Attribute_.ID = "Attribute_"
            Attribute_Neg1.ID = "Attribute_Neg1"
            Attribute_Neg2.ID = "Attribute_Neg2"
            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'itemList', './DefaultshippingTargetSave.aspx');"
            ShippingTargetPeriodId.ID = "ShippingTargetPeriodId"
            month.ID = "monthfilter"
            litcopy.ID = "LitCopy"
            EditForm.Controls.Add(litcopy)
            EditForm.Controls.Add(ShippingTargetPeriodId)
            EditForm.Controls.Add(GridMonth)
            dropdown = New ProductPicker(DalUtility, True)
            dropdown.ID = "producttypepicker"
            _grades = DalUtility.GetGradeList(1)
            Dim code = New HtmlInputHidden()

            'Retrieve values from DataBase
            If Not IsNew Then
                recordDataTable = DalShippingTarget.GetBhpbioShippingTargets(_productTypeId, _shippingTargetDate)
                If recordDataTable.Rows.Count > 0 Then
                    dropdown.SelectedValue = recordDataTable.Rows(0).Item("ProductTypeId").ToString
                    month.SelectedDate = _shippingTargetDate
                    boxTitle = "Edit Shipping Targets"
                End If
            Else
                boxTitle = "Add Shipping Targets"
            End If

            With ProductTable
                .ID = "productTableLayout"
                .Width = Unit.Percentage(100)
                .CellSpacing = 3
                'Copying

                If recordDataTable IsNot Nothing And recordDataTable.Rows.Count > 0 Then
                    If _isCopy Then
                        ShippingTargetPeriodId.Value = "-1" 'recordDataTable.Rows(0).Item("ShippingTargetPeriodId").ToString
                        litcopy.Text = "<b>Copying from:</b> " + dropdown.SelectedItem.ToString() + " " + Date.Parse(GridMonth.Value).ToString("dd-MMM-yyy")
                        rowIndex = .Rows.Add(New TableRow)
                        With .Rows(rowIndex)
                            cellIndex = .Cells.Add(New TableCell)
                            .Cells(cellIndex).Controls.Add(litcopy)
                        End With
                    Else 'Editing
                        ShippingTargetPeriodId.Value = recordDataTable.Rows(0).Item("ShippingTargetPeriodId").ToString
                        dropdown.Enabled = False
                    End If
                End If

                'Product Row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<b>Product:</b>"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(dropdown)
                End With

                'Month Row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<b> Effective From: </b>"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(month)

                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<b>Effective To:</b>"))
                    cellIndex = .Cells.Add(New TableCell)
                    If recordDataTable.Rows.Count > 0 Then
                        If Date.TryParse(recordDataTable.Rows(0).Item("EffectiveToDateTime").ToString(), New DateTime()) Then
                            .Cells(cellIndex).Controls.Add(New LiteralControl(Date.Parse(recordDataTable.Rows(0).Item("EffectiveToDateTime").ToString()).ToString("dd-MMM-yyyy")))
                        Else
                            .Cells(cellIndex).Controls.Add(New LiteralControl("Current"))
                        End If
                    End If

                End With
            End With

            With LayoutTable
                .ID = "ShippingTargetLayout"
                .Width = Unit.Percentage(100)
                .CellSpacing = 3

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(ProductTable)

                End With

                'Header Row
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(""))
                    For Each dr As DataRow In _grades.Rows
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("<b>" + dr("grade_name").ToString() + "</b>"))
                        .Cells(cellIndex).HorizontalAlign = HorizontalAlign.Center
                    Next
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<b>Oversize</b>"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<b>Undersize</b>"))
                End With

                ' now we have all the controls and headers set up, create the actual editable rows for each type
                Dim valueTypes = New String() {"Upper Control", "Target", "Lower Control"}
                For Each valueType In valueTypes
                    Dim data = recordDataTable.AsEnumerable.FirstOrDefault(Function(r) r.AsString("ValueType") = valueType)
                    Dim row = CreateEditRow(data, valueType)
                    rowIndex = .Rows.Add(row)
                Next

            End With

            With LayoutBox
                .Title = boxTitle
                .Width = Unit.Percentage(100)
                .Controls.Add(LayoutTable)
                .Controls.Add(SubmitEdit)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(CancelEdit)
            End With

            EditForm.Controls.Add(LayoutBox)
        End Sub

        Private Function CreateEditRow(ByRef row As DataRow, valueType As String) As TableRow
            Dim tableRow = New TableRow
            Dim Oversize = New InputText()
            Dim Undersize = New InputText()
            Dim prefix = valueType.Chars(0).ToString

            tableRow.Cells.Add(CreateCellWithContents(New LiteralControl(valueType)))

            For Each gradeRow As DataRow In _grades.Rows
                Dim gradeName = gradeRow.AsString("Grade_Name")

                If IsCellNA(gradeName, valueType) Then
                    tableRow.Cells.Add(CreateNACell())
                    Continue For
                End If

                Dim Attrib = New InputText()
                Attrib.Width = 50
                Attrib.ID = prefix + "_Attribute_" + gradeRow.AsString("Grade_Id")

                If row IsNot Nothing Then
                    Dim columnName = "Attribute_" + gradeRow.AsString("Grade_Id")
                    Attrib.Text = row.AsString(columnName)
                End If

                tableRow.Cells.Add(CreateCellWithContents(Attrib))
            Next

            If Not IsCellNA("Oversize", valueType) Then
                Oversize.ID = prefix + "_Oversize"
                Oversize.Width = 50
                If row IsNot Nothing Then Oversize.Text = row.AsString("Attribute_Neg1")
                tableRow.Cells.Add(CreateCellWithContents(Oversize))
            Else
                tableRow.Cells.Add(CreateNACell())
            End If

            If Not IsCellNA("Undersize", valueType) Then
                Undersize.ID = prefix + "_Undersize"
                Undersize.Width = 50
                If row IsNot Nothing Then Undersize.Text = row.AsString("Attribute_Neg2")
                tableRow.Cells.Add(CreateCellWithContents(Undersize))
            Else
                tableRow.Cells.Add(CreateNACell())
            End If

            Return tableRow

        End Function

        Private Function IsCellNA(ByVal gradeName As String, ByVal valueType As String) As Boolean
            If gradeName.ToUpper = "LOI" AndAlso valueType.ToUpper <> "TARGET" Then
                Return True
            ElseIf gradeName.ToUpper = "OVERSIZE" AndAlso valueType.ToUpper = "LOWER CONTROL" Then
                Return True
            ElseIf gradeName.ToUpper = "UNDERSIZE" AndAlso valueType.ToUpper = "LOWER CONTROL" Then
                Return True
            Else
                Return False
            End If
        End Function

        Private Function CreateNACell() As TableCell
            Dim cell = CreateCellWithContents(New LiteralControl("n/a"))
            cell.HorizontalAlign = HorizontalAlign.Center
            Return cell
        End Function

        Private Function CreateCellWithContents(contents As Control) As TableCell
            Dim cell = New TableCell
            cell.Controls.Add(contents)
            Return cell
        End Function

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
            If _dalShippingTarget Is Nothing Then
                _dalShippingTarget = New SqlDalShippingTarget(Resources.Connection)
            End If
        End Sub

    End Class

End Namespace
