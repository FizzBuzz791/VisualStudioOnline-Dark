Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Runtime.CompilerServices

Imports System.Linq
Imports System.Data

' these modules add LINQ methods to the datatable + datarow
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

Namespace ReportDefinitions

    Public Class ShippingTargetsReport
        Inherits F1F2F3ReconciliationByAttributeReport

        Private _calcIds As Dictionary(Of String, Calc.CalcType) = Nothing

        Public Property IncludeChildLocations() As Boolean
        Public Property SingleSource() As String = Nothing

        Public Overrides Function GetCustomCalculationSet(ByVal session As Types.ReportSession,
                ByVal locationId As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime,
                Optional ByVal includeChildLocations As Boolean = False) As CalculationSet

            If SingleSource Is Nothing Then
                ' if we are not getting the child locations, then return null and run the default
                ' calc set method. This can only occur when the normal shipping targets report is
                ' run, and this report can contain mulitple factors/calculations
                Return Nothing
            End If

            Dim holdingData As New CalculationSet()

            ' Always get raw data monthly, even if then aggregating to a higher level
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly
            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, includeChildLocations)
            session.UseHistorical = True

            Dim factorAdded As Boolean = False
            Dim sourceType = Calc.Calculation.GetCalcTypeFromString(SingleSource)

            session.RequiredModelList.Clear()

            ' work out what models are needed and whether the source is a factor or not
            If SingleSource = Calc.F15.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelGradeControlSTGM.BlockModelName)
                session.RequiredModelList.Add(Calc.ModelShortTermGeology.BlockModelName)
                factorAdded = True
            ElseIf SingleSource = Calc.F2.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelGradeControl.BlockModelName)
                factorAdded = True
            ElseIf SingleSource = Calc.F25.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelMining.BlockModelName)
                factorAdded = True
            ElseIf SingleSource = Calc.F3.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelMining.BlockModelName)
                factorAdded = True
            ElseIf SingleSource = Calc.ModelGeology.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelGeology.BlockModelName)
            ElseIf SingleSource = Calc.ModelGradeControl.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelGradeControl.BlockModelName)
            ElseIf SingleSource = Calc.ModelShortTermGeology.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelShortTermGeology.BlockModelName)
            ElseIf SingleSource = Calc.ModelGradeControlSTGM.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelGradeControlSTGM.BlockModelName)
            ElseIf SingleSource = Calc.ModelMining.CalculationId Then
                session.RequiredModelList.Add(Calc.ModelMining.BlockModelName)
            End If

            ' if we have a factor, then the GC model is required in order to chart the context tonnes
            ' the actual calculation will be added to the calcSet later, but we need to add the model
            ' to the required list before the block model query gets triggered, otherwise the data
            ' won't be included
            If SingleSource.EndsWith("Factor") Then
                session.RequiredModelList.Add(Calc.ModelGradeControl.BlockModelName)
            End If

            ' we need to have at least one factor added in order for the outputted data table to have the
            ' correct fields, so if there are no factors in the list already, then we will add the F1
            If SingleSource = Calc.F1.CalculationId Or Not factorAdded Then
                session.RequiredModelList.Add(Calc.ModelGradeControl.BlockModelName)
                session.RequiredModelList.Add(Calc.ModelMining.BlockModelName)

                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())
                factorAdded = True
            End If

            ' Add the source
            If Not holdingData.HasCalcId(SingleSource) Then
                Dim c = Calc.Calculation.Create(Calc.Calculation.GetCalcTypeFromString(SingleSource), session)
                holdingData.Add(c.Calculate())
            End If

            ' we need to manually add the components for any factors, because otherwise the recalc after aggregation will fail
            ' The ToDataTable method can do that automatically, but that causes other problems down stream, so we do it manually
            ' instead
            If holdingData.HasCalcId(Calc.F15.CalculationId) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelShortTermGeology, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())
            End If

            If holdingData.HasCalcId(Calc.F2.CalculationId) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MineProductionExpitEquivalent, session).Calculate())
            End If

            If holdingData.HasCalcId(Calc.F25.CalculationId) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.OreForRail, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelOreForRailEquivalent, session).Calculate())
            End If

            If holdingData.HasCalcId(Calc.F3.CalculationId) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortOreShipped, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelShippingEquivalent, session).Calculate())
            End If

            ' if the single source is a factor, and we don't have grade control in the calcset yet, then add it. We need
            ' the grde control tonnes in order ot add the context bars to the charts
            If SingleSource.EndsWith("Factor") AndAlso Not holdingData.HasCalcId(Calc.ModelGradeControl.CalculationId) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
            End If

            session.RequiredModelList.Clear()
            Return holdingData

        End Function

        Public Function GetShippingData(ByVal session As Types.ReportSession, ByVal productTypeId As Int32,
                                  ByVal startDate As DateTime, ByVal endDate As DateTime,
                                  ByVal attributes As String(),
                                  ByVal factorList As String(),
                                  ByVal dateBreakdown As Types.ReportBreakdown) As DataTable


            If session.SelectedProductType Is Nothing Then
                session.ProductTypeId = productTypeId
            End If

            Dim reportStartDate = startDate
            Dim reportEndDate = endDate
            Dim factorsOnly = factorList.All(Function(r) r.Contains("Factor"))
            Dim parentLocationId = session.SelectedProductType.LocationId

            ' we can include either mulitple calculations, or multiple locations, so if the caller has sent more than
            ' one factor in the list, then don't get the children
            If IncludeChildLocations And factorList.Count > 1 Then
                Throw New Exception("Cannot include child locations in shipping report if there is more than one calculation")
            End If

            ' make sure that none of the dates are before the lump fines cutover. This should be checked on the client side as well
            ' buts its best to have a defense-in-depth I guess
            If startDate < session.GetLumpFinesCutoverDate Then
                startDate = session.GetLumpFinesCutoverDate
            End If

            If endDate < session.GetLumpFinesCutoverDate Then
                endDate = session.GetLumpFinesCutoverDate
            End If

            If Not factorsOnly AndAlso dateBreakdown <> ReportBreakdown.CalendarQuarter Then
                ' when we actually get the calculation date we need to add a month to the start and end of the query
                ' this is so that when the chart is rendered the lines that go off the edge of the chart are correct
                ' without these extra points they would just be flat. I couldn't work out a way to hide the 'flat' lines
                ' - the empty point logic isn't quite flexible enough for this
                reportStartDate = startDate.AddMonths(-1)
                reportEndDate = endDate.AddMonths(1)

                If reportStartDate < session.GetLumpFinesCutoverDate Then
                    reportStartDate = session.GetLumpFinesCutoverDate
                End If
            End If

            ' only one calculation selected? then set the single source - this will cause a custom calc set to be generated with just that
            ' calc (and the supporting values). This was required for speed reasons
            If factorList.Length = 1 Then
                SingleSource = factorList.First
            End If

            Dim table = Me.GetContributionData(session, productTypeId, parentLocationId, reportStartDate, reportEndDate, dateBreakdown, IncludeChildLocations)

            AddGradeControlTonnesToUnpivoted(table)
            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributes)
            F1F2F3ReportEngine.FilterTableByFactors(table, factorList)
            F1F2F3ReportEngine.AddProductTypeColumns(table, session.SelectedProductType)


            ' if even after the filtering, we have null rows left, we will have to get rid of them, or it causes
            ' the rendering of the table to fail
            table.DeleteRows(table.AsEnumerable.Where(Function(r) Not r.HasValue("AttributeValue")).ToList)

            ' now we add the shipping targets records to the dataset, we will add them as separate rows
            ' but only if the source is not a factor
            If Not factorsOnly Then
                session.DateBreakdown = dateBreakdown

                ' By Default the CalendarDate = DateFrom, even if there is a gap between the DateFrom and DateTo. This method will
                ' set the CalendarDate to be midway between the DateFrom and DateTo, making the calculation values render in the 
                ' proper spot on the report
                AdjustCalendarDates(table)

                ' Adds the shipping targets as separate 'locations' to the dataset. This doesn't make much logical sense,
                ' but it needs to be done this way in order for the grouping the report to work properly
                AddShippingTargetsAsRows(table, session, productTypeId, attributes.ToList)

                ' now we can add the formatting to the table..
                F1F2F3ReportEngine.AddAttributeValueFormat(table)

                ' Add the shipping nomination items. These are on particaulr *days*. The times are removed. The fact that they are
                ' on days, and not months means that report has to do some tricky stuff
                AddShippingNominationItems(table, session, startDate, endDate, attributes.ToList)

                ' since the shipping nomination items are on individual days, not at the month boundries, then we need to add records
                ' for these dates for each other record, otherwise the report doesn't render properly. this method creates those records.
                '
                ' It will either use the value from the previous point, or DBNull as the AttributeValue. 
                '
                ' SSRS will handle rendering these properly
                AddBlankDateRecords(table)
            Else
                ' even if there is no shipping data to add, we still need to format the rows
                F1F2F3ReportEngine.AddAttributeValueFormat(table)
            End If

            ' set the format on any fields that are missing it...
            table.AsEnumerable.Where(Function(r) Not r.HasValue("AttributeValueFormat")).SetField("AttributeValueFormat", "N2")

            Return table
        End Function

        ' assumes the table already has the garde control data in it, we just need to pivot it out
        Public Shared Sub AddGradeControlTonnesToUnpivoted(ByRef table As DataTable)
            If Not table.IsUnpivotedTable Then Throw New Exception("This method is only valid on unpivoted tables")
            If Not table.Columns.Contains("Tonnes") Then Throw New Exception("This method requires the Tonnes field on the table. Run 'AddTonnesValuesToUnpivotedTable'")

            Dim gradeControlRows = table.AsEnumerable.Where(Function(r) r.AsString("CalcId") = "GradeControlModel").ToList

            If Not table.Columns.Contains("GradeControlTonnes") Then
                table.Columns.Add("GradeControlTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                Dim gc = gradeControlRows.AsEnumerable.
                    GetCorrespondingRowsForGroupUnpivoted(row).
                    FirstOrDefault(Function(r) r.AsString("Attribute") = row.AsString("Attribute"))

                If gc IsNot Nothing AndAlso gc.HasValue("AttributeValue") AndAlso gc.HasValue("Tonnes") Then
                    Dim attributeName = gc.AsString("Attribute")
                    Dim gradePct = gc.AsDbl("AttributeValue") / 100.0

                    ' tonnes are tonnes, don't need to times by the gade value
                    If attributeName.Contains("Tonnes") Or attributeName = "Volume" Then
                        gradePct = 1.0
                    End If

                    row("GradeControlTonnes") = gc.AsDbl("Tonnes") * gradePct
                    Else
                        row("GradeControlTonnes") = 0.0
                End If
            Next
        End Sub

        ' Adds the shipping targets as separate 'locations' to the dataset. This doesn't make much logical sense,
        ' but it needs to be done this way in order for the grouping the report to work properly
        Public Shared Sub AddShippingTargetsAsRows(ByRef table As DataTable, ByVal session As Types.ReportSession, ByVal productTypeId As Integer, attributes As List(Of String), Optional dateList As List(Of Date) = Nothing)

            If dateList Is Nothing Then
                dateList = table.AsEnumerable.Select(Function(r) r.AsDate("DateFrom")).Distinct.ToList
            End If

            For Each shippingDate In dateList

                ' we could call this at the top, and then do the date filtering in code, but do it in this easy way at first
                Dim shippingTargets = session.DalShippingTarget.GetBhpbioShippingTargets(productTypeId, shippingDate)

                For Each row As DataRow In shippingTargets.Rows
                    For Each attributeName In attributes
                        Dim targetRow = ShippingTargetToFactorRow(table, row, attributeName)

                        targetRow("CalendarDate") = shippingDate
                        targetRow("DateFrom") = shippingDate
                        targetRow("DateTo") = shippingDate

                        If session.DateBreakdown.HasValue Then
                            targetRow("DateText") = Data.DateBreakdown.GetDateText(shippingDate, session.DateBreakdown.Value)
                        End If

                        table.Rows.Add(targetRow)
                    Next
                Next
            Next

        End Sub

        Public Shared Function ShippingTargetToFactorRow(table As DataTable, row As DataRow, attributeName As String) As DataRow
            Dim targetRow = table.NewRow()
            Dim targetType = row.AsString("ValueType").Replace(" ", "")
            Dim attributeId = F1F2F3ReportEngine.GetAttributeId(attributeName)

            targetRow("TagId") = "ShippingTarget" + targetType
            targetRow("ReportTagId") = "ShippingTarget" + targetType
            targetRow("CalcId") = "ShippingTarget" + targetType
            targetRow("Type") = 3

            Dim description = String.Format("Shipping Target ({0})", row.AsString("ValueType"))
            targetRow("Description") = description

            If table.Columns.Contains("LocationType") Then
                targetRow("LocationName") = description
                targetRow("LocationType") = ""
            End If

            Dim color = GetShippingTargetColor(targetType)

            targetRow("PresentationColor") = color
            If targetRow.Table.Columns.Contains("LocationColor") Then
                targetRow("LocationColor") = color
            End If


            If table.Columns.Contains("AttributeId") Then
                targetRow("AttributeId") = attributeId
            End If

            targetRow("Attribute") = attributeName
            Dim valueColumnName = "Attribute_" + attributeId.ToString.Replace("-", "Neg")

            If row.HasColumn(valueColumnName) AndAlso row.HasValue(valueColumnName) Then
                targetRow("AttributeValue") = row.AsDbl(valueColumnName)
            End If

            Return targetRow
        End Function

        Private Shared Function GetShippingTargetColor(targetType As String) As String
            ' eventually these will probably have to be moved out to the configuration screen with the
            ' rest of the colors, but for now it is probably ok just to hard code them here
            If targetType.Contains("Upper") Or targetType.Contains("Lower") Then
                Return "DodgerBlue"
            Else
                Return "SteelBlue"
            End If

        End Function

        ' if there are records where the DateTo is much more than the DateFrom, adjust the calendar date so that
        ' it is midway between the two dates. If you are plotting other stuff with daily points this makes the
        ' point render in the middle of the month, which is more representative
        Public Shared Sub AdjustCalendarDates(ByRef table As DataTable)
            For Each row As DataRow In table.Rows
                If row.AsDate("DateFrom") < row.AsDate("DateTo") Then
                    Dim diff = row.AsDate("DateTo") - row.AsDate("DateFrom")
                    Dim deltaDays = Math.Floor(diff.TotalDays / 2)
                    row("CalendarDate") = row.AsDate("DateFrom").AddDays(deltaDays)
                End If
            Next

        End Sub

        ' Add the shipping nomination items. These are on particaulr *days*. The times are removed. The fact that they are
        ' on days, and not months means that report has to do some tricky stuff
        Public Shared Sub AddShippingNominationItems(ByRef table As DataTable, ByVal session As Types.ReportSession, dateFrom As Date, dateTo As Date, attributes As List(Of String))
            Dim shippingItemsTable = session.DalReport.GetBhpbioShippingNomination(dateFrom, dateTo, session.SelectedProductType.LocationId)
            Dim shippingItems = shippingItemsTable.AsEnumerable.
                Where(Function(r) r.AsString("ProductCode") = session.ProductTypeCode).
                OrderBy(Function(r) r.AsDate("DateOrder"))

            If Not table.Columns.Contains("AttributeValueTrend") Then
                table.Columns.Add("AttributeValueTrend", GetType(Double))

                ' since only the nomination items have these trend values, we will set the first row in
                ' the table to zero so that we are sure that it comes through in the column set
                If table.Rows.Count > 0 Then table.Rows(0)("AttributeValueTrend") = 0
            End If

            For Each attributeName In attributes
                ' this is the current best fit value
                Dim currentBestFit As Double? = Nothing

                For Each shippingItem In shippingItems
                    If Not shippingItem.HasColumn(attributeName) OrElse Not shippingItem.HasValue(attributeName) Then Continue For

                    Dim itemRow = table.NewRow()

                    itemRow("TagId") = "ShippingItem"
                    itemRow("ReportTagId") = "ShippingItem"
                    itemRow("CalcId") = "ShippingItem"
                    itemRow("Type") = 4
                    itemRow("LocationType") = ""
                    itemRow("LocationName") = String.Format("Shipping Item")

                    Dim shippingDate = RoundDate(shippingItem.AsDate("DateOrder"))

                    itemRow("CalendarDate") = shippingDate
                    itemRow("DateFrom") = shippingDate
                    itemRow("DateTo") = shippingDate

                    itemRow("Attribute") = attributeName
                    itemRow("AttributeValue") = shippingItem.AsDbl(attributeName)
                    itemRow("AttributeId") = F1F2F3ReportEngine.GetAttributeId(attributeName)

                    ' calculate the trendline / best for the chart. Logically this should be added as a separate
                    ' series, but it is much easier to calculate by just adding the extra column. Since it only exists
                    ' on the shipping nomination items, I think this will be ok for now
                    currentBestFit = CalculateBestFit(currentBestFit, shippingItem.AsDbl(attributeName))
                    itemRow("AttributeValueTrend") = currentBestFit.Value

                    table.Rows.Add(itemRow)
                Next
            Next



        End Sub

        Private Shared Function RoundDate(d As Date) As Date
            Return New Date(d.Year, d.Month, d.Day, d.Hour, d.Minute, 0)
        End Function

        Private Shared Function CalculateBestFit(currentBestFit As Double?, attributeValue As Double) As Double
            ' not much chance this weighting is going to change, it seems to be a waio standard, so won't
            ' bother putting in it in the database
            Dim valueWeight = 0.1

            ' calculate the best fit based off the current value and the previous value
            If currentBestFit Is Nothing Then
                Return attributeValue
            Else
                Return attributeValue * valueWeight + currentBestFit.Value * (1 - valueWeight)
            End If
        End Function

        Private Shared Sub AddBlankDateRecords(ByRef table As DataTable)
            ' for the date list we use the calendarDate, but then we match on the DateFrom, this so that the matching
            ' works with both the ShippingTargets and normal value rows
            '
            ' UPDATE: Seems like we might only need to apply this to the ShippingTarget records, not the normal ones... this should
            ' hopefully speed up these reports.
            Dim dateList = table.AsEnumerable.Select(Function(r) r.AsDate("CalendarDate")).Distinct.OrderBy(Function(d) d).ToList
            Dim initialRows = table.AsEnumerable.Where(Function(r) r.AsDate("DateFrom") = dateList.Min AndAlso r.AsString("ReportTagId").StartsWith("ShippingTarget")).ToList

            ' if the table is empty / it can't find any initial date records, then just return
            ' as the code after this will crash with an empty table
            If dateList.Count = 0 OrElse initialRows.Count = 0 Then
                Return
            End If

            ' the shipping items will not always have the same initial date as the rest of the series - it
            ' just depends on when the first shipment happens. So we manually add this series to the list of 
            ' initial rows (if it isn't there already)
            If Not initialRows.Any(Function(r) r.AsString("ReportTagId") = "ShippingItem") Then
                Dim nominationRows = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "ShippingItem")
                Dim minShippingDate = nominationRows.Select(Function(r) r.AsDate("CalendarDate")).Min
                Dim initialNominationRows = nominationRows.Where(Function(r) r.AsDate("CalendarDate") = minShippingDate).ToList

                initialRows.AddRange(initialNominationRows)
            End If

            For Each row In initialRows
                For Each currentDate In dateList
                    ' not all the series start on the same date, so if the current initial row of the series
                    ' starts after the current date in the list, we just skip it
                    If currentDate < row.AsDate("CalendarDate") Then Continue For

                    ' see if there is a row that matches the initial one, for the current date...
                    Dim matchingRow = table.AsEnumerable.FirstOrDefault(Function(r) r.AsString("ReportTagId") = row.AsString("ReportTagId") AndAlso
                                                                     r.AsString("LocationName") = row.AsString("LocationName") AndAlso
                                                                     r.AsString("Attribute") = row.AsString("Attribute") AndAlso
                                                                     r.AsDate("CalendarDate") = currentDate)

                    ' ... if it doesn't exist, then we clone the closest row, and set the Value to DBNull, or the same as the previous value
                    ' (depending on the type of the row)
                    If matchingRow Is Nothing Then
                        Dim previousRow = GetPreviousRow(table, row, currentDate)
                        If previousRow IsNot Nothing Then

                            Dim newRow = previousRow.CloneFactorRow(True)

                            ' set all the dates to the same value - this is a 'point' value. The CalendarDate will be used
                            ' by the client when rendering
                            newRow("CalendarDate") = currentDate
                            newRow("DateFrom") = currentDate
                            newRow("DateTo") = currentDate

                            If previousRow.AsString("ReportTagId").Contains("ShippingTarget") And previousRow.HasValue("AttributeValue") Then
                                ' shipping targets need to take the previou value, because they are a 'step' type line chart,
                                ' so using the empty point interpolation fucks up the rendering
                                newRow("AttributeValue") = previousRow.AsDbl("AttributeValue")
                                newRow("AttributeValueTrend") = previousRow("AttributeValueTrend")
                            Else
                                newRow("AttributeValue") = DBNull.Value
                                newRow("AttributeValueTrend") = DBNull.Value
                            End If
                        End If


                    End If

                Next

            Next
        End Sub

        Private Shared Function GetPreviousRow(ByRef table As DataTable, ByVal row As DataRow, ByVal maxDate As Date) As DataRow
            Return table.AsEnumerable.
                        Where(Function(r) r.AsString("ReportTagId") = row.AsString("ReportTagId") AndAlso
                                  r.AsString("LocationName") = row.AsString("LocationName") AndAlso
                                  r.AsString("Attribute") = row.AsString("Attribute")).
                        OrderByDescending(Function(r) r.AsDate("DateFrom")).
                        FirstOrDefault(Function(r) r.AsDate("DateFrom") < maxDate)
        End Function
    End Class


End Namespace

