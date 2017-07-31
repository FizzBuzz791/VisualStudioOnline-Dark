Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class MiningModelOreForRailEquivalent
        Inherits Calculation

        Public Const CalculationId As String = "MiningModelOreForRailEquivalent"
        Public Const CalculationDescription As String = "Mining Model Ore For Rail Equivalent"

        Public Property GeometType As GeometTypeSelection = GeometTypeSelection.AsDropped

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
            Dim mmce = CType(Calculation.Create(CalcType.MiningModelCrusherEquivalent, Session, Me), MiningModelCrusherEquivalent)
            mmce.GeometType = GeometType
            Dim mmceResult = mmce.Calculate()
            Dim pcsdResult = Calculation.Create(CalcType.PostCrusherStockpileDelta, Session, Me).Calculate()

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, mmceResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Subtract, pcsdResult))
            ' Ensure the results do not have material types. This should have been sorted by the previous subtract
            ' but incase the tonnes were null.
            Calculations.Add(New CalculationOperation(CalculationStep.AggregateDateLocation, Nothing))
        End Sub
    End Class
End Namespace
