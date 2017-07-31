
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Linq

Namespace ReportDefinitions

    Public Class ValidationApprovalData
        Inherits ReportBase

        ''' <summary>
        ''' A sort expression used to order product sizes in desired display order
        ''' </summary>
        Private Const ProductSizeColumnSortExpression As String = "IIF([ProductSize]='LUMP',1,IIF([ProductSize]='FINES',2,0))"

        Public Shared Function GetValidationData(ByVal session As Types.ReportSession, ByVal startDate As DateTime,
         ByVal endDate As DateTime, ByVal locationId As Int32?, ByVal childLocations As Boolean,
         ByVal calcId As String, Optional ByVal includeDensityCalculations As Boolean = False, Optional ByVal includeMoistureCalculations As Boolean = False) As DataTable
            Dim calcSet As New Types.CalculationSet
            Dim f25 As CalculationResult
            Dim f3 As CalculationResult
            Dim geology As CalculationResult
            Dim table As DataTable
            Dim row As DataRow
            Dim locationLevel As String = Report.Data.FactorLocation.GetLocationTypeName(session.DalUtility, locationId)

            session.CalculationParameters(startDate, endDate, Types.ReportBreakdown.None, locationId, childLocations)

            ' Force the data we are going to need into the cache in an efficient manner
            F1F2F3ReportEngine.PrepareF1F2F3Cache(session)

            If calcId Is Nothing OrElse calcId = Calc.ModelGeology.CalculationId Then
                geology = Calc.Calculation.Create(Calc.CalcType.ModelGeology, session).Calculate()
                geology.PrefixTagId("F1")
                calcSet.Add(geology)
            End If

            If calcId Is Nothing Then
                calcSet.Add(New Types.CalculationResult(CalculationResultType.Hidden))
            End If

            If calcId Is Nothing OrElse calcId = Calc.F1.CalculationId Then
                calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate())
                If childLocations Then
                    calcSet.ReplaceDescription("F1Factor", "F1")
                End If
            End If

            If calcId Is Nothing OrElse calcId = Calc.F15.CalculationId Then
                calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F15, session).Calculate())
                If childLocations Then
                    calcSet.ReplaceDescription("F15Factor", "F1.5")
                End If
            End If

            If includeDensityCalculations Then
                calcSet.Add(Calc.Calculation.Create(Calc.CalcType.RecoveryFactorDensity, session).Calculate())
                calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F2Density, session).Calculate())
            End If

            If includeMoistureCalculations Then
                Dim rfm As CalculationResult = Calc.Calculation.Create(Calc.CalcType.RecoveryFactorMoisture, session).Calculate()
                calcSet.Add(rfm)
                ' the recovery factor moisture calculation also requires its own model mining data to be added to support the recalculation
                calcSet.Add(rfm.GetFirstCalcId(Calc.ModelMining.CalculationId))
            End If

            If locationLevel.ToUpper() <> "PIT" Then
                If calcId Is Nothing Then
                    calcSet.Add(New Types.CalculationResult(CalculationResultType.Hidden))
                End If

                If calcId Is Nothing OrElse calcId = Calc.F2.CalculationId Then
                    calcSet.Add(Calc.Calculation.Create(Calc.CalcType.F2, session).Calculate())
                    calcSet.ReplaceDescription("MineProductionExpitEqulivent", "Mine Production Expit Equivalent (C-z+y)")
                    calcSet.ReplaceDescription("MineProductionActuals", "C: Mine Production Actuals")
                    If childLocations Then
                        calcSet.ReplaceDescription("F2Factor", "F2")
                    End If
                End If

                If locationLevel.ToUpper() <> "SITE" Then
                    If calcId Is Nothing Then
                        calcSet.Add(New Types.CalculationResult(CalculationResultType.Hidden))
                    End If
                    If calcId Is Nothing OrElse calcId = Calc.F25.CalculationId Then
                        f25 = Calc.Calculation.Create(Calc.CalcType.F25, session).Calculate()
                        calcSet.Add(f25)
                        f25.ReplaceDescription("PostCrusherStockpileDelta", "J: ∆Post-Crusher Stockpile")
                        f25.ReplaceDescription("MiningModelCrusherEquivalent", "I: Mining Model Crusher Equivalent (A-y+z)")
                        f25.ReplaceDescription("MiningModel", "A: Mining Model (AD)")
                        f25.ReplaceDescription("BeneRatio", Calc.BeneRatio.CalculationDescription.Replace("Bene Ratio", "Bene Ratio %"))

                    End If
                    If calcId Is Nothing Then
                        calcSet.Add(New Types.CalculationResult(CalculationResultType.Hidden))
                    End If
                    If calcId Is Nothing OrElse calcId = Calc.F3.CalculationId Then
                        f3 = Calc.Calculation.Create(Calc.CalcType.F3, session).Calculate()
                        calcSet.Add(f3)

                        f3.ReplaceDescription("MiningModelShippingEquivalent", "Mining Model Shipping Equivalent (I - J + K - L)")
                        f3.ReplaceDescription("MiningModelCrusherEquivalent", "I: Mining Model Crusher Equivalent (A-y+z)")
                        f3.ReplaceDescription("BeneRatio", Calc.BeneRatio.CalculationDescription.Replace("Bene Ratio", "Bene Ratio %"))
                        f3.ReplaceDescription("MiningModel", "A: Mining Model (AS)")
                        f3.ReplaceDescription("PortStockpileDelta", "L: ∆Port Stockpiles")
                        f3.ReplaceDescription("PortBlendedAdjustment", "K: Port Blended Adjustment")
                        f3.ReplaceDescription("PostCrusherStockpileDelta", "J: ∆Post-Crusher Stockpile")

                        If childLocations Then
                            calcSet.ReplaceDescription("F3Factor", "F3")
                        End If
                    End If
                End If

                calcSet.ReplaceDescription("ExPitToOreStockpile", "y: Ex-pit to Ore Stockpile Movements")
                calcSet.ReplaceDescription("StockpileToCrusher", "z: Stockpile to Crusher Movements")
            End If

            Data.ApprovalData.AddApprovalTagLocation(calcSet, locationId, childLocations, session.DalUtility)

            If Not childLocations Then
                table = calcSet.ToDataTable(True, False, False, True, session)
            Else
                'table = calcSet.ToDataTable(True, False, True)
                table = calcSet.ToDataTable(True, False, True, True, session)
            End If

            If (includeDensityCalculations) Then
                ' Density has been included and therefore needs to be copied across to F2
                F1F2F3ReportEngine.FixF2Density(table)
            End If

            ' total doesn't have a AD or AS type, so we want to get rid of that in the description
            table.AsEnumerable.WithProductSize("TOTAL").SetField("Description", Function(r) r.AsString("Description").Replace("(AD)", "").Replace("(AS)", ""))

            ' the PBA for L/F won't add to the total, we want to add something to the label
            ' to flag this so later we don't get emails about it
            table.AsEnumerable.
                Where(Function(r) r.AsString("CalcId") = "PortBlendedAdjustment").
                Where(Function(r) r.AsString("ProductSize") <> "TOTAL").
                SetField("Description", Function(r) r.AsString("Description") + " (NI Only)")

            ' Add an original position value to the table (used for sorting in the next step)
            table.Columns.Add("OriginalPosition", GetType(Integer))

            Dim index As Integer = 0
            For Each row In table.Rows
                If Not childLocations Then
                    row("LocationId") = locationId
                End If
                row("OriginalPosition") = index
                index = index + 1
            Next

            ' Sort the table results in a way that will be better suited for presentation
            ' this is in product size order but otherwise retaining original record orders
            Dim productSizeSortColumn = table.Columns.Add("ProductSizeSortExpression", GetType(Integer))
            productSizeSortColumn.Expression = ProductSizeColumnSortExpression

            Dim sortedTable As DataTable = table.Clone()

            For Each dr As DataRow In table.Select(Nothing, "ProductSizeSortExpression, OriginalPosition")
                Dim newRow As DataRow = sortedTable.Rows.Add(dr.ItemArray)
                If Not newRow.Item("ProductSize").ToString = CalculationResult.ProductSizeTotal Then

                    ' If CalculationDepth is 0 (ie top level) and no Material Type specified then include product size in the description
                    If (String.IsNullOrEmpty(newRow.Item("MaterialTypeId").ToString) And newRow.Item("CalculationDepth").ToString = "0") Then
                        Dim description As String = newRow.Item("Description").ToString

                        Dim indexOfSpaceDash As Integer = description.IndexOf(" -")

                        If indexOfSpaceDash > 0 Then
                            description = description.Substring(0, indexOfSpaceDash)
                        End If
                        description = description + " - " + SentenceCase(newRow.Item("ProductSize").ToString())

                        newRow.Item("Description") = description
                    End If
                End If
            Next

            Data.ApprovalData.AddApprovalFromTags(session, sortedTable)
            Return sortedTable
        End Function

        ''' <summary>
        ''' Transforms text to sentence case, where the first letter is uppercased and the remainder lower.
        ''' </summary>
        ''' <param name="stringToSentenceCase">The string to transform</param>
        ''' <returns>Transformed text</returns>
        ''' <remarks>Example input and output:  "TEST" => "Test", "test" => "Test", "THis iS a Test" => "This is a test"</remarks>
        Private Shared Function SentenceCase(ByVal stringToSentenceCase As String) As String
            Dim result As String = String.Empty

            If Not String.IsNullOrEmpty(stringToSentenceCase) AndAlso stringToSentenceCase.Length > 0 Then
                result = stringToSentenceCase.Substring(0, 1).ToUpper()
                result = result + stringToSentenceCase.Substring(1).ToLower()
            End If

            Return result
        End Function

    End Class
End Namespace
