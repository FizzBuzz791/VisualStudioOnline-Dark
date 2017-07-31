Public Partial Class test
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim windowsIdentity As System.Security.Principal.WindowsIdentity

        windowsIdentity = DirectCast(User.Identity, System.Security.Principal.WindowsIdentity)

        Response.Write("IsAuthenticated: " & windowsIdentity.IsAuthenticated & "<br>")
        Response.Write("Name: " & windowsIdentity.Name & "<br>")
        Response.Write("Authentication Type: " & windowsIdentity.AuthenticationType & "<br>")
        Response.Write("In Role Snowden\Technologies (Worldwide): " & User.IsInRole("SNOWDEN\Technologies (Worldwide)") & "<br>")
        Response.Write("In Role Snowden\Technologies (Brisbane): " & User.IsInRole("Snowden\Technologies (Brisbane)") & "<br>")
        Response.Write("In Role Snowden\Technologies (Perth): " & User.IsInRole("Snowden\Technologies (Perth)") & "<br>")
        If Not windowsIdentity.User Is Nothing Then
            Response.Write("SID: " & windowsIdentity.User.Value & "<br>")
        Else
            Response.Write("SID: N/A<br>")
        End If

        Dim iref As System.Security.Principal.IdentityReference
        Dim acct As System.Security.Principal.IdentityReference

        If Not windowsIdentity.Groups Is Nothing Then
            For Each iref In windowsIdentity.Groups
                acct = iref.Translate(GetType(System.Security.Principal.NTAccount))
                Response.Write("Member of group: " & acct.Value & ", " & iref.Value & "<br>")
            Next
        Else
            Response.Write("anon doesn't have any groups")
        End If

        Dim a As New System.Security.Principal.NTAccount("Snowden\Technologies (worldwide)")
        Response.Write("Snowden\Technologies (worldwide): sid = ")
        Response.Write(a.Translate(GetType(System.Security.Principal.SecurityIdentifier)).Value)
    End Sub
End Class