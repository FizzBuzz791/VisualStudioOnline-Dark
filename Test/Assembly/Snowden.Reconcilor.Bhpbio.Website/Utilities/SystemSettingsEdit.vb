Namespace Utilities
    Public Class SystemSettingsEdit
        Inherits Core.Website.Utilities.SystemSettingsEdit

        Protected Overrides Sub SetupFormControls()
            MyBase.SetupFormControls()

            ValueText.Width = 700
        End Sub

        Protected Overrides Sub LayoutForm()
            MyBase.LayoutForm()

            LayoutBox.Width = 800
        End Sub

    End Class
End Namespace
