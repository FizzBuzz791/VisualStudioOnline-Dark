Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc

    Public MustInherit Class CalculationBasic
        Inherits Calculation

        Protected Overrides ReadOnly Property ResultType() As CalculationResultType
            Get
                Return CalculationResultType.Tonnes
            End Get
        End Property

        ''' <summary>
        ''' Basic Calculation Function which is to return the data set the needs processing.
        ''' </summary>
        Protected MustOverride ReadOnly Property GetCache() As Cache.DataCache

        ''' <summary>
        ''' Processes a basic cache data and assigns it to the calculation.
        ''' </summary>
        Protected Overrides Sub SetupOperation()
            Dim result As CalculationResult
            Dim cache As Cache.DataCache
            cache = GetCache()

            result = Types.CalculationResult.ToCalculationResult(cache.RetrieveData(), _
                 Session.RequestParameter.StartDate, Session.RequestParameter.EndDate, _
                 Session.RequestParameter.DateBreakdown)

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, result))
        End Sub
    End Class
End Namespace
