Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class CustomFieldsMessagesDetailsEdit
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _name As String

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            'Should be a safe call.
            _name = RequestAsString("Name")

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim layoutTable As New Tags.HtmlTableTag
            Dim nameInputText As New InputTags.InputTextFormless
            Dim descriptionInputTextArea As New InputTags.InputTextArea
            Dim activatedBox As New InputTags.InputCheckBoxFormless
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing
            Dim messageData As DataRow = Nothing
            Dim form As Tags.HtmlFormTag
            Dim saveButton As New InputTags.InputButtonFormless
            Dim newMessageHiddenInput As New InputTags.InputHidden
            Dim saveGroupBox As New GroupBox
            Dim expirationDate As New WebpageControls.DatePicker("ExpirationDate", "", DateAdd(DateInterval.Day, 1, Now))

            Try
                dalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                If Not _name Is Nothing Then
                    With dalUtility.GetBhpbioCustomMessage(_name)
                        If .Rows.Count > 0 Then
                            messageData = dalUtility.GetBhpbioCustomMessage(_name).Rows(0)
                        End If
                    End With
                End If
            Catch ex As SqlClient.SqlException
                If Not dalUtility Is Nothing Then
                    dalUtility.Dispose()
                    dalUtility = Nothing
                End If
            End Try

            With saveGroupBox
                If Not messageData Is Nothing Then
                    .Title = "Edit Message"
                Else
                    .Title = "Add New Message"
                End If
            End With

            form = New Tags.HtmlFormTag
            With form
                .ID = "EditForm"
                .OnSubmit = "SubmitForm('EditForm', '', './CustomFieldsMessagesDetailsSave.aspx'); return false;"
            End With

            'Setup Date Picker
            expirationDate.Id = "ExpiryDate"
            expirationDate.FormId = "EditForm"
            expirationDate.ElementId = "ExpiryDateCell"

            With newMessageHiddenInput
                .ID = "IsNew"
                If messageData Is Nothing Then
                    .Value = "true"
                Else
                    .Value = "false"
                End If
            End With

            With nameInputText
                .ID = "Name"
                .Width = 100
                If Not messageData Is Nothing Then
                    .Value = DirectCast(messageData("Name"), String)
                    .Disabled = True
                End If
            End With

            With descriptionInputTextArea
                .ID = "MessageText"
                .Cols = 76
                .Rows = 5
                If Not messageData Is Nothing Then
                    .Value = DirectCast(messageData("Text"), String)
                End If
            End With

            With activatedBox
                .ID = "Activated"
                If Not messageData Is Nothing Then
                    .Checked = Convert.ToBoolean(messageData("IsActive"))
                Else
                    .Checked = True
                End If
            End With

            With saveButton
                .ID = "Save"
                .Value = " Save Message "
                .OnClientClick = "SubmitForm('EditForm', '', './CustomFieldsMessagesDetailsSave.aspx'); return false;"
            End With

            If Not messageData Is Nothing Then
                expirationDate.DateSet = Convert.ToDateTime(messageData("ExpirationDate"))
            End If

            With layoutTable
                .AddCellInNewRow()
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Controls.Add(New RequiredFieldLabel("Name:"))
                .AddCell()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;"))
                .CurrentCell.Controls.Add(nameInputText)
                .AddCellInNewRow()
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Controls.Add(New RequiredFieldLabel("Message Text:"))
                .AddCell()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;"))
                .CurrentCell.Controls.Add(descriptionInputTextArea)
                .AddCellInNewRow()
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Controls.Add(New RequiredFieldLabel("Expiry Date:"))
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .AddCell()
                .CurrentCell.ID = "ExpiryDateCell"
                .CurrentCell.Controls.Add(expirationDate.ControlScript)
                .AddCellInNewRow()
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Controls.Add(New LiteralControl("Activated:&nbsp;&nbsp;&nbsp;"))
                .AddCell.Controls.Add(activatedBox)
                .AddCellInNewRow()
                .AddCell()
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Controls.Add(saveButton)
                .CurrentCell.Controls.Add(newMessageHiddenInput)
            End With
            form.Controls.Add(layoutTable)
            saveGroupBox.Controls.Add(form)

            Controls.Add(expirationDate.InitialiseScript)
            Controls.Add(saveGroupBox)

        End Sub

    End Class
End Namespace
