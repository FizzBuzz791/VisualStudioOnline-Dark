Imports System.Configuration
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Web
Imports Snowden.Common.Security.RoleBasedSecurity
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Consulting.DataSeries.DataAccess
Imports Snowden.Consulting.DataSeries.DataAccess.DataTypes
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility

Namespace Approval
    Module ApprovalDataListData

        Friend Const OUTLIER_BACKGROUND_ABOVE As String = "LightSkyBlue"
        Friend Const OUTLIER_BACKGROUND_BELOW As String = "#82A0E8"
        Friend Const NON_OUTLIER_BACKGROUND As String = "Transparent"
        Friend Const OUTLIER_LEGEND_DIV_ID As String = "outlierLegend"

        Private Const OUTLIER_ANALYSIS_IMAGE_STANDARD As String = "outlieranalysis.png"
        Private Const OUTLIER_ANALYSIS_IMAGE_HIGHLIGHT As String = "outlieranalysishighlight.png"
        Private ReadOnly OutlierOrdinalOffsetMoth As Date = New Date(2009, 03, 01)  ' the month representing ordinal 0 in outlier detection functionality
        Private Const OUTLIER_QUEUE_ENTRY_TYPE As String = "OutlierProcessRequest" ' name describing outlier queue entry type
        Private Const DATA_RETRIEVAL_QUEUE_ENTRY_TYPE As String = "DataRetrievalRequest" ' name describing outlier queue entry type

        Private Const OUTLIER_DISPLAY_MININUM_DATE_SETTING_NAME As String = "OUTLIER_DISPLAY_MINIMUM_DATE"
        Private Const OUTLIER_DISPLAY_SUPPRESS_BY_APPROVAL_MAXIMUM_DATE_SETTING_NAME As String = "OUTLIER_DISPLAY_SUPPRESS_BY_APPROVAL_MAXIMUM_DATE"
        Private Const OUTLIER_DISPLAY_SUPPRESS_WHEN_CALCULATING_SETTING_NAME As String = "OUTLIER_DISPLAY_SUPPRESS_WHEN_CALCULATING"

        Public Property DalUtility As IUtility
        Public Property ApprovalMonth As Date

        Public Class OutlierDetails
            Public ProjectedValue As Double
            Public DeviationInSd As Double?
            Public SeriesId As Integer
            Public IsOutlier As Boolean
        End Class

        Public Function CreateValidationTableData(connectionString As String, nodeLevel As Int32, locationId As Int32, childLocations As Boolean,
            editPermissions As Boolean, calcId As String, parentNodeRowId As String, userId As Int32, forceApprovalCheckDisabled As Boolean,
            Optional ByRef userSecurity As IUserSecurity = Nothing, Optional ByRef areOutliersDisplayed As Boolean = False, 
            Optional ByVal nextOutlierDetectionQueueEntryMonth As Date? = Nothing) As DataTable

            Dim session As New ReportSession(connectionString) With {
                .Context = ReportContext.ApprovalListing,
                .IncludeProductSizeBreakdown = True,
                .IncludeModelDataForInactiveLocations = True, ' data for inactive pits and other locations should be included
                .UserSecurity = userSecurity ' allow the calculations to access the security model
            }

            Dim approvalDataList As DataTable = ValidationApprovalData.GetValidationData(session, ApprovalMonth,
                DateAdd(DateInterval.Day, -1, DateAdd(DateInterval.Month, 1, ApprovalMonth)), locationId,
                childLocations, calcId)

            Dim presentationApprovalDataList As DataTable = CreatePresentationTable(approvalDataList, session)
            
            DetermineLocationCalcBlocks(presentationApprovalDataList)

            areOutliersDisplayed = DetermineIfOutliersShouldBeDisplayed(DetermineMinSignOff(approvalDataList), nextOutlierDetectionQueueEntryMonth)
            approvalDataList.Dispose()

            AddOutliers(presentationApprovalDataList, areOutliersDisplayed, connectionString, locationId, childLocations, parentNodeRowId, nodeLevel)

            ' Create the new check box column for approvals
            AddApprovalCheck(presentationApprovalDataList, locationId,
                editPermissions, "TagId", "PresentationEditable", session, userId, forceApprovalCheckDisabled)

            UpdateBeneDescriptions(presentationApprovalDataList, MaterialType.GetMaterialType(session, "Bene Product"))

            session.Dispose()

            Return presentationApprovalDataList
        End Function

        Private Function DetermineIfOutliersShouldBeDisplayed(minSignoffDate As Date?, nextOutlierDetectionQueueEntryMonth As Date?) As Boolean

            ' determine the cutoff dates for outlier display
            Dim outlierDisplayMinimumDate As DateTime = DateTime.MinValue
            Dim outlierDisplaySuppressByApprovalMaximumDate = DateTime.MinValue
            Dim displayOutliers = True

            If (nextOutlierDetectionQueueEntryMonth.HasValue AndAlso nextOutlierDetectionQueueEntryMonth.Value <= approvalMonth) Then
                Dim outlierDisplaySuppressWhenCalculatingSetting As String = dalUtility.GetSystemSetting(OUTLIER_DISPLAY_SUPPRESS_WHEN_CALCULATING_SETTING_NAME)
                If (String.IsNullOrEmpty(outlierDisplaySuppressWhenCalculatingSetting) OrElse outlierDisplaySuppressWhenCalculatingSetting = "TRUE") Then
                    displayOutliers = False
                End If
            End If

            If displayOutliers Then
                Dim outlierDisplayMinimumDateSetting As String = dalUtility.GetSystemSetting(OUTLIER_DISPLAY_MININUM_DATE_SETTING_NAME)
                If (Not String.IsNullOrEmpty(outlierDisplayMinimumDateSetting)) Then
                    DateTime.TryParse(outlierDisplayMinimumDateSetting, outlierDisplayMinimumDate)
                End If

                Dim outlierDisplaySuppressByApprovalMaximumDateSetting As String =
                        dalUtility.GetSystemSetting(OUTLIER_DISPLAY_SUPPRESS_BY_APPROVAL_MAXIMUM_DATE_SETTING_NAME)
                If (Not String.IsNullOrEmpty(outlierDisplaySuppressByApprovalMaximumDateSetting)) Then
                    DateTime.TryParse(outlierDisplaySuppressByApprovalMaximumDateSetting, outlierDisplaySuppressByApprovalMaximumDate)
                End If

                If (approvalMonth < outlierDisplayMinimumDate OrElse (minSignoffDate.HasValue AndAlso minSignoffDate.Value < outlierDisplaySuppressByApprovalMaximumDate)) Then
                    displayOutliers = False
                End If
            End If

            Return displayOutliers
        End Function

        ''' <summary>
        ''' Determine the minimum signoff date (if any) within a set of approval data
        ''' </summary>
        ''' <param name="approvalDataList">data list to be checked</param>
        ''' <returns>The minimum signoff date within the table, or null if there have been no signoffs</returns>
        Private Function DetermineMinSignOff(approvalDataList As DataTable) As Date?
            Dim minDate As Date?

            If (Not approvalDataList Is Nothing) Then
                For Each row As DataRow In approvalDataList.Rows
                    If (row("SignOffDate") IsNot DBNull.Value) Then
                        Dim signOffDate = row.AsDate("SignOffDate")
                        If (minDate Is Nothing OrElse minDate.Value > signOffDate) Then
                            minDate = signOffDate
                        End If
                    End If
                Next
            End If

            Return minDate
        End Function

        Private Sub AddOutliers(presentationApprovalDataList As DataTable, areOutliersDisplayed As Boolean, connectionString As String, locationId As Int32,
                                childLocations As Boolean, parentNodeRowId As String, nodeLevel As Int32)

            ' get outlier counts by group
            Dim outlierCountByGroup As Dictionary(Of String, Integer) = Nothing

            If (areOutliersDisplayed) Then
                outlierCountByGroup = CreateOutlierCountByGroupDictionary(connectionString, locationId)
            End If

            AddAdditionalRows(presentationApprovalDataList, locationId, childLocations, parentNodeRowId, nodeLevel, outlierCountByGroup)

            If childLocations Then
                AddNodeLocationNameRemoveInvalidLocations(presentationApprovalDataList, locationId)
            End If
        End Sub

        Private Sub UpdateBeneDescriptions(ByRef table As DataTable, beneMaterialTypeId As Integer)
            For Each row As DataRow In table.Rows
                Dim materialType As Integer

                If (Not row("MaterialTypeId") Is Nothing AndAlso Integer.TryParse(row("MaterialTypeId").ToString(), materialType) AndAlso materialType = beneMaterialTypeId) Then
                    Select Case row("CalcId").ToString()
                        Case "MiningModelCrusherEquivalent"
                            If (Not row("Description").ToString().EndsWith("Bene Product")) Then
                                row("Description") = row("Description").ToString().Replace("(A-y+z)", "(Abene-ybene+zbene)")
                            End If
                        Case "MiningModel"
                            row("Description") = row("Description").ToString().Replace("A:", "Abene:")
                        Case "ExPitToOreStockpile"
                            row("Description") = row("Description").ToString().Replace("y:", "ybene:")
                        Case "StockpileToCrusher"
                            row("Description") = row("Description").ToString().Replace("z:", "zbene:")
                    End Select
                End If
            Next
        End Sub

        Private Function CreateBlankRow(table As DataTable) As DataRow
            Dim blankRow As DataRow = table.NewRow()
            blankRow("Type") = CalculationResultType.Hidden
            Return blankRow
        End Function

        Private Function ListOfMaterialTypes(table As DataTable, session As ReportSession) As IDictionary(Of Int32?, String)
            Dim list As New Dictionary(Of Int32?, String)
            Dim allMaterialTypelist As IDictionary(Of Int32, String) = session.GetReportMaterialList()
            Dim row As DataRow
            Dim materialTypeId As Int32

            For Each row In table.Select("", "MaterialTypeId Desc")
                If Int32.TryParse(row("MaterialTypeId").ToString(), materialTypeId) Then
                    If Not list.ContainsKey(materialTypeId) AndAlso allMaterialTypelist.ContainsKey(materialTypeId) Then
                        list.Add(materialTypeId, allMaterialTypelist(materialTypeId))
                    End If
                End If
            Next

            Return list
        End Function

        Private Function CopyRow(row As DataRow) As DataRow
            Dim newRow = row.Table.NewRow()
            newRow.ItemArray = row.ItemArray
            Return newRow
        End Function

        Private Function CreatePresentationTable(table As DataTable, session As ReportSession) As DataTable
            Dim presentationTable As DataTable = table.Copy()
            Dim row As DataRow
            Dim previousRow As DataRow = Nothing
            Dim i As Integer

            Dim filteredRows As IEnumerable(Of DataRow)
            Dim filteredRow As DataRow
            Dim holdingRows As New List(Of DataRow)
            Const materialTypeGroupDepth = 1
            Dim materialTypes As Int32
            Dim productSizesSeen As New HashSet(Of String)
            Dim rootCalcIdsSeen As New HashSet(Of String)
            Dim locationIdsSeen As New HashSet(Of String)

            Try
                ' Build a list of material types to be represented
                Dim materialList As IDictionary(Of Int32?, String) = ListOfMaterialTypes(table, session)

                presentationTable.Columns.Add(New DataColumn("MaterialTypeGroup", GetType(Boolean), ""))

                ' Work backwards through the table
                For i = presentationTable.Rows.Count - 1 To 0 Step -1
                    row = presentationTable.Rows(i)

                    ' Remove any Geology model rows that do not have a specific material type
                    If row("CalcId").ToString() = ModelGeology.CalculationId Then
                        If Not IsDBNull(row("MaterialTypeId")) Then
                            presentationTable.Rows.Remove(row)
                            row = previousRow
                        End If
                    End If

                    If Not row Is Nothing Then
                        Dim rootCalcId As String = row("RootCalcId").ToString()
                        Dim productSize As String = row("ProductSize").ToString()

                        rootCalcIdsSeen.Add(rootCalcId)
                        productSizesSeen.Add(productSize)
                        locationIdsSeen.Add(row("LocationId").ToString())

                        ' If there is more than one material type, then the output is extended to incnlude material type rows
                        If materialList.Count > 1 Then
                            If row("CalculationDepth").ToString() = materialTypeGroupDepth.ToString() And
                                ((rootCalcId = "F3Factor" And row("CalcId").ToString = "MiningModelShippingEquivalent") OrElse
                                 (rootCalcId = "F25Factor" And row("CalcId").ToString = "MiningModelOreForRailEquivalent")) Then
                                'insert rows below, one for each material type.
                                For Each material In materialList
                                    filteredRows = holdingRows.Where(Function(t) _
                                        t.Item("RootCalcId").ToString() = rootCalcId _
                                        And IntNullableEqual(t.Item("LocationId"), row("LocationId")) _
                                        And IntNullableEqual(t.Item("MaterialTypeId"), material.Key))

                                    For Each filteredRow In filteredRows.ToArray()
                                        presentationTable.Rows.InsertAt(filteredRow, i + 1)
                                        filteredRow("CalculationDepth") = Convert.ToInt32(filteredRow("CalculationDepth")) + 1
                                        holdingRows.Remove(filteredRow)

                                        ' This is the material type row itself
                                        If filteredRow("CalculationDepth").ToString() = "3" Then
                                            Dim row2 As DataRow = presentationTable.NewRow()
                                            row2.ItemArray = filteredRow.ItemArray
                                            row2("CalculationDepth") = Convert.ToInt32(filteredRow("CalculationDepth")) - 1
                                            row2("Description") = materialList(Convert.ToInt32(filteredRow("MaterialTypeId")))
                                            row2("MaterialTypeGroup") = True
                                            row2("TagId") = ""
                                            row2("Approved") = DBNull.Value
                                            row2("SignOff") = DBNull.Value
                                            row2("SignOffDate") = DBNull.Value
                                            presentationTable.Rows.InsertAt(row2, i + 1)
                                        End If
                                    Next
                                Next

                            ElseIf row("CalculationDepth").ToString() = materialTypeGroupDepth.ToString() _
                                And Not IsDBNull(row("MaterialTypeId")) _
                                AndAlso materialList.ContainsKey(Convert.ToInt32(row("MaterialTypeId"))) Then

                                row("CalculationDepth") = Convert.ToInt32(row("CalculationDepth")) + 1
                                row("Description") = materialList(Convert.ToInt32(row("MaterialTypeId")))
                                row("MaterialTypeGroup") = True
                                row("TagId") = ""
                                row("Approved") = DBNull.Value
                                row("SignOff") = DBNull.Value
                                row("SignOffDate") = DBNull.Value

                                filteredRows = holdingRows.Where(Function(t) _
                                 t.Item("RootCalcId").ToString() = rootCalcId _
                                 And IntNullableEqual(t.Item("LocationId"), row("LocationId")) _
                                 And IntNullableEqual(t.Item("MaterialTypeId"), row("MaterialTypeId")) _
                                 And t.Item("ProductSize").ToString = row("ProductSize").ToString())

                                For Each filteredRow In filteredRows.ToArray()
                                    presentationTable.Rows.InsertAt(filteredRow, i + 1)
                                    filteredRow("CalculationDepth") = Convert.ToInt32(filteredRow("CalculationDepth")) + 1
                                    holdingRows.Remove(filteredRow)
                                Next
                            ElseIf Not IsDBNull(row("CalculationDepth")) AndAlso Convert.ToInt32(row("CalculationDepth")) > 1 Then
                                'If the row has so far not been processed, but it relates to a CalcId for which there is data within the table
                                'matching the location of the row that also has non-null material type information
                                materialTypes = table.Select().Where(Function(t) _
                                    t.Item("CalcId").ToString() = row("CalcId").ToString() _
                                    And IntNullableEqual(t.Item("LocationId"), row("LocationId")) _
                                    And Not IsDBNull(t.Item("MaterialTypeId"))).Count()

                                If materialTypes > 0 Then
                                    ' add the row to the holding list
                                    holdingRows.Add(CopyRow(row))
                                    ' and remove it from the main table
                                    row.Table.Rows.Remove(row)
                                    row = previousRow
                                End If
                            End If
                        Else
                            ' if not more than 1 material type, then just keep rows with null Material TypeId
                            If Not IsDBNull(row("MaterialTypeId")) Then
                                presentationTable.Rows.Remove(row)
                                row = previousRow
                            End If
                        End If
                    End If

                    previousRow = row
                Next

                ' Reposition lump and fines breakdowns
                ' but only do this if the TOTAL product size has been seen
                If productSizesSeen.Contains(CalculationConstants.PRODUCT_SIZE_TOTAL) Then
                    For Each productSizeToProcess As String In productSizesSeen
                        For Each rootCalcIdToProcess As String In rootCalcIdsSeen
                            For Each locationIdToProcess As String In locationIdsSeen

                                If Not String.IsNullOrEmpty(productSizeToProcess) And Not productSizeToProcess = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                                    Dim tempTableForMove As DataTable = presentationTable.Clone

                                    ' iterate through the set.. for all rows matching this criteria.. remove them
                                    For i = presentationTable.Rows.Count - 1 To 0 Step -1
                                        row = presentationTable.Rows(i)

                                        If (row(ColumnNames.PRODUCT_SIZE).ToString = productSizeToProcess And
                                            row(ColumnNames.ROOT_CALC_ID).ToString = rootCalcIdToProcess And
                                            row("LocationId").ToString = locationIdToProcess) Then

                                            ' increment the calculation depth of the row
                                            row(ColumnNames.CALCULATION_DEPTH) = Convert.ToInt32(row("CalculationDepth")) + 1

                                            ' copy the row to the temporary table for the later reinsertion at a different position
                                            Dim copiedRow As DataRow = tempTableForMove.NewRow()
                                            copiedRow.ItemArray = row.ItemArray
                                            tempTableForMove.Rows.Add(copiedRow)

                                            ' remove the row
                                            presentationTable.Rows.RemoveAt(i)
                                        End If
                                    Next

                                    Dim insertionIndex = 0

                                    ' Find the insert position.. and reinsert the rows
                                    For i = 0 To presentationTable.Rows.Count - 1 Step 1
                                        row = presentationTable.Rows(i)
                                        If (row(ColumnNames.PRODUCT_SIZE).ToString = CalculationConstants.PRODUCT_SIZE_TOTAL And
                                            row(ColumnNames.ROOT_CALC_ID).ToString = rootCalcIdToProcess And
                                            row("LocationId").ToString = locationIdToProcess) Then

                                            ' This is the row after which the rows should be inserted
                                            insertionIndex = i + 1

                                            Exit For
                                        End If
                                    Next

                                    For i = 0 To tempTableForMove.Rows.Count - 1 Step 1
                                        row = tempTableForMove.Rows(i)

                                        Dim copiedRow As DataRow = presentationTable.NewRow()
                                        copiedRow.ItemArray = row.ItemArray
                                        presentationTable.Rows.InsertAt(copiedRow, insertionIndex)
                                    Next
                                End If
                            Next
                        Next
                    Next
                End If

                previousRow = Nothing

                Dim rowType As Integer
                Dim previousRowType As Integer

                ' Add in line breaks between changes in rootcalcid or product size where the location is the same (ie break between F1 and F2 etc)
                For i = presentationTable.Rows.Count - 1 To 0 Step -1
                    row = presentationTable.Rows(i)

                    If Not Int32.TryParse(row("Type").ToString, rowType) Then
                        rowType = -1
                    End If

                    If Not previousRow Is Nothing Then
                        Dim needBlankRow = False

                        ' Add space when going from a ratio to a non ratio row
                        If rowType <> 0 And previousRowType = 0 AndAlso
                            (previousRow(ColumnNames.PRODUCT_SIZE).ToString() = CalculationConstants.PRODUCT_SIZE_TOTAL) Then
                            needBlankRow = True
                        ElseIf previousRow("LocationId").ToString() = row("LocationId").ToString() _
                            AndAlso (previousRow(ColumnNames.PRODUCT_SIZE).ToString() = CalculationConstants.PRODUCT_SIZE_TOTAL) _
                            AndAlso (previousRow("RootCalcId").ToString() <> row("RootCalcId").ToString()) Then
                            needBlankRow = True
                        End If

                        ' if we are about to insert a blank row, but the calc type if bene ratio, then don't bother
                        ' it should be treated as a normal value
                        If needBlankRow And previousRow.AsString("CalcId") = "BeneRatio" Then
                            needBlankRow = False
                        End If

                        If needBlankRow Then
                            Dim dataRow As DataRow = CreateBlankRow(presentationTable)
                            dataRow(ColumnNames.PRODUCT_SIZE) = row(ColumnNames.PRODUCT_SIZE)
                            presentationTable.Rows.InsertAt(dataRow, i + 1)
                        End If
                    End If

                    previousRow = row
                    previousRowType = rowType
                Next

                Return presentationTable

            Catch ex As Exception
                ' TODO: Really should log this or something similar.
            End Try

            Return Nothing

        End Function

        ''' <summary>
        ''' Determine the month associated with the next outlier detection queue entry
        ''' </summary>
        ''' <param name="connectionString">connection string for database access</param>
        ''' <returns>The month associated with the next queue entry if any, otherwise null</returns>
        Friend Function DetermineMonthForNextOutlierQueueEntry(connectionString As String) As Date?

            Dim month As DateTime? = Nothing
            Dim provider As IDataSeriesDataAccessProvider = New SqlServerDataSeriesDataAccessProvider(connectionString)

            Dim queueEntry As SeriesQueueEntry = provider.GetNextPendingQueueEntry(OUTLIER_QUEUE_ENTRY_TYPE)
            If (Not queueEntry Is Nothing) Then
                month = OutlierOrdinalOffsetMoth.AddMonths(CType(queueEntry.Ordinal, Int32))
            End If

            queueEntry = provider.GetNextPendingQueueEntry(DATA_RETRIEVAL_QUEUE_ENTRY_TYPE)
            If (Not queueEntry Is Nothing) Then
                Dim dataRetrievalQueueDate As Date = OutlierOrdinalOffsetMoth.AddMonths(CType(queueEntry.Ordinal, Int32))

                If month Is Nothing OrElse dataRetrievalQueueDate < month Then
                    month = dataRetrievalQueueDate
                End If
            End If

            Return month

        End Function

        Private Function IntNullableEqual(l As Object, r As Object) As Boolean
            Dim number As Int32
            Dim lNumber As Int32? = Nothing
            Dim rNumber As Int32? = Nothing
            If Int32.TryParse(l.ToString(), number) Then
                lNumber = number
            End If
            If Int32.TryParse(r.ToString(), number) Then
                rNumber = number
            End If

            Return (rNumber.HasValue And lNumber.HasValue AndAlso rNumber.Value = lNumber.Value) _
             Or (Not rNumber.HasValue AndAlso Not lNumber.HasValue)
        End Function

        ''' <summary>
        ''' Loop through all rows to determine Calc Block Top,Mid,Parent and Bottom.
        ''' </summary>
        ''' <param name="table"></param>
        Private Sub DetermineLocationCalcBlocks(table As DataTable)
            Dim i As Int32
            Dim lastTagSet As String = Nothing
            Dim lastTagRowId As Int32

            table.Columns.Add(New DataColumn("CalcBlockTop", GetType(Boolean), ""))
            table.Columns.Add(New DataColumn("CalcBlockBot", GetType(Boolean), ""))
            table.Columns.Add(New DataColumn("CalcBlockMid", GetType(Boolean), ""))
            table.Columns.Add(New DataColumn("CalcBlockParent", GetType(Int32), ""))

            For i = 0 To table.Rows.Count - 1 Step 1
                Dim row As DataRow = table.Rows(i)
                Dim thisTagSet As String = row("RootCalcId").ToString & row("LocationId").ToString()
                Dim nextRowTagSet = ""
                If i < table.Rows.Count - 1 Then
                    Dim nextRow As DataRow = table.Rows(i + 1)
                    nextRowTagSet = nextRow("RootCalcId").ToString & nextRow("LocationId").ToString()
                End If

                'Check to see if it is a top record
                If thisTagSet <> "" And lastTagSet <> thisTagSet Then
                    lastTagSet = thisTagSet
                    lastTagRowId = i
                    row("CalcBlockTop") = True
                End If

                ' Check to see if this is a middle row
                If thisTagSet <> "" AndAlso lastTagSet = thisTagSet Then
                    row("CalcBlockMid") = True
                    row("CalcBlockParent") = lastTagRowId
                End If

                ' Check to see if this is the bottom row
                If thisTagSet <> "" And thisTagSet <> nextRowTagSet Then
                    row("CalcBlockBot") = True
                End If
            Next
        End Sub

        Private Sub AddNodeLocationNameRemoveInvalidLocations(table As DataTable, parentLocationId As Int32)
            Dim locations = DalUtility.GetBhpbioLocationListWithOverride(parentLocationId, Convert.ToInt16(True), ApprovalMonth)
            Dim locationId As Int32

            For i = table.Rows.Count - 1 To 0 Step -1
                Dim row As DataRow = table.Rows(i)

                If Int32.TryParse(row("LocationId").ToString(), locationId) Then
                    If Not IsDBNull(row("CalcBlockTop")) Then
                        Dim location As DataRow = (locations.Select(String.Format("Location_Id = {0}", locationId)))(0)
                        Dim locationRow As DataRow = table.NewRow()
                        locationRow("Description") = location("Name").ToString()
                        locationRow("CalcBlockTop") = True
                        locationRow("CalcBlockMid") = True
                        locationRow("nodeRowId") = row("nodeRowId").ToString() & "LocName"
                        row("CalcBlockTop") = DBNull.Value
                        table.Rows.InsertAt(locationRow, i)
                    End If
                Else ' Remove as the location was not valid.
                    table.Rows.RemoveAt(i)
                End If
            Next
        End Sub

        Private Function HasLiveViewer(tagId As String) As Boolean
            Dim contains As New List(Of String)
            Dim notContains As New List(Of String)
            contains.Add("MiningModel")
            contains.Add("GradeControlModel")
            contains.Add("GradeControlSTGM")
            contains.Add("GeologyModel")
            contains.Add("OreShipped")
            contains.Add("PortStockpileDelta")
            contains.Add("PortBlendedAdjustment")
            contains.Add("SitePostCrusherStockpileDelta")
            contains.Add("HubPostCrusherStockpileDelta")
            contains.Add("MineProductionActuals")
            contains.Add("StockpileToCrusher")
            contains.Add("ExPitToOreStockpile")
            contains.Add("OreForRail")
            notContains.Add("F25MiningModelOreForRailEquivalent")
            notContains.Add("F25MiningModelCrusherEquivalent")
            notContains.Add("F3MiningModelShippingEquivalent")
            notContains.Add("F3MiningModelCrusherEquivalent")

            HasLiveViewer = False
            For Each item As String In contains
                If tagId.Contains(item) And Not notContains.Contains(tagId) Then
                    HasLiveViewer = True
                End If
            Next
        End Function

        Private Function HasResourceClassificationLink(calcId As String, Optional tagId As String = "") As Boolean
            Dim calculationList = New String() {
                "GeologyModel",
                "MiningModel",
                "GradeControlModel",
                "GradeControlSTGM",
                "ShortTermGeologyModel",
                "F1Factor",
                "F15Factor"
            }

            Return calculationList.Contains(calcId) AndAlso Not tagId.StartsWith("F3") AndAlso Not tagId.StartsWith("F25")
        End Function

        Private Sub AddAdditionalRows(approvalDataList As DataTable, locationId As Int32, childLocations As Boolean, parentNodeRowId As String,
                                      nodeLevel As Int32, Optional ByVal outlierCountByAnalysisGroup As IDictionary(Of String, Integer) = Nothing)

            Dim expandable As Boolean
            Const expandImage = "<img src=""../images/plus.png"" id=""Image_{0}"" onclick=""ToggleApprovalNode('Node_{0}', {1}, '{2}', {3}, '{4}')"">"
            Dim lastExpandableNodeId As String = String.Empty
            Dim locationIdParsed As Int32
            Dim nodeRowId As String
            Dim rowIdIncrementer = 0
            Dim i As Int32
            Dim lastExpandableNodeProductSize As String = Nothing
            Dim rowType As Integer
            Const defaultSpacerBlock = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
            Const lumpFinesSpacerBlockAtChildLevels = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"

            approvalDataList.Columns.Add(New DataColumn("NodeRowId", GetType(String), ""))
            approvalDataList.Columns.Add(New DataColumn("Investigation", GetType(String), ""))

            Dim locationExpandable As Boolean = approvalDataList.Columns.Contains("LocationExpandable")

            For i = 0 To approvalDataList.Rows.Count - 1 Step 1
                Dim row As DataRow = approvalDataList.Rows(i)

                If Not Int32.TryParse(row("Type").ToString, rowType) Then
                    rowType = -1
                End If

                If Not Int32.TryParse(row("locationId").ToString, locationIdParsed) Then
                    locationIdParsed = 1
                End If

                Dim effectiveNodeLevel As Int32 = nodeLevel

                Dim productSize As String = row(ColumnNames.PRODUCT_SIZE).ToString
                If Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                    effectiveNodeLevel = effectiveNodeLevel + 1
                End If

                Dim spacerBlock As String = defaultSpacerBlock
                If Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL AndAlso Not String.IsNullOrEmpty(parentNodeRowId) Then
                    spacerBlock = lumpFinesSpacerBlockAtChildLevels
                End If

                ' On change of product size, the last expandable node id is no longer relevant
                If Not String.IsNullOrEmpty(productSize) AndAlso Not productSize = lastExpandableNodeProductSize Then
                    lastExpandableNodeId = Nothing
                    lastExpandableNodeProductSize = Nothing
                End If

                ' Get expandable
                If locationExpandable Then
                    If rowType = 0 AndAlso Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                        ' Lump and Fines ratio nodes are always expandable
                        expandable = True
                    ElseIf Not Boolean.TryParse(row("LocationExpandable").ToString(), expandable) Then
                        expandable = False
                    End If
                End If

                Dim effectiveParentNodeId As String = parentNodeRowId

                ' Get location Id into locationIdParsed
                If expandable Then
                    If Not childLocations Then
                        If locationId = -1 Then
                            locationIdParsed = 1
                        Else
                            locationIdParsed = locationId
                        End If
                    Else
                        If Not Int32.TryParse(row("locationId").ToString, locationIdParsed) Then
                            locationIdParsed = 1
                        End If
                    End If
                Else
                    If Not String.IsNullOrEmpty(lastExpandableNodeId) Then
                        If Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL AndAlso Not String.IsNullOrEmpty(parentNodeRowId) Then
                            If lastExpandableNodeId.StartsWith(parentNodeRowId) Then
                                effectiveParentNodeId = lastExpandableNodeId
                            Else
                                effectiveParentNodeId = $"{parentNodeRowId}~{lastExpandableNodeId}"
                            End If
                        End If
                    End If
                    If String.IsNullOrEmpty(effectiveParentNodeId) Then
                        effectiveParentNodeId = lastExpandableNodeId
                    End If
                End If

                ' Obtain the Node Row Id
                If Not childLocations AndAlso (productSize = CalculationConstants.PRODUCT_SIZE_TOTAL OrElse String.IsNullOrEmpty(effectiveParentNodeId)) Then
                    nodeRowId = String.Format("Node_{0}_{1}_R{2}", locationId, productSize, rowIdIncrementer.ToString())
                Else
                    nodeRowId = String.Format("{0}~{1}_R{2}", effectiveParentNodeId, productSize, rowIdIncrementer.ToString())
                End If
                rowIdIncrementer = rowIdIncrementer + 1

                If Not IsDBNull(row("Type")) Then
                    If expandable Then
                        If Not childLocations Then
                            nodeRowId = String.Format("Node_{0}_{1}_{2}", row("CalcId").ToString(), productSize, locationId)
                        Else
                            nodeRowId = String.Format("{0}~{1}_{2}", effectiveParentNodeId, productSize, locationIdParsed)
                        End If
                    ElseIf row("CalcBlockBot").ToString().ToLower() = "true" Then
                        Dim productSizeForCalcBlock As String = productSize

                        If productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                            productSizeForCalcBlock = String.Empty
                        End If

                        If Not childLocations Then
                            nodeRowId = String.Format("Node_{0}_{1}_{2}~End",
                                                      approvalDataList.Rows(Convert.ToInt32(row("CalcBlockParent").ToString()))("CalcId").ToString(),
                                                      productSizeForCalcBlock, locationId)
                        Else
                            nodeRowId = String.Format("{0}~{1}_{2}~End", effectiveParentNodeId, productSizeForCalcBlock, locationIdParsed)
                        End If
                    End If
                End If
                row("nodeRowId") = nodeRowId

                If row("CalcId").ToString = ModelGeology.CalculationId AndAlso Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                    expandable = False
                End If

                ' Set Description
                If expandable Then
                    lastExpandableNodeId = nodeRowId
                    lastExpandableNodeProductSize = productSize
                    row("Description") = String.Format(expandImage, nodeRowId.Replace("Node_", ""),
                        effectiveNodeLevel + 1, row("CalcId").ToString(), locationIdParsed,
                        ApprovalMonth) & row("Description").ToString()
                    If childLocations Then
                        row("Description") = defaultSpacerBlock & row("Description").ToString()
                    End If
                    If Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                        row("Description") = row("Description").ToString() & String.Format("<script>ApprovalCollapseNodeRow('{0}');</script>", nodeRowId)
                    End If
                Else
                    If Not IsDBNull(row("Type")) Then
                        row("Description") = spacerBlock & row("Description").ToString()
                    End If
                End If

                ' Set the investigation tag
                If Not childLocations Then
                    Dim investigationColumn As New StringBuilder()

                    If (Not outlierCountByAnalysisGroup Is Nothing) Then
                        ' Add the outlier analysis link
                        Dim analysisGroupId As String = String.Format("OutlierAnalysis{0}", row.AsString("CalcId"))
                        Dim materialTypeIdForCountLookup As String = row.AsString("MaterialTypeId")
                        Dim countKey As String = String.Format("{0}_{1}_{2}", analysisGroupId, productSize, materialTypeIdForCountLookup)

                        ' work out if the icon should be the standard one or the highlight one
                        Dim outlierAnalysisImageName As String = OUTLIER_ANALYSIS_IMAGE_STANDARD

                        If (outlierCountByAnalysisGroup.ContainsKey(countKey)) Then
                            outlierAnalysisImageName = OUTLIER_ANALYSIS_IMAGE_HIGHLIGHT
                        End If

                        Dim outlierAnalysisImageElement =
                                String.Format(
                                    "<img src=""../images/1x1Trans.gif"" style=""filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='../images/{0}', sizingMethod='image');"" border=0>",
                                    outlierAnalysisImageName)
                        investigationColumn.Append(String.Format("<a target=""{0}"" href=""{1}"" title=""Outlier Analysis"">{2}</a>",
                             "newVal",
                             String.Format("{0}/Analysis/OutlierAnalysisAdministration.aspx?AnalysisGroup={1}&MonthStart={2:dd-MMM-yyyy}&MonthEnd={2:dd-MMM-yyyy}&LocationId={3}&ProductSize={4}&AttributeFilter=All",
                              HttpRuntime.AppDomainAppVirtualPath,
                              analysisGroupId, ApprovalMonth,
                              locationId,
                              productSize),
                             outlierAnalysisImageElement))
                    End If

                    ' Add the live viewer link if there is one
                    If HasLiveViewer(row("TagId").ToString()) Then
                        investigationColumn.Append("&nbsp;&nbsp;")
                        investigationColumn.Append(String.Format("<a target=""{0}"" href=""{1}"" title=""Live Data Viewer"">{2}</a>",
                                                                 "newVal",
                                                                 String.Format(
                                                                     "ApprovalDataReview.aspx?TagId={0}&DateFrom={1:dd-MMM-yyyy}&DateTo={2:dd-MMM-yyyy}&LocationId={3}&ProductSize={4}",
                                                                     row("TagId").ToString(), ApprovalMonth,
                                                                     DateAdd(DateInterval.Day, - 1, DateAdd(DateInterval.Month, 1, ApprovalMonth)),
                                                                     locationId, productSize),
                                                                 "<img src=""../images/1x1Trans.gif"" style=""filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='../images/search-small.png', sizingMethod='image');"" border=0>"))
                    Else 'Adds white icon to keep column formating for Resource Classification
                        investigationColumn.Append("&nbsp;&nbsp;")
                        investigationColumn.Append(GetPngImgHtml("../images/ico_white.png"))
                    End If

                    ' Add the Resource Classification link if there is one
                    If HasResourceClassificationLink(row.AsString("CalcId"), row.AsString("TagId")) AndAlso Not row.HasValue("MaterialTypeId") Then
                        investigationColumn.Append("&nbsp;&nbsp;")

                        Dim url = String.Format("ApprovalResourceClassification.aspx?CalculationID={0}&DateFrom={1:dd-MMM-yyyy}&DateTo={2:dd-MMM-yyyy}&LocationId={3}&ProductSize={4}",
                              row("CalcId").ToString(), ApprovalMonth, DateAdd(DateInterval.Day, -1, DateAdd(DateInterval.Month, 1, ApprovalMonth)),
                              locationId,
                              productSize)

                        Dim link = String.Format("<a target=""{0}"" href=""{1}"" title=""Resource Classification"">{2}</a>", "newVal", url, GetPngImgHtml("../images/rcico.png"))
                        investigationColumn.Append(link)
                    End If

                    row("Investigation") = investigationColumn.ToString()
                End If
            Next
        End Sub

        Private Function GetPngImgHtml(src As String) As String
            Return String.Format("<img src=""../images/1x1Trans.gif"" style=""filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='{0}', sizingMethod='image');"" border=0>", src)
        End Function

        Public Function ValidationTable_ItemCallback(textData As String, columnName As String, row As DataRow) As String
            Return ValidationTable_ItemCallbackWithOutlierCheck(textData, columnName, row, Nothing)
        End Function

        Public Function ValidationTable_ItemCallbackWithOutlierCheck(textData As String, columnName As String, row As DataRow,
            outlierDictionary As Dictionary(Of String, OutlierDetails)) As String

            Dim returnValue As String = textData.Trim
            Dim calculationDepth As Int32
            Dim type As CalculationResultType
            Dim inError As Boolean
            Dim errorMessage As String = row("ErrorMessage").ToString()
            Dim parsedNumber As Double

            Dim reportTagId = row.AsString("ReportTagId")
            Dim calcId = row.AsString("CalcId")
            Dim locationId = row.AsString("LocationId")
            Dim productSize = row("ProductSize").ToString()
            Dim materialTypeId = row.AsString("MaterialTypeId")

            ' Build a cell key for outlier checking
            Dim cellKey As String = String.Format("{0}_{1}_{2}_{3}_{4}", calcId, locationId, productSize, materialTypeId, columnName)

            Dim matchedOutlierDetails As OutlierDetails = Nothing
            If (Not outlierDictionary Is Nothing) Then
                outlierDictionary.TryGetValue(cellKey, matchedOutlierDetails)
            End If

            ' some cells (such as the moisture ones will always have no value, we want to show n/a in these
            ' cells so that the users will no get confused between this and a genuine null value. To change which
            ' cells should show n/a edit the IsCellNA function to return true for a tagId/columnName combination
            If FactorList.IsCellNA(reportTagId, columnName, row("ProductSize").ToString) Then
                If Not String.IsNullOrEmpty(textData) Then
                    Dim behaviour As String = ConfigurationManager.AppSettings.Get("approvalScreenNANotNullBehaviour")

                    If Not String.IsNullOrEmpty(behaviour) Then
                        behaviour = behaviour.ToLower()
                        If behaviour = "exception" Then
                            Throw New Exception(String.Format("N/A cell has non-null value ({0}/{1})", row("ReportTagId"), columnName))
                        ElseIf behaviour = "output" Then
                            Return textData
                        ElseIf behaviour = "outputwithmarkers" Then
                            Return String.Format("|{0}|", textData)
                        ElseIf behaviour = "outputerror" Then
                            Return "error"
                        End If
                    End If
                End If

                Return "n/a"
            End If

            If Not IsDBNull(row("Type")) Then
                type = DirectCast(row("Type"), CalculationResultType)
            End If

            Int32.TryParse(row("CalculationDepth").ToString(), calculationDepth)
            Boolean.TryParse(row("InError").ToString(), inError)

            ' Format the item depending on the type
            If IsDBNull(row("Type")) Then
                If columnName = "Description" Then
                    returnValue = "<b>" & returnValue & "</b>"
                Else
                    returnValue = ""
                End If
            ElseIf type = CalculationResultType.Hidden Then
                returnValue = ""
            ElseIf type = CalculationResultType.Ratio Then
                Dim rawValue As String = row(columnName).ToString
                Dim padding As String = String.Empty

                If Double.TryParse(rawValue, parsedNumber) Then
                    Dim formatString = FactorFormatHelper.GetFormat(columnName)

                    If calcId = "BeneRatio" Then
                        parsedNumber *= 100
                        formatString = "N2"
                    End If

                    returnValue = parsedNumber.ToString(formatString)
                End If

                If calculationDepth <= 1 Then
                    If columnName = "Description" AndAlso Not row(ColumnNames.PRODUCT_SIZE).ToString = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                        padding = RepeatString("&nbsp;&nbsp;", calculationDepth + 1)
                    End If

                    returnValue = "<b>" & padding & returnValue & "</b>"
                Else
                    If columnName = "Description" Then
                        returnValue = RepeatString("&nbsp;&nbsp;&nbsp;&nbsp;", calculationDepth - 1) & returnValue
                    End If
                End If

                ' the bene ratio should always be italic. It would be better to do this through CSS
                If calcId = "BeneRatio" Then
                    returnValue = String.Format("<i>{0}</i>", returnValue)
                End If
            Else
                If columnName = "Description" AndAlso calculationDepth = 1 Then
                    returnValue = "<font color=blue>" & returnValue & "</font>"
                ElseIf columnName = "Description" AndAlso calculationDepth > 1 Then
                    Dim spaces As String = RepeatString("&nbsp;&nbsp;&nbsp;&nbsp;", calculationDepth - 1)
                    returnValue = spaces & returnValue
                    If calculationDepth = 2 AndAlso Not productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                        returnValue = "<font color=blue>" & returnValue & "</font>"
                    End If
                ElseIf columnName = "Description" AndAlso calculationDepth = 3 Then
                    returnValue = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" & returnValue
                ElseIf columnName = "Tonnes" And inError = True Then
                    returnValue = String.Format("<span title=""{0}"">Err</span>", errorMessage)
                ElseIf columnName = "Tonnes" And Double.TryParse(returnValue, parsedNumber) Then
                    Dim tonnes As Double = parsedNumber / 1000
                    returnValue = tonnes.ToString(ReconcilorFunctions.SetNumericFormatDecimalPlaces(1))
                End If
            End If

            If (Not matchedOutlierDetails Is Nothing) Then
                ' Generate link for cell
                Dim linkColumns() As String = {"Tonnes", "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O"}
                If (linkColumns.Contains(columnName)) Then
                    Const reportId = 48
                    Const exportFormat = 11
                    Dim dateFrom As Date = Convert.ToDateTime(DalUtility.GetSystemSetting("SYSTEM_START_DATE"))
                    Dim dateTo = New DateTime(Date.Today.AddMonths(-1).Year, Date.Today.AddMonths(-1).Month, 1)
                    Dim highlightMarker As String
                    If (matchedOutlierDetails.IsOutlier) Then
                        highlightMarker = "outlier"
                    Else
                        highlightMarker = "normal"
                    End If
                    Dim chartUrl = String.Format("../Reports/ReportsRun.aspx?ReportId={0}&SeriesId={1}&DateFrom={2:yyyy-MM-dd}&DateTo={3:yyyy-MM-dd}&DateHighlight={4:yyyy-MM-dd}&ExportFormat={5}&HighlightMarker={6}",
                                              reportId, matchedOutlierDetails.SeriesId, dateFrom, dateTo, ApprovalMonth, exportFormat, highlightMarker)
                    returnValue = String.Format("<a href='{0}' target='_blank' style='color: black; text-decoration: none;'>{1}</a>", chartUrl, returnValue)
                End If

                ' This cell is an outlier surround the return value with the required outlier information and colouring
                Dim backGroundColour As String
                Dim deviationInSdPrefix = ""

                If (matchedOutlierDetails.IsOutlier) Then
                    If (matchedOutlierDetails.DeviationInSd > 0) Then
                        backGroundColour = OUTLIER_BACKGROUND_ABOVE
                    Else
                        backGroundColour = OUTLIER_BACKGROUND_BELOW
                    End If
                Else
                    backGroundColour = NON_OUTLIER_BACKGROUND
                End If

                If (matchedOutlierDetails.DeviationInSd > 0) Then
                    deviationInSdPrefix = "+"
                End If

                If (Not String.IsNullOrEmpty(returnValue)) Then
                    Dim decimalPlaces = 0
                    Dim divideBy As Double = 1

                    If (columnName = "Tonnes" AndAlso Not calcId.Contains("Factor")) Then
                        decimalPlaces = 0
                        divideBy = 1000 ' convert to ktonnes
                    End If

                    Dim lastDotPosition As Integer = returnValue.LastIndexOf("."c)

                    If (lastDotPosition > 0) Then
                        Dim beyondValueIndex = returnValue.IndexOf("<"c, lastDotPosition)
                        If (beyondValueIndex <= 0) Then
                            beyondValueIndex = returnValue.Length
                        End If

                        decimalPlaces = beyondValueIndex - lastDotPosition - 1
                    End If

                    Dim projectedValueDisplay As Double = matchedOutlierDetails.ProjectedValue / divideBy
                    Dim formatString = "#,##0"
                    If (decimalPlaces > 0) Then
                        formatString = String.Format("{0}.{1}", formatString, New String("0"c, decimalPlaces))
                    End If

                    Dim outlierInfo As String = String.Format("Projected Value: {0}&#013;Difference in SD: {1}{2:##0.0}&#013;Click this value to display it graphically", projectedValueDisplay.ToString(formatString), deviationInSdPrefix, matchedOutlierDetails.DeviationInSd)
                    returnValue = String.Format("<span style='background-color:{0};' title=""{1}"">{2}</span>", backGroundColour, outlierInfo, returnValue)
                End If
            End If

            Return returnValue
        End Function

        Friend Function CreateOutlierDetectionDictionary(connectionString As String, locationId As Integer) As Dictionary(Of String, OutlierDetails)
            Dim outlierDictionary As New Dictionary(Of String, OutlierDetails)()

            Using approvalDal As New SqlDalApproval(connectionString)
                Dim outlierTable As DataTable = approvalDal.GetBhpbioOutliersForLocation(Nothing, ApprovalMonth, ApprovalMonth, locationId, Nothing, Nothing, 0, includeDirectSubLocations:=True, includeAllSubLocations:=False, excludeTotalMaterialDuplicates:=False, includeAllPoints:=True)

                If (Not outlierTable Is Nothing) Then
                    For Each row As DataRow In outlierTable.Rows
                        ' create a cell key for the outlier
                        Dim calcId = row.AsString("CalculationId")
                        Dim outlierLocationId = row.AsString("LocationId")
                        Dim productSize = row("ProductSize").ToString()
                        Dim materialTypeId = row.AsString("MaterialTypeId")
                        Dim attribute = row.AsString("Attribute")
                        If (attribute = "Grade") Then
                            attribute = row.AsString("Grade")
                        End If
                        If (String.IsNullOrEmpty(attribute)) Then
                            attribute = "Tonnes" ' tonnes is teh default attribute
                        End If

                        ' Build a cell key for outlier checking
                        Dim cellKey As String = String.Format("{0}_{1}_{2}_{3}_{4}", calcId, outlierLocationId, productSize, materialTypeId, attribute)

                        Dim outlierDetails As New OutlierDetails() With {
                            .ProjectedValue = row.AsDbl("ProjectedValue"),
                            .DeviationInSd = row.AsDbl("DeviationInSD"),
                            .SeriesId = row.AsInt("SeriesId"),
                            .IsOutlier = row.AsBool("IsOutlier")
                        }

                        ' add the outlier to the dictionary
                        outlierDictionary(cellKey) = outlierDetails
                    Next
                End If
            End Using

            Return outlierDictionary
        End Function

        Friend Function CreateOutlierCountByGroupDictionary(connectionString As String, locationId As Integer) As Dictionary(Of String, Integer)
            Dim countDictionary As New Dictionary(Of String, Integer)()

            Using approvalDal As New SqlDalApproval(connectionString)
                Dim outlierCountTable As DataTable = approvalDal.GetBhpbioOutlierCountByAnalysisGroupForLocation(ApprovalMonth, ApprovalMonth, locationId, Nothing, Nothing, 0, True, False)

                If (outlierCountTable IsNot Nothing) Then
                    For Each row As DataRow In outlierCountTable.Rows
                        ' create a cell key for the outlier
                        Dim analysisGroup As String = row.AsString("AnalysisGroup")
                        Dim productSize As String = row.AsString("ProductSize")
                        Dim materialTypeId As String = row.AsString("MaterialTypeId")
                        Dim outlierCount = 0

                        If (Not IsDBNull(row("OutlierCount"))) Then
                            outlierCount = CType(row("OutlierCount"), Integer)
                        End If

                        If (outlierCount > 0) Then
                            Dim key As String = String.Format("{0}_{1}_{2}", analysisGroup, productSize, materialTypeId)
                            countDictionary(key) = outlierCount

                            ' if a product size or material type is specified..also update the non specific entry
                            If (Not String.IsNullOrEmpty(productSize) Or Not String.IsNullOrEmpty(materialTypeId)) Then
                                productSize = Nothing
                                materialTypeId = Nothing
                                key = String.Format("{0}_{1}_{2}", analysisGroup, productSize, materialTypeId)

                                Dim currentCount = 0
                                countDictionary.TryGetValue(key, currentCount)
                                countDictionary(key) = currentCount + outlierCount
                            End If
                        End If
                    Next
                End If
            End Using

            Return countDictionary
        End Function

        Private Function RepeatString(stringToRepeat As String, times As Integer) As String
            Dim stringToReturn As String = String.Empty
            Dim index = 0

            While index < times
                stringToReturn += stringToRepeat
                index += 1
            End While

            Return stringToReturn
        End Function
    End Module
End Namespace