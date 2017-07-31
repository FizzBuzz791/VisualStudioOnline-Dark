Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Calc

Namespace Data

    Public NotInheritable Class FactorList
        Private Sub New()
        End Sub

        Public Shared ReadOnly Property GetFactors(Optional ByVal reportName As String = Nothing) As IDictionary(Of String, String)
            Get
                Dim list As New Dictionary(Of String, String)

                If reportName = "BhpbioDensityAnalysisReport" Then
                    ' The BhpbioDensityAnalysisReport has a specific list
                    list.Add(ModelMining.CalculationId, ModelMining.CalculationDescription)
                    list.Add(ModelShortTermGeology.CalculationId, ModelShortTermGeology.CalculationDescription)
                    list.Add(ModelGradeControl.CalculationId, "Grade Control")
                    list.Add(ModelGradeControlSTGM.CalculationId, ModelGradeControlSTGM.CalculationDescription)
                    list.Add(ActualMined.CalculationId, ActualMined.CalculationDescription)
                ElseIf reportName = "BhpbioFactorAnalysisReport" Then
                    list.Add(F1.CalculationId, "F1 - Grade Control / Mining Model")
                    list.Add(F15.CalculationId, F15.CalculationDescription)
                    list.Add(F2.CalculationId, "F2 - Mine Production (Expit) / Grade Control")
                    list.Add(F3.CalculationId, F3.CalculationDescription)
                ElseIf reportName = "BhpbioFactorsVsTimeResourceClassificationReport" Then
                    list.Add(F0.CalculationId, F0.CalculationDescription)
                    list.Add(F05.CalculationId, F05.CalculationDescription)
                    list.Add(F1.CalculationId, F1.CalculationDescription)
                Else
                    Dim newFactorReports = New String() {"BhpbioFactorsVsTimeDensityReport", "BhpbioFactorsVsTimeMoistureReport", "BhpbioFactorsVsTimeVolumeReport",
                                                     "BhpbioDensityReconciliationReport", "BhpbioFactorsVsTimeProductReport"}
                    Dim shippingTargetReports = New String() {"BhpbioFactorsVsShippingTargetsReport", "BhpbioFactorsByLocationVsShippingTargetsReport"}
                    Dim forwardEstimateReports = New String() {"BhpbioForwardErrorContributionContextReport"}

                    list.Add(ModelGeology.CalculationId, ModelGeology.CalculationDescription)
                    list.Add(ModelShortTermGeology.CalculationId, ModelShortTermGeology.CalculationDescription)
                    list.Add(ModelMining.CalculationId, ModelMining.CalculationDescription)
                    list.Add(ModelGradeControl.CalculationId, "Grade Control")
                    list.Add(MineProductionExpitEquivalent.CalculationId, MineProductionExpitEquivalent.CalculationDescription)
                    list.Add(MiningModelCrusherEquivalent.CalculationId, MiningModelCrusherEquivalent.CalculationDescription)

                    If Not shippingTargetReports.Contains(reportName) AndAlso Not reportName = "BhpbioF1F2F3GeometReconciliationAttributeReport" Then
                        list.Add(SitePostCrusherStockpileDelta.CalculationId, SitePostCrusherStockpileDelta.CalculationDescription)
                        list.Add(HubPostCrusherStockpileDelta.CalculationId, HubPostCrusherStockpileDelta.CalculationDescription)
                        list.Add(PostCrusherStockpileDelta.CalculationId, PostCrusherStockpileDelta.CalculationDescription)
                        list.Add(PortStockpileDelta.CalculationId, PortStockpileDelta.CalculationDescription)
                    End If

                    list.Add(PortOreShipped.CalculationId, PortOreShipped.CalculationDescription)
                    list.Add(MiningModelShippingEquivalent.CalculationId, MiningModelShippingEquivalent.CalculationDescription)
                    list.Add(MiningModelOreForRailEquivalent.CalculationId, MiningModelOreForRailEquivalent.CalculationDescription)

                    If (Not shippingTargetReports.Contains(reportName)) Then
                        list.Add(OreForRail.CalculationId, OreForRail.CalculationDescription)
                    End If

                    list.Add(F1.CalculationId, "F1 - Grade Control / Mining Model")
                    list.Add(F15.CalculationId, F15.CalculationDescription)

                    If reportName = "BhpbioF1F2F3ReconciliationAttributeReport" Then
                        list.Add(RFGM.CalculationId, RFGM.CalculationDescription)
                        list.Add(RFMM.CalculationId, RFMM.CalculationDescription)
                        list.Add(RFSTM.CalculationId, RFSTM.CalculationDescription)
                    End If

                    list.Add(F2.CalculationId, "F2 - Mine Production (Expit) / Grade Control")

                    If Not shippingTargetReports.Contains(reportName) Then
                        list.Add(F25.CalculationId, F25.CalculationDescription)
                    End If

                    list.Add(F3.CalculationId, F3.CalculationDescription)

                    If newFactorReports.Contains(reportName) Then
                        list.Add(F2Density.CalculationId, F2Density.CalculationDescription)
                        list.Add(RecoveryFactorDensity.CalculationId, RecoveryFactorDensity.CalculationDescription)
                        list.Add(RecoveryFactorMoisture.CalculationId, RecoveryFactorMoisture.CalculationDescription)
                    End If

                    ' the forward contribution reports need to change the factor names slightly to indicate
                    If forwardEstimateReports.Contains(reportName) Then
                        list(F1.CalculationId) = list(F1.CalculationId).Replace("F1", "F1f")
                        list(F15.CalculationId) = list(F15.CalculationId).Replace("F1.5", "F1.5f")
                    End If
                End If

                Return list
            End Get
        End Property

        ' if this method returns true, then the cell will be shown as N/A on the approval page
        Public Shared Function IsCellNA(ByVal reportTagId As String, ByVal columnName As String, Optional ByVal productSize As String = "TOTAL") As Boolean
            ' F2.5 & OFR return null for every grade
            If Not HasGrades(reportTagId, productSize) AndAlso IsGradeColumn(columnName) Then
                Return True
            End If

            ' H2O has a lot of special handling around the n/a, so do that checking here. Some of this might be
            ' redunant now with the F2.5 not having any grades, but leave it anyway, in case they change their mind later
            If columnName.ToUpper = "H2O" Then
                Dim ignoredTags = New String() {"F2StockpileToCrusher", "F2ExPitToOreStockpile",
                                "F25StockpileToCrusher", "F25ExPitToOreStockpile",
                                "F3StockpileToCrusher", "F3ExPitToOreStockpile",
                                "F3PostCrusherStockpileDelta", "F3SitePostCrusherStockpileDelta", "F3HubPostCrusherStockpileDelta",
                                "F3PortBlendedAdjustment", "RFGM", "RFMM", "RFSTM", "F0Factor", "F05Factor"}

                ' these tags are ignored only if the product size is *not* TOTAL
                Dim ignoredLumpFinesTags = New String() {"F1Factor", "F1GeologyModel", "F1MiningModel", "F1GradeControlModel", "GeologyModel",
                                                         "F15Factor", "F15ShortTermGeologyModel", "F15GradeControlSTGM",
                                                         "F2Factor", "F2GradeControlModel"}

                If ignoredTags.Contains(reportTagId) OrElse (productSize <> "TOTAL" AndAlso ignoredLumpFinesTags.Contains(reportTagId)) Then
                    Return True
                End If
            ElseIf columnName.ToUpper = "ULTRAFINES" Then
                Dim ignoredTags = New String() {"F2Factor", "F25SitePostCrusherStockpileDelta", "F25HubPostCrusherStockpileDelta",
                    "F25PostCrusherStockpileDelta", "F25OreForRail", "F2MineProductionExpitEqulivent", "F2MineProductionActuals",
                    "F2ExPitToOreStockpile", "F2StockpileToCrusher", "F3PortStockpileDelta", "F3PortBlendedAdjustment"}
                If (ignoredTags.Contains(reportTagId)) Then
                    Return True
                End If
            End If

            Return False
        End Function
        ' Some calculations have no valid grade values at all, this method will return false if all the grade values should
        ' be n/a or null, otherwise it returns true
        Public Shared Function HasGrades(ByVal reportTagId As String, Optional ByVal productSize As String = "TOTAL") As Boolean
            If (reportTagId = "F25Factor" Or reportTagId = "F25OreForRail" Or reportTagId = "F2DensityActualMined") Then
                Return False
            Else
                Return True
            End If
        End Function

        ' if the column is a grade value then return true otherwise false
        ' ie, 'Fe' returns true, 'Tonnes', 'Volume', 'ProductSize' etc return false
        Public Shared Function IsGradeColumn(ByVal columnName As String) As Boolean
            Return CalculationResultRecord.GradeNames.Contains(columnName)
        End Function

    End Class
End Namespace
