Imports coreExt = Snowden.Reconcilor.Core.Extensibility

Namespace Extensibility
    Public Class DependencyFactories
        Inherits coreExt.DependencyFactories

        Protected Overrides Sub ConfigureNotificationFactory(ByVal factory As Core.Notification.NotificationFactory)
            MyBase.ConfigureNotificationFactory(factory)
            factory.Register("Approval", GetType(Notification.ApprovalInstance))
        End Sub

    End Class
End Namespace
