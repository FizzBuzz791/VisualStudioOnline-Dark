Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class CustomFieldsMessagesDetailsActivate
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _messageName As String
        Private _activated As Boolean

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _messageName = RequestAsString("Name")
            _activated = RequestAsBoolean("Activated")

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing

            Try
                dalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                dalUtility.AddOrUpdateBhpbioCustomMessage(_messageName, 0, NullValues.String, 0, NullValues.DateTime, 1, Convert.ToInt16(Not _activated))
                'All good, refresh the list.
                JavaScriptEvent("GetCustomFieldsMessagesList();")
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message, "A SQL server error occurred:")
            Finally
                If Not dalUtility Is Nothing Then
                    dalUtility.Dispose()
                    dalUtility = Nothing
                End If
            End Try

        End Sub

    End Class
End Namespace
