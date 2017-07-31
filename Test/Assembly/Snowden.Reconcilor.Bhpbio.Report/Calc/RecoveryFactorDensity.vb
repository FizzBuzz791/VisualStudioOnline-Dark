Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class RecoveryFactorDensity
        Inherits Calculation

        Public Const CalculationId As String = "RecoveryFactorDensity"
        Public Const CalculationDescription As String = "RFMMD - Total Hauled / Mining Model"

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
            Dim actualMined As CalculationResult = Calculation.Create(CalcType.ActualMined, Session, Me).Calculate()
            Dim miningCalc As CalculationModel = CType(Calculation.Create(CalcType.ModelMining, Session, Me), CalculationModel)
            miningCalc.IncludeAllMaterialTypes = True
            Dim miningResult = miningCalc.Calculate()

            If (Session.IncludeResourceClassification) Then
                ' For this operation: Remove all model data where ResourceClassification information is present
                miningResult.RemoveResourceClassificationRows()
            End If

            actualMined.PrefixTagId("RFD")
            miningResult.PrefixTagId("RFD")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, actualMined))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, miningResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "PIT"
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