
Imports System.Threading
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportDefinitions

    Public Class F1F2F3ReportEngine
        Public Const COLUMN_TAG_ID As String = "TagId"

#Region "Private Methods"

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualBeneProduct(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualBeneProduct.ClearCache()
                session.GetCacheActualBeneProduct.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCachePortStockpileDelta(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCachePortStockpileDelta.ClearCache()
                session.GetCachePortStockpileDelta.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheBlockModel(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheBlockModel.ClearCache()
                session.GetCacheBlockModel.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheOreForRail(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheOreForRail.ClearCache()
                session.GetCacheOreForRail.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCachePortOreShipped(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCachePortOreShipped.ClearCache()
                session.GetCachePortOreShipped.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCachePortBlendedAdjustment(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCachePortBlendedAdjustment.ClearCache()
                session.GetCachePortBlendedAdjustment.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualStockpileToCrusher(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualStockpileToCrusher.ClearCache()
                session.GetCacheActualStockpileToCrusher.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualMineProduction(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualMineProduction.ClearCache()
                session.GetCacheActualMineProduction.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualExpitToStockpile(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualExpitToStockpile.ClearCache()
                session.GetCacheActualExpitToStockpile.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualHubPostCrusherStockpileDelta(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualHubPostCrusherStockpileDelta.ClearCache()
                session.GetCacheActualHubPostCrusherStockpileDelta.RetrieveData()
            End Using
        End Sub

        ''' <summary>
        ''' Method used to obtain report data on a background thread for caching purposes
        ''' </summary>
        Private Shared Sub BackgroundGetCacheActualSitePostCrusherStockpileDelta(sessionObject As Object)
            ' cast the object passed on Thread.Start to a ReportSession
            Dim session = CType(sessionObject, ReportSession)

            ' Setup a thread report context just for this thread...  within this scope session.DalReport will return a thread specific instance
            Using New ReportThreadContext(session)
                ' access the property.. only to force the data to be looked up and added to cache
                session.GetCacheActualSitePostCrusherStockpileDelta.ClearCache()
                session.GetCacheActualSitePostCrusherStockpileDelta.RetrieveData()
            End Using
        End Sub

        Private Shared Sub BackgroundGetCacheForContext(backgroundContext As Object)
            Dim context = CType(backgroundContext, BackgroundCacheRetrievalContext)

            Try
                context.BackgroundRetrievalSub.Invoke(context.Session)
            Catch ex As Exception
                ' Save the exception
                context.Err = ex
            End Try
        End Sub

        ''' <summary>
        ''' Prepare the report cache by asynchronously performing the data lookups needed
        ''' </summary>
        ''' <param name="session">The report session to be used</param>
        ''' <remarks>This is done for performance reasons</remarks>
        Public Shared Sub PrepareF1F2F3Cache(session As ReportSession)
            Dim backgroundList As New List(Of BackgroundCacheRetrievalContext) From {
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualBeneProduct),
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheBlockModel),
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualStockpileToCrusher),
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualMineProduction),
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualExpitToStockpile),
                    New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualSitePostCrusherStockpileDelta)
                    }

            If Not session.IsFactorExcludedFromHubReportSet(F25.CalculationId) Then
                backgroundList.Add(New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheOreForRail))
            End If

            If Not session.IsFactorExcludedFromHubReportSet(F3.CalculationId) Then
                backgroundList.Add(New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCachePortStockpileDelta))
                backgroundList.Add(New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCachePortOreShipped))
                backgroundList.Add(New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCacheActualHubPostCrusherStockpileDelta))
                backgroundList.Add(New BackgroundCacheRetrievalContext(session, AddressOf BackgroundGetCachePortBlendedAdjustment))
            End If

            Dim threadList As New List(Of Thread)

            For Each backgroundContext In backgroundList
                Dim thread As Thread

                ' make a new thread to handle the background worker work
                ' VB.Net doesn't support anonymous functions in the way need so we need to provide an address of a named function
                thread = New Thread(AddressOf BackgroundGetCacheForContext) With {
                    .IsBackground = True
                    }
                threadList.Add(thread)
                thread.Start(backgroundContext)
            Next

            ' then wait for them all to finish
            ' this is the point at which all the threads join up again
            For Each retrievalThread In threadList
                retrievalThread.Join()
            Next

            ' this function will only exit once all threads have completed
            For Each backgroundContext In backgroundList
                ' if there was an error on a background context.. throw it on this main thread... if it was allowed to throw on the background thread it may kill the entire process
                If Not backgroundContext.Err Is Nothing Then
                    Throw backgroundContext.Err
                End If
            Next
        End Sub

        Private Shared Function GetHubReportSet(session As ReportSession,
                                                locationId As Int32, dateFrom As DateTime,
                                                dateTo As DateTime) As CalculationSet
            Dim holdingData As New CalculationSet

            ' Always retrieve data on a monthly basis from source calculations
            ' This is the only safe way to force larger periods to be aggregated from months
            ' and not just calculated at a higher level which can produce different results depending on the formulas in use
            '
            ' If the user wants to do a quarter aggregation, then the session.DateBreakdown parameter needs to be set
            ' this will causes the aggregation to be done in the code later on when the ToDataTable method is run
            ' the breakdown getting set here is just the one that goes to the database (AFAIK!)
            session.CalculationParameters(dateFrom, dateTo, ReportBreakdown.Monthly, locationId, Nothing)

            session.UseHistorical = True

            ' Force the data we are going to need into the cache in an efficient manner
            PrepareF1F2F3Cache(session)

            ' Then allow normal processing
            Dim f1Calc As CalculationResult = Nothing
            Dim f15Calc As CalculationResult = Nothing
            Dim f2Calc As CalculationResult = Nothing
            Dim f2DensityCalc As CalculationResult = Nothing
            Dim f25Calc As CalculationResult = Nothing
            Dim f3Calc As CalculationResult = Nothing
            Dim miningModelCrusherEquivalentResult As CalculationResult

            Dim postCrusherStockpileDeltaResult As CalculationResult
            Dim portBlendedAdjustmentResult As CalculationResult = Nothing
            Dim portStockpileDeltaResult As CalculationResult = Nothing
            Dim sitePostCrusherStockpileDeltaResult As CalculationResult
            Dim hubPostCrusherStockpileDeltaResult As CalculationResult
            Dim rfgmResult As CalculationResult = Nothing
            Dim rfmmResult As CalculationResult = Nothing
            Dim rfstmResult As CalculationResult = Nothing
            Dim f0Result As CalculationResult = Nothing
            Dim f05Result As CalculationResult = Nothing

            If Not session.IsFactorExcludedFromHubReportSet(F1.CalculationId) Then
                f1Calc = Calculation.Create(CalcType.F1, session).Calculate()
            End If

            If Not session.IsFactorExcludedFromHubReportSet(F15.CalculationId) Then
                f15Calc = Calculation.Create(CalcType.F15, session).Calculate()
            End If

            If Not session.IsFactorExcludedFromHubReportSet(F2.CalculationId) Then
                f2Calc = Calculation.Create(CalcType.F2, session).Calculate()
                f2DensityCalc = Calculation.Create(CalcType.F2Density, session).Calculate()
            End If

            If Not session.IsFactorExcludedFromHubReportSet(F25.CalculationId) Then
                f25Calc = Calculation.Create(CalcType.F25, session).Calculate()
            End If

            If Not session.IsFactorExcludedFromHubReportSet(F3.CalculationId) Then
                f3Calc = Calculation.Create(CalcType.F3, session).Calculate()
            End If

            If session.OptionalCalculationTypesToInclude.Contains(CalcType.RFGM) Then
                rfgmResult = Calculation.Create(CalcType.RFGM, session).Calculate()
            End If

            If session.OptionalCalculationTypesToInclude.Contains(CalcType.RFMM) Then
                rfmmResult = Calculation.Create(CalcType.RFMM, session).Calculate()
            End If

            If session.OptionalCalculationTypesToInclude.Contains(CalcType.RFSTM) Then
                rfstmResult = Calculation.Create(CalcType.RFSTM, session).Calculate()
            End If

            If session.OptionalCalculationTypesToInclude.Contains(CalcType.F0) Then
                f0Result = Calculation.Create(CalcType.F0, session).Calculate()
                f0Result.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), True))
            End If

            If session.OptionalCalculationTypesToInclude.Contains(CalcType.F05) Then
                f05Result = Calculation.Create(CalcType.F05, session).Calculate()
                f05Result.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), True))
            End If

            Dim geologyModel = Calculation.Create(CalcType.ModelGeology, session).Calculate()
            Dim geologyModelH2OAsDropped As CalculationResult = Nothing
            Dim geologyModelH2OAsShipped As CalculationResult = Nothing
            Dim miningModelH2OAsDropped As CalculationResult = Nothing
            Dim miningModelH2OAsShipped As CalculationResult = Nothing

            ' for sites that have bene material, the mining model will be different in the F2.5 and F3, because
            ' it will have the bene adjustment applied. In certain circumstances we want to show this number
            Dim miningModelBeneAdjusted As CalculationResult = Nothing

            If session.ExplicitlyIncludeExtendedH2OModelCalculations Then
                geologyModelH2OAsDropped = CalculationModel.CreateForExplicitH2OOverride(CalcType.ModelGeology, session, CalculationModel.H2OOverideAsDropped).Calculate()
                geologyModelH2OAsShipped = CalculationModel.CreateForExplicitH2OOverride(CalcType.ModelGeology, session, CalculationModel.H2OOverideAsShipped).Calculate()
                miningModelH2OAsDropped = CalculationModel.CreateForExplicitH2OOverride(CalcType.ModelMining, session, CalculationModel.H2OOverideAsDropped).Calculate()
                miningModelH2OAsShipped = CalculationModel.CreateForExplicitH2OOverride(CalcType.ModelMining, session, CalculationModel.H2OOverideAsShipped).Calculate()
                miningModelH2OAsDropped.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), True))
                miningModelH2OAsShipped.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), True))
            End If

            Dim shortTermGeologyModel = Calculation.Create(CalcType.ModelShortTermGeology, session).Calculate()

            If Not f25Calc Is Nothing Then
                miningModelCrusherEquivalentResult = f25Calc.GetFirstCalcId(MiningModelCrusherEquivalent.CalculationId)
                postCrusherStockpileDeltaResult = f25Calc.GetFirstCalcId(PostCrusherStockpileDelta.CalculationId)
                sitePostCrusherStockpileDeltaResult = f25Calc.GetFirstCalcId(SitePostCrusherStockpileDelta.CalculationId)
                hubPostCrusherStockpileDeltaResult = f25Calc.GetFirstCalcId(HubPostCrusherStockpileDelta.CalculationId)
            Else
                miningModelCrusherEquivalentResult = Calculation.Create(CalcType.MiningModelCrusherEquivalent, session).Calculate()
                postCrusherStockpileDeltaResult = Calculation.Create(CalcType.PostCrusherStockpileDelta, session).Calculate()
                sitePostCrusherStockpileDeltaResult = Calculation.Create(CalcType.SitePostCrusherStockpileDelta, session).Calculate()
                hubPostCrusherStockpileDeltaResult = Calculation.Create(CalcType.HubPostCrusherStockpileDelta, session).Calculate()
            End If

            ' and other components when F3 is needed
            If Not f3Calc Is Nothing Then
                portBlendedAdjustmentResult = f3Calc.GetFirstCalcId(PortBlendedAdjustment.CalculationId)
                portStockpileDeltaResult = f3Calc.GetFirstCalcId(PortStockpileDelta.CalculationId)

                ' does the report need to show the mining model bene stuff? It can be different to the normal mining model
                If session.OptionalCalculationTypesToInclude.Contains(CalcType.ModelMiningBene) Then
                    miningModelBeneAdjusted = f3Calc.GetFirstCalcId(ModelMining.CalculationId)
                    miningModelBeneAdjusted.Description += " (Bene Adjusted)"
                    Dim hasBene = miningModelBeneAdjusted.MaterialTypeIdCollection.Where(Function(r) r.HasValue).Count > 1

                    ' ok, if we actually don't have bene material then we don't want to show this line item, so turn it off
                    If Not hasBene Then
                        miningModelBeneAdjusted = Nothing
                    End If
                End If
            End If

            'Determine if we should be showing it.
            Dim valid = FactorLocation.IsLocationInLocationType(session, session.RequestParameter.LocationId, "HUB")

            ' add the validation flags to the results (where we have them)
            If Not miningModelCrusherEquivalentResult Is Nothing Then
                miningModelCrusherEquivalentResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            If Not postCrusherStockpileDeltaResult Is Nothing Then
                postCrusherStockpileDeltaResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            If Not sitePostCrusherStockpileDeltaResult Is Nothing Then
                sitePostCrusherStockpileDeltaResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            If Not hubPostCrusherStockpileDeltaResult Is Nothing Then
                hubPostCrusherStockpileDeltaResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            If Not portBlendedAdjustmentResult Is Nothing Then
                portBlendedAdjustmentResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            If Not portStockpileDeltaResult Is Nothing Then
                portStockpileDeltaResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            End If

            ' add the results to the holding table (where we have them)
            '
            ' NOTE: the order the calcs are added to the holding table is generally the order they will be displayed in the
            ' reports, so pay attention to it
            If Not geologyModel Is Nothing Then
                holdingData.Add(geologyModel)
            End If

            If Not geologyModelH2OAsDropped Is Nothing Then
                holdingData.Add(geologyModelH2OAsDropped)
            End If

            If Not geologyModelH2OAsShipped Is Nothing Then
                holdingData.Add(geologyModelH2OAsShipped)
            End If

            If Not f15Calc Is Nothing Then
                holdingData.Add(f15Calc.GetFirstCalcId(ModelShortTermGeology.CalculationId))
            End If

            If Not f1Calc Is Nothing Then
                holdingData.Add(f1Calc.GetFirstCalcId(ModelMining.CalculationId))
            End If

            If Not miningModelBeneAdjusted Is Nothing Then
                holdingData.Add(miningModelBeneAdjusted)
            End If

            If Not miningModelH2OAsDropped Is Nothing Then
                holdingData.Add(miningModelH2OAsDropped)
            End If

            If Not miningModelH2OAsShipped Is Nothing Then
                holdingData.Add(miningModelH2OAsShipped)
            End If

            If Not f1Calc Is Nothing Then
                holdingData.Add(f1Calc.GetFirstCalcId(ModelGradeControl.CalculationId))
            End If

            If Not f15Calc Is Nothing Then
                holdingData.Add(f15Calc.GetFirstCalcId(ModelGradeControlSTGM.CalculationId))
            End If

            If session.IncludeAsShippedModelsInHubSet Then
                Dim geo = ModelGeology.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim gc = ModelGradeControl.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                Dim mm = ModelMining.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()

                gc.PrefixTagId("F1")
                mm.PrefixTagId("F1")
                holdingData.Add(geo)
                holdingData.Add(gc)
                holdingData.Add(mm)

                If Not session.IsFactorExcludedFromHubReportSet(F15.CalculationId) Then
                    Dim stm = ModelShortTermGeology.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                    Dim gcstm = ModelGradeControlSTGM.CreateWithGeometType(session, GeometTypeSelection.AsShipped).Calculate()
                    stm.PrefixTagId("F15")
                    gcstm.PrefixTagId("F15")
                    holdingData.Add(stm)
                    holdingData.Add(gcstm)
                End If
            End If

            If Not miningModelCrusherEquivalentResult Is Nothing Then
                holdingData.Add(miningModelCrusherEquivalentResult)
            End If

            If Not sitePostCrusherStockpileDeltaResult Is Nothing Then
                holdingData.Add(sitePostCrusherStockpileDeltaResult)
            End If

            If Not hubPostCrusherStockpileDeltaResult Is Nothing Then
                holdingData.Add(hubPostCrusherStockpileDeltaResult)
            End If

            If Not postCrusherStockpileDeltaResult Is Nothing Then
                holdingData.Add(postCrusherStockpileDeltaResult)
            End If

            If Not f25Calc Is Nothing Then
                holdingData.Add(f25Calc.GetFirstCalcId(OreForRail.CalculationId))
            End If

            If Not f25Calc Is Nothing Then
                holdingData.Add(f25Calc.GetFirstCalcId(MiningModelOreForRailEquivalent.CalculationId))
            End If

            If Not f2Calc Is Nothing Then
                Dim mineProductionExpitEquivalent = f2Calc.GetFirstCalcId(Calc.MineProductionExpitEquivalent.CalculationId)

                holdingData.Add(mineProductionExpitEquivalent)
                holdingData.Add(mineProductionExpitEquivalent.GetFirstCalcId(MineProductionActuals.CalculationId))
                holdingData.Add(mineProductionExpitEquivalent.GetFirstCalcId(ExpitToOreStockpile.CalculationId))
                holdingData.Add(mineProductionExpitEquivalent.GetFirstCalcId(StockpileToCrusher.CalculationId))

                If Not f2DensityCalc Is Nothing Then
                    ' hide all these, and then add the density to the other calculations at the last moment
                    holdingData.Add(f2DensityCalc.GetFirstCalcId(ModelGradeControl.CalculationId))

                    Dim actualMined = f2DensityCalc.GetFirstCalcId(Calc.ActualMined.CalculationId)
                    If Not actualMined Is Nothing Then
                        holdingData.Add(actualMined)
                    End If
                    holdingData.Add(f2DensityCalc)
                End If
            End If

            If f15Calc Is Nothing Then
                ' only add the STGM explicitly if the F1.5 is not added. otherwise it will get
                ' doubled up
                If Not shortTermGeologyModel Is Nothing Then
                    holdingData.Add(shortTermGeologyModel)
                End If
            End If

            If session.OptionalCalculationTypesToInclude.Count > 0 Then
                For Each calcTypeToInclude In session.OptionalCalculationTypesToInclude
                    If calcTypeToInclude = CalcType.ModelMiningBene Or
                       calcTypeToInclude = CalcType.RFGM Or
                       calcTypeToInclude = CalcType.RFMM Or
                       calcTypeToInclude = CalcType.RFSTM Or
                       calcTypeToInclude = CalcType.F0 Or
                       calcTypeToInclude = CalcType.F05 Then
                        Continue For
                    End If
                    Dim result = Calculation.Create(calcTypeToInclude, session).Calculate()

                    If Not result Is Nothing Then
                        holdingData.Add(result)

                        ' for ratio calculations (ie factors) we need to add all the sub-calculation results as well, because after
                        ' aggregation the results need to be recalculated. We add them with the presentationValid set to false, so that
                        ' they will not appear in the results when they are rendered in the reports and so on
                        If result.CalculationType = CalculationResultType.Ratio Then
                            For Each calcResult In result.GetAllCalculations().Where(Function(c) c.CalcId <> result.CalcId)
                                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), False))
                                holdingData.Add(calcResult)
                            Next
                        End If
                    End If
                Next
            End If

            If Not portStockpileDeltaResult Is Nothing Then
                holdingData.Add(portStockpileDeltaResult)
            End If

            If Not portBlendedAdjustmentResult Is Nothing Then
                holdingData.Add(portBlendedAdjustmentResult)
            End If

            If Not f3Calc Is Nothing Then
                holdingData.Add(f3Calc.GetFirstCalcId(MiningModelShippingEquivalent.CalculationId))
            End If

            If session.IncludeAsShippedModelsInHubSet AndAlso f3Calc IsNot Nothing AndAlso f3Calc.PresentationValid Then
                ' for the mmse we want to include the AD version, as that is the non-standard one.
                Dim mmse = MiningModelShippingEquivalent.CreateWithGeometType(session, GeometTypeSelection.AsDropped).Calculate()
                mmse.PrefixTagId("F3")
                mmse.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), f3Calc.PresentationValid))
                holdingData.Add(mmse)
            End If

            If Not f3Calc Is Nothing Then
                holdingData.Add(f3Calc.GetFirstCalcId(PortOreShipped.CalculationId))
            End If

            If Not f0Result Is Nothing Then
                holdingData.Add(f0Result)
            End If

            If Not f05Result Is Nothing Then
                holdingData.Add(f05Result)
            End If

            If Not f1Calc Is Nothing Then
                holdingData.Add(f1Calc)
            End If

            If Not f15Calc Is Nothing Then
                holdingData.Add(f15Calc)
            End If

            If Not rfgmResult Is Nothing Then
                holdingData.Add(rfgmResult)
            End If

            If Not rfmmResult Is Nothing Then
                holdingData.Add(rfmmResult)
            End If

            If Not rfstmResult Is Nothing Then
                holdingData.Add(rfstmResult)
            End If

            If Not f2Calc Is Nothing Then
                holdingData.Add(f2Calc)
            End If

            If Not f25Calc Is Nothing Then
                holdingData.Add(f25Calc)
            End If

            If Not f3Calc Is Nothing Then
                holdingData.Add(f3Calc)
            End If

            Return holdingData
        End Function

        Private Shared Sub MakeTheZeroRecordsNull(result As DataTable)
            Dim gradeNames = CalculationResultRecord.GradeNames.ToList
            Dim attributeNames = New List(Of String)(gradeNames)
            attributeNames.Insert(0, "Tonnes")
            attributeNames.Insert(1, "Volume")

            For Each row As DataRow In result.Rows
                For Each col In attributeNames
                    If row(col) Is DBNull.Value OrElse Math.Abs(DirectCast(row(col), Double) - 0.0) < Double.Epsilon Then
                        row(col) = DBNull.Value
                        If result.Columns.Contains(col & "Difference") Then
                            row(col & "Difference") = DBNull.Value
                        End If
                    End If
                Next
            Next
        End Sub

        Public Shared Function AddResourceClassificationColor(table As DataTable, Optional columnName As String = "PresentationColor") As DataTable
            If Not table.Columns.Contains(columnName) Then
                table.Columns.Add(columnName)
            End If

            For Each row As DataRow In table.Rows
                If row.HasValue("ResourceClassification") Then
                    row(columnName) = GetResourceClassificationColor(row)
                End If
            Next

            Return table
        End Function

        Friend Shared Function GetResourceClassificationColor(row As DataRow) As String
            Return GetResourceClassificationColor(row.AsString("ResourceClassification"))
        End Function

        Friend Shared Function GetResourceClassificationColor(resourceClassificationCode As String) As String
            Dim colour As String

            Select Case resourceClassificationCode
                Case "ResourceClassification1"
                    colour = "#4DFA90"
                Case "ResourceClassification2"
                    colour = "#FABE4D"
                Case "ResourceClassification3"
                    colour = "#FF5468"
                Case "ResourceClassification4"
                    colour = "#f062c7"
                Case "ResourceClassification5"
                    colour = "#909090"
                Case Else
                    colour = "#D0D0D0"
            End Select

            Return colour
        End Function

        '
        ' this method converts the DataTable from the pivoted version, with each grade in a separate column, into the unpivoted version
        ' where each grade has ites own row
        '
        ' the grade name is stored in Attribute, and the value in AttributeValue
        '
        ' maintainTonnes will stop the tonnes column from being deleted - it is often useful to have this column to calculate metal
        ' tonnes, error contributions etc, so it only needs to be readded if removed
        '
        Public Shared Function UnpivotDataTable(table As DataTable, Optional maintainTonnes As Boolean = False) As DataTable

            If table.IsUnpivotedTable Then
                Throw New NotSupportedException("This table is already unpivoted")
            End If

            table.Columns.Add("Attribute")
            table.Columns.Add("AttributeValue")

            Dim newRows = New List(Of DataRow)()
            Dim attributeNames = CalculationResultRecord.AttributeNames

            ' get the new set of unpivoted rows
            For Each row As DataRow In table.Rows
                For Each attributeName In attributeNames
                    Dim attributeValue = row.AsDblN(attributeName)

                    If table.Columns.Contains(attributeName) Then
                        Dim newRow = GenericDataTableExtensions.Copy(row)

                        newRow("Attribute") = attributeName

                        If attributeValue IsNot Nothing Then
                            newRow("AttributeValue") = attributeValue
                        Else
                            newRow("AttributeValue") = DBNull.Value
                        End If

                        newRows.Add(newRow)
                    End If
                Next
            Next

            ' delete all the existing unpivoted rows
            table.Rows.Clear()

            ' add the new rows to the table
            For Each row In newRows
                table.Rows.Add(row)
            Next

            ' delete the unneeded pivot columns
            For Each attributeName In attributeNames
                If Not maintainTonnes Or attributeName <> "Tonnes" AndAlso table.Columns.Contains(attributeName) Then
                    table.Columns.Remove(attributeName)
                End If
            Next

            Return table

        End Function


        ' to be honest, I'm not sure why this function has to exist - the aggregation logic to do this already exists in the calculation classes
        ' and this is essentially duplicating it. At the very least. I feel like its possible to replace this with a linq statement that
        ' would work in a much clearer way. Could have speed implications though. (NR)
        '
        ' NOTE: This function is used to aggregate multiple months into larger time periods
        Public Shared Function Aggregate(resultsToAggregate As DataTable, referenceTime As DateTime, 
                                         Optional ByVal retainCalendarGroupings As Boolean = False) As DataTable

            Dim resultTable As DataTable
            Dim resultRow As DataRow
            Dim ratio As Boolean
            Dim firstRow As Boolean

            Dim tagsHashSet As New HashSet(Of String)
            Dim tags As New List(Of String)
            Dim calendarDateHashSet As New HashSet(Of DateTime)
            Dim calendarDateList As New List(Of DateTime)

            Dim gradeNames = CalculationResultRecord.GradeNames.ToList
            Dim attributeNames = New List(Of String)(gradeNames)
            attributeNames.AddRange(From gradeName In gradeNames Select gradeName + "Difference")

            ' for the purposes of this method, attributes are all the grades, plus the grade difference tags

            'find the distinct tags and calendar dates
            For Each row As DataRow In resultsToAggregate.Rows()
                If Not tagsHashSet.Contains(DirectCast(row("TagId"), String)) Then
                    tags.Add(DirectCast(row("TagId"), String))
                    tagsHashSet.Add(DirectCast(row("TagId"), String))
                End If

                If retainCalendarGroupings OrElse calendarDateHashSet.Count = 0 AndAlso
                    Not calendarDateHashSet.Contains(DirectCast(row("CalendarDate"), DateTime)) Then

                    calendarDateHashSet.Add(DirectCast(row("CalendarDate"), DateTime))
                    calendarDateList.Add(DirectCast(row("CalendarDate"), DateTime))
                End If
            Next

            'copy the structure
            resultTable = resultsToAggregate.Clone()

            If resultTable.Columns.Contains("Order_No") Then
                resultTable.DefaultView.Sort = resultsToAggregate.DefaultView.Sort
            End If

            For Each tag In tags
                For Each calendarDate In calendarDateList
                    firstRow = True
                    resultRow = Nothing

                    Dim filterExpression As String

                    If retainCalendarGroupings Then
                        filterExpression = $"TagId = '{tag}' AND CalendarDate = '{calendarDate:yyyy-MM-dd}'"
                    Else
                        filterExpression = $"TagId = '{tag}'"
                    End If

                    For Each currentRow In resultsToAggregate.Select(filterExpression)
                        'assign the appropriate values directly from the first result
                        If firstRow Then
                            resultRow = resultTable.NewRow()
                            resultTable.Rows.Add(resultRow)

                            ratio = DirectCast(currentRow("Type"), CalculationResultType) = CalculationResultType.Ratio

                            'copy the first row
                            For Each column In New String() _
                                {"TagId", "CalcId", "Description", "Type", "CalculationDepth", "InError",
                                 "ErrorMessage", "RootCalcId", "PresentationEditable", "PresentationLocked",
                                 "PresentationValid", "PresentationColor", CalculationConstants.COLUMN_NAME_PRODUCT_SIZE, CalculationConstants.COLUMN_NAME_REPORT_TAG_ID}
                                resultRow(column) = currentRow(column)
                            Next

                            resultRow("LocationId") = DBNull.Value
                            resultRow("MaterialTypeId") = DBNull.Value

                        End If

                        'aggregate the result into the current record

                        'take the minimum
                        If firstRow OrElse DirectCast(resultRow("CalendarDate"), DateTime) > DirectCast(currentRow("CalendarDate"), DateTime) Then
                            resultRow("CalendarDate") = currentRow("CalendarDate")
                        End If

                        'take the minimum
                        If firstRow OrElse DirectCast(resultRow("DateFrom"), DateTime) > DirectCast(currentRow("DateFrom"), DateTime) Then
                            resultRow("DateFrom") = currentRow("DateFrom")
                        End If

                        'take the maximum
                        If firstRow OrElse DirectCast(resultRow("DateTo"), DateTime) < DirectCast(currentRow("DateTo"), DateTime) Then
                            resultRow("DateTo") = currentRow("DateTo")
                        End If

                        If resultRow.HasColumn("Order_No") Then
                            If firstRow OrElse resultRow.AsInt("Order_No") < currentRow.AsInt("Order_No") Then
                                resultRow("Order_No") = currentRow("Order_No")
                            End If
                        End If

                        'perform the value based aggregates if the tonnes are valid
                        If firstRow OrElse Not currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value Then
                            'sum the tonnes
                            For Each tonnesName In New String() {"Tonnes", "Volume", "TonnesDifference"}
                                If firstRow Then
                                    resultRow(tonnesName) = currentRow(tonnesName)
                                ElseIf Not (resultRow(tonnesName) Is DBNull.Value) _
                                       AndAlso Not (currentRow(tonnesName) Is DBNull.Value) Then
                                    resultRow(tonnesName) = DirectCast(resultRow(tonnesName), Double) + DirectCast(currentRow(tonnesName), Double)
                                ElseIf Not (currentRow(tonnesName) Is DBNull.Value) Then
                                    resultRow(tonnesName) = DirectCast(currentRow(tonnesName), Double)
                                End If
                            Next

                            If firstRow AndAlso Not (currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value) Then
                                resultRow("DodgyAggregateGradeTonnes") = Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double))
                            ElseIf Not (resultRow("DodgyAggregateGradeTonnes") Is DBNull.Value) _
                                   AndAlso Not (currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value) Then
                                resultRow("DodgyAggregateGradeTonnes") = DirectCast(resultRow("DodgyAggregateGradeTonnes"), Double) + Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double))
                            ElseIf Not (currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value) Then
                                resultRow("DodgyAggregateGradeTonnes") = Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double))
                            End If

                            'weight-sum the grades
                            For Each gradeName In attributeNames
                                If firstRow AndAlso Not currentRow(gradeName) Is DBNull.Value Then
                                    If ratio Then
                                        resultRow(gradeName) = DirectCast(currentRow(gradeName), Double)
                                    Else
                                        resultRow(gradeName) = DirectCast(currentRow(gradeName), Double) * Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double))
                                    End If
                                ElseIf Not (resultRow(gradeName) Is DBNull.Value) _
                                       And Not (currentRow(gradeName) Is DBNull.Value) _
                                       And Not (currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value) Then
                                    If ratio Then
                                        resultRow(gradeName) = DirectCast(resultRow(gradeName), Double) + (DirectCast(currentRow(gradeName), Double))
                                    Else
                                        resultRow(gradeName) = DirectCast(resultRow(gradeName), Double) + (DirectCast(currentRow(gradeName), Double) * Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double)))
                                    End If
                                ElseIf Not (currentRow(gradeName) Is DBNull.Value) _
                                       And Not (currentRow("DodgyAggregateGradeTonnes") Is DBNull.Value) Then
                                    If ratio Then
                                        resultRow(gradeName) = (DirectCast(currentRow(gradeName), Double))
                                    Else
                                        resultRow(gradeName) = (DirectCast(currentRow(gradeName), Double) * Math.Abs(DirectCast(currentRow("DodgyAggregateGradeTonnes"), Double)))
                                    End If
                                End If
                            Next
                        End If

                        firstRow = False
                    Next

                    If Not resultRow Is Nothing AndAlso Not ratio Then
                        For Each target In attributeNames
                            If Not resultRow(target) Is DBNull.Value Then
                                resultRow(target) = DirectCast(resultRow(target), Double)/
                                                    DirectCast(resultRow("DodgyAggregateGradeTonnes"), Double)
                            End If
                        Next
                    End If
                Next
            Next

            Return resultTable
        End Function

        ''' <summary>
        ''' Update / Recalculate Factor row values based on component values within the data table.
        ''' NOTE: Use RecalculateF1F2F3Factors instead of calling this directly
        ''' </summary>
        ''' <param name="resultTable">The table whose factor values must be updated</param>
        ''' <param name="groupOnCalendarDate">If true, the results are grouped on calendar date... if false, only a single date is expected</param>
        ''' <param name="includeFactorPrefixOnCalcIds">If true, the F1 F2 F3 factor prefixes will be prepended to row Ids</param>
        ''' <returns>The same table (it is updated in place, so return value can be ignored)</returns>
        ''' <remarks>This function exists because when multiple sets of results are merged into a datatable together (such as results for multiple periods), the factor values become invalid and must be recalculated from the aggregate components</remarks>
        Public Shared Function CalculateF1F2F3Factors(resultTable As DataTable, 
                                                      Optional ByVal groupOnCalendarDate As Boolean = False, 
                                                      Optional ByVal includeFactorPrefixOnCalcIds As Boolean = True, 
                                                      Optional ByVal locationId As Integer? = Nothing) As DataTable

            Const AD_SUFFIX = "ADForTonnes"
            Dim rowIndexByTagDictionary = New Dictionary(Of String, DataRow)
            Dim productSizes = New HashSet(Of String)
            Dim calendarDates = New HashSet(Of Date)
            Dim resourceClassifications = New HashSet(Of String)

            Dim f0Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F0", ""))
            Dim f05Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F05", ""))
            Dim f1Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F1", ""))
            Dim f15Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F15", ""))
            Dim f2Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F2", ""))
            Dim f25Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F25", ""))
            Dim f3Prefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F3", ""))
            Dim rfstmPrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "RFSTM", ""))
            Dim rfmmPrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "RFMM", ""))
            Dim rfgmPrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "RFGM", ""))

            Dim recoveryFactorDensityPrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "RFD", ""))
            Dim recoveryFactorMoisturePrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "RFM", ""))
            Dim f2DensityPrefix = CStr(IIf(includeFactorPrefixOnCalcIds, "F2Density", ""))


            ' Create a dictionary of rows by TagId and Product size
            If Not resultTable Is Nothing Then
                Dim matchedRows = resultTable.AsEnumerable

                If locationId.HasValue Then
                    matchedRows = matchedRows.Where(Function(r) r.AsInt("LocationId") = locationId.Value)
                End If

                For Each row In matchedRows
                    Dim rowKey = row.Item(COLUMN_TAG_ID).ToString()
                    Dim productSize = row.Item(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE).ToString()
                    Dim resourceClassification = row.Item(CalculationConstants.COLUMN_NAME_RESOURCE_CLASSIFICATION).ToString()

                    If productSize <> "TOTAL" AndAlso Not rowKey.EndsWith(productSize, StringComparison.Ordinal) Then
                        rowKey += productSize.ToUpper
                    End If

                    If Not String.IsNullOrEmpty(resourceClassification) Then
                        rowKey = $"{rowKey}_{resourceClassification.ToUpper}"
                    End If

                    If groupOnCalendarDate Then
                        calendarDates.Add(CDate(row.Item("CalendarDate")))
                        rowKey = $"{rowKey}_{row.Item("CalendarDate"):yyyyMMdd}"
                    End If

                    ' Add each row by TagId to a dictionary by TagId
                    rowIndexByTagDictionary.Add(rowKey, row)

                    ' Determine the list of product sizes and resource classifications seen
                    productSizes.Add(productSize)
                    resourceClassifications.Add(resourceClassification)
                Next
            End If

            If Not groupOnCalendarDate Then
                ' just add a single entry to the calendar date list.. this forms a single iteration of the outer loop even though the value won't be used
                calendarDates.Add(Date.MinValue)
            End If

            ' Iterate each calendar date in the set
            For Each calendarDate In calendarDates

                Dim calendarDateRowKeySuffix = String.Empty
                If groupOnCalendarDate Then
                    calendarDateRowKeySuffix = $"_{calendarDate:yyyyMMdd}"
                End If

                ' Iterate for each ProductSize in the set
                For Each productSize In productSizes
                    For Each resourceClassification In resourceClassifications

                        Dim resourceClassificationTagSuffix = String.Empty

                        If Not String.IsNullOrEmpty(resourceClassification) Then
                            resourceClassificationTagSuffix = $"_{resourceClassification.ToUpper()}"
                        End If

                        Dim dataRowF1GradeControl As DataRow = Nothing
                        Dim dataRowF1MiningModel As DataRow = Nothing
                        Dim dataRowF1Factor As DataRow = Nothing

                        Dim dataRowF15GradeControlSTGM As DataRow = Nothing
                        Dim dataRowF15ShortTermGeology As DataRow = Nothing
                        Dim dataRowF15Factor As DataRow = Nothing

                        ' note that the F2 GC is only available in special cases, most of the time
                        ' the F1 GC is used to recalculate the F2
                        Dim dataRowF2GradeControl As DataRow = Nothing
                        Dim dataRowF2MineProductionExpitEquivalent As DataRow = Nothing
                        Dim dataRowF2Factor As DataRow = Nothing

                        Dim dataRowF25Factor As DataRow = Nothing
                        Dim dataRowF25FactorMiningModelOreForRailEquivalent As DataRow = Nothing
                        Dim dataRowF25OreForRail As DataRow = Nothing

                        Dim dataRowF3OreShipped As DataRow = Nothing
                        Dim dataRowF3MiningModelShippingEquivalent As DataRow = Nothing
                        Dim dataRowF3Factor As DataRow = Nothing

                        Dim dataRowRFDActualMined As DataRow = Nothing
                        Dim dataRowRFDMiningModel As DataRow = Nothing
                        Dim dataRowRFDFactor As DataRow = Nothing

                        Dim dataRowRFMMineProductionActuals As DataRow = Nothing
                        Dim dataRowRFMMiningModel As DataRow = Nothing
                        Dim dataRowRFMFactor As DataRow = Nothing
                        Dim dataRowF0Factor As DataRow = Nothing
                        Dim dataRowF05Factor As DataRow = Nothing

                        Dim dataRowF2DensityActualMined As DataRow = Nothing
                        Dim dataRowF2DensityGradeControl As DataRow = Nothing
                        Dim dataRowF2DensityFactor As DataRow = Nothing

                        Dim dataRowRFGM As DataRow = Nothing
                        Dim dataRowRFMM As DataRow = Nothing
                        Dim dataRowRFSTM As DataRow = Nothing
                        Dim dataRowRFGMMineProductionExpitEquivalent As DataRow = Nothing
                        Dim dataRowRFMMMineProductionExpitEquivalent As DataRow = Nothing
                        Dim dataRowRFSTMMineProductionExpitEquivalent As DataRow = Nothing
                        Dim dataRowRFGMGeologyModel As DataRow = Nothing
                        Dim dataRowRFMMMiningModel As DataRow = Nothing
                        Dim dataRowRFSTMShortTermGeology As DataRow = Nothing


                        Dim dataRowF0GeologyModel As DataRow = Nothing
                        Dim dataRowF0MiningModel As DataRow = Nothing

                        Dim dataRowF05GeologyModel As DataRow = Nothing
                        Dim dataRowF05GradeControlModel As DataRow = Nothing

                        ' the product size 'TOTAL' is not used as a suffix, so will need to exclude it from our matching
                        If productSize = CalculationConstants.PRODUCT_SIZE_TOTAL Then
                            productSize = String.Empty
                        End If

                        ' F1
                        rowIndexByTagDictionary.TryGetValue(f1Prefix & ModelGradeControl.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF1GradeControl)
                        rowIndexByTagDictionary.TryGetValue(f1Prefix & ModelMining.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF1MiningModel)
                        rowIndexByTagDictionary.TryGetValue(F1.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF1Factor)

                        ' F0
                        rowIndexByTagDictionary.TryGetValue(F0.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF0Factor)
                        rowIndexByTagDictionary.TryGetValue(f0Prefix & ModelGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF0GeologyModel)
                        rowIndexByTagDictionary.TryGetValue(f0Prefix & ModelMining.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF0MiningModel)
                        dataRowF0Factor.RecalculateRatios(dataRowF0MiningModel, dataRowF0GeologyModel)

                        'F0.5
                        rowIndexByTagDictionary.TryGetValue(F05.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF05Factor)
                        rowIndexByTagDictionary.TryGetValue(f05Prefix & ModelGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF05GeologyModel)
                        rowIndexByTagDictionary.TryGetValue(f05Prefix & ModelGradeControl.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF05GradeControlModel)
                        dataRowF05Factor.RecalculateRatios(dataRowF05GradeControlModel, dataRowF05GeologyModel)

                        ' F1.5
                        rowIndexByTagDictionary.TryGetValue(f15Prefix & ModelGradeControlSTGM.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF15GradeControlSTGM)
                        rowIndexByTagDictionary.TryGetValue(f15Prefix & ModelShortTermGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF15ShortTermGeology)
                        rowIndexByTagDictionary.TryGetValue(F15.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowF15Factor)

                        ' now we have enough to recalculate F0, F0.5, F1 and F1.5

                        dataRowF1Factor.RecalculateRatios(dataRowF1GradeControl, dataRowF1MiningModel)
                        dataRowF15Factor.RecalculateRatios(dataRowF15GradeControlSTGM, dataRowF15ShortTermGeology)
                        dataRowF1Factor.RecalculateDifferences(dataRowF1GradeControl, dataRowF1MiningModel)
                        dataRowF15Factor.RecalculateDifferences(dataRowF15GradeControlSTGM, dataRowF15ShortTermGeology)

                        ' Anything beyond F15 is only relevant when not reporting by resource classification
                        If String.IsNullOrEmpty(resourceClassification) Then

                            ' F2
                            rowIndexByTagDictionary.TryGetValue(f2Prefix & ModelGradeControl.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2GradeControl)
                            rowIndexByTagDictionary.TryGetValue(f2Prefix & MineProductionExpitEquivalent.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2MineProductionExpitEquivalent)
                            rowIndexByTagDictionary.TryGetValue(F2.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2Factor)

                            ' F2.5
                            rowIndexByTagDictionary.TryGetValue(f25Prefix & MiningModelOreForRailEquivalent.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF25FactorMiningModelOreForRailEquivalent)
                            rowIndexByTagDictionary.TryGetValue(f25Prefix & OreForRail.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF25OreForRail)
                            rowIndexByTagDictionary.TryGetValue(F25.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF25Factor)

                            ' F3
                            rowIndexByTagDictionary.TryGetValue(f3Prefix & PortOreShipped.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF3OreShipped)
                            rowIndexByTagDictionary.TryGetValue(F3.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF3Factor)

                            ' F3 has a special case for GEOMET - it will use the AD Adjusted version if it exists. We would actually like to use this in
                            ' general for all the Factors, but can't work out a nice way to do this
                            If productSize = "GEOMET" Then
                                rowIndexByTagDictionary.TryGetValue(f3Prefix & MiningModelShippingEquivalent.CalculationId & AD_SUFFIX & productSize & calendarDateRowKeySuffix, dataRowF3MiningModelShippingEquivalent)

                                ' we tried at first with to get the ad-adjusted version, but if that doesn't exist, then we fall back to the normal one
                                If dataRowF3MiningModelShippingEquivalent Is Nothing Then
                                    rowIndexByTagDictionary.TryGetValue(f3Prefix & MiningModelShippingEquivalent.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF3MiningModelShippingEquivalent)
                                End If
                            Else
                                rowIndexByTagDictionary.TryGetValue(f3Prefix & MiningModelShippingEquivalent.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF3MiningModelShippingEquivalent)
                            End If

                            ' RecoveryFactorDensity
                            rowIndexByTagDictionary.TryGetValue(recoveryFactorDensityPrefix & ActualMined.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFDActualMined)
                            rowIndexByTagDictionary.TryGetValue(recoveryFactorDensityPrefix & ModelMining.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFDMiningModel)
                            rowIndexByTagDictionary.TryGetValue(RecoveryFactorDensity.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFDFactor)

                            ' RecoveryFactorMoisture
                            rowIndexByTagDictionary.TryGetValue(recoveryFactorMoisturePrefix & MineProductionActuals.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFMMineProductionActuals)
                            rowIndexByTagDictionary.TryGetValue(recoveryFactorMoisturePrefix & ModelMining.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFMMiningModel)
                            rowIndexByTagDictionary.TryGetValue(RecoveryFactorMoisture.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFMFactor)

                            ' F2-Density
                            rowIndexByTagDictionary.TryGetValue(f2DensityPrefix & ActualMined.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2DensityActualMined)
                            rowIndexByTagDictionary.TryGetValue(f2DensityPrefix & ModelGradeControl.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2DensityGradeControl)
                            rowIndexByTagDictionary.TryGetValue(F2Density.CalculationId & productSize & calendarDateRowKeySuffix, dataRowF2DensityFactor)

                            'RF Factors

                            'RFGM
                            rowIndexByTagDictionary.TryGetValue(rfgmPrefix & MineProductionExpitEquivalent.CalculationId & productSize & resourceClassification, dataRowRFGMMineProductionExpitEquivalent)
                            rowIndexByTagDictionary.TryGetValue(rfmmPrefix & ModelGradeControlSTGM.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFGMGeologyModel)

                            If dataRowRFGMGeologyModel Is Nothing Then
                                rowIndexByTagDictionary.TryGetValue(ModelGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFGMGeologyModel)
                            End If

                            If dataRowRFGMMineProductionExpitEquivalent Is Nothing Then
                                dataRowRFGMMineProductionExpitEquivalent = dataRowF2MineProductionExpitEquivalent
                            End If

                            rowIndexByTagDictionary.TryGetValue(RFGM.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFGM)

                            'RFMM
                            rowIndexByTagDictionary.TryGetValue(rfmmPrefix & MineProductionExpitEquivalent.CalculationId & productSize & resourceClassification, dataRowRFMMMineProductionExpitEquivalent)
                            rowIndexByTagDictionary.TryGetValue(rfmmPrefix & ModelMining.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFMMMiningModel)

                            If dataRowRFMMMiningModel Is Nothing Then
                                rowIndexByTagDictionary.TryGetValue(f1Prefix & ModelMining.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFMMMiningModel)
                            End If

                            If dataRowRFMMMineProductionExpitEquivalent Is Nothing Then
                                dataRowRFMMMineProductionExpitEquivalent = dataRowF2MineProductionExpitEquivalent
                            End If

                            rowIndexByTagDictionary.TryGetValue(RFMM.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFMM)

                            'RFSTM
                            rowIndexByTagDictionary.TryGetValue(rfstmPrefix & MineProductionExpitEquivalent.CalculationId & productSize & resourceClassification, dataRowRFSTMMineProductionExpitEquivalent)
                            rowIndexByTagDictionary.TryGetValue(rfstmPrefix & ModelShortTermGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFSTMShortTermGeology)

                            If dataRowRFSTMShortTermGeology Is Nothing Then
                                rowIndexByTagDictionary.TryGetValue(f15Prefix & ModelShortTermGeology.CalculationId & productSize & resourceClassificationTagSuffix & calendarDateRowKeySuffix, dataRowRFSTMShortTermGeology)
                            End If

                            If dataRowRFSTMMineProductionExpitEquivalent Is Nothing Then
                                dataRowRFSTMMineProductionExpitEquivalent = dataRowF2MineProductionExpitEquivalent
                            End If

                            rowIndexByTagDictionary.TryGetValue(RFSTM.CalculationId & productSize & calendarDateRowKeySuffix, dataRowRFSTM)

                            ' now we have all the data, actually go ahead and re-calculate all the remaining factors

                            ' with F2 we want to use the F2 specific Grade control in some cases
                            If productSize = "GEOMET" AndAlso dataRowF2GradeControl IsNot Nothing Then
                                dataRowF2Factor.RecalculateRatios(dataRowF2MineProductionExpitEquivalent, dataRowF2GradeControl)
                                dataRowF2Factor.RecalculateDifferences(dataRowF2MineProductionExpitEquivalent, dataRowF2GradeControl)
                            ElseIf dataRowF1GradeControl Is Nothing AndAlso dataRowF2GradeControl IsNot Nothing Then
                                ' if the table has *only* the F2 and its sub calculations, then the recalc will fail silently, because it
                                ' will default to using the F1 GC. In this case we will use the F2. This could maybe be merged with the
                                ' GEOMET case above, but don't have the time to test this in detail
                                dataRowF2Factor.RecalculateRatios(dataRowF2MineProductionExpitEquivalent, dataRowF2GradeControl)
                                dataRowF2Factor.RecalculateDifferences(dataRowF2MineProductionExpitEquivalent, dataRowF2GradeControl)
                            Else
                                dataRowF2Factor.RecalculateRatios(dataRowF2MineProductionExpitEquivalent, dataRowF1GradeControl)
                                dataRowF2Factor.RecalculateDifferences(dataRowF2MineProductionExpitEquivalent, dataRowF1GradeControl)
                            End If

                            dataRowF25Factor.RecalculateRatios(dataRowF25OreForRail, dataRowF25FactorMiningModelOreForRailEquivalent)
                            dataRowF3Factor.RecalculateRatios(dataRowF3OreShipped, dataRowF3MiningModelShippingEquivalent)

                            dataRowRFDFactor.RecalculateRatios(dataRowRFDActualMined, dataRowRFDMiningModel)
                            dataRowRFMFactor.RecalculateRatios(dataRowRFMMineProductionActuals, dataRowRFMMiningModel)
                            dataRowF2DensityFactor.RecalculateRatios(dataRowF2DensityActualMined, dataRowF2DensityGradeControl)
                            dataRowF25Factor.RecalculateDifferences(dataRowF25OreForRail, dataRowF25FactorMiningModelOreForRailEquivalent)
                            dataRowF3Factor.RecalculateDifferences(dataRowF3OreShipped, dataRowF3MiningModelShippingEquivalent)

                            dataRowRFDFactor.RecalculateDifferences(dataRowRFDActualMined, dataRowRFDMiningModel)
                            dataRowRFMFactor.RecalculateDifferences(dataRowRFMMineProductionActuals, dataRowRFMMiningModel)
                            dataRowF2DensityFactor.RecalculateDifferences(dataRowF2DensityActualMined, dataRowF2DensityGradeControl)
                        End If

                        If Not dataRowRFGM Is Nothing Then
                            dataRowRFGM.RecalculateRatios(dataRowRFGMMineProductionExpitEquivalent, dataRowRFGMGeologyModel)
                        End If

                        If Not dataRowRFMM Is Nothing Then
                            dataRowRFMM.RecalculateRatios(dataRowRFMMMineProductionExpitEquivalent, dataRowF1MiningModel)
                        End If

                        If Not dataRowRFSTM Is Nothing Then
                            dataRowRFSTM.RecalculateRatios(dataRowRFSTMMineProductionExpitEquivalent, dataRowRFSTMShortTermGeology)
                        End If
                    Next
                Next
            Next

            FixF2Density(resultTable)
            FixRecoveryFactors(resultTable)

            Return resultTable
        End Function

        ' Returns a list of the factors in the system, along with the components used to recalculate them
        Public Shared Function GetFactorComponentList(useCalculationPrefixes As Boolean) As Dictionary(Of String, String())
            Dim factorList As New Dictionary(Of String, String())

            If useCalculationPrefixes Then
                factorList.Add("F1Factor", New String() {"F1GradeControlModel", "F1MiningModel"})
                factorList.Add("F15Factor", New String() {"F15GradeControlSTGM", "F15ShortTermGeologyModel"})
                factorList.Add("F2Factor", New String() {"F2MineProductionExpitEqulivent", "F1GradeControlModel"}) ' NOTE: uses the *F1* GC not F2 when prefixed
                factorList.Add("F25Factor", New String() {"F25OreForRail", "F25MiningModelOreForRailEquivalent"})
                factorList.Add("F3Factor", New String() {"F3OreShipped", "F3MiningModelShippingEquivalent"})

                factorList.Add("F2DensityFactor", New String() {"F2DensityActualMined", "F2DensityGradeControlModel"})
                factorList.Add("RecoveryFactorDensity", New String() {"RFDActualMined", "RFDMiningModel"})
                factorList.Add("RecoveryFactorMoisture", New String() {"RFMMineProductionActuals", "RFMMiningModel"})

                factorList.Add(RFGM.CalculationId, New String() {RFGM.CalculationId + MineProductionExpitEquivalent.CalculationId, RFGM.CalculationId + ModelGeology.CalculationId})
                factorList.Add(RFMM.CalculationId, New String() {RFMM.CalculationId + MineProductionExpitEquivalent.CalculationId, RFMM.CalculationId + ModelMining.CalculationId})
                factorList.Add(RFSTM.CalculationId, New String() {RFSTM.CalculationId + MineProductionExpitEquivalent.CalculationId, RFSTM.CalculationId + ModelShortTermGeology.CalculationId})
            Else
                factorList.Add("F1Factor", New String() {"GradeControlModel", "MiningModel"})
                factorList.Add("F15Factor", New String() {"GradeControlSTGM", "ShortTermGeologyModel"})
                factorList.Add("F2Factor", New String() {"MineProductionExpitEqulivent", "GradeControlModel"})
                factorList.Add("F25Factor", New String() {"OreForRail", "MiningModelOreForRailEquivalent"})
                factorList.Add("F3Factor", New String() {"OreShipped", "MiningModelShippingEquivalent"})

                ' NOTE: these factors normally need the prefix no matter what (on the denominator), since they are different to the standard use of
                ' those calculation. It will try the prefixed version first, and then the unprefixed as a backup
                factorList.Add("F2DensityFactor", New String() {"ActualMined", "F2DensityGradeControlModel", "GradeControlModel"})
                factorList.Add("RecoveryFactorDensity", New String() {"ActualMined", "RFDMiningModel", "MiningModel"})
                factorList.Add("RecoveryFactorMoisture", New String() {"MineProductionActuals", "RFMMiningModel", "MiningModel"})

                factorList.Add(RFGM.CalculationId, New String() {MineProductionExpitEquivalent.CalculationId, ModelGeology.CalculationId})
                factorList.Add(RFMM.CalculationId, New String() {MineProductionExpitEquivalent.CalculationId, ModelMining.CalculationId})
                factorList.Add(RFSTM.CalculationId, New String() {MineProductionExpitEquivalent.CalculationId, ModelShortTermGeology.CalculationId})
            End If

            ' add specical case factor items to be excluded.. returning an empty set indicates no processing should occur
            factorList.Add("F3BeneRatio", New String() {})

            Return factorList
        End Function

        ' NOTE: You should use this as the standard method for recalculating factors after an aggregation or other change
        '
        ' It calls the existing calculation method, but does some checks before to make sure that certain cases are
        ' handled correctly.
        '
        Public Shared Function RecalculateF1F2F3Factors(table As DataTable) As DataTable
            Dim timePeriodCount = table.AsEnumerable.Select(Function(r) r.AsDate("DateFrom")).Distinct.Count()
            Dim locationCount = table.AsEnumerable.Select(Function(r) r.AsInt("LocationId")).Distinct.Count()
            Dim groupOnCalendarDate = timePeriodCount > 1
            Dim mulitpleLocations = locationCount > 1

            ' if we don't have anything in the table, or every single row has zero tonnes, then there is no
            ' point to recalculate anything, so we just return the table as is. The other recalculation methods
            ' will throw an exception if they are called with such a table, so this needs to be done
            If table.Rows.Count = 0 OrElse table.AsEnumerable.Sum(Function(r) r.AsDblN("Tonnes")) = 0 Then
                Return table
            End If

            If mulitpleLocations Then
                ' if there are multiple locations in the table, we need to recalculate the factors for them
                ' one by one, as the existing recalc method doesn't handle this
                Dim locationList = table.AsEnumerable.Select(Function(r) r.AsInt("LocationId")).Distinct
                For Each locationId In locationList
                    CalculateF1F2F3Factors(table, groupOnCalendarDate, locationId:=locationId)
                Next
            Else
                ' if there is only a single location we can calculate things in the usual way
                CalculateF1F2F3Factors(table, groupOnCalendarDate)
            End If

            Return table
        End Function

        ' This function recalculates the factors after aggregation in the reporting layer. The method CalculateF1F2F3Factors also does this, but it
        ' does it for a pivoted table, where all the grades are in a single row. This method recalculates the values properly for an unpivoted
        ' DataTable
        '
        ' WARNING: This method seems to have serious performance problems when run with large data sets, if possible use the pivoted version
        ' of the this method, and unpivot the data afterwards with `F1F2F3ReportEngine.UnpivotDataTable`
        '
        Public Shared Function RecalculateF1F2F3FactorsForUnpivotedTable(resultTable As DataTable, 
                                                                         Optional ByVal useCalculationPrefixes As Boolean = True) _
                                                                         As DataTable

            If Not resultTable.Columns.Contains("AttributeValue") Then
                Throw New ArgumentException("resultTable is not a valid F1F2F3 unpivoted report result table")
            End If

            Dim factorList = GetFactorComponentList(useCalculationPrefixes)

            For Each row As DataRow In resultTable.Rows
                If Not row.IsFactorRow() Then Continue For ' only care about the factors

                Dim factorId = row("ReportTagId").ToString
                Dim factorComponents As String() = Nothing
                factorList.TryGetValue(factorId, factorComponents)

                If factorComponents Is Nothing OrElse factorComponents.Length > 0 AndAlso factorComponents.Length < 2 Then
                    ' we don't have a record in the FactorList for this factor. Maybe it is a new one?
                    Throw New Exception("Could not recalculate factor: Found unknown Factor type " + factorId)
                End If

                If factorComponents.Length > 0 Then
                    ' an empty components list is an indication to skip processing

                    Dim topRow = resultTable.AsEnumerable.GetCorrespondingRowUnpivoted(row, factorComponents(0))
                    Dim bottomRow = resultTable.AsEnumerable.GetCorrespondingRowUnpivoted(row, factorComponents(1))

                    If bottomRow Is Nothing AndAlso factorComponents.Length = 3 Then
                        ' we have a secondary reportTagId to check for the denominator, so lets do that
                        bottomRow = resultTable.AsEnumerable.GetCorrespondingRowUnpivoted(row, factorComponents(2))
                    End If

                    row.RecalculateAttributeRatioUnpivoted(topRow, bottomRow)

                    If topRow IsNot Nothing AndAlso bottomRow IsNot Nothing Then
                        Dim attributeName = topRow.AsString("Attribute")
                        Dim attributeDifference = topRow.AsDblN("AttributeValue") - bottomRow.AsDblN("AttributeValue")
                        Dim attributeSet = resultTable.AsEnumerable.GetCorrespondingRowsUnpivoted(row)

                        For Each attributeRow In attributeSet
                            If resultTable.Columns.Contains(attributeName + "Difference") Then
                                If attributeDifference IsNot Nothing Then
                                    attributeRow(attributeName + "Difference") = attributeDifference
                                Else
                                    attributeRow(attributeName + "Difference") = DBNull.Value
                                End If

                            End If
                        Next
                    End If
                End If
            Next

            Return resultTable
        End Function

        Private Shared Function GetF1F2F3ReportData(session As ReportSession, locationId As Int32, 
                                                    dateFrom As DateTime, dateTo As DateTime, 
                                                    Optional ByVal willAggregate As Boolean = True) As DataTable

            Dim holdingDataTable = GetHubReportSet(session, locationId, dateFrom, dateTo).ToDataTable(session)

            holdingDataTable.Columns.Add("ModelTagExtended", GetType(String))

            For Each row As DataRow In holdingDataTable.Rows()
                ' Determine the TagId (stripped of ProductSize differentiator)
                Dim tagIdForComparison = DirectCast(row("ReportTagId"), String)

                Dim productSizeForRow = String.Empty
                Dim productSizeObject = row(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE)

                If Not productSizeObject Is Nothing AndAlso Not productSizeObject Is DBNull.Value Then
                    productSizeForRow = productSizeObject.ToString
                End If

                If tagIdForComparison.EndsWith(productSizeForRow, StringComparison.Ordinal) AndAlso Not productSizeForRow Is Nothing AndAlso productSizeForRow.Length > 0 Then
                    ' Strip the product size from the tag if needed
                    tagIdForComparison = tagIdForComparison.Substring(0, tagIdForComparison.Length - productSizeForRow.Length)
                End If

                ' Ensure the main factor values have an extended tag used to control colors
                Select Case tagIdForComparison
                    'only want these main factors to have colors
                    Case "F1Factor" : row("ModelTagExtended") = "F1Factor"
                    Case "F15Factor" : row("ModelTagExtended") = "F15Factor"
                    Case "F2Factor" : row("ModelTagExtended") = "F2Factor"
                    Case "F25Factor" : row("ModelTagExtended") = "F25Factor"
                    Case "F3Factor" : row("ModelTagExtended") = "F3Factor"
                    Case "RFGM" : row("ModelTagExtended") = "RFGM"
                    Case "RFMM" : row("ModelTagExtended") = "RFMM"
                    Case "RFSTM" : row("ModelTagExtended") = "RFSTM"
                    Case Else : row("ModelTagExtended") = DBNull.Value
                End Select
            Next

            ReportColour.AddPresentationColour(session, holdingDataTable, "ModelTagExtended")

            holdingDataTable.Columns.Remove("ModelTagExtended")
            MakeTheZeroRecordsNull(holdingDataTable)

            'Aggregate results from multiple time periods into one..
            If willAggregate And Not session.IncludeResourceClassification Then
                holdingDataTable = Aggregate(holdingDataTable, session.GetSystemStartDate())
            End If

            ' after the aggregation... invert the density for display
            InvertDensityForDisplay(holdingDataTable, "Density", False)

            If session.IncludeAsShippedModelsInHubSet Then
                Dim totalRows = holdingDataTable.AsEnumerable.WithProductSize("TOTAL").ToList()
                totalRows.Where(Function(r) r.AsString("ReportTagId").EndsWith("_AS", StringComparison.Ordinal)).DeleteRows()
                totalRows.Where(Function(r) r.AsString("ReportTagId").EndsWith("_AD", StringComparison.Ordinal)).DeleteRows()
                holdingDataTable.AsEnumerable.Where(Function(r) r.AsString("ReportTagId").StartsWith("F15", StringComparison.Ordinal)).SetFieldIfNull("RootCalcId", "F15Factor")
            End If

            ' LUMP UF shuld display as zero, not null, unlike some of the other data
            holdingDataTable.AsEnumerable.WithProductSize("LUMP").SetFieldIfNull("Ultrafines", 0.0)

            Return holdingDataTable
        End Function

        ' now we have to do some special stuff for F2. The density for F2 comes from a separate calculation called F2Density. F2-Density should
        ' aggregate properly etc, and now at the end of the this function all the aggregation should be complete, so that we can copy the the volume
        ' and density values into their new homes in F2, and make the F2Density rows to not be displayed
        '
        ' This now also fixes the RF densities
        Public Shared Sub FixF2Density(ByRef table As DataTable)
            Dim isPivotedTable = Not table.Columns.Contains("AttributeValue")
            Dim attributesToCopy = New String() {"Density", "Volume"}

            For Each row In table.AsEnumerable.Where(Function(r) r("ReportTagId").ToString.StartsWith("F2Density", StringComparison.Ordinal)).ToList()
                Dim tagId As String
                Select Case row("TagId").ToString()
                    Case "F2DensityActualMined" : tagId = "F2MineProductionExpitEqulivent"
                    Case "F2DensityFactor" : tagId = "F2Factor"
                    Case Else : tagId = Nothing
                End Select

                If tagId IsNot Nothing Then
                    If isPivotedTable Then
                        ' now we copy the density across
                        Dim matchedRow = table.AsEnumerable.GetCorrespondingRow(tagId, row)
                        If Not matchedRow Is Nothing Then
                            For Each grade In attributesToCopy
                                matchedRow(grade) = row(grade)
                            Next
                        End If

                    ElseIf Not isPivotedTable AndAlso attributesToCopy.Contains(row("Attribute").ToString) Then
                        Dim matchedRow = table.AsEnumerable.GetCorrespondingRowUnpivoted(row, tagId)
                        If Not matchedRow Is Nothing Then
                            matchedRow("AttributeValue") = row("AttributeValue")
                        End If
                    End If
                End If
            Next
        End Sub

        Public Shared Sub FixRecoveryFactors(table As DataTable)
            ' the recovery factors have no density, but it can keep getting recalced by the factor recalc method, so we null it out
            ' again here. Do volume as well just in case, although this doesn't seem to get recalced in practise.
            Dim unneededAttributes = New String() {"Density", "Volume", "H2O", "Ultrafines"}
            Dim recoveryFactors = New String() {RFMM.CalculationId, RFGM.CalculationId, RFSTM.CalculationId}
            Dim recoveryFactorsRows = table.AsEnumerable.Where(Function(r) recoveryFactors.Contains(r.AsString("CalcId"))).ToList

            If table.IsUnpivotedTable Then
                recoveryFactorsRows.Where(Function(r) unneededAttributes.Contains(r.AsString("Attribute"))).SetField("AttributeValue", Nothing)
            Else
                For Each attr In unneededAttributes
                    recoveryFactorsRows.AsEnumerable.SetField(attr, Nothing)
                Next
            End If
        End Sub

        ''' <summary>
        ''' Invert the Density column (switching between m3/t and t/m3)
        ''' </summary>
        ''' <param name="table">the table for which the density column should be inverted</param>
        ''' <param name="densityValueColumnName">The name of the density value column</param>
        ''' <param name="checkAttributeNameColumn">flag used to check whether the attribute column name should be referred to
        ''' </param>
        ''' <remarks>NOTE: Intuitively it would seem that density valuees on factor rows should not be inverted (because factors are already a ratio, however on further analysis
        ''' they also require inversion... In m3/t form, higher numbers are less dense...but in t/m3 form higher numbers are proportionally more dense...
        ''' for this reason any factor ratios already calculated also need to be inverted (values > 1 will become &lt; 1 and vice-versa</remarks>
        Public Shared Sub InvertDensityForDisplay(ByRef table As DataTable, densityValueColumnName As String, checkAttributeNameColumn As Boolean)
            If table.Columns.Contains(densityValueColumnName) Then
                For Each row As DataRow In table.Rows
                    Dim density As Single

                    ' If we are processing all rows, or this is the density attribute row
                    If Not checkAttributeNameColumn OrElse 
                        Not row("Attribute") Is DBNull.Value AndAlso 
                        Not row("Attribute") Is Nothing AndAlso
                        row("Attribute").ToString() = "Density" AndAlso
                        Not row(densityValueColumnName) Is DBNull.Value AndAlso
                        Not row(densityValueColumnName) Is Nothing Then

                        density = CType(row(densityValueColumnName), Single)
                        If Math.Abs(density - 0) > Double.Epsilon Then
                            ' invert the value
                            row(densityValueColumnName) = 1/density
                        End If
                    End If
                Next
            End If
        End Sub

        Private Shared Function GetFactorsForReportData(holdingDataTable As DataTable) As DataTable
            Dim reportDataTable As DataTable
            reportDataTable = CalculateF1F2F3Factors(holdingDataTable)

            ' Remove all rows except for the main factors
            For i = reportDataTable.Rows.Count - 1 To 0 Step -1
                ' Determine the tag Id for each row (and remove the product size suffix if there is one)
                Dim tagId = reportDataTable.Rows(i)("ReportTagId").ToString
                Dim productSizeValue = reportDataTable.Rows(i)(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE)
                Dim productSize = String.Empty

                If Not productSizeValue Is Nothing AndAlso Not productSizeValue Is DBNull.Value Then
                    productSize = productSizeValue.ToString
                End If

                If tagId.EndsWith(productSize, StringComparison.Ordinal) AndAlso productSize.Length > 0 Then
                    tagId = tagId.Substring(0, tagId.Length - productSize.Length)
                End If

                Dim remove As Boolean

                Select Case tagId
                    Case "F1Factor" : remove = False
                    Case "F15Factor" : remove = False
                    Case "F2Factor" : remove = False
                    Case "F25Factor" : remove = False
                    Case "F3Factor" : remove = False
                    Case Else : remove = True
                End Select

                If remove Then
                    reportDataTable.Rows.RemoveAt(i)
                End If
            Next

            Return reportDataTable
        End Function

        ' this method id only for the unpivoted tables. It is very useful to have the tonnes in each row
        ' to make it possible to calculate  metal units etc
        Public Shared Sub AddTonnesValuesToUnpivotedTable(ByRef table As DataTable)
            If Not table.IsUnpivotedTable Then
                Throw New Exception("This method is only valid on unpivoted tables")
            End If

            If Not table.Columns.Contains("Tonnes") Then
                table.Columns.Add("Tonnes", GetType(Double))
            End If

            For Each row As DataRow In table.Rows
                Dim rowSet = table.AsEnumerable.GetCorrespondingRowsUnpivoted(row)
                Dim tonnesRow = rowSet.FirstOrDefault(Function(r) r.AsString("Attribute") = "Tonnes")

                If tonnesRow IsNot Nothing Then
                    Dim tonnes = tonnesRow.AsDblN("AttributeValue")
                    If tonnes.HasValue Then
                        row("Tonnes") = tonnes
                    End If
                End If
            Next
        End Sub

        Public Shared Function AddOrderNoColumn(ByRef table As DataTable) As DataTable
            If Not table.Columns.Contains("Order_No") Then
                table.Columns.Add("Order_No", GetType(Integer))
            End If

            Dim rowNumber = 0
            For Each row As DataRow In table.Rows
                row("Order_No") = rowNumber
                rowNumber += 1
            Next

            table.DefaultView.Sort = "Order_No"

            Return table
        End Function

        Public Shared Function AddAttributeIds(ByRef table As DataTable) As DataTable
            If Not table.Columns.Contains("AttributeId") Then
                table.Columns.Add("AttributeId", GetType(Integer))
            End If

            For Each row As DataRow In table.Rows
                row("AttributeId") = GetAttributeId(row.AsString("Attribute"))
            Next

            Return table
        End Function

        Public Shared Function AddAttributeValueFormat(table As DataTable) As DataTable
            If Not table.Columns.Contains("AttributeValueFormat") Then
                table.Columns.Add("AttributeValueFormat", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                Dim attributeName = row.AsString("Attribute")
                row("AttributeValueFormat") = GetAttributeValueFormat(attributeName, row.IsFactorRow)
            Next

            Return table
        End Function

        Public Shared Function GetAttributeValueFormat(attributeName As String, calcId As String) As String
            Dim isFactor = calcId.EndsWith("Factor", StringComparison.Ordinal) OrElse Calculation.RecoveryFactors.Contains(calcId)
            Return GetAttributeValueFormat(attributeName, isFactor)
        End Function

        Public Shared Function GetAttributeValueFormat(attributeName As String, isFactor As Boolean) As String
            Dim stringFormat As String

            If isFactor Then
                ' for factor rows the formats have to be hardcoded, as there is nothing in the DB for factor
                ' specific ones
                Select Case attributeName.ToUpper
                    Case "FE" : stringFormat = "N3"
                    Case Else : stringFormat = "N2"
                End Select
            Else
                ' TODO: this should use the precision attributes from the database, but just hard code them for now
                Select Case attributeName.ToUpper
                    Case "TONNES" : stringFormat = "N1"
                    Case "P" : stringFormat = "N3"
                    Case Else : stringFormat = "N2"
                End Select
            End If

            Return stringFormat
        End Function

        Public Shared Function GetAttributeId(attributeName As String) As Integer
            If attributeName Is Nothing Then
                Throw New ArgumentNullException("attributeName")
            End If

            Dim attributeId As Integer

            Select Case attributeName.ToUpper
                Case "UNDERSIZE" : attributeId = -2
                    ' due to an oversite we do in fact have TWO attributes with the same attribute_id
                    ' so far they are used in different contexts so it hasn't been a problem, but this
                    ' will have to be changed eventually
                Case "VOLUME", "OVERSIZE" : attributeId = -1
                Case "TONNES" : attributeId = 0
                Case "FE" : attributeId = 1
                Case "P" : attributeId = 2
                Case "SIO2" : attributeId = 3
                Case "AL2O3" : attributeId = 4
                Case "LOI" : attributeId = 5
                Case "DENSITY" : attributeId = 6
                Case "H2O" : attributeId = 7
                Case "H2O-AS-DROPPED" : attributeId = 8
                Case "H2O-AS-SHIPPED" : attributeId = 9
                Case Else : attributeId = 99
            End Select

            Return attributeId
        End Function

        Public Shared Function AddThresholdValues(session As ReportSession, ByRef table As DataTable, Optional ByVal locationId As Integer = 1) As DataTable
            If Not table.Columns.Contains("AttributeValue") Then
                Throw New Exception("AddThresholdValues can only be used on a pivoted factor table")
            End If

            Dim thresholds = GradeProperties.GetFAttributeProperties(session, locationId)

            If Not table.Columns.Contains("FactorThresholdValue") Then
                table.Columns.Add("FactorThresholdValue", GetType(String))
            End If

            If Not table.Columns.Contains("FactorThresholdImage") Then
                table.Columns.Add("FactorThresholdImage", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                If Not row.IsFactorRow Then
                    row("FactorThresholdValue") = "NONE"
                    Continue For
                End If

                Dim thresholdValue = GetThresholdValue(row, thresholds)

                If thresholdValue Is Nothing Then
                    row("FactorThresholdValue") = "NONE"
                Else
                    row("FactorThresholdValue") = thresholdValue
                End If
            Next

            For Each row As DataRow In table.Rows
                Dim threshold = row.AsString("FactorThresholdValue").ToUpper()

                If row.AsDblN("AttributeValue") = 0.0 Then
                    threshold = "ZERO"
                End If

                Select Case threshold
                    Case "LOW"
                        row("FactorThresholdImage") = "facegreen.gif"
                    Case "MEDIUM"
                        row("FactorThresholdImage") = "faceorange.gif"
                    Case "HIGH"
                        row("FactorThresholdImage") = "facered.gif"
                    Case Else
                        row("FactorThresholdImage") = "faceDisabled.gif"
                End Select
            Next

            Return table
        End Function

        Public Shared Function GetThresholdValue(row As DataRow, thresholds As DataTable) As String
            If row Is Nothing Then
                Throw New ArgumentNullException("row")
            End If

            If Not row.Table.Columns.Contains("AttributeValue") Then
                Throw New Exception("AddThresholdValues can only be used on a pivoted factor table")
            End If

            Return GetThresholdValue(row, thresholds, row.AsString("Attribute"))
        End Function

        Public Shared Function GetThresholdValue(row As DataRow, thresholds As DataTable, attributeName As String) As String
            If row Is Nothing Then
                Throw New ArgumentNullException("row")
            End If

            Dim attributeValueField = "AttributeValue"

            ' if this is a pivoted table, then the field with the value in it is the same as the attributeName
            If Not row.Table.IsUnpivotedTable Then
                attributeValueField = attributeName
            End If

            If Not row.HasValue(attributeValueField) Then
                Return Nothing
            End If

            Dim table = row.Table
            Dim attributeValue = row.AsDbl(attributeValueField)

            Dim threshold = thresholds.
                    AsEnumerable.
                    FirstOrDefault(Function(r) r.AsString("ThresholdTypeId") = row.AsString("ReportTagId") AndAlso
                                               r.AsString("FieldName") = attributeName)

            If threshold Is Nothing Then
                Return Nothing
            End If

            If threshold.AsBool("AbsoluteThreshold") Then
                If Not table.Columns.Contains(attributeName + "Difference") Then
                    Throw New Exception("Factor Table must contain Difference columns in order to handle absolute thresholds")
                End If

                If row.AsDblN(attributeName + "Difference") Is Nothing Then
                    Return Nothing
                End If

                Dim attributeDifference = row.AsDbl(attributeName + "Difference")

                If Math.Abs(attributeDifference) > threshold.AsDbl("HighThreshold") Then
                    Return "High"
                ElseIf Math.Abs(attributeDifference) > threshold.AsDbl("LowThreshold") Then
                    Return "Medium"
                Else
                    Return "Low"
                End If

            Else
                If Math.Abs(attributeValue - 1) * 100 > threshold.AsDbl("HighThreshold") Then
                    Return "High"
                ElseIf Math.Abs(attributeValue - 1) * 100 > threshold.AsDbl("LowThreshold") Then
                    Return "Medium"
                Else
                    Return "Low"
                End If
            End If
        End Function

        Public Shared Function AddLocationDataToTable(ByRef session As ReportSession, ByRef table As DataTable, parentLocationId As Integer) As DataTable
            Dim locations = GetAllLocationNames(session, parentLocationId).Values.ToList
            Dim parentLocation = locations.First
            Dim parentLocationType = parentLocation.LocationType.ToUpper
            Dim locationPrefix = ""

            If parentLocationType = "BENCH" Then
                ' when getting the locations for lower down the heirachy, we need to update the name to add the pit
                ' and bench name
                Dim locationParents = session.DalUtility.GetLocationParentHeirarchy(parentLocationId)
                Dim pitLocation = locationParents.AsEnumerable.FirstOrDefault(Function(r) r.AsString("Location_Type_Description").ToUpper = "PIT")

                If pitLocation IsNot Nothing Then
                    locationPrefix = $"{pitLocation.AsString("Name")}-{parentLocation.LocationName}-"
                End If
            ElseIf parentLocationType = "PIT" Then
                ' if the parent location is a pit, then the children must be benches. In this case we have
                ' to prefix the names with the pit names, because the bench names aren't unique
                locationPrefix = parentLocation.LocationName + "-"
            End If

            If Not table.Columns.Contains("LocationName") Then
                table.Columns.Add("LocationName", GetType(String))
            End If

            If Not table.Columns.Contains("LocationType") Then
                table.Columns.Add("LocationType", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                If Not row.HasValue("LocationId") Then Continue For
                Dim locationId = row.AsInt("LocationId")
                Dim location = locations.FirstOrDefault(Function(r) r.LocationId = locationId)

                If location IsNot Nothing AndAlso location.LocationId <> parentLocation.LocationId Then
                    row("LocationName") = locationPrefix + location.LocationName
                    row("LocationType") = location.LocationType
                ElseIf location IsNot Nothing Then
                    row("LocationName") = location.LocationName
                    row("LocationType") = location.LocationType
                Else
                    row("LocationName") = "Unknown"
                    row("LocationType") = "Unknown"
                End If
            Next

            Return table
        End Function

        Public Shared Function AddTagOrderNo(ByRef table As DataTable) As DataTable
            If Not table.Columns.Contains("Tag_Order_No") Then
                table.Columns.Add("Tag_Order_No", GetType(Integer))
            End If

            For Each row As DataRow In table.Rows
                row("Tag_Order_No") = GetTagOrderNo(row)
            Next

            Return table
        End Function

        ' get an order based off the tagId / reportTagId. This is for sorting the calculations within their grouping
        ' unlike the order_no column, it is not unique to the table
        Public Shared Function GetTagOrderNo(row As DataRow) As Integer
            Return GetTagOrderNo(row.AsString("CalcId"), row.AsString("TagId"))
        End Function

        Public Shared Function GetTagOrderNo(calcId As String, Optional tagId As String = "") As Integer
            Dim orderNo = 0

            Select Case calcId
                Case "GeologyModel" : orderNo = 10
                Case "ShortTermGeologyModel" : orderNo = 20
                Case "MiningModel" : orderNo = 30
                Case "GradeControlModel" : orderNo = 40
                Case "GradeControlSTGM" : orderNo = 50

                Case "MineProductionActuals" : orderNo = 60
                Case "ExPitToOreStockpile" : orderNo = 70
                Case "StockpileToCrusher" : orderNo = 80
                Case "MineProductionExpitEqulivent" : orderNo = 90

                Case "OreForRail" : orderNo = 100
                Case "MiningModelOreForRailEquivalent" : orderNo = 110
                Case "MiningModelCrusherEquivalent" : orderNo = 120

                Case "SitePostCrusherStockpileDelta" : orderNo = 130
                Case "HubPostCrusherStockpileDelta" : orderNo = 140
                Case "PostCrusherStockpileDelta" : orderNo = 150

                Case "ActualMined" : orderNo = 160
                Case "MiningModelShippingEquivalent" : orderNo = 170
                Case "PortStockpileDelta" : orderNo = 180
                Case "PortBlendedAdjustment" : orderNo = 190

                Case "OreShipped" : orderNo = 200

                Case "F1Factor" : orderNo = 300
                Case "F15Factor" : orderNo = 310
                Case "RFGM" : orderNo = 312
                Case "RFMM" : orderNo = 313
                Case "RFSTM" : orderNo = 314
                Case "F2Factor" : orderNo = 320
                Case "F2DensityFactor" : orderNo = 321
                Case "F25Factor" : orderNo = 330
                Case "F3Factor" : orderNo = 340
            End Select

            If calcId = "MiningModel" And tagId.StartsWith("F3MiningModel", StringComparison.Ordinal) Then
                orderNo += 1
            End If

            Return orderNo
        End Function

        ''' <summary>
        ''' Adds the LocationName column and LocationType column to the report data table and populates the LocationName,
        ''' LocationType and LocationId columns used by the report with the relevant location information.
        ''' </summary>
        ''' <param name="location"></param>
        ''' <param name="reportDataTable"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Shared Function AddLocationDataToTable(location As Types.Location, reportDataTable As DataTable) As DataTable
            reportDataTable.Columns.Add(New DataColumn("LocationName"))
            reportDataTable.Columns.Add(New DataColumn("LocationType"))

            For i = 0 To reportDataTable.Rows.Count - 1
                reportDataTable.Rows(i)("LocationName") = location.LocationName
                reportDataTable.Rows(i)("LocationType") = location.LocationType
                reportDataTable.Rows(i)("LocationId") = location.LocationId

                ' sometimes we are dealing with an extended location that also contains the sitename and hub name of the
                ' location (to make it easier to generate reports). In this case we want to extract this data from the location
                ' object and make sure it gets added to the result table
                Dim extendedLocation = TryCast(location, ExtendedLocation)
                If extendedLocation IsNot Nothing Then
                    ' add the columns if they dont exist. This should happen only once...
                    If Not reportDataTable.Columns.Contains("SiteName") Then
                        reportDataTable.Columns.Add(New DataColumn("SiteName", GetType(String)))
                        reportDataTable.Columns.Add(New DataColumn("HubName", GetType(String)))
                    End If

                    reportDataTable.Rows(i)("SiteName") = extendedLocation.SiteName
                    reportDataTable.Rows(i)("HubName") = extendedLocation.HubName
                End If
            Next i

            Return reportDataTable
        End Function

        Public Shared Function FilterTableByFactors(ByRef table As DataTable, calcIdList As String()) As DataTable
            Dim rows = table.AsEnumerable.Where(Function(r) Not calcIdList.Contains(r.AsString("CalcId"))).ToList
            table.DeleteRows(rows.AsEnumerable)
            Return table
        End Function

        Public Shared Function FilterTableByCalcId(ByRef table As DataTable, calcId As String) As DataTable
            Dim rows = table.AsEnumerable.Where(Function(r) r.AsString("CalcId") <> calcId).ToList
            table.DeleteRows(rows.AsEnumerable)
            Return table
        End Function

        Public Shared Function FilterTableByAttributeList(ByRef table As DataTable, attributes As String()) As DataTable
            Dim rows = table.AsEnumerable.Where(Function(r) Not attributes.Contains(r.AsString("Attribute")))
            table.DeleteRows(rows.AsEnumerable)
            Return table
        End Function

        ''' <summary>
        ''' Retrieves a dictionary of all the location ids, location definitons of the supplied parent id and ALL it's children.
        ''' all the way down to the set level
        '''
        ''' A DateTime is required due to the dynamic nature of the location hierarchy
        ''' </summary>
        Public Shared Function GetAllLocationNamesRecursive(session As ReportSession, parentLocation As Int32, dateTime As Date, 
                                                            Optional lowestLocationType As String = "Pit") _
                                                            As Dictionary(Of Int32, ExtendedLocation)

            Dim locationNames As New Dictionary(Of Int32, ExtendedLocation)
            Dim locationTable As DataTable

            ' Get child locations
            locationTable = session.DalReport.GetBhpbioReportLocationBreakdownWithNames(parentLocation, False, lowestLocationType, dateTime)

            For Each row As DataRow In locationTable.Rows
                Dim l As New ExtendedLocation() With {
                        .LocationId = Convert.ToInt32(row("Location_Id")),
                        .LocationName = row("Name").ToString(),
                        .LocationType = row("Location_Type_Description").ToString(),
                        .SiteName = row("SiteName").ToString(),
                        .HubName = row("HubName").ToString()
                        }

                locationNames.Add(Convert.ToInt32(row("Location_Id")), l)
            Next

            Return locationNames
        End Function

        ''' <summary>
        ''' Retrieves a dictionary of all the location ids, location definitons of the supplied parent id and ALL it's children.
        ''' </summary>
        Public Shared Function GetAllLocationNames(session As ReportSession, 
                                                   parentLocation As Int32) As Dictionary(Of Int32, Types.Location)

            Dim locationDate = Date.Now

            If session.RequestParameter IsNot Nothing Then
                locationDate = session.RequestParameter.StartDate
            End If

            ' Get parent location
            Dim locationNames = GetParentLocationName(session, parentLocation)

            ' Get child locations
            Dim locationTable = session.DalUtility.GetBhpbioLocationListWithOverride(parentLocation, 1, locationDate)

            For Each row As DataRow In locationTable.Rows
                locationNames.Add(row.AsInt("Location_Id"), New Types.Location(row.AsInt("Location_Id"), row.AsString("Name"), row.AsString("Location_Type_Description")))
            Next

            Return locationNames
        End Function

        Private Shared Function GetParentLocationNameWithOverride(session As ReportSession, parentLocationId As Int32, 
                                                                  startDate As Date, endDate As Date) _
                                                                  As Dictionary(Of Int32, Types.Location)

            Dim locationTable As DataTable

            locationTable = session.DalUtility.GetBhpbioLocationNameWithOverride(parentLocationId, startDate, endDate)

            Return _
                locationTable.Rows.Cast(Of DataRow)().ToDictionary(Function(row) Convert.ToInt32(row("Location_Id")),
                                                                   Function(row) _
                                                                      New Types.Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString,
                                                                                         row("Location_Type_Description").ToString()))
        End Function

        Private Shared Function GetParentLocationName(session As ReportSession, 
                                                      parentLocationId As Int32) As Dictionary(Of Int32, Types.Location)
            Dim locationTable As DataTable

            locationTable = session.DalUtility.GetLocationList(DoNotSetValues.Int16,
                                                               DoNotSetValues.Int32, parentLocationId, DoNotSetValues.Int16)

            Return _
                locationTable.Rows.Cast(Of DataRow)().ToDictionary(Function(row) Convert.ToInt32(row("Location_Id")),
                                                                   Function(row) _
                                                                      New Types.Location(Convert.ToInt32(row("Location_Id")), row("Name").ToString,
                                                                                         row("Location_Type_Description").ToString()))
        End Function

#End Region

        Public Shared Function GetFactorsExtendedForLocation(session As ReportSession, locationId As Int32,
                                                             dateFrom As DateTime, dateTo As DateTime) As DataTable
            If locationId = 0 Then
                locationId = session.DalUtility.GetBhpbioLocationRoot()
            End If

            Dim locations As Dictionary(Of Int32, Types.Location)
            locations = GetParentLocationNameWithOverride(session, locationId, dateFrom, dateTo)

            Return GetFactorsExtendedForLocations(session, dateFrom, dateTo, locations)
        End Function

        ' despite the confusing name, this method is only called by the data export report at the moment
        ' It gets the required parameters and calls 'GetFactorsExtendedForLocations'. GetFactorsExtendedForLocations on
        ' the other hand, is actually called by other reports, so be careful when changing it.
        Public Shared Function GetFactorsExtendedForAllChildLocations(session As ReportSession, locationId As Int32,
                                                                      dateFrom As DateTime, dateTo As DateTime, dateBreakdown As ReportBreakdown,
                                                                      includeSublocations As Boolean) As DataTable
            If locationId = 0 Then
                locationId = session.DalUtility.GetBhpbioLocationRoot()
            End If

            session.DateBreakdown = dateBreakdown

            Dim locations As New Dictionary(Of Int32, Types.Location)
            Dim extendedLocations = GetAllLocationNamesRecursive(session, locationId, dateFrom)

            ' cast the locations to the basic type, so they can be fed into the factors method
            ' maybe the get location names method should return them in this format in the first place?
            ' and we can just cst them up if needed?
            If includeSublocations Then
                For Each l In extendedLocations
                    locations.Add(l.Key, CType(l.Value, Types.Location))
                Next
            Else
                ' dont want any sublocations, so just take the first item of the extended location array
                ' this results in some wasted effort because we end up getting all the sublocations to only
                ' use the first one, but we have to do it this way, because the GetAllLocationNamesRecursive
                ' method is the only one that returns the Site + Hub for the locations

                'If clause added to handle the Annual Report specific for Jimblebar. Depending on the selected date range it returns
                'null causing the function to crash
                If extendedLocations.Count = 0 Then
                    Return Nothing
                End If

                locations.Add(extendedLocations.First.Key, CType(extendedLocations.First.Value, Types.Location))
            End If

            Return GetFactorsExtendedForLocations(session, dateFrom, dateTo, locations, False, True)
        End Function

        Public Shared Function GetFactorsExtendedForLocations(session As ReportSession, dateFrom As DateTime,
                                                              dateTo As DateTime,
                                                              locations As Dictionary(Of Int32, Types.Location),
                                                              Optional ByVal willAggregate As Boolean = True,
                                                              Optional ByVal loadApprovals As Boolean = False) As DataTable
            Dim reportDataTable As DataTable = Nothing

            For Each location In locations
                If reportDataTable Is Nothing Then
                    reportDataTable = GetF1F2F3ReportData(session, location.Key, dateFrom, dateTo, willAggregate)
                    reportDataTable = AddLocationDataToTable(location.Value, reportDataTable)
                    reportDataTable = CalculateF1F2F3Factors(reportDataTable, Not willAggregate) ' group on date only if NOT aggregating
                Else
                    Dim tempDataTable = GetF1F2F3ReportData(session, location.Key, dateFrom, dateTo, willAggregate)
                    tempDataTable = AddLocationDataToTable(location.Value, tempDataTable)
                    reportDataTable.Merge(CalculateF1F2F3Factors(tempDataTable, Not willAggregate))
                End If
            Next

            If loadApprovals Then
                If session.Context = ReportContext.LiveOnly Then
                    ' live data should have nothing approved. So in this case we just add an empty column for
                    ' approved, which will get converted to false later on
                    reportDataTable.Columns.Add("Approved", GetType(Boolean))
                Else
                    ApprovalData.AddApprovalFromTagsForMulitpleMonths(session, reportDataTable)
                End If
            End If

            Return reportDataTable
        End Function

        ''' <summary>
        ''' Get factor values for a Product Type
        ''' </summary>
        ''' <param name="session">session object defining paramters for this reporting session</param>
        ''' <param name="dateFrom">start date in the reporting range</param>
        ''' <param name="dateTo">end date in the reporting range</param>
        ''' <param name="productTypeId">product type code to report</param>
        ''' <param name="groupOnCalendarDate">if true, results are grouped by calendar date within the reporting period, otherwise they are grouped together</param>
        ''' <returns>DataTable containing factor results for the product type</returns>
        Public Shared Function GetFactorsForProductType(session As ReportSession, dateFrom As DateTime,
                                                        dateTo As DateTime,
                                                        productTypeId As Integer,
                                                        groupOnCalendarDate As Boolean) As DataTable


            ' we only need to set the product_type_id, this will automatically set session.selectedProductType, session.productTypeCode
            ' and the productSizeFilter
            ' If the product type isn't found then an exception will be thrown
            session.ProductTypeId = productTypeId

            ' obtain information about the location for this product type (or the top level location)
            ' all product type information will be given the same location identity
            Dim locationInformation As Dictionary(Of Int32, Types.Location)
            locationInformation = GetParentLocationNameWithOverride(session, session.SelectedProductType.LocationId, dateFrom, dateFrom)
            Dim productTypeLocationInfo = locationInformation(session.SelectedProductType.LocationId)

            Dim productTypeResultTable = GetF1F2F3ReportData(session, session.SelectedProductType.LocationId, dateFrom, dateTo, Not groupOnCalendarDate)

            If Not productTypeResultTable Is Nothing Then
                ' need an order number to ensure that the rows can be shown in required order even if later aggregation occurs on the table
                productTypeResultTable = AddOrderNoColumn(productTypeResultTable)
                ' add location columns
                productTypeResultTable = AddLocationDataToTable(productTypeLocationInfo, productTypeResultTable)
                ' calculate the factors on the entire table
                productTypeResultTable = RecalculateF1F2F3Factors(productTypeResultTable)
                ' then add the product type identification columns
                AddProductTypeColumns(productTypeResultTable, session.SelectedProductType)
            End If

            Return productTypeResultTable.DefaultView.ToTable
        End Function

        ''' <summary>
        ''' Get factor values for a Product Type
        ''' </summary>
        ''' <param name="session">session object defining paramters for this reporting session</param>
        ''' <param name="dateFrom">start date in the reporting range</param>
        ''' <param name="dateTo">end date in the reporting range</param>
        ''' <param name="productTypeIdsString">product type Ids to include in report (as delimited string)</param>
        ''' <param name="groupOnCalendarDate">if true, results are grouped by calendar date within the reporting period, otherwise they are grouped together</param>
        ''' <returns>DataTable containing factor results for the product type</returns>
        Public Shared Function GetFactorsForProductTypes(session As ReportSession, dateFrom As DateTime,
                                                         dateTo As DateTime,
                                                         productTypeIdsString As String,
                                                         groupOnCalendarDate As Boolean) As DataTable

            Dim productTypeIdStrings = productTypeIdsString.Split({","c})
            Dim productTypeIdIntegerValues = productTypeIdStrings.Select(Function(s) Integer.Parse(s)).ToList()

            Return GetFactorsForProductTypes(session, dateFrom, dateTo, productTypeIdIntegerValues, groupOnCalendarDate)
        End Function

        ''' <summary>
        ''' Get factor values for a Product Type
        ''' </summary>
        ''' <param name="session">session object defining paramters for this reporting session</param>
        ''' <param name="dateFrom">start date in the reporting range</param>
        ''' <param name="dateTo">end date in the reporting range</param>
        ''' <param name="productTypeIds">product type Ids to include in report</param>
        ''' <param name="groupOnCalendarDate">if true, results are grouped by calendar date within the reporting period, otherwise they are grouped together</param>
        ''' <returns>DataTable containing factor results for the product type</returns>
        Public Shared Function GetFactorsForProductTypes(session As ReportSession, dateFrom As DateTime,
                                                         dateTo As DateTime, productTypeIds As IEnumerable(Of Integer),
                                                         groupOnCalendarDate As Boolean) As DataTable
            Dim resultsDataTable As DataTable = Nothing

            If Not productTypeIds Is Nothing Then
                For Each productTypeId In productTypeIds
                    'Need to clear the cache as failing to do so was causing incorrect results when running
                    'for multiple productTypes
                    session.ClearCacheBlockModel()
                    Dim tempDataTable = GetFactorsForProductType(session, dateFrom, dateTo, productTypeId, groupOnCalendarDate)

                    If resultsDataTable Is Nothing Then
                        resultsDataTable = tempDataTable
                    Else
                        ' include this product type code result with the overall results
                        resultsDataTable.Merge(tempDataTable)
                    End If
                Next
            End If

            Return resultsDataTable
        End Function


        ''' <summary>
        ''' Add product type column to the table and assign the value provided
        ''' </summary>
        ''' <param name="table">table to have the product type code assigned</param>
        ''' <param name="prodType">ProductType object containing id and name information for the Product Type</param>
        Public Shared Sub AddProductTypeColumns(table As DataTable, prodType As ProductType)
            If Not table.Columns.Contains("ProductTypeCode") Then
                table.Columns.Add("ProductTypeCode", GetType(String))
            End If

            If Not table.Columns.Contains("ProductTypeDescription") Then
                table.Columns.Add("ProductTypeDescription", GetType(String))
            End If

            If Not table.Columns.Contains("ProductTypeId") Then
                table.Columns.Add("ProductTypeId", GetType(Integer))
            End If

            For Each row As DataRow In table.Rows
                row("ProductTypeCode") = prodType.ProductTypeCode
                row("ProductTypeId") = prodType.ProductTypeID
                row("ProductTypeDescription") = prodType.Description
            Next
        End Sub

        Public Shared Function GetFactorsForLocation(session As ReportSession, locationId As Int32,
                                                     dateFrom As DateTime, dateTo As DateTime,
                                                     includeMainFactorsOnly As Boolean) As DataTable

            If locationId = 0 Then
                locationId = session.DalUtility.GetBhpbioLocationRoot()
            End If

            Dim locations As Dictionary(Of Int32, Types.Location)
            locations = GetParentLocationName(session, locationId)

            Return GetFactorsForLocations(session, dateFrom, dateTo, locations, includeMainFactorsOnly)
        End Function

        Public Shared Function GetFactorsForLocations(session As ReportSession, dateFrom As DateTime,
                                                      dateTo As DateTime,
                                                      locations As Dictionary(Of Int32, Types.Location),
                                                      includeMainFactorsOnly As Boolean) As DataTable

            Dim reportDataTable As DataTable = Nothing

            For Each location In locations
                If reportDataTable Is Nothing Then
                    reportDataTable = GetF1F2F3ReportData(session, location.Key, dateFrom, dateTo)
                    reportDataTable = AddLocationDataToTable(location.Value, reportDataTable)
                    If includeMainFactorsOnly Then
                        reportDataTable = GetFactorsForReportData(reportDataTable)
                    Else
                        reportDataTable = CalculateF1F2F3Factors(reportDataTable)
                    End If

                Else
                    Dim holdingTable = GetF1F2F3ReportData(session, location.Key, dateFrom, dateTo)
                    holdingTable = AddLocationDataToTable(location.Value, holdingTable)
                    If includeMainFactorsOnly Then
                        holdingTable = GetFactorsForReportData(holdingTable)
                    Else
                        holdingTable = CalculateF1F2F3Factors(holdingTable)
                    End If
                    reportDataTable.Merge(holdingTable)
                End If
            Next

            Return reportDataTable
        End Function


        Public Shared Sub FixModelNames(ByRef table As DataTable)
            FixModelNames(table, "Model")
            FixModelNames(table, "ModelTag")
            FixModelNames(table, "BlockModelName1")
            FixModelNames(table, "BlockModelName2")
        End Sub

        Public Shared Sub FixModelNames(ByRef table As DataTable, columnName As String)
            If Not table.Columns.Contains(columnName) Then
                Return
            End If

            For Each row As DataRow In table.Rows
                If row.AsString(columnName) = "Short Term Geology" Then
                    row(columnName) = ModelShortTermGeology.CalculationDescription
                End If
            Next
        End Sub
        Public Shared Function AddResourceClassificationDescriptions(table As DataTable) As DataTable
            If Not table.Columns.Contains("ResourceClassificationDescription") Then
                table.Columns.Add("ResourceClassificationDescription", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                row("ResourceClassificationDescription") = GetResourceClassificationDescription(row.AsString("ResourceClassification"), row.AsString("CalcId"))
            Next

            Return table
        End Function

        Public Shared Function GetResourceClassificationDescription(resourceClassification As String, modelNameOrCalcId As String) As String
            Dim result = "INVALID_RC"
            Dim key = modelNameOrCalcId.Replace(" ", "").ToLower

            If key.Contains("shortterm") Or key.Contains("f15factor") Or key.Contains("stgm") Then
                Select Case resourceClassification
                    Case "ResourceClassification1" : result = "High"
                    Case "ResourceClassification2" : result = "Medium"
                    Case "ResourceClassification3" : result = "Low"
                    Case "ResourceClassification4" : result = "Very Low"
                    Case "ResourceClassification5" : result = "Default/Unclass"
                    Case "ResourceClassificationUnknown" : result = "No Information"
                End Select
            Else
                Select Case resourceClassification
                    Case "ResourceClassification1" : result = "Measured"
                    Case "ResourceClassification2" : result = "Indicated"
                    Case "ResourceClassification3" : result = "Inferred"
                    Case "ResourceClassification4" : result = "Potential"
                    Case "ResourceClassification5" : result = "Default/Unclass"
                    Case "ResourceClassificationUnknown" : result = "No Information"
                End Select
            End If

            Return result
        End Function
    End Class
End NameSpace