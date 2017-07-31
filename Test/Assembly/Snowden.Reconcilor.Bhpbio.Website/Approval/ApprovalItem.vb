
''' <summary>
''' Container class to hold approval item data in collections. Primarly used in the Approval Update to know
''' which approval items to add and remove.
''' </summary>
Public Class ApprovalItem

#Region "Properties"
    Private _tagId As String
    Private _locationId As Int32
    Private _approved As Boolean

    Public Property TagId() As String
        Get
            Return _tagId
        End Get
        Set(ByVal value As String)
            _tagId = value
        End Set
    End Property

    Public Property LocationId() As Int32
        Get
            Return _locationId
        End Get
        Set(ByVal value As Int32)
            _locationId = value
        End Set
    End Property

    Public Property Approved() As Boolean
        Get
            Return _approved
        End Get
        Set(ByVal value As Boolean)
            _approved = value
        End Set
    End Property
#End Region

    Public Sub New(ByVal tagId As String, ByVal locationId As Int32, ByVal approved As Boolean)
        _tagId = tagId
        _locationId = locationId
        _approved = approved
    End Sub

End Class
