Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportDefinitions

    Public Class HomeScreenValues
        Inherits ReportBase

        Public Shared Function GetHomeScreenFactors(ByVal session As Types.ReportSession, _
                                                   ByVal locationId As Int32, ByVal startDate As DateTime, _
                                                   ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown, _
                                                   ByVal referenceTimeFrame As DateTime, ByVal aggregateResult As Boolean, _
                                                   ByVal aggregateToYears As Boolean) As DataTable

            ' exclude F2.5 + F1.5 as we don't need it
            session.ExcludeFactorFromHubReportSet(Calc.F15.CalculationId)
            session.ExcludeFactorFromHubReportSet(Calc.F25.CalculationId)

            ' include historical data
            session.UseHistorical = True
            
            Dim resultTable As DataTable = F1F2F3ReportEngine.GetFactorsForLocation(session, locationId, startDate, endDate, True)
            Return resultTable
        End Function

        Public Shared Function GetHomeScreenValues(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32, ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown, _
         ByVal referenceTimeframe As DateTime) As DataTable

            Dim deleteList As New ArrayList

            ' always get the data at monthly level
            session.CalculationParameters(startDate, endDate, ReportBreakdown.Monthly, locationId, Nothing)
            session.UseHistorical = True

            F1F2F3ReportEngine.PrepareF1F2F3Cache(session)

            ' get the raw data (without using the requested breakdown)
            Dim calculationSet As CalculationSet = GetRawCalculationSet(session, locationId, startDate, endDate)

            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Report.Data.DateBreakdown.AddDateText(dateBreakdown, calculationSet)

            ' convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(False, False, False, False, dateBreakdown, session, False)

            MakeTheZeroRecordsNull(table)

            ' Recalculate F1F2F3 factors post aggregation as per other reports
            table = F1F2F3ReportEngine.CalculateF1F2F3Factors(table, True, False)

            Dim factorList As New List(Of String)
            factorList.Add(Calc.F1.CalculationId.ToLower)
            factorList.Add(Calc.F2.CalculationId.ToLower)
            factorList.Add(Calc.F3.CalculationId.ToLower)

            For Each row As DataRow In table.Rows
                If Not factorList.Contains(row("ReportTagId").ToString.ToLower) Then
                    deleteList.Add(row)
                End If
            Next

            For Each row As DataRow In deleteList
                row.Table.Rows.Remove(row)
            Next

            Return table
        End Function


#Region "Home Screen Chart Private Methods"

        Private Shared Function GetRawCalculationSet(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32, ByVal startDate As DateTime, _
         ByVal endDate As DateTime) As CalculationSet
            Dim holdingData As New CalculationSet

            ' Always get raw data monthly
            ' even if then aggregating to a higher level
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, Nothing)
            ' include historical data
            session.UseHistorical = True

            Dim f1Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate()
            Dim f2Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F2, session).Calculate()
            Dim f3Calc As CalculationResult = Calc.Calculation.Create(Calc.CalcType.F3, session).Calculate()

            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
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

            holdingData.Add(f1Calc)
            holdingData.Add(f2Calc)
            holdingData.Add(f3Calc)

            Return holdingData
        End Function

        Private Shared Sub MakeTheZeroRecordsNull(ByVal result As DataTable)
            For Each row As DataRow In result.Rows
                For Each col As String In New String() {"Tonnes", "DodgyAggregateGradeTonnes", "Fe", "P", "SiO2", "Al2O3", "LOI"}
                    If (Not row(col) Is DBNull.Value) AndAlso (DirectCast(row(col), Double) = 0.0) Then
                        row(col) = DBNull.Value
                        If result.Columns.Contains(col & "Difference") Then
                            row(col & "Difference") = DBNull.Value
                        End If
                    End If
                Next
            Next
        End Sub

#End Region

    End Class

End Namespace

