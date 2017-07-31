Imports System.Text.RegularExpressions
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class CustomFieldsMessagesDetailsSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _name As String
        Private _messageText As String
        Private _activated As Boolean
        Private _expiryDate As DateTime
        Private _isNewItem As Boolean

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _name = RequestAsString("Name")
            _messageText = RequestAsString("MessageText")
            _activated = RequestAsBoolean("Activated")
            _expiryDate = RequestAsDateTime("ExpiryDateText")
            _isNewItem = RequestAsBoolean("IsNew")

        End Sub

        ''' <summary>
        ''' Searches through the MessageText looking for words beginning with http://
        ''' It wraps these words in HTML a tags so that it'll render as a link which will open
        ''' in a new window.
        ''' </summary>
        ''' <remarks></remarks>
        Private Sub ParseLinksInMessageText()
            _messageText = Regex.Replace(_messageText, "(\bhttp://[^ ]+\b)", "<a href=""$0"" target=""_blank"">$0</a>")
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim validateMessages As New Text.StringBuilder
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing

            If _name Is Nothing Then
                validateMessages.Append("Please supply a name for this message.\n")
            End If

            If _messageText Is Nothing Then
                validateMessages.Append("Please supply text for the homescreen message.\n")
            End If

            If RequestAsDateTime("ExpiryDateText") = NullValues.DateTime Then
                validateMessages.Append("An expiry date was not supplied.\n")
            End If

            If validateMessages.ToString = String.Empty AndAlso _isNewItem Then
                Try
                    dalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                    If dalUtility.GetBhpbioCustomMessage(_name).Rows.Count > 0 Then
                        validateMessages.Append("A message with this name already exists.\n")
                    End If
                Catch ex As SqlClient.SqlException
                    If Not dalUtility Is Nothing Then
                        dalUtility.Dispose()
                        dalUtility = Nothing
                    End If
                End Try
            End If

            Return validateMessages.ToString
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing
            Dim validateMessages As String

            validateMessages = ValidateData()

            If validateMessages = String.Empty Then
                Try
                    dalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
                    dalUtility.AddOrUpdateBhpbioCustomMessage(_name, 1, _messageText, 1, _expiryDate, 1, Convert.ToInt16(_activated))
                    JavaScriptAlert("The message has been saved", String.Empty, "GetCustomFieldsMessagesList();")
                Catch ex As SqlClient.SqlException
                    JavaScriptAlert(ex.Message, "A SQL server error occurred:")
                Finally
                    If Not dalUtility Is Nothing Then
                        dalUtility.Dispose()
                        dalUtility = Nothing
                    End If
                End Try
            Else
                JavaScriptAlert(validateMessages, "Please correct the following issues:")
            End If

        End Sub

    End Class
End Namespace
