Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc

    Public NotInheritable Class F25
        Inherits Calculation

        Public Const CalculationId As String = "F25Factor"
        Public Const CalculationDescription As String = "F2.5 - Ore For Rail / Mining Model OFR Equivalent"

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
            Dim oreForRailResult As CalculationResult = Calculation.Create(CalcType.OreForRail, Session, Me).Calculate()
            Dim miningModelOreForRailEquivalentResult As CalculationResult = Calculation.Create(CalcType.MiningModelOreForRailEquivalent, Session, Me).Calculate()

            oreForRailResult.PrefixTagId("F25")
            miningModelOreForRailEquivalentResult.PrefixTagId("F25")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, oreForRailResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, miningModelOreForRailEquivalentResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "HUB"
            Dim lockedMessage As String = String.Empty
            Dim calcResult As CalculationResult

            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, _
                Session.RequestParameter.LocationId)
            Dim valid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, _
                Session.RequestParameter.LocationId, validLocationType)

            If Not Session.UserSecurity Is Nothing Then
                If lockedMessage = "" AndAlso Not Session.UserSecurity.HasAccess("APPROVAL_F25") Then
                    lockedMessage = "Only Reconcilor administrators are able to approve F2.5 data."
                End If
            End If

            ' Check for F2, Must have all F2 data approved.
            If lockedMessage = String.Empty AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, _
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
            Dim oreForRailResult As CalculationResult = Calculation.Create(CalcType.OreForRail, Session, Me).Calculate()
            Dim miningModelOreForRailEquivalentResult As CalculationResult = Calculation.Create(CalcType.MiningModelOreForRailEquivalent, Session, Me).Calculate()
            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.Difference(oreForRailResult, miningModelOreForRailEquivalentResult)

            For Each differenceDate In difference.AggregateRecords(True, False, False, False)
                Result.Tags.Add(New CalculationResultTag("TonnesDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Tonnes)))

                For Each gradeName As String In CalculationResultRecord.GradeNames
                    Result.Tags.Add(New CalculationResultTag(gradeName + "Difference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.GetGrade(gradeName))))
                Next

            Next
        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            ' the grades for F2.5 are not considered valid - we want to null them out
            For Each record In result
                For Each gradeName In CalculationResultRecord.GradeNames
                    record.SetGrade(gradeName, Nothing)
                Next
            Next

            Return result
        End Function
    End Class

End Namespace
