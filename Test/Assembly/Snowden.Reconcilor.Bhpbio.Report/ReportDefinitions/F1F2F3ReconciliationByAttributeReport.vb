Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Linq

Namespace ReportDefinitions

    Public Class F1F2F3ReconciliationByAttributeReport
        Inherits ReportBase

        Public Overridable Function GetCustomCalculationSet(ByVal session As Types.ReportSession,
                ByVal locationId As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime,
                Optional ByVal includeChildLocations As Boolean = False) As CalculationSet

            Return Nothing
        End Function

        Public Overridable Sub AddErrorContributionToResults(ByRef table As DataTable, ByVal parentLocationId As Integer)
            ErrorContributionEngine.AddErrorContributionByLocation(table, parentLocationId)
        End Sub

        Private Shared Function GetRawCalculationSet(ByVal session As Types.ReportSession,
         ByVal locationId As Int32, ByVal startDate As DateTime,
         ByVal endDate As DateTime, ByVal isFactorVsTimeReport As Boolean, Optional ByVal includeChildLocations As Boolean = False) As CalculationSet
            Dim holdingData As New CalculationSet

            ' Always get raw data monthly
            ' even if then aggregating to a higher level
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, includeChildLocations)
            session.UseHistorical = True
            Dim f1Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate()
            Dim f15Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F15, session).Calculate()
            Dim f2Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F2, session).Calculate()

            If session.OptionalCalculationTypesToInclude.Contains(Calc.CalcType.RFGM) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.RFGM, session).Calculate())
            End If

            If session.OptionalCalculationTypesToInclude.Contains(Calc.CalcType.RFMM) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.RFMM, session).Calculate())
            End If

            If session.OptionalCalculationTypesToInclude.Contains(Calc.CalcType.RFSTM) Then
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.RFSTM, session).Calculate())
            End If

            Dim f25Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F25, session).Calculate()
            Dim f3Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F3, session).Calculate()

            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MineProductionExpitEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelCrusherEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.SitePostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.OreForRail, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelOreForRailEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.HubPostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelShippingEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortOreShipped, session).Calculate())

            ' The RecoveryFactorMoisture needs to have the As-Dropped mining model in the calc set, in order to be
            ' recalculated properly, so we add it in explicitly
            If isFactorVsTimeReport Then
                Dim F2DResult = Calc.Calculation.Create(Calc.CalcType.F2Density, session).Calculate()
                Dim RFMResult = Calc.Calculation.Create(Calc.CalcType.RecoveryFactorMoisture, session).Calculate()
                Dim RFDResult = Calc.Calculation.Create(Calc.CalcType.RecoveryFactorDensity, session).Calculate()

                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MineProductionActuals, session).Calculate())
                holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ActualMined, session).Calculate())

                holdingData.Add(F2DResult.GetFirstCalcId(Calc.ModelGradeControl.CalculationId))
                holdingData.Add(RFMResult.GetFirstCalcId(Calc.ModelMining.CalculationId))
                holdingData.Add(RFDResult.GetFirstCalcId(Calc.ModelMining.CalculationId))

                holdingData.Add(F2DResult)
                holdingData.Add(RFMResult)
                holdingData.Add(RFDResult)
            End If

            ' does the report need to show the mining model bene stuff? It can be different to the normal mining model
            If session.OptionalCalculationTypesToInclude.Contains(Calc.CalcType.ModelMiningBene) Then
                Dim miningModelBeneAdjusted = GetBeneAdjustedMiningModel(f3Calc)

                If miningModelBeneAdjusted IsNot Nothing Then
                    holdingData.Add(miningModelBeneAdjusted)
                End If
            End If

            If session.IncludeAsShippedModelsInHubSet Then
                Dim geo = Calc.ModelGeology.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim gc = Calc.ModelGradeControl.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim mm = Calc.ModelMining.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim stm = Calc.ModelShortTermGeology.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim gcstm = Calc.ModelGradeControlSTGM.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()

                holdingData.Add(geo)
                holdingData.Add(gc)
                holdingData.Add(mm)
                holdingData.Add(stm)
                holdingData.Add(gcstm)
            End If

            holdingData.Add(f1Calc)
            holdingData.Add(f15Calc)
            holdingData.Add(f2Calc)
            holdingData.Add(f25Calc)
            holdingData.Add(f3Calc)

            Return holdingData
        End Function

        ' extracts the mining model bene adjusted figures from the F3 calculation and returns them
        ' (but only if there are bene results)
        '
        ' We access this calculation as 'F3MiningModel'
        Private Shared Function GetBeneAdjustedMiningModel(f3Calc As CalculationResult) As CalculationResult
            Dim miningModelBeneAdjusted = f3Calc.GetFirstCalcId(Calc.ModelMining.CalculationId)
            miningModelBeneAdjusted.Description += " (Bene Adjusted)"
            Dim hasBene = miningModelBeneAdjusted.MaterialTypeIdCollection.Where(Function(r) r.HasValue).Count > 1

            ' ok, if we actually don't have bene material then we don't actually want to return anything
            ' this will happen for every Hub except NJV
            If hasBene Then
                Return miningModelBeneAdjusted
            Else
                Return Nothing
            End If
        End Function

        ' This is mainly used by the Factor v Time - Density Report. The All Material Types data set only goes to the
        ' F2 level - after that it generally doesn't make sense (As only HG is going to be shipped as part of F3 etc)
        Private Shared Function GetAllMaterialsRawCalculationSet(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32, ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal isFactorVsTimeReport As Boolean) As CalculationSet

            Dim holdingData As New CalculationSet
            Dim BreakdownFactorByMaterialType = True

            session.CalculationParameters(startDate, endDate, ReportBreakdown.Monthly, locationId, Nothing)
            session.UseHistorical = True

            Dim f1Calc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F1, breakdownFactorByMaterialType, session)
            Dim f15Calc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F15, breakdownFactorByMaterialType, session)
            Dim f2DensityCalc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F2Density, BreakdownFactorByMaterialType, session)
            Dim rfCalc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.RecoveryFactorDensity, breakdownFactorByMaterialType, session)

            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelGradeControl, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())
            holdingData.Add(CreateAllMaterialsCalculation(Calc.CalcType.ActualMined, BreakdownFactorByMaterialType, session).Calculate())

            holdingData.Add(f1Calc.Calculate())
            holdingData.Add(f15Calc.Calculate())
            holdingData.Add(f2DensityCalc.Calculate())
            holdingData.Add(rfCalc.Calculate())

            Return holdingData
        End Function

        Public Function GetRawDataForLocation(ByVal session As Types.ReportSession, ByVal locationId As Int32,
                                  ByVal startDate As DateTime, ByVal endDate As DateTime,
                                  ByVal dateBreakdown As Types.ReportBreakdown, Optional ByVal includeChildLocations As Boolean = False) As DataTable

            Dim calculationSet = Me.GetCustomCalculationSet(session, locationId, startDate, endDate, includeChildLocations)

            ' by default we use the custom calculation set, but if that is not available, then we fall back to the default RawCalculationSet
            If calculationSet Is Nothing Then
                calculationSet = GetRawCalculationSet(session, locationId, startDate, endDate, False, includeChildLocations)
            End If

            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Data.DateBreakdown.AddDateText(dateBreakdown, calculationSet)

            ' convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(session, New DataTableOptions With {
                                                                    .DateBreakdown = dateBreakdown,
                                                                    .PivotedResults = True,
                                                                    .IncludeSourceCalculations = False,
                                                                    .GroupByLocationId = True
                                                                })

            If includeChildLocations Then
                table.DeleteRows(table.AsEnumerable.Where(Function(r) Not r.HasValue("LocationId")))
            Else
                table.AsEnumerable.SetField("LocationId", locationId)
            End If

            ' if the table doesn't have the diff columns in it (as can happen when the date breakdown is .None)
            ' the we add and recalculate these
            If Not table.Columns.Contains("TonnesDifference") Then
                Dim attributeList = CalculationResultRecord.StandardGradeNames.ToList
                attributeList.Insert(0, "Tonnes")
                attributeList.Insert(1, "Volume")

                For Each attributeName In attributeList
                    table.Columns.Add(attributeName + "Difference")
                Next
            End If

            ' we left the table pivoted just so we could recalculate the differences. Now we unpivot it before sending it
            ' back
            F1F2F3ReportEngine.UnpivotDataTable(table)

            Return table
        End Function

        Public Function GetRawDataForChildrenAndParent(ByVal session As Types.ReportSession, ByVal locationId As Int32,
                          ByVal startDate As DateTime, ByVal endDate As DateTime,
                          ByVal dateBreakdown As Types.ReportBreakdown) As DataTable

            Dim table As DataTable = GetRawDataForLocation(session, locationId, startDate, endDate, dateBreakdown, True)
            Dim parentTable As DataTable = GetRawDataForLocation(session, locationId, startDate, endDate, dateBreakdown, False)

            ' when getting the child locations, we don't want to include any of the parent stuff, as it is not consistent. 
            ' we will get all this stuff separately
            table.DeleteRows(table.AsEnumerable.Where(Function(r) r.AsInt("LocationId") = locationId))
            table.Merge(parentTable)

            Return table
        End Function

        ' this method needs to be non-static so that it can take a custom calculation set. This is a bit non-standard compared to the 
        ' other report methods, but it was the only way I could think to used a custom calc set without having to pass it all the
        ' way down the call chain
        Public Function GetContributionData(ByVal session As Types.ReportSession, ByVal productTypeId As Int32, ByVal parentLocationId As Int32,
                                          ByVal startDate As DateTime, ByVal endDate As DateTime,
                                          ByVal dateBreakdown As Types.ReportBreakdown, Optional ByVal includeChildLocations As Boolean = True, Optional ByVal includeVolume As Boolean = False) As DataTable


            Dim table As DataTable = Nothing

            If includeChildLocations Then
                table = GetRawDataForChildrenAndParent(session, parentLocationId, startDate, endDate, dateBreakdown)
            Else
                table = GetRawDataForLocation(session, parentLocationId, startDate, endDate, dateBreakdown, False)
            End If

            Dim relevantAttributes As List(Of String) = New List(Of String)(New String() {"Tonnes", "Volume", "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O"})

            If (Not includeVolume) Then
                relevantAttributes.Remove("Volume")
            End If

            F1F2F3ReportEngine.FilterTableByAttributeList(table, relevantAttributes.ToArray())

            ' invert density for display
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)
            F1F2F3ReportEngine.RecalculateF1F2F3FactorsForUnpivotedTable(table, False)
            F1F2F3ReportEngine.AddLocationDataToTable(session, table, parentLocationId)
            Data.ReportColour.AddLocationColor(session, table)

            ' get the tonnes for each attribute for the factor rows. This data is already in the table, it is just a 
            ' matter of pivoting it properly.
            F1F2F3ReportEngine.AddAttributeIds(table)
            F1F2F3ReportEngine.FixF2Density(table)
            F1F2F3ReportEngine.AddThresholdValues(session, table, parentLocationId)
            F1F2F3ReportEngine.AddTonnesValuesToUnpivotedTable(table)


            Dim parentLocationType As String = "Unknown"
            For Each row As DataRow In table.Rows
                If row.AsBool("PresentationValid") Then
                    row("PresentationValid") = IsPresentationValid(row.AsString("ReportTagId"), row.AsString("LocationType"))
                End If

                If (parentLocationType = "Unknown" AndAlso row.AsInt("LocationId") = parentLocationId) Then
                    ' get the type of the parent location row type
                    parentLocationType = row.AsString("LocationType")
                End If
            Next

            ' clear out rows for which contribution data is not relevant (ie. clear out child rows for F3 where the location specified is a hub.. )
            If includeChildLocations Then

                Dim prefixToRemove As New List(Of String)

                If parentLocationType.ToUpper = "HUB" Or parentLocationType.ToUpper = "SITE" Then
                    prefixToRemove.Add("F25")
                    prefixToRemove.Add("F3")
                End If

                If parentLocationType.ToUpper = "SITE" Then
                    prefixToRemove.Add("F2")
                End If

                Dim rowsToRemove As New List(Of DataRow)
                For Each row As DataRow In table.Rows
                    For Each prefix As String In prefixToRemove
                        If (row.AsString("ReportTagId").StartsWith(prefix)) Then
                            If row.AsInt("LocationId") = parentLocationId Then
                                ' this is the parent row itself.. it should be the %100 contributor
                                ' leave it in this list
                            Else
                                ' if not the parent row itself, remove the row as it is not relevant
                                rowsToRemove.Add(row)
                                Exit For
                            End If
                        End If
                    Next
                Next

                ' remove the rows identified as not being required
                For Each row As DataRow In rowsToRemove
                    table.Rows.Remove(row)
                Next
            End If

            AddErrorContributionToResults(table, parentLocationId)

            ' remove volume data for lump / fines - it is never valid
            Dim volumeRows = table.AsEnumerable.Where(Function(r) r.AsString("Attribute") = "Volume")
            volumeRows.AsEnumerable.WithProductSize("LUMP").DeleteRows()
            volumeRows.AsEnumerable.WithProductSize("FINES").DeleteRows()

            ' also remove any volume data that isn't for the F1 or F1.5 - it also isn't valid
            volumeRows.Where(Function(r) r.AsString("ReportTagId") <> "F1Factor" AndAlso r.AsString("ReportTagId") <> "F15Factor").DeleteRows()

            Return table
        End Function

        Public Shared Function IsPresentationValid(row As DataRow) As Boolean
            If Not row.HasColumn("LocationType") Then
                Throw New Exception("location information require to use this method. Add with F1F2F3ReportEngine.AddLocationDataToTable")
            End If

            Return IsPresentationValid(row.AsString("ReportTagId"), row.AsString("LocationType"))
        End Function

        Public Shared Function IsPresentationValid(ByRef reportTagId As String, ByRef locationType As String) As Boolean
            If locationType Is Nothing Or reportTagId Is Nothing Then Return False

            If locationType.ToUpper = "COMPANY" Then
                Return True
            ElseIf locationType.ToUpper = "HUB" Then
                Return True
            ElseIf locationType.ToUpper = "SITE" Then
                Return Not (reportTagId.StartsWith("F3") Or reportTagId.StartsWith("F25"))
            ElseIf locationType.ToUpper = "PIT" Then
                Return Not (reportTagId.StartsWith("F3") OrElse reportTagId.StartsWith("F25") OrElse reportTagId.StartsWith("F2") OrElse reportTagId.StartsWith("RF"))
            Else
                Return False
            End If

        End Function

        Public Shared Function GetDataProductType(ByVal session As Types.ReportSession, ByVal productTypeId As Int32,
          ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal attributes As String, ByVal factors As String, ByVal dateBreakdown As Types.ReportBreakdown) As DataTable

            ' Setting the ProductTypeId or ProductTypeCode properties on the session will automatically
            ' set the product size filter or the SelectedProductType. There is no reason to do it manually
            session.ProductTypeId = productTypeId

            ' SelectedProductType will always be set - if the productTypeId wa invalid, then an exception would
            ' have been rasied
            Return GetData(session, session.SelectedProductType.LocationId, startDate, endDate, dateBreakdown, attributes, factors)
        End Function

        Private Shared Sub AddOptionalCalculations(session As ReportSession, factorList As List(Of String))
            If factorList.Contains("RFGM") Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFGM)
            End If

            If factorList.Contains("RFMM") Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFMM)
            End If

            If factorList.Contains("RFSTM") Then
                session.OptionalCalculationTypesToInclude.Add(Calc.CalcType.RFSTM)
            End If
        End Sub

        Public Shared Function GetData(ByVal session As Types.ReportSession,
         ByVal locationId As Int32, ByVal startDate As DateTime,
         ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown,
         ByVal attributes As String, ByVal factors As String,
         Optional ByVal isFactorVsTimeReport As Boolean = False, Optional ByVal includeMaterialTypes As Boolean = False,
         Optional ByVal designationMaterialTypeId As Integer = 0) As DataTable

            Dim deleteList As New ArrayList
            Dim attributeList = Data.ReportDisplayParameter.GetXmlAsList(attributes, "Attribute", "name").Cast(Of String).ToList
            Dim factorList = Data.ReportDisplayParameter.GetXmlAsList(factors, "Factor", "id").Cast(Of String).ToList

            AddOptionalCalculations(session, factorList)

            ' get the raw data (without using the requested breakdown)
            Dim calculationSet As CalculationSet = Nothing

            If includeMaterialTypes Then
                calculationSet = GetAllMaterialsRawCalculationSet(session, locationId, startDate, endDate, isFactorVsTimeReport)
            Else
                calculationSet = GetRawCalculationSet(session, locationId, startDate, endDate, isFactorVsTimeReport)
            End If

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, Nothing)
            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Data.DateBreakdown.AddDateText(dateBreakdown, calculationSet)

            ' convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(session, New DataTableOptions With {
                .PivotedResults = True,
                .GroupMeasureByMaterialType = includeMaterialTypes,
                .IncludeSourceCalculations = False,
                .GroupByLocationId = False,
                .DateBreakdown = dateBreakdown
            })

            If session.IncludeGeometData Then
                Dim geomet = New F1F2F3GeometDataHelper()
                geomet.HasSourceCalculations = False
                geomet.CalculateGeometValues(table)
                F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)
            End If

            ' to reorder the table by the Tag_Order_No before continuing
            F1F2F3ReportEngine.AddTagOrderNo(table)
            table = table.SortBy("Tag_Order_No")

            F1F2F3ReportEngine.UnpivotDataTable(table)

            ' invert density for display
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)

            ' Recalculate F1F2F3 factors post aggregation as per other reports
            ' This is neccessary because the aggregation step (built in as part of ToDateTable() above will have invalidated the factors
            F1F2F3ReportEngine.RecalculateF1F2F3FactorsForUnpivotedTable(table, False)


            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)
            Data.GradeProperties.AddGradeColourToNormalizedTable(session, table)

            Data.DateBreakdown.MergeDateText(dateBreakdown, table, "CalendarDate", "DateText")

            If session.IncludeGeometData AndAlso factorList.Contains("MiningModel") Then
                factorList.Add("F3MiningModel")
            End If

            ' get the tonnes for each attribute for the factor rows. This data is already in the table, it is just a 
            ' matter of pivoting it properly.
            '
            ' The location comparision report shouldn't use the metal units, since it can display multiple attributes
            ' per chart
            Dim useMetalUnitsForFactorTonnes = session.ReportName <> "BhpbioF1F2F3ReconciliationLocationComparisonReport"
            SetFactorTonnes(table, useMetalUnitsForFactorTonnes)

            F1F2F3ReportEngine.FixF2Density(table)
            F1F2F3ReportEngine.FilterTableByFactors(table, factorList.ToArray)
            F1F2F3ReportEngine.FilterTableByAttributeList(table, attributeList.ToArray)

            For Each row As DataRow In table.Rows
                ' now we filter out material types that are not needed (but only if we have that mode turned out), by default we just use
                ' whatever the top level aggregated material type is (usually HG, or HG+Bene)
                If includeMaterialTypes AndAlso row.AsInt("MaterialTypeId") <> designationMaterialTypeId Then
                    If Not deleteList.Contains(row) Then deleteList.Add(row)
                End If

            Next

            For Each row As DataRow In deleteList
                row.Table.Rows.Remove(row)
            Next

            Return table
        End Function

        Public Shared Sub SetFactorTonnes(ByRef table As DataTable, Optional metalUnits As Boolean = True)
            If Not table.Columns.Contains("FactorTonnes") Then
                table.Columns.Add("FactorTonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                row("FactorTonnes") = GetFactorTonnesForRow(table, row, metalUnits)
            Next
        End Sub

        ' Calculates the tonnes for a given factor row in the attribute table. Only do this if the row we are looking at is for a factor
        ' and doesn't have tonnes or grade associated with it. We could speed this up by adding some caching, but it seems to be
        ' fast enough without it at the moment.
        '
        ' The 'top' measure from the factor formula is used when getting the tonnes. Ie for F1, the Grade Control Model is used
        '
        ' If a result couldn't be found, or the passed in TagId is not for a factor, then zero is returned. It is important
        ' to return zero instead of Nothing, because otherwise SSRS has problems...
        '
        ' If metalUnits is set to true, then the metal units will be calculated for each attribute, if it is false
        ' then the raw GC tonnes will be returned regardless of the attribute
        '
        Public Shared Function GetFactorTonnesForRow(ByRef table As DataTable, ByVal row As DataRow, Optional metalUnits As Boolean = True) As Double
            Dim tonnes As Double = 0
            Dim tonnesFactorId As String = Nothing
            Dim reportTagId = row.AsString("ReportTagId")
            Dim attributeName = row.AsString("Attribute")

            ' get the tagId for the top measure in the factor formula. We will pull the tonnes + grade
            ' for this tag, and use it to calculate the tonnes for that factor attr.
            '
            ' If the passed in tagId is not a factor, or we can't find the data, then return zero for the tonnes.
            ' setting it to Nothing seems to cause problems when converting to xml
            If reportTagId.EndsWith("Factor") Then
                tonnesFactorId = "GradeControlModel"
            End If

            If tonnesFactorId IsNot Nothing Then
                Dim productSize = row.AsString("ProductSize")
                If productSize = "GEOMET" Then productSize = "TOTAL"

                ' get all the records for that measure and date (ie, all the attributes)
                Dim factorRows = table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId") = tonnesFactorId AndAlso
                                                              r.AsDate("DateFrom") = row.AsDate("DateFrom") AndAlso
                                                              r.AsString("ProductSize") = productSize).ToList()

                Dim tonnesRow = factorRows.FirstOrDefault(Function(r) r.AsString("Attribute") = "Tonnes")

                If factorRows Is Nothing OrElse tonnesRow Is Nothing Then
                    Return 0.0
                End If

                If Not tonnesRow.HasValue("AttributeValue") Then
                    Return 0.0
                End If

                tonnes = tonnesRow.AsDbl("AttributeValue")

                If metalUnits AndAlso attributeName <> "Tonnes" And Not attributeName.StartsWith("Dodgy") Then
                    Dim gradeRow = factorRows.First(Function(r) r("Attribute").ToString = row("Attribute").ToString)
                    Dim grade = gradeRow.AsDblN("AttributeValue")

                    ' if the attribute is not tonnes, then get the grade as well, and use this to calculate the tonnes
                    ' for the attribute
                    If Not grade Is Nothing Then
                        tonnes = tonnes * (grade.Value / 100.0)
                    End If
                End If
            Else
                ' if we couldn't get a value, then make sure we will return zero. Setting this to Nothing can cause
                ' problems when SSRS deserializes the xml
                tonnes = 0
            End If

            Return tonnes
        End Function

        Private Shared Function CreateAllMaterialsCalculation(ByVal calcType As Calc.CalcType, ByVal breakdownFactorByMaterialType As Boolean, ByVal session As Types.ReportSession) As Calc.Calculation
            Dim calculation As Calc.Calculation = DirectCast(Calc.Calculation.Create(calcType, session), Calc.Calculation)
            calculation.BreakdownFactorByMaterialType = breakdownFactorByMaterialType

            If TypeOf calculation Is Calc.IAllMaterialTypesCalculation Then
                DirectCast(calculation, Calc.IAllMaterialTypesCalculation).IncludeAllMaterialTypes = True
            End If

            Return calculation
        End Function

        Private Shared Function CreateAllMaterialsModelCalc(ByVal calcType As Calc.CalcType, ByVal session As Types.ReportSession) As Calc.CalculationModel

            Dim modelCalc As Calc.CalculationModel = DirectCast(Calc.Calculation.Create(calcType, session), Calc.CalculationModel)
            modelCalc.IncludeAllMaterialTypes = True
            Return modelCalc

        End Function

    End Class
End Namespace

