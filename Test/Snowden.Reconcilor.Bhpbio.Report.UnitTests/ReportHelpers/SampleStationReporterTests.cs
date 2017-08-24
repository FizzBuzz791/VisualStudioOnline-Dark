using System;
using System.Data;
using System.Linq;
using NSubstitute;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using Snowden.Reconcilor.Bhpbio.Report.ReportHelpers;
using Snowden.Reconcilor.Bhpbio.Report.Types;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.ReportHelpers
{
    [TestFixture]
    public class SampleStationReporterTests
    {
        private ISampleStationReporter _sut;
        private DataTable _masterTable;

        [SetUp]
        public void Setup()
        {
            _masterTable = new DataTable();
            _masterTable.Columns.Add("CalendarDate");
            _masterTable.Columns.Add("DateFrom");
            _masterTable.Columns.Add("DateTo");
            _masterTable.Columns.Add("DateText");
            _masterTable.Columns.Add("LocationId");
            _masterTable.Columns.Add("LocationName");
            _masterTable.Columns.Add("LocationType");
            _masterTable.Columns.Add("ContextCategory");
            _masterTable.Columns.Add("ContextGrouping");
            _masterTable.Columns.Add("ContextGroupingLabel");
            _masterTable.Columns.Add("PresentationColor");
            _masterTable.Columns.Add("LocationColor");
            _masterTable.Columns.Add("Attribute");
            _masterTable.Columns.Add("AttributeValue");
            _masterTable.Columns.Add("Type");
            _masterTable.Columns.Add("Tonnes");
            _masterTable.Columns.Add("FactorGradeValueBottom");
            _masterTable.Columns.Add("FactorTonnesBottom");
        }

        [Test]
        public void SampleStationCoverageContextData_IsAddedToTheReferenceTable()
        {
            // Arrange
            GeneralSetup();

            // Act
            _sut.AddSampleStationCoverageContextData(ref _masterTable, Arg.Any<int>(), Arg.Any<DateTime>(),
                Arg.Any<DateTime>(), Arg.Any<ReportBreakdown>());

            // Assert
            Assert.That(_masterTable.Rows.Count, Is.EqualTo(3)); // 1 Sample Coverage row becomes 1 non-factor row, 1 unsampled row & 1 label row
        }

        [Test]
        public void SampleStationRatioContextData_IsAddedToTheReferenceTable()
        {
            // Arrange
            GeneralSetup();

            // Act
            _sut.AddSampleStationRatioContextData(ref _masterTable, Arg.Any<int>(), Arg.Any<DateTime>(),
                Arg.Any<DateTime>(), Arg.Any<ReportBreakdown>());

            // Assert
            Assert.That(_masterTable.Rows.Count, Is.EqualTo(1)); // 1 Sample Ratio row becomes 1 non-factor row. No "unsampled" or label row.
        }

        [Test]
        public void LegendIsSeededWhenHaulageDataIsPresent()
        {
            // Arrange
            SeedingSetup();

            // Act
            _sut.AddSampleStationCoverageContextData(ref _masterTable, Arg.Any<int>(), Arg.Any<DateTime>(),
                Arg.Any<DateTime>(), Arg.Any<ReportBreakdown>());

            // Assert
            Assert.That(_masterTable.Rows.Cast<DataRow>().Count(r => (string) r["ContextCategory"] == "HaulageContext"),
                Is.EqualTo(4)); // Haulage Row, Sample Coverage Sampled Row, Sample Coverage Unsampled Row, Label Row
        }

        private void GeneralSetup()
        {
            DataTable sampleStationReportData = new DataTable();
            sampleStationReportData.Columns.Add("Assayed");
            sampleStationReportData.Columns.Add("SampleStation");
            sampleStationReportData.Columns.Add("DateFrom");
            sampleStationReportData.Columns.Add("DateTo");
            sampleStationReportData.Columns.Add("LocationId");
            sampleStationReportData.Columns.Add("Grade_Name");
            sampleStationReportData.Columns.Add("Grade_Value");
            sampleStationReportData.Columns.Add("Grade_Id");
            sampleStationReportData.Columns.Add("Unassayed");
            sampleStationReportData.Columns.Add("Sample_Count");
            DataRow testRow = sampleStationReportData.NewRow();
            testRow["DateFrom"] = DateTime.MaxValue;
            testRow["SampleStation"] = "SS01";
            testRow["Grade_Name"] = "Tonnes";
            testRow["Sample_Count"] = 1;
            sampleStationReportData.Rows.Add(testRow);

            ISqlDalReport sqlDalReport = Substitute.For<ISqlDalReport>();
            sqlDalReport.GetBhpbioSampleStationReportData(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<DateTime>(),
                Arg.Any<string>()).Returns(sampleStationReportData);
            _sut = new SampleStationReporter(sqlDalReport);
        }

        private void SeedingSetup()
        {
            DataTable sampleStationReportData = new DataTable();
            sampleStationReportData.Columns.Add("Assayed");
            sampleStationReportData.Columns.Add("SampleStation");
            sampleStationReportData.Columns.Add("DateFrom");
            sampleStationReportData.Columns.Add("DateTo");
            sampleStationReportData.Columns.Add("LocationId");
            sampleStationReportData.Columns.Add("Grade_Name");
            sampleStationReportData.Columns.Add("Grade_Value");
            sampleStationReportData.Columns.Add("Grade_Id");
            sampleStationReportData.Columns.Add("Unassayed");
            sampleStationReportData.Columns.Add("Sample_Count");

            DataRow testRow = sampleStationReportData.NewRow();
            testRow["DateFrom"] = DateTime.MaxValue;
            testRow["SampleStation"] = "SS01";
            testRow["Grade_Name"] = "Tonnes";
            testRow["Sample_Count"] = 1;
            sampleStationReportData.Rows.Add(testRow);

            DataRow haulageRow = _masterTable.NewRow();
            haulageRow["ContextCategory"] = "HaulageContext";
            haulageRow["DateFrom"] = DateTime.MinValue;
            _masterTable.Rows.Add(haulageRow);

            ISqlDalReport sqlDalReport = Substitute.For<ISqlDalReport>();
            sqlDalReport.GetBhpbioSampleStationReportData(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<DateTime>(),
                Arg.Any<string>()).Returns(sampleStationReportData);
            _sut = new SampleStationReporter(sqlDalReport);
        }
    }
}