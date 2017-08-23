using System.Data;
using NUnit.Framework;
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
    }
}