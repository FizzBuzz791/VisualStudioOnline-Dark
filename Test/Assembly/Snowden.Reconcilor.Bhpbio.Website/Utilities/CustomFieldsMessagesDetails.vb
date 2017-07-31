Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class CustomFieldsMessagesDetails
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim useColumns As String() = New String() {"Name", "Text", "ExpirationDate", "IsActive", "Actions"}
            Dim messagesTable As DataTable
            Dim messagesReconcilorTable As ReconcilorTable = Nothing
            Dim dalUtility As Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility = Nothing

            Try
                dalUtility = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                messagesTable = dalUtility.GetBhpbioCustomMessages()
            Catch ex As SqlClient.SqlException
                Throw
            Finally
                If Not dalUtility Is Nothing Then
                    dalUtility.Dispose()
                    dalUtility = Nothing
                End If
            End Try

            messagesReconcilorTable = New ReconcilorTable(messagesTable, useColumns)
            messagesTable.Columns.Add("Actions", GetType(String), "'<a href=""#"" onclick=""GetCustomFieldsMessagesEdit(''' + Name + ''')"">Edit</a>" + _
                                      " | <a href=""#"" onclick=""GetCustomFieldsMessagesActivate(''' + Name + ''', ''' + IsActive + ''')"">'+IIF(IsActive = 1,'Deactivate','Activate')+'</a>" + _
                                      " | <a href=""#"" onclick=""GetCustomFieldsMessagesDelete(''' + Name + ''')"">Delete</a>'")
            messagesReconcilorTable.DataSource = messagesTable
            messagesReconcilorTable.Columns.Add("Text", New ReconcilorTableColumn("Message", 225))
            messagesReconcilorTable.Columns.Add("Name", New ReconcilorTableColumn("Name", 100))
            messagesReconcilorTable.Columns.Add("ExpirationDate", New ReconcilorTableColumn("Expiry Date", 75))
            messagesReconcilorTable.Columns.Add("IsActive", New ReconcilorTableColumn("Active", 50))
            messagesReconcilorTable.Columns.Add("Delete", New ReconcilorTableColumn("Delete", 50))
            messagesReconcilorTable.Columns.Add("Activation", New ReconcilorTableColumn("Activation", 75))
            messagesReconcilorTable.Columns("Text").MaximumLength = 45
            messagesReconcilorTable.Columns("ExpirationDate").DateTimeFormat = DirectCast(Application("DateFormat"), String)
            messagesReconcilorTable.DataBind()
            Controls.Add(messagesReconcilorTable)

        End Sub

    End Class
End Namespace
