Namespace Utilities
    Public Class NotificationAdministrationDelete
        Inherits Core.Website.Utilities.NotificationAdministrationDelete

        Protected Overrides Sub ProcessData()
            Dim dalBhpbioNotification As Bhpbio.Notification.SqlDalNotification = Nothing

            Try
                dalBhpbioNotification = New Bhpbio.Notification.SqlDalNotification(Resources.Connection)
                dalBhpbioNotification.DeleteInstanceApproval(InstanceId)
            Catch ex As Exception
                Throw
            Finally
                If Not dalBhpbioNotification Is Nothing Then
                    dalBhpbioNotification.Dispose()
                    dalBhpbioNotification = Nothing
                End If
            End Try

            MyBase.ProcessData()

        End Sub

    End Class
End Namespace
