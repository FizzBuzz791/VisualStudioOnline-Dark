Namespace Types

    Public Enum LocationTypes
        Company = 1
        Hub = 2
        Site = 3
        Pit = 4
        Bench = 5
        Blast = 6
        Block = 7
    End Enum

    ''' <summary>
    ''' Class to hold location information.
    ''' </summary>
    Public Class ExtendedLocation : Inherits Location
#Region "Properties"

        Private _siteName As String
        Private _hubName As String

        

        Public Property SiteName() As String
            Get
                Return _siteName
            End Get
            Set(ByVal value As String)
                _siteName = value
            End Set
        End Property

        Public Property HubName() As String
            Get
                Return _hubName
            End Get
            Set(ByVal value As String)
                _hubName = value
            End Set
        End Property

#End Region

        Sub New()
            MyBase.New(-1, Nothing, Nothing)
        End Sub

        Sub New(ByVal locationId As Int32, ByVal locationName As String, ByVal locationType As String)
            MyBase.New(locationId, locationName, locationType)
        End Sub
    End Class

    ''' <summary>
    ''' Class to hold location information.
    ''' </summary>
    Public Class Location
#Region "Properties"
        Private _locationId As Int32
        Private _locationName As String
        Private _locationType As String

        Public Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property

        Public Property LocationName() As String
            Get
                Return _locationName
            End Get
            Set(ByVal value As String)
                _locationName = value
            End Set
        End Property

        Public Property LocationType() As String
            Get
                Return _locationType
            End Get
            Set(ByVal value As String)
                _locationType = value
            End Set
        End Property

#End Region

        Sub New(ByVal locationId As Int32, ByVal locationName As String, ByVal locationType As String)
            Me.LocationId = locationId
            Me.LocationName = locationName
            Me.LocationType = locationType
        End Sub

    End Class
End Namespace
