Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public Class PostCrusherStockpileDelta
        Inherits Calculation

        Public Const CalculationId As String = "PostCrusherStockpileDelta"
        Public Const CalculationDescription As String = "Total ∆Post-Crusher Stockpile"

        Protected Overrides ReadOnly Property CalcId() As String
            Get
                Return CalculationId
            End Get
        End Property

        Protected Overrides ReadOnly Property ResultType() As CalculationResultType
            Get
                Return CalculationResultType.Tonnes
            End Get
        End Property

        Protected Overrides ReadOnly Property Description() As String
            Get
                Return CalculationDescription
            End Get
        End Property

        Protected Overrides Sub SetupOperation()
            Dim hubDelta As CalculationResult
            Dim siteDelta As CalculationResult

            Calculation.Create(CalcType.MineProductionActuals, Session, Me).Calculate()
            hubDelta = Calculation.Create(CalcType.HubPostCrusherStockpileDelta, Session, Me).Calculate()
            siteDelta = Calculation.Create(CalcType.SitePostCrusherStockpileDelta, Session, Me).Calculate()

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, siteDelta))
            Calculations.Add(New CalculationOperation(CalculationStep.BeginDodgyTonnesAggregation, Nothing))
            Calculations.Add(New CalculationOperation(CalculationStep.Addition, hubDelta))
            Calculations.Add(New CalculationOperation(CalculationStep.EndDodgyTonnesAggregation, Nothing))

        End Sub

        Public Overrides Sub Initialise(ByVal session As Types.ReportSession)
            MyBase.Initialise(session)
            CanLoadHistoricData = False
        End Sub
    End Class
End Namespace
