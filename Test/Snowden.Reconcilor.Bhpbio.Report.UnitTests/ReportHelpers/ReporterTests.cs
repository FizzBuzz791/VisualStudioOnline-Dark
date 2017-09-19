using System;
using System.Data;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions;
using Snowden.Reconcilor.Bhpbio.Report.ReportHelpers;
using Snowden.Reconcilor.Bhpbio.Report.UnitTests.Mocks;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.ReportHelpers
{
    [TestFixture]
    public class ReporterTests
    {
        private Reporter _sut;

        [SetUp]
        public void Setup()
        {
            // Called before each test.
            _sut = new ReporterMock();
        }

        [TestCase("Pit", "", 1)]
        [TestCase("Stockpile", "", 2)]
        [TestCase("SampleCoverage", "", 3)]
        [TestCase("", "Other", 4)]
        [TestCase("", "StockpileContext", 5)]
        [TestCase("SampleCoverage", "Unsampled", 5)]
        [TestCase("SampleCoverage", "SampledPercentage", 6)]
        [TestCase("", "", 50)]
        [TestCase("Stratigraphy", "Stratigraphy", 1)]
        [TestCase("Stratigraphy", "SP to Crusher", 2)]
        [TestCase("Weathering", "Weathering", 1)]
        [TestCase("Weathering", "SP to Crusher", 2)]
        public void GetContextGroupingOrder_ReturnsTheCorrectOrder(string locationType, string contextGrouping, int expectedOrder)
        {
            // Arrange
            DataTable table = new DataTable();
            table.Columns.Add("LocationType");
            table.Columns.Add("ContextGrouping");
            DataRow dataRow = table.NewRow();
            dataRow["LocationType"] = locationType;
            dataRow["ContextGrouping"] = contextGrouping;

            // Act
            int order = _sut.GetContextGroupingOrder(dataRow);

            // Assert
            Assert.That(order, Is.EqualTo(expectedOrder));
        }

        [Test]
        public void AddsContextRowAsNonFactorRow_WithCorrectValues()
        {
            // Arrange
            DataTable masterTable = new DataTable();
            masterTable.Columns.Add("CalendarDate");
            masterTable.Columns.Add("DateFrom");
            masterTable.Columns.Add("DateTo");
            masterTable.Columns.Add("DateText");
            masterTable.Columns.Add("LocationId");
            masterTable.Columns.Add("LocationName");
            masterTable.Columns.Add("LocationType");
            masterTable.Columns.Add("ContextCategory");
            masterTable.Columns.Add("ContextGrouping");
            masterTable.Columns.Add("ContextGroupingLabel");
            masterTable.Columns.Add("PresentationColor");
            masterTable.Columns.Add("LocationColor");
            masterTable.Columns.Add("Attribute");
            masterTable.Columns.Add("AttributeValue");
            masterTable.Columns.Add("Type");
            masterTable.Columns.Add("Tonnes");
            masterTable.Columns.Add("FactorGradeValueBottom");
            masterTable.Columns.Add("FactorTonnesBottom");

            DateTime dateFrom = new DateTime(2017, 1, 1);
            DateTime dateTo = new DateTime(2017, 1, 31);
            const int LOCATION_ID = 23;
            const string GRADE_NAME = "Tonnes";
            const double GRADE_VALUE = 61.2351;
            const string LOCATION_NAME = "Test";
            const string LOCATION_TYPE = "Type";
            const string CONTEXT_CATEGORY = "Category";
            const string CONTEXT_GROUPING = "Grouping";
            const string CONTEXT_GROUPING_LABEL = "Label";
            const int TONNES = 1234;

            DataRow expectedRow = masterTable.NewRow();
            expectedRow["CalendarDate"] = dateFrom;
            expectedRow["DateFrom"] = dateFrom;
            expectedRow["DateTo"] = dateTo;
            expectedRow["DateText"] = dateTo.ToString("MMMM-yy");
            expectedRow["LocationId"] = LOCATION_ID;
            expectedRow["LocationName"] = LOCATION_NAME;
            expectedRow["LocationType"] = LOCATION_TYPE;
            expectedRow["ContextCategory"] = CONTEXT_CATEGORY;
            expectedRow["ContextGrouping"] = CONTEXT_GROUPING;
            expectedRow["ContextGroupingLabel"] = CONTEXT_GROUPING_LABEL;
            expectedRow["PresentationColor"] = LOCATION_NAME.AsColor();
            expectedRow["LocationColor"] = DBNull.Value;
            expectedRow["Attribute"] = GRADE_NAME;
            expectedRow["AttributeValue"] = 0.0;
            expectedRow["Type"] = 1;
            expectedRow["Tonnes"] = TONNES;
            expectedRow["FactorGradeValueBottom"] = GRADE_VALUE;
            expectedRow["FactorTonnesBottom"] = TONNES;

            DataTable contextTable = new DataTable();
            contextTable.Columns.Add("DateFrom");
            contextTable.Columns.Add("DateTo");
            contextTable.Columns.Add("LocationId");
            contextTable.Columns.Add("Grade_Name");
            contextTable.Columns.Add("Grade_Value");
            contextTable.Columns.Add("LocationName");
            DataRow contextRow = contextTable.NewRow();
            contextRow["DateFrom"] = dateFrom;
            contextRow["DateTo"] = dateTo;
            contextRow["LocationId"] = LOCATION_ID;
            contextRow["Grade_Name"] = GRADE_NAME;
            contextRow["Grade_Value"] = GRADE_VALUE;
            contextRow["LocationName"] = LOCATION_NAME;

            // Act
            _sut.AddContextRowAsNonFactorRow(contextRow, ref masterTable, string.Empty, TONNES, CONTEXT_GROUPING, LOCATION_TYPE,
                CONTEXT_CATEGORY, CONTEXT_GROUPING_LABEL, LOCATION_NAME);

            // Assert
            for (int i = 0; i < masterTable.Rows[0].ItemArray.Length; i++)
            {
                if (!masterTable.Rows[0].ItemArray[i].Equals(expectedRow.ItemArray[i]))
                    Assert.Fail(
                        $"{masterTable.Columns[i].ColumnName} did not match. Expected {masterTable.Rows[0].ItemArray[i]} but got {expectedRow.ItemArray[i]}.");
            }
        }
    }
}