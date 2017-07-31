Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Snowden.Reconcilor.Bhpbio.Report.Types

<TestClass()> Public Class GetLocationDepositCommentTests

    Private _reportSession As ReportSession

    <TestInitialize()> Public Sub TestInitalize()
        _reportSession = IntegrationTestsHelper.CreateReportSession()
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentCompany()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, 1, Nothing).Trim()

        Assert.AreEqual("Company: WAIO", result)
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentHub()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, 8, Nothing).Trim()

        Assert.AreEqual("Hub: NJV", result)
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentSite()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, 9, Nothing).Trim()

        Assert.AreEqual("Hub: NJV  Site: Newman", result)
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentPit()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, 32272, Nothing).Trim()

        Assert.AreEqual("Hub: NJV  Site: Newman  Pit: 29", result)
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentBench()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, 32273, Nothing).Trim()

        Assert.AreEqual("Hub: NJV  Site: Newman  Pit: 29  Bench: 0556", result)
    End Sub

    <TestMethod()> Public Sub GetLocationDepositCommentDeposit()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, Nothing, 5).Trim()

        Assert.AreEqual("Deposit: Deposit4", result)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(System.ArgumentNullException), "You must specify a value for either locationId or depositId")>
    Public Sub GetLocationDepositCommentNullArgs()

        Dim result = Data.ReportDisplayParameter.GetLocationDepositComment(_reportSession, Nothing, Nothing)

    End Sub

End Class