Namespace Dtos

    Public Class PurgeUser
        Private _firstName As String
        Public Property FirstName() As String
            Get
                Return _firstName
            End Get
            Set(ByVal value As String)
                _firstName = value
            End Set
        End Property

        Private _lastName As String
        Public Property LastName() As String
            Get
                Return _lastName
            End Get
            Set(ByVal value As String)
                _lastName = value
            End Set
        End Property


        Private _id As Integer
        Public Property Id() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property


    End Class
End Namespace