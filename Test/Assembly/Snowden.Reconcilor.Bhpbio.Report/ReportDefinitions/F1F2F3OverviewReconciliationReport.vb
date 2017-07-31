Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Linq.Expressions
Imports System.Linq
Imports System.Data

' these modules add LINQ methods to the datatable + datarow
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports System.Runtime.CompilerServices
Imports Snowden.Reconcilor.Bhpbio.Report.GenericDataTableExtensions

Namespace ReportDefinitions
    Public Class F1F2F3OverviewReconciliationReport
        Inherits ReportBase

        Private Const ColumnLocationId As String = "LocationId"
        Private Const ColumnLocationName As String = "LocationName"
        Private Const ColumnLocationType As String = "LocationType"
        Private Const ColumnTagId As String = "ReportTagId"
        Private Const ColumnDescription As String = "Description"
        Private Const ColumnPresentationValid As String = "PresentationValid"
        Private Const TagF1Factor As String = "F1Factor"
        Private Const TagF2Factor As String = "F2Factor"
        Private Const TagF25Factor As String = "F25Factor"
        Private Const TagF3Factor As String = "F3Factor"

        Public Shared Function GetContributionData(ByVal session As Types.ReportSession, ByVal locationId As Int32?, _
            ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As ReportBreakdown, ByVal f25Required As Boolean) As DataTable

            Dim contributionData As DataTable
            contributionData = F1F2F3OverviewReconciliationReport.GetData(session, locationId, dateFrom, dateTo, dateBreakdown, f25Required, False)

            ' now we need to pivot the thing to get the grade control data assigned to the F1 row, so that it can
            ' be displayed in the report.
            contributionData.Columns.Add("GradeControlValue")
            Dim gradeControlRows As List(Of DataRow) = contributionData.AsEnumerable.Where(Function(r) CType(r("TagId"), String).StartsWith("F1GradeControlModel")).ToList
            For Each row As DataRow In gradeControlRows
                If CType(row("LocationId"), Integer) = locationId Then
                    ' don't add the data for the parent row, as this gives a duplicate sum()
                    Continue For
                End If

                ' we do a replace on the tag id, so that it can handle the lumps and fines properly
                Dim tagId As String = CType(row("TagId"), String).Replace("GradeControlModel", "Factor")
                Dim factorRow As DataRow() = contributionData.Select(String.Format("TagId = '{0}' and LocationId = {1}", tagId, CType(row("LocationId"), Integer)))

                ' we should only get exactly one row back from the select. anything else and we just
                ' ignore it
                If factorRow.Length = 1 Then
                    factorRow(0)("GradeControlValue") = row("Tonnes")
                End If
            Next

            Data.ReportColour.MergePresentationColour(session, contributionData, "LocationId")

            contributionData.Columns.Add("LocationColours", GetType(String))
            For Each row In contributionData.Rows()
                Dim datarow As DataRow = DirectCast(row, DataRow)
                datarow("LocationColours") = datarow("PresentationColor")
            Next

            contributionData.Columns.Add("ComparisonTypeExtended", GetType(String))
            For Each row In contributionData.Rows()
                Dim datarow As DataRow = DirectCast(row, DataRow)
                Select Case Convert.ToString(datarow("ReportTagId"))
                    Case "F1Factor" : datarow("ComparisonTypeExtended") = "F1Factor"
                    Case "F15Factor" : datarow("ComparisonTypeExtended") = "F15Factor"
                    Case "F2Factor" : datarow("ComparisonTypeExtended") = "F2Factor"
                    Case "F25Factor" : datarow("ComparisonTypeExtended") = "F25Factor"
                    Case "F3Factor" : datarow("ComparisonTypeExtended") = "F3Factor"
                    Case Else : datarow("ComparisonTypeExtended") = datarow("LocationId")
                End Select
            Next

            Data.ReportColour.MergePresentationColour(session, contributionData, "ComparisonTypeExtended")

            ' make sure we don't have factors where every value is zero for every location, as this will cause the pie charts to fail
            ' if we have factors like this, we set one row to a very small value (0.00001) and this causes the charts to work. Note
            ' that we can't just set the values to zero (despite the name of the function) as this caues the same error
            contributionData.ZeroFactorValues()

            Return contributionData
        End Function

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal locationId As Int32?,
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal dateBreakdown As ReportBreakdown, ByVal f25Required As Boolean,
         Optional ByVal factorsOnly As Boolean = True) As DataTable

            Dim parentLocation As Int32 = session.DalUtility.GetBhpbioLocationRoot()
            Dim locations As Dictionary(Of Int32, Location)

            ' Get the parentLocation and the location names.
            If locationId Is Nothing Then
                parentLocation = session.DalUtility.GetBhpbioLocationRoot()
            Else
                parentLocation = locationId.Value
            End If
            'locations = GetLocationNames(session, parentLocation)
            locations = GetLocationNamesWithOverride(session, parentLocation, dateFrom, dateTo)

            Dim locationDataTable As DataTable
            locationDataTable = F1F2F3ReportEngine.GetFactorsForLocations(session, dateFrom, dateTo, locations, factorsOnly)

            Return locationDataTable
        End Function


        Public Shared Function GetFactorsAndChildren(ByVal session As Types.ReportSession, ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As DataTable

            Dim table = GetFactorsAndChildren(session, locationId, dateFrom, dateTo, includeChildLocations:=False)
            Dim children = GetFactorsAndChildren(session, locationId, dateFrom, dateTo, includeChildLocations:=True)
            table.Merge(children)

            F1F2F3ReportEngine.AddLocationDataToTable(session, table, locationId)

            If table.Columns.Contains("PresentationValid") Then
                For Each row As DataRow In table.Rows
                    row("PresentationValid") = row.AsBool("PresentationValid") AndAlso F1F2F3ReconciliationByAttributeReport.IsPresentationValid(row)
                Next

                table.AsEnumerable.Where(Function(r) Not r.AsBool("PresentationValid")).DeleteRows()
            End If

            Return table
        End Function


        Public Shared Function GetFactorsAndChildren(ByVal session As Types.ReportSession, ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, includeChildLocations As Boolean) As DataTable

            Dim calcSet = New CalculationSet()
            session.CalculationParameters(dateFrom, dateTo, ReportBreakdown.Monthly, locationId, includeChildLocations)

            calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate())
            calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F15, session).Calculate())
            calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F2, session).Calculate())
            calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F3, session).Calculate())

            Data.ReportColour.AddCalculationColor(session, calcSet)

            Dim table As DataTable = calcSet.ToDataTable(session, New DataTableOptions With {
                                                        .DateBreakdown = ReportBreakdown.None,
                                                        .PivotedResults = True,
                                                        .IncludeSourceCalculations = True,
                                                        .GroupByLocationId = True
                                                    })

            If includeChildLocations Then
                table.DeleteRows(table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId")))
            Else
                table.AsEnumerable.SetField("LocationId", locationId)
            End If

            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(table)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)

            Return table
        End Function


        ''' <summary>
        ''' Retrieves a dictionary of all the location ids, location definitons of the supplied parent id and its children.
        ''' </summary>
        Private Shared Function GetLocationNamesWithOverride(ByVal session As ReportSession, _
          ByVal parentLocation As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            ' Get parent location
            locationNames = GetParentLocationName(session, parentLocation)

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

        Private Shared Function GetBhpbioLocationChildrenNameWithOverride(ByVal session As ReportSession, _
                                            ByVal parentLocationId As Int32, _
                                            ByVal startDate As Date, _
                                            ByVal endDate As Date) As Dictionary(Of Int32, Location)
            Dim locationNames As New Dictionary(Of Int32, Location)
            Dim locationTable As DataTable

            locationTable = session.DalUtility.GetBhpbioLocationChildrenNameWithOverride(parentLocationId, startDate, endDate)

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

    Module OverviewDataSetExtensions
        <Extension()> _
        Public Sub ZeroFactorValues(ByRef table As DataTable)
            table.ZeroNullValues("F1Factor")
            table.ZeroNullValues("F15Factor")
            table.ZeroNullValues("F2Factor")
            table.ZeroNullValues("F25Factor")
            table.ZeroNullValues("F3Factor")
        End Sub

        <Extension()> _
        Public Sub ZeroNullValues(ByRef table As DataTable, ByVal tagId As String)
            For Each row In table.AsEnumerable.Where(Function(r) r("TagId").ToString = tagId)
                row.ZeroNullValues()
            Next
        End Sub

        <Extension()> _
        Public Sub ZeroNullValues(ByRef row As DataRow)
            row.ZeroIfNull("Tonnes")
            row.ZeroIfNull("Volume")
            row.ZeroIfNull("Fe")
            row.ZeroIfNull("P")
            row.ZeroIfNull("SiO2")
            row.ZeroIfNull("Al2O3")
            row.ZeroIfNull("LOI")
            row.ZeroIfNull("H2O")

            row.ZeroIfNull("TonnesDifference")
            row.ZeroIfNull("VolumeDifference")
            row.ZeroIfNull("FeDifference")
            row.ZeroIfNull("PDifference")
            row.ZeroIfNull("SiO2Difference")
            row.ZeroIfNull("Al2O3Difference")
            row.ZeroIfNull("LOIDifference")
            row.ZeroIfNull("H2ODifference")

        End Sub

        <Extension()> _
        Public Sub ZeroIfNull(ByRef row As DataRow, ByVal fieldName As String)
            If Not row.Table.Columns.Contains(fieldName) Then Return

            ' if the all the rows for a given factor are null, then the pie chart will error out in SSRS2005 and cause
            ' the entire report to fail, so here we will set the last row of the factor to 0 if it is 
            ' null.
            '
            ' Update for SSRS2008 - I think the nulls still cause problems in the factors when generating the charts, 
            ' but zero appears to be ok. Changing this to zero, as it solves many rendering issues with the report
            If row(fieldName) Is Nothing Or IsDBNull(row(fieldName)) Then
                row(fieldName) = 0.0
            End If
        End Sub


    End Module

End Namespace
