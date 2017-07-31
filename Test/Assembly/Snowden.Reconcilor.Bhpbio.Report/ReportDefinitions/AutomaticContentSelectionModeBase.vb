Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Core

Namespace ReportDefinition
    Public MustInherit Class AutomaticContentSelectionModeBase
        Implements IAutomaticContentSelectionMode

        Public Const F1F2Factor As String = "F1,F2"
        Public Const F15RFSTMFACTOR As String = "F15,RFSTM"
        Public Const F1F2F3Factor As String = "F1,F2,F3"

        Public Const LOCATIONID_COLUMN As String = "LocationId"
        Public Const LOCATIONNAME_COLUMN As String = "LocationName"
        Public Const LOCATIONTYPE_COLUMN As String = "LocationType"
        Public Const FACTOR_COLUMN As String = "Factor"
        Public Const MODE_COLUMN As String = "Mode"
        Public Const ATTRIBUTE_COLUMN As String = "Attribute"
        Public Const TREND_COLUMN As String = "Trend"
        Public Const XML_COLUMN As String = "Xml"

        Public Const NONE As String = "None"
        Public Const COMPACT As String = "Compact"
        Public Const EXPANDED As String = "Expanded"

        Public Const MAIN As String = "Main"
        Public Const SUBLOC As String = "SubLocation"

        Protected _gradeDictionary As Dictionary(Of String, Grade)
        Protected _attributes As List(Of String)

        Sub New(gradeDictionary As Dictionary(Of String, Grade))
            _gradeDictionary = gradeDictionary
            _attributes = GetAttributes()
        End Sub

        Public Function IAutomaticContentSelectionMode_GetDataTable(ByVal locationId As Int32, ByVal locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factorOption As String, automaticContentSelectionMode As String) As DataTable Implements IAutomaticContentSelectionMode.GetDataTable
            Dim dataTable As New DataTable
            Dim factor As AutomaticContentSelectionModeFactorEnum
            Dim factorRfstm As Boolean = False
            Dim mode As String

            Select Case factorOption
                Case F1F2Factor
                    factor = AutomaticContentSelectionModeFactorEnum.F1F2
                Case F15RFSTMFACTOR
                    factor = AutomaticContentSelectionModeFactorEnum.F15RFSTM
                Case F1F2F3Factor
                    factor = AutomaticContentSelectionModeFactorEnum.F1F2F3
                Case Else
                    Throw New ArgumentException(String.Format("Factor option should be ""{0}"" or ""{1}"".", F1F2Factor, F15RFSTMFACTOR))
            End Select

            AddColumns(dataTable)

            Select Case automaticContentSelectionMode.ToLower
                Case NONE.ToLower
                    dataTable = BuildNoneDataTable(dataTable, locationId, locationName, factor)
                    mode = NONE
                Case COMPACT.ToLower
                    dataTable = BuildCompactDataTable(dataTable, locationId, locationName, dateBreakdown, periodStart, factor)
                    mode = COMPACT
                Case EXPANDED.ToLower
                    dataTable = BuildExpandedDataTable(dataTable, locationId, locationName, dateBreakdown, periodStart, factor)
                    mode = EXPANDED
                Case Else
                    Throw New ArgumentException(String.Format("Automatic Content Selection Mode should be ""{0}"", ""{1}"" or ""{2}"".", NONE, COMPACT, EXPANDED))
            End Select

            AddTrendAnalysisRow(dataTable, locationId, locationName, factorOption, mode)

            dataTable.TableName = "PowerPointFiltering"
            dataTable.AcceptChanges()

            Return dataTable
        End Function

        Protected Sub PopulateXmlColumn(dataRow As DataRow, gradeDictionary As Dictionary(Of String, Grade))

            Dim attribute As String = dataRow(ATTRIBUTE_COLUMN).ToString()

            Dim xml = AttributeHelper.ConvertAttributeCsvToXml(attribute, gradeDictionary)

            dataRow(XML_COLUMN) = xml

        End Sub
        MustOverride Function BuildExpandedDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable

        MustOverride Function BuildCompactDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable

        Protected Function BuildNoneDataTable(dataTable As DataTable, locationId As Integer, locationName As String, factor As AutomaticContentSelectionModeFactorEnum) As DataTable

            Dim analytesToInclude = _attributes

            Dim rows As List(Of DataRow)
            Dim firstCalcId As String = GetFirstCalcId(factor)
            Dim secondCalcId As String = GetSecondCalcId(factor)

            rows = PopulateRow(dataTable, locationId, locationName, MAIN, firstCalcId, NONE, analytesToInclude)
            AddRows(dataTable, rows)

            rows = (PopulateRow(dataTable, locationId, locationName, MAIN, secondCalcId, NONE, analytesToInclude))
            AddRows(dataTable, rows)

            If (factor = AutomaticContentSelectionModeFactorEnum.F1F2F3) Then
                Dim thirdCalcid As String = GetThirdCalcId()
                rows = (PopulateRow(dataTable, locationId, locationName, MAIN, thirdCalcid, NONE, analytesToInclude))
                AddRows(dataTable, rows)
            End If

            Return dataTable
        End Function

        Protected Sub AddRows(dataTable As DataTable, rows As List(Of DataRow))
            For Each row As DataRow In rows
                dataTable.Rows.Add(row)
            Next
        End Sub

        Public Function GetFirstCalcId(factor As AutomaticContentSelectionModeFactorEnum) As String
            Return IIf((factor.Equals(AutomaticContentSelectionModeFactorEnum.F1F2) Or
                        factor.Equals(AutomaticContentSelectionModeFactorEnum.F1F2F3)), Calc.F1.CalculationId, Calc.F15.CalculationId).ToString()
        End Function

        Protected Function GetSecondCalcId(factor As AutomaticContentSelectionModeFactorEnum) As String
            Return IIf((factor.Equals(AutomaticContentSelectionModeFactorEnum.F1F2) Or
                        factor.Equals(AutomaticContentSelectionModeFactorEnum.F1F2F3)), Calc.F2.CalculationId, Calc.RFSTM.CalculationId).ToString()
        End Function

        Protected Function GetThirdCalcId() As String
            Return Calc.F3.CalculationId
        End Function

        Protected Function PopulateRow(dataTable As DataTable, locationId As Integer, locationName As String, locationType As String, factor As String, mode As String, analytesToInclude As List(Of String)) As List(Of DataRow)
            Dim retRows = New List(Of DataRow)
            For Each attribute As String In analytesToInclude
                retRows.Add(BuildRow(dataTable, locationId, locationName, locationType, factor, mode, attribute))
            Next
            Return retRows
        End Function

        Protected Function BuildRow(dataTable As DataTable, locationId As Integer, locationName As String, locationType As String, factor As String, mode As String, attribute As String) As DataRow
            Dim row = dataTable.NewRow

            row(LOCATIONID_COLUMN) = locationId
            row(LOCATIONNAME_COLUMN) = locationName
            row(LOCATIONTYPE_COLUMN) = locationType
            row(FACTOR_COLUMN) = factor
            row(MODE_COLUMN) = mode

            row(ATTRIBUTE_COLUMN) = attribute


            PopulateXmlColumn(row, _gradeDictionary)

            Return row

        End Function

        Protected Sub AddColumns(dataTable As DataTable)
            dataTable.Columns.Add(LOCATIONID_COLUMN, GetType(Integer))
            dataTable.Columns.Add(LOCATIONNAME_COLUMN, GetType(String))
            dataTable.Columns.Add(LOCATIONTYPE_COLUMN, GetType(String))
            dataTable.Columns.Add(FACTOR_COLUMN, GetType(String))
            dataTable.Columns.Add(MODE_COLUMN, GetType(String))

            dataTable.Columns.Add(ATTRIBUTE_COLUMN, GetType(String))
            dataTable.Columns.Add(XML_COLUMN, GetType(String))
        End Sub

        Private Function GetAttributes() As List(Of String)
            Dim columns = New List(Of String)

            columns.Add("Tonnes")
            columns.AddRange(CalculationResultRecord.StandardGradeNames.ToList())
            columns.Remove("H2O")

            Return columns
        End Function

        Public Function GetAttributes(dataTable As DataTable, locationType As String, Optional factor As String = Nothing, Optional locationId As Integer? = Nothing) As List(Of String)
            Dim analytesToInclude As List(Of String) = New List(Of String)
            For Each row As DataRow In dataTable.Rows
                If (CStr(row(LOCATIONTYPE_COLUMN))) = locationType Then
                    If (factor Is Nothing Or CStr(row(FACTOR_COLUMN)) = factor) Then
                        If (locationId Is Nothing Or locationId = CInt(row(LOCATIONID_COLUMN))) Then
                            analytesToInclude.Add(row(ATTRIBUTE_COLUMN).ToString())
                        End If
                    End If
                End If
            Next

            Return GetSortedAttributes(analytesToInclude.ToList())
        End Function

        Private Sub AddTrendAnalysisRow(dataTable As DataTable, locationId As Integer, locationName As String, factor As String, mode As String)
            Dim analytesToInclude As List(Of String) = GetAttributes(dataTable, MAIN)
            Dim sortedAnalytes As List(Of String) = GetSortedAttributes(analytesToInclude)

            dataTable.Rows.Add(BuildRow(dataTable, locationId, locationName, MAIN, factor, mode, String.Join(",", sortedAnalytes.ToArray())))
        End Sub

        Protected Function GetSortedAttributes(analytesToInclude As List(Of String)) As List(Of String)
            Dim sortedAnalytes As List(Of String) = New List(Of String)

            For Each attribute As String In _attributes
                If (analytesToInclude.Contains(attribute)) Then
                    sortedAnalytes.Add(attribute)
                End If
            Next

            Return sortedAnalytes
        End Function
    End Class

End Namespace