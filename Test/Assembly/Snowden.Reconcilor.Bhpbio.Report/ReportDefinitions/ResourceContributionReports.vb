Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace ReportDefinitions

    Public Class ResourceContributionReports
        Inherits ReportBase

        Private Const MaxSubLocations = 15
        Private Const SmallContributorsThreshold = 0.005

        Public Shared ResourceClassificationFieldNames As String() = Data.ResourceClassifcation.ResourceClassificationFields

        Public Shared Function GetErrorContributionDataForLocation(session As ReportSession, locationId As Integer, dateFrom As DateTime, dateTo As DateTime, factorList As String(), includeChildLocation As Boolean) As DataTable
            session.CalculationParameters(dateFrom, dateTo, locationId, includeChildLocation)
            Dim calcSet = CalculationSet.CreateForCalculations(session, factorList)
            Dim table = calcSet.ToDataTable(session, New DataTableOptions With {.DateBreakdown = ReportBreakdown.None, .IncludeSourceCalculations = True})
            F1F2F3SingleCalculationReport.RecalculateDifferences(table)

            If Not includeChildLocation Then
                table.AsEnumerable.SetField("LocationId", locationId)
            End If

            ' delete any rows with no location set. We only want sublocations in this case, and sometimes 
            ' we will end up with data from the parent locations in the calc set no matter what
            table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId")).DeleteRows()

            ' if we are getting the child locations, then delete any rows that have the location_id of the parent. These will sometimes
            ' get sent through by the db methods
            If includeChildLocation Then
                table.AsEnumerable.Where(Function(r) r.AsInt("LocationId") = locationId).DeleteRows()
            End If

            ' also delete any rows where the date from and date to are at Date.Min. Not sure why these rows appear, but they
            ' cause the factor recalculation to break
            table.AsEnumerable.Where(Function(r) r.AsDate("DateFrom") = Date.MinValue).DeleteRows()

            Return table
        End Function

        Public Shared Function GetErrorContextContributionReportData(session As ReportSession,
                                                                     locationId As Integer, dateFrom As DateTime, dateTo As DateTime,
                                                                     breakdownLocationType As String,
                                                                     attributeList As String(), factorList As String()) As DataTable

            Dim result As DataTable = Nothing
            Dim subLocationList = GetSubLocationListOfType(session, locationId, breakdownLocationType, dateFrom)
            Dim locationIdList = subLocationList.Select(Function(l) l.LocationId).ToList

            ' we need to get the parent location first, for some reason this is needed to calc the error contribution
            session.IncludeProductSizeBreakdown = False
            result = GetErrorContributionDataForLocation(session, locationId, dateFrom, dateTo, factorList, includeChildLocation:=False)

            ' now we need to get the sublocations
            For Each location In subLocationList
                Dim table = GetErrorContributionDataForLocation(session, location.LocationId, dateFrom, dateTo, factorList, includeChildLocation:=True)
                result.Merge(table)
            Next

            ' the breakdown used to get the list of sublocations to query is different to the breakdown that we
            ' need for getting the list of location names to fill out the table. The 'AddLocationData' method will
            ' still work without this parameter, but it makes it much faster at the higher levels
            Dim lowestLocationType As String = LowestPossibleLocationType(session, breakdownLocationType)

            BlockOutSummaryReport.AddLocationData(session, result, locationId, dateFrom, lowestLocationType)

            ' in order to handle some edge cases where the location heirachy has changed between the dateFrom and
            ' dateTo we remove any locations that couldn't have their name resolved.
            '
            ' We also have situations where the forward estimates don't properly handle the changing location heirachy,
            ' so we want this stuff to be removed as well.
            result.AsEnumerable.Where(Function(r) r.AsString("LocationName").ToUpper() = "UNKNOWN").DeleteRows()

            ' unpivot the table
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(result)
            F1F2F3ReportEngine.UnpivotDataTable(result, maintainTonnes:=True)

            ' add the required attributes stuff to calculate the error contribution
            Data.ReportColour.AddLocationColor(session, result)
            F1F2F3ReportEngine.AddAttributeIds(result)
            ErrorContributionEngine.AddErrorContributionByLocation(result, locationId)

            ' get rid of attributes and calculations we don't need
            ' we couldn't do this until now, because they might have been needed in the intermediate 
            ' calculations
            F1F2F3ReportEngine.FilterTableByAttributeList(result, attributeList)
            F1F2F3ReportEngine.FilterTableByFactors(result, factorList)

            ' in the header of the reports we need to show the factor value of the header. We could do this lookup in SSRS,
            ' but its a lot easier to do it in .net and add it into a new field
            F1F2F3ReportEngine.AddAttributeValueFormat(result)
            AddParentFactorValues(result, locationId)

            ' now we need to filter the list to get the top N rows, as we don't want the report to get flooded with too many
            ' sublocations, unlike the other (RC context) section of the report, where we can use the tonnes only, across the
            ' whole table, this time we have to do it on a calculation and attribute basis, and take only the top N based on the 
            ' abs error contribution pct
            AddOtherGrouping(result, factorList, attributeList, locationId)

            ' we need fix any null LocationColor fields, because if the first record happens to be empty, none of the colors will
            ' get set on the client. However, we still need to detect these NONE values and turn them back into Nothing on the client,
            ' other otherwise the automatic colors will not work.
            '
            ' At the pit level all the locations should have a color, because they are configured by the user on the utilities page,
            ' but for the benches that is not the case, and they need to have their colors assigned automatically
            result.AsEnumerable.Where(Function(r) r.IsNull("LocationColor")).SetField("LocationColor", "NONE")
            result.AsEnumerable.Where(Function(r) r.IsNull("FactorErrorContributionPct")).DeleteRows()

            ' we need to add the undercall and overcall rows. These need to be separate rows so that the labels display at the
            ' top (or bottom) of the column on the reports. In the RC context section we use the ResourceClassificationTotal
            ' group to do this, as it doesn't need to be shown on the report otherwise. In this dataset we are not so lucky
            ' unfortunately, so we have to add a new set of rows manually
            result = AddUnderOverCallRecords(result, attributeList, factorList)

            Return result
        End Function

        ' because there are a few different ways that the location breakdown can happen, we use this method to tell us
        ' what the lowest location type in the data will be. It doesn't guarentee that this location type *will* be in the data
        ', just that there will be nothing under that
        Public Shared Function LowestPossibleLocationType(session As ReportSession, sublocationLocationType As String) As String
            If session.OverrideModelDataLocationTypeBreakdown IsNot Nothing Then
                Return session.OverrideModelDataLocationTypeBreakdown
            Else
                ' this is the location type sent to the calc set with 'includeChildren' on, so the min location
                ' will be one under that
                Select Case sublocationLocationType
                    Case "Pit" : Return "Bench"
                    Case "Bench" : Return "Blast"
                    Case "Blast" : Return "Blast"
                    Case Else : Return "Pit"
                End Select
            End If
        End Function

        Public Shared Function AddOtherGrouping(table As DataTable, factorList As String(), attributeList As String(), locationId As Integer) As DataTable
            For Each attributeName In attributeList
                For Each factor In factorList
                    Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("Attribute") = attributeName AndAlso r.AsString("ReportTagId") = factor AndAlso r.AsInt("LocationId") <> locationId)
                    Dim locationsToKeep = rows.OrderByDescending(Function(r) Math.Abs(r.AsDbl("FactorErrorContributionPct"))).Take(MaxSubLocations).Select(Function(r) r.AsInt("LocationId"))
                    Dim locationsToAggregate = rows.AsEnumerable.Where(Function(r) Not locationsToKeep.Contains(r.AsInt("LocationId"))).ToList

                    ' only group the small contributors if there is a minimum number of locations
                    If locationsToKeep.Distinct.Count >= 8 Then
                        Dim smallContributors = rows.AsEnumerable.Where(Function(r) Math.Abs(r.AsDbl("FactorErrorContributionPct")) < SmallContributorsThreshold).ToList
                        locationsToAggregate.AddRange(smallContributors)
                    End If

                    For Each row In locationsToAggregate
                        If row.AsDblN("FactorErrorContributionPct") > 0 Then
                            row("LocationId") = -1
                            row("LocationName") = "Other (+ve)"
                            row("LocationColor") = "#D0D0D0"
                        Else
                            row("LocationId") = -2
                            row("LocationName") = "Other (-ve)"
                            row("LocationColor") = "#D0D0D0"
                        End If

                    Next
                Next
            Next

            Return table
        End Function

        Public Shared Function AddParentFactorValues(table As DataTable, parentLocatinId As Integer) As DataTable
            table.Columns.AddIfNeeded("ParentFactorValue", GetType(Double))

            For Each row As DataRow In table.Rows
                Dim parentRow = table.AsEnumerable.FirstOrDefault(Function(r) r.AsString("ReportTagId") = row.AsString("ReportTagId") AndAlso
                                                              r.AsString("Attribute") = row.AsString("Attribute") AndAlso
                                                              r.AsInt("LocationId") = parentLocatinId)

                If parentRow IsNot Nothing AndAlso parentRow.HasValue("AttributeValue") Then
                    row("ParentFactorValue") = parentRow.AsDbl("AttributeValue")
                End If
            Next

            Return table
        End Function

        Public Shared Function AddUnderOverCallRecords(table As DataTable, attributeList As String(), factorList As String()) As DataTable
            ' we will set the error contribution pct to zero, so the bar has no thickness, set the attributeValue to the
            ' under/overcall percentages
            For Each attributeName In attributeList
                For Each factor In factorList
                    ' each row should be a separate location, but the code should still work properly even if that doesn't turn out to be the 
                    ' case
                    Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("Attribute") = attributeName AndAlso r.AsString("ReportTagId") = factor AndAlso r.HasValue("FactorErrorContributionPct")).ToList

                    ' extract the error contribution percentages, and then ge the total undercall and overcall, so
                    ' we can calculate those labels as well
                    Dim errorPcts = rows.AsEnumerable.Select(Function(r) r.AsDbl("FactorErrorContributionPct"))
                    Dim totalUnderCall = errorPcts.Where(Function(v) v < 0).Sum()
                    Dim totalOverCall = errorPcts.Where(Function(v) v >= 0).Sum()

                    For Each row In rows
                        Dim locationRows = rows.Where(Function(r) r.AsInt("LocationId") = row.AsInt("LocationId"))

                        If locationRows.Count > 1 Then


                            Dim labelCount = table.AsEnumerable.Where(Function(r) r.AsString("Attribute") = attributeName AndAlso
                                                     r.AsString("ReportTagId") = factor AndAlso
                                                     r.HasValue("FactorErrorContributionPct") AndAlso
                                                      r.AsInt("LocationId") = row.AsInt("LocationId") AndAlso
                                                      r.AsString("TagId") = "UnderOverLabel").Count

                            ' we only want one label added per location, otherwise the y-axis will not scale properly
                            ' because there will be a bunch of invisible stacked labels
                            If labelCount > 0 Then
                                Continue For
                            End If
                        End If

                        Dim errorContribution = locationRows.Sum(Function(r) r.AsDbl("FactorErrorContributionPct"))
                        Dim totalError = If(errorContribution < 0, totalUnderCall, totalOverCall)

                        Dim newRow = row.CloneFactorRow()
                        newRow("FactorErrorContributionPct") = If(errorContribution < 0, -0.05, 0.05)
                        newRow("TagId") = "UnderOverLabel"

                        If table.Columns.Contains("LocationColor") Then
                            newRow("LocationColor") = "Transparent"
                        End If

                        If table.Columns.Contains("PresentationColor") Then
                            newRow("PresentationColor") = "Transparent"
                        End If

                        If totalError <> 0 Then
                            Dim contribution = errorContribution / totalError
                            newRow("AttributeValue") = contribution
                            newRow("Description") = String.Format("{0:P1}", contribution)
                        Else
                            ' i think this can never happen, but might as well put it in to be safe
                            newRow("AttributeValue") = 0.0
                            newRow("Description") = ""
                        End If

                    Next
                Next
            Next

            Return table
        End Function

        Public Shared Function GetResourceContextReportData(session As ReportSession, ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, breakdownLocationType As String, attributeList As String()) As DataTable

            Dim result As DataTable = Nothing

            ' this will give us all locations under the current one, down to the Pit level. Even though we want to report
            ' on benches, we still only need the list of Pits, because we will get the data with sublocations turned on
            Dim subLocationList = GetSubLocationListOfType(session, locationId, breakdownLocationType, dateFrom)

            For Each location In subLocationList
                session.CalculationParameters(dateFrom, dateTo, location.LocationId, True)
                Dim table = F1F2F3SingleCalculationReport.GetResourceClassificationByLocation(session, "GradeControlModel")
                F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)

                If (result Is Nothing) Then
                    result = table
                Else
                    result.Merge(table)
                End If

            Next

            ' the report is only supposed to contain the top 15 locations (in terms of tonnes?), so if we have more than
            ' that we need to get rid of some. We use a new list for the locations here, instead of the one from above, 
            ' because we don't know if there was data for all the sublocations - here we care about the unique locations
            ' that are actually in the dataset, not those that were queried for
            BlockOutSummaryReport.AddLocationData(session, result, locationId, dateFrom)
            Dim locationList = result.AsEnumerable.Select(Function(r) r.AsInt("LocationId")).Distinct.ToList

            If locationList.Count > MaxSubLocations Then

                ' ok, this is a bit of a complicated query:
                ' 1. we filter the list to just the total tonnes
                ' 2. reverse order by tonnes
                ' 3. take the first n
                ' 4. get the distinct list of locations in that set of rows
                '
                ' This is the list of locations we want to keep, so we delete all rows that are
                ' not one of those locations
                Dim locationsToKeep = result.AsEnumerable.
                    Where(Function(r) r.AsString("ResourceClassification") = "ResourceClassificationTotal" AndAlso r.AsString("Attribute") = "Tonnes").
                    OrderByDescending(Function(r) r.AsDblN("AttributeValue")).
                    Take(MaxSubLocations).
                    Select(Function(r) r.AsInt("LocationId")).
                    Distinct

                result.AsEnumerable.Where(Function(r) Not locationsToKeep.Contains(r.AsInt("LocationId"))).DeleteRows()

            End If

            Return result
        End Function

        Private Shared Function GetSubLocationListOfType(session As ReportSession, locationId As Integer, locationTypeName As String, locationDate As DateTime) As List(Of ExtendedLocation)
            Dim subLocationList = F1F2F3ReportEngine.GetAllLocationNamesRecursive(session, locationId, locationDate, locationTypeName).Values.ToList
            subLocationList = subLocationList.Where(Function(r) r.LocationType = locationTypeName).ToList

            If subLocationList.Count = 0 Then
                Throw New Exception("Invalid Location Breakdown - no sublocations for " + locationId.ToString)
            End If

            Return subLocationList
        End Function

    End Class

End Namespace

