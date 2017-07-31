Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ModelGeology
        Inherits CalculationModel

        Public Const CalculationId As String = "GeologyModel"
        Public Const CalculationDescription As String = "Geology Model"
        Public Const BlockModelName = "Geology"

        Protected Overrides ReadOnly Property CalcId() As String
            Get
                Return GetCalculationIdWithOptionalSuffix(CalculationId)
            End Get
        End Property

        Protected Overrides ReadOnly Property Description() As String
            Get
                Return CalculationDescription
            End Get
        End Property

        Protected Overrides ReadOnly Property ModelName() As String
            Get
                Return BlockModelName
            End Get
        End Property

        Protected Overrides ReadOnly Property DefaultGeometType As GeometTypeSelection
            Get
                Return GeometTypeSelection.AsDropped
            End Get
        End Property

        Protected Overrides Sub ProcessTags()
            For Each parent In Result.GetAllResults()
                parent.Result.Tags.Add(New CalculationResultTag("RootCalcId", GetType(String), Result.CalcId()))
            Next

            SetPresentation()
        End Sub

        Public Overloads Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As ModelGeology
            Return CType(CalculationModel.CreateWithGeometType(CalcType.ModelGeology, session, geometType), ModelGeology)
        End Function

        Protected Sub SetPresentation()
            Dim lockedMessage As String = ""
            Dim validLocationType As String = "PIT"
            Dim calcResult As CalculationResult
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, _
             Session.RequestParameter.LocationId)

            ' Check for F1 to stop it being editable. Must have no F1 approved.
            If Report.Data.ApprovalData.IsAnyTagGroupApproved(Session, Session.RequestParameter.LocationId, Session.RequestParameter.StartDate, "F1Factor") Then
                lockedMessage = "F1 Data has already been approved."
            End If

            ' Note: the check to ensure pits have movements before approval was previously carried out here, but is no longer wanted (as even pits with 0 values need to be approved)

            ' Check for Blast Blocks. Must have all blast blocks approved.
            If lockedMessage = "" AndAlso Not Report.Data.ApprovalData.GetDigblockApprovalValid(Session, _
             Session.RequestParameter.LocationId, Session.RequestParameter.StartDate) Then
                lockedMessage = "Not all Blastblocks for this pit have been approved."
            End If

            Report.Data.ApprovalData.AssignEditableOnLocationType(Session.DalUtility, Result.GetAllCalculations(), _
                validLocationType, Session.RequestParameter.LocationId)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationLocked", _
                 GetType(String), lockedMessage))
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", _
                 GetType(Boolean), True))
            Next
        End Sub
    End Class
End Namespace
