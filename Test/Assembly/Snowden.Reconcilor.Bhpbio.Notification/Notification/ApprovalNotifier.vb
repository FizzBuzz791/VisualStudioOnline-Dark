Imports Snowden.Reconcilor.Core.Notification.Comparer
Imports Snowden.Reconcilor.Core.Notification

Namespace Notification
    Public Class ApprovalNotifier
        Inherits EmailNotifier(Of ApprovalValue)

        Protected Overrides Sub GetBodyContent(ByVal tags As System.Collections.Generic.IDictionary(Of String, String), ByVal previous As ApprovalValue, ByVal current As ApprovalValue, ByVal threshold As ApprovalValue, ByVal previousThresholdState As Core.Notification.ThresholdState?, ByVal currentThresholdState As Core.Notification.ThresholdState, ByVal trend As Core.Notification.TrendState?)
            MyBase.GetBodyContent(tags, previous, current, threshold, previousThresholdState, currentThresholdState, trend)

            tags("ApprovalAttribute") = threshold.ApprovalAttribute
            tags("NotificationExpiryDate") = current.CalculatedExpiryDate.ToString
            tags("Reminder") = threshold.Reminder.ToString
            tags("CalculatedApprovalDate") = current.CalculatedApprovalDate.ToString
            tags("Location") = threshold.Location.ToString
            tags("EmailMessage") = threshold.EmailTemplate

        End Sub

        Protected Overrides Function GetBodyTemplate() As String
            Return Convert.ToString(My.Resources.ResourceManager.GetObject("ApprovalNotification"))
        End Function


    End Class
End Namespace
