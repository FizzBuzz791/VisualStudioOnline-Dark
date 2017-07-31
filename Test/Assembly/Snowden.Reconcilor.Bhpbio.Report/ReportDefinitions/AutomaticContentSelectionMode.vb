Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Core

Namespace ReportDefinition
    Public Class AutomaticContentSelectionMode
        Inherits AutomaticContentSelectionModeBase

        Dim _utility As IUtility
        Dim _combinationOfInterestIdentifier As ICombinationOfInterestIdentifier
        Private Const LOCATION_ID As String = "Location_Id"
        Private Const NAME As String = "Name"

        Sub New(gradeDictionary As Dictionary(Of String, Grade), utility As IUtility, combinationOfInterestIdentifier As ICombinationOfInterestIdentifier)
            MyBase.New(gradeDictionary)
            _utility = utility
            _combinationOfInterestIdentifier = combinationOfInterestIdentifier
        End Sub

        Public Overrides Function BuildCompactDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable
            Return BuildMainDataTable(dataTable, locationId, locationName, dateBreakdown, periodStart, factor, COMPACT)
        End Function

        Public Overrides Function BuildExpandedDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable
            Dim insertPosition As Integer = 1
            Dim analytesToCheck As List(Of String)
            Dim analyteList As List(Of String)
            Dim childLocationId As Integer
            Dim childLocationName As String
            Dim endDate = GetEndDate(periodStart, dateBreakdown)
            Dim childLocations = GetChildLocations(locationId, periodStart, endDate)
            Dim dt = BuildMainDataTable(dataTable, locationId, locationName, dateBreakdown, periodStart, factor, EXPANDED)
            Dim childRows As List(Of DataRow)
            'Dim parentRow As DataRow = dataTable.Rows(0)
            Dim calcId As String = GetFirstCalcId(factor)

            analytesToCheck = GetAttributes(dataTable, MAIN, calcId, locationId)
            Dim analytes = _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(locationId, dateBreakdown, periodStart, calcId, analytesToCheck)

            For Each row As DataRow In childLocations.Rows
                childLocationId = CInt(row(LOCATION_ID))
                childLocationName = CStr(row(NAME))

                If analytes.Count > 0 Then
                    Dim whereResults = analytes.Where(Function(x) x.LocationId.Equals(childLocationId))
                    analyteList = whereResults.Select(Function(x) x.Analyte).ToList()
                    childRows = PopulateRow(dt, childLocationId, childLocationName, SUBLOC, calcId, EXPANDED, analyteList)
                    For Each childRow As DataRow In childRows
                        dt.Rows.InsertAt(childRow, insertPosition)
                        insertPosition += 1
                    Next
                End If
            Next

            Return dt
        End Function

        Private Function GetChildLocations(locationId As Integer, startDate As DateTime, endDate As DateTime) As DataTable
            Return _utility.GetBhpbioLocationChildrenNameWithOverride(locationId, startDate, endDate)
        End Function

        Private Function GetAnalytesOfInterest(locationId As Integer, dateBreakdown As ReportBreakdown, periodStart As Date, calcId As String) As List(Of String)
            Dim combinationsOfInterestByOutlier As List(Of CombinationOfInterest)
            Dim combinationsOfInterestByFactorThreshold As List(Of CombinationOfInterest)

            combinationsOfInterestByOutlier = _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(locationId, dateBreakdown, periodStart, calcId, _attributes)
            combinationsOfInterestByFactorThreshold = _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(locationId, dateBreakdown, periodStart, calcId, _attributes)

            Dim returnList = combinationsOfInterestByOutlier.Select(Function(x) x.Analyte).ToList()
            returnList.AddRange(combinationsOfInterestByFactorThreshold.Select(Function(x) x.Analyte).ToList())

            Return returnList.Distinct().ToList()

        End Function

        Private Function BuildMainDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum, mode As String) As DataTable
            Dim tonnes As Boolean = False
            Dim fe As Boolean = False
            Dim p As Boolean = False
            Dim sio2 As Boolean = False
            Dim al2o3 As Boolean = False
            Dim loi As Boolean = False
            Dim rows As List(Of DataRow)
            Dim firstCalcId As String = GetFirstCalcId(factor)
            Dim secondCalcId As String = GetSecondCalcId(factor)

            Dim analytesToInclude As List(Of String)

            analytesToInclude = GetAnalytesOfInterest(locationId, dateBreakdown, periodStart, firstCalcId)
            rows = PopulateRow(dataTable, locationId, locationName, MAIN, firstCalcId, mode, analytesToInclude)
            AddRows(dataTable, rows)

            analytesToInclude = GetAnalytesOfInterest(locationId, dateBreakdown, periodStart, secondCalcId)
            rows = PopulateRow(dataTable, locationId, locationName, MAIN, secondCalcId, mode, analytesToInclude)
            AddRows(dataTable, rows)

            If (factor = AutomaticContentSelectionModeFactorEnum.F1F2F3) Then
                Dim thirdCalcid As String = GetThirdCalcId()
                analytesToInclude = GetAnalytesOfInterest(locationId, dateBreakdown, periodStart, thirdCalcid)
                rows = PopulateRow(dataTable, locationId, locationName, MAIN, thirdCalcid, mode, analytesToInclude)
                AddRows(dataTable, rows)
            End If

            Return dataTable
        End Function
    End Class
End Namespace
