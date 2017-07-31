Imports Microsoft.VisualBasic
' Version.vb gets replaced with auto-gen file on label TFS builds with the correct version.
' As a result this file is only used in desktop builds. It is recommended to still update major.minor
' increments in this file for desktop builds.
Friend Class Version
    Private Sub New()
    End Sub

    Public Const AssemblyVersion As String = "4.1.0.0"
End Class
