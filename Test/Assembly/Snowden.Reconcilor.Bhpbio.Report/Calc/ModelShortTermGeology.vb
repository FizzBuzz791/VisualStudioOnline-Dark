Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ModelShortTermGeology
        Inherits CalculationModel

        Public Const CalculationId As String = "ShortTermGeologyModel"
        Public Const CalculationDescription As String = "Short Term Model"
        Public Const BlockModelName = "Short Term Geology"

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

        Public Overloads Shared Function CreateWithGeometType(session As ReportSession, geometType As GeometTypeSelection) As ModelShortTermGeology
            Return CType(CalculationModel.CreateWithGeometType(CalcType.ModelShortTermGeology, session, geometType), ModelShortTermGeology)
        End Function


    End Class
End Namespace
