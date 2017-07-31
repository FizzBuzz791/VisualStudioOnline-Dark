Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class MiningModelShippingEquivalent
        Inherits Calculation

        Public Const CalculationId As String = "MiningModelShippingEquivalent"
        Public Const CalculationDescription As String = "Mining Model Shipping Equivalent"

        Public Property GeometType As GeometTypeSelection = GeometTypeSelection.AsShipped

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

        Public Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As MiningModelShippingEquivalent
            Dim c = CType(Calc.Calculation.Create(Calc.CalcType.MiningModelShippingEquivalent, session), MiningModelShippingEquivalent)
            c.GeometType = geometType
            Return c
        End Function

        Protected Overrides Sub SetupOperation()
            Dim postCrusherStockpileDeltaResult = Calculation.Create(CalcType.PostCrusherStockpileDelta, Session, Me).Calculate()
            Dim portBlendedAdjustmentResult = Calculation.Create(CalcType.PortBlendedAdjustment, Session, Me).Calculate()
            Dim portStockpileDeltaResult = Calculation.Create(CalcType.PortStockpileDelta, Session, Me).Calculate()

            Dim MiningModelCrusherEquivalent = CType(Calculation.Create(CalcType.MiningModelCrusherEquivalent, Session, Me), MiningModelCrusherEquivalent)
            MiningModelCrusherEquivalent.GeometType = GeometType
            Dim miningModelCrusherEquivalentResult = MiningModelCrusherEquivalent.Calculate()

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, miningModelCrusherEquivalentResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Subtract, postCrusherStockpileDeltaResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Addition, portBlendedAdjustmentResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Subtract, portStockpileDeltaResult))
            ' Ensure the results do not have material types. This should have been sorted by the previous subtract
            ' but incase the tonnes were null.
            Calculations.Add(New CalculationOperation(CalculationStep.AggregateDateLocation, Nothing))
        End Sub

        Public Overrides Function Calculate() As CalculationResult
            Dim result = MyBase.Calculate()
            result.GeometType = GeometType

            ' on other calculations we add _AS to indicate that it is as-shipped - but in this case AS is the
            ' default, so I think we want to change the tag name only when it is in AD mode
            If result.GeometType = GeometTypeSelection.AsDropped Then
                result.TagId = result.TagId + "_AD"
            End If

            Return result
        End Function

    End Class
End Namespace

