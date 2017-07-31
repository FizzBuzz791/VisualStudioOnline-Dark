Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc

    Public NotInheritable Class OreForRail
        Inherits CalculationBasic

        Public Const CalculationId As String = "OreForRail"
        Public Const CalculationDescription As String = "Ore For Rail"

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

        Protected Overrides ReadOnly Property GetCache() As Cache.DataCache
            Get
                Return Session.GetCacheOreForRail()
            End Get
        End Property

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            ' the grades for OFR are not considered valid - we want to null them out. This should flow up and null out the
            ' F2.5 grades as well
            For Each record In result
                For Each gradeName In CalculationResultRecord.GradeNames
                    record.SetGrade(gradeName, Nothing)
                Next
            Next

            Return result
        End Function
    End Class

End Namespace
