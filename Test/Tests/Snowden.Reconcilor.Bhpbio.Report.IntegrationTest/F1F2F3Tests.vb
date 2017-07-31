Imports System
Imports System.Text
Imports System.Collections.Generic
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports System.Data
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

<TestClass()>
Public Class F1F2F3ReportingTests

    Private testContextInstance As TestContext
    Private Const _defaultDatabaseConfigurationName As String = "Main"
    Private Const _defaultDatabaseUserName As String = "ReconcilorUI"

    Private Shared _r As New Random()
    Private Shared _table As DataTable = Nothing
    Private Shared _session As Types.ReportSession = Nothing
    Private Shared _service As New WebService

    Private Const _locationId As Integer = 7
    Private Shared _dateFrom As DateTime = Date.Parse("2015-07-01")

    Public Property TestContext() As TestContext
        Get
            Return testContextInstance
        End Get
        Set(ByVal value As TestContext)
            testContextInstance = value
        End Set
    End Property

    <ClassInitialize>
    Public Shared Sub Initialize(testContext As TestContext)

        Dim connectionString As String = IntegrationTestsHelper.GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName)
        _service.SetOverrideConnectionString(connectionString)
        _service.SetOverrideReportContext(Types.ReportContext.Standard)

        Dim locationId = _locationId
        Dim dateFrom = _dateFrom.Date
        Dim dateTo = dateFrom.AddMonths(1).AddDays(-1)

        ' get some hub data from the reporting service so that we can run our tests
        _session = _service.CreateReportSession()
        _session.CalculationParameters(dateFrom, dateTo, locationId, False)
        '_session.IncludeProductSizeBreakdown = True
        '_table = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(_session, locationId, dateFrom, dateTo, "MONTH", False)

    End Sub

    <ClassCleanup>
    Public Shared Sub Cleanup()
        If _session IsNot Nothing Then
            _session.Dispose()
        End If
    End Sub

    <TestMethod()>
    Public Sub Test_DataRow_Cloning()
        Assert.IsTrue(_table.Rows.Count > 0, "Table is Empty")

        Dim beforeCount = _table.Rows.Count
        Dim row = _table.Rows(0).CloneFactorRow()
        Dim afterCount = _table.Rows.Count

        Assert.IsNotNull(row.Table, "Row should be cloned into a table, but it wasn't")
        Assert.IsTrue(IsDBNull(row("Tonnes")), "Tonnes not nulled out properly in cloned row")
        Assert.IsTrue(IsDBNull(row("Fe")), "Grades not nulled out properly in cloned row")
        Assert.IsTrue(afterCount > beforeCount, "New row did not get added to the table")

        ' remove the rows again, so later tests don't break
        _table.Rows.Remove(row)
    End Sub

    <TestMethod()>
    Public Sub Test_Resource_Classification_Webservice()
        Dim table = _service.ListResourceClassifications()

        Assert.IsTrue(table.Rows.Count > 4, "Expected more resource classifications")
        Assert.IsTrue(table.Columns.Contains("ResourceClassification"), "Expected Column Missing")
        Assert.IsTrue(table.Columns.Contains("ResourceClassificationDescription"), "Expected Column Missing")

    End Sub

    <TestMethod()>
    Public Sub Test_F1Factor_Calculation()
        Using session = _service.CreateReportSession()
            session.RethrowCalculationSetErrors = True
            session.CalculationParameters(Date.Parse("2016-01-01"), Date.Parse("2016-01-31"), 9, False)

            Dim calcSet = Types.CalculationSet.CreateForCalculations(session, New String() {"F1Factor"})
            Dim table = calcSet.ToDataTable(session, New Types.DataTableOptions())

            Assert.IsNotNull(table)
        End Using
    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Has_All_Sizes()
        Assert.IsTrue(_table.Rows.Count > 0, "Table is Empty")
        Dim count = ProductSizeCount()
        Assert.IsTrue(count > 1, String.Format("Not enough product sizes in table (found {0})", count))

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Size_Filtering()

        Dim rows = _table.AsEnumerable.WithProductSize("TOTAL")
        Dim count = rows.Select(Function(r) r.AsString("ProductSize")).Distinct.Count

        Assert.IsTrue(rows.Count > 0, "Filtered dataset was empty")
        Assert.IsTrue(count = 1, String.Format("More than one productsize (found {0})", count))

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Clone_Rows()
        Dim beforeCount = _table.Rows.Count
        Dim rows = _table.AsEnumerable.WithProductSize("LUMP")
        Dim cloned = rows.CloneFactorRows
        Dim afterCount = _table.Rows.Count
        Dim clonedCount = cloned.Count

        Assert.IsTrue(clonedCount > 0, "Nothing was cloned")
        Assert.IsTrue(afterCount > 0, "No new rows were added to the table")
        Assert.IsTrue(afterCount - beforeCount = clonedCount, "New table size does not match number of cloned rows")

        ' remove the rows again, so later tests don't break
        For Each row In rows.ToList
            row.Delete()
        Next

        _table.AcceptChanges()

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Clone_Product_Size()
        Dim geomet As New F1F2F3GeometDataHelper
        Dim beforeCount = ProductSizeCount()
        geomet.AddNewProductSize(_table, "TEST_SIZE")
        Dim afterCount = ProductSizeCount()

        Assert.IsTrue(afterCount = beforeCount + 1, "No new ProductSize was added")

    End Sub


    <TestMethod()>
    Public Sub Test_DataTable_Geomet_Calculation()
        Dim geomet As New F1F2F3GeometDataHelper
        Dim pz = "GEOMET2"

        geomet.AddNewProductSize(_table, pz)
        geomet.CalculateGeometValues(_table, pz)

        Dim avgGeomet = _table.AsEnumerable.WithProductSize(pz).Select(Function(r) r.AsDblN("Tonnes")).Average()

        Assert.IsNotNull(avgGeomet, "Could not calculate average lump %")
        Assert.IsTrue(avgGeomet >= 0, "Lump % is less than zero")
        Assert.IsTrue(avgGeomet <= 100, "Lump % is greater than 100 %")

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Geomet_Calculation_With_Factors()
        Dim geomet As New F1F2F3GeometDataHelper

        geomet.AddGeometData(_table)

        Dim factor = _table.AsEnumerable.WithProductSize("GEOMET").Where(Function(r) r.IsFactorRow).Select(Function(r) r.AsDblN("Tonnes")).Average()
        Assert.IsNotNull(factor, "Could not calculate average factor")
        Assert.IsTrue(factor >= 0.5, "geomet factor is less than 0.50")
        Assert.IsTrue(factor <= 2.0, "geomet factor is greater than 2.00")

        ' check that the there is a MM adjusted number
        Dim mmCount = _table.AsEnumerable.Where(Function(r) r.AsString("ReportTagId").Contains("MiningModelADForTonnes")).Count
        Assert.IsTrue(mmCount > 0, "No Mining Model AD Adjusted record")

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Check_F2_Factor()

        Dim hasgeomet = (_table.AsEnumerable.WithProductSize("GEOMET").Count > 1)

        If Not hasgeomet Then
            ' only add the geomet data to the table if we don't have it yet
            Dim geomet As New F1F2F3GeometDataHelper
            geomet.AddGeometData(_table)
        End If

        Dim attr = "Tonnes"
        Dim rows = _table.AsEnumerable.WithProductSize("GEOMET").Where(Function(r) r.AsString("RootCalcId") = "F2Factor")
        Dim f2 = rows.Where(Function(r) r.AsString("ReportTagId") = "F2Factor").First.AsDbl(attr)
        Dim gc = rows.Where(Function(r) r.AsString("ReportTagId") = "F2GradeControlModel").First.AsDbl(attr)
        Dim mmpe = rows.Where(Function(r) r.AsString("ReportTagId") = "F2MineProductionExpitEqulivent").First.AsDbl(attr)

        Assert.IsTrue(rows.Count > 0, "No GEOMET F2 Rows")
        Assert.IsTrue(f2 > 0, "Invalid factor")
        Assert.IsTrue(Math.Abs(f2 - (mmpe / gc)) < 0.001, "F2 GEOMET was not calculated properly")

    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_Adjust_Tonnes()
        Dim adjustment = 0.8
        Dim rows = _table.AsEnumerable.WithProductSize("LUMP")

        Dim beforeTonnes = rows.Where(Function(r) r.HasTonnes).Select(Function(r) r.AsDbl("Tonnes")).Sum()
        rows.AdjustTonnes(0.8)
        Dim afterTonnes = rows.Where(Function(r) r.HasTonnes).Select(Function(r) r.AsDbl("Tonnes")).Sum()

        Assert.IsTrue(beforeTonnes > 0, "No tonnes in test dataset")
        Assert.IsTrue(afterTonnes > 0, "No tonnes in test dataset after adjustment")
        Assert.IsTrue(beforeTonnes > afterTonnes, String.Format("Adjustment of '{0}' did not reduce the total tonnes", adjustment))

        ' reverse the adjustment so that it doesn't affect other tests
        rows.AdjustTonnes(1 / 0.8)
    End Sub

    <TestMethod()>
    Public Sub Test_DataTable_To_Calculation_Row()
        ' get a random row from the set to get better test coverage - even though this makes the test
        ' non-deterministic
        Dim index = _r.Next(_table.AsEnumerable.Count - 1)
        Dim row = _table.AsEnumerable.ElementAt(index)
        Dim calcRow = row.ToCalculationRecord()

        'Assert.AreEqual(calcRow.TagId, row.AsString("TagId"))
        Assert.AreEqual(calcRow.ReportTagId, row.AsString("ReportTagId"))
        Assert.AreEqual(calcRow.Description, row.AsString("Description"))

        Assert.AreEqual(calcRow.Tonnes, row.AsDblN("Tonnes"))
        Assert.AreEqual(calcRow.Fe, row.AsDblN("Fe"))
    End Sub

    <TestMethod()>
    Public Sub Test_ProductSize_Filter_Property()
        _session.ProductSizeFilter = Types.ProductSizeFilterValue.NONE
        Assert.AreEqual(_session.ProductSizeFilter, Types.ProductSizeFilterValue.NONE)
        Assert.AreEqual(_session.ProductSizeFilterString, "NONE")

        _session.ProductSizeFilter = Types.ProductSizeFilterValue.LUMP
        Assert.AreEqual(_session.ProductSizeFilter, Types.ProductSizeFilterValue.LUMP)
        Assert.AreEqual(_session.ProductSizeFilterString, "LUMP")

        _session.ProductSizeFilterString = "fines"
        Assert.AreEqual(_session.ProductSizeFilter, Types.ProductSizeFilterValue.FINES)
        Assert.AreEqual(_session.ProductSizeFilterString, "FINES")

        _session.ProductSizeFilterString = Nothing
        Assert.AreEqual(_session.ProductSizeFilter, Types.ProductSizeFilterValue.NONE)
        Assert.AreEqual(_session.ProductSizeFilterString, "NONE")


    End Sub


    <TestMethod()>
    <ExpectedException(GetType(Exception))>
    Public Sub Test_ProductSize_Filter_Property_Invalid_String()
        _session.ProductSizeFilterString = "fake_size"
    End Sub

    <TestMethod()>
    Public Sub Test_Get_Table_Filtered_By_ProductSize()
        _session.ProductSizeFilterString = "LUMP"
        Dim table = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(_session, 137037, DateTime.Parse("2015-04-01"), DateTime.Parse("2015-04-30"), "MONTH", False)
        Dim count = ProductSizeCount(table)
        Dim productSize = table.AsEnumerable.Select(Function(r) r.AsString("ProductSize")).Distinct.FirstOrDefault

        Assert.AreEqual(1, count, "Exactly one product size was expected")
        Assert.AreEqual(_session.ProductSizeFilterString, productSize, "productSize in table did no match filter value")
    End Sub

    <TestMethod()>
    Public Sub Test_ReportSession_ProductType_List()
        Assert.IsTrue(_session.ProductTypes.Count > 0, "ProductTypes list is empty")
        Assert.AreEqual(_session.ProductTypes.Count, _session.ProductTypes.Select(Function(p) p.ProductTypeID).Distinct.Count, "Product Type List contains duplicated")
    End Sub

    <TestMethod()>
    Public Sub Test_ReportSession_ProductType_Property()
        _session.ProductTypeCode = "NBLL"
        Assert.AreEqual(_session.ProductTypeCode, _session.SelectedProductType.ProductTypeCode, "Incorrect Selected ProductType")
        Assert.AreEqual(_session.RequestParameter.LocationId, 1, "Location Id was not set properly")
        Assert.AreEqual(_session.ProductSizeFilterString, "LUMP", "Product Size filter was not set properly")

        _session.ProductTypeCode = "YNDF"
        Assert.AreEqual(_session.ProductTypeCode, _session.SelectedProductType.ProductTypeCode, "Incorrect Selected ProductType")
        Assert.AreEqual(_session.RequestParameter.LocationId, 2, "Location Id was not set properly")
        Assert.AreEqual(_session.ProductSizeFilterString, "FINES", "Product Size filter was not set properly")

        _session.ProductTypeCode = Nothing
        Assert.IsNull(_session.ProductTypeCode, "Selected product type not nulled properly")
        Assert.IsNull(_session.SelectedProductType, "Selected product type not nulled properly")

    End Sub

    <TestMethod()>
    Public Sub Test_Get_Hub_Data_By_Product()
        Dim productTypeId = 1
        Dim dateFrom = _dateFrom.Date
        Dim dateTo = dateFrom.AddMonths(1).AddDays(-1)

        Dim table = F1F2F3ReportEngine.GetFactorsForProductType(_session, dateFrom, dateTo, productTypeId, groupOnCalendarDate:=False)
        Dim productTypeCode = table.AsEnumerable.Select(Function(r) r.AsString("ProductTypeCode")).FirstOrDefault
        Dim productTypeIdFromTable = table.AsEnumerable.Select(Function(r) r.AsInt("ProductTypeId")).FirstOrDefault

        Assert.IsNotNull(table, "Null DataTable returned")
        Assert.IsTrue(productTypeCode = _session.ProductTypeCode, "Incorrect product type code in table")
        Assert.IsTrue(productTypeIdFromTable = productTypeId, "Incorrect product type id in table")

        table = F1F2F3ReportEngine.UnpivotDataTable(table)


    End Sub

    <TestMethod()>
    Public Sub Test_Get_Resource_Classification_Data()
        Dim locationId = 137037
        Dim dateFrom = Date.Parse("2015-02-01") '_dateFrom.Date
        Dim dateTo = dateFrom.AddMonths(1).AddDays(-1)

        Using session = _service.CreateReportSession()
            session.IncludeResourceClassification = True
            session.IncludeProductSizeBreakdown = False
            session.Context = Types.ReportContext.ApprovalListing
            session.CalculationParameters(dateFrom, dateTo, Types.ReportBreakdown.Monthly, locationId, False)

            Dim calcSet As New Types.CalculationSet()
            Dim miningModel = Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate()

            miningModel.AddResourceClassificationTotals()

            calcSet.Add(miningModel)
            Dim rawTable = miningModel.ToDataTable()
            Dim table = calcSet.ToDataTable(True, False, True, False, session)

            Assert.IsNotNull(table, "Null DataTable returned")
            Assert.IsFalse(table.AsEnumerable.All(Function(r) String.IsNullOrEmpty(r.AsString("ResourceClassification"))), "No Resource Class data")

        End Using
    End Sub

    <TestMethod()>
    Public Sub Test_Get_Resource_Classification_SingleCalculation()
        Dim locationId = 137037
        Dim dateFrom = Date.Parse("2015-02-01") '_dateFrom.Date
        Dim dateTo = dateFrom.AddMonths(1).AddDays(-1)

        Using session = _service.CreateReportSession()
            Dim table = F1F2F3SingleCalculationReport.GetResourceClassificationCalculation(session, "MiningModel", locationId, dateFrom, dateTo)

            Assert.IsNotNull(table, "Null DataTable returned")
            Assert.IsFalse(table.AsEnumerable.All(Function(r) String.IsNullOrEmpty(r.AsString("ResourceClassification"))), "No Resource Class data")
        End Using
    End Sub

    '<TestMethod()>
    'Public Sub Test_Get_Resource_Classification_Design_Breakdown()
    '    Dim locationId = 137037

    '    Using session = _service.CreateReportSession()
    '        Dim table = BlastByBlastReconciliationReport.GetResourceClassificationByLocation(session, locationId, New String() {"Mining"})

    '        Assert.IsNotNull(table, "Null DataTable returned")
    '        Assert.IsFalse(table.AsEnumerable.All(Function(r) String.IsNullOrEmpty(r.AsString("ResourceClassification"))), "No Resource Class data")
    '    End Using
    'End Sub

    '<TestMethod()>
    'Public Sub Test_Get_Resource_Classification_ByLocation()
    '    Dim dateFrom = Date.Parse("2015-03-01")
    '    Dim dateTo = dateFrom.AddMonths(1).AddDays(-1)

    '    Dim table = _service.GetErrorContributionDataForSubLocations(9, dateFrom, dateTo, 4, "Tonnes, Fe", "F1Factor, F2Factor")
    '    Assert.IsNotNull(table, "Null DataTable returned")

    'End Sub

    <TestMethod()>
    <ExpectedException(GetType(Exception))>
    Public Sub Test_ReportSession_ProductType_Invalid_Property()
        _session.ProductTypeCode = "XXXXX"
    End Sub

    Public Shared Function ProductSizeCount(Optional ByVal table As DataTable = Nothing) As Integer
        If table Is Nothing Then table = _table
        Return table.AsEnumerable.Select(Function(r) r.AsString("ProductSize")).Distinct.Count
    End Function



End Class
