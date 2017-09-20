using System;
using System.Data;
using System.Linq;
using NSubstitute;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.Constants;
using Snowden.Reconcilor.Bhpbio.Report.ReportHelpers;
using Snowden.Reconcilor.Bhpbio.Report.Types;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.ReportHelpers
{
    [TestFixture]
    public class StratigraphyReporterTests
    {
        private IStratigraphyReporter _sut;
        private DataTable _masterTable;

        [SetUp]
        public void Setup()
        {
            _masterTable = new DataTable();
            _masterTable.Columns.Add(ColumnNames.DATE_CAL);
            _masterTable.Columns.Add(ColumnNames.DATE_FROM);
            _masterTable.Columns.Add(ColumnNames.DATE_TO);
            _masterTable.Columns.Add("DateText");
            _masterTable.Columns.Add(ColumnNames.LOCATION_ID);
            _masterTable.Columns.Add("LocationName");
            _masterTable.Columns.Add("LocationType");
            _masterTable.Columns.Add("ContextCategory");
            _masterTable.Columns.Add("ContextGrouping");
            _masterTable.Columns.Add("ContextGroupingLabel");
            _masterTable.Columns.Add("PresentationColor");
            _masterTable.Columns.Add("LocationColor");
            _masterTable.Columns.Add("Attribute");
            _masterTable.Columns.Add("AttributeValue");
            _masterTable.Columns.Add(ColumnNames.TYPE);
            _masterTable.Columns.Add("Tonnes");
            _masterTable.Columns.Add("FactorGradeValueBottom");
            _masterTable.Columns.Add("FactorTonnesBottom");
            _masterTable.Columns.Add(ColumnNames.STRAT_NUM);
            _masterTable.Columns.Add(ColumnNames.STRAT_LEVEL);
            _masterTable.Columns.Add(ColumnNames.STRAT_COLOR);
            _masterTable.Columns.Add("CalcId");
        }

        [Test]
        public void StratigraphyContextDataForF1OrF15_IsAddedToTheReferenceTable()
        {
            // Arrange
            GeneralSetup();

            // Act
            _sut.AddStratigraphyContextDataForF1OrF15(ref _masterTable, Arg.Any<int>(), Arg.Any<DateTime>(),
                Arg.Any<DateTime>(), Arg.Any<ReportBreakdown>());

            // Assert
            Assert.That(_masterTable.Rows.Count, Is.EqualTo(2)); // 1 Factor row becomes 1 Factor row, 1 Non-Factor (a.k.a Strat) row.
            Assert.That(_masterTable.Rows.Cast<DataRow>().Last()["ContextCategory"], Is.EqualTo("Stratigraphy"));
            Assert.That(_masterTable.Rows.Cast<DataRow>().First()["Tonnes"], Is.EqualTo(_masterTable.Rows.Cast<DataRow>().Last()["Tonnes"]));
            Assert.That(_masterTable.Rows.Cast<DataRow>().First()[ColumnNames.STRAT_NUM], Is.EqualTo(_masterTable.Rows.Cast<DataRow>().Last()["ContextGrouping"]));
        }

        private void GeneralSetup()
        {
            DataRow testRow = _masterTable.NewRow();
            testRow[ColumnNames.DATE_FROM] = DateTime.MaxValue;
            testRow[ColumnNames.STRAT_NUM] = "5610";
            testRow[ColumnNames.STRAT_LEVEL] = 3;
            testRow[ColumnNames.STRAT_COLOR] = "Member";
            testRow["CalcId"] = ModelGradeControl.CalculationId;
            testRow["Tonnes"] = 1234;
            _masterTable.Rows.Add(testRow);

            _sut = new StratigraphyReporter(3);
        }
    }
}