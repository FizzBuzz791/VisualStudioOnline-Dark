Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions
Imports System.Data.SqlClient

Namespace Utilities

    Public Class DefaultDepositEdit
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"

        Private _editForm As New HtmlFormTag
        Private _layoutBox As New GroupBox
        Private _layoutTable As New HtmlTableTag
        Private _submitEdit As New InputButton

        Protected Property IsNew As Boolean = True

        Protected Property BhpbioDefaultDepositId As InputHidden = New InputHidden
        Protected Property ParentLocationDepositId As InputHidden = New InputHidden
        Protected Property OriginalName As InputHidden = New InputHidden

        Protected Property DepositNameBox As InputText = New InputText

        Protected Property ReturnTable As ReconcilorTable

        Protected Property DalUtility As Database.DalBaseObjects.IUtility

        Public Property EditForm As HtmlFormTag
            Get
                Return _editForm
            End Get
            Set
                If (Not value Is Nothing) Then
                    _editForm = value
                End If
            End Set
        End Property

        Public Property LayoutBox As GroupBox
            Get
                Return _layoutBox
            End Get
            Set
                If (Not value Is Nothing) Then
                    _layoutBox = value
                End If
            End Set
        End Property

        Public Property LayoutTable As HtmlTableTag
            Get
                Return _layoutTable
            End Get
            Set
                If (Not value Is Nothing) Then
                    _layoutTable = value
                End If
            End Set
        End Property

        Public Property SubmitEdit As InputButton
            Get
                Return _submitEdit
            End Get
            Set
                If (Not value Is Nothing) Then
                    _submitEdit = value
                End If
            End Set
        End Property

        Public Property CancelEdit As InputButton = New InputButton

#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("BhpbioDefaultDepositId") Is Nothing Then
                BhpbioDefaultDepositId.Value = Request("BhpbioDefaultDepositId").Trim
                IsNew = False
            End If
            If Not Request("ParentLocationId") Is Nothing Then
                ParentLocationDepositId.Value = Request("ParentLocationId").Trim
            End If
        End Sub

        Protected Overrides Function ValidateData() As String
            If IsNew AndAlso Not String.IsNullOrEmpty(ParentLocationDepositId.Value) Then
                Dim parentSiteId = Integer.Parse(ParentLocationDepositId.Value)
                Dim locationType = DalUtility.GetLocation(parentSiteId)
                Dim locationTypeId = locationType.AsEnumerable.First.AsInt("Location_Type_Id")
                Const SITE_LOCATION_TYPE_ID = 3

                If locationTypeId <> SITE_LOCATION_TYPE_ID Then
                    Return "Please select a site from the location selection control"
                End If
            End If

            Return Nothing
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then

                    SetupFormControls()
                    Controls.Add(EditForm)
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while saving Deposit: {0}", ex.Message)
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex, cellIndex As Integer
            Dim titleText As String

            SubmitEdit.ID = "DefaultDepositSubmit"
            SubmitEdit.Text = String.Format(" Save ")

            CancelEdit.ID = "CancelSubmit"
            CancelEdit.Text = String.Format(" Cancel ")
            CancelEdit.OnClientClick = "return CancelEditDefaultDeposit();"

            EditForm.ID = "DefaultDepositEditForm"
            DepositNameBox.ID = "Name"
            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'itemList', './DefaultDepositSave.aspx');"

            BhpbioDefaultDepositId.ID = "BhpbioDefaultDepositId"
            ParentLocationDepositId.ID = "ParentLocationDepositId"
            OriginalName.ID = "OriginalName"
            EditForm.Controls.Add(BhpbioDefaultDepositId)
            EditForm.Controls.Add(ParentLocationDepositId)
            EditForm.Controls.Add(OriginalName)

            Dim depositId As Integer?
            Dim parentSiteId As Integer?
            If (Not IsNew) Then
                depositId = Integer.Parse(BhpbioDefaultDepositId.Value)
            Else
                parentSiteId = Integer.Parse(ParentLocationDepositId.Value)
            End If

            titleText = CType(IIf(IsNew, "Add Deposit", "Edit Deposit"), String)

            With LayoutTable
                .ID = "DefaultDepositLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Name:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(DepositNameBox)
                End With

                ' Implements Pit Select List component
                Dim pits As New PitSelectList()
                Dim ds As DataSet = DalUtility.GetDepositPits(depositId, parentSiteId)

                If Not IsNew Then
                    DepositNameBox.Text = ds.Tables(0).Rows(0).AsString("Name")
                    OriginalName.Value = DepositNameBox.Text
                    ParentLocationDepositId.Value = ds.Tables(0).Rows(0).AsString("ParentLocationId")
                End If

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Pits:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(pits.GetPitList(depositId, ds.Tables(1), ds.Tables(2)))
                End With

            End With

            With LayoutBox
                .Title = titleText
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

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace