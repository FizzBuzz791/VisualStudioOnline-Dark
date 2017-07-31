Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ModelGradeControl
        Inherits CalculationModel

        Public Const CalculationId As String = "GradeControlModel"
        Public Const CalculationDescription As String = "Grade Control Model"
        Public Const BlockModelName = "Grade Control"

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

        Public Overloads Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As ModelGradeControl
            Return CType(CalculationModel.CreateWithGeometType(CalcType.ModelGradeControl, session, geometType), ModelGradeControl)
        End Function

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            If MyBase.IncludeAllMaterialTypes Then
                ' this version of the grade control model uses a calculated density. The density we get back from the proc will come from the
                ' grade tables, so we need to recalculate this based off the tonnes and volume. We should only have to do this once, and then
                ' it will aggregate properly up the heirachy
                For Each record In result
                    record.CalculateDensity()
                Next
            End If

            Return result
        End Function

    End Class

End Namespace
