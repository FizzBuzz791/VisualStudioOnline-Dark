Imports System.Collections.Generic
Imports System.Data
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinition
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Imports NSubstitute
Imports Snowden.Reconcilor.Bhpbio.Report

<TestClass()> Public Class AutomaticContentSelectionModeTests

    Const TONNES_COLUMN As String = "Tonnes"
    Const FE_COLUMN As String = "Fe"
    Const P_COLUMN As String = "P"
    Const SIO2_COLUMN As String = "SiO2"
    Const AL2O3_COLUMN As String = "Al2O3"
    Const LOI_COLUMN As String = "LOI"
    Const CSV_COLUMN As String = "Csv"
    Const XML_COLUMN As String = "Xml"
    Const CSV As String = "Tonnes,Fe,P,SiO2,Al2O3,LOI"
    Const XML As String = "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""1"" name=""Fe""/><Attribute id=""2"" name=""P""/><Attribute id=""3"" name=""SiO2""/><Attribute id=""4"" name=""Al2O3""/><Attribute id=""5"" name=""LOI""/></Attributes>"
    Const EMPTYATTRIBUTES = "<Attributes></Attributes>"
    Const FILTER = "{0} = {1} and {2} = '{3}' and {4} = '{5}' and {6} = '{7}' and {8} = '{9}'"
    Private _acsm As IAutomaticContentSelectionMode
    Private _gradeDictionary As Dictionary(Of String, Grade)
    Private _utility As IUtility
    Private _monthPeriodStart As DateTime
    Private _monthPeriodEnd As DateTime
    Private _analyteList As List(Of String)
    Private _emptyCOIList As List(Of CombinationOfInterest)
    Private _combinationOfInterestIdentifier As ICombinationOfInterestIdentifier


    <TestInitialize>
    Public Sub InitializeTests()

        _monthPeriodStart = New DateTime(2016, 1, 1)
        _monthPeriodEnd = _monthPeriodStart.AddMonths(1).AddDays(-1)
        _emptyCOIList = New List(Of CombinationOfInterest)

        _gradeDictionary = AttributeHelperTestsHelper.BuildGradeDictionary()

        _utility = Substitute.For(Of IUtility)

        _utility.GetBhpbioLocationChildrenNameWithOverride(Arg.Any(Of Integer), Arg.Any(Of DateTime), Arg.Any(Of DateTime)).Returns(BuildEmptyChildSitesDataTable())
        _utility.GetBhpbioLocationChildrenNameWithOverride(9, Arg.Any(Of DateTime), Arg.Any(Of DateTime)).Returns(BuildChildLocationDataTableSite())
        _utility.GetBhpbioLocationChildrenNameWithOverride(8, Arg.Any(Of DateTime), Arg.Any(Of DateTime)).Returns(BuildChildLocationDataTableHub())

        _combinationOfInterestIdentifier = Substitute.For(Of ICombinationOfInterestIdentifier)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Arg.Any(Of String), Arg.Any(Of List(Of String))).Returns(_emptyCOIList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Arg.Any(Of String), Arg.Any(Of List(Of String))).Returns(_emptyCOIList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Arg.Any(Of String), Arg.Any(Of List(Of String))).Returns(_emptyCOIList)
        _analyteList = CSV.Split(",").ToList()

        _acsm = New ReportDefinition.AutomaticContentSelectionMode(_gradeDictionary, _utility, _combinationOfInterestIdentifier)

    End Sub

#Region "Generic Tests"
    <TestMethod()> Public Sub DoesTableContainRequiredColumns()
        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.NONE)

        Assert.AreEqual(dataTable.Columns.Count, 7, "Number of columns returned wasn't 12")

        Assert.IsTrue(dataTable.Columns.Contains("LocationId"), "LocationId was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("LocationName"), "LocationId was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("LocationType"), "LocationType was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("Factor"), "Factor was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("Mode"), "Mode was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("Attribute"), "Attribute was not found in the columns collection")
        Assert.IsTrue(dataTable.Columns.Contains("Xml"), "Xml was not found in the columns collection")
    End Sub

    <TestMethod()>
    Public Sub DoesInvalidFactorArgumentThrowException()
        Try
            Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "XXX", AutomaticContentSelectionMode.NONE)

            Assert.Fail("No exception was thrown.")
        Catch ex As ArgumentException
            Assert.AreEqual(ex.Message, "Factor option should be ""F1,F2"" or ""F15,RFSTM"".", "Wrong Message was returned")
        Catch ex As Exception
            Assert.Fail("Wrong exception was thrown.")
        End Try
    End Sub

    <TestMethod()>
    Public Sub DoesInvalidModeThrowException()
        Try
            Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", "XXX")

            Assert.Fail("No exception was thrown.")
        Catch ex As ArgumentException
            Assert.AreEqual(ex.Message, "Automatic Content Selection Mode should be ""None"", ""Compact"" or ""Expanded"".", "Wrong Message was returned")
        Catch ex As Exception
            Assert.Fail("Wrong exception was thrown.")
        End Try
    End Sub
#End Region

#Region "None Tests"
    <TestMethod()>
    Public Sub Does_GetDataTable_None_F1F2_ReturnCorrectly()
        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.NONE)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.NONE, CSV, XML)

    End Sub

    <TestMethod()>
    Public Sub Does_GetDataTable_None_F15RFSTM_ReturnCorrectly()
        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.NONE)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.NONE, CSV, XML)

    End Sub

    <TestMethod()>
    Public Sub Does_GetDataTable_None_F1F2F3_ReturnCorrectly()
        Dim dataTable = _acsm.GetDataTable(8, "NJV", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2,F3", AutomaticContentSelectionMode.NONE)

        Assert.AreEqual(19, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F3Factor", AutomaticContentSelectionMode.NONE, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1,F2,F3", AutomaticContentSelectionMode.NONE, CSV, XML)
    End Sub

#End Region

#Region "Compact Tests"

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_All_False()
        Dim dataTable = _acsm.GetDataTable(8, "NJV", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(1, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_All_False()

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(1, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, "", EMPTYATTRIBUTES)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_All_GetCombinationsOfInterestByOutlier()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_All_GetCombinationsOfInterestByOutlier()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_All_GetCombinationsOfInterestByFactorThreshold()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_All_GetCombinationsOfInterestByFactorThreshold()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_All_True()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_All_True()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_Only_F15_True()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(7, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_Only_F15_True()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(7, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_Only_F2_True()
        Dim returnList As New List(Of CombinationOfInterest)


        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(7, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_Only_RFSTM_True()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(7, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_And_Row1CombinationsOfInterestByFactorThreshold()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_And_Row1CombinationsOfInterestByFactorThreshold()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, False, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_And_Row2CombinationsOfInterestByFactorThreshold()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, False, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_And_Row2CombinationsOfInterestByFactorThreshold()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, False, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, True, False, False, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F1F2_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_Tonnes_And_Row2CombinationsOfInterestByFactorThreshold_P()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F2.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F2.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, False, False, True, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_BuildCompactDataTable_Return_F15RFSTM_Correctly_When_Single_Row1CombinationsOfInterestByOutlier_Tonnes_And_Row2CombinationsOfInterestByFactorThreshold_P()
        Dim returnList As New List(Of CombinationOfInterest)

        returnList = BuildReturnList(Calc.F15.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F15.CalculationId, 9, "Tonnes".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, "P".Split(",").ToList(), _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(3, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.COMPACT, True, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.COMPACT, False, False, True, False, False, False)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.COMPACT, "Tonnes,P", "<Attributes><Attribute id=""0"" name=""Tonnes""/><Attribute id=""2"" name=""P""/></Attributes>")
    End Sub

    <TestMethod()>
    Public Sub Does_GetDataTable_Compact_F1F2F3_ReturnCorrectly()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 8, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F2.CalculationId, 8, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F3.CalculationId, 8, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F3.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F3.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(8, "NJV", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2,F3", AutomaticContentSelectionMode.COMPACT)

        Assert.AreEqual(19, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F3Factor", AutomaticContentSelectionMode.COMPACT, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1,F2,F3", AutomaticContentSelectionMode.COMPACT, CSV, XML)
    End Sub
#End Region

#Region "Expanded Tests"
    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Call_Dal_GetBhpbioLocationChildrenNameWithOverride()
        Dim returnList = New List(Of CombinationOfInterest)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Arg.Any(Of String), Arg.Any(Of List(Of String))).Returns(returnList)

        _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        _utility.Received().GetBhpbioLocationChildrenNameWithOverride(9, _monthPeriodStart, _monthPeriodEnd)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_No_ChildRows()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(13, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F1_ChildRows()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList.AddRange(BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 32272, "Tonnes".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28438, "P".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28424, "Al2O3".Split(",").ToList(), _monthPeriodEnd))

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(16, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, False, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, False, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F15_ChildRows()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 32272, "Tonnes".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28438, "P".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28424, "Al2O3".Split(",").ToList(), _monthPeriodEnd))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(16, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, False, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, False, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Call_GetCombinationsOfInterestByOutlier_Correctly_Return_F1_ChildRows()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)


        Dim list As List(Of String) = CSV.Split(",").ToList
        _combinationOfInterestIdentifier.Received().GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(list)))

        _combinationOfInterestIdentifier.DidNotReceive().GetCombinationsOfInterestByErrorContribution(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList)))
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Call_GetCombinationsOfInterestByOutlier_Correctly_Return_F15_ChildRows()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED)

        Dim list As List(Of String) = CSV.Split(",").ToList
        _combinationOfInterestIdentifier.Received().GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(list)))

        _combinationOfInterestIdentifier.DidNotReceive().GetCombinationsOfInterestByErrorContribution(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList)))
    End Sub


    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F1_ChildRows_Scenario2()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 32272, "Tonnes,P".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28438, "Tonnes,P,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28424, "Tonnes,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(20, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, True, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F15_ChildRows_Scenario2()
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F15.CalculationId, 32272, "Tonnes,P".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F15.CalculationId, 28438, "Tonnes,P,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F15.CalculationId, 28424, "Tonnes,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(20, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, True, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED, CSV, XML)

    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Call_GetCombinationsOfInterestByErrorContribution_Only_When_Parent_Analytes_Are_True()

        Dim listToCheck = "Tonnes,P,Al2O3".Split(",").ToList
        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, listToCheck, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        _combinationOfInterestIdentifier.Received().GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(listToCheck)))

        _combinationOfInterestIdentifier.DidNotReceive().GetCombinationsOfInterestByErrorContribution(Arg.Any(Of Integer), Arg.Any(Of Types.ReportBreakdown), Arg.Any(Of DateTime), Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList)))

    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F1_ChildRows_Scenario3()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F2.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F2.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F1.CalculationId, 32272, "Tonnes,P".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28438, "Tonnes,P,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F1.CalculationId, 28424, "Tonnes,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F1.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(20, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, True, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F1Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F1,F2", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod>
    Public Sub Does_BuildExpandedDataTable_Return_F15_ChildRows_Scenario3()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F15.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.RFSTM.CalculationId, 9, _analyteList, _monthPeriodStart)
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByOutlier(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.RFSTM.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        returnList = BuildReturnList(Calc.F15.CalculationId, 32272, "Tonnes,P".Split(",").ToList(), _monthPeriodEnd)
        returnList.AddRange(BuildReturnList(Calc.F15.CalculationId, 28438, "Tonnes,P,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        returnList.AddRange(BuildReturnList(Calc.F15.CalculationId, 28424, "Tonnes,Al2O3".Split(",").ToList(), _monthPeriodEnd))
        _combinationOfInterestIdentifier.GetCombinationsOfInterestByErrorContribution(9, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F15.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(9, "Newman", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(20, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertDataIsEqual(dataTable, 32272, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, False, False)

        AssertDataIsEqual(dataTable, 28438, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, True, False, True, False)

        AssertDataIsEqual(dataTable, 28424, AutomaticContentSelectionMode.SUBLOC, "F15Factor", AutomaticContentSelectionMode.EXPANDED, True, False, False, False, True, False)

        AssertDataIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "RFSTM", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 9, AutomaticContentSelectionMode.MAIN, "F15,RFSTM", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

    <TestMethod()>
    Public Sub Does_GetDataTable_Expanded_F1F2F3_ReturnCorrectly()

        Dim returnList As New List(Of CombinationOfInterest)
        returnList = BuildReturnList(Calc.F1.CalculationId, 9, _analyteList, _monthPeriodStart)

        _combinationOfInterestIdentifier.GetCombinationsOfInterestByFactorThreshold(8, Types.ReportBreakdown.Monthly, _monthPeriodStart, Calc.F3.CalculationId, Arg.Is(Of List(Of String))(Function(x) x.SequenceEqual(_analyteList))).Returns(returnList)

        Dim dataTable = _acsm.GetDataTable(8, "NJV", Types.ReportBreakdown.Monthly, _monthPeriodStart, "F1,F2,F3", AutomaticContentSelectionMode.EXPANDED)

        Assert.AreEqual(7, dataTable.Rows.Count)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1Factor", AutomaticContentSelectionMode.EXPANDED, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F2Factor", AutomaticContentSelectionMode.EXPANDED, False, False, False, False, False, False)

        AssertDataIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F3Factor", AutomaticContentSelectionMode.EXPANDED, True, True, True, True, True, True)

        AssertTrendIsEqual(dataTable, 8, AutomaticContentSelectionMode.MAIN, "F1,F2,F3", AutomaticContentSelectionMode.EXPANDED, CSV, XML)
    End Sub

#End Region
#Region "Helper Methods"
    Private Sub AssertDataIsEqual(dataTable As DataTable, locationId As Integer, locationType As String, factor As String, mode As String, tonnes As Boolean, fe As Boolean, p As Boolean, sio2 As Boolean, al2o3 As Boolean, loi As Boolean)
        AssertSearchString(dataTable, locationId, locationType, factor, mode, tonnes, "Tonnes")
        AssertSearchString(dataTable, locationId, locationType, factor, mode, fe, "Fe")
        AssertSearchString(dataTable, locationId, locationType, factor, mode, p, "P")
        AssertSearchString(dataTable, locationId, locationType, factor, mode, sio2, "SiO2")
        AssertSearchString(dataTable, locationId, locationType, factor, mode, al2o3, "Al2O3")
        AssertSearchString(dataTable, locationId, locationType, factor, mode, loi, "LOI")



        'Assert.AreEqual(locationId, row(AutomaticContentSelectionMode.LOCATIONID_COLUMN), "LocationId column")
        'Assert.AreEqual(locationType, row(AutomaticContentSelectionMode.LOCATIONTYPE_COLUMN), "LocationType column")
        'Assert.AreEqual(factor, row(AutomaticContentSelectionMode.FACTOR_COLUMN), "Factor column")
        'Assert.AreEqual(mode, row(AutomaticContentSelectionMode.MODE_COLUMN), "Mode column")

        'Assert.AreEqual(tonnes, row(TONNES_COLUMN), "Tonnes column")
        'Assert.AreEqual(fe, row(FE_COLUMN), "Fe column")
        'Assert.AreEqual(p, row(P_COLUMN), "P column")
        'Assert.AreEqual(sio2, row(SIO2_COLUMN), "SiO2 column")
        'Assert.AreEqual(al2o3, row(AL2O3_COLUMN), "Al2O3 column")
        'Assert.AreEqual(loi, row(LOI_COLUMN), "LOI column")

        'Assert.AreEqual(csv, row(CSV_COLUMN), "Csv column")
        'Assert.AreEqual(xml, row(XML_COLUMN), "Xml column")
    End Sub

    Private Sub AssertTrendIsEqual(dataTable As DataTable, locationId As Integer, locationType As String, factor As String, mode As String, csv As String, xml As String)
        Dim foundRows() As DataRow
        Dim searchString As String

        searchString = String.Format(FILTER, AutomaticContentSelectionMode.LOCATIONID_COLUMN, locationId, AutomaticContentSelectionMode.LOCATIONTYPE_COLUMN, locationType, AutomaticContentSelectionMode.FACTOR_COLUMN, factor, AutomaticContentSelectionMode.MODE_COLUMN, mode, AutomaticContentSelectionMode.ATTRIBUTE_COLUMN, csv)
        foundRows = dataTable.Select(searchString)

        Assert.AreEqual(1, foundRows.Count, String.Format("Expected a single foundRow for {0}", "Trend Row"))
        Assert.AreEqual(GetLocationName(foundRows.First()(AutomaticContentSelectionMode.LOCATIONID_COLUMN)), foundRows.First()(AutomaticContentSelectionMode.LOCATIONNAME_COLUMN))
        Assert.AreEqual(csv, CStr(foundRows.First()(AutomaticContentSelectionMode.ATTRIBUTE_COLUMN)), "CSV")
        Assert.AreEqual(xml, CStr(foundRows.First()(AutomaticContentSelectionMode.XML_COLUMN)), "XML")

    End Sub


    Private Sub AssertSearchString(dataTable As DataTable, locationId As Integer, locationType As String, factor As String, mode As String, expectedValue As Boolean, attribute As String)
        Dim foundRows() As DataRow
        Dim searchString As String

        searchString = String.Format(FILTER, AutomaticContentSelectionMode.LOCATIONID_COLUMN, locationId, AutomaticContentSelectionMode.LOCATIONTYPE_COLUMN, locationType, AutomaticContentSelectionMode.FACTOR_COLUMN, factor, AutomaticContentSelectionMode.MODE_COLUMN, mode, AutomaticContentSelectionMode.ATTRIBUTE_COLUMN, attribute)
        foundRows = dataTable.Select(searchString)

        If foundRows.Count > 1 Then
            Assert.Fail("Too many rows found")
        End If

        If (expectedValue) Then
            Assert.AreEqual(1, foundRows.Count, String.Format("Expected a single foundRow for {0}", attribute))
            Assert.AreEqual(expectedValue, CStr(foundRows.First()(AutomaticContentSelectionMode.ATTRIBUTE_COLUMN)) = attribute)
        Else
            Assert.AreEqual(0, foundRows.Count, String.Format("Expected no found rows for {0}", attribute))
        End If
    End Sub


    Private Function BuildReturnList(calculationId As String, locationId As Integer, analyteList As List(Of String), monthPeriodStart As Date) As IEnumerable(Of CombinationOfInterest)
        Dim returnList As New List(Of CombinationOfInterest)
        For Each analyte As String In analyteList
            returnList.Add(New CombinationOfInterest(calculationId, locationId, analyte, monthPeriodStart))
        Next

        Return returnList
    End Function

    Private Function BuildChildLocationDataTableSite() As DataTable
        Dim dt = BuildEmptyChildSitesDataTable()
        Dim row As DataRow
        row = dt.NewRow
        row.ItemArray = "32272,29,Pit".Split(",")
        dt.Rows.Add(row)

        row = dt.NewRow
        row.ItemArray = "28438,30,Pit".Split(",")
        dt.Rows.Add(row)

        row = dt.NewRow
        row.ItemArray = "137037,35,Pit".Split(",")
        dt.Rows.Add(row)

        row = dt.NewRow
        row.ItemArray = "28424,WB,Pit".Split(",")
        dt.Rows.Add(row)

        dt.AcceptChanges()

        Return dt
    End Function

    Private Function BuildChildLocationDataTableHub() As DataTable
        Dim dt = BuildEmptyChildSitesDataTable()
        Dim row As DataRow
        row = dt.NewRow
        row.ItemArray = "11,Eastern Ridge,Site".Split(",")
        dt.Rows.Add(row)

        row = dt.NewRow
        row.ItemArray = "9,Newman,Site".Split(",")
        dt.Rows.Add(row)

        row = dt.NewRow
        row.ItemArray = "10,OB18,Site".Split(",")
        dt.Rows.Add(row)

        dt.AcceptChanges()

        Return dt
    End Function

    Private Function BuildEmptyChildSitesDataTable() As DataTable
        Dim dt = New DataTable
        dt.Columns.Add("Location_Id", GetType(Integer))
        dt.Columns.Add("Name", GetType(String))
        dt.Columns.Add("Location_Type_Description", GetType(String))
        dt.TableName = "dbo.GetBhpbioLocationChildrenNameWithOverride"
        dt.AcceptChanges()

        Return dt
    End Function

    Private Function GetLocationName(locationId As Integer) As String
        Dim name

        Select Case locationId
            Case 8
                name = "NJV"
            Case 9
                name = "Newman"
            Case 28424
                name = "WB"
            Case 28438
                name = "30"
            Case 32272
                name = "29"
            Case 137037
                name = "35"
            Case Else
                name = "Unknown"
        End Select

        Return name
    End Function

#End Region
End Class