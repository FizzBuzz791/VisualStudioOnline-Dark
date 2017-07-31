''' <summary>
''' Interface supported by classes used to identify reporting combinations of interest
''' </summary>
Public Interface ICombinationOfInterestIdentifier

    ReadOnly Property MaximumContributors As Integer
    ReadOnly Property MininumErrorContribution As Double

    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the existence of identified outliers
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify combinations of interest</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the month for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByOutlier(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest)

    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the factor values and the tolerances defined for each analyte
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify analytes of interest</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the month for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByFactorThreshold(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest)

    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the error contribution from child locations
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify combinations of interest.  The child locations of this location will be checked</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the month for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByErrorContribution(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest)
End Interface
