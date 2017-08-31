Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Calc
    Public NotInheritable Class F3
        Inherits Calculation

        Public Const CalculationId As String = "F3Factor"
        Public Const CalculationDescription As String = "F3 - Ore Shipped / Mining Model Shipping Equivalent"

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
            Dim oreShippedResult As CalculationResult = Calculation.Create(CalcType.PortOreShipped, Session, Me).Calculate()
            Dim miningModelShippingEquivalentResult As CalculationResult = Calculation.Create(CalcType.MiningModelShippingEquivalent, Session, Me).Calculate()

            oreShippedResult.PrefixTagId("F3")
            miningModelShippingEquivalentResult.PrefixTagId("F3")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, oreShippedResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, miningModelShippingEquivalentResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "HUB"
            Dim lockedMessage As String = ""
            Dim calcResult As CalculationResult
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, _
             Session.RequestParameter.LocationId)
            Dim valid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, _
             Session.RequestParameter.LocationId, validLocationType)

            If Not Session.UserSecurity Is Nothing Then
                If lockedMessage = "" AndAlso Not Session.UserSecurity.HasAccess("APPROVAL_F3") Then
                    lockedMessage = "Only Reconcilor administrators are able to approve F3 data."
                End If
            End If

            ' Check for F2, Must have all F2 data approved.
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, _
             Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F2Factor") Then
                lockedMessage = "All F2 data for this site must be approved."
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
            Dim oreShippedResult As CalculationResult = GetCacheCalcResult(Session.GetCachePortOreShipped(), "OreShipped", "Ore Shipped")
            Dim miningModelShippingEquivalentResult As CalculationResult = Calculation.Create(CalcType.MiningModelShippingEquivalent, Session, Me).Calculate()
            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.PerformCalculation(oreShippedResult, miningModelShippingEquivalentResult, CalculationType.Difference)

            For Each differenceDate In difference.AggregateRecords(onMaterialTypeId := False, onLocationId := False, onProductSize := False)
                Result.Tags.Add(New CalculationResultTag("TonnesDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Tonnes)))

                For Each gradeName As String In CalculationResultRecord.GradeNames
                    Result.Tags.Add(New CalculationResultTag(gradeName + "Difference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.GetGrade(gradeName))))
                Next

            Next
        End Sub
    End Class
End Namespace
