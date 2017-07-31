Namespace Extensibility
    Module SettingsExtensions

        <System.Runtime.CompilerServices.Extension()> _
        Public Function GetDateSetting(ByVal userSecurity As Snowden.Common.Security.RoleBasedSecurity.IUserSecurity, ByVal name As String, ByVal defaultValue As Date) As Date
            Dim result As Date

            If Date.TryParse(userSecurity.GetSetting(name, defaultValue.ToString()), result) Then
                Return result
            Else
                Return defaultValue
            End If

        End Function
    End Module

End Namespace

