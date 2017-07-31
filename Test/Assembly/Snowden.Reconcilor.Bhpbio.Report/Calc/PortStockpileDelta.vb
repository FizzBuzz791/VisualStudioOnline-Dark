Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class PortStockpileDelta
        Inherits CalculationBasic

        Public Const CalculationId As String = "PortStockpileDelta"
        Public Const CalculationDescription As String = "∆Port Stockpiles"

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
                Return Session.GetCachePortStockpileDelta()

            End Get
        End Property

        Public Overrides Sub Initialise(ByVal session As Types.ReportSession)
            MyBase.Initialise(session)
            CanLoadHistoricData = True
        End Sub
    End Class
End Namespace
