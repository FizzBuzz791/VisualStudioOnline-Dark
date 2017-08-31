Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class RFMM
        Inherits Calculation

        Public Const CalculationId As String = "RFMM"
        Public Const CalculationDescription As String = "RFMM - Mine Production (Expit) / Mining Model"

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

            Dim mineProductionExpitEquivalentResult As CalculationResult = Calculation.Create(CalcType.MineProductionExpitEquivalent, Session).Calculate()
            Dim miningModelResult As CalculationResult = Calculation.Create(CalcType.ModelMining, Session).Calculate()

            If Session.IncludeResourceClassification Then
                ' For F2/RF: Remove all model data where ResourceClassification information is present
                miningModelResult.RemoveResourceClassificationRows()
            End If

            miningModelResult.PrefixTagId("RFMM")
            mineProductionExpitEquivalentResult.PrefixTagId("RFMM")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, mineProductionExpitEquivalentResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, miningModelResult))
        End Sub

        Protected Overrides Sub ProcessTags()
            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            Dim mineProductionExpitEquivalentResult As CalculationResult = Calculation.Create(CalcType.MineProductionExpitEquivalent, Session).Calculate()
            Dim miningModelResult As CalculationResult = Calculation.Create(CalcType.ModelMining, Session).Calculate()

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.PerformCalculation(mineProductionExpitEquivalentResult, miningModelResult, CalculationType.Difference)

            For Each differenceDate In difference.AggregateRecords(onMaterialTypeId := False, onLocationId := False, onProductSize := False)
                Result.Tags.Add(New CalculationResultTag("TonnesDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Tonnes)))
                Result.Tags.Add(New CalculationResultTag("VolumeDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Volume)))

                For Each gradeName As String In CalculationResultRecord.GradeNames
                    Result.Tags.Add(New CalculationResultTag(gradeName + "Difference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.GetGrade(gradeName))))
                Next

            Next
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "SITE"
            Dim locationId = Session.RequestParameter.LocationId
            Dim presentationValid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, locationId, validLocationType)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), presentationValid))
            Next
        End Sub


    End Class
End Namespace