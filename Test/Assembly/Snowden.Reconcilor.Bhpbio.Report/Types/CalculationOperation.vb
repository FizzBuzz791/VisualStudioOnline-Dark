Namespace Types
    Public Class CalculationOperation
        Implements IDisposable

#Region "Properties"
        Private _calcStep As CalculationStep
        Private _calculation As CalculationResult
        Private _disposed As Boolean

        Public Property CalcStep() As CalculationStep
            Get
                Return _calcStep
            End Get
            Set(ByVal value As CalculationStep)
                _calcStep = value
            End Set
        End Property

        Public ReadOnly Property Calculation() As CalculationResult
            Get
                Return _calculation
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
                    'Clean up managed Resources ie: Objects
                    If (Not _calculation Is Nothing) Then
                        _calculation.Dispose()
                        _calculation = Nothing
                    End If
                End If

                'Clean up unmanaged resources ie: Pointers & Handles				
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub
#End Region


        Public Sub New(ByVal calcStepIn As CalculationStep, _
                       ByVal calculationIn As CalculationResult)
            _calcStep = calcStepIn
            _calculation = calculationIn
        End Sub


    End Class
End Namespace
