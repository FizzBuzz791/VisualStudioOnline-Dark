Imports System.Runtime.InteropServices
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class PurgeAdministrationCancel
        Inherits PurgeAdministrationTemplate

        Public Class PurgeCancelRequest

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
            EventLogAuditTypeName = AuditTypes.PurgeCancelled
            EventLogHyperlink = ""
            EventLogIsVisible = True
        End Sub

        Protected Function GetRequestId() As Nullable(Of Integer)
            Dim text As String = RequestAsString("RequestId")
            Dim value As Integer
            If Integer.TryParse(text, value) Then
                Return value
            End If
            Return Nothing
        End Function

        Protected Function TryCancelRequest(<Out()> ByRef result As PurgeCancelRequest) As Boolean
            result = New PurgeCancelRequest
            Try
                Dim requestId As Nullable(Of Integer) = GetRequestId()
                If Not requestId.HasValue OrElse requestId.Value < 1 Then
                    result.Message = "Invalid Request Id"
                    Return False
                End If
                result.RequestId = requestId.Value
                Dim requests As New List(Of Integer)
                requests.Add(result.RequestId)

                If Not DalPurge.UpdatePurgeRequests(requests, Database.Dtos.PurgeRequestState.Cancelled, Nothing) Then
                    result.Message = "Update Purge Request Reported A Failure"
                    Return False
                End If

                result.Message = String.Format("Request {0} cancelled", result.RequestId)
                Return True
            Catch ex As Exception
                result.Message = ex.Message
                Return False
            End Try

        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim result As New PurgeCancelRequest
            If Not TryCancelRequest(result) Then
                EventLogDescription = "Purge request could not be cancelled. " & result.Message
                JavaScriptAlert("Error Cancelling Request:\n" & result.Message)
            Else
                EventLogDescription = result.Message
                JavaScriptAlert(result.Message, "")
            End If
        End Sub
    End Class
End Namespace
