Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ModelMining
        Inherits CalculationModel

        Public Const CalculationId As String = "MiningModel"
        Public Const CalculationDescription As String = "Mining Model"
        Public Const BlockModelName = "Mining"

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

        Public Overloads Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As ModelMining
            Return CType(CalculationModel.CreateWithGeometType(CalcType.ModelMining, session, geometType), ModelMining)
        End Function


        Public Overrides Function Calculate() As Types.CalculationResult
            ' for F2.5 and F3 we have to use a different version of the H2O value
            If Me.RootCalculationId = F25.CalculationId Or Me.RootCalculationId = RecoveryFactorMoisture.CalculationId _
                Or Me.RootCalculationId = MiningModelOreForRailEquivalent.CalculationId Then

                H2OOverride = H2OOverideAsDropped
            ElseIf Me.RootCalculationId = F3.CalculationId Or Me.RootCalculationId = MiningModelShippingEquivalent.CalculationId Then
                H2OOverride = H2OOverideAsShipped
            End If
            Return MyBase.Calculate()
        End Function

    End Class
End Namespace
