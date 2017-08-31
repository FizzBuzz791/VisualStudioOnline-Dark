Imports Snowden.Reconcilor.Bhpbio.Report.Enums
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class MiningModelCrusherEquivalent
        Inherits Calculation

        Public Const CalculationId As String = "MiningModelCrusherEquivalent"
        Public Const CalculationDescription As String = "Mining Model Crusher Equivalent"
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

        Protected Overrides Sub SetupOperation()
            Dim beneFeedId As Integer = Data.MaterialType.GetMaterialType(Session, "Bene Feed")
            Dim beneProdId As Integer = Data.MaterialType.GetMaterialType(Session, "Bene Product")

            Dim beneRatio As CalculationResult = Calculation.Create(CalcType.BeneRatio, Session, Me).Calculate()
            Dim exPitToOreStockpileMovements = Calculation.Create(CalcType.ExPitToOreStockpile, Session, Me).Calculate()
            Dim stockpileToCrusherMovements = Calculation.Create(CalcType.StockpileToCrusher, Session, Me).Calculate()

            Dim miningModelCalc = CType(Calculation.Create(CalcType.ModelMining, Session, Me), ModelMining)
            miningModelCalc.GeometType = Me.GeometType
            Dim miningModel = miningModelCalc.Calculate()

            If Session.IncludeResourceClassification Then
                ' For this operation: Remove all model data where ResourceClassification information is present
                ' because it is not valid at this level (but will have been needed when this model was included in
                ' the F1 or F1.5)
                miningModel.RemoveResourceClassificationRows()
            End If

            ' Apply the Bene Ratio to make Bene Feed into Bene Prod.
            beneRatio.UpdateMaterialType(beneProdId)
            miningModel.UpdateMaterialType(beneFeedId, beneProdId)
            miningModel = CalculationResult.PerformCalculation(miningModel, beneRatio, CalculationType.Ratio)
            exPitToOreStockpileMovements.UpdateMaterialType(beneFeedId, beneProdId)
            exPitToOreStockpileMovements = CalculationResult.PerformCalculation(exPitToOreStockpileMovements, beneRatio, CalculationType.Ratio)
            stockpileToCrusherMovements.UpdateMaterialType(beneFeedId, beneProdId)
            stockpileToCrusherMovements = CalculationResult.PerformCalculation(stockpileToCrusherMovements, beneRatio, CalculationType.Ratio)

            If beneRatio.Count > 0 Then
                ' if we actually have a bene ratio, we would like to show it, but only when there is data
                Calculations.Add(New CalculationOperation(CalculationStep.Assign, beneRatio.RemoveAllParents().WithProductSize("TOTAL")))
            End If

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, miningModel))
            Calculations.Add(New CalculationOperation(CalculationStep.Subtract, exPitToOreStockpileMovements))
            Calculations.Add(New CalculationOperation(CalculationStep.Addition, stockpileToCrusherMovements))
        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()
            result.GeometType = GeometType

            ' density is not valid in the MMCE, so we want to remove it to stop it bubbling up the calculations
            ' and causing problems in F2.5 and F3
            For Each record In result
                record.Volume = Nothing
                record.Density = Nothing
            Next
            Return result
        End Function

    End Class
End Namespace
