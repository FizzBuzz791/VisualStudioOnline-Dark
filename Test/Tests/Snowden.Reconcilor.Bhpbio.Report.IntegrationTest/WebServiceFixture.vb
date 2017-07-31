Imports System
Imports System.Text
Imports System.Collections.Generic
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports pc = Snowden.Bcd.ProductConfiguration
Imports System.Data

<TestClass()> Public Class WebServiceFixture

    Private testContextInstance As TestContext
    Private Const _defaultDatabaseConfigurationName As String = "Main"
    Private Const _defaultDatabaseUserName As String = "ReconcilorUI"
    Private Const _productConfigurationPathKeyName As String = "ProductConfigurationPath"
    Private Const _testProductSizeLump As String = "LUMP"
    Private Const _testProductSizeFines As String = "FINES"
    Private ReadOnly _testReportStartDate As DateTime = New Date(2013, 1, 1)
    Private ReadOnly _testReportEndDate As DateTime = New Date(2013, 3, 31)
    Private Const _testReportBreakdown As String = "QUARTER"
    Private Const _testHubLocationId As Integer = 8
    Private Const _testAttributes As String = "<Attributes><Attribute id=""0"" name=""Tonnes""/></Attributes>"
    Private Const _testComparisonReportFactor As String = "F25Factor"
    Private Const _testAttributeReportFactors As String = "<Factors><Factor id=""F1Factor""/><Factor id=""F2Factor""/><Factor id=""F25Factor""/></Factors>"
    Private Const _testLocations As String = "<Locations><Location id=""6""/><Location id=""133098""/><Location id=""8"" /><Location id=""2""/><Location id=""4""/></Locations>"

    '''<summary>
    '''Gets or sets the test context which provides
    '''information about and functionality for the current test run.
    '''</summary>
    Public Property TestContext() As TestContext
        Get
            Return testContextInstance
        End Get
        Set(ByVal value As TestContext)
            testContextInstance = value
        End Set
    End Property

#Region "Additional test attributes"
    '
    ' You can use the following additional attributes as you write your tests:
    '
    ' Use ClassInitialize to run code before running the first test in the class
    ' <ClassInitialize()> Public Shared Sub MyClassInitialize(ByVal testContext As TestContext)
    ' End Sub
    '
    ' Use ClassCleanup to run code after all tests in a class have run
    ' <ClassCleanup()> Public Shared Sub MyClassCleanup()
    ' End Sub
    '
    ' Use TestInitialize to run code before running each test
    ' <TestInitialize()> Public Sub MyTestInitialize()
    ' End Sub
    '
    ' Use TestCleanup to run code after each test has run
    ' <TestCleanup()> Public Sub MyTestCleanup()
    ' End Sub
    '
#End Region

    '<TestMethod()> Public Sub FHUBReport_WithoutLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    FHUBReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, False, True)
    'End Sub

    '<TestMethod()> Public Sub FHUBReport_WithLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    FHUBReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)
    'End Sub

    '<TestMethod()> Public Sub FHUBReport_WithoutLumpFinesBreakdown_ApprovedDataOnly_ReportRunsAsExpected()
    '    FHUBReport_Generic(Types.ReportContext.Standard, _testReportStartDate, _testReportEndDate, _testReportBreakdown, False, True)
    'End Sub

    '<TestMethod()> Public Sub FHUBReport_WithLumpFinesBreakdown_ApprovedDataOnly_ReportRunsAsExpected()
    '    ' Note: there will only be lump and fines data using approved data only if the approval was made after the introduction of Lump and Fines to the system
    '    FHUBReport_Generic(Types.ReportContext.Standard, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)
    'End Sub

    '<TestMethod()> Public Sub FHUBReport_WithoutLumpFinesBreakdown_ApprovalListingData_ReportRunsAsExpected()
    '    ' Note: there will only be lump and fines data using approved data only if the approval was made after the introduction of Lump and Fines to the system
    '    FHUBReport_Generic(Types.ReportContext.ApprovalListing, _testReportStartDate, _testReportEndDate, _testReportBreakdown, False, True)
    'End Sub

    '<TestMethod()> Public Sub FHUBReport_WithLumpFinesBreakdown_ApprovalListingData_ReportRunsAsExpected()
    '    FHUBReport_Generic(Types.ReportContext.ApprovalListing, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)
    'End Sub

    <TestMethod()> Public Sub FHUBAllLocationsReport_Standard()
        FHUBAllLocationsExportReport_Generic(Types.ReportContext.Standard, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, False)
    End Sub

    <TestMethod()> Public Sub FHUBAllLocationsReport_With_Sublocations()
        FHUBAllLocationsExportReport_Generic(Types.ReportContext.Standard, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)
    End Sub

    <TestMethod()> Public Sub RiskProfileReport_AllSitesInHub_F1()
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(Types.ReportContext.LiveOnly)
        Dim rs As New Types.ReportSession()
        rs.SetupDal(connectionString)

        Dim data As DataTable = ReportDefinitions.RiskProfilereport.GetData(rs, 8, New DateTime(2015, 1, 1), "PIT", "F1")

    End Sub

    <TestMethod()> Public Sub RiskProfileReport_SingleSite_F1()
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(Types.ReportContext.LiveOnly)
        Dim rs As New Types.ReportSession()
        rs.SetupDal(connectionString)

        Dim data As DataTable = ReportDefinitions.RiskProfilereport.GetData(rs, 11, New DateTime(2015, 1, 1), "SITE", "F1")

    End Sub


    <TestMethod()> Public Sub RiskProfileReport_AllPitsInSite_F15()
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(Types.ReportContext.LiveOnly)
        Dim rs As New Types.ReportSession()
        rs.SetupDal(connectionString)

        Dim data As DataTable = ReportDefinitions.RiskProfilereport.GetData(rs, 12, New DateTime(2015, 1, 1), "PIT", "F15")

    End Sub
    <TestMethod()> Public Sub RiskProfileReport_AllHubs_F1()
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(Types.ReportContext.LiveOnly)
        Dim rs As New Types.ReportSession()
        rs.SetupDal(connectionString)

        Dim data As DataTable = ReportDefinitions.RiskProfilereport.GetData(rs, 1, New DateTime(2015, 1, 1), "HUB", "F1")

    End Sub


    <TestMethod()> Public Sub GetRiskProfileReport_AllSitesForHub_F1()
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(Types.ReportContext.LiveOnly)

        Dim rs As New Types.ReportSession()
        rs.SetupDal(connectionString)

        Dim data As DataTable = service.GetRiskProfileReport(8, New DateTime(2015, 1, 1), "F1", 3)
    End Sub

    '<TestMethod()> Public Sub F1F2F3OverviewReconciliationReport_WithoutLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3OverviewReconciliationReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, False, True)
    'End Sub

    '<TestMethod()> Public Sub F1F2F3OverviewReconciliationReport_WithLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3OverviewReconciliationReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)
    'End Sub

    '<TestMethod()> Public Sub F1F2F3ReconciliationComparisonReport_WithoutLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3ReconciliationComparisonReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, _testAttributes, _testComparisonReportFactor, _testLocations, False)
    'End Sub

    '<TestMethod()> Public Sub F1F2F3ReconciliationComparisonReport_WithLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3ReconciliationComparisonReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, _testAttributes, _testComparisonReportFactor, _testLocations, True)
    'End Sub

    '<TestMethod()> Public Sub F1F2F3ReconciliationByAttributeReport_WithoutLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3ReconciliationByAttributeReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, _testAttributes, _testComparisonReportFactor, False)
    'End Sub

    '<TestMethod()> Public Sub F1F2F3ReconciliationByAttributeReport_WithLumpFinesBreakdown_LiveOnly_ReportRunsAsExpected()
    '    F1F2F3ReconciliationByAttributeReport_Generic(Types.ReportContext.LiveOnly, _testReportStartDate, _testReportEndDate, _testReportBreakdown, _testAttributes, _testComparisonReportFactor, True)
    'End Sub

    '<TestMethod()> _
    'Public Sub FHUBAllLocationsExportReport_Excel_Export()
    '    ' instantiate the test web service
    '    Dim service As New WebService
    '    Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

    '    service.SetOverrideConnectionString(connectionString)
    '    service.SetOverrideReportContext(Types.ReportContext.Standard)

    '    Dim result As System.Data.DataTable = service.FHUBAllLocationsReportExcelReady(_testHubLocationId, _testReportStartDate, _testReportEndDate, _testReportBreakdown, True, True)

    'End Sub

    Private Sub FHUBAllLocationsExportReport_Generic(ByVal reportContext As Types.ReportContext, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdown As String, ByVal lumpFinesBreakdown As Boolean, ByVal includeSubLocations As Boolean)
        ' instantiate the test web service
        Dim service As New WebService
        Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

        service.SetOverrideConnectionString(connectionString)
        service.SetOverrideReportContext(reportContext)

        Dim result As System.Data.DataTable = service.GetBhpbioReconciliationDataExportData(Nothing, _testHubLocationId, startDate, endDate, breakdown, lumpFinesBreakdown, includeSubLocations, includeResourceClassifications:=False)

        ' Data has been retrieved without exception
        ' Check that the result table does NOT contain Lump and Fines tags
        Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeLump))
        Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeFines))
    End Sub

    'Private Sub FHUBReport_Generic(ByVal reportContext As Types.ReportContext, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdown As String, ByVal lumpFinesBreakdown As Boolean, ByVal f25Breakdwon As Boolean)
    '    ' instantiate the test web service
    '    Dim service As New WebService
    '    Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

    '    service.SetOverrideConnectionString(connectionString)
    '    service.SetOverrideReportContext(reportContext)

    '    Dim result As System.Data.DataTable = service.FHUBReport(Nothing, _testHubLocationId, startDate, endDate, breakdown, lumpFinesBreakdown, f25Breakdwon)

    '    ' Data has been retrieved without exception
    '    ' Check that the result table does NOT contain Lump and Fines tags
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeLump))
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeFines))
    'End Sub

    'Private Sub F1F2F3OverviewReconciliationReport_Generic(ByVal reportContext As Types.ReportContext, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdown As String, ByVal lumpFinesBreakdown As Boolean, ByVal f25Breakdwon As Boolean)
    '    ' instantiate the test web service
    '    Dim service As New WebService
    '    Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

    '    service.SetOverrideConnectionString(connectionString)
    '    service.SetOverrideReportContext(reportContext)

    '    Dim result As System.Data.DataTable = service.GetBhpbioF1F2F3OverviewReconReport(_testHubLocationId, startDate.ToString("yyyy-MM-dd"), endDate.ToString("yyyy-MM-dd"), breakdown, lumpFinesBreakdown, f25Breakdwon)

    '    ' Data has been retrieved without exception
    '    ' Check that the result table does NOT contain Lump and Fines tags
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeLump))
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeFines))
    'End Sub


    'Private Sub F1F2F3ReconciliationComparisonReport_Generic(ByVal reportContext As Types.ReportContext, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdown As String, ByVal attributes As String, ByVal factor As String, ByVal locations As String, ByVal lumpFinesBreakdown As Boolean)
    '    ' instantiate the test web service
    '    Dim service As New WebService
    '    Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

    '    service.SetOverrideConnectionString(connectionString)
    '    service.SetOverrideReportContext(reportContext)

    '    Dim result As System.Data.DataTable = service.GetF1F2F3ReconciliationComparisonReport(_testHubLocationId, startDate.ToString("yyyy-MM-dd"), endDate.ToString("yyyy-MM-dd"), breakdown, attributes, factor, locations, lumpFinesBreakdown)

    '    ' Data has been retrieved without exception
    '    ' Check that the result table does NOT contain Lump and Fines tags
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeLump))
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeFines))
    'End Sub

    'Private Sub F1F2F3ReconciliationByAttributeReport_Generic(ByVal reportContext As Types.ReportContext, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal breakdown As String, ByVal attributes As String, ByVal factor As String, ByVal lumpFinesBreakdown As Boolean)
    '    ' instantiate the test web service
    '    Dim service As New WebService
    '    Dim connectionString As String = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)

    '    service.SetOverrideConnectionString(connectionString)
    '    service.SetOverrideReportContext(reportContext)

    '    Dim result As System.Data.DataTable = service.GetBhpbioF1F2F3HUBReconAttributeReport(_testHubLocationId, startDate.ToString("yyyy-MM-dd"), endDate.ToString("yyyy-MM-dd"), breakdown, attributes, factor, lumpFinesBreakdown)

    '    ' Data has been retrieved without exception
    '    ' Check that the result table does NOT contain Lump and Fines tags
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeLump))
    '    Assert.AreEqual(lumpFinesBreakdown, DoesTagSuffixExist(result, _testProductSizeFines))
    'End Sub


    Private Function DoesTagSuffixExist(ByRef dt As DataTable, ByVal tagSuffix As String) As Boolean
        For Each dr As DataRow In dt.Rows
            If (dr.Item("TagId").ToString().EndsWith(tagSuffix)) Then
                Return True
            End If
        Next
        Return False
    End Function

    Private Function GetConnectionString(ByVal databaseConfigurationName As String, ByVal databaseUserName As String) As String

        ' Read the product configuration based on the file path in the configuration file
        Dim productConfiguration As New pc.ConfigurationManager(System.Configuration.ConfigurationManager.AppSettings(_productConfigurationPathKeyName))
        ' open the configuration
        productConfiguration.Open()

        Dim connectionString As String

        Dim databaseConfiguration As pc.DatabaseConfiguration
        databaseConfiguration = productConfiguration.GetDatabaseConfiguration(databaseConfigurationName)

        If databaseConfiguration Is Nothing Then
            Throw New InvalidOperationException("The Reconcilor database configuration was not found within the product configuration file; please run the Management application to configure settings.")
        End If

        connectionString = databaseConfiguration.GenerateSqlClientConnectionString(databaseUserName)

        Return connectionString

    End Function

End Class
