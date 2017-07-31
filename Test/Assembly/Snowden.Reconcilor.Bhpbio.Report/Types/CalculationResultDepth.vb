Namespace Types

    Public Class CalculationResultDepth
        Implements IDisposable

#Region "Properties"
        Private _depth As Int32
        Private _result As CalculationResult
        Private _disposed As Boolean

        Public Property Depth() As Int32
            Get
                Return _depth
            End Get
            Set(ByVal value As Int32)
                _depth = value
            End Set
        End Property

        Public ReadOnly Property Result() As CalculationResult
            Get
                Return _result
            End Get
        End Property
#End Region


#Region " Destructors "
        Public Sub Dispose() Implements IDisposable.Dispose
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If (Not _disposed) Then
                If (disposing) Then
                    If (Not _result Is Nothing) Then
                        _result.Dispose()
                        _result = Nothing
                    End If
                End If
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub
#End Region

        Public Sub New(ByVal depth As Int32, ByVal result As CalculationResult)
            _depth = depth
            _result = result
        End Sub
    End Class
End Namespace
