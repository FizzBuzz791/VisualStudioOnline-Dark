Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public Class HubPostCrusherStockpileDelta
        Inherits CalculationBasic

        Public Const CalculationId As String = "HubPostCrusherStockpileDelta"
        Public Const CalculationDescription As String = "Hub ∆Post-Crusher Stockpile"

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
                Return Session.GetCacheActualHubPostCrusherStockpileDelta()
            End Get
        End Property

        Public Overrides Sub Initialise(ByVal session As Types.ReportSession)
            MyBase.Initialise(session)
            CanLoadHistoricData = True
        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            If RootCalculationId = F3.CalculationId Or Me.RootCalculationId = MiningModelShippingEquivalent.CalculationId Then
                For Each record In result
                    record.H2O = Nothing
                    record.H2ODropped = Nothing
                    record.H2OShipped = Nothing
                Next
            End If

            Return result
        End Function
    End Class
End Namespace
