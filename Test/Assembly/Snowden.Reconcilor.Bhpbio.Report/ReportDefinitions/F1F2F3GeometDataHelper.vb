Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace ReportDefinitions
    
    Public Class F1F2F3GeometDataHelper
        ' this is the ProductSize used for the geomet data
        Private Const _geomet_size As String = "GEOMET"
        Private _session As ReportSession = Nothing
        Private _adAdjustment As Double = 0.86

        ' these calculations are not shown for the geomet product size because it doesn't make sense to
        ' calculate a split for them. Mainly this is the stockpile Delta
        Private _hiddenCalculations As String() = {"SitePostCrusherStockpileDelta", "HubPostCrusherStockpileDelta",
                                                   "PostCrusherStockpileDelta", "ActualMined", "PortStockpileDelta",
                                                   "PortBlendedAdjustment"}

        Public ReadOnly Property AsDroppedAdjustment As Double
            Get
                Return _adAdjustment
            End Get
        End Property

        Public Sub New(Optional ByRef session As ReportSession = Nothing)
            _session = session

            If _session IsNot Nothing AndAlso _session.DalUtility IsNot Nothing Then
                Dim setting = session.DalUtility.GetSystemSetting("GEOMET_AS_DROPPED_ADJUSTMENT")

                If setting IsNot Nothing Then
                    _adAdjustment = Convert.ToDouble(setting)
                End If
            End If
        End Sub

        Public Property HasSourceCalculations() As Boolean = False

        ' Geomet probably should never have Reclass data, so the default here is true. Put in as an options though
        ' in case it changes in the future
        Public Property RemoveResourceClassificationData As Boolean = True

        '
        ' the table that is passed in here should contain the full set of data that the HUB report uses, with all values etc calculated
        ' correctly. We then use this data to calculate a new GEOMET section. Instead of containing tonnes and grades this section
        ' will just contain percentages. These percentatge represent the % LUMP for each attribute 
        '
        ' We then use these numbers the calculate a new set of factors that can be used to see how accurate the L/F split
        ' was
        '
        ' See WREC-1171 in JIRA for more details on how this is calculated
        '
        Public Function AddGeometData(ByRef table As DataTable) As DataTable
            ' check the type of table, and throw an exception if its the wrong one. It would be nice for it
            ' to work on both, but this would require too many changes. The easier solution for adding geomet
            ' to pivoted DataTables is to get the CalculationSet to provide an 
            If table.Columns.Contains("Attribute") AndAlso table.Columns.Contains("AttributeValue") Then
                Throw New Exception("The Geomet Split data can only be added to a Pivoted Factor DataTable")
            End If

            ' is the dataset 'flat' or does it contain nested calculations? We will try to work this out automatically
            ' by looking for reportTagIds that are not present in the flat data set (such as used for the line chart
            ' reports)
            Me.HasSourceCalculations = (table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F1MiningModel").Count() > 0)

            ' since the tonnes splits we have in reconcilor are As-Shipped, there needs to be an adjustment back to AD
            ' in order to properly calculate geomet factors. To do this we copy the existing Grade Control model data
            ' and apply an adjustment to it

            'AddAdjustedGradeControl(table)
            'AddAdjustedMMSE(table)

            ' copy a single product size section, give it a new name, and null out the values. This gives us a blank
            ' slate to work with that we can fill in with the appropriate values, without having to worry about creating
            ' all the secondary information (TagIds, Presentation Flags etc) manually
            AddNewProductSize(table, _geomet_size)

            ' we now have a whole new product size section with completely blank values. Fill these values in using the method
            ' described above. Note that the factors are not calculated here, that is done afterwards
            CalculateGeometValues(table)

            ' Add the other adjusted models - because these are just for display, not being used int he F2 like the GC model
            ' we add them later, and just for the GC model

            ' AddAdjustedModels(table)

            ' this is minor item to make sure that the adjusted F2-GC has the same visibility as the usual F2
            SetPresentationFlag(table)

            If RemoveResourceClassificationData Then
                ' delete all the non-total RC rows
                table.AsEnumerable.WithProductSize(_geomet_size).
                    Where(Function(r) r.HasValue("ResourceClassification") AndAlso r.AsString("ResourceClassification") <> "ResourceClassificationTotal").
                    DeleteRows()
            End If

            ' the geomet factors haven't been calculated yet, we just ignored them before. This is the standard method
            ' for recalculating the factors. This will redo the entire table, not just GEOMET, but no big deal.
            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)

            Return table
        End Function

        ' some of the geomet report should have the moisture data hidden. This is not run by default
        ' but it can be used by the reporting layer as required
        Public Shared Sub RemoveMoistureData(ByRef table As DataTable)
            For Each row As DataRow In table.AsEnumerable.WithProductSize(_geomet_size)
                row.SetNull("H2O")
                row.SetNull("H2O-As-Dropped")
                row.SetNull("H2O-As-Shipped")
            Next
        End Sub

        Public Sub SetPresentationFlag(ByRef table As DataTable)
            ' is it valid to be showing the F2 for this report? If it is we want to show the GEOMET F2GradeControl
            Dim isF2Valid = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F2Factor").First.AsBool("PresentationValid")
            Dim isF3Valid = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F3Factor").First.AsBool("PresentationValid")

            ' before when we added the new adjusted grade control we set the PresentationValid to false, so that
            ' they will not show up in the other tables on the reports, we need to reverse this for the GEOMET
            ' ones, we want them to be seen in that section
            table.AsEnumerable.WithProductSize(_geomet_size).
                Where(Function(r) r.AsString("ReportTagId") = "F2GradeControlModel").
                SetField("PresentationValid", isF2Valid)

            table.AsEnumerable.WithProductSize(_geomet_size).
                Where(Function(r) r.AsString("CalcId") = "MiningModelShippingEquivalent").
                SetField("PresentationValid", isF3Valid)

            ' set the delta calculations etc to be hidden on the GEOMET - it doesn't make sense to calculate a split for them
            table.AsEnumerable.WithProductSize(_geomet_size).
                Where(Function(r) _hiddenCalculations.Contains(r.AsString("CalcId"))).
                SetField("PresentationValid", False)

            ' if the F1MiningModel is valid, then make the F3MiningModel valid
            table.AsEnumerable.WithProductSize(_geomet_size).
                Where(Function(r) r.AsString("ReportTagId").StartsWith("F3") And r.AsString("CalcId") = "MiningModel").
                SetField("PresentationValid", isF2Valid)


        End Sub

        ' copies the TOTAL product size, nulls the values, and adds a duplicate set of rows with the given product size
        Public Function AddNewProductSize(ByRef table As DataTable, ByVal productSize As String) As List(Of DataRow)
            Dim sourceProductSize = "FINES"
            Dim rows = table.AsEnumerable.WithProductSize("FINES").CloneFactorRows()
            rows.AsEnumerable.SetField("ProductSize", productSize)
            rows.AsEnumerable.Where(Function(r) r.AsString("TagId").EndsWith(sourceProductSize)).SetField("TagId", Function(r) r.AsString("TagId").Replace(sourceProductSize, ""))

            Return rows
        End Function

        Public Sub AddAdjustedMMSE(ByRef table As DataTable)
            Dim reportTagId = "F3MiningModelShippingEquivalent"

            If Not HasSourceCalculations Then
                reportTagId = "MiningModelShippingEquivalent"
            End If

            ' copy the mmse into a new set of adjusted rows. set them to hidden as usual
            Dim mmse = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = reportTagId).ToList
            Dim mmse_ad = Me.CopyRowsForAsDropped(mmse)

            ' make sure that the rows are hidden, we don't want them to show unless we set it specifically
            mmse_ad.AsEnumerable.SetField("PresentationValid", False)

            ' this is like the adjusted F2-GC, but a bit more complicated because we
            ' need to get the MM adjustment difference then apply it to the MMSE (
            ' and the MMCE as well I guess)
            '
            ' We will try to get the F3 Mining Model, which will contain the Bene adjustment, but if
            ' it doesn't exist in the data table, then just fall back to the F1 mining model instead
            Dim lumpRows = table.AsEnumerable.WithProductSize("LUMP")
            Dim rows = lumpRows.Where(Function(r) r.AsString("ReportTagId") = "F3MiningModel")

            If rows.Count = 0 Then
                rows = lumpRows.Where(Function(r) r.AsString("ReportTagId") = "F1MiningModel")
            End If

            If rows.Count = 0 Then
                rows = lumpRows.Where(Function(r) r.AsString("ReportTagId") = "MiningModel")
            End If

            For Each miningModelRow In rows
                Dim adjustedTonnes = miningModelRow.AsDblN("Tonnes") / Me.AsDroppedAdjustment
                Dim tonnesDelta = adjustedTonnes - miningModelRow.AsDblN("Tonnes")

                ' don't always have tonnes - this could be a null row. Just skip to the next one, and apply no adjustment
                If tonnesDelta Is Nothing Then Continue For

                ' get the matching MMSE for the mining model row - if the location is below the hub, then these
                ' might be null. No problem, we just do nothing in that case
                Dim mmseLump = table.AsEnumerable.GetCorrespondingRowWithReportTagId(reportTagId + "ADForTonnes", miningModelRow)
                If (mmseLump IsNot Nothing) Then
                    Dim mmseFines = table.AsEnumerable.GetCorrespondingRowWithProductSize("FINES", mmseLump)

                    ' move the tonnes from the fines record to the lump. The total is unchanged. Later the 
                    ' geomet values will be calculated
                    If (mmseFines IsNot Nothing) Then
                        mmseFines("Tonnes") = mmseFines.AsDblN("Tonnes") - tonnesDelta
                    End If

                    mmseLump("Tonnes") = mmseLump.AsDblN("Tonnes") + tonnesDelta
                End If
            Next

        End Sub

        Public Sub AddAdjustedGradeControl(ByRef table As DataTable)
            ' if the table doesn't have a sort field already add one, otherwise there is no way to get the 
            ' row into the correct position (the actual sorting can be done by ssrs)
            '
            ' Actually don't have to do anything after this to make the F2-GC appear in the right place, 
            ' because it will have the same order_no as the other GC data
            If Not table.Columns.Contains("Order_No") Then
                table.Columns.Add("Order_No", GetType(Integer))

                Dim orderNo = 0
                For Each row As DataRow In table.Rows
                    row("Order_No") = orderNo
                    orderNo += 10
                Next

                ' set the default view sort to be on the order column
                table.DefaultView.Sort = "Order_No"
            End If

            ' insert the new set of GC rows into the table as part of the F2 calculation. Its a shame this isn't done
            ' by default in the Calculation classes, but it isn't
            Dim rows = CopyGradeControlToF2(table)
            Me.ApplyADAdjustment(rows)

        End Sub

        ' this will adjust the models given by the calculationId in place in the table, instead of copying 
        ' new ones with the adjusted values
        Public Function AdjustCalculationInPlace(ByRef table As DataTable, calculationId As String) As List(Of DataRow)
            Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("CalcId") = calculationId).ToList

            For Each row In rows
                Dim description = row.AsString("Description")
                If Not description.ToLower.Contains("bene adjusted") Then
                    row("Description") = description + " (AD)"
                Else
                    description = description.Replace("(Bene Adjusted)", "").Trim
                    row("Description") = description + " (Bene + AD)"
                End If

            Next

            Return Me.ApplyADAdjustment(rows)
        End Function



        Public Sub AdjustAllModelsInPlace(ByRef table As DataTable)
            '' if we have the F3MiningModel (ie the Bene Adjusted mining model), replace the existing mining
            '' model with it
            'If table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F3MiningModel").Count() > 0 Then
            '    ' if we have the F3 Mining Model in the dataset, then we want to use them, so delete the old mining model
            '    ' and rename it
            '    '
            '    ' Actually I don't think this works?
            '    Dim isValid = True
            '    table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F1MiningModel" Or r.AsString("ReportTagId") = "MiningModel").DeleteRows()

            '    Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F3MiningModel").ToList
            '    rows.AsEnumerable.SetField("ReportTagId", "MiningModel")
            '    rows.AsEnumerable.SetField("PresentationValid", isValid)
            'End If

            Me.AdjustCalculationInPlace(table, "MiningModel")
            Me.AdjustCalculationInPlace(table, "GeologyModel")
            Me.AdjustCalculationInPlace(table, "GradeControlModel")
            Me.AdjustCalculationInPlace(table, "GradeControlSTGM")
            Me.AdjustCalculationInPlace(table, "ShortTermGeologyModel")
        End Sub

        ' sometimes we want to replace the MMSE with the Ad Adjusted version, not have the two versions in the
        ' table side by side. This method will delete the normal MMSE and rename the MMSE_AD to take its place
        '
        ' Probably the order will be wrog after this, and you will have to add Tag_Order_No to resort the table
        Public Sub ReplaceMMSEWithAdjusted(ByRef table As DataTable)
            Dim mmseId = Calc.MiningModelShippingEquivalent.CalculationId
            Dim mmseADId = mmseId + "ADForTonnes"

            ' delete all rows for the existing MMSE
            table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = mmseId).DeleteRows()

            ' get all rows for the Ad Adjusted MMSE. Will are going to do some renaming on these
            ' so they will appears as the regular MMSE
            Dim mmseRows = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = mmseADId).ToList

            For Each row In mmseRows
                row("TagId") = row.AsString("TagId").Replace(mmseADId, mmseId)
                row("ReportTagId") = row.AsString("ReportTagId").Replace(mmseADId, mmseId)
                row("CalcId") = row.AsString("CalcId").Replace(mmseADId, mmseId)
                row("Description") = Calc.MiningModelShippingEquivalent.CalculationDescription + " (AD)"
            Next
        End Sub

        Public Sub AddAdjustedModels(ByRef table As DataTable)


            ' copy the other models for display. These are easier to handle than the GC model, because they don't have to be used in
            ' a calculation
            Dim hasF3MiningModel = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = "F3MiningModel").Count > 0
            Dim miningModelTagId = If(hasF3MiningModel, "F3MiningModel", "F1MiningModel")

            Me.CopyCalculationForAsDropped(table, miningModelTagId)
            Me.CopyCalculationForAsDropped(table, "GeologyModel")
            Me.CopyCalculationForAsDropped(table, "F15ShortTermGeologyModel")

            ' now we want to move all the adjusted models after the standard ones, and have them all grouped together
            ' first get a set of all the adjusted rows that have to be 'moved'
            Dim adjustedModels = table.AsEnumerable.
                WithProductSize("GEOMET").
                Where(Function(r) r.AsString("Description").Contains("(AD Adjusted)") AndAlso Not r.AsString("ReportTagId").Contains("ShippingEquivalent")).
            OrderBy(Function(r) r.AsInt("Order_No"))

            ' next we need the position of the last unadjusted model row - we will use this as a reference and
            ' put all the adjusted rows after this. There were some problems getting this number, so just assume
            ' that the last F1.5 / STGM model row, is going to be the last one
            Dim f15Rows = table.AsEnumerable.
                WithProductSize("GEOMET").
                Where(Function(r) r.AsString("ReportTagId").StartsWith("F15") AndAlso Not r.IsFactorRow)

            If f15Rows.Count > 0 Then
                Dim lastModelPosition = f15Rows.Max(Function(r) r.AsInt("Order_No"))

                ' now actually update the order numbers
                Dim i As Integer = 0
                For Each row In adjustedModels
                    row("Order_No") = lastModelPosition + i
                    i += 1
                Next
            End If
        End Sub

        '
        ' Given a set of rows for a calculation, including all product sizes, apply the AD adjustment to the
        ' LUMP
        '
        Public Function ApplyADAdjustment(ByRef rows As List(Of DataRow)) As List(Of DataRow)
            Dim lumpCount = rows.AsEnumerable.WithProductSize("LUMP").Count()

            If lumpCount > 0 Then
                ' adjust the LUMP tonnes to increase the amount, also set all the fines values to
                ' null, they are no longer valid. We *could* recalculate them, but since they aren't used in the
                ' geomet calcs we can just ignore them
                rows.AsEnumerable.WithProductSize("LUMP").AdjustTonnes(1 / Me.AsDroppedAdjustment)
                rows.AsEnumerable.WithProductSize("FINES").ClearValues()
            Else
                ' sometimes we will just apply the adjustment directly to the GEOMET Tonnes LUMP % number - this is mathematically
                ' equivilent to adjusting the LUMP tonnes in the base data. Do this if we detect that there are no lump
                ' rows in the data that gets passed in
                rows.AsEnumerable.WithProductSize("GEOMET").AdjustTonnes(1 / Me.AsDroppedAdjustment)
            End If

            Return rows
        End Function

        Public Function CopyCalculationForAsDropped(ByRef table As DataTable, ByVal reportTagId As String) As List(Of DataRow)

            Dim rows = table.AsEnumerable.
                WithProductSize(_geomet_size).
                Where(Function(r) r.AsString("ReportTagId") = reportTagId).
                ToList

            Dim newRows = Me.CopyRowsForAsDropped(rows)

            ' since this is specifically about copying the values for AD, lets just apply the adjustment now
            Me.ApplyADAdjustment(newRows)

            Return newRows
        End Function

        Public Function CopyRowsForAsDropped(ByRef rows As List(Of DataRow)) As List(Of DataRow)
            Dim tagSuffix As String = "ADForTonnes"

            Dim newRows = rows.AsEnumerable.CloneFactorRows(withValues:=True)

            For Each row In newRows
                row("ReportTagId") = row.AsString("ReportTagId") + tagSuffix
                row("TagId") = row.GenerateTagId

                Dim description = row.AsString("Description")
                Dim descriptionStart = description.Split("("c).First.Trim()

                Dim suffix = "(AD Adjusted)"
                If description.ToLower.Contains("bene adjusted") Then suffix = "(AD + Bene Adjusted)"

                row("Description") = String.Format("{0} {1}", descriptionStart, suffix)
            Next

            Return newRows
        End Function

        ' We can't use the standard CopyCalculationForAsDropped for the F2-GC, because later we need to recalculate
        ' the factor based off it, so this has to be done as a special case
        Public Function CopyGradeControlToF2(ByRef table As DataTable) As List(Of DataRow)
            Dim fromRoot = "F1"
            Dim toRoot = "F2"
            Dim calcId = "GradeControlModel"
            Dim reportTagId = fromRoot + calcId

            Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = reportTagId).CloneFactorRows(withValues:=True)

            For Each row In rows
                row("TagId") = row.AsString("TagId").Replace(fromRoot, toRoot)
                row("ReportTagId") = row.AsString("ReportTagId").Replace(fromRoot, toRoot)
                row("RootCalcId") = row.AsString("RootCalcId").Replace(fromRoot, toRoot)
                row("Description") = row.AsString("Description") + " (AD Adjusted)"
                row("PresentationValid") = False
            Next

            Return rows
        End Function

        '
        ' The table needs to have the geomet product size in order for this method to work properly
        '
        Public Sub CalculateGeometValues(ByRef table As DataTable, Optional ByVal geometProductSize As String = _geomet_size)
            If table.AsEnumerable.WithProductSize(geometProductSize).Count() = 0 Then
                Me.AddNewProductSize(table, geometProductSize)
            End If

            For Each geometRow In table.AsEnumerable.WithProductSize(geometProductSize)
                ' we want the geomet rows to always sort to the bottom, so reset the order_no (if
                ' we have one)
                If table.Columns.Contains("Order_No") Then
                    geometRow("Order_No") = geometRow.AsInt("Order_No") * 5000
                End If

                ' factor values get calculated later, just skip them for now
                If geometRow.IsFactorRow Then Continue For

                ' get the matching rows for this tag for the lump and total sizes
                Dim lumpRow As DataRow = table.AsEnumerable.GetCorrespondingRowWithProductSize("LUMP", geometRow)
                Dim totalRow As DataRow = table.AsEnumerable.GetCorrespondingRowWithProductSize("TOTAL", geometRow)
                Dim finesRow As DataRow = table.AsEnumerable.GetCorrespondingRowWithProductSize("FINES", geometRow)

                ' set the geomet values for that single row
                CalculateGeometValues(geometRow, lumpRow, totalRow, finesRow)
            Next
        End Sub

        ' all the values in the geomet row are calculated as lump / total
        '
        ' this always has to be calulated using tonnes or metal units, so for the grades this means multiplying by the tonnes (Update: this
        ' may not actually be true - see JIRA for the most up to date information)
        Public Function CalculateGeometValues(ByRef geometRow As DataRow, ByRef lumpRow As DataRow, ByRef totalRow As DataRow, ByRef finesRow As DataRow) As DataRow
            If geometRow Is Nothing Then
                Throw New ArgumentNullException("geometRow")
            End If

            If lumpRow Is Nothing Or totalRow Is Nothing Then
                Return geometRow
            End If

            Dim tonnesAttributes = New String() {"Tonnes", "Volume"}
            Dim gradeAttributes = CalculationResultRecord.GradeNames.ToList

            ' the geomet description needs to come from the fines or lump row, so it has the proper
            ' geomet type description in it (as these are not present in the TOTAL)
            geometRow("Description") = finesRow.AsString("Description")

            ' for tonnes and volume it is just a simple ratio. This number is bascially the Lump %
            '
            ' we mulitply by 100 as this is how the grade percents are already done (as numbers between 0 - 100, 
            ' instead of 0 - 1 as would be more correct)
            For Each attr In tonnesAttributes
                Dim v = lumpRow.AsDblN(attr) / totalRow.AsDblN(attr) * 100
                If v.HasValue Then geometRow(attr) = v.Value
            Next

            ' for grades we need to convert the values into metal units before doing the divide
            For Each attr In gradeAttributes
                If attr = "Density" Then Continue For ' dont do density

                ' this is the code that is required to calculate the number for metal units, it seems to be that this is not actually
                ' used, when we compare it to the examples. Will leave this here commented out for now, in case it is needed later
                'Dim v = (lumpRow.AsDblN(attr) * lumpRow.AsDblN("Tonnes")) / (totalRow.AsDblN(attr) * totalRow.AsDblN("Tonnes")) * 100

                ' the grades values are displayed as a 'factor' style value around 1.00, so we don't mult this by 100
                Dim v As Double?
                If attr = "Ultrafines" Then
                    If (finesRow IsNot Nothing) Then
                        v = finesRow.AsDblN(attr)
                    End If
                Else
                    v = lumpRow.AsDblN(attr) / totalRow.AsDblN(attr)
                End If
                If v.HasValue Then geometRow(attr) = v.Value
            Next

            Return geometRow
        End Function

    End Class


End Namespace

