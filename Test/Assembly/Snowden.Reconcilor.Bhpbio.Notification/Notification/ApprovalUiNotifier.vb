Imports RecCore = Snowden.Reconcilor.Core

Namespace Notification
    Public Class ApprovalUiNotifier
        Inherits RecCore.Notification.UiNotifier(Of ApprovalValue)

        Protected Overrides Sub GetUiSimpleMessageContent(ByVal tags As System.Collections.Generic.IDictionary(Of String, String), ByVal previous As ApprovalValue, ByVal current As ApprovalValue, ByVal threshold As ApprovalValue, ByVal previousThresholdState As Core.Notification.ThresholdState?, ByVal currentThresholdState As Core.Notification.ThresholdState, ByVal trend As Core.Notification.TrendState?)
            MyBase.GetUiSimpleMessageContent(tags, previous, current, threshold, previousThresholdState, currentThresholdState, trend)

            If Not tags.ContainsKey("Timing") Then
                tags.Add("Timing", threshold.Timing.ToString)
            Else
                tags("Timing") = threshold.Timing.ToString
            End If

            If Not tags.ContainsKey("ApprovalDate") Then
                tags.Add("ApprovalDate", current.CalculatedApprovalDate.ToString("dd-MMM-yyyy"))
            Else
                tags("ApprovalDate") = current.CalculatedApprovalDate.ToString("dd-MMM-yyyy")
            End If

            If Not tags.ContainsKey("Reminder") Then
                tags.Add("Reminder", threshold.Reminder.ToString)
            Else
                tags("Reminder") = threshold.Reminder.ToString
            End If

            If Not tags.ContainsKey("Attribute") Then
                tags.Add("Attribute", threshold.ApprovalAttribute)
            Else
                tags("Attribute") = threshold.ApprovalAttribute
            End If

            If Not tags.ContainsKey("Location") Then
                tags.Add("Location", threshold.Location)
            Else
                tags("Location") = threshold.Location
            End If

        End Sub

        Protected Overrides Function GetUiSimpleMessageTemplate() As String
            Return My.Resources.ApprovalNotificationSimpleUiMessage
        End Function

    End Class
End Namespace
