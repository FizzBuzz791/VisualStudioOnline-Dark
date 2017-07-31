
Namespace Types
    Public Class DataRequest

#Region "Properties"
        Private _startDate As Date
        Private _endDate As Date
        Private _dateBreakdown As ReportBreakdown
        Private _locationId As Nullable(Of Int32)
        Private _childLocations As Boolean

        Public Property LocationId() As Nullable(Of Int32)
            Get
                Return _locationId
            End Get
            Set(ByVal value As Nullable(Of Int32))
                _locationId = value
            End Set
        End Property

        Public Property StartDate() As Date
            Get
                Return _startDate
            End Get
            Set(ByVal value As Date)
                _startDate = value
            End Set
        End Property

        Public Property EndDate() As Date
            Get
                Return _endDate
            End Get
            Set(ByVal value As Date)
                _endDate = value
            End Set
        End Property

        Public Property DateBreakdown() As ReportBreakdown
            Get
                Return _dateBreakdown
            End Get
            Set(ByVal value As ReportBreakdown)
                _dateBreakdown = value
            End Set
        End Property

        Public Property ChildLocations() As Boolean
            Get
                Return _childLocations
            End Get
            Set(ByVal value As Boolean)
                _childLocations = value
            End Set
        End Property



#End Region

        Sub New(ByVal locationId As Nullable(Of Int32), _
            ByVal startDate As Date, ByVal endDate As Date, ByVal dateBreakdown As Types.ReportBreakdown, _
            ByVal childLocations As Boolean)
            Me.LocationId = locationId
            Me.StartDate = startdate
            Me.EndDate = endDate
            Me.DateBreakdown = dateBreakdown
            Me.ChildLocations = childLocations
        End Sub

        Public Shared Function Equal(ByVal left As DataRequest, ByVal right As DataRequest) As Boolean?
            Return (left.DateBreakdown = right.DateBreakdown And left.EndDate = right.EndDate And
                         left.StartDate = right.StartDate And left.LocationId = right.LocationId And
                         left.ChildLocations = right.ChildLocations)
        End Function

        'Public Shared Operator <>(ByVal l As DataRequest, ByVal r As DataRequest) As Boolean?
        '    Return (l.DateBreakdown <> r.DateBreakdown Or l.EndDate <> r.EndDate Or _
        '                 l.StartDate <> r.StartDate Or l.LocationId <> r.LocationId Or _
        '                 l.ChildLocations = r.ChildLocations)

        'End Operator
    End Class
End Namespace
