using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.Constants;
using Snowden.Reconcilor.Bhpbio.Report.Extensions;
using Snowden.Reconcilor.Bhpbio.Report.Types;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.Extensions
{
    [TestFixture]
    public class F1F2F3DataExtensionsTests
    {
        private DataTable _referenceTable;

        [SetUp]
        public void Setup()
        {
            _referenceTable = new DataTable();
            _referenceTable.Columns.Add(ColumnNames.DATE_FROM);
            _referenceTable.Columns.Add(ColumnNames.LOCATION_ID);
            _referenceTable.Columns.Add(ColumnNames.MATERIAL_TYPE_ID);
            _referenceTable.Columns.Add(ColumnNames.PRODUCT_SIZE);
            _referenceTable.Columns.Add(ColumnNames.REPORT_TAG_ID);
            _referenceTable.Columns.Add(ColumnNames.TAG_ID);
            _referenceTable.Columns.Add(ColumnNames.RESOURCE_CLASSIFICATION);
            _referenceTable.Columns.Add("Attribute");
            _referenceTable.Columns.Add("AttributeValue");

            DataRow row1 = _referenceTable.NewRow();
            row1[ColumnNames.DATE_FROM] = DateTime.Today;
            row1[ColumnNames.LOCATION_ID] = 1;
            row1[ColumnNames.MATERIAL_TYPE_ID] = 2;
            row1[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            row1[ColumnNames.REPORT_TAG_ID] = F1.CalculationId;
            row1[ColumnNames.TAG_ID] = F1.CalculationId;
            row1[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            row1["Attribute"] = "Tonnes";
            row1["AttributeValue"] = 1234;
            _referenceTable.Rows.Add(row1);

            DataRow row2 = _referenceTable.NewRow();
            row2[ColumnNames.DATE_FROM] = DateTime.Today;
            row2[ColumnNames.LOCATION_ID] = 1;
            row2[ColumnNames.MATERIAL_TYPE_ID] = 2;
            row2[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            row2[ColumnNames.REPORT_TAG_ID] = F2.CalculationId;
            row2[ColumnNames.TAG_ID] = F2.CalculationId;
            row2[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            row2["Attribute"] = "P";
            row2["AttributeValue"] = 12;
            _referenceTable.Rows.Add(row2);

            DataRow row3 = _referenceTable.NewRow();
            row3[ColumnNames.DATE_FROM] = DateTime.Today;
            row3[ColumnNames.LOCATION_ID] = 1;
            row3[ColumnNames.MATERIAL_TYPE_ID] = 2;
            row3[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            row3[ColumnNames.REPORT_TAG_ID] = F2.CalculationId;
            row3[ColumnNames.TAG_ID] = F2.CalculationId;
            row3[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification2";
            row3["Attribute"] = "LOI";
            row3["AttributeValue"] = 34;
            _referenceTable.Rows.Add(row3);

            DataRow row4 = _referenceTable.NewRow();
            row4[ColumnNames.DATE_FROM] = DateTime.Today;
            row4[ColumnNames.LOCATION_ID] = 3;
            row4[ColumnNames.MATERIAL_TYPE_ID] = 2;
            row4[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            row4[ColumnNames.REPORT_TAG_ID] = F1.CalculationId;
            row4[ColumnNames.TAG_ID] = F1.CalculationId;
            row4[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            row4["Attribute"] = "Tonnes";
            row4["AttributeValue"] = 98;
            _referenceTable.Rows.Add(row4);
        }

        [Test]
        public void GetCorrespondingRowsUnpivoted_ReturnsExpectedRows()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.REPORT_TAG_ID] = F1.CalculationId;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Fe";
            referenceRow["AttributeValue"] = 1011;

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            IEnumerable<DataRow> result =
                F1F2F3DataExtensions.GetCorrespondingRowsUnpivoted(ref referenceTableRows, referenceRow);

            // Assert
            Assert.That(result.Count(), Is.EqualTo(1));
        }

        [Test]
        public void GetCorrespondingRowsForGroupUnpivoted_ReturnsExpectedRows()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Fe";
            referenceRow["AttributeValue"] = 1011;

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            IEnumerable<DataRow> result =
                F1F2F3DataExtensions.GetCorrespondingRowsForGroupUnpivoted(ref referenceTableRows, referenceRow);

            // Assert
            Assert.That(result.Count(), Is.EqualTo(2));
        }

        [Test]
        public void GetCorrespondingRowsForLocationsUnpivoted_ReturnsExpectedRows()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.REPORT_TAG_ID] = F1.CalculationId;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Tonnes";

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            IEnumerable<DataRow> result =
                F1F2F3DataExtensions.GetCorrespondingRowsForLocationsUnpivoted(ref referenceTableRows,
                    referenceRow);

            // Assert
            Assert.That(result.Count(), Is.EqualTo(2));
        }

        [Test]
        public void GetCorrespondingRowUnpivoted_ReturnsExpectedRow()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Tonnes";

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            DataRow result = F1F2F3DataExtensions.GetCorrespondingRowUnpivoted(ref referenceTableRows,
                    referenceRow, F1.CalculationId);

            // Assert
            Assert.That(result, Is.Not.Null); // More than 1 match will throw an exception, but no match just returns null.
            Assert.That(result[ColumnNames.DATE_FROM], Is.EqualTo(referenceRow[ColumnNames.DATE_FROM]));
            Assert.That(result[ColumnNames.LOCATION_ID], Is.EqualTo(referenceRow[ColumnNames.LOCATION_ID]));
            Assert.That(result[ColumnNames.REPORT_TAG_ID], Is.EqualTo(F1.CalculationId));
        }

        [Test]
        public void GetCorrespondingRow_ReturnsExpectedRow()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Tonnes";

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            DataRow result = F1F2F3DataExtensions.GetCorrespondingRow(ref referenceTableRows, F1.CalculationId, referenceRow);

            // Assert
            Assert.That(result, Is.Not.Null); // More than 1 match will throw an exception, but no match just returns null.
            Assert.That(result[ColumnNames.DATE_FROM], Is.EqualTo(referenceRow[ColumnNames.DATE_FROM]));
            Assert.That(result[ColumnNames.LOCATION_ID], Is.EqualTo(referenceRow[ColumnNames.LOCATION_ID]));
            Assert.That(result[ColumnNames.TAG_ID], Is.EqualTo(F1.CalculationId));
        }

        [Test]
        public void GetCorrespondingRowWithReportTagId_ReturnsExpectedRow()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.PRODUCT_SIZE] = CalculationConstants.PRODUCT_SIZE_TOTAL;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow["Attribute"] = "Tonnes";

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            DataRow result = F1F2F3DataExtensions.GetCorrespondingRowWithReportTagId(ref referenceTableRows, F1.CalculationId, referenceRow);

            // Assert
            Assert.That(result, Is.Not.Null); // More than 1 match will throw an exception, but no match just returns null.
            Assert.That(result[ColumnNames.DATE_FROM], Is.EqualTo(referenceRow[ColumnNames.DATE_FROM]));
            Assert.That(result[ColumnNames.LOCATION_ID], Is.EqualTo(referenceRow[ColumnNames.LOCATION_ID]));
            Assert.That(result[ColumnNames.REPORT_TAG_ID], Is.EqualTo(F1.CalculationId));
        }

        [Test]
        public void GetCorrespondingRowWithProductSize_ReturnsExpectedRow()
        {
            // Arrange
            DataRow referenceRow = _referenceTable.NewRow();
            referenceRow[ColumnNames.DATE_FROM] = DateTime.Today;
            referenceRow[ColumnNames.LOCATION_ID] = 1;
            referenceRow[ColumnNames.MATERIAL_TYPE_ID] = 2;
            referenceRow[ColumnNames.RESOURCE_CLASSIFICATION] = "ResourceClassification1";
            referenceRow[ColumnNames.REPORT_TAG_ID] = F1.CalculationId;
            referenceRow["Attribute"] = "Tonnes";

            // Act
            IEnumerable<DataRow> referenceTableRows = _referenceTable.Rows.Cast<DataRow>();
            DataRow result = F1F2F3DataExtensions.GetCorrespondingRowWithProductSize(ref referenceTableRows,
                CalculationConstants.PRODUCT_SIZE_TOTAL, referenceRow);

            // Assert
            Assert.That(result, Is.Not.Null); // More than 1 match will throw an exception, but no match just returns null.
            Assert.That(result[ColumnNames.DATE_FROM], Is.EqualTo(referenceRow[ColumnNames.DATE_FROM]));
            Assert.That(result[ColumnNames.LOCATION_ID], Is.EqualTo(referenceRow[ColumnNames.LOCATION_ID]));
            Assert.That(result[ColumnNames.PRODUCT_SIZE], Is.EqualTo(CalculationConstants.PRODUCT_SIZE_TOTAL));
        }
    }
}