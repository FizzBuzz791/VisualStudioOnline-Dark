Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs


Namespace Utilities

    Public Class DefaultProductTypeEdit
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"

        Private _isNew As Boolean = True
        Private _defaultProductTypeId As New InputHidden
        Private _defaultProductTypeSize As New InputHidden
        Private _productTypeCodeBox As New InputText
        Private _productTypeDescriptionBox As New InputText
        Private _productTypeProductSize As New SelectBox
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _editForm As New HtmlFormTag
        Private _layoutBox As New GroupBox
        Private _layoutTable As New HtmlTableTag
        Private _submitEdit As New InputButton
        Private _cancelEdit As New InputButton
        Private _returnTable As ReconcilorTable


        Protected Property IsNew() As Boolean
            Get
                Return _isNew
            End Get
            Set(ByVal value As Boolean)
                _isNew = value
            End Set
        End Property

        Protected Property BhpbioDefaultProductTypeId() As InputHidden
            Get
                Return _defaultProductTypeId
            End Get
            Set(ByVal value As InputHidden)
                _defaultProductTypeId = value
            End Set
        End Property
        Protected Property ProductSize() As InputHidden
            Get
                Return _defaultProductTypeSize
            End Get
            Set(ByVal value As InputHidden)
                _defaultProductTypeSize = value
            End Set
        End Property

        Protected Property CodeBox() As InputText
            Get
                Return _productTypeCodeBox
            End Get
            Set(ByVal value As InputText)
                _productTypeCodeBox = value
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

            If Not Request("BhpbioDefaultProductTypeId") Is Nothing Then
                BhpbioDefaultProductTypeId.Value = Request("BhpbioDefaultProductTypeId").Trim
                IsNew = False
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
            Dim title As String = Nothing
            Dim recordDataTable = New DataTable()
            Dim _locations As ArrayList = New ArrayList()
            SubmitEdit.ID = "DefaultProductTypeSubmit"
            SubmitEdit.Text = " Save "

            CancelEdit.ID = "CancelSubmit"
            CancelEdit.Text = " Cancel "
            CancelEdit.OnClientClick = "return CancelEditDefaultProductType();"

            EditForm.ID = "DefaultProductTypeEditForm"
            CodeBox.ID = "CodeBox"
            DescriptionBox.ID = "Description"
            ProductSize.ID = "ProductSize"
            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'itemList', './DefaultProductTypeSave.aspx');"

            BhpbioDefaultProductTypeId.ID = "BhpbioDefaultProductTypeId"
            EditForm.Controls.Add(BhpbioDefaultProductTypeId)
            Dim code = New HtmlInputHidden()


            _productTypeProductSize = New SelectBox()
            With _productTypeProductSize
                .ID = "productTypeProductSize"
                .Items.Insert(0, New ListItem("LUMP", "LUMP"))
                .Items.Insert(1, New ListItem("FINES", "FINES"))
            End With

            If Not IsNew Then
                recordDataTable = DalUtility.GetBhpbioProductTypeLocation(Convert.ToInt32(BhpbioDefaultProductTypeId.Value))
                If recordDataTable.Rows.Count > 0 Then
                    CodeBox.Text = recordDataTable.Rows(0).Item("ProductTypeCode").ToString
                    DescriptionBox.Text = recordDataTable.Rows(0).Item("Description").ToString
                    _productTypeProductSize.SelectedValue = recordDataTable.Rows(0).Item("ProductSize").ToString
                    ProductSize.Value = _productTypeProductSize.SelectedValue
                    For Each row As DataRow In recordDataTable.Rows
                        _locations.Add(row("location_id").ToString())
                    Next
                    title = "Edit Product Types"
                End If
            Else
                title = "Add Product Types"
            End If


            With LayoutTable
                .ID = "DefautlProductTypeLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Code:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(CodeBox)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Description:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(DescriptionBox)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Product Size:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(_productTypeProductSize)
                End With

                ' Implements Hub Select List component
                Dim hubs As New HubSelectList()
                hubs.DalUtility = DalUtility
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Hubs:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(hubs.GetHubSelectList(_locations))
                End With

            End With

            With LayoutBox
                .Title = title
                .Width = Unit.Percentage(100)
                .Controls.Add(LayoutTable)
                .Controls.Add(SubmitEdit)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(CancelEdit)
            End With

            EditForm.Controls.Add(LayoutBox)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

    End Class

End Namespace
