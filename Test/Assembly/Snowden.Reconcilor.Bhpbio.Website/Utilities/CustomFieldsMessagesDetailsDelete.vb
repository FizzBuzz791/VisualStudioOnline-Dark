Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class CustomFieldsMessagesDetailsDelete
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _name As String

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            'Should be a safe call.
            _name = RequestAsString("Name")
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing

            Try
                dalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                dalUtility.DeleteBhpbioCustomMessage(_name)
                JavaScriptAlert("The message has been deleted", String.Empty, "GetCustomFieldsMessagesList();")
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message, "A SQL server error has occurred:")
            Finally
                If Not dalUtility Is Nothing Then
                    dalUtility.Dispose()
                    dalUtility = Nothing
                End If
            End Try

        End Sub

    End Class
End Namespace
