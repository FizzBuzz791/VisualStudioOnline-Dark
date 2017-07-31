Namespace Dtos
    Public Class PurgeRequest
        Private _id As Integer
        Public Property Id() As Integer
            Get
                Return Me._id
            End Get
            Set(ByVal value As Integer)
                Me._id = value
            End Set
        End Property
        Private _month As Date
        Public Property Month() As DateTime
            Get
                Return Me._month
            End Get
            Set(ByVal value As DateTime)
                Me._month = value
            End Set
        End Property

        Private _status As PurgeRequestState
        Public Property Status() As PurgeRequestState
            Get
                Return Me._status
            End Get
            Set(ByVal value As PurgeRequestState)
                Me._status = value
            End Set
        End Property


        Private _requestingUser As PurgeUser
        Public Property RequestingUser() As PurgeUser
            Get
                Return _requestingUser
            End Get
            Set(ByVal value As PurgeUser)
                _requestingUser = value
            End Set
        End Property


        Private _approvingUser As PurgeUser
        Public Property ApprovingUser() As PurgeUser
            Get
                Return _approvingUser
            End Get
            Set(ByVal value As PurgeUser)
                _approvingUser = value
            End Set
        End Property



        Private _Timestamp As Date
        Public Property Timestamp() As DateTime
            Get
                Return _Timestamp
            End Get
            Set(ByVal value As DateTime)
                _Timestamp = value
            End Set
        End Property


        Private _isReadyForApproval As Boolean
        Public Property IsReadyForApproval() As Boolean
            Get
                Return _isReadyForApproval
            End Get
            Set(ByVal value As Boolean)
                _isReadyForApproval = value
            End Set
        End Property


        Private _isReadyForPurging As Boolean
        Public Property IsReadyForPurging() As Boolean
            Get
                Return _isReadyForPurging
            End Get
            Set(ByVal value As Boolean)
                _isReadyForPurging = value
            End Set
        End Property




    End Class
End Namespace
