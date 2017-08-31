Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Runtime.CompilerServices

Imports System.Linq
Imports System.Data

' these modules add LINQ methods to the datatable + datarow
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace ReportDefinitions

    Public Class SupplyChainMonitoringReport
        Inherits ReportBase

        Private Shared Function GetRawCalculationSet(ByVal session As Types.ReportSession, ByVal locationId As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime) As CalculationSet
            Dim holdingData As New CalculationSet
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, Nothing)
            session.UseHistorical = True

            ' simple model
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())

            ' direct feed + stockpile measures
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.DirectFeed, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ExPitToOreStockpile, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.StockpileToCrusher, session).Calculate())

            '  the 'Crusher Feed (Measured)' bar (ie ActualC)
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MineProductionActuals, session).Calculate())

            Dim validFullLocations As String() = {"hub", "company"}
            Dim locationTypeName As String = Data.FactorLocation.GetLocationTypeName(session.DalUtility, session.RequestParameter.LocationId)

            ' the rest of these calculations are only needed if the location is Hub or higher. If it isn't then we
            ' just leave out these calculations and the chart stops after the ActualC bar
            If validFullLocations.Contains(locationTypeName.ToLower) Then

                ' OreForRail
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PostCrusherStockpileDelta, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.OreForRail, session).Calculate())

                ' three port measures
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortStockpileDelta, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortBlendedAdjustment, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortOreShipped, session).Calculate())

            End If

            Return holdingData
        End Function

        Public Shared Function GetDataProductType(ByVal session As Types.ReportSession,
         ByVal productTypeId As Int32, ByVal startDate As DateTime,
         ByVal endDate As DateTime,
         ByVal attributes As String) As DataTable

            ' Setting the ProductTypeId or ProductTypeCode properties on the session will automatically
            ' set the product size filter or the SelectedProductType. There is no reason to do it manually
            session.ProductTypeId = productTypeId

            ' SelectedProductType will always be set - if the productTypeId wa invalid, then an exception would
            ' have been rasied
            Return GetData(session, session.SelectedProductType.LocationId, startDate, endDate, attributes)
        End Function

        Public Shared Function GetData(ByVal session As Types.ReportSession,
         ByVal locationId As Int32, ByVal startDate As DateTime,
         ByVal endDate As DateTime,
         ByVal attributes As String) As DataTable

            Dim dateBreakdown As ReportBreakdown = ReportBreakdown.Monthly

            ' get the raw data, and then add the colors to the report
            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, Nothing)

            Dim calculationSet As CalculationSet = GetRawCalculationSet(session, locationId, startDate, endDate)

            ' Before using the results of the calculation determine whether there have been any retrieval errors,
            ' and if so, generate a suitable error message and raise the error
            If calculationSet.InError Then
                Throw New Exception(calculationSet.GetErrorMessage())
            End If

            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Dim table As DataTable = calculationSet.ToDataTable(False, True, False, False, ReportBreakdown.None, session, False)

            ' this report uses the TagId to do some fancy stuff with the bars to get them to group and stack
            ' properly. This means that if we are in Lump/Fines mode it won't work properly. This detects this situation
            ' and resets the TagId to the ReportTagId
            If session.IncludeProductSizeBreakdown Then
                If session.SelectedProductType IsNot Nothing Then
                    For Each row As DataRow In table.Rows
                        row("TagId") = row("ReportTagId")
                    Next
                Else
                    ' if the lump/fines is on, but the product type filter is not, then we need to throw an
                    ' exception, because the report can't work properly in this scenario
                    Throw New Exception("This report does not support including both Lump and Fines in the same data")
                End If
            End If

            ' convert the attribute argument from an xml string to a list of attribute names.
            ' should work both if the list is a csv list, or an xml list
            Dim attributeList As List(Of String)
            If attributes.Trim.StartsWith("<") Then
                attributeList = Data.ReportDisplayParameter.GetXmlAsList(attributes.ToLower, "attribute", "name").Cast(Of String).ToList()
            Else
                attributeList = attributes.ToLower.Split(","c).ToList
            End If

            attributeList = AddTonnesAttributes(attributeList)

            If (table.Rows.Count > 0) Then

                ' remove rows that are not requried, and calculate the grde tonnes for all rows. Its important that the tonnes are
                ' calculated here, BEFORE any of the offset rows etc are added, otherwise the values will not be calculated correctly
                table.Rows.RemoveDBNulls("AttributeValue")
                AddAttributeTonnes(table)
                AddGradeTonnesRows(table)
                FilterByAttrbiutes(table, attributeList.ToArray)

                ' add all the required offset data for the waterfall chart columns. See the comments on these
                ' methods for how exactly this is accomplished
                table.AddOffsetRow("PostCrusherStockpileDelta", baseTagId:="MineProductionActuals", additionalOffsetTagId:=Nothing, InvertValue:=True, invertAdditionalOffset:=False, applyToTonnes:=True, applyToGradeTonnes:=True)

                '------------
                ' Add offsets for Tonnes only charts - for PortStockpileDelta and PortBlendedAdjustment
                table.AddOffsetRow("PortStockpileDelta", baseTagId:="OreForRail", additionalOffsetTagId:=Nothing, InvertValue:=True, invertAdditionalOffset:=False, applyToTonnes:=True, applyToGradeTonnes:=False)
                ' the PortBlendedAdjustment bar is based on the OreForRail position AFTER modification by the PortStockpileDelta.. for this reason the PortStockpileDelta is applied as an additional offset
                table.AddOffsetRow("PortBlendedAdjustment", baseTagId:="OreForRail", additionalOffsetTagId:="PortStockpileDelta", InvertValue:=False, invertAdditionalOffset:=True, applyToTonnes:=True, applyToGradeTonnes:=False)
                '------------

                '------------
                ' Add offsets for GradeTonnes only charts - for PortStockpileDelta and PortBlendedAdjustment... need to skip OreForRail here...
                table.AddOffsetRow("PortStockpileDelta", baseTagId:="MineProductionActuals", additionalOffsetTagId:="PostCrusherStockpileDelta", InvertValue:=True, invertAdditionalOffset:=True, applyToTonnes:=False, applyToGradeTonnes:=True)
                ' NOTE: For grade related rows, PortStockpileDelta grades are not used..  apply PortBlendedAdjustment directly on MineProductionActuals with PostCrusherStockpileDelta
                table.AddOffsetRow("PortBlendedAdjustment", baseTagId:="MineProductionActuals", additionalOffsetTagId:="PostCrusherStockpileDelta", InvertValue:=False, invertAdditionalOffset:=True, applyToTonnes:=False, applyToGradeTonnes:=True)
                '------------

                ' create the actual mined + crusher feed columns and set the appropriate descriptions
                table.MoveToGroup("ExPitToOreStockpile", "DirectFeed")
                table.CopyToGroup("StockpileToCrusher", "DirectFeed")
                table.SetCategoryDescription("ExPitToOreStockpile", "Actual Mined")
                table.SetCategoryDescription("StockpileToCrusher", "Crusher Feed")

                NormalizeTonnes(table)

            End If

            If (session.ProductTypeId > 0) Then
                AddSimpleDateText(table)
                AddShippingTargets(session, table, startDate, endDate)
            End If

            Return table
        End Function

        Private Shared Sub AddSimpleDateText(table As DataTable)
            If Not table.Columns.Contains("DateText") Then
                table.Columns.Add("DateText")

                For Each row As DataRow In table.Rows
                    row("DateText") = row.AsDate("DateFrom").ToString("dd-MMM-yyyy")
                Next
            End If
        End Sub

        Private Shared Sub AddShippingTargets(session As ReportSession, ByRef table As DataTable, startDate As Date, endDate As Date)
            Dim attributeList = table.AsEnumerable.Select(Function(r) r.AsString("Attribute")).Distinct.ToList
            Dim shippingAttributes = attributeList.Where(Function(a) Not a.ToLower.Contains("tonnes")).ToList

            Dim shippingDate = startDate
            Dim currentValues = New Dictionary(Of String, Double)

            While shippingDate < endDate

                ' we could call this at the top, and then do the date filtering in code, but do it in this easy way at first
                Dim shippingTargets = session.DalShippingTarget.GetBhpbioShippingTargets(session.ProductTypeId, shippingDate)

                For Each row As DataRow In shippingTargets.Rows
                    ' in the case of the supply chain moniroting report, we only care about the Target - not the upper or lower values
                    If row.AsString("ValueType") <> "Target" Then
                        Continue For
                    End If

                    For Each attributeName In shippingAttributes
                        Dim targetRow = ShippingTargetsReport.ShippingTargetToFactorRow(table, row, attributeName)

                        ' we don't want to add the target record if it hasn't changed since last time, or there
                        ' is no value
                        If Not targetRow.HasValue("AttributeValue") Then
                            Continue For
                        ElseIf Not currentValues.ContainsKey(attributeName) Then
                            currentValues.Add(attributeName, targetRow.AsDbl("AttributeValue"))
                        ElseIf currentValues(attributeName) = targetRow.AsDbl("AttributeValue") Then
                            ' the value hasn't changed since the last target, so we don't want to insert it
                            Continue For
                        Else
                            currentValues(attributeName) = targetRow.AsDbl("AttributeValue")
                        End If

                        ' these dates are not really used, but we set them anyway. The only important one is the
                        ' DateText field
                        targetRow("CalendarDate") = shippingDate
                        targetRow("DateFrom") = shippingDate
                        targetRow("DateTo") = shippingDate
                        targetRow("DateText") = row.AsDate("EffectiveFromDateTime").ToString("dd-MMM-yyyy")

                        table.Rows.Add(targetRow)
                    Next
                Next

                ' we get the end date for this shipping target. if it ends before the reporting period, then
                ' we will need to get the one after for the next set of targets
                If shippingTargets.Rows.Count = 0 OrElse Not shippingTargets(0).HasValue("EffectiveToDateTime") Then
                    shippingDate = endDate
                Else
                    shippingDate = shippingTargets(0).AsDate("EffectiveToDateTime")
                    shippingDate = shippingDate.AddDays(1)
                End If

            End While

        End Sub

        Private Shared Sub NormalizeTonnes(ByRef table As DataTable)
            For Each row As DataRow In table.Rows
                If Convert.ToBoolean(row("IsTonnes")) And Not IsDBNull(row("AttributeValue")) Then
                    row("AttributeValue") = CType(row("AttributeValue"), Double) / 1000
                End If
            Next
        End Sub

        Private Shared Function AddTonnesAttributes(ByRef attributeList As List(Of String)) As List(Of String)
            Dim tonnesAttributeList As List(Of String) = (From attribute In attributeList Where Not attribute.ToLower.EndsWith("tonnes") Select attribute + "tonnes").ToList()

            Return attributeList.Concat(tonnesAttributeList).ToList
        End Function

        ' the standard calculations return data for all the grades/attributes, however on the report we only specify
        ' the attributes we want, this method deletes the rows that don't have the attrbiutes we want
        Private Shared Sub FilterByAttrbiutes(ByRef table As DataTable, ByVal attributeList As String())
            ' delete rows that are not in the list of ones that we want
            Dim deleteList As List(Of DataRow) = table.AsEnumerable.Where(Function(r) Not attributeList.Contains(r("Attribute").ToString.ToLower)).ToList
            For Each row In deleteList
                row.Table.Rows.Remove(row)
            Next
        End Sub

        ' The report needs to show the tonnes values for various grades as well. This method adds
        ' a new column to the report with the tonnes value for each row.
        '
        ' This would actually be a good candidate to move into a shared class so that other 
        ' methods can use it
        Private Shared Sub AddAttributeTonnes(ByRef table As DataTable)

            If Not table.Columns.Contains("AttributeTonnes") Then
                table.Columns.Add("AttributeTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                Dim attribute As String = CStr(row("Attribute")).ToLower

                If attribute = "tonnes" Then
                    row("AttributeTonnes") = row("AttributeValue")
                ElseIf Not IsDBNull(row("AttributeValue")) Then
                    Dim grade As Double = CDbl(row("AttributeValue"))
                    Dim tonnes As Double = row.GetTonnes()

                    row("AttributeTonnes") = tonnes * (grade / 100)
                End If

            Next


        End Sub


        Private Shared Sub AddGradeTonnesRows(ByRef table As DataTable)
            If Not table.Columns.Contains("AttributeTonnes") Then Throw New Exception("'AttributeTonnes' tonnes column requried before adding tonnes rows")

            If Not table.Columns.Contains("IsTonnes") Then
                table.Columns.Add("IsTonnes", GetType(Boolean))

                ' set the default value for the new column
                For Each row As DataRow In table.Rows
                    row("IsTonnes") = (row("Attribute").ToString.ToLower.EndsWith("tonnes"))
                Next
            End If

            ' for every grade row, we want to create a new row with the tonnes so it will be easier to chart
            Dim newRows As New List(Of DataRow)
            For Each row As DataRow In table.Rows
                Dim attribute As String = CStr(row("Attribute")).ToLower
                If attribute.EndsWith("tonnes") Then Continue For

                Dim newRow = GenericDataTableExtensions.Copy(row)
                newRow("IsTonnes") = True
                newRow("Attribute") = String.Format("{0}Tonnes", newRow("Attribute").ToString)
                newRow("AttributeValue") = newRow("AttributeTonnes")
                newRows.Add(newRow)
            Next

            For Each row In newRows
                table.Rows.Add(row)
            Next

        End Sub
    End Class

    ' instead of adding heaps and heaps of static methods to the report definiation class, we will try to add them
    ' as extension methods where appropriate. These methods extend not just the table, but occasionally the 
    ' RowCollection in a table, or an individual rows
    Module AttributeDataTableExtensions
        ' use the date and tagid to get the tonnes from the table for the current attribute, this can then
        ' be used to calculate the grade tonnes for the given row
        <Extension()>
        Public Function GetTonnes(ByVal row As DataRow) As Double
            Dim tonnesRow As DataRow = row.Table.AsEnumerable.FirstOrDefault(Function(r) _
                r("Attribute").ToString.ToLower = "tonnes" AndAlso
                r("CalendarDate").ToString = row("CalendarDate").ToString AndAlso
                r("TagId").ToString = row("TagId").ToString
            )

            If Not tonnesRow Is Nothing Then
                Return CDbl(tonnesRow("AttributeValue"))
            Else
                Return Nothing
            End If
        End Function

        ' detecting the dbnulls when doing calculations is pretty annoying, so this method makes it easy to 
        ' set all the values in a given column to zero
        <Extension()>
        Public Sub RemoveDBNulls(ByRef rows As DataRowCollection, ByVal ColumnName As String)
            For Each r As DataRow In rows
                If IsDBNull(r(ColumnName)) Then
                    r(ColumnName) = 0.0
                End If
            Next
        End Sub

        ' On this particular report, we need to have a different description on the x-axis as in the legend, because
        ' we are dealing with a stacked bar chart. In order to do this we add a new column called 'Category Description'
        ' and set it to whatever. Then in SSRS we use this as the x-axis label. If the category description doesn't exist
        ' then we use the normal description instead
        <Extension()>
        Public Sub SetCategoryDescription(ByRef table As DataTable, ByVal ReportTagId As String, ByVal NewDescription As String)
            If Not table.Columns.Contains("CategoryDescription") Then
                table.Columns.Add("CategoryDescription", GetType(String))
                ' we ned to set the first row to a value (instead of just leaving it null), otherwise reporting services has 
                ' trouble detecting if the row exists or not, due to a bug in the way the datasets are processed
                table.Rows(0)("CategoryDescription") = ""
            End If

            Dim rows = table.AsEnumerable.Where(Function(r) r("ReportTagId").ToString = ReportTagId).ToList
            For Each r As DataRow In rows
                r("CategoryDescription") = NewDescription
            Next
        End Sub

        ' copies all the rows with a given TagId, and set the ReportId. This is useful because in the report we need to 
        ' duplicate the direct feed measure
        <Extension()>
        Public Sub CopyToGroup(ByRef table As DataTable, ByVal DestinationReportTagId As String, ByVal SourceTagId As String)
            Dim rows = table.AsEnumerable.Where(Function(r) r("TagId").ToString = SourceTagId And r("Attribute").ToString.ToLower.EndsWith("tonnes")).ToList

            For Each row As DataRow In rows
                Dim newRow = GenericDataTableExtensions.Copy(row)
                newRow("ReportTagId") = DestinationReportTagId
                table.Rows.Add(newRow)
            Next
        End Sub

        ' 'Moves' all the rows with the given TagId to the new ReportTagId, so that they will be grouped together in the same
        ' column on the report
        <Extension()>
        Public Sub MoveToGroup(ByRef table As DataTable, ByVal DestinationReportTagId As String, ByVal SourceTagId As String)
            Dim rows = table.AsEnumerable.Where(Function(r) r("TagId").ToString = SourceTagId And r("Attribute").ToString.ToLower.EndsWith("tonnes")).ToList

            For Each row As DataRow In rows
                row("ReportTagId") = DestinationReportTagId
            Next
        End Sub

        ' In order for the waterfall chart to work properly we add rows with a transparent color to the dataset. These
        ' will offset the bars on the chart and make it look like a waterfall chart, even though it is just a regular
        ' stacked bar chart.
        '
        ' This has to be done on a attribute by attribute basis in order for the aggregate values to be calulated properly.
        '
        ' Only a single offset row is added for each attribute, even if the data goes over mulitple months and consists
        ' of multiple rows for the values
        '
        <Extension()>
        Public Sub AddOffsetRow(ByRef table As DataTable, ByVal TagId As String, ByVal baseTagId As String, ByVal additionalOffsetTagId As String, InvertValue As Boolean, ByVal invertAdditionalOffset As Boolean, ByVal applyToTonnes As Boolean, ByVal applyToGradeTonnes As Boolean)
            Dim Attributes As String() = table.AsEnumerable.Select(Function(r) r("Attribute").ToString).Distinct.ToArray
            For Each Attribute In Attributes
                If Attribute.ToLower.EndsWith("tonnes") Then
                    ' apply only to the relevant rows
                    If ((applyToTonnes AndAlso Attribute.ToLower() = "tonnes") OrElse (applyToGradeTonnes AndAlso Not Attribute.ToLower = "tonnes")) Then
                        table.AddOffsetRow(TagId, baseTagId, additionalOffsetTagId, Attribute, InvertValue, invertAdditionalOffset)
                    End If
                End If
            Next
        End Sub

        ' Add the offset row for a single attribute. Only a single row will be added for the entire date range. This means that the
        ' report will not work properly, if the users decide to change it later on to use a month by month grouping
        <Extension()>
        Public Sub AddOffsetRow(ByRef table As DataTable, ByVal TagId As String, ByVal baseTagId As String, ByVal additionalOffsetTagId As String, ByVal Attribute As String, Optional InvertValue As Boolean = False, Optional invertAdditionalOffset As Boolean = False)
            If Not table.Columns.Contains("AttributeTonnes") Then
                Throw New Exception("Column 'AttributeTonnes' required in datatable in order to add an offset row")
            End If

            Dim baseValue As Double = table.AsEnumerable.Where(Function(r) r("ReportTagId").ToString = baseTagId AndAlso r("Attribute").ToString = Attribute).Select(Function(r) CDbl(r("AttributeTonnes"))).Sum()

            Dim additionalOffsetValue As Double = 0
            If (Not String.IsNullOrEmpty(additionalOffsetTagId)) Then
                additionalOffsetValue = table.AsEnumerable.Where(Function(r) r("TagId").ToString = additionalOffsetTagId AndAlso r("Attribute").ToString = Attribute).Select(Function(r) CDbl(r("AttributeTonnes"))).Sum()

                If Not additionalOffsetValue = 0 Then
                    If invertAdditionalOffset Then
                        baseValue = baseValue - additionalOffsetValue
                    Else
                        baseValue = baseValue + additionalOffsetValue
                    End If
                End If
            End If

            Dim TagValue As Double = table.AsEnumerable.Where(Function(r) r("TagId").ToString = TagId AndAlso r("Attribute").ToString = Attribute).Select(Function(r) CDbl(r("AttributeTonnes"))).Sum()
            Dim row As DataRow = table.AsEnumerable.FirstOrDefault(Function(r) r("TagId").ToString = TagId AndAlso r("Attribute").ToString = Attribute)

            If row Is Nothing Then
                Return
            End If

            ' when we have a negative value for the actual series, we need to reduce the offset
            ' by that amount so that the graph can render it properly. -ve values will always be shown
            ' at the bottom in a stacked chart in SSRS, so we need to reduce the offset, then show as
            ' an abs value on the ssrs. The conversion to an absolute value is done in the chart itself
            '
            ' If invert value is true, don't do this, because we want the -ve shown on the chart, but the offset
            ' to still be 'upwards', this is used with the PC-delta for example
            '
            If TagValue < 0 AndAlso Not InvertValue Then
                baseValue += TagValue
            End If

            ' similarly... if there is a positive value, but the invert flag is set.. this must appear to have a downward influence on the chart
            ' to acheve this deduct the offset by the tag value
            If InvertValue AndAlso TagValue > 0 Then
                baseValue -= TagValue
            End If

            Dim newRow = GenericDataTableExtensions.Copy(row)
            newRow("TagId") = "Offset"
            newRow("PresentationColor") = "Transparent"

            newRow("AttributeValue") = baseValue
            newRow("AttributeTonnes") = baseValue

            table.Rows.Add(newRow)
        End Sub

        ' Makes a copy of the current row. We need this in order to add the offset rows etc
        <Extension()>
        Public Function Copy(ByRef row As DataRow) As DataRow
            Dim destRow = row.Table.NewRow()
            destRow.ItemArray = CType(row.ItemArray.Clone(), Object())
            Return destRow
        End Function
    End Module
End Namespace

