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
            const int locationId = 23;
            const string gradeName = "Tonnes";
            const double gradeValue = 61.2351;
            const string locationName = "Test";
            const string locationType = "Type";
            const string contextCategory = "Category";
            const string contextGrouping = "Grouping";
            const string contextGroupingLabel = "Label";
            const int tonnes = 1234;

            DataRow expectedRow = masterTable.NewRow();
            expectedRow["CalendarDate"] = dateFrom;
            expectedRow["DateFrom"] = dateFrom;
            expectedRow["DateTo"] = dateTo;
            expectedRow["DateText"] = dateTo.ToString("MMMM-yy");
            expectedRow["LocationId"] = locationId;
            expectedRow["LocationName"] = locationName;
            expectedRow["LocationType"] = locationType;
            expectedRow["ContextCategory"] = contextCategory;
            expectedRow["ContextGrouping"] = contextGrouping;
            expectedRow["ContextGroupingLabel"] = contextGroupingLabel;
            expectedRow["PresentationColor"] = locationName.AsColor();
            expectedRow["LocationColor"] = DBNull.Value;
            expectedRow["Attribute"] = gradeName;
            expectedRow["AttributeValue"] = 0.0;
            expectedRow["Type"] = 1;
            expectedRow["Tonnes"] = tonnes;
            expectedRow["FactorGradeValueBottom"] = gradeValue;
            expectedRow["FactorTonnesBottom"] = tonnes;

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
            contextRow["LocationId"] = locationId;
            contextRow["Grade_Name"] = gradeName;
            contextRow["Grade_Value"] = gradeValue;
            contextRow["LocationName"] = locationName;

            // Act
            _sut.AddContextRowAsNonFactorRow(contextRow, ref masterTable, string.Empty, tonnes, contextGrouping, locationType,
                contextCategory, contextGroupingLabel, locationName);

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