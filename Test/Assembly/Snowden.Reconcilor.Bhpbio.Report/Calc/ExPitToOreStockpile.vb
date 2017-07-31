Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ExpitToOreStockpile
        Inherits CalculationBasic

        Public Const CalculationId As String = "ExPitToOreStockpile"
        Public Const CalculationDescription As String = "Ex-pit to Ore Stockpile Movements"

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
                Return Session.GetCacheActualExpitToStockpile()
            End Get
        End Property
    End Class
End Namespace
