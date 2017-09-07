using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using NUnit.Framework;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.Extensions
{
    [TestFixture]
    public class GenericDataTableExtensionsTests
    {
        private DataRow _sut;

        private const string COL_INTEGER = "Integer";
        private const string COL_BOOL = "Boolean";
        private const string COL_DATE = "Date";
        private const string COL_DBL = "Double";

        [SetUp]
        public void Setup()
        {
            DataTable definition = new DataTable();
            definition.Columns.Add(COL_INTEGER, typeof(int));
            definition.Columns.Add(COL_BOOL, typeof(bool));
            definition.Columns.Add(COL_DATE, typeof(DateTime));
            definition.Columns.Add(COL_DBL, typeof(double));

            _sut = definition.NewRow();
            definition.Rows.Add(_sut);
        }

        public static IEnumerable<TestCaseData> AsIntTestCases
        {
            get
            {
                yield return new TestCaseData(1).SetName("AsInt_ReturnsExpectedValue_Integer").Returns(1);
                // AsInt returns a non-nullable int, so this holds true, even if it seems a bit weird.
                yield return new TestCaseData(DBNull.Value).SetName("AsInt_ReturnsExpectedValue_Null").Returns(0);
                yield return new TestCaseData(1.2).SetName("AsInt_ReturnsExpectedValue_DoubleLow").Returns(1);
                yield return new TestCaseData(1.7).SetName("AsInt_ReturnsExpectedValue_DoubleHigh").Returns(2);
                yield return new TestCaseData("1").SetName("AsInt_ReturnsExpectedValue_StringInt").Returns(1);
            }
        }

        [TestCaseSource(nameof(AsIntTestCases))]
        public int AsInt_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_INTEGER] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsInt(ref _sut, COL_INTEGER);
        }

        public static IEnumerable<TestCaseData> AsIntNTestCases
        {
            get
            {
                yield return new TestCaseData(1).SetName("AsIntN_ReturnsExpectedValue_Integer").Returns(1);
                // AsInt returns a non-nullable int, so this holds true, even if it seems a bit weird.
                yield return new TestCaseData(DBNull.Value).SetName("AsIntN_ReturnsExpectedValue_Null").Returns(null);
                yield return new TestCaseData(1.2).SetName("AsIntN_ReturnsExpectedValue_DoubleLow").Returns(1);
                yield return new TestCaseData(1.7).SetName("AsIntN_ReturnsExpectedValue_DoubleHigh").Returns(2);
                yield return new TestCaseData("1").SetName("AsIntN_ReturnsExpectedValue_StringInt").Returns(1);
            }
        }

        [TestCaseSource(nameof(AsIntNTestCases))]
        public int? AsIntN_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_INTEGER] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsIntN(ref _sut, COL_INTEGER);
        }

        public static IEnumerable<TestCaseData> AsBoolTestCases
        {
            get
            {
                yield return new TestCaseData(true).SetName("AsBool_ReturnsExpectedValue_True").Returns(true);
                yield return new TestCaseData(false).SetName("AsBool_ReturnsExpectedValue_False").Returns(false);
                yield return new TestCaseData(DBNull.Value).SetName("AsBool_ReturnsExpectedValue_Null").Returns(false);
            }
        }

        [TestCaseSource(nameof(AsBoolTestCases))]
        public bool AsBool_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_BOOL] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsBool(ref _sut, COL_BOOL);
        }

        public static IEnumerable<TestCaseData> AsDateTestCases
        {
            get
            {
                yield return new TestCaseData(DateTime.Today).SetName("AsDate_ReturnsExpectedValue_DateTime").Returns(DateTime.Today);
                yield return new TestCaseData("20-05-2017").SetName("AsDate_ReturnsExpectedValue_String").Returns(new DateTime(2017,5,20));
                yield return new TestCaseData(DBNull.Value).SetName("AsDate_ReturnsExpectedValue_Null").Returns(DateTime.MinValue);
            }
        }

        [TestCaseSource(nameof(AsDateTestCases))]
        public DateTime AsDate_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_DATE] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsDate(ref _sut, COL_DATE);
        }

        public static IEnumerable<TestCaseData> AsDblTestCases
        {
            get
            {
                yield return new TestCaseData(2.3).SetName("AsDbl_ReturnsExpectedValue_Double").Returns(2.3);
                yield return new TestCaseData("2.3").SetName("AsDbl_ReturnsExpectedValue_String").Returns(2.3);
                yield return new TestCaseData(DBNull.Value).SetName("AsDbl_ReturnsExpectedValue_Null").Returns(0.0);
                yield return new TestCaseData(Double.NaN).SetName("AsDbl_ReturnsExpectedValue_NaN").Returns(0.0);
            }
        }

        [TestCaseSource(nameof(AsDblTestCases))]
        public double AsDbl_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_DBL] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsDbl(ref _sut, COL_DBL);
        }

        [TestCase(1.2, ExpectedResult = 1.2)]
        [TestCase(Double.NaN, ExpectedResult = 0.0)]
        public double RemoveNaNs_ReturnsExpectedValue(double value)
        {
            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.RemoveNaNs(value);
        }

        public static IEnumerable<TestCaseData> AsDblNTestCases
        {
            get
            {
                yield return new TestCaseData(2.3).SetName("AsDblN_ReturnsExpectedValue_Double").Returns(2.3);
                yield return new TestCaseData("2.3").SetName("AsDblN_ReturnsExpectedValue_String").Returns(2.3);
                yield return new TestCaseData(DBNull.Value).SetName("AsDblN_ReturnsExpectedValue_Null").Returns(null);
                yield return new TestCaseData(Double.NaN).SetName("AsDblN_ReturnsExpectedValue_NaN").Returns(0.0);
            }
        }

        [TestCaseSource(nameof(AsDblNTestCases))]
        public double? AsDblN_ReturnsExpectedValue(object value)
        {
            // Arrange
            _sut[COL_DBL] = value;

            // Act & Assert
            // Don't actually need an explicit assert, it's implied by the test case.
            return Report.Extensions.GenericDataTableExtensions.AsDblN(ref _sut, COL_DBL);
        }

        [TestCase(COL_DBL, ExpectedResult = true)]
        [TestCase("XYZ", ExpectedResult = false)]
        public bool HasColumn_ReturnsExpectedValue(string columnName)
        {
            return Report.Extensions.GenericDataTableExtensions.HasColumn(ref _sut, columnName);
        }

        [Test]
        public void Copy_PerformsADeepCopy()
        {
            // Arrange
            _sut[COL_DBL] = 12.34;

            // Act
            DataRow newRow = Report.Extensions.GenericDataTableExtensions.Copy(ref _sut);

            // Assert
            Assert.That(newRow.ItemArray, Is.EqualTo(_sut.ItemArray));
            Assert.That(newRow[COL_DBL], Is.EqualTo(_sut[COL_DBL]));
        }

        [TestCase(COL_DBL)]
        [TestCase("XYZ")]
        public void SetNull_AssignsDBNullToColumnValue(string columnName)
        {
            // Arrange
            if (Report.Extensions.GenericDataTableExtensions.HasColumn(ref _sut, columnName))
                _sut[columnName] = 12.34;

            // Act
            Report.Extensions.GenericDataTableExtensions.SetNull(ref _sut, columnName);

            // Assert
            if (Report.Extensions.GenericDataTableExtensions.HasColumn(ref _sut, columnName))
                Assert.That(_sut[columnName], Is.EqualTo(DBNull.Value));
        }

        [Test]
        public void SetFieldIfNull_EnsuresAllNullFieldsHaveAValue()
        {
            // Arrange
            _sut[COL_DBL] = 12.34; // Give one row a non-null value to ensure it's working as expected.
            _sut.Table.Rows.Add(_sut.Table.NewRow());
            _sut.Table.Rows.Add(_sut.Table.NewRow());

            IEnumerable<DataRow> rows = _sut.Table.Rows.Cast<DataRow>().ToList();
            int nullCount = rows.Count(r => r[COL_DBL] == DBNull.Value);

            // Act
            Report.Extensions.GenericDataTableExtensions.SetFieldIfNull(ref rows, COL_DBL, 5.67);

            // Assert
            Assert.That(rows.Count(r => r[COL_DBL] == DBNull.Value), Is.Zero); // No nulls for COL_DBL
            Assert.That(rows.Count(r => Math.Abs((double)r[COL_DBL] - 5.67) < Double.Epsilon), Is.EqualTo(nullCount)); // Count of rows set to new value is same as null row count.
        }

        [TestCase(34.56)]
        [TestCase(null)]
        public void SetField_EnsuresAllFieldsHaveTheSameValue(object value)
        {
            // Arrange
            _sut[COL_DBL] = 12.34;
            DataRow newRow = _sut.Table.NewRow();
            newRow[COL_DBL] = 56.78;
            _sut.Table.Rows.Add(newRow);
            _sut.Table.Rows.Add(_sut.Table.NewRow());

            IEnumerable<DataRow> rows = _sut.Table.Rows.Cast<DataRow>().ToList();

            // Act
            Report.Extensions.GenericDataTableExtensions.SetField(ref rows, COL_DBL, value);

            // Assert
            Assert.That(rows.Count(r => Equals(r[COL_DBL], value ?? DBNull.Value)), Is.EqualTo(rows.Count())); // Count of rows set to new value is same as row count.
        }

        [Test]
        public void SetFieldByPredicate_SetsAllRelevantRows()
        {
            // Arrange
            _sut[COL_DBL] = 5.1;
            DataRow newRow = _sut.Table.NewRow();
            newRow[COL_DBL] = 4.9;
            _sut.Table.Rows.Add(newRow);

            IEnumerable<DataRow> rows = _sut.Table.Rows.Cast<DataRow>().ToList();

            // Act
            Report.Extensions.GenericDataTableExtensions.SetField(ref rows, COL_DBL,
                r => Report.Extensions.GenericDataTableExtensions.AsDblN(ref r, COL_DBL) > 5 ? 1 : 0);

            // Assert
            Assert.That(rows.Count(r => Equals(r[COL_DBL], 1d)), Is.EqualTo(1));
            Assert.That(rows.Count(r => Equals(r[COL_DBL], 0d)), Is.EqualTo(1));
        }

        [Test]
        public void SortBy_ReturnsSortedTable()
        {
            // Arrange
            _sut[COL_DBL] = 5;
            DataRow newRow = _sut.Table.NewRow();
            newRow[COL_DBL] = 3;
            _sut.Table.Rows.Add(newRow);

            DataTable dataTable = _sut.Table;

            // Act
            DataTable result = Report.Extensions.GenericDataTableExtensions.SortBy(ref dataTable, COL_DBL);

            // Assert
            Assert.That(result.Rows[0][COL_DBL], Is.EqualTo(dataTable.Rows.Cast<DataRow>().Min(r => (double)r[COL_DBL])));
            Assert.That(result.Rows[1][COL_DBL], Is.EqualTo(dataTable.Rows.Cast<DataRow>().Max(r => (double)r[COL_DBL])));
        }

        [Test]
        public void SortBy_ThrowsExceptionIfColumnDoesntExist()
        {
            // Arrange
            DataTable dataTable = _sut.Table;

            // Act & Assert
            Assert.That(() => Report.Extensions.GenericDataTableExtensions.SortBy(ref dataTable, "XYZ"),
                Throws.Exception.With.Message.Contains("Cannot sort table by"));
        }

        [Test]
        public void DeleteRows_DeletesOnlyExpectedRows()
        {
            // Arrange
            _sut.Table.Rows.Add(_sut.Table.NewRow());

            IEnumerable<DataRow> rowsToDelete = new List<DataRow> {_sut};

            // Act
            Report.Extensions.GenericDataTableExtensions.DeleteRows(ref rowsToDelete);

            // Assert
            Assert.That(_sut.Table.Rows.Count, Is.EqualTo(1));
        }

        [Test]
        public void ToDataTable_OnlyContainsExpectedRows()
        {
            // Arrange
            _sut.Table.Rows.Add(_sut.Table.NewRow());

            IEnumerable<DataRow> rowsToConvert = new List<DataRow> {_sut};

            // Act
            DataTable newTable = Report.Extensions.GenericDataTableExtensions.ToDataTable(rowsToConvert);

            // Assert
            Assert.That(_sut.Table.Rows.Count, Is.EqualTo(2));
            Assert.That(newTable.Rows.Count, Is.EqualTo(1));
            Assert.That(newTable.Rows[0][COL_DBL], Is.EqualTo(_sut[COL_DBL]));
        }
    }
}