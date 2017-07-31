Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class CustomFieldsLocationColorsDetailsSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _selectedColor As String
        Private _locationId As String

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _selectedColor = RequestAsString("ColorSelectPicker")
            _locationId = RequestAsString("LocationId")
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim validateMessages As New Text.StringBuilder
            Dim dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility = Nothing

            If _selectedColor Is Nothing Then
                validateMessages.Append("Please select a color for this location.\n")
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
                    dalUtility.AddOrUpdateBhpbioReportColor(_locationId, "Location " + _locationId, 1, _selectedColor, Nothing, Nothing)
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
