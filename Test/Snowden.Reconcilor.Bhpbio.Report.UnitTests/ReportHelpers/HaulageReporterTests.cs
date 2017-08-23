using System;
using System.Data;
using NSubstitute;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using Snowden.Reconcilor.Bhpbio.Report.ReportHelpers;
using Snowden.Reconcilor.Bhpbio.Report.Types;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.ReportHelpers
{
    [TestFixture]
    public class HaulageReporterTests
    {
        private IHaulageReporter _sut;
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
        public void HaulageContextData_IsAddedToTheReferenceTable()
        {
            // Arrange
            GeneralSetup();

            // Act
            _sut.AddHaulageContextData(ref _masterTable, Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<DateTime>(),
                Arg.Any<ReportBreakdown>());

            // Assert
            Assert.That(_masterTable.Rows.Count, Is.GreaterThanOrEqualTo(3)); // Haulage Row, Other Row, Label Row, Seeded Row(s)
        }

        private void GeneralSetup()
        {
            DataTable haulageReportData = new DataTable();
            haulageReportData.Columns.Add("TotalTonnes");
            haulageReportData.Columns.Add("LocationName");
            haulageReportData.Columns.Add("LocationType");
            haulageReportData.Columns.Add("DateFrom");
            haulageReportData.Columns.Add("DateTo");
            haulageReportData.Columns.Add("LocationId");
            haulageReportData.Columns.Add("Grade_Name");
            haulageReportData.Columns.Add("Grade_Value");

            DataRow testRow = haulageReportData.NewRow();
            testRow["DateFrom"] = DateTime.MaxValue;
            testRow["LocationName"] = "Test";
            testRow["TotalTonnes"] = 1000;
            testRow["LocationType"] = "Stockpile";
            haulageReportData.Rows.Add(testRow);

            DataRow otherRow = haulageReportData.NewRow();
            otherRow["DateFrom"] = DateTime.MaxValue;
            otherRow["LocationName"] = "Test";
            otherRow["TotalTonnes"] = 5;
            otherRow["LocationType"] = "Stockpile";
            haulageReportData.Rows.Add(otherRow);

            DataRow seedTestRow = haulageReportData.NewRow();
            seedTestRow["DateFrom"] = DateTime.MinValue;
            seedTestRow["LocationName"] = "Test2";
            seedTestRow["TotalTonnes"] = 500;
            seedTestRow["LocationType"] = "Stockpile";
            haulageReportData.Rows.Add(seedTestRow);

            ISqlDalReport sqlDalReport = Substitute.For<ISqlDalReport>();
            sqlDalReport.GetBhpbioHaulageMovementsToCrusher(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<DateTime>(),
                Arg.Any<string>()).Returns(haulageReportData);
            IUtility dalUtility = Substitute.For<IUtility>();
            dalUtility.GetBhpbioReportColorList(Arg.Any<string>(), Arg.Any<bool>()).Returns(new DataTable());
            _sut = new HaulageReporter(sqlDalReport, dalUtility);
        }
    }
}
