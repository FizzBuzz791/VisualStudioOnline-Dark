
Namespace Utilities
    Public Class SystemSettingsList
        Inherits Core.Website.Utilities.SystemSettingsList


        Protected Overrides Sub CreateReturnTable()
            MyBase.CreateReturnTable()

            With ReturnTable
                .Columns("Value").Width = 300
            End With
        End Sub

    End Class
End Namespace
