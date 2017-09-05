using System;
using System.Data;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.Constants;
using Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.ReportDefinitions
{
    [TestFixture]
    public class F1F2F3ReportEngineTests
    {
        private DataTable _resultsTable; // Everything is modified by ref, so this is both original and results.
        private const double TOLERANCE = 0.00000000000001;

        [SetUp]
        public void Setup()
        {
            ConfigureDataTable();
        }

        /// <summary>
        /// Cheating a bit since they're actually all calculated at once. 
        /// This was the easiest way to pull out resulting data to test though, achieves the desired result anyway.
        /// </summary>
        /// <param name="calculationId"></param>
        /// <param name="useF1GCForF2"></param>
        /// <param name="productSize"></param>
        [TestCase(F0.CalculationId)]
        [TestCase(F05.CalculationId)]
        [TestCase(F1.CalculationId)]
        [TestCase(F15.CalculationId)]
        [TestCase(F2.CalculationId)]
        [TestCase(F2.CalculationId, true)]
        [TestCase(F2.CalculationId, false, CalculationConstants.PRODUCT_SIZE_GEOMET)]
        [TestCase(F25.CalculationId)]
        [TestCase(F3.CalculationId)]
        [TestCase(F3.CalculationId, false, CalculationConstants.PRODUCT_SIZE_GEOMET)]
        [TestCase(RecoveryFactorDensity.CalculationId)]
        [TestCase(RecoveryFactorMoisture.CalculationId)]
        [TestCase(F2Density.CalculationId)]
        [TestCase(RFGM.CalculationId)]
        [TestCase(RFMM.CalculationId)]
        [TestCase(RFSTM.CalculationId)]
        public void CalculateF1F2F3Factors_RecalculatesTonnesCorrectly_ForFactor(string calculationId, bool useF1GCForF2 = false, 
            string productSize = CalculationConstants.PRODUCT_SIZE_TOTAL)
        {
            // Arrange
            bool checkRatios = true;
            bool checkDifferences = true;
            switch (calculationId)
            {
                case F0.CalculationId:
                    AddRows(F0.CalculationId, $"F0{ModelMining.CalculationId}", $"F0{ModelGeology.CalculationId}",
                        productSize);
                    checkDifferences = false;
                    break;
                case F05.CalculationId:
                    AddRows(F05.CalculationId, $"F05{ModelGradeControl.CalculationId}",
                        $"F05{ModelGeology.CalculationId}", productSize);
                    checkDifferences = false;
                    break;
                case F1.CalculationId:
                    AddRows(F1.CalculationId, $"F1{ModelGradeControl.CalculationId}", $"F1{ModelMining.CalculationId}",
                        productSize);
                    break;
                case F15.CalculationId:
                    AddRows(F15.CalculationId, $"F15{ModelGradeControlSTGM.CalculationId}",
                        $"F15{ModelShortTermGeology.CalculationId}", productSize);
                    break;
                case F2.CalculationId:
                    AddRows(F2.CalculationId, $"F2{MineProductionExpitEquivalent.CalculationId}",
                        useF1GCForF2 ? $"F1{ModelGradeControl.CalculationId}" : $"F2{ModelGradeControl.CalculationId}",
                        productSize);
                    break;
                case F25.CalculationId:
                    AddRows(F25.CalculationId, $"F25{OreForRail.CalculationId}",
                        $"F25{MiningModelOreForRailEquivalent.CalculationId}", productSize);
                    break;
                case F3.CalculationId:
                    AddRows(F3.CalculationId, $"F3{PortOreShipped.CalculationId}",
                        $"F3{MiningModelShippingEquivalent.CalculationId}{(productSize == CalculationConstants.PRODUCT_SIZE_GEOMET ? "ADForTonnes" : string.Empty)}",
                        productSize);
                    break;
                case RecoveryFactorDensity.CalculationId:
                    AddRows(RecoveryFactorDensity.CalculationId, $"RFD{ActualMined.CalculationId}",
                        $"RFD{ModelMining.CalculationId}", productSize);
                    checkRatios = false; // This seems weird...
                    break;
                case RecoveryFactorMoisture.CalculationId:
                    AddRows(RecoveryFactorMoisture.CalculationId, $"RFM{MineProductionActuals.CalculationId}",
                        $"RFM{ModelMining.CalculationId}", productSize);
                    break;
                case F2Density.CalculationId:
                    AddRows(F2Density.CalculationId, $"F2Density{ActualMined.CalculationId}",
                        $"F2Density{ModelGradeControl.CalculationId}", productSize);
                    break;
                case RFGM.CalculationId:
                    AddRows(RFGM.CalculationId, $"RFGM{MineProductionExpitEquivalent.CalculationId}",
                        $"RFGM{ModelGradeControlSTGM.CalculationId}", productSize);
                    checkDifferences = false;
                    break;
                case RFMM.CalculationId:
                    AddRows(RFMM.CalculationId, $"RFMM{MineProductionExpitEquivalent.CalculationId}",
                        $"RFMM{ModelMining.CalculationId}", productSize);
                    checkDifferences = false;
                    break;
                case RFSTM.CalculationId:
                    AddRows(RFSTM.CalculationId, $"RFSTM{MineProductionExpitEquivalent.CalculationId}",
                        $"RFSTM{ModelShortTermGeology.CalculationId}", productSize);
                    checkDifferences = false;
                    break;
                default:
                    Assert.Fail($"Unknown Test Case: {calculationId}");
                    break;
            }

            DataRow targetRow = _resultsTable.Rows[0];
            double originalTonnes = Convert.ToDouble(targetRow["Tonnes"]);
            double operandOne = Convert.ToDouble(_resultsTable.Rows[1]["Tonnes"]);
            double operandTwo = Convert.ToDouble(_resultsTable.Rows[2]["Tonnes"]);

            // Act
            F1F2F3ReportEngine.CalculateF1F2F3Factors(_resultsTable);

            // Assert
            Assert.That(targetRow["Tonnes"], Is.Not.EqualTo(originalTonnes));
            // Representative of all attributes, as they all have the same calculations.
            if (checkRatios)
                Assert.That(Math.Abs(Convert.ToDouble(targetRow["Tonnes"]) - operandOne / operandTwo), Is.LessThan(TOLERANCE));

            if (checkDifferences)
                Assert.That(Convert.ToDouble(targetRow["TonnesDifference"]), Is.EqualTo(operandOne - operandTwo));
        }

        private void ConfigureDataTable()
        {
            _resultsTable = new DataTable("Values");
            _resultsTable.Columns.Add(ColumnNames.TAG_ID);
            _resultsTable.Columns.Add(ColumnNames.REPORT_TAG_ID);
            _resultsTable.Columns.Add("CalcId");
            _resultsTable.Columns.Add("Description");
            _resultsTable.Columns.Add(ColumnNames.TYPE);
            _resultsTable.Columns.Add(ColumnNames.CALCULATION_DEPTH);
            _resultsTable.Columns.Add("InError");
            _resultsTable.Columns.Add("ErrorMessage");
            _resultsTable.Columns.Add(ColumnNames.PRODUCT_SIZE);
            _resultsTable.Columns.Add(ColumnNames.SORT_KEY);
            _resultsTable.Columns.Add(ColumnNames.DATE_CAL);
            _resultsTable.Columns.Add(ColumnNames.DATE_FROM);
            _resultsTable.Columns.Add(ColumnNames.DATE_TO);
            _resultsTable.Columns.Add(ColumnNames.LOCATION_ID);
            _resultsTable.Columns.Add(ColumnNames.MATERIAL_TYPE_ID);
            _resultsTable.Columns.Add(ColumnNames.RESOURCE_CLASSIFICATION);
            _resultsTable.Columns.Add("Tonnes");
            _resultsTable.Columns.Add("Volume");
            _resultsTable.Columns.Add("DodgyAggregateGradeTonnes");
            _resultsTable.Columns.Add("Density");
            _resultsTable.Columns.Add("Fe");
            _resultsTable.Columns.Add("P");
            _resultsTable.Columns.Add("SiO2");
            _resultsTable.Columns.Add("Al2O3");
            _resultsTable.Columns.Add("LOI");
            _resultsTable.Columns.Add("H2O");
            _resultsTable.Columns.Add("H2O-As-Dropped");
            _resultsTable.Columns.Add("H2O-As-Shipped");
            _resultsTable.Columns.Add("Ultrafines");
            _resultsTable.Columns.Add(ColumnNames.ROOT_CALC_ID);
            _resultsTable.Columns.Add("PresentationEditable");
            _resultsTable.Columns.Add("PresentationLocked");
            _resultsTable.Columns.Add("PresentationValid");
            _resultsTable.Columns.Add("TonnesDifference");
            _resultsTable.Columns.Add("VolumeDifference");
            _resultsTable.Columns.Add("DensityDifference");
            _resultsTable.Columns.Add("FeDifference");
            _resultsTable.Columns.Add("PDifference");
            _resultsTable.Columns.Add("SiO2Difference");
            _resultsTable.Columns.Add("Al2O3Difference");
            _resultsTable.Columns.Add("LOIDifference");
            _resultsTable.Columns.Add("H2ODifference");
            _resultsTable.Columns.Add("H2O-As-DroppedDifference");
            _resultsTable.Columns.Add("H2O-As-ShippedDifference");
            _resultsTable.Columns.Add("UltrafinesDifference");
            _resultsTable.Columns.Add("DateText");
        }

        /// <summary>
        /// Helper so we're not repeating code.
        /// </summary>
        /// <param name="calcIdOne">Calc Id such as F1.CalculationId for Row 1 (a.k.a. target row)</param>
        /// <param name="calcIdTwo">Calc Id such as $"F1{ModelGradeControl.CalculationId}" for Row 2 (used for: Row 2 / Row 3)</param>
        /// <param name="calcIdThree">Calc Id such as $"F1{ModelMining.CalculationId}" for Row 3 (used for: Row 2 / Row 3)</param>
        /// <param name="productSize">Product Size for all 3 rows.</param>
        private void AddRows(string calcIdOne, string calcIdTwo, string calcIdThree, string productSize)
        {
            DataRow targetFactor = _resultsTable.NewRow();
            targetFactor[ColumnNames.TAG_ID] = calcIdOne;
            targetFactor[ColumnNames.PRODUCT_SIZE] = productSize;
            targetFactor[ColumnNames.RESOURCE_CLASSIFICATION] = string.Empty;
            targetFactor["Tonnes"] = 21.71428; // Taken from real data
            _resultsTable.Rows.Add(targetFactor);

            // This is used to recalculate the factor.
            DataRow rowTwo = _resultsTable.NewRow();
            rowTwo[ColumnNames.TAG_ID] = calcIdTwo;
            rowTwo[ColumnNames.PRODUCT_SIZE] = productSize;
            rowTwo[ColumnNames.RESOURCE_CLASSIFICATION] = string.Empty;
            rowTwo["Tonnes"] = 7371516.13201; // Taken from real data
            _resultsTable.Rows.Add(rowTwo);

            // This is used to recalculate the factor.
            DataRow rowThree = _resultsTable.NewRow();
            rowThree[ColumnNames.TAG_ID] = calcIdThree;
            rowThree[ColumnNames.PRODUCT_SIZE] = productSize;
            rowThree[ColumnNames.RESOURCE_CLASSIFICATION] = string.Empty;
            rowThree["Tonnes"] = 7766238.49068; // Taken from real data
            _resultsTable.Rows.Add(rowThree);
        }
    }
}