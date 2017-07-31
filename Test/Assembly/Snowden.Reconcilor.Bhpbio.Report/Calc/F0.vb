Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class F0
        Inherits Calculation
        Implements IAllMaterialTypesCalculation

        Public Const CalculationId As String = "F0Factor"
        Public Const CalculationDescription As String = "F0.0 - Mining Model / Geology Model"

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

            Dim miningModelCalc As Calc.IAllMaterialTypesCalculation =
                DirectCast(Calculation.Create(CalcType.ModelMining, Session), Calc.IAllMaterialTypesCalculation)
            Dim geologyModelCalc As Calc.IAllMaterialTypesCalculation =
                DirectCast(Calculation.Create(CalcType.ModelGeology, Session), Calc.IAllMaterialTypesCalculation)

            geologyModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes
            miningModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes

            Dim geologyModelResult As CalculationResult = DirectCast(geologyModelCalc, Calc.ICalculation).Calculate()
            Dim miningModelResult As CalculationResult = DirectCast(miningModelCalc, Calc.ICalculation).Calculate()

            geologyModelResult.PrefixTagId("F0")
            miningModelResult.PrefixTagId("F0")

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, miningModelResult))
            Calculations.Add(New CalculationOperation(CalculationStep.Divide, geologyModelResult))
        End Sub

        Protected Sub SetPresentation()
            Dim validLocationType As String = "PIT"
            Dim lockedMessage As String = ""
            Dim calcResult As CalculationResult
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility,
             Session.RequestParameter.LocationId)


            ' Check for F15 to stop it being editable. Must have no F15 approved.
            If Report.Data.ApprovalData.IsAnyTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F15Factor") Then
                lockedMessage = "F1.5 Data has already been approved."
            End If

            ' Check for F2 to stop it being editable. Must have no F2 approved.
            '
            ' Normally this would never get executed, because if F2 is approved F1.5 must be approved as well. However
            ' that is not the case with historical months, before the F1.5 was introduced
            If lockedMessage = "" AndAlso Report.Data.ApprovalData.IsAnyTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F2Factor") Then
                lockedMessage = "F2 Data has already been approved."
            End If

            ' Must have the geo model approved before F1 can be approved. Note that in the db the geo model is part of the
            ' F1 Tag group for some reason, so we have to pass through the eact tag Id as well to find out if it is approved.
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F1Factor", "F1GeologyModel") Then
                lockedMessage = "All Geology Model data for this pit must be approved."
            End If

            ' All other movements have to be approved before F1 can be approved
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.IsAllTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "OtherMaterial") Then
                lockedMessage = "All Other Material Movement data for this pit must be approved."
            End If

            Report.Data.ApprovalData.AssignEditableOnLocationType(Session.DalUtility, Result.GetAllCalculations(),
                validLocationType, Session.RequestParameter.LocationId)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationLocked",
                 GetType(String), lockedMessage))
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid",
                 GetType(Boolean), True))
            Next
        End Sub

        Protected Overrides Sub ProcessTags()
            Dim difference As CalculationResult
            Dim differenceDate As CalculationResultRecord

            Dim miningModelCalc As Calc.CalculationModel = DirectCast(Calculation.Create(CalcType.ModelMining, Session), Calc.CalculationModel)
            Dim geologyModelCalc As Calc.CalculationModel = DirectCast(Calculation.Create(CalcType.ModelGeology, Session), Calc.CalculationModel)

            geologyModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes
            miningModelCalc.IncludeAllMaterialTypes = Me.IncludeAllMaterialTypes

            Dim geologylModelResult As CalculationResult = geologyModelCalc.Calculate()
            Dim modelResult As CalculationResult = miningModelCalc.Calculate()

            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()

            difference = CalculationResult.Difference(geologylModelResult, modelResult)

            For Each differenceDate In difference.AggregateRecords(True, False, False, False)
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
