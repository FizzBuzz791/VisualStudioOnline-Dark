Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace ReportDefinitions

    Public Class DensityReconciliationReport
        Inherits ReportBase

        Private Shared ReadOnly _densityHeader As String = "Calculated Density"
        Private Shared ReadOnly _tonnesHeader As String = "kTonnes"
        Private Shared ReadOnly _volumeHeader As String = "Volume - k(m3)"

        Private Shared ReadOnly _factorList As List(Of String) = _
            New List(Of String)(New String() {"RecoveryFactorDensity", "F1Factor", "F15Factor", "F2DensityFactor"})

        Private Shared ReadOnly _supportingMeasureList As List(Of String) = _
            New List(Of String)(New String() {"MiningModel", "ShortTermGeologyModel", "GradeControlModel", "GradeControlSTGM", "ActualMined"})

        Private Shared ReadOnly _supportingAttributeList As List(Of String) = _
            New List(Of String)(New String() {"Tonnes", "Volume", "Density"})


        Public Shared Function GetFactorData(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
           ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal breakdownDensityByDesignation As Boolean) As DataTable

            Dim deleteList As New ArrayList
            Dim row As DataRow

            ' Get the raw data
            Dim calculationSet As CalculationSet = GetRawCalculationSet(session, locationId, dateFrom, dateTo, breakdownDensityByDesignation)

            Data.ReportColour.AddPresentationColour(session, calculationSet)
            Data.DateBreakdown.AddDateText(ReportBreakdown.None, calculationSet)

            ' Convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(False, True, False, breakdownDensityByDesignation, ReportBreakdown.None, session, breakdownDensityByDesignation)

            ' recalculate factors  and invert density for display
            F1F2F3ReportEngine.RecalculateF1F2F3FactorsForUnpivotedTable(table, False)
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)

            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)
            Data.GradeProperties.AddGradeColourToNormalizedTable(session, table)

            ' Convert material type ids to root material type names (aka designations)
            SetMaterialTypeDesignations(table, locationId, breakdownDensityByDesignation, session)
            ' Add threshold indicators for each density value (i.e. for smily faces on the report)
            SetThresholds(table, locationId, breakdownDensityByDesignation, session)


            ' Only retain the relevant data in the results
            For Each row In table.Rows
                If row("Attribute").ToString.ToLower <> "density" Or Not _factorList.Contains(row("ReportTagId").ToString) Then
                    deleteList.Add(row)
                End If
            Next
            For Each row In deleteList
                row.Table.Rows.Remove(row)
            Next

            Return table

        End Function

        Public Shared Function GetSupportingDetailsData(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
            ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal breakdownDensityByDesignation As Boolean) As DataTable

            Dim deleteList As New ArrayList
            Dim row As DataRow

            ' Get the raw data (without using the requested breakdown)
            Dim calculationSet As CalculationSet = GetRawCalculationSet(session, locationId, dateFrom, dateTo, breakdownDensityByDesignation)
            Data.ReportColour.AddPresentationColour(session, calculationSet)

            ' Convert the calcualtion set to a table
            Dim table As DataTable = calculationSet.ToDataTable(False, True, False, breakdownDensityByDesignation, ReportBreakdown.None, session, breakdownDensityByDesignation)

            ' Invert density for display
            F1F2F3ReportEngine.RecalculateF1F2F3FactorsForUnpivotedTable(table, False)
            F1F2F3ReportEngine.InvertDensityForDisplay(table, "AttributeValue", True)

            ' Add decimal point precision to be used by report
            Data.GradeProperties.AddGradePrecisionToNormalizedTable(session, table)

            ' Only retain the relevant data in the results
            For Each row In table.Rows
                If Not _supportingAttributeList.Contains(row("Attribute").ToString) Or Not _supportingMeasureList.Contains(row("ReportTagId").ToString) Then
                    deleteList.Add(row)
                End If
            Next
            For Each row In deleteList
                row.Table.Rows.Remove(row)
            Next

            SetMaterialTypeDesignations(table, locationId, breakdownDensityByDesignation, session)
            CalculateDensityAndSetKiloUnits(table, breakdownDensityByDesignation)

            Return table
        End Function

        Public Shared Function GetDesignationList(ByVal session As Types.ReportSession) As Dictionary(Of Integer, String)
            Dim materialTypeList As Dictionary(Of Integer, String) = New Dictionary(Of Integer, String)()

            Dim materialTypeData As DataTable = session.DalUtility.GetMaterialTypeList(NullValues.Int16, NullValues.Int16, NullValues.Int32, "Designation", NullValues.Int32)
            For Each mtRow As DataRow In materialTypeData.Rows
                materialTypeList.Add(Convert.ToInt32(mtRow("Material_Type_Id")), Convert.ToString(mtRow("Description")))
            Next

            Return materialTypeList
        End Function

        Private Shared Function GetRawCalculationSet(ByVal session As Types.ReportSession, ByVal locationId As Int32, _
            ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdownFactorByMaterialType As Boolean) As CalculationSet

            Dim holdingData As New CalculationSet

            session.CalculationParameters(startDate, endDate, ReportBreakdown.Monthly, locationId, Nothing)
            session.UseHistorical = True

            Dim f1Calc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F1, breakdownFactorByMaterialType, session)
            Dim f15Calc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F15, breakdownFactorByMaterialType, session)
            Dim f2DensityCalc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.F2Density, breakdownFactorByMaterialType, session)
            Dim rfCalc As Calc.Calculation = CreateAllMaterialsCalculation(Calc.CalcType.RecoveryFactorDensity, breakdownFactorByMaterialType, session)

            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelMining, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelGradeControl, session).Calculate())
            holdingData.Add(CreateAllMaterialsModelCalc(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())

            holdingData.Add(CreateAllMaterialsCalculation(Calc.CalcType.ActualMined, breakdownFactorByMaterialType, session).Calculate())

            Dim f1 = f1Calc.Calculate()
            Dim f15 = f15Calc.Calculate()
            Dim f2 = f2DensityCalc.Calculate()
            Dim rf = rfCalc.Calculate()

            f1.ReplaceDescription("F1Factor", f1.Description.Replace("F1", "F1* (Density)"))
            f15.ReplaceDescription("F15Factor", f15.Description.Replace("F1.5", "F1.5* (Density)"))
            f2.ReplaceDescription("F2DensityFactor", f2.Description.Replace("F2", "F2*"))
            rf.ReplaceDescription("RecoveryFactorDensity", rf.Description.Replace("Recovery Factor", "Recovery Factor*"))

            holdingData.Add(f1)
            holdingData.Add(f15)
            holdingData.Add(f2)
            holdingData.Add(rf)

            Return holdingData
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

        Private Shared Sub SetThresholds(ByRef dataTable As DataTable, ByVal locationId As Int32, ByVal breakdownByMaterialType As Boolean, ByVal session As Types.ReportSession)

            Dim tonnes, density, lowThreshold, highThreshold As Single
            Dim thresholdDataTable As DataTable = Data.GradeProperties.GetFAttributeProperties(session, locationId)

            dataTable.Columns.Add("Threshold", GetType(String))

            If breakdownByMaterialType Then
                Dim designationList = (From row In dataTable.AsEnumerable() Select row.Field(Of String)("Designation")).Distinct().ToList()

                For Each factor As String In _factorList
                    For Each designation As String In designationList
                        Try
                            Dim thresholdRow As DataRow = thresholdDataTable.Select( _
                                String.Format("ThresholdTypeId='{0}' and FieldName='Density'", factor)).First()
                            Dim tonnesRow As DataRow = dataTable.Select( _
                                String.Format("ReportTagId='{0}' and Designation='{1}' and Attribute='Tonnes'", factor, designation)).First()
                            Dim densityRow As DataRow = dataTable.Select( _
                                String.Format("ReportTagId='{0}' and Designation='{1}' and Attribute='Density'", factor, designation)).First()

                            If (tonnesRow("AttributeValue") Is DBNull.Value) Or (densityRow("AttributeValue") Is DBNull.Value) Then
                                densityRow("Threshold") = "disabled"
                                Continue For
                            End If

                            tonnes = Convert.ToSingle(tonnesRow("AttributeValue"))
                            density = Convert.ToSingle(densityRow("AttributeValue"))
                            lowThreshold = Convert.ToSingle(thresholdRow("LowThreshold")) / 100 'convert to percentage
                            highThreshold = Convert.ToSingle(thresholdRow("HighThreshold")) / 100 'convert to percentage

                            If tonnes = 0 Or density = 0 Then
                                densityRow("Threshold") = "disabled"
                            ElseIf Math.Abs(1 - density) < lowThreshold Then
                                densityRow("Threshold") = "low"
                            ElseIf Math.Abs(1 - density) > lowThreshold And Math.Abs(1 - density) < highThreshold Then
                                densityRow("Threshold") = "medium"
                            Else
                                densityRow("Threshold") = "high"
                            End If

                        Catch ex As Exception
                            ' for now just ignore and go on to the next factor
                        End Try
                    Next
                Next
            Else
                For Each factor As String In _factorList
                    Try
                        Dim thresholdRow As DataRow = thresholdDataTable.Select( _
                            String.Format("ThresholdTypeId='{0}' and FieldName='Density'", factor)).First()
                        Dim tonnesRow As DataRow = dataTable.Select( _
                            String.Format("ReportTagId='{0}' and Attribute='Tonnes'", factor)).First()
                        Dim densityRow As DataRow = dataTable.Select( _
                            String.Format("ReportTagId='{0}' and Attribute='Density'", factor)).First()

                        tonnes = Convert.ToSingle(tonnesRow("AttributeValue"))
                        density = Convert.ToSingle(densityRow("AttributeValue"))
                        lowThreshold = Convert.ToSingle(thresholdRow("LowThreshold")) / 100 'convert to percentage
                        highThreshold = Convert.ToSingle(thresholdRow("HighThreshold")) / 100 'convert to percentage

                        If tonnes = 0 Or density = 0 Then
                            densityRow("Threshold") = "disabled"
                        ElseIf Math.Abs(1 - density) < lowThreshold Then
                            densityRow("Threshold") = "low"
                        ElseIf Math.Abs(1 - density) > lowThreshold And Math.Abs(1 - density) < highThreshold Then
                            densityRow("Threshold") = "medium"
                        Else
                            densityRow("Threshold") = "high"
                        End If

                    Catch ex As Exception
                        ' for now just ignore and go on to the next factor
                    End Try
                Next
            End If
        End Sub

        Private Shared Sub SetMaterialTypeDesignations(ByRef dataTable As DataTable, ByVal locationId As Int32, _
            ByVal breakdownByDesignation As Boolean, ByVal session As Types.ReportSession)

            dataTable.Columns.Add("Designation", GetType(String))

            If breakdownByDesignation Then
                Dim materialType As String
                Dim materialTypeId As Integer
                Dim materialTypeList As Dictionary(Of Integer, String) = GetDesignationList(session)

                For Each row As DataRow In dataTable.Rows
                    Try
                        materialType = row("MaterialTypeId").ToString
                        If Not String.IsNullOrEmpty(materialType) Then
                            materialTypeId = Convert.ToInt32(materialType)
                            materialType = materialTypeList(materialTypeId)
                            row("Designation") = materialType
                        Else
                            row("Designation") = String.Empty
                        End If
                    Catch
                        row("Designation") = "Unknown" ' this is not ideal, but better than no error handling at all
                    End Try
                Next
            Else
                For Each row As DataRow In dataTable.Rows
                    row("Designation") = String.Empty
                Next
            End If
        End Sub

        Private Shared Sub CalculateDensityAndSetKiloUnits(ByRef table As DataTable, ByVal breakdownByDesignation As Boolean)
            Dim tonnes, volume As Single

            If breakdownByDesignation Then

                Dim designationList = (From row In table.AsEnumerable() Select row.Field(Of String)("Designation")).Distinct().ToList()

                For Each measure As String In _supportingMeasureList
                    For Each designation As String In designationList
                        Try
                            Dim volumeRow As DataRow = table.Select( _
                                String.Format("ReportTagId='{0}' and Designation='{1}' and Attribute='Volume'", measure, designation)).First()
                            Dim tonnesRow As DataRow = table.Select( _
                                String.Format("ReportTagId='{0}' and Designation='{1}' and Attribute='Tonnes'", measure, designation)).First()
                            Dim densityRow As DataRow = table.Select( _
                                String.Format("ReportTagId='{0}' and Designation='{1}' and Attribute='Density'", measure, designation)).First()

                            tonnes = Convert.ToSingle(tonnesRow("AttributeValue"))
                            volume = Convert.ToSingle(volumeRow("AttributeValue"))

                            ' Calculate density
                            densityRow("AttributeValue") = IIf(volume = 0, 0, tonnes / volume)
                            densityRow("Attribute") = _densityHeader

                            ' Set kTonnes
                            tonnesRow("AttributeValue") = tonnes / 1000
                            tonnesRow("Attribute") = _tonnesHeader

                            ' Set kM3 (kilo cubic metres)
                            volumeRow("AttributeValue") = volume / 1000
                            volumeRow("Attribute") = _volumeHeader

                        Catch ex As Exception
                        End Try
                    Next
                Next
            Else
                For Each measure As String In _supportingMeasureList
                    Try
                        Dim volumeRow As DataRow = table.Select( _
                            String.Format("ReportTagId='{0}' and Attribute='Volume'", measure)).First()
                        Dim tonnesRow As DataRow = table.Select( _
                            String.Format("ReportTagId='{0}' and Attribute='Tonnes'", measure)).First()
                        Dim densityRow As DataRow = table.Select( _
                            String.Format("ReportTagId='{0}' and Attribute='Density'", measure)).First()

                        tonnes = Convert.ToSingle(tonnesRow("AttributeValue"))
                        volume = Convert.ToSingle(volumeRow("AttributeValue"))

                        ' Calculate density
                        densityRow("AttributeValue") = IIf(volume = 0, 0, tonnes / volume)
                        densityRow("Attribute") = _densityHeader

                        ' Set kTonnes
                        tonnesRow("AttributeValue") = tonnes / 1000
                        tonnesRow("Attribute") = _tonnesHeader

                        ' Set kM3 (kilo cubic metres)
                        volumeRow("AttributeValue") = volume / 1000
                        volumeRow("Attribute") = _volumeHeader

                    Catch ex As Exception
                    End Try
                Next
            End If
        End Sub

    End Class

End Namespace