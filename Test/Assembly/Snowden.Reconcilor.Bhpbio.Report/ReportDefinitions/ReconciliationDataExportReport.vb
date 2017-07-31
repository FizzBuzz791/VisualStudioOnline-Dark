Imports Snowden.Reconcilor.Bhpbio.Report.Types


Namespace ReportDefinitions
    
    Public Class ReconciliationDataExportReport
        Inherits ReportBase

        Public Shared Function ConvertDataTableForExcel(ByRef data As DataTable) As DataTable

            ' Although certain columns are not relevant to all rows, there is no explicit filtering or nulling out in this export logic.  
            ' It is expected that the calculation classes that produce these results will themselves only produce values for attributes where appropriate

            Dim resultTable As New DataTable()

            ' dont change these column names, as some of the export stuff later on
            ' is dependent on these being the same as the Grade names. If you want to change the excel
            ' column headers, change the column names later on, once the actual excel export is complete

            resultTable.Columns.Add("PeriodStart", GetType(DateTime))

            If data.Columns.Contains("HubName") Then
                resultTable.Columns.Add("HubName", GetType(String))
                resultTable.Columns.Add("SiteName", GetType(String))
                resultTable.Columns.Add("PitName", GetType(String))
            Else
                resultTable.Columns.Add("LocationName", GetType(String))
            End If

            resultTable.Columns.Add("ProductSize", GetType(String))
            resultTable.Columns.Add("MeasureDescription", GetType(String))
            resultTable.Columns.Add("Approved", GetType(String))
            resultTable.Columns.Add("kTonnes", GetType(Double))
            resultTable.Columns.Add("Volume", GetType(Double))


            ' Determine which grade columns should be included.. (both as GradeValues and as GradeTonnes)
            Dim gradeNamesForExport() As String = CalculationResultRecord.GradeNames.Where(Function(name) Not CalculationResultRecord.GradeNamesNotApplicableForReconciliationExport.Contains(name)).ToArray()
            Dim gradeNamesForGradeTonnesExport() As String = gradeNamesForExport.Where(Function(name) Not CalculationResultRecord.GradeNamesNotApplicableForGradeTonnesCalculation.Contains(name)).ToArray()

            For Each gradeName As String In gradeNamesForExport
                resultTable.Columns.Add(gradeName, GetType(Double))
            Next

            For Each gradeName As String In gradeNamesForGradeTonnesExport
                resultTable.Columns.Add(gradeName + "Tonnes", GetType(Double))
            Next

            For Each row As DataRow In data.Rows()
                If IsDBNull(row("PresentationValid")) Then
                    row("PresentationValid") = True
                End If

                If row.AsBool("PresentationValid") = False Then
                    Continue For
                End If

                If Not row.HasValue("Tonnes") Then
                    If row.HasValue("ResourceClassification") AndAlso row.AsString("ResourceClassification") <> "ResourceClassificationTotal" Then
                        row("Tonnes") = 0.0
                        row("Volume") = 0.0
                    Else
                        Continue For
                    End If
                End If


                Dim newRow = resultTable.NewRow()
                newRow("PeriodStart") = row("DateFrom")

                If row.HasColumn("HubName") Then
                    newRow("HubName") = row("HubName")
                    newRow("SiteName") = row("SiteName")
                    newRow("PitName") = If(row.AsString("LocationType") = "Pit", row.AsString("LocationName"), "")
                Else
                    newRow("LocationName") = row.AsString("LocationName")
                End If

                newRow("ProductSize") = row("ProductSize")
                newRow("MeasureDescription") = row("Description")

                If row.HasColumn("Approved") AndAlso row.HasValue("Approved") Then
                    newRow("Approved") = row("Approved")
                Else
                    newRow("Approved") = False
                End If

                Dim kTonnes = row.AsDblN("Tonnes")

                ' convert to ktonnes, unless its a factor
                If Not row.IsFactorRow AndAlso Not row.IsGeometRow Then
                    kTonnes /= 1000
                End If

                newRow("kTonnes") = kTonnes

                If row.HasValue("Volume") AndAlso HasValidVolume(row) Then
                    Dim volume = row.AsDbl("Volume")
                    newRow("Volume") = If(row.IsFactorRow, volume, volume / 1000)
                End If

                ' loop through each of the grade values and put them in the table if they exist, and
                ' calculate the correct tonnes value for the value
                For Each attributeName In gradeNamesForExport
                    If row.HasValue(attributeName) Then
                        Dim attributeValue = row.AsDbl(attributeName)
                        newRow(attributeName) = attributeValue

                        If Not row.IsFactorRow AndAlso gradeNamesForGradeTonnesExport.Contains(attributeName) AndAlso Not row.IsGeometRow Then
                            Dim gradeTonnesColumnName = attributeName + "Tonnes"
                            newRow(attributeName + "Tonnes") = kTonnes * (attributeValue / 100.0)
                        End If
                    End If
                Next

                resultTable.Rows.Add(newRow)
            Next

            ' now we can update any column names, if required
            resultTable.Columns("Volume").ColumnName = "Volume k(m3)"

            Return resultTable
        End Function

        Public Shared Function GetF1F2F3AllLocationsReconciliationReportData(ByVal session As Types.ReportSession, _
                                                      ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, _
                                                      ByVal dateBreakdown As String, ByVal includeSublocations As Boolean) As DataTable

            If Not (dateBreakdown = "MONTH" Or dateBreakdown = "QUARTER") Then
                Throw New NotSupportedException("Only MONTH/QUARTER are supported for this report.")
            End If

            Dim breakdown As ReportBreakdown = Types.ReportSession.ConvertReportBreakdown(dateBreakdown)
            Return F1F2F3ReportEngine.GetFactorsExtendedForAllChildLocations(session, locationId, dateFrom, dateTo, breakdown, includeSublocations)
        End Function

        Public Shared Function GetPatternLevelFactors(session As ReportSession, ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As DataTable
            If session.ForwardModelFactorCalculation Then
                dateFrom = dateFrom.AddMonths(1)
                dateTo = dateFrom
                session.Context = Types.ReportContext.LiveOnly
            End If

            session.CalculationParameters(dateFrom, dateTo, locationId, childLocations:=True)
            session.OverrideModelDataLocationTypeBreakdown = "Blast"

            Dim calcList = New String() {"F1Factor", "F15Factor", "GeologyModel"}
            Dim calcSet = CalculationSet.CreateForCalculations(session, calcList)
            Dim table = calcSet.ToDataTable(session, New DataTableOptions With {
                                                .DateBreakdown = ReportBreakdown.Monthly,
                                                .IncludeSourceCalculations = True,
                                                .IncludeParentAndChildLocations = True
                                            })

            F1F2F3ReportEngine.RecalculateF1F2F3Factors(table)
            BlockOutSummaryReport.AddLocationData(session, table, locationId, dateFrom)

            If session.IncludeResourceClassification Then
                F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)

                table.AsEnumerable.
                    Where(Function(r) r.HasValue("ResourceClassification")).
                    SetField("Description", Function(r) String.Format("{0} - {1}", r("Description"), r("ResourceClassificationDescription")))
            End If

            If session.ForwardModelFactorCalculation Then
                table.AsEnumerable.SetField("Description", Function(r) r.AsString("Description") + " (Forward)")
            End If

            Return ConvertDataTableForExcel(table)
        End Function

        Public Shared Function HasValidVolume(ByRef row As DataRow) As Boolean
            If row.IsGeometRow Then Return False
            ' Volume is valid for all non-factors (maybe?) and the F1 and F15 factors
            Return Not row.IsFactorRow Or (row("ReportTagId").ToString = "F1Factor" Or row("ReportTagId").ToString = "F15Factor")
        End Function
    End Class

End Namespace

