Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class BeneRatio
        Inherits Calculation

        Public Const CalculationId As String = "BeneRatio"
        Public Const CalculationDescription As String = "Bene Ratio (Product / Feed)"

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
                Return CalculationResultType.Ratio
            End Get
        End Property

        Protected Overrides Sub SetupOperation()
            Dim beneProductResults As CalculationResult = Calculation.Create(CalcType.BeneProduct, Session).Calculate()
            Dim mineProductionActuals As CalculationResult = Calculation.Create(CalcType.MineProductionActuals, Session).Calculate()
            Dim beneFeedId As Integer = Data.MaterialType.GetMaterialType(Session, "Bene Feed")
            Dim beneProdId As Integer = Data.MaterialType.GetMaterialType(Session, "Bene Product")
            Dim beneFeed As CalculationResult = mineProductionActuals.GetMaterialTypeResult(beneFeedId)
            Dim beneProduct As CalculationResult = beneProductResults.GetMaterialTypeResult(beneProdId)

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, beneProduct))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, beneFeed))
        End Sub

        Public Overrides Function Calculate() As CalculationResult
            Dim result = MyBase.Calculate()
            For Each record In result
                record.UltraFines = 1
            Next
            Return result
        End Function
    End Class
End Namespace
