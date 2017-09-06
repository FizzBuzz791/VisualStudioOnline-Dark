Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI
Imports System.Drawing
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

' VS2015 says these are not needed, but I'm pretty sure they are... I think it doesn't
' know the difference between a namespace and module import
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions

Namespace Digblocks
    Public Class DigblockDetails
        Inherits Core.Website.Digblocks.DigblockDetails

        Private _hauledTonnesTerm As String = Reconcilor.Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Tonnes")
        Private _resourceClassificationTab As New WebDevelopment.Controls.TabPage("tabResourceClassification", "tpgResourceClassification", "Resource Class.")
        Private _resourceClassificationColumnIds As String() = New String() {"Measured_High", "Indicated_Medium", "Inferred_Low", "Potential_VeryLow", "Other", "Unknown"}

        Const FormatString = "#,##0.00"

        Public ReadOnly Property BhpbioDalDigblock() As Reconcilor.Bhpbio.Database.SqlDal.SqlDalDigblock
            Get
                Return DirectCast(DalDigblock, Reconcilor.Bhpbio.Database.SqlDal.SqlDalDigblock)
            End Get
        End Property
        Public Property ResourceClassificationTab() As WebDevelopment.Controls.TabPage
            Get
                Return _resourceClassificationTab
            End Get
            Set
                If (Not value Is Nothing) Then
                    _resourceClassificationTab = value
                End If
            End Set
        End Property
        Protected Overrides Sub SetupMiningTabPage()
            MyBase.SetupMiningTabPage()

            With MiningTab
                .OnClickScript &= "; clearDigblockFilterDates();"
            End With
        End Sub

        Protected Overrides Sub SetupLocationTabPage()
            MyBase.SetupLocationTabPage()

            With LocationTab
                .OnClickScript = "clearDigblockFilterDates();"
            End With
        End Sub

        Protected Overrides Sub SetupAttributesTabPage()
            MyBase.SetupAttributesTabPage()

            With AttributesTab
                .OnClickScript = "clearDigblockFilterDates();"
            End With
        End Sub
        Protected Overridable Sub SetupResourceClassificationTabPage()

            Dim dt As DataTable = BhpbioDalDigblock.GetBhpbioResourceClassificationData(MiningTabFilter.DigblockId.Value)

            Dim modelNames = dt.AsEnumerable.Select(Function(r) r.AsString("Description")).Distinct().ToList
            modelNames.Remove("Grade Control Model")

            With ResourceClassificationTab
                .OnClickScript = "clearDigblockFilterDates();"
                .Controls.Add(New Tags.HtmlBRTag())
                .Controls.Add(New Tags.HtmlBRTag())

                'Create tables based on distinct model names
                For Each modelName As String In modelNames
                    Dim layout As New Tags.HtmlTableTag

                    Dim modelTable = dt.AsEnumerable.Where(Function(r) r.AsString("Description") = modelName).ToDataTable()
                    modelTable = CalculateAddTotalRow(modelTable)

                    ' due to a change in requirements, we only want to show the totals
                    modelTable.AsEnumerable.Where(Function(r) r.AsString("MaterialTypeDescription") <> "Total").DeleteRows()

                    Dim returnTable = New ReconcilorTable(modelTable)
                    Dim columnWidth = 75

                    Dim usecolumns = _resourceClassificationColumnIds.ToList
                    usecolumns.Insert(0, "MaterialTypeDescription")

                    Dim rowIndex, cellIndex As Integer
                    With returnTable

                        .ItemDataBoundCallback = AddressOf ResourceClass_ItemDataBoundCallbackEventHandler
                        .Columns.Add("MaterialTypeDescription", New ReconcilorTableColumn(modelName))

                        If modelName.Contains("Short Term") Then 'Changes column names for STM
                            .Columns.Add("Measured_High", New ReconcilorTableColumn("% High"))
                            .Columns.Add("Indicated_Medium", New ReconcilorTableColumn("% Medium"))
                            .Columns.Add("Inferred_Low", New ReconcilorTableColumn("% Low"))
                            .Columns.Add("Potential_VeryLow", New ReconcilorTableColumn("% Very Low"))
                        Else
                            .Columns.Add("Measured_High", New ReconcilorTableColumn("% Measured"))
                            .Columns.Add("Indicated_Medium", New ReconcilorTableColumn("% Indicated"))
                            .Columns.Add("Inferred_Low", New ReconcilorTableColumn("% Inferred"))
                            .Columns.Add("Potential_VeryLow", New ReconcilorTableColumn("% Potential"))
                        End If

                        .Columns.Add("Other", New ReconcilorTableColumn("% Default/Unclass"))
                        .Columns.Add("Unknown", New ReconcilorTableColumn("% No" + vbCrLf + "Information"))

                        .Columns("MaterialTypeDescription").Width = 110

                        For Each columnName In _resourceClassificationColumnIds
                            .Columns(columnName).Width = columnWidth
                            .Columns(columnName).NumericFormat = FormatString
                        Next

                        .UseColumns = usecolumns.ToArray
                        .CanExportCsv = False
                        .Width = 650
                        .Height = 60
                        .DataBind()
                    End With

                    With layout
                        rowIndex = .Rows.Add(New TableRow)
                        With .Rows(rowIndex)
                            cellIndex = .Cells.Add(New TableCell)
                            .Cells(cellIndex).Controls.Add(returnTable)
                        End With
                    End With

                    .Controls.Add(layout)
                    .Controls.Add(New Tags.HtmlBRTag())
                Next

                If (modelNames.Count = 0) Then
                    .Controls.Add(New LiteralControl("No data available for the selected Blastblock"))
                End If

            End With
        End Sub
        Private Function ResourceClass_ItemDataBoundCallbackEventHandler(ByVal textData As String, ByVal columnName As String, ByVal row As DataRow) As String
            Dim cellContent As String = textData
            Dim isTotalRow = row("MaterialTypeDescription").ToString().Contains("Total")

            If _resourceClassificationColumnIds.Contains(columnName) Then
                If row.HasValue(columnName) Then
                    cellContent = row.AsDbl(columnName).ToString(FormatString)
                Else
                    Dim zero = 0.0
                    cellContent = zero.ToString(FormatString)
                End If

            End If

            If columnName.ToUpper = "UNKNOWN" Then
                Dim total As Double? = _resourceClassificationColumnIds.Select(Function(c) row.AsDblN(c)).Sum()
                If Not total.HasValue Then total = 0
                cellContent = (100 - (total.Value)).ToString(FormatString)
            End If

            If isTotalRow Then
                cellContent = "<b>" + cellContent + "</b>"
            End If

            Return cellContent
        End Function
        Private Function CalculateAddTotalRow(ByVal dt As DataTable) As DataTable
            Dim totalTonnes = dt.AsEnumerable.Select(Function(r) r.AsDblN("Tonnes")).Sum()
            Dim totalRow As DataRow = dt.NewRow()

            totalRow("MaterialTypeDescription") = "Total"
            totalRow("Tonnes") = totalTonnes

            For Each column In _resourceClassificationColumnIds
                Dim total = dt.AsEnumerable.Select(Function(r) r.AsDblN(column) * r.AsDblN("Tonnes")).Sum()
                Dim weightedTotal = total / totalTonnes
                totalRow(column) = weightedTotal
            Next

            dt.Rows.Add(totalRow)
            Return dt
        End Function

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            SetupResourceClassificationTabPage()
            TasksSidebar.TryRemoveItem("Digblock_Edit")
            TasksSidebar.TryRemoveItem("Digblock_Delete")
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With DigblockTabPane
                .TabPages.Add(ResourceClassificationTab)
            End With

            ReconcilorContent.SideNavigation.TryRemoveItem("DIGBLOCK_ADD")

            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioAnalysis.js"))
            End With
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalDigblock Is Nothing) Then
                DalDigblock = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalDigblock(Resources.Connection)
            End If

            MyBase.SetupDalObjects()

            If (DalDepletion Is Nothing) Then
                DalDepletion = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalDepletion(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub CreateListTable()
            Dim DigblockDetailsHiddenGrades = New String() {"Density", "Ultrafines"}

            ' Get the data. We will get all grades (even hidden ones) and break down by Lump/Fines
            ' The list of grades to breakdown by LF is in the stored proc itself
            AttributeTable = BhpbioDalDigblock.GetBhpbioDigblockDetailList(DigblockId, 1, 1, NullValues.Int16, 1)

            ' Remove the list of grades that are not valid for display on the Digblock details page. This is different
            ' to the list of hidden grades in the Grades table. But we can't change the visibility in this table, because
            ' it has side-effects elsewhere in the system
            Dim hiddenRows = AttributeTable.AsEnumerable.Where(Function(r) DigblockDetailsHiddenGrades.Contains(r("Attribute").ToString)).ToList()
            For Each row In hiddenRows
                row.Delete()
            Next
            AttributeTable.AcceptChanges()

            ' do some normalization on the moisture rows
            Dim moistureRows As DataRow() = AttributeTable.Select("Attribute like 'H2O-As-Dropped%' Or Attribute like 'H2O-As-Shipped%'")
            For Each row In moistureRows
                ' These might be set to zero when they come back from the proc
                ' set them to null so that a '-' will be shown in the UI as per the design
                row("Hauled") = DBNull.Value
                row("Reconciled") = DBNull.Value
            Next

            'rename the 'Best Haulaged Tonnes'
            Dim attributeRows As DataRow()
            attributeRows = AttributeTable.Select("Attribute = 'Best Hauled Tonnes'")
            If attributeRows.Length <> 1 Then
                Throw New InvalidOperationException("The 'Best Haulaged Tonnes' row in the 'Attribute' column cannot be found.")
            Else
                attributeRows(0)("Attribute") = "Tonnes"
            End If
        End Sub

        Protected Overrides Sub CreateDigblockTable()
            'specify the columns to exclude
            AttributeExcludeColumn.Add("Blast Block")
            AttributeExcludeColumn.Add("OrderNo")

            'build the reconcilor table
            With AttributeDisplayTable
                .DataSource = AttributeTable
                .ExcludeColumns = AttributeExcludeColumn.ToArray()
                .UseColumns = New String() {"Attribute", "Geology", "Mining", "Short Term Geology", "Grade Control", "Hauled", "Reconciled"}
                .ContainerPadding = .ContainerPadding + 250
                .ItemDataBoundCallback = AddressOf AttributeDisplayTable_ItemDataboundCallback
                .Height = 260

                .DataBind()

                For Each col As String In .Columns.Keys
                    If col <> "Attribute" Then
                        .Columns(col).Width = 75
                        .Columns(col).TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Right
                    End If

                    If col = "Hauled" Then
                        .Columns(col).HeaderText = "Best Tonnes /<br>Mine Estimate Grades"
                        .Columns(col).Width = 125
                    ElseIf col = "Geology" Then
                        .Columns(col).HeaderText = "Geology<br>Model"
                    ElseIf col = "Mining" Then
                        .Columns(col).HeaderText = "Mining<br>Model"
                    ElseIf col = "Grade Control" Then
                        .Columns(col).HeaderText = "Grade<br>Control"
                    ElseIf col = "Short Term Geology" Then
                        .Columns(col).HeaderText = "Short Term Model"
                    End If
                Next
            End With
        End Sub

        Protected Overrides Function AttributeDisplayTable_ItemDataboundCallback(ByVal textData As String, ByVal columnName As String, ByVal row As DataRow) As String
            Dim ReturnValue As String = textData.Trim
            Dim Attribute As String = row("Attribute").ToString
            Dim MoistureGrades = New String() {"H2O-As-Dropped", "H2O-As-Shipped"}

            If Grades.ContainsKey(Attribute) Then
                If columnName = "Attribute" Then
                    If Grades(Attribute).Units <> "" Then
                        ReturnValue = Attribute & " (" & Grades(Attribute).Units & ")"
                    End If
                Else
                    If (Not row(columnName) Is DBNull.Value) Then
                        ReturnValue = Grades(Attribute).ToString(Convert.ToSingle(row(columnName)), False)
                    Else
                        ReturnValue = "-"
                    End If
                End If
            ElseIf columnName = "Attribute" Then
                If MoistureGrades.Contains(Attribute) Then
                    ReturnValue = ReturnValue + " (%)"
                End If

                ' Indent the L/F grades, so it is clearer which parent grade they apply to
                If Attribute.ToLower.Contains("(lump)") Or Attribute.ToLower.Contains("(fines)") Then
                    ReturnValue = "&nbsp;&nbsp;" + ReturnValue
                End If

            ElseIf columnName <> "Attribute" And Attribute = "Tonnes" Then
                If textData.Trim = "" Then textData = "0"
                ReturnValue = Convert.ToDouble(textData).ToString(Application("NumericFormat").ToString)
            ElseIf columnName <> "Attribute" And Attribute = "Best Hauled Tonnes" Then
                If textData.Trim = "" Then textData = "0"
                ReturnValue = Convert.ToDouble(textData).ToString("###,###,###,###")
            ElseIf columnName <> "Attribute" And Attribute = "% of Grade Control" Then
                If (Not row(columnName) Is DBNull.Value) Then
                    ReturnValue = Convert.ToDouble(row(columnName)).ToString(Application("NumericFormat").ToString & ".00")
                Else
                    ReturnValue = "-"
                End If
            ElseIf columnName <> "Attribute" Then
                If (Not row(columnName) Is DBNull.Value) Then
                    ReturnValue = Convert.ToDouble(row(columnName)).ToString(Application("NumericFormat").ToString & ".00")
                Else
                    ReturnValue = "-"
                End If
            End If

            Return ReturnValue
        End Function

        Protected Overrides Sub CreateDigblockChart()
            Dim DepletionChart As New ChartFX.WebForms.Chart
            Dim digblockTable As DataTable = DalDigblock.GetDigblock(DigblockId)
            Dim legendAttribute As New ChartFX.WebForms.LegendItemAttributes
            Dim customItem As ChartFX.WebForms.CustomLegendItem

            If (digblockTable.Rows(0)("Approved_Removed_Percentage") Is DBNull.Value) Then
                ChartReconciled = 0
            Else
                ChartReconciled = Convert.ToDouble(digblockTable.Rows(0)("Approved_Removed_Percentage"))
            End If

            If (digblockTable.Rows(0)("Unapproved_Removed_Percentage") Is DBNull.Value) Then
                ChartUnreconciled = 0
            Else
                ChartUnreconciled = Convert.ToDouble(digblockTable.Rows(0)("Unapproved_Removed_Percentage"))
            End If

            ChartRemaining = 100.0 - ChartReconciled - ChartUnreconciled
            Depleted = ChartUnreconciled + ChartReconciled

            ChartReconciled /= 100
            ChartUnreconciled /= 100
            ChartRemaining /= 100
            Depleted /= 100

            'If we have overdepleted then rescale back down to 1
            If Depleted > 1 Then
                ChartRemaining = 0
            End If

            With DepletionChart
                Dim format As String = "(%p%%)"
                .ToolTipFormat = format

                .Gallery = ChartFX.WebForms.Gallery.Pie
                .View3D.Enabled = True
                .Background = New ChartFX.WebForms.Adornments.SolidBackground(Drawing.Color.White)

                .ImageSettings.Width = 200
                .ImageSettings.Height = AttributeDisplayTable.Height + 32
                .ImageSettings.Interactive = False
                .RenderFormat = "PNG"

                .ToolBar.Visible = False
                .MenuBar.Visible = False
                .ContextMenus = False

                .Data.Series = 1
                .Data.Points = 3

                .Points(0, 0).Color = ChartReconciledColour
                .Points(0, 1).Color = ChartUnreconciledColour
                .Points(0, 2).Color = ChartRemainingColour

                .Data.Y(0, 0) = ChartReconciled
                .Data.Y(0, 1) = ChartUnreconciled
                .Data.Y(0, 2) = ChartRemaining

                .LegendBox.Visible = True
                .LegendBox.ContentLayout = ChartFX.WebForms.ContentLayout.Near
                .LegendBox.Dock = ChartFX.WebForms.DockArea.Bottom
                .LegendBox.AutoSize = True
                .LegendBox.Font = New Font("Arial", 6)

                legendAttribute.Visible = False
                .LegendBox.ItemAttributes(.AxisX) = legendAttribute
                .LegendBox.CustomItems.Clear()

                customItem = New ChartFX.WebForms.CustomLegendItem
                customItem.Text = "Approved Depletion"
                customItem.Color = ChartReconciledColour
                customItem.MarkerShape = ChartFX.WebForms.MarkerShape.Rect
                .LegendBox.CustomItems.Add(customItem)

                customItem = New ChartFX.WebForms.CustomLegendItem
                customItem.Text = "Unapproved Depletion"
                customItem.Color = ChartUnreconciledColour
                customItem.MarkerShape = ChartFX.WebForms.MarkerShape.Rect
                .LegendBox.CustomItems.Add(customItem)

                customItem = New ChartFX.WebForms.CustomLegendItem
                customItem.Text = "Remaining"
                customItem.Color = ChartRemainingColour
                customItem.MarkerShape = ChartFX.WebForms.MarkerShape.Rect
                .LegendBox.CustomItems.Add(customItem)
            End With

            DigblockChartContainer.Style.Add("text-align", "center")
            DigblockChartContainer.Controls.Add(DepletionChart)
            DigblockChartContainer.Controls.Add(New LiteralControl("<br/>" & Depleted.ToString("0%") & " Depleted"))
        End Sub
    End Class
End Namespace
