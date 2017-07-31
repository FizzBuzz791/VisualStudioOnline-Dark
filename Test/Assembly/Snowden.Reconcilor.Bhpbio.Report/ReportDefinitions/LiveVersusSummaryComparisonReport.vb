Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Linq.Expressions
Imports System.Collections.Generic

Namespace ReportDefinitions
    Public Class LiveVersusSummaryComparisonReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal liveSession As Types.ReportSession, ByVal summarySession As Types.ReportSession, ByVal locationId As Int32?, _
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As ReportBreakdown) As DataTable
            Dim parentLocation As Int32 = liveSession.DalUtility.GetBhpbioLocationRoot()
            Dim locations As Dictionary(Of Int32, Location)

            If Not (dateBreakdown = ReportBreakdown.Monthly Or dateBreakdown = ReportBreakdown.CalendarQuarter) Then
                Throw New NotSupportedException("Only MONTH/QUARTER are supported for this report.")
            End If

            ' Get the parentLocation and the location names.
            If locationId Is Nothing Then
                parentLocation = liveSession.DalUtility.GetBhpbioLocationRoot()
            Else
                parentLocation = locationId.Value
            End If
            locations = GetLocationNamesWithOverride(liveSession, parentLocation, dateFrom, dateTo)

            ' First get results based on live data
            Dim liveLocationDataTable As DataTable
            liveLocationDataTable = F1F2F3ReportEngine.GetFactorsForLocations(liveSession, dateFrom, dateTo, locations, False)

            ' The get results based on approved data
            Dim summaryLocationDataTable As DataTable
            summaryLocationDataTable = F1F2F3ReportEngine.GetFactorsForLocations(summarySession, dateFrom, dateTo, locations, False)

            ' Then combine results
            Dim locationDataTable As DataTable
            locationDataTable = CombineLiveAndSummaryData(liveLocationDataTable, summaryLocationDataTable)

            Return locationDataTable
        End Function

        ''' <summary>
        ''' Combines Live and Summary data into a table
        ''' </summary>
        ''' <param name="liveLocationDataTable">the live data</param>
        ''' <param name="summaryLocationDataTable">the summary data</param>
        ''' <returns>Newly combined data table</returns>
        ''' <remarks>This method is used to prepare comparison data</remarks>
        Private Shared Function CombineLiveAndSummaryData(ByVal liveLocationDataTable As DataTable, ByVal summaryLocationDataTable As DataTable) As DataTable


            Dim comparisonColumns As New List(Of String)(New String() {"Tonnes", "Volume"})
            comparisonColumns.AddRange(CalculationResultRecord.GradeNames)

            Dim combinedDataTable As DataTable = liveLocationDataTable.Copy()

            Dim dataEnumerator As IEnumerator(Of DataRow) = CType(combinedDataTable.Rows.GetEnumerator(), IEnumerator(Of DataRow))
            Dim summaryEnumerator As IEnumerator(Of DataRow) = CType(summaryLocationDataTable.Rows.GetEnumerator(), IEnumerator(Of DataRow))
            Dim summaryRow() As DataRow
            Dim expression As String

            Dim tagIdColumnIndex As Integer = combinedDataTable.Columns.IndexOf("TagId")
            Dim locationIdColumnIndex As Integer = combinedDataTable.Columns.IndexOf("LocationId")
            Dim calendarDateColumnIndex As Integer = combinedDataTable.Columns.IndexOf("CalendarDate")


            While (dataEnumerator.MoveNext())
                expression = String.Format("TagId = '{0}' and LocationId = {1} and CalendarDate = '{2}'", _
                    dataEnumerator.Current(tagIdColumnIndex), dataEnumerator.Current(locationIdColumnIndex), dataEnumerator.Current(calendarDateColumnIndex))
                summaryRow = summaryLocationDataTable.Select(expression)

                If summaryRow.Count > 0 Then
                    For Each columnName As String In comparisonColumns
                        UpdateComparisonValue(dataEnumerator.Current, summaryRow(0), columnName)
                    Next
                End If
            End While

            Return combinedDataTable
        End Function

        ''' <summary>
        ''' Compare column values across 2 rows and change the column value in the first to represent the proportional difference between the 2
        ''' </summary>
        ''' <param name="firstRow">the first row</param>
        ''' <param name="secondRow">the second row</param>
        ''' <param name="columnName">the column to compare</param>
        ''' <remarks>this is used to support variation reporting</remarks>
        Private Shared Sub UpdateComparisonValue(ByVal firstRow As DataRow, ByVal secondRow As DataRow, ByVal columnName As String)

            Dim firstValue As Double? = Nothing
            Dim secondValue As Double? = Nothing

            Dim firstValueObject As Object
            Dim secondValueObject As Object

            firstValueObject = firstRow(columnName)
            secondValueObject = secondRow(columnName)

            If Not firstValueObject Is Nothing And Not IsDBNull(firstValueObject) Then
                firstValue = CType(firstValueObject, Double)
            End If

            If Not secondValueObject Is Nothing And Not IsDBNull(secondValueObject) Then
                secondValue = CType(secondValueObject, Double)
            End If

            Dim difference As Double? = firstValue - secondValue
            Dim proportionalDifference As Double? = (difference / secondValue) + 1

            If proportionalDifference Is Nothing Then
                ' do this because it is the standard way that the factors show 'null' values
                ' The absolute difference should still be null though, if one of the components was
                ' null
                proportionalDifference = 0.0
            End If

            firstRow(columnName) = proportionalDifference

            If difference Is Nothing Then
                firstRow(columnName + "Difference") = DBNull.Value
            Else
                firstRow(columnName + "Difference") = difference
            End If

        End Sub

        ''' <summary>
        ''' Retrieves a dictionary of all the location ids, location definitons of the supplied parent id and its childrend.
        ''' </summary>
        Private Shared Function GetLocationNamesWithOverride(ByVal session As ReportSession, _
          ByVal parentLocation As Int32, ByVal dateFrom As Date, ByVal dateTo As Date) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            ' Get parent location
            'locationNames = GetParentLocationName(session, parentLocation)
            locationNames = GetParentLocationNameWithOverride(session, parentLocation,dateFrom,dateTo)

            ' Get child locations
            locationTable = session.DalUtility.GetBhpbioLocationChildrenNameWithOverride(parentLocation, dateFrom, dateTo)

            For Each row As DataRow In locationTable.Rows
                locationNames.Add(Convert.ToInt32(row("Location_Id")), New Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString(), row("Location_Type_Description").ToString()))
            Next

            Return locationNames
        End Function

        ''' <summary>
        ''' Retrieves a dictionary of all the location ids, location definitons of the supplied parent id and its childrend.
        ''' </summary>
        Private Shared Function GetLocationNames(ByVal session As ReportSession, _
          ByVal parentLocation As Int32) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            ' Get parent location
            locationNames = GetParentLocationName(session, parentLocation)

            ' Get child locations
            locationTable = session.DalUtility.GetLocationList(DoNotSetValues.Int16, _
                parentLocation, DoNotSetValues.Int32, DoNotSetValues.Int16, 1)

            For Each row As DataRow In locationTable.Rows
                locationNames.Add(Convert.ToInt32(row("Location_Id")), New Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString(), row("Location_Type_Description").ToString()))
            Next

            Return locationNames
        End Function

        Private Shared Function GetParentLocationNameWithOverride(ByVal session As ReportSession, _
                                    ByVal parentLocationId As Int32, _
                                    ByVal dateFrom As Date, _
                                    ByVal dateTo As Date) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            locationTable = session.DalUtility.GetBhpbioLocationNameWithOverride(parentLocationId, dateFrom, dateTo)
            For Each row As DataRow In locationTable.Rows
                locationNames.Add(Convert.ToInt32(row("Location_Id")), New Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString, row("Location_Type_Description").ToString()))
            Next

            Return locationNames
        End Function

        Private Shared Function GetParentLocationName(ByVal session As ReportSession, _
                                                      ByVal parentLocationId As Int32) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            locationTable = session.DalUtility.GetLocationList(DoNotSetValues.Int16, _
                                                               DoNotSetValues.Int32, parentLocationId, DoNotSetValues.Int16)
            For Each row As DataRow In locationTable.Rows
                locationNames.Add(Convert.ToInt32(row("Location_Id")), New Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString, row("Location_Type_Description").ToString()))
            Next

            Return locationNames
        End Function
    End Class
End Namespace
