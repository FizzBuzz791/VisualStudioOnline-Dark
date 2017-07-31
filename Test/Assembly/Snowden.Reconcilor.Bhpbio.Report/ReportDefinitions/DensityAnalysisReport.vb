Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.WebService

Namespace ReportDefinitions

    Public Class DensityAnalysisReport

        Private Const _differencePresentationColour As String = "Red"

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
           ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal sourceList As String()) As DataTable

            Dim deleteList As New ArrayList

            ' Get the raw data
            Dim calculationSet As CalculationSet = GetRawCalculationSet(session, locationId, dateFrom, dateTo)

            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Data.DateBreakdown.AddDateText(ReportBreakdown.None, calculationSet)

            ' Convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(False, True, False, True, ReportBreakdown.None, session, False)

            ' Invert density for display
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)

            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)
            Data.GradeProperties.AddGradeColourToNormalizedTable(session, table)

            ' Only retain the relevant data in the results
            FilterRows(table, sourceList)

            If Not table.Columns.Contains("GraphTitle") Then
                table.Columns.Add("GraphTitle")
            End If

            For Each row As DataRow In table.Rows
                row("GraphTitle") = String.Empty
            Next

            ' Convert material type ids to root material type names (aka designations)
            SetMaterialTypeDesignations(table, locationId, session)
            ' Converto to kTonnes
            ConvertToKiloTonnes(table)

            Return table

        End Function

        Public Shared Function GetSupportingDetailsData(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
           ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal sourceList As String()) As DataTable

            Dim table = GetData(session, locationId, dateFrom, dateTo, sourceList)
            CalculateDifferences(table)
            Return table

        End Function

        Private Shared Function GetRawCalculationSet(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
            ByVal startDate As DateTime, ByVal endDate As DateTime) As CalculationSet

            Dim holdingData As New CalculationSet

            session.CalculationParameters(startDate, endDate, ReportBreakdown.Monthly, locationId, Nothing)
            session.UseHistorical = True

            Dim f1 = CreateAllMaterialsCalculation(Calc.CalcType.F1, session).Calculate()
            holdingData.Add(f1.GetFirstCalcId(Calc.ModelGradeControl.CalculationId))
            holdingData.Add(f1.GetFirstCalcId(Calc.ModelMining.CalculationId))

            Dim f15 = CreateAllMaterialsCalculation(Calc.CalcType.F15, session).Calculate()
            holdingData.Add(f15.GetFirstCalcId(Calc.ModelGradeControlSTGM.CalculationId))
            holdingData.Add(f15.GetFirstCalcId(Calc.ModelShortTermGeology.CalculationId))

            Dim f2 = CreateAllMaterialsCalculation(Calc.CalcType.F2Density, session).Calculate()
            Dim gc = f2.GetFirstCalcId(Calc.ModelGradeControl.CalculationId)
            gc.ReplaceDescription(Calc.ModelGradeControl.CalculationId, "Grade Control Model")
            holdingData.Add(f2.GetFirstCalcId(Calc.ActualMined.CalculationId))
            holdingData.Add(gc)

            Dim rfd = CreateAllMaterialsCalculation(Calc.CalcType.RecoveryFactorDensity, session).Calculate()
            holdingData.Add(rfd.GetFirstCalcId(Calc.ActualMined.CalculationId))
            holdingData.Add(rfd.GetFirstCalcId(Calc.ModelMining.CalculationId))

            Return holdingData
        End Function

        Private Shared Function CreateAllMaterialsCalculation(ByVal calcType As Calc.CalcType, ByVal session As Types.ReportSession) As Calc.Calculation

            Dim calculation As Calc.Calculation = DirectCast(Calc.Calculation.Create(calcType, session), Calc.Calculation)

            If TypeOf calculation Is Calc.IAllMaterialTypesCalculation Then
                DirectCast(calculation, Calc.IAllMaterialTypesCalculation).IncludeAllMaterialTypes = True
            End If

            Return calculation
        End Function

        Private Shared Function CreateAllMaterialsModelCalc(ByVal calcType As Calc.CalcType, ByVal session As Types.ReportSession) As Calc.CalculationModel

            Dim model As Calc.CalculationModel = DirectCast(Calc.Calculation.Create(calcType, session), Calc.CalculationModel)
            model.IncludeAllMaterialTypes = True
            Return model

        End Function

        Private Shared Sub SetMaterialTypeDesignations(ByRef dataTable As DataTable, ByVal locationId As Int32, ByVal session As Types.ReportSession)

            dataTable.Columns.Add("Designation", GetType(String))

            Dim materialType As String
            Dim materialTypeId As Integer
            Dim materialTypeList As Dictionary(Of Integer, String) = DensityReconciliationReport.GetDesignationList(session)

            For Each row As DataRow In dataTable.Rows
                Try
                    materialType = row("MaterialTypeId").ToString
                    If Not String.IsNullOrEmpty(materialType) Then
                        materialTypeId = Convert.ToInt32(materialType)
                        materialType = materialTypeList(materialTypeId)
                        row("Designation") = materialType
                    Else
                        row("Designation") = "Total"
                    End If
                Catch
                    row("Designation") = "Unknown" ' this is not ideal, but better than no error handling at all
                End Try
            Next
        End Sub

        Private Shared Sub ConvertToKiloTonnes(ByRef data As DataTable)
            Dim tonnes As Single

            For Each row As DataRow In data.Rows
                If Single.TryParse(row("AttributeValue").ToString(), tonnes) Then
                    row("Attribute") = "kTonnes"
                    row("AttributeValue") = tonnes / 1000
                Else
                    Throw New DataException(String.Format("Record with report tag id {0}, attribute {1}, has non-numeric attribute value of {2}", row("ReportTagId"), row("Attribute"), row("AttributeValue")))
                End If
            Next

        End Sub

        Private Shared Sub CalculateDifferences(ByRef data As DataTable)
            Dim kTonnesMeasure1, kTonnesMeasure2 As Single

            Dim designationList = (From row In data.AsEnumerable() Select row.Field(Of String)("Designation")).Distinct().ToList()
            Dim factorList = data.AsEnumerable.Select(Function(r) r("RootCalcId").ToString).Distinct.ToList

            For Each factor In factorList
                For Each designation As String In designationList
                    ' for each (distinct) designation there are 2 (if both measures have values) or 1 row (if only 1 measure has value)
                    Dim rows = data.Select(String.Format("Designation='{0}' And RootCalcId='{1}'", designation, factor)).ToList()

                    If rows.Count < 1 Then
                        Continue For 'should not happens because of the way designationList is created
                    End If

                    Dim differenceRow = data.NewRow()
                    differenceRow("TagId") = "Difference"
                    differenceRow("ReportTagId") = "Difference"
                    differenceRow("CalcId") = "Difference"
                    differenceRow("Description") = "Difference"
                    differenceRow("Type") = rows(0)("Type")
                    differenceRow("CalculationDepth") = rows(0)("CalculationDepth")
                    differenceRow("InError") = False
                    differenceRow("ErrorMessage") = String.Empty
                    differenceRow("ProductSize") = rows(0)("ProductSize")
                    differenceRow("SortKey") = rows(0)("SortKey")
                    differenceRow("CalendarDate") = rows(0)("CalendarDate")
                    differenceRow("DateFrom") = rows(0)("DateFrom")
                    differenceRow("DateTo") = rows(0)("DateTo")
                    differenceRow("LocationId") = rows(0)("LocationId")
                    differenceRow("MaterialTypeId") = rows(0)("MaterialTypeId")
                    differenceRow("Attribute") = rows(0)("Attribute")
                    differenceRow("PresentationColor") = _differencePresentationColour
                    differenceRow("PresentationAttributePrecision") = rows(0)("PresentationAttributePrecision")
                    differenceRow("AttributeColour") = rows(0)("AttributeColour")
                    differenceRow("Designation") = designation
                    differenceRow("RootCalcId") = rows(0)("RootCalcId")

                    If rows.Count = 2 Then
                        kTonnesMeasure1 = Convert.ToSingle(rows(0)("AttributeValue"))
                        kTonnesMeasure2 = Convert.ToSingle(rows(1)("AttributeValue"))
                        differenceRow("AttributeValue") = kTonnesMeasure1 - kTonnesMeasure2
                    ElseIf rows.Count = 1 Then
                        ' one of the measures was null: null - <any value> = null
                        differenceRow("AttributeValue") = DBNull.Value
                    Else
                        Continue For 'should not happens because of the way designationList is created
                    End If
                    data.Rows.Add(differenceRow)
                Next
            Next

        End Sub


        Private Shared Sub FilterRows(ByRef table As DataTable, ByVal sourceList As String())
            Dim deleteList As New ArrayList

            For Each row As DataRow In table.Rows
                If row("Attribute").ToString.ToLower <> "tonnes" Then
                    deleteList.Add(row)
                ElseIf Not sourceList.Contains(row("CalcId").ToString) Then
                    deleteList.Add(row)
                End If
            Next

            For Each row As DataRow In deleteList
                row.Table.Rows.Remove(row)
            Next
        End Sub
    End Class

End Namespace
