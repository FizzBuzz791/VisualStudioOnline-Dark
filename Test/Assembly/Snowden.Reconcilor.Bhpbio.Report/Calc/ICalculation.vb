Namespace Calc

    Public Interface ICalculation
        Inherits IDisposable

        Sub Initialise(ByVal session As Types.ReportSession)

        Function Calculate() As Types.CalculationResult
    End Interface

End Namespace

