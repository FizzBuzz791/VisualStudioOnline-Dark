Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class F15
        Inherits Calculation
        Implements IAllMaterialTypesCalculation

        Public Const CalculationId As String = "F15Factor"
        Public Const CalculationDescription As String = "F1.5 - Grade Control Model (with STM) / STM"

        Private _includeAllMaterialTypes As Boolean = False

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

        ''' <summary>
        ''' The block model method now will return all material types, if the appropriate arguments are set. Overriding this properly will decide if non-high grade MTs are filtered out or not.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property IncludeAllMaterialTypes() As Boolean Implements IAllMaterialTypesCalculation.IncludeAllMaterialTypes
            Get
                Return _includeAllMaterialTypes
            End Get
            Set(ByVal value As Boolean)
                _includeAllMaterialTypes = value
            End Set
        End Property

        Protected Overrides Sub SetupOperation()
            Dim gcStgmModelCalc As Calc.IAllMaterialTypesCalculation = _
                DirectCast(Calculation.Create(CalcType.ModelGradeControlSTGM, Session), Calc.IAllMaterialTypesCalculation)
            Dim stgmModelCalc As Calc.IAllMaterialTypesCalculation = _
                DirectCast(Calculation.Create(CalcType.ModelShortTermGeology, Session), Calc.IAllMaterialTypesCalculation)

            gcStgmModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes
            stgmModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes

            Dim gradeControlResult As CalculationResult = DirectCast(gcStgmModelCalc, Calc.ICalculation).Calculate()
            Dim modelResult As CalculationResult = DirectCast(stgmModelCalc, Calc.ICalculation).Calculate()

            gradeControlResult.PrefixTagId("F15")
            modelResult.PrefixTagId("F15")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, gradeControlResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, modelResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "PIT"
            Dim lockedMessage As String = ""
            Dim calcResult As CalculationResult
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, _
             Session.RequestParameter.LocationId)

            ' Check for F2 to stop it being editable. Must have no F2 approved.
            If Report.Data.ApprovalData.IsAnyTagGroupApproved(Session, _
             Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F2Factor") Then
                lockedMessage = "F2 Data has already been approved."
            End If

            ' Check for F1, Must have all F1 data approved.
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F1Factor") Then
                lockedMessage = "All F1 data for this pit must be approved."
            End If

            Report.Data.ApprovalData.AssignEditableOnLocationType(Session.DalUtility, Result.GetAllCalculations(), _
                validLocationType, Session.RequestParameter.LocationId)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationLocked", _
                 GetType(String), lockedMessage))
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", _
                 GetType(Boolean), True))
            Next

            ' the grade control STGM checkbox should always be disabled, its value duplicates the value in the
            ' F1 grade control checkbox
            Dim gradeControlLocked = "These are Grade Control data/blocks that have STGM data associated. Approval status is non-editable as it refers to the Grade Control Model data approval (see above)."
            Me.Result.GetFirstCalcId(Calc.ModelGradeControlSTGM.CalculationId).Tags.Add( _
                New CalculationResultTag("PresentationLocked", GetType(String), gradeControlLocked) _
            )
        End Sub

        Protected Overrides Sub ProcessTags()
            Dim gradeControlResult As CalculationResult = Calculation.Create(CalcType.ModelGradeControlSTGM, Session).Calculate()
            Dim modelResult As CalculationResult = Calculation.Create(CalcType.ModelShortTermGeology, Session).Calculate()

            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.Difference(modelResult, gradeControlResult)

            For Each differenceDate In difference.AggregateRecords(onMaterialTypeId := False, onLocationId := False, onProductSize := False)
                Result.Tags.Add(New CalculationResultTag("TonnesDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Tonnes)))
                Result.Tags.Add(New CalculationResultTag("VolumeDifference", differenceDate.CalendarDate, GetType(Double), ZeroIfNull(differenceDate.Volume)))

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
