Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ModelGradeControlSTGM
        Inherits CalculationModel

        Public Const CalculationId As String = "GradeControlSTGM"
        Public Const CalculationDescription As String = "Grade Control with STM"
        Public Const BlockModelName = "Grade Control STGM"

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

        Public Overloads Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As ModelGradeControlSTGM
            Return CType(CalculationModel.CreateWithGeometType(CalcType.ModelGradeControlSTGM, session, geometType), ModelGradeControlSTGM)
        End Function


    End Class
End Namespace
