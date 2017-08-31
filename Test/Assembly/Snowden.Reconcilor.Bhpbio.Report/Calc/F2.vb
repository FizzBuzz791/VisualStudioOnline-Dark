Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class F2
        Inherits Calculation

        Public Const CalculationId As String = "F2Factor"
        Public Const CalculationDescription As String = "F2 - Mine Production (Expit) / Grade Control Model"

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
            Dim mineProductionExpitEquivalentResult As CalculationResult = _
             Calculation.Create(CalcType.MineProductionExpitEquivalent, Session).Calculate()

            Dim gradeControlResult As CalculationResult = Calculation.Create(CalcType.ModelGradeControl, Session).Calculate()
            If (Session.IncludeResourceClassification) Then
                ' For F2: Remove all model data where ResourceClassification information is present
                gradeControlResult.RemoveResourceClassificationRows()
            End If

            mineProductionExpitEquivalentResult.PrefixTagId("F2")
            gradeControlResult.PrefixTagId("F2")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, mineProductionExpitEquivalentResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, gradeControlResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "SITE"
            Dim lockedMessage As String = ""
            Dim calcResult As CalculationResult
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, _
             Session.RequestParameter.LocationId)
            Dim valid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, _
             Session.RequestParameter.LocationId, validLocationType)

            ' Check for F3 to stop it being editable. Must have no F3 approved.
            If Report.Data.ApprovalData.IsAnyTagGroupApproved(Session, _
             Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F3Factor") Then
                lockedMessage = "F3 Data has already been approved."
            End If

            ' Check for F1.5, Must have all F1.5 data approved.
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F15Factor") Then
                lockedMessage = "All F1.5 data for this site must be approved."
            End If

            Report.Data.ApprovalData.AssignEditableOnLocationType(Session.DalUtility, Result.GetAllCalculations(), _
                validLocationType, Session.RequestParameter.LocationId)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationLocked", _
                 GetType(String), lockedMessage))
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", _
                 GetType(Boolean), valid))
            Next
        End Sub

        Protected Overrides Sub ProcessTags()
            Dim mineProductionExpitEquivalentResult As CalculationResult = _
              Calculation.Create(CalcType.MineProductionExpitEquivalent, Session).Calculate()
            Dim gradeControlResult As CalculationResult = Calculation.Create(CalcType.ModelGradeControl, Session).Calculate()
            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.Difference(mineProductionExpitEquivalentResult, gradeControlResult)

            For Each differenceDate In difference.AggregateRecords(onMaterialTypeId := False, onLocationId := False, onProductSize := False)
                Result.Tags.Add(New CalculationResultTag("TonnesDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Tonnes)))

                For Each gradeName As String In CalculationResultRecord.GradeNames
                    Result.Tags.Add(New CalculationResultTag(gradeName + "Difference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.GetGrade(gradeName))))
                Next

            Next
        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            For Each record In result
                If record.ProductSize.ToUpper <> "TOTAL" Then record.H2O = Nothing
            Next

            Return result
        End Function
    End Class
End Namespace
