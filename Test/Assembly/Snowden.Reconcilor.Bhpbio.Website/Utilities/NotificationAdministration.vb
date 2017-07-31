Namespace Utilities
    Public Class NotificationAdministration
        Inherits Core.Website.Utilities.NotificationAdministration

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            NotificationListFilterBox.ShowLocationFilter = True
        End Sub

    End Class
End Namespace
