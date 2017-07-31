Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class RecoveryFactorMoisture
        Inherits Calculation

        Public Const CalculationId As String = "RecoveryFactorMoisture"
        Public Const CalculationDescription As String = "RFMMH2O - Actual C / Mining Model (Dropped)"

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
            Dim actualCResult As CalculationResult = Calculation.Create(CalcType.MineProductionActuals, Session, Me).Calculate()
            Dim miningResult As CalculationResult = Calculation.Create(CalcType.ModelMining, Session, Me).Calculate()

            If (Session.IncludeResourceClassification) Then
                ' For this operation: Remove all model data where ResourceClassification information is present
                miningResult.RemoveResourceClassificationRows()
            End If

            actualCResult.PrefixTagId("RFM")
            miningResult.PrefixTagId("RFM")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, actualCResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, miningResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "SITE"
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, Session.RequestParameter.LocationId)
            Dim isValid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, Session.RequestParameter.LocationId, validLocationType)
            Result.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), isValid))
        End Sub

        Protected Overrides Sub ProcessTags()
            SetPresentation()

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next
        End Sub

    End Class
End Namespace