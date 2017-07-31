Imports System.Runtime.InteropServices
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Database.Dtos

Namespace Utilities
    Public Class PurgeAdministrationApprove
        Inherits PurgeAdministrationTemplate

        Public Class PurgeApprovalResult

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
            EventLogAuditTypeName = AuditTypes.PurgeApproved
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

        Protected Function TryApproveRequest(<Out()> ByRef result As PurgeApprovalResult) As Boolean
            result = New PurgeApprovalResult
            Try
                If Not Resources.UserSecurity.UserId.HasValue Then
                    result.Message = "Invalid User Id"
                End If

                Dim requestId As Nullable(Of Integer) = GetRequestId()

                If Not requestId.HasValue OrElse requestId.Value < 1 Then
                    result.Message = "Invalid Request Id"
                    Return False
                End If

                ' Get the current set of requests
                Dim purgeRequests = DalPurge.GetPurgeRequests(True, False, True)
                ' If no requests ready for approval
                If (purgeRequests Is Nothing) Then
                    ' Then error condition
                    result.Message = "No requests are currently available for approval"
                    Return False
                End If

                Dim matchedRequest As PurgeRequest = Nothing

                ' Try to get the exact request
                matchedRequest = purgeRequests.FirstOrDefault(Function(pq As PurgeRequest) pq.Id = requestId.Value)

                ' If the request object was not found
                If matchedRequest Is Nothing Then
                    ' Error condition
                    result.Message = "The Request Id specified did not match an existing Purge Request ready for approval"
                    Return False
                End If

                ' Now get the set of purgable months
                Dim purgableMonths = GetPurgeableMonths()
                Dim matchingPurgeableMonth = purgableMonths.FirstOrDefault(Function(dt As Date) New DateTime(dt.Year, dt.Month, 1) = matchedRequest.Month)

                ' If the month is no longer purgable
                If (Not New DateTime(matchingPurgeableMonth.Year, matchingPurgeableMonth.Month, 1) = matchedRequest.Month) Then
                    result.Message = "The month specified for this request is no longer valid for purging.  This may be due to recent unapprovals."
                    Return False
                End If

                result.RequestId = requestId.Value

                Dim requests As New List(Of Integer)

                requests.Add(result.RequestId)

                If Not DalPurge.UpdatePurgeRequests(requests, Database.Dtos.PurgeRequestState.Approved, Resources.UserSecurity.UserId) Then
                    result.Message = "Update Purge Request Reported A Failure"
                    Return False
                End If

                result.Message = String.Format("Request {0} approved", result.RequestId)
                Return True
            Catch ex As Exception
                result.Message = ex.Message
                Return False
            End Try

        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim result As New PurgeApprovalResult
            If Not TryApproveRequest(result) Then
                EventLogDescription = "Purge request could not be approved. " & result.Message
                JavaScriptAlert("Error Approving Request:\n" & result.Message)
            Else
                EventLogDescription = result.Message
                JavaScriptAlert(result.Message, "")
            End If
        End Sub

    End Class
End Namespace
