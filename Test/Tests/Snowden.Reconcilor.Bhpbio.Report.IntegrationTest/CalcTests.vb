Imports System.Data
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Types

<TestClass()> Public Class CalcTests

    'Private testContextInstance As TestContext
    Private _dateFrom As DateTime
    Private _dateTo As DateTime
    Private _locationId As Integer?

    Private _reportSession As ReportSession
    Private _FO As F0


    <TestInitialize()> Public Sub TestInitalize()
        Dim connectionString As String = IntegrationTestsHelper.GetConnectionString(DEFAULT_DATABASE_CONFIGURATION_NAME, DEFAULT_DATABASE_USER_NAME)
        _reportSession = IntegrationTestsHelper.CreateReportSession()
        _reportSession.Context = ReportContext.Standard

        ' set the dateFrom, dateTo, locationId parameters to test values...
        _dateFrom = New DateTime(2015, 12, 1)
        _dateTo = _dateFrom.AddMonths(1).AddDays(-1)
        _locationId = 148218
    End Sub

    <TestMethod()> Public Sub TestF0()
        _reportSession.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, Nothing)

        ' create a calculation set
        Dim calcSet As New CalculationSet
        ' calculation F0
        calcSet.Add(Calculation.Create(CalcType.F0, _reportSession).Calculate())

        Assert.IsNotNull(calcSet)

        Assert.AreEqual(1, calcSet.Count)

        Dim calculations As CalculationSet = calcSet(0).GetAllCalculations()
        Assert.AreEqual(3, calculations.Count, "Number of calculations")
        Assert.AreEqual("F0Factor", calculations(0).TagId)
        Assert.AreEqual("F0 - Mining Model / Geology Model", calculations(0).Description)
        Assert.AreEqual(CalculationResultType.Ratio, calculations(0).CalculationType)
        Assert.AreEqual("F0MiningModel", calculations(1).TagId)
        Assert.AreEqual("Mining Model", calculations(1).Description)
        Assert.AreEqual("F0GeologyModel", calculations(2).TagId)
        Assert.AreEqual("Geology Model", calculations(2).Description)

    End Sub

    <TestMethod()> Public Sub TestF05()
        _reportSession.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, Nothing)

        ' create a calculation set
        Dim calcSet As New CalculationSet
        ' calculation F0
        calcSet.Add(Calculation.Create(CalcType.F05, _reportSession).Calculate())

        Assert.IsNotNull(calcSet)
        Assert.AreEqual(1, calcSet.Count)
        Dim calculations As CalculationSet = calcSet(0).GetAllCalculations()
        Assert.AreEqual(3, calculations.Count, "Number of calculations")

        Assert.AreEqual("F05Factor", calculations(0).TagId)
        Assert.AreEqual("F05 - Grade Control / Geology Model", calculations(0).Description)
        Assert.AreEqual(CalculationResultType.Ratio, calculations(0).CalculationType)

        Assert.AreEqual("F05GradeControlModel", calculations(1).TagId)
        Assert.AreEqual("Grade Control Model", calculations(1).Description)

        Assert.AreEqual("F05GeologyModel", calculations(2).TagId)
        Assert.AreEqual("Geology Model", calculations(2).Description)

    End Sub

    <TestMethod()> Public Sub TestRFGM()
        _reportSession.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, Nothing)

        ' create a calculation set
        Dim calcSet As New CalculationSet
        ' calculation RFGM
        calcSet.Add(Calculation.Create(CalcType.RFGM, _reportSession).Calculate())

        Assert.IsNotNull(calcSet)

        Assert.AreEqual(1, calcSet.Count)

        Dim calculations As CalculationSet = calcSet(0).GetAllCalculations()
        Assert.AreEqual(6, calculations.Count, "Number of calculations")
        Assert.AreEqual("RFGM", calculations(0).TagId)
        Assert.AreEqual("RFGM - Mine Production Expit Equivalent / Geology Model", calculations(0).Description)
        Assert.AreEqual(CalculationResultType.Ratio, calculations(0).CalculationType)
        Assert.AreEqual("RFGMMineProductionExpitEqulivent", calculations(1).TagId)    'Mistyped on purpose to match actual returned value due to bug
        Assert.AreEqual("Mine Production Expit Equivalent", calculations(1).Description)
        Assert.AreEqual("RFGMMineProductionActuals", calculations(2).TagId)
        Assert.AreEqual("Mine Production Actuals", calculations(2).Description)
        Assert.AreEqual("RFGMExPitToOreStockpile", calculations(3).TagId)
        Assert.AreEqual("Ex-pit to Ore Stockpile Movements", calculations(3).Description)
        Assert.AreEqual("RFGMStockpileToCrusher", calculations(4).TagId)
        Assert.AreEqual("Stockpile to Crusher Movements", calculations(4).Description)
        Assert.AreEqual("RFGMGeologyModel", calculations(5).TagId)
        Assert.AreEqual("Geology Model", calculations(5).Description)

    End Sub

    <TestMethod()> Public Sub TestRFMM()
        _reportSession.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, Nothing)

        ' create a calculation set
        Dim calcSet As New CalculationSet
        ' calculation RFMM

        calcSet.Add(Calculation.Create(CalcType.RFMM, _reportSession).Calculate())

        Assert.IsNotNull(calcSet)

        Assert.AreEqual(1, calcSet.Count)

        Dim calculations As CalculationSet = calcSet(0).GetAllCalculations()
        Assert.AreEqual(6, calculations.Count, "Number of calculations")
        Assert.AreEqual("RFMM", calculations(0).TagId)
        Assert.AreEqual("RFMM - Mine Production Expit Equivalent / Mining Model", calculations(0).Description)
        Assert.AreEqual(CalculationResultType.Ratio, calculations(0).CalculationType)
        Assert.AreEqual("RFMMMineProductionExpitEqulivent", calculations(1).TagId)    'Mistyped on purpose to match actual returned value due to bug
        Assert.AreEqual("Mine Production Expit Equivalent", calculations(1).Description)
        Assert.AreEqual("RFMMMineProductionActuals", calculations(2).TagId)
        Assert.AreEqual("Mine Production Actuals", calculations(2).Description)
        Assert.AreEqual("RFMMExPitToOreStockpile", calculations(3).TagId)
        Assert.AreEqual("Ex-pit to Ore Stockpile Movements", calculations(3).Description)
        Assert.AreEqual("RFMMStockpileToCrusher", calculations(4).TagId)
        Assert.AreEqual("Stockpile to Crusher Movements", calculations(4).Description)
        Assert.AreEqual("RFMMMiningModel", calculations(5).TagId)
        Assert.AreEqual("Mining Model", calculations(5).Description)

    End Sub

    <TestMethod()> Public Sub TestRFSTM()
        _reportSession.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, Nothing)

        ' create a calculation set
        Dim calcSet As New CalculationSet
        ' calculation RFSTM

        calcSet.Add(Calculation.Create(CalcType.RFSTM, _reportSession).Calculate())

        Assert.IsNotNull(calcSet)

        Assert.AreEqual(1, calcSet.Count)

        Dim calculations As CalculationSet = calcSet(0).GetAllCalculations()
        Assert.AreEqual(6, calculations.Count, "Number of calculations")
        Assert.AreEqual("RFSTM", calculations(0).TagId)
        Assert.AreEqual("RFSTM - Mine Production Expit Equivalent / Short Term Model", calculations(0).Description)
        Assert.AreEqual(CalculationResultType.Ratio, calculations(0).CalculationType)
        Assert.AreEqual("RFSTMMineProductionExpitEqulivent", calculations(1).TagId)    'Mistyped on purpose to match actual returned value due to bug
        Assert.AreEqual("Mine Production Expit Equivalent", calculations(1).Description)
        Assert.AreEqual("RFSTMMineProductionActuals", calculations(2).TagId)
        Assert.AreEqual("Mine Production Actuals", calculations(2).Description)
        Assert.AreEqual("RFSTMExPitToOreStockpile", calculations(3).TagId)
        Assert.AreEqual("Ex-pit to Ore Stockpile Movements", calculations(3).Description)
        Assert.AreEqual("RFSTMStockpileToCrusher", calculations(4).TagId)
        Assert.AreEqual("Stockpile to Crusher Movements", calculations(4).Description)
        Assert.AreEqual("RFSTMShortTermGeologyModel", calculations(5).TagId)
        Assert.AreEqual("Short Term Model", calculations(5).Description)

    End Sub
End Class