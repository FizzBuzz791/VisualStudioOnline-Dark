Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class MineProductionActuals
        Inherits CalculationBasic

        Public Const CalculationId As String = "MineProductionActuals"
        Public Const CalculationDescription As String = "Mine Production Actuals"

        Protected Overrides ReadOnly Property CalcId() As String
            Get
                Return CalculationId
            End Get
        End Property

        Protected Overrides ReadOnly Property Description() As String
            Get
                Return CalculationDescription
            End Get
        End Property

        Protected Overrides ReadOnly Property GetCache() As Cache.DataCache
            Get
                Return Session.GetCacheActualMineProduction()
            End Get
        End Property
    End Class
End Namespace
