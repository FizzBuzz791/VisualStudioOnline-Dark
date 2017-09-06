Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Types

    ' this list of options is passed to the ToDataTable method to avoid having a long list of boolean
    ' arguments. The defaults represent the most common options, making is easier to use than the old
    ' methods
    '
    ' In brackets above each property is the name of the parameter it maps to in the old ToDataTable method
    Public Class DataTableOptions
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(options As DataTableOptions)
            IncludeSourceCalculations = options.IncludeSourceCalculations
            PivotedResults = options.PivotedResults
            GroupByLocationId = options.GroupByLocationId
            GroupMeasureByMaterialType = options.GroupMeasureByMaterialType
            GroupFactorByMaterialType = options.GroupFactorByMaterialType
            DateBreakdown = options.DateBreakdown
            IncludeParentAndChildLocations = options.IncludeParentAndChildLocations
        End Sub

        Public Function Copy() As DataTableOptions
            Return New DataTableOptions(Me)
        End Function

        ' (includeParents)
        Public Property IncludeSourceCalculations() As Boolean = False

        ' (Not normalizedData)
        Public Property PivotedResults As Boolean = True

        ' (maintainLocations)
        Public Property GroupByLocationId() As Boolean = True

        ' (breakdownMeasureByMaterialType)
        Public Property GroupMeasureByMaterialType() As Boolean = False

        ' (breakdownFactorByMaterialType)
        Public Property GroupFactorByMaterialType() As Boolean = False

        ' (aggregateToDateBreakdown)
        Public Property DateBreakdown As ReportBreakdown = ReportBreakdown.Monthly

        ' This causes GroupByLocationId to be ignored, and the child location breakdown
        ' will be included, as well as the total location aggregation
        Public Property IncludeParentAndChildLocations As Boolean = False

    End Class

    ''' <summary>
    ''' Contains a set of CalculationResults and functions to manage them.
    ''' Supplies shared functions for the conversion between datatables and CalculationSet's.
    ''' </summary>
    ''' <remarks></remarks>
    Public Class CalculationSet
        Inherits Collections.ObjectModel.Collection(Of CalculationResult)

        ''' <summary>
        ''' returns true if any of the CalculationResults are in error
        ''' </summary>
        Public ReadOnly Property InError() As Boolean
            Get
                Return Me.Any(Function(c) c.InError)
            End Get
        End Property

        Public Function GetErrorMessage() As String
            If Not InError Then
                Return ""
            End If

            Dim errors = Me.Where(Function(c) c.InError).Select(Function(c) String.Format("{0}: {1}", c.CalcId, c.ErrorMessage))
            Return String.Format("An error has occurred retrieving report data.{0}", vbCrLf + String.Join(vbCrLf, errors.ToArray))
        End Function

        ''' <summary>
        ''' Returns the Calculation set of all result's and their parent results.
        ''' </summary>
        Public ReadOnly Property GetAllParentResults() As CalculationSet
            Get
                Dim allParentCalculation As New CalculationSet
                Dim result As CalculationResult
                Dim parentResult As CalculationResult

                For Each result In Me
                    For Each parentResult In result.GetAllCalculations()
                        allParentCalculation.Add(parentResult)
                    Next
                Next

                Return allParentCalculation
            End Get
        End Property


        Public Shared Function CreateForCalculations(session As ReportSession, calculationIds As String()) As CalculationSet
            Dim calcSet As New Types.CalculationSet()

            For Each calculationId In calculationIds
                Dim result = Calc.Calculation.Create(calculationId, session).Calculate()
                calcSet.Add(result)
            Next

            Return calcSet
        End Function

        Public Function HasCalcId(ByVal calcId As String) As Boolean
            Return GetCalcById(calcId).Count > 0
        End Function

        ''' <summary>
        ''' Returns a Calculation set of all items matching that calc id.
        ''' </summary>
        Public Function GetCalcById(ByVal requestedTagId As String) As CalculationSet
            Dim calcSet As New CalculationSet()
            Dim calc As CalculationResult

            For Each calc In Me
                calcSet.Merge(calc.GetCalcById(requestedTagId))
            Next

            Return calcSet
        End Function

        Public Sub ReplaceDescription(ByVal calcId As String, ByVal description As String)
            Dim result As CalculationResult
            For Each result In Me
                result.ReplaceDescription(calcId, description)
            Next
        End Sub

        Public Function GetStripToDate(ByVal calendarDate As DateTime) As CalculationSet
            Dim calcSet As New CalculationSet
            Dim result As CalculationResult
            Dim resultCopy As CalculationResult

            For Each result In ToArray()
                resultCopy = result.Clone()
                resultCopy.StripDateExcept(calendarDate)
                calcSet.Add(resultCopy)
            Next

            Return calcSet
        End Function


#Region "ToDataTable"
        ''' <summary>
        ''' Converts set to a datatable, this is the same as the other ToDataTable methods, but it takes an options object
        ''' that is a bit easier to deal with
        ''' </summary>
        Public Function ToDataTable(ByVal session As ReportSession, options As DataTableOptions) As DataTable
            If options.IncludeParentAndChildLocations Then
                ' sometimes we want to show both the child location breakdown and the aggregated location data
                ' when IncludeParentAndChildLocations is set we attempt to do this. This is done by running ToDataTable
                ' twice - once with the location grouping on, and once with it off and combining the results. Note that
                ' in this case stored proc is only run once - its only the ToDataTable aggregation that is being repeating
                '
                ' This means that the results will only be correct if the DataTable contains all the location data needed, 
                ' and the proc has been run with the child location breakdown on
                If session.RequestParameter Is Nothing Then
                    Throw New ArgumentException("session.RequestParamter")
                ElseIf session.RequestParameter.LocationId Is Nothing Then
                    Throw New ArgumentException("session.RequestParamter.LocationId")
                End If

                If Not session.RequestParameter.ChildLocations Then
                    ' if the proc likely had the child locations breakdown turned off then
                    ' we want to raise an exception, because we probably don't have the data we
                    ' need in the CalculationSet in order to do the location grouping
                    Throw New Exception("Proc was run with ChildLocations = false - we probably don't have the data to do a location breakdown ")
                End If

                Dim locationId = session.RequestParameter.LocationId.Value
                Dim parentOptions = options.Copy()
                Dim childOptions = options.Copy()

                parentOptions.IncludeParentAndChildLocations = False
                parentOptions.GroupByLocationId = False
                Dim parentTable = ToDataTable(session, parentOptions)
                CalculationSet.NormalizeLocationId(parentTable, locationId)

                childOptions.IncludeParentAndChildLocations = False
                childOptions.GroupByLocationId = True
                Dim childTable = ToDataTable(session, childOptions)
                CalculationSet.NormalizeLocationId(childTable, locationId)

                childTable.Merge(parentTable)
                Return childTable
            Else
                Return ToDataTable(options.IncludeSourceCalculations,
                        Not options.PivotedResults,
                        options.GroupByLocationId,
                        options.GroupMeasureByMaterialType,
                        options.DateBreakdown,
                        session,
                        options.GroupFactorByMaterialType)
            End If

        End Function

        ''' <summary>
        ''' Converts set to a datatable without including parents in a denorm form.
        ''' </summary>
        Public Function ToDataTable(ByVal reportSession As ReportSession) As DataTable
            Return ToDataTable(False, False, False, False, reportSession)
        End Function

        ''' <summary>
        ''' Converts set to a datatable without including parents in a denorm form.
        ''' </summary>
        Public Function ToDataTable(ByVal includeParents As Boolean, ByVal normalizedData As Boolean, _
         ByVal maintainLocations As Boolean, ByVal breakdownMeasureByMaterialType As Boolean, ByVal aggregateToDateBreakdown As ReportBreakdown?, _
         ByVal reportSession As ReportSession, ByVal breakdownFactorByMaterialType As Boolean) As DataTable

            Dim table As DataTable = Nothing

            If reportSession.SelectedLocationGroup IsNot Nothing AndAlso Not reportSession.RequestParameter.ChildLocations Then
                Throw New Exception("Having ChildLocations are turned off when a location group is selected is invalid")
            End If

            If reportSession.RethrowCalculationSetErrors AndAlso InError Then
                Throw New Exception(GetErrorMessage())
            End If

            For Each result In ToArray()

                If reportSession.SelectedLocationGroup IsNot Nothing Then
                    Dim unneededResults = result.Where(Function(r) r.LocationId.HasValue AndAlso Not reportSession.SelectedLocationGroup.LocationIds.Contains(r.LocationId.Value)).ToList

                    For Each row In unneededResults
                        result.Remove(row)
                    Next
                End If

                If Not table Is Nothing Then
                    table.Merge(result.ToDataTable(includeParents, normalizedData, maintainLocations, 
                                                   breakdownMeasureByMaterialType, Not reportSession.IncludeProductSizeBreakdown, 
                                                   aggregateToDateBreakdown, breakdownFactorByMaterialType, 
                                                   reportSession.IncludeStratigraphy, reportSession.IncludeWeathering))
                Else
                    table = result.ToDataTable(includeParents, normalizedData, maintainLocations, breakdownMeasureByMaterialType, 
                                               Not reportSession.IncludeProductSizeBreakdown, aggregateToDateBreakdown, 
                                               breakdownFactorByMaterialType, reportSession.IncludeStratigraphy, 
                                               reportSession.IncludeWeathering)
                End If
            Next

            If reportSession.IgnoreLumpFinesCutover = False Then
                RemoveProductSizeRecordsBeforeCutover(table, reportSession)
            End If

            If reportSession.ProductSizeFilter <> ProductSizeFilterValue.NONE Then
                FilterDataTableByProductSize(table, reportSession.ProductSizeFilter)
            End If

            If aggregateToDateBreakdown = ReportBreakdown.None Then
                ' after doing a ToDataTable with the ReportBreakdown.None, the Calendar date is broken, so we need to fix
                ' this, and set it back to the DateFrom like it is normally.
                For Each row In table.AsEnumerable.Where(Function(r) r.HasValue("CalendarDate") AndAlso r.AsDate("CalendarDate") = Date.MinValue).ToList
                    ' normally use SetField to set the value of a bunch of values, but that only works with 
                    ' static values, we we actually need to loop through the collection. Probably we should
                    ' update SetFeild to take a lambda
                    row("CalendarDate") = row("DateFrom")
                Next
            End If

            ' if the location doesn't have any date for one of the months, then the dates will be different for that
            ' location, because the aggregation sets the start and end dates based off the minimum and maximum values
            ' for those fields.
            '
            ' If we have the date parameters, then we will use them to set the start and end dates in the table (only
            ' if we are using a None date breakdown obviously)
            If aggregateToDateBreakdown = ReportBreakdown.None AndAlso reportSession.RequestParameter IsNot Nothing Then
                Dim startDate = reportSession.RequestParameter.StartDate
                Dim endDate = reportSession.RequestParameter.EndDate

                table.AsEnumerable.Where(Function(r) r.AsDate("DateFrom") <> startDate).SetField("DateFrom", startDate)
                table.AsEnumerable.Where(Function(r) r.AsDate("CalendarDate") <> startDate).SetField("CalendarDate", startDate)
                table.AsEnumerable.Where(Function(r) r.AsDate("DateTo") <> endDate).SetField("DateTo", endDate)
            End If

            table.TableName = "Values"
            Return table
        End Function


        ''' <summary>
        ''' Converts set to a datatable without including parents in a denorm form.
        ''' </summary>
        Public Function ToDataTable(ByVal includeParents As Boolean, ByVal normalizedData As Boolean, _
         ByVal maintainLocations As Boolean, ByVal breakdownMeasureByMaterialType As Boolean, ByVal reportSession As ReportSession) As DataTable
            Dim result As CalculationResult
            Dim table As DataTable = Nothing

            If reportSession.RethrowCalculationSetErrors AndAlso InError Then
                Throw New Exception(GetErrorMessage())
            End If

            For Each result In ToArray()
                Dim partialResult As DataTable

                If result Is Nothing Then
                    Throw New NullReferenceException("Null CalculationResult in CalculationSet")
                End If

                If Not reportSession.DateBreakdown Is Nothing Then
                    partialResult = result.ToDataTable(includeParents, normalizedData, maintainLocations, 
                                                       breakdownMeasureByMaterialType, 
                                                       Not reportSession.IncludeProductSizeBreakdown, 
                                                       reportSession.DateBreakdown, False, reportSession.IncludeStratigraphy, 
                                                       reportSession.IncludeWeathering)
                Else
                    partialResult = result.ToDataTable(includeParents, normalizedData, maintainLocations, 
                                                       breakdownMeasureByMaterialType, 
                                                       Not reportSession.IncludeProductSizeBreakdown, 
                                                       reportSession.IncludeStratigraphy, reportSession.IncludeWeathering)
                End If

                If Not table Is Nothing Then
                    table.Merge(partialResult)
                Else
                    table = partialResult
                End If
            Next

            If reportSession.IgnoreLumpFinesCutover = False Then
                RemoveProductSizeRecordsBeforeCutover(table, reportSession)
            End If

            If reportSession.ProductSizeFilter <> ProductSizeFilterValue.NONE Then
                FilterDataTableByProductSize(table, reportSession.ProductSizeFilter)
            End If

            table.TableName = "Values"
            Return table
        End Function

        ''' <summary>
        ''' Merges Calulcation References.
        ''' </summary>
        Public Sub Merge(ByVal calcSetToCopy As CalculationSet)
            Dim result As CalculationResult

            For Each result In calcSetToCopy
                Me.Add(result)
            Next
        End Sub

        ' The location Id results behave quite differently depending on if the location grouping is on or not, we would like
        ' to abstract this away, and normalize the location_id field, so that it always holds the correct thing
        Public Shared Function NormalizeLocationId(table As DataTable, locationId As Integer) As DataTable
            If table.AsEnumerable.Where(Function(r) r.HasValue("LocationId")).Distinct().Count() > 0 Then
                ' if we are grouping by location, then probably we have a row with a null location id, and zero
                ' tonnes. Just delete this
                table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId") AndAlso r.AsDbl("Tonnes") = 0).DeleteRows()
            Else
                ' when not grouping by location id the location id will be null, but will contain data. In this case
                ' we set the field to the location id that was passed in as an argument
                table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId")).SetField("LocationId", locationId)
            End If

            Return table
        End Function

        ''' <summary>
        ''' Lump and Fines breakdowns records should only appear in report results and approvals if they are after the cutover
        ''' </summary>
        ''' <param name="reportDataTable">The data table containing results</param>
        ''' <param name="session">The session containing the cutover date</param>
        Private Shared Sub RemoveProductSizeRecordsBeforeCutover(ByVal reportDataTable As DataTable, ByVal session As ReportSession)

            Dim lumpFinesCutover As DateTime = session.GetLumpFinesCutoverDate()

            ' Remove all product size breakdown rows that are before the cutover
            For i As Int32 = reportDataTable.Rows.Count - 1 To 0 Step -1
                Dim row As DataRow = reportDataTable.Rows(i)

                Dim productSizeValue As String = row(ColumnNames.PRODUCT_SIZE).ToString()

                If (Not String.IsNullOrEmpty(productSizeValue) AndAlso Not productSizeValue = CalculationConstants.PRODUCT_SIZE_TOTAL) Then
                    ' This is a breakdown row.. check if it is before the cutover
                    Dim rowDateTimeObject As Object = row(ColumnNames.DATE_FROM)
                    Dim rowDateTime As DateTime

                    If (Not rowDateTimeObject Is Nothing AndAlso Not rowDateTimeObject Is DBNull.Value) Then
                        rowDateTime = CDate(rowDateTimeObject)

                        If rowDateTime < lumpFinesCutover Then
                            ' This row is a product size breakdown AND is before the cutover... the row should be excluded
                            reportDataTable.Rows.RemoveAt(i)
                        End If
                    End If
                End If
            Next
        End Sub

        Private Shared Sub FilterDataTableByProductSize(ByRef table As DataTable, ByVal ProductSizeFilter As ProductSizeFilterValue)
            If ProductSizeFilter = ProductSizeFilterValue.NONE Then Return

            ' we want to delete all the rows that don't match the current product size
            ' this has to be done in two stages - we get strange errors if we try to do the deletes
            ' inside the lambda
            Dim rowsToDelete = table.AsEnumerable.Where(Function(r) r.AsString("ProductSize") <> ProductSizeFilter.ToString)

            For Each row In rowsToDelete.ToList
                row.Delete()
            Next

            table.AcceptChanges()
        End Sub

        ''' <summary>
        ''' Get a string value from a data row, avoiding exceptions that may be caused by incorrect treatment of nulls or DBNull
        ''' </summary>
        ''' <param name="row">The row to read from</param>
        ''' <param name="columnName">The name of the column to read</param>
        ''' <returns>The read value, or Nothing if the value could not be read</returns>
        Private Function SafeGetDataRowString(ByRef row As DataRow, ByVal columnName As String) As String
            Dim readValue As String = Nothing

            Dim value As Object = row(columnName)
            If Not value Is Nothing And Not value Is DBNull.Value Then
                readValue = Convert.ToString(row(columnName))
            End If

            Return readValue
        End Function

        ''' <summary>
        ''' Get an integer value from a data row, avoiding exceptions that may be caused by incorrect treatment of nulls or DBNull
        ''' </summary>
        ''' <param name="row">The row to read from</param>
        ''' <param name="columnName">The name of the column to read</param>
        ''' <returns>The read value, or the default value for integer if the value could not be read</returns>
        Private Function SafeGetDataRowInteger(ByRef row As DataRow, ByVal columnName As String) As Integer
            Dim readValue As Integer

            Dim value As Object = row(columnName)

            If Not value Is Nothing And Not value Is DBNull.Value Then
                readValue = Convert.ToInt32(row(columnName))
            End If
            
            Return readValue
        End Function
#End Region

    End Class
End Namespace
