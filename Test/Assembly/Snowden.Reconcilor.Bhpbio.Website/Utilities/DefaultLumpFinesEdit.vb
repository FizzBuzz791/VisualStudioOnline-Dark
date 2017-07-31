Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities

    Public Class DefaultLumpFinesEdit
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"

        Private _isNew As Boolean = True
        Private _defaultLumpFinesId As New InputHidden
        Private _isNonDeletable As New InputHidden
        Private _locationControl As New ReconcilorLocationSelector
        Private _startDatePicker As New DatePicker("LumpPercentStartDate", String.Empty, DateTime.Now)
        Private _lumpPercentageBox As New InputText
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _editForm As New HtmlFormTag
        Private _layoutBox As New GroupBox
        Private _layoutTable As New HtmlTableTag
        Private _submitEdit As New InputButton
        Private _cancelEdit As New InputButton

        Protected Property IsNew() As Boolean
            Get
                Return _isNew
            End Get
            Set(ByVal value As Boolean)
                _isNew = value
            End Set
        End Property

        Protected Property BhpbioDefaultLumpFinesId() As InputHidden
            Get
                Return _defaultLumpFinesId
            End Get
            Set(ByVal value As InputHidden)
                _defaultLumpFinesId = value
            End Set
        End Property

        Protected Property IsNonDeletable() As InputHidden
            Get
                Return _isNonDeletable
            End Get
            Set(ByVal value As InputHidden)
                _isNonDeletable = value
            End Set
        End Property

        Protected ReadOnly Property LocationControl() As ReconcilorLocationSelector
            Get
                Return _locationControl
            End Get
        End Property

        Protected Property StartDatePicker() As DatePicker
            Get
                Return _startDatePicker
            End Get
            Set(ByVal value As DatePicker)
                _startDatePicker = value
            End Set
        End Property

        Protected Property LumpPercentageBox() As InputText
            Get
                Return _lumpPercentageBox
            End Get
            Set(ByVal value As InputText)
                _lumpPercentageBox = value
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

            If Not Request("BhpbioDefaultLumpFinesId") Is Nothing Then
                BhpbioDefaultLumpFinesId.Value = Request("BhpbioDefaultLumpFinesId").Trim
                IsNew = False
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                SetupFormControls()
                Controls.Add(StartDatePicker.InitialiseScript)
                Controls.Add(EditForm)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex, cellIndex As Integer
            Dim title As String = "Edit Default Lump Fines Percentage"
            Dim recordDataTable As DataTable
            Dim isNonDeletable As Boolean = False
            Dim locationName As String = String.Empty
            Dim startDate As String = String.Empty

            SubmitEdit.ID = "DefaultLumpFinesSubmit"
            SubmitEdit.Text = " Save "

            CancelEdit.ID = "CancelSubmit"
            CancelEdit.Text = " Cancel "
            CancelEdit.OnClientClick = "return CancelEditDefaultLumpFines();"

            EditForm.ID = "DefaultLumpFinesEditForm"
            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'itemDetail', './DefaultLumpFinesSave.aspx');"

            BhpbioDefaultLumpFinesId.ID = "BhpbioDefaultLumpFinesId"
            EditForm.Controls.Add(BhpbioDefaultLumpFinesId)

            Me.IsNonDeletable.ID = "IsNonDeletable"
            EditForm.Controls.Add(Me.IsNonDeletable)

            LocationControl.ID = "Location"

            StartDatePicker.FormId = EditForm.ID
            StartDatePicker.ElementId = "LumpPercentStartDateCell"

            LumpPercentageBox.ID = "LumpPercentage"

            If Not IsNew Then
                recordDataTable = DalUtility.GetBhpbioDefaultLumpFinesRecord(Convert.ToInt32(BhpbioDefaultLumpFinesId.Value))
                If recordDataTable.Rows.Count > 0 Then
                    BhpbioDefaultLumpFinesId.Value = recordDataTable.Rows(0).Item("BhpbioDefaultLumpFinesId").ToString
                    LocationControl.LocationId = Convert.ToInt32(recordDataTable.Rows(0).Item("LocationId"))
                    StartDatePicker.DateSet = Convert.ToDateTime(recordDataTable.Rows(0).Item("StartDate"))
                    LumpPercentageBox.Text = recordDataTable.Rows(0).Item("LumpPercentage").ToString

                    isNonDeletable = Convert.ToBoolean(recordDataTable.Rows(0).Item("IsNonDeletable"))
                    locationName = recordDataTable.Rows(0).Item("LocationName").ToString
                    startDate = String.Format("{0:dd-MMM-yyyy}", recordDataTable.Rows(0).Item("StartDate"))
                End If
            End If

            Me.IsNonDeletable.Value = isNonDeletable.ToString

            With LayoutTable
                .ID = "DefautlLumpFinesLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    If isNonDeletable Then
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("Location Name:"))

                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl(locationName))
                    Else
                        Dim locationCell As New TableCell
                        locationCell.ColumnSpan = 2
                        cellIndex = .Cells.Add(locationCell)
                        .Cells(cellIndex).Controls.Add(LocationControl)
                    End If
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Start Date:"))

                    cellIndex = .Cells.Add(New TableCell)
                    With .Cells(cellIndex)
                        .ID = "LumpPercentStartDateCell"
                        If isNonDeletable Then
                            .Controls.Add(New LiteralControl(startDate))
                        Else
                            .Controls.Add(StartDatePicker.ControlScript)
                        End If
                    End With
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Lump Percentage:"))

                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(LumpPercentageBox)
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
