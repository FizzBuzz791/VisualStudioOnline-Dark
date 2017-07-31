Imports System.Collections.Generic
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports NSubstitute

<TestClass()> Public Class CombinationOfInterestIdentifierTests

    Private Const _testLocationId As Integer = 9
    Private ReadOnly _testMonthMonthly As New Date(2012, 8, 1)
    Private ReadOnly _testMonthQuarterly As New Date(2012, 7, 1)
    Private _testAnalyteList As New List(Of String)({"Tonnes", "Fe", "Al2O3", "Density"})
    Private Const _testNumberOfContributors As Integer = 2
    Private Const _testMinimumContribution As Double = 0.1

    Private _reportSession As Types.ReportSession
    Dim _identifier As CombinationOfInterestIdentifier

    <TestInitialize>
    Public Sub InitalizeTests()
        _reportSession = IntegrationTestsHelper.CreateReportSession()
        _identifier = New CombinationOfInterestIdentifier(_reportSession, _testNumberOfContributors, _testMinimumContribution)
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByOutlier_Monthly_CombinationsOfInterestAreReturned()
        Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByOutlier(_testLocationId, Types.ReportBreakdown.Monthly, _testMonthMonthly, Calc.F1.CalculationId, _testAnalyteList)

        ' The combinations of interest are only asserted to be valid according to initial criteria.. this test does not verify the outlier calculation
        AssertCombinationsOfInterestListContainsValidMembers(Calc.F1.CalculationId, _testMonthMonthly, combinationsOfInterest)
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByOutlier_AllBreakdownsOtherThanMonthly_NoCombinationsOfInterestAreReturned()
        Dim breakdowns As New List(Of Types.ReportBreakdown)({Types.ReportBreakdown.CalendarQuarter, Types.ReportBreakdown.None, Types.ReportBreakdown.Yearly})

        For Each breakown In breakdowns
            Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByOutlier(_testLocationId, breakown, _testMonthQuarterly, Calc.F1.CalculationId, _testAnalyteList)

            Assert.IsNotNull(combinationsOfInterest, String.Format("A non-null list of combinations of interest was expected for breakdown {0}", breakdowns.ToString()))
            Assert.AreEqual(0, combinationsOfInterest.Count, String.Format("An empty list of combinations of interest was expected when run for  for breakdown {0}", breakdowns.ToString()))
        Next
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByFactorThreshold_Monthly_CombinationsOfInterestAreReturned()

        Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByFactorThreshold(_testLocationId, Types.ReportBreakdown.Monthly, _testMonthMonthly, Calc.F1.CalculationId, _testAnalyteList)

        ' The combinations of interest are only asserted to be valid according to initial criteria.. this test does not verify the outlier calculation
        AssertCombinationsOfInterestListContainsValidMembers(Calc.F1.CalculationId, _testMonthMonthly, combinationsOfInterest, assertLocationIdEqualsTestId:=True, assertLocationIdNotEqualsTestId:=False)
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByFactorThreshold_Quarterly_CombinationsOfInterestAreReturned()

        Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByFactorThreshold(_testLocationId, Types.ReportBreakdown.CalendarQuarter, _testMonthQuarterly, Calc.F1.CalculationId, _testAnalyteList)

        ' The combinations of interest are only asserted to be valid according to initial criteria.. this test does not verify the outlier calculation
        AssertCombinationsOfInterestListContainsValidMembers(Calc.F1.CalculationId, _testMonthQuarterly, combinationsOfInterest, assertLocationIdEqualsTestId:=True, assertLocationIdNotEqualsTestId:=False)
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByErrorContribution_Monthly_CombinationsOfInterestAreReturned()
        Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByErrorContribution(_testLocationId, Types.ReportBreakdown.Monthly, _testMonthMonthly, Calc.F1.CalculationId, _testAnalyteList)

        ' The combinations of interest are only asserted to be valid according to initial criteria.. this test does not verify the outlier calculation
        AssertCombinationsOfInterestListContainsValidMembers(Calc.F1.CalculationId, _testMonthMonthly, combinationsOfInterest, assertLocationIdEqualsTestId:=False, assertLocationIdNotEqualsTestId:=True)
    End Sub

    <TestMethod()> Public Sub GetCombinationsOfInterestByErrorContribution_Quarterly_CombinationsOfInterestAreReturned()
        Dim combinationsOfInterest = _identifier.GetCombinationsOfInterestByErrorContribution(_testLocationId, Types.ReportBreakdown.CalendarQuarter, _testMonthQuarterly, Calc.F1.CalculationId, _testAnalyteList)

        ' The combinations of interest are only asserted to be valid according to initial criteria.. this test does not verify the outlier calculation
        AssertCombinationsOfInterestListContainsValidMembers(Calc.F1.CalculationId, _testMonthQuarterly, combinationsOfInterest, assertLocationIdEqualsTestId:=False, assertLocationIdNotEqualsTestId:=True)
    End Sub

    Private Sub AssertCombinationsOfInterestListContainsValidMembers(ByVal calculationId As String, ByVal expectedMonth As DateTime, ByRef combinationsOfInterest As List(Of CombinationOfInterest), Optional ByVal assertLocationIdEqualsTestId As Boolean = True, Optional ByVal assertLocationIdNotEqualsTestId As Boolean = False)
        Assert.IsNotNull(combinationsOfInterest, "A non-null list of combinations of interest was expected")

        Assert.IsTrue(combinationsOfInterest.Count > 0, "A non-empty list of combinations of interest was expected")

        Dim index As Integer = 0
        For Each combinationOfInterest In combinationsOfInterest
            index = index + 1
            Assert.AreEqual(expectedMonth, combinationOfInterest.PeriodStart, String.Format("CombinationOfInterest at index {0} did not have the expected month", index))
            If (assertLocationIdEqualsTestId) Then
                Assert.AreEqual(_testLocationId, combinationOfInterest.LocationId, String.Format("CombinationOfInterest at index {0} did not have the expected location Id", index))
            End If
            If (assertLocationIdNotEqualsTestId) Then
                Assert.AreNotEqual(_testLocationId, combinationOfInterest.LocationId, String.Format("CombinationOfInterest at index {0} had a location Id that was NOT expected", index))
            End If

            Assert.AreEqual(calculationId, combinationOfInterest.CalculationId, String.Format("CombinationOfInterest at index {0} did not have the expected month", index))
            Assert.IsTrue(_testAnalyteList.Contains(combinationOfInterest.Analyte), String.Format("CombinationOfInterest at index {0} did not have an analyte that is a member of the set of analytes ins scope", index))
        Next
    End Sub

End Class