Imports Snowden.Common.Import

Public NotInheritable Class ResMain

    'Hide Constructor
    Private Sub New()
    End Sub

    Public Shared ReadOnly Property SharedResourceManager() As Resources.ResourceManager
        Get
            Return My.Resources.ResourceManager
        End Get
    End Property

End Class
