Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

''' <summary>
''' Identifies reporting combinations of interest based on reporting thresholds, the existence of outliers, error contributions and other logic
''' </summary>
Public Class CombinationOfInterestIdentifier
    Implements ICombinationOfInterestIdentifier

    Private _session As ReportSession

    Public Sub New(ByVal session As Types.ReportSession, ByVal maximumContributors As Integer, ByVal mininumErrorContribution As Double)
        _session = session
        _MaximumContributors = maximumContributors
        _MininumErrorContribution = mininumErrorContribution
    End Sub
    Public ReadOnly Property MaximumContributors As Integer Implements ICombinationOfInterestIdentifier.MaximumContributors

    Public ReadOnly Property MininumErrorContribution As Double Implements ICombinationOfInterestIdentifier.MininumErrorContribution


    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the existence of identified outliers
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify combinations of interest</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the period for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByOutlier(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest) Implements ICombinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier

        Dim combinationList As New List(Of CombinationOfInterest)()
        Dim endDate = GetEndDate(periodStart, dateBreakdown)

        If (dateBreakdown = ReportBreakdown.Monthly) Then
            ' monthly is the only breakdown that can possibly have outliers... for other breakdowns there is no need to attempt a lookup

            Dim outlierDataTable = _session.DalApproval.GetBhpbioOutliersForLocation(Nothing, periodStart, endDate, locationId, CalculationConstants.PRODUCT_SIZE_TOTAL, Nothing, 0D, includeDirectSubLocations:=False, includeAllSubLocations:=False, excludeTotalMaterialDuplicates:=False, includeAllPoints:=False)

            If (Not outlierDataTable Is Nothing) Then

                For Each analyte In analyteList
                    ' test whether an outlier exists for this combination
                    Dim matchingOutlier = outlierDataTable.Select(String.Format("LocationId = {0} And CalculationId = '{1}' And MaterialTypeId Is Null And Attribute = '{2}'", locationId, factorCalculationId, analyte)).FirstOrDefault()

                    If (Not matchingOutlier Is Nothing) Then
                        combinationList.Add(New CombinationOfInterest(factorCalculationId, locationId, analyte, periodStart))
                    End If
                Next
            End If
        End If

        Return combinationList

    End Function


    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the factor values and the tolerances defined for each analyte
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify analytes of interest</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the period for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByFactorThreshold(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest) Implements ICombinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold

        Dim combinationOfInterestList = New List(Of CombinationOfInterest)

        ' find the tolerances per analyte
        ' this will be required to determine which analytes are of interest
        Dim attributes = Data.GradeProperties.GetFAttributeProperties(_session, locationId)
        Dim endDate = GetEndDate(periodStart, dateBreakdown)

        _session.CalculationParameters(periodStart, endDate, locationId, childLocations:=False)
        _session.IncludeProductSizeBreakdown = False
        _session.IncludeResourceClassification = False

        Dim tableOptions = New DataTableOptions With {
            .DateBreakdown = dateBreakdown,
            .IncludeSourceCalculations = True,
            .GroupByLocationId = False
        }

        ' calculate the factor values for the location
        Dim calcSet = Types.CalculationSet.CreateForCalculations(_session, New String() {factorCalculationId})
        Data.DateBreakdown.AddDateText(dateBreakdown, calcSet)

        ' perform the factor calculation
        Dim table = calcSet.ToDataTable(_session, tableOptions)

        ' normalize the table
        table.AsEnumerable.SetFieldIfNull("LocationId", locationId)
        F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(table)
        F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)

        ' find the table row that equates to this factor
        Dim factorRow = table.Select(String.Format("CalcId = '{0}' And ProductSize = '{1}' And MaterialTypeId IS NULL", factorCalculationId, CalculationConstants.PRODUCT_SIZE_TOTAL)).FirstOrDefault()

        If (Not (factorRow Is Nothing)) Then

            ' iterate over each analyte
            For Each analyte As String In analyteList

                ' get the threshold information required to determine whether a value is out of tolerance
                Dim thresholdRow = attributes.Select(String.Format("ThresholdTypeId = '{0}' And  FieldName = '{1}'", factorCalculationId, analyte)).FirstOrDefault()

                If (Not (thresholdRow Is Nothing)) Then
                    Dim lowThreshold As Double = thresholdRow.AsDbl("LowThreshold")
                    Dim absoluteThreshold As Boolean = thresholdRow.AsBool("AbsoluteThreshold")

                    Dim combinationIsOfInterest As Boolean = False

                    If (absoluteThreshold) Then
                        ' get the difference value
                        Dim differenceColumnName = String.Format("{0}Difference", analyte)

                        If (factorRow.Table.Columns.Contains(differenceColumnName)) Then
                            ' a difference value for the absolute check exists
                            ' check the tolerance based on absolute difference
                            If (Not factorRow.IsNull(differenceColumnName)) Then
                                Dim diff As Double = factorRow.AsDbl(differenceColumnName)

                                If (Math.Abs(diff) >= lowThreshold) Then
                                    combinationIsOfInterest = True
                                End If
                            End If
                        End If
                    Else
                        ' whether the factor value is out of tolerance
                        If (Not factorRow.IsNull(analyte)) Then
                            Dim factorValue As Double = factorRow.AsDbl(analyte)

                            If (Math.Abs(factorValue - 1.0) >= (lowThreshold / 100.0)) Then
                                combinationIsOfInterest = True
                            End If
                        End If
                    End If

                    If (combinationIsOfInterest) Then
                        combinationOfInterestList.Add(New CombinationOfInterest(calculationId:=factorCalculationId, locationId:=locationId, analyte:=analyte, periodStart:=periodStart))
                    End If
                End If
            Next
        End If

        Return combinationOfInterestList
    End Function

    ''' <summary>
    ''' Determines what analytes are of interest for a location and factor based on the error contribution from child locations
    ''' </summary>
    ''' <param name="locationId">the id of the location for which to identify combinations of interest.  The child locations of this location will be checked</param>
    ''' <param name="dateBreakdown">indicates the date granularity to be used for the check (whether monthly or quarterly)</param>
    ''' <param name="periodStart">the period for which combinations of interest are to be identified</param>
    ''' <param name="factorCalculationId">Identifies the factor to be checked</param>
    ''' <param name="analyteList">a list of analytes to be checked</param>
    ''' <returns>A list of the combinations of interest that have been identified</returns>
    Function GetCombinationsOfInterestByErrorContribution(ByVal locationId As Int32, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, ByVal factorCalculationId As String, ByVal analyteList As List(Of String)) As List(Of CombinationOfInterest) Implements ICombinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution

        Dim combinationOfInterestList = New List(Of CombinationOfInterest)

        If (MaximumContributors = 0) Then
            ' max contributors is 0.. in which case there is no possibility of adding any combinations of interest
            Return combinationOfInterestList
        End If

        Dim endDate = GetEndDate(periodStart, dateBreakdown)
        Dim report = New ReportDefinitions.F1F2F3ReconciliationByAttributeReport

        ' get the error contribution data required for this calculation
        Dim data As DataTable = report.GetContributionData(_session, -1, locationId, periodStart, endDate, dateBreakdown, True, False)
        data.AcceptChanges()

        ' iterate through each analyte
        For Each analyte In analyteList
            ' get the contributing locations order by the absolute factor error contribution percent
            Dim contributingRows = data.Select(String.Format("CalcId = '{0}' And LocationId <> {1} And ProductSize = '{2}' AND MaterialTypeId IS NULL AND Attribute = '{3}' AND NOT FactorErrorContributionPct IS NULL AND NOT LocationId IS NULL", factorCalculationId, locationId, CalculationConstants.PRODUCT_SIZE_TOTAL, analyte)).ToList()

            Dim contributorCount As Integer = 0

            For Each row In contributingRows.OrderByDescending(Function(r As DataRow) Math.Abs(r.AsDbl("FactorErrorContributionPct")))
                Dim contribution = Math.Abs(row.AsDbl("FactorErrorContributionPct"))

                If (contribution < MininumErrorContribution) Then
                    ' this contributor is below the threshold, and because we have ordered descending by absolute contribution, so will all the rest in our list.. no point continuing
                    Exit For
                End If

                ' this location can be included
                Dim contributingLocationId = row.AsInt("LocationId")

                combinationOfInterestList.Add(New CombinationOfInterest(calculationId:=factorCalculationId, locationId:=contributingLocationId, analyte:=analyte, periodStart:=periodStart))

                ' increment the count of contributors found
                contributorCount = contributorCount + 1
                If (contributorCount >= MaximumContributors) Then
                    ' we have reached the maximum contributors to include
                    ' no need to continue for this analyte
                    Exit For
                End If
            Next
        Next

        Return combinationOfInterestList

    End Function

#Region "Support Methods"


#End Region


End Class
