Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class MineProductionExpitEquivalent
        Inherits Calculation

        Public Const CalculationId As String = "MineProductionExpitEqulivent"
        Public Const CalculationDescription As String = "Mine Production Expit Equivalent"

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

        Protected Overrides ReadOnly Property ResultType() As CalculationResultType
            Get
                Return CalculationResultType.Tonnes
            End Get
        End Property

        Public Overrides Sub Initialise(ByVal session As Types.ReportSession)
            MyBase.Initialise(session)
            CanLoadHistoricData = True
        End Sub

        Protected Overrides Sub SetupOperation()
            Dim mineProductionActual As CalculationResult
            Dim exPitToOreStockpileMovements As CalculationResult
            Dim stockpileToCrusherMovements As CalculationResult

            mineProductionActual = Calculation.Create(CalcType.MineProductionActuals, Session, Me).Calculate()
            exPitToOreStockpileMovements = Calculation.Create(CalcType.ExPitToOreStockpile, Session, Me).Calculate()
            stockpileToCrusherMovements = Calculation.Create(CalcType.StockpileToCrusher, Session, Me).Calculate()

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, mineProductionActual))
            Calculations.Add(New CalculationOperation(CalculationStep.Addition, exPitToOreStockpileMovements))
            Calculations.Add(New CalculationOperation(CalculationStep.Subtract, stockpileToCrusherMovements))
        End Sub
    End Class
End Namespace
