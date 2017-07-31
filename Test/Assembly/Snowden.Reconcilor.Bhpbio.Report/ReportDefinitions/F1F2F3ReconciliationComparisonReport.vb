Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace ReportDefinitions

    Public Class F1F2F3ReconciliationComparisonReport
        Inherits ReportBase

        ''' <summary>
        ''' Gets the raw data.
        ''' </summary>
        ''' <param name="session">The session.</param>
        ''' <param name="locationId">The location id.</param>
        ''' <param name="startDate">The start date.</param>
        ''' <param name="endDate">The end date.</param>
        ''' <returns></returns>
        Private Shared Function GetRawData(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32, ByVal startDate As DateTime, _
         ByVal endDate As DateTime) As CalculationSet
            Dim holdingData As New CalculationSet

            ' Always get raw data monthly
            ' even if then aggregating to a higher level
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, True)
            session.UseHistorical = True

            ' prime data cache, multi-threaded
            F1F2F3ReportEngine.PrepareF1F2F3Cache(session)

            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MineProductionExpitEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelCrusherEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.SitePostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.HubPostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PostCrusherStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelShippingEquivalent, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortStockpileDelta, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.PortOreShipped, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.OreForRail, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.MiningModelOreForRailEquivalent, session).Calculate())

            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F15, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F2, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F25, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F3, session).Calculate())

            Data.ReportColour.AddPresentationColour(session, holdingData)
            Data.DateBreakdown.AddDateText(dateBreakdown, holdingData)

            Return holdingData
        End Function

        Public Shared Function GetData(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32, ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown, _
         ByVal attributes As String, ByVal factor As String, ByVal locations As String) As DataTable

            Dim attributeList As IList
            Dim locationList As IList
            Dim deleteList As New ArrayList
            Dim row As DataRow

            ' get the raw calculation values
            Dim rawDataCalculationSet As CalculationSet = GetRawData(session, locationId, startDate, endDate)

            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, True)

            ' convert to a table aggregated to the relevant level
            Dim table As DataTable = rawDataCalculationSet.ToDataTable(False, True, True, False, dateBreakdown, session, False)

            ' invert density for display
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)

            ' recalculate the factor values as required
            ' this is neccessary because the aggregation step (built in as part of ToDateTable() above will have invalidated the factors
            F1F2F3ReportEngine.RecalculateF1F2F3FactorsByCalculationIdLookup(table)

            Dim locationNames As DataTable = session.DalUtility.GetBhpbioLocationChildrenNameWithOverride(locationId, startDate, endDate)
            Dim currentLocationId As String
            Dim presentationColor As String
            Dim colorDataTable As DataTable

            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)

            Data.DateBreakdown.MergeDateText(dateBreakdown, table, "CalendarDate", "DateText")

            attributeList = Data.ReportDisplayParameter.GetXmlAsList(attributes.ToLower, "attribute", "name")
            locationList = Data.ReportDisplayParameter.GetXmlAsList(locations.ToLower, "location", "id")

            table.Columns.Add(New DataColumn("FactorDescription", GetType(String)))

            For Each row In table.Rows
                currentLocationId = row("LocationId").ToString
                presentationColor = "black"

                'Changed If Condition to filter out any empty "currentlocationid"

                If (Not attributeList.Contains(row("Attribute").ToString.ToLower)) _
                    Or row("ReportTagId").ToString.ToLower <> factor.ToLower Then _
                    'Or ((Not locationList.Contains(currentLocationId))) Then _
                    'Or (currentLocationId Is String.Empty)) Then
                    deleteList.Add(row)
                Else
                    row("FactorDescription") = row("Description").ToString
                    If Not currentLocationId Is String.Empty Then

                        If (Not locationList.Contains(currentLocationId)) Then
                            deleteList.Add(row)
                        Else
                            row("Description") = locationNames.Select("Location_Id = " & currentLocationId)(0)("Location_Type_Description").ToString & ": " & locationNames.Select("Location_Id = " & currentLocationId)(0)("Name").ToString

                            colorDataTable = session.DalUtility.GetBhpbioReportColorList(currentLocationId, True)

                            If (Not colorDataTable.Rows.Count = 0) Then
                                presentationColor = colorDataTable.Rows(0)("color").ToString()
                            End If

                            row("PresentationColor") = presentationColor
                        End If

                    Else
                        row("Description") = ""
                        'row("PresentationColor") = "Black"
                        row("AttributeValue") = 0
                    End If

                End If
            Next

            For Each row In deleteList
                row.Table.Rows.Remove(row)
            Next

            Return table
        End Function
    End Class
End Namespace
