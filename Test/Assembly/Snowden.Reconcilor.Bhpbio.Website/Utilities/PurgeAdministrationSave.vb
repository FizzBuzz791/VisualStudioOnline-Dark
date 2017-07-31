Imports System.Runtime.InteropServices
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class PurgeAdministrationSave
        Inherits PurgeAdministrationTemplate

        Public Class PurgeRequestResult
            Private _selectedMonth As DateTime
            Public Property SelectedMonth() As DateTime
                Get
                    Return _selectedMonth
                End Get
                Set(ByVal value As DateTime)
                    _selectedMonth = value
                End Set
            End Property

            Private _requestId As Integer
            Public Property RequestId() As Integer
                Get
                    Return _requestId
                End Get
                Set(ByVal value As Integer)
                    _requestId = value
                End Set
            End Property

            Private _message As String
            Public Property Message() As String
                Get
                    Return _message
                End Get
                Set(ByVal value As String)
                    _message = value
                End Set
            End Property
        End Class

        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)
            MyBase.OnInit(e)
            EventLogAuditTypeName = AuditTypes.PurgeRequested
            EventLogHyperlink = ""
            EventLogIsVisible = True
        End Sub

        Protected Function GetSelectedMonth() As Nullable(Of DateTime)
            Dim text As String = RequestAsString("SelectedMonth")
            Dim result As DateTime
            If Not DateTime.TryParse(text, result) Then
                Return Nothing
            End If

            If Not GetPurgeableMonths().Any(Function(o) o.Month = result.Month AndAlso o.Year = result.Year) Then
                Return Nothing
            End If
            Return result
        End Function

        Protected Function TrySavePurgeRequest(<Out()> ByRef result As PurgeRequestResult) As Boolean
            result = New PurgeRequestResult
            Try
                If Not Resources.UserSecurity.UserId.HasValue Then
                    result.Message = "Invalid User Id"
                End If
                Dim month As Nullable(Of DateTime) = GetSelectedMonth()
                If Not month.HasValue Then
                    result.Message = "Invalid Selected Month"
                    Return False
                End If
                result.SelectedMonth = month.Value
                If Not DalPurge.AddPurgeRequest(result.SelectedMonth, Resources.UserSecurity.UserId.Value, result.RequestId) Then
                    result.Message = "Add Purge Process Reported Failure"
                    Return False
                End If
                result.Message = String.Format("Request {0} for {1:MMMM yyyy} submitted", result.RequestId, result.SelectedMonth)
                Return True
            Catch ex As Exception
                result.Message = ex.Message
                Return False
            End Try

        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim result As New PurgeRequestResult
            If Not TrySavePurgeRequest(result) Then
                EventLogDescription = "Purge request could not be submitted. " & result.Message
                JavaScriptAlert("Error Saving Purge Request:\n" & result.Message)
            Else
                EventLogDescription = result.Message
                JavaScriptAlert(result.Message, "")
            End If

        End Sub
    End Class
End Namespace
