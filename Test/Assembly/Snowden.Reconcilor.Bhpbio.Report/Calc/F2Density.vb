Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class F2Density
        Inherits Calculation

        Public Const CalculationId As String = "F2DensityFactor"
        Public Const CalculationDescription As String = "F2 (Density) - Total Hauled / Grade Control Model"

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
            Dim actualMinedResult As CalculationResult = Calculation.Create(CalcType.ActualMined, Session).Calculate()
            Dim gradeControlCalc As Calc.ModelGradeControl = DirectCast(Calculation.Create(CalcType.ModelGradeControl, Session), Calc.ModelGradeControl)
            gradeControlCalc.IncludeAllMaterialTypes = True
            Dim gradeControlResult As CalculationResult = gradeControlCalc.Calculate()

            If (Session.IncludeResourceClassification) Then
                ' For this operation: Remove all model data where ResourceClassification information is present
                gradeControlResult.RemoveResourceClassificationRows()
            End If

            actualMinedResult.PrefixTagId("F2Density")
            gradeControlResult.PrefixTagId("F2Density")
            gradeControlResult.ReplaceDescription("GradeControlModel", "Grade Control Model (All Materials)")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, actualMinedResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, gradeControlResult))
        End Sub

        Protected Overrides Sub ProcessTags()
            ' F2-Density is always an intermediate calculation, so we don't want to show the results in whatever reports get
            ' exported (we might want to show the sub-calcs such as Actual-M (now H-value) though. So we don't set the presentation flag
            ' for those here, even though that is the normal process in other calculations)
            Result.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), False))

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

        End Sub
    End Class
End Namespace
