Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace ReportDefinitions

    Public Class BlockOutSummaryReport
        Inherits ReportBase

        Public Shared Function GetPatternValidationData(session As ReportSession, locationId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
            Dim table = session.DalReport.GetBhpbioReportPatternValidationData(locationId, dateFrom, dateTo)
            table.AsEnumerable.Where(Function(r) Not r.HasValue("ModelFilename")).SetField("ModelFilename", "")
            Return table
        End Function

        Public Shared Function GetPatternFactors(session As ReportSession, locationId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
            Dim factorList = New String() {"F1Factor", "F15Factor"}
            Dim attributeList = New String() {"Tonnes", "Volume", "Fe", "P", "SiO2", "Al2O3", "LOI"}

            session.IncludeResourceClassification = True
            session.IncludeProductSizeBreakdown = False
            session.OverrideModelDataLocationTypeBreakdown = "BLAST"

            ' actually this flag is ignored by the blockout proc, but just in case that changes in the
            ' future we want to explicity set the context to live, because that is the data the report is
            ' returning, as it says many times in the RDL
            session.Context = ReportContext.LiveOnly

            ' this is what makes this different to a normal query, and causes the proc to return
            ' the design model data, instead of teh survey depletions
            session.GetModelDesignDataByBlockoutDate = True

            session.CalculationParameters(dateFrom, dateTo, locationId, childLocations:=True)
            Dim calcSet = Types.CalculationSet.CreateForCalculations(session, factorList)
            Data.ReportColour.AddPresentationColour(session, calcSet)

            Dim tableOptions = New DataTableOptions With {
                .DateBreakdown = ReportBreakdown.None,
                .IncludeSourceCalculations = True,
                .IncludeParentAndChildLocations = True
            }

            Dim table = calcSet.ToDataTable(session, tableOptions)

            F1F2F3SingleCalculationReport.AddDifferenceColumnsIfNeeded(table)
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)

            AddLocationData(session, table, locationId, dateFrom)
            ReportColour.AddLocationColor(session, table)

            ' fix the null location colors... sinc we go down to the pattern level, this can be quite common
            ' we just set them to a random color based off the location name
            table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationColor")).
                SetField("LocationColor", Function(r) r.AsString("LocationName").AsColor())

            AddFactorTonnes(table)
            AddTotalTonnes(table, locationId)
            AddBlockedDate(session, table, locationId)

            F1F2F3ReportEngine.UnpivotDataTable(table, maintainTonnes:=True)
            F1F2F3ReportEngine.AddAttributeIds(table)
            F1F2F3ReportEngine.AddAttributeValueFormat(table)
            F1F2F3ReportEngine.AddThresholdValues(session, table, locationId)

            ' because of the way the report is laid out, with the validation and factor data interleaved
            ' we need to have it all in the same DataTable, and returned in a single WebService call. The fields
            ' don't really line up that well, but it does work
            AddModelValidationSection(session, table, locationId, dateFrom, dateTo)

            Dim filterList = factorList.ToList()
            filterList.Add("GradeControlModel")
            filterList.Add("ValidateModel")

            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList)
            F1F2F3ReportEngine.FilterTableByFactors(table, filterList.ToArray)
            Return table
        End Function

        Public Shared Function AddModelValidationSection(session As ReportSession, table As DataTable, locationId As Integer, dateFrom As Date, dateTo As Date) As DataTable
            Dim validationTable = GetPatternValidationData(session, locationId, dateFrom, dateTo)

            table.Columns.AddIfNeeded("HasResourceClassification", GetType(Integer)).SetDefault(0)
            table.Columns.AddIfNeeded("BlockCount", GetType(Integer)).SetDefault(0)

            ' there are three possible states with the geomet information that a pattern has - either it
            ' has the tonnes split and the geomet grades, or just the tonnes split. This means that there are 
            ' three possible values for this field - Y, N or P (for Partial)
            table.Columns.AddIfNeeded("GeometState", GetType(String)).SetDefault("N")

            For Each row As DataRow In validationTable.Rows
                Dim template = table.AsEnumerable.FirstOrDefault(Function(r) r.AsInt("LocationId") = row.AsInt("LocationId"))
                If template IsNot Nothing Then
                    Dim newRow = template.CloneFactorRow()
                    newRow("TagId") = String.Format("ValidateModel{0}", row.AsString("ModelName").Replace(" ", ""))
                    newRow("ReportTagId") = row.AsString("ModelName")
                    newRow("CalcId") = "ValidateModel"
                    newRow("Type") = 1
                    newRow("Description") = row.AsString("ModelFilename")
                    newRow("Attribute") = "Tonnes"
                    newRow("HasResourceClassification") = row.AsInt("HasResourceClassification")
                    newRow("BlockCount") = row.AsInt("BlockCount")
                    newRow("GeometState") = GetGeometValidationCode(row)
                End If
            Next

            Return table
        End Function

        Public Shared Function GetGeometValidationCode(row As DataRow) As String
            Dim hasGeomet = row.AsInt("HasGeomet") = 1
            Dim hasGeometGrades = row.AsInt("HasGeometGrades") = 1

            If hasGeomet AndAlso hasGeometGrades Then
                Return "Y"
            ElseIf hasGeomet Then
                Return "P"
            Else
                Return "N"
            End If
        End Function


        Public Shared Function AddBlockedDate(session As ReportSession, table As DataTable, parentLocationId As Integer) As DataTable
            Dim locationIds = table.AsEnumerable.Select(Function(r) r.AsInt("LocationId")).Where(Function(l) l <> parentLocationId).Distinct()
            Dim blockedDates = GetBlockedDates(session, locationIds.ToList)

            table.Columns.AddIfNeeded("BlockedDate", GetType(DateTime)).SetDefault(DateTime.MinValue)

            For Each row As DataRow In table.Rows
                Dim locationId = row.AsInt("LocationId")
                If blockedDates.ContainsKey(locationId) Then row("BlockedDate") = blockedDates(locationId)
            Next

            Return table
        End Function

        ' getting the blocked date from the locationid of a pattern is actually not that easy, because the
        ' blocked date is stored at the BLOCK level. To fill out the blocked dates we get a list of unique
        ' location ids, and call a scalar function for each of them. This is not very fast, but it appears
        ' to be the best option.
        '
        ' The other obvious way to do this is to update the location details method to return the blocked date
        ' as well, however this method can return thousands of rows, and would likely we even slower than the 
        ' simple procedural method used here
        Public Shared Function GetBlockedDates(session As ReportSession, locationIds As List(Of Integer)) As Dictionary(Of Integer, DateTime)
            Dim result = New Dictionary(Of Integer, DateTime)
            For Each locationId In locationIds
                Dim blockedDate = session.DalUtility.BhpbioGetBlockedDateForLocation(locationId, DateTime.Now)
                If blockedDate.HasValue Then result.Add(locationId, blockedDate.Value)
            Next
            Return result
        End Function

        Public Shared Function AddTotalTonnes(table As DataTable, parentLocationId As Integer) As DataTable
            table.Columns.AddIfNeeded("TotalTonnes", GetType(Double)).SetDefault(0)

            Dim rows = table.AsEnumerable.Where(Function(r) r.IsFactorRow AndAlso r.AsInt("LocationId") <> parentLocationId AndAlso r.AsString("CalcId") = "F1Factor")
            Dim totalTonnes = rows.Where(Function(r) r.HasValue("FactorTonnes")).Sum(Function(r) r.AsDbl("FactorTonnes"))
            rows.AsEnumerable.SetField("TotalTonnes", totalTonnes)

            Return table
        End Function

        Public Shared Function AddFactorTonnes(table As DataTable) As DataTable
            table.Columns.AddIfNeeded("FactorTonnes", GetType(Double))

            table.AsEnumerable.Where(Function(r) r.IsFactorRow).
                SetField("FactorTonnes", Function(r) r.AsDblN("TonnesDifference") / (1 - 1 / r.AsDblN("Tonnes")))

            table.AsEnumerable.Where(Function(r) Not r.HasValue("FactorTonnes")).SetField("FactorTonnes", 0)
            Return table
        End Function

        ' we can't use the usual location methods because we need to go down to the pattern level,
        ' and to get the full names, (in the form 35-0141-0012 for example). Still use the standard
        ' column names though
        Public Shared Sub AddLocationData(session As ReportSession, table As DataTable, parentLocationId As Integer, locationDate As DateTime, Optional lowestLocationType As String = "Blast")
            table.Columns.AddIfNeeded("LocationName", GetType(String))
            table.Columns.AddIfNeeded("LocationType", GetType(String))
            Dim locations = GetLocationDataWithFullName(session, parentLocationId, locationDate, lowestLocationType)

            For Each row As DataRow In table.Rows
                Dim location = locations.AsEnumerable.FirstOrDefault(Function(r) r.AsInt("Location_Id") = row.AsInt("LocationId"))

                If location IsNot Nothing Then
                    row("LocationName") = location.AsString("LocationFullName")
                    row("LocationType") = location.AsString("Location_Type_Description")
                Else
                    row("LocationName") = "UNKNOWN"
                    row("LocationType") = "UNKNOWN"
                End If

            Next

        End Sub

        Public Shared Function GetLocationDataWithFullName(session As ReportSession, parentLocationId As Integer, locationDate As DateTime, Optional lowestLocationType As String = "Blast") As DataTable
            Dim locations = session.DalReport.GetBhpbioReportLocationBreakdownWithNames(parentLocationId, False, lowestLocationType, locationDate)
            Dim rootLocation = locations.AsEnumerable.First

            locations.Columns.AddIfNeeded("LocationFullName", GetType(String))
            locations.AsEnumerable.SetField("LocationFullName", Function(r) r.AsString("Name"))

            ' when getting the locations for lower down the heirachy, we need to update the name to add the pit
            ' and bench name
            If rootLocation.AsString("Location_Type_Description") = "Bench" Then
                Dim locationParents = session.DalUtility.GetLocationParentHeirarchy(parentLocationId)
                Dim pitLocation = locationParents.AsEnumerable.FirstOrDefault(Function(r) r.AsString("Location_Type_Description").ToUpper = "PIT")

                If pitLocation IsNot Nothing Then
                    rootLocation("LocationFullName") = String.Format("{0}-{1}", pitLocation.AsString("Name"), rootLocation("Name"))
                End If
            End If

            For Each location As DataRow In locations.Rows
                ' if the location is below the bench level, we build the name by prepending the parent name
                Dim locationTypeName = location.AsString("Location_Type_Description")

                If locationTypeName = "Bench" OrElse locationTypeName = "Blast" OrElse locationTypeName = "Block" Then
                    Dim parentLocation = locations.AsEnumerable.FirstOrDefault(Function(r) r.AsInt("Location_Id") = location.AsInt("Parent_Location_Id"))

                    If parentLocation IsNot Nothing Then
                        location("LocationFullName") = String.Format("{0}-{1}", parentLocation.AsString("LocationFullName"), location.AsString("Name"))
                    End If
                End If
            Next

            Return locations
        End Function

    End Class


    Public Module StringExtensions
        <Runtime.CompilerServices.Extension()>
        Public Function AddIfNeeded(columns As DataColumnCollection, columnName As String, type As Type) As DataColumn
            If Not columns.Contains(columnName) Then
                Return columns.Add(columnName, type)
            Else
                Return columns(columnName)
            End If
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function SetDefault(column As DataColumn, defaultValue As Object) As DataColumn
            column.Table.AsEnumerable.SetFieldIfNull(column.ColumnName, defaultValue)
            Return column
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function AsColor(input As String) As String
            Return "#" + input.SHA1.Substring(0, 6)
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function SHA1(input As String) As String
            Using hasher = New Security.Cryptography.SHA1Managed()
                Dim hash = hasher.ComputeHash(Text.Encoding.UTF8.GetBytes(input))
                Return String.Join("", hash.Select(Function(b) b.ToString("x2")).ToArray())
            End Using
        End Function
    End Module

End Namespace

