using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.Constants;
using Snowden.Reconcilor.Bhpbio.Report.Enums;
using Snowden.Reconcilor.Bhpbio.Report.Types;

namespace Snowden.Reconcilor.Bhpbio.Report.UnitTests.Types
{
    [TestFixture]
    public class CalculationResultTests
    {
        private CalculationResult _sut;

        [SetUp]
        public void Setup()
        {
            _sut = new CalculationResult(CalculationResultType.Tonnes);
            GenerateRecordsForTest();
        }

        [Test]
        public void AggregatesResultsCorrectlyForDefaultGrouping() // A.K.A Date grouping
        {
            // Arrange
            IEnumerable<CalculationResultRecord> expectedAggregatedRecords =
                GenerateExpectedResultForGrouping(t => t.CalendarDate).ToList();

            // Act
            IEnumerable<CalculationResultRecord> result = _sut.AggregateRecords();
            IEnumerable<CalculationResultRecord> calculationResultRecords =
                result as IList<CalculationResultRecord> ?? result.ToList();

            // Assert
            Assert.That(calculationResultRecords.Count(), Is.EqualTo(expectedAggregatedRecords.Count()));
            Assert.That(calculationResultRecords.First(), Is.EqualTo(expectedAggregatedRecords.First()));
        }

        [Test]
        public void AggregatesResultsCorrectlyForMaterialTypeGrouping()
        {
            // Arrange
            IEnumerable<CalculationResultRecord> expectedAggregatedRecords =
                GenerateExpectedResultForGrouping(t => t.MaterialTypeId).ToList();

            // Act
            IEnumerable<CalculationResultRecord> result = _sut.AggregateRecords(true);
            IEnumerable<CalculationResultRecord> calculationResultRecords =
                result as IList<CalculationResultRecord> ?? result.ToList();

            // Assert
            Assert.That(calculationResultRecords.Count(), Is.EqualTo(expectedAggregatedRecords.Count()));
            Assert.That(calculationResultRecords.First(), Is.EqualTo(expectedAggregatedRecords.First()));
        }

        [Test]
        public void AggregatesResultsCorrectlyForLocationGrouping()
        {
            // Arrange
            IEnumerable<CalculationResultRecord> expectedAggregatedRecords =
                GenerateExpectedResultForGrouping(t => t.LocationId).ToList();

            // Act
            IEnumerable<CalculationResultRecord> result = _sut.AggregateRecords(false, true);
            IEnumerable<CalculationResultRecord> calculationResultRecords =
                result as IList<CalculationResultRecord> ?? result.ToList();

            // Assert
            Assert.That(calculationResultRecords.Count(), Is.EqualTo(expectedAggregatedRecords.Count()));
            Assert.That(calculationResultRecords.First(), Is.EqualTo(expectedAggregatedRecords.First()));
        }

        [Test]
        public void AggregatesResultsCorrectlyForStratigraphyGrouping()
        {
            // Arrange
            IEnumerable<CalculationResultRecord> expectedAggregatedRecords =
                GenerateExpectedResultForGrouping(t => t.StratNum).ToList();

            // Act
            IEnumerable<CalculationResultRecord> result = _sut.AggregateRecords(false, false, false, true);
            IEnumerable<CalculationResultRecord> calculationResultRecords =
                result as IList<CalculationResultRecord> ?? result.ToList();

            // Assert
            Assert.That(calculationResultRecords.Count(), Is.EqualTo(expectedAggregatedRecords.Count()));
            Assert.That(calculationResultRecords.First(), Is.EqualTo(expectedAggregatedRecords.First()));
        }

        [Test]
        public void AggregatesResultsCorrectlyForWeatheringGrouping()
        {
            // Arrange
            IEnumerable<CalculationResultRecord> expectedAggregatedRecords =
                GenerateExpectedResultForGrouping(t => t.Weathering).ToList();

            // Act
            IEnumerable<CalculationResultRecord> result = _sut.AggregateRecords(false, false, false, false, true);
            IEnumerable<CalculationResultRecord> calculationResultRecords =
                result as IList<CalculationResultRecord> ?? result.ToList();

            // Assert
            Assert.That(calculationResultRecords.Count(), Is.EqualTo(expectedAggregatedRecords.Count()));
            Assert.That(calculationResultRecords.First(), Is.EqualTo(expectedAggregatedRecords.First()));
        }

        [TestCase(CalculationType.Addition)]
        [TestCase(CalculationType.Subtraction)]
        [TestCase(CalculationType.Division)]
        [TestCase(CalculationType.Division, true, "Factor")]
        [TestCase(CalculationType.Difference)]
        [TestCase(CalculationType.Ratio)]
        public void PerformCalculation_HandlesAllCalcuationTypes(CalculationType calcType,
            bool breakdownFactorByMaterialType = false, string calcId = "Unknown")
        {
            // Arrange
            CalculationResult secondTerm = new CalculationResult(CalculationResultType.Tonnes)
            {
                new CalculationResultRecord
                {
                    CalendarDate = new DateTime(2017, 5, 5),
                    LocationId = 27,
                    ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL,
                    ResourceClassification = "Unclass",
                    StratNum = "1234",
                    Weathering = 29,
                    // Records above this line are intentionally the same so that calculations actually match and get processed.
                    Tonnes = 2,
                    Volume = 6,
                    Fe = 12,
                    DodgyAggregateGradeTonnes = 10
                }
            };
        
            IEnumerable<CalculationResultRecord> aggregatedRecords = _sut.AggregateRecords(breakdownFactorByMaterialType, true, true);
            CalculationResultRecord testAggregateRecord = aggregatedRecords.First();
            IEnumerable<CalculationResultRecord> aggregatedTerms = secondTerm.AggregateRecords(breakdownFactorByMaterialType, true, true);
            CalculationResultRecord testAggregatedTerm = aggregatedTerms.First();
        
            // Act
            CalculationResult result = CalculationResult.PerformCalculation(_sut, secondTerm, calcType, breakdownFactorByMaterialType, calcId);
        
            // Assert
            switch (calcType)
            {
                case CalculationType.Addition:
                    CalculationResultRecord addedRecords = CalculationResultRecord.Add(testAggregateRecord, testAggregatedTerm);
                    Assert.That(result.First().Tonnes, Is.EqualTo(addedRecords.Tonnes));
                    Assert.That(result.First().Fe, Is.EqualTo(addedRecords.Fe));
                    break;
                case CalculationType.Subtraction:
                    CalculationResultRecord subtractedRecords = CalculationResultRecord.Subtract(testAggregateRecord, testAggregatedTerm);
                    Assert.That(result.First().Tonnes, Is.EqualTo(subtractedRecords.Tonnes));
                    Assert.That(result.First().Fe, Is.EqualTo(subtractedRecords.Fe));
                    break;
                case CalculationType.Division:
                    CalculationResultRecord dividedRecords = CalculationResultRecord.Divide(testAggregateRecord, testAggregatedTerm);
                    Assert.That(result.First().Tonnes, Is.EqualTo(dividedRecords.Tonnes));
                    Assert.That(result.First().Fe, Is.EqualTo(dividedRecords.Fe));
                    break;
                case CalculationType.Difference:
                    CalculationResultRecord diffedRecords = CalculationResultRecord.Difference(testAggregateRecord, testAggregatedTerm);
                    Assert.That(result.First().Tonnes, Is.EqualTo(diffedRecords.Tonnes));
                    Assert.That(result.First().Fe, Is.EqualTo(diffedRecords.Fe));
                    break;
                case CalculationType.Ratio:
                    CalculationResultRecord ratioRecords = CalculationResultRecord.Multiply(testAggregateRecord, testAggregatedTerm);
                    Assert.That(result.First().Tonnes, Is.EqualTo(ratioRecords.Tonnes));
                    Assert.That(result.First().Fe, Is.EqualTo(ratioRecords.Fe));
                    break;
            }
        }

        private void GenerateRecordsForTest()
        {
            DateTime calendarDateOne = new DateTime(2017, 5, 5);
            DateTime calendarDateTwo = new DateTime(2017, 6, 6);
            DateTime datefromOne = new DateTime(2017, 1, 1);
            DateTime dateFromTwo = new DateTime(2017, 2, 2);
            DateTime dateToOne = new DateTime(2017, 3, 3);
            DateTime dateToTwo = new DateTime(2017, 4, 4);
            const double TONNES_ONE = 100;
            const double TONNES_TWO = 2;
            const double VOLUME_ONE = 3;
            const double VOLUME_TWO = 4;
            const double DODGY_AGGREGATE_GRADE_TONNES_ONE = 5;
            const double DODGY_AGGREGATE_GRADE_TONNES_TWO = 6;
            const bool DODGY_AGGREGATE_ENABLED_ONE = true;
            const bool DODGY_AGGREGATE_ENABLED_TWO = false;
            const double FE_ONE = 7;
            const double FE_TWO = 8;
            const double P_ONE = 9;
            const double P_TWO = 10;
            const double SIO2_ONE = 11;
            const double SIO2_TWO = 12;
            // ReSharper disable InconsistentNaming
            const double AL2O3_ONE = 13;
            const double AL2O3_TWO = 14;
            // ReSharper restore InconsistentNaming
            const double LOI_ONE = 15;
            const double LOI_TWO = 16;
            const double DENSITY_ONE = 17;
            const double DENSITY_TWO = 18;
            const double ULTRAFINES_ONE = 19;
            const double ULTRAFINES_TWO = 20;
            // ReSharper disable InconsistentNaming
            const double H2O_ONE = 21;
            const double H2O_TWO = 22;
            const double H2O_DROPPED_ONE = 23;
            const double H2O_DROPPED_TWO = 24;
            const double H2O_SHIPPED_ONE = 25;
            const double H2O_SHIPPED_TWO = 26;
            // ReSharper restore InconsistentNaming
            const int LOCATION_ONE = 27;
            const int LOCATION_TWO = 28;
            const string STRATNUM_ONE = "1234";
            const string STRATNUM_TWO = "5678";
            const int WEATHERING_ONE = 29;
            const int WEATHERING_TWO = 30;

            _sut.Add(new CalculationResultRecord
            {
                CalendarDate = calendarDateOne,
                DateFrom = datefromOne,
                DateTo = dateToOne,
                ResourceClassification = "Unclass",
                ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL,
                Tonnes = TONNES_ONE,
                Volume = VOLUME_ONE,
                DodgyAggregateGradeTonnes = DODGY_AGGREGATE_GRADE_TONNES_ONE,
                DodgyAggregateEnabled = DODGY_AGGREGATE_ENABLED_ONE,
                Fe = FE_ONE,
                P = P_ONE,
                SiO2 = SIO2_ONE,
                Al2O3 = AL2O3_ONE,
                Loi = LOI_ONE,
                Density = DENSITY_ONE,
                UltraFines = ULTRAFINES_ONE,
                H2O = H2O_ONE,
                H2ODropped = H2O_DROPPED_ONE,
                H2OShipped = H2O_SHIPPED_ONE,
                LocationId = LOCATION_ONE,
                StratNum = STRATNUM_ONE,
                Weathering = WEATHERING_ONE
            });
            _sut.Add(new CalculationResultRecord
            {
                CalendarDate = calendarDateTwo,
                DateFrom = dateFromTwo,
                DateTo = dateToTwo,
                ResourceClassification = "Unclass",
                ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL,
                Tonnes = TONNES_TWO,
                Volume = VOLUME_TWO,
                DodgyAggregateGradeTonnes = DODGY_AGGREGATE_GRADE_TONNES_TWO,
                DodgyAggregateEnabled = DODGY_AGGREGATE_ENABLED_TWO,
                Fe = FE_TWO,
                P = P_TWO,
                SiO2 = SIO2_TWO,
                Al2O3 = AL2O3_TWO,
                Loi = LOI_TWO,
                Density = DENSITY_TWO,
                UltraFines = ULTRAFINES_TWO,
                H2O = H2O_TWO,
                H2ODropped = H2O_DROPPED_TWO,
                H2OShipped = H2O_SHIPPED_TWO,
                LocationId = LOCATION_TWO,
                StratNum = STRATNUM_TWO,
                Weathering = WEATHERING_TWO
            });
        }

        private IEnumerable<CalculationResultRecord> GenerateExpectedResultForGrouping<T>(Expression<Func<CalculationResultRecord, T>> groupby)
        {
            PropertyInfo propInfo = (PropertyInfo)((MemberExpression)groupby.Body).Member;
            Func<CalculationResultRecord, T> compiled = groupby.Compile();

            // CalendarDate is "hard-coded" because all calls in the system group by date.
            return _sut.GroupBy(t => new { t.CalendarDate, t.ProductSize, t.ResourceClassification, compiled })
                .Select(grouping => new CalculationResultRecord
                {
                    CalendarDate = grouping.Key.CalendarDate,
                    MaterialTypeId = propInfo.Name == nameof(CalculationResultRecord.MaterialTypeId) ? (int?)(object)grouping.Key.compiled(grouping.First()) : null,
                    LocationId = propInfo.Name == nameof(CalculationResultRecord.LocationId) ? (int?)(object)grouping.Key.compiled(grouping.First()) : null,
                    StratNum = propInfo.Name == nameof(CalculationResultRecord.StratNum) ? (string)(object)grouping.Key.compiled(grouping.First()) : null,
                    Weathering = propInfo.Name == nameof(CalculationResultRecord.Weathering) ? (int?)(object)grouping.Key.compiled(grouping.First()) : null,
                    DateFrom = grouping.Min(t => t.DateFrom),
                    DateTo = grouping.Max(t => t.DateTo),
                    ResourceClassification = grouping.First().ResourceClassification,
                    ProductSize = grouping.First().ProductSize,
                    Tonnes = grouping.Sum(t => t.Tonnes),
                    Volume = grouping.Sum(t => t.Volume),
                    DodgyAggregateGradeTonnes = grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    DodgyAggregateEnabled = grouping.Max(t => t.DodgyAggregateEnabled),
                    Fe = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.Fe) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    P = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.P) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    SiO2 = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.SiO2) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    Al2O3 = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.Al2O3) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    Loi = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.Loi) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    Density = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.Density) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    UltraFines = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.UltraFines) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    H2O = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.H2O) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    H2ODropped = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.H2ODropped) / grouping.Sum(t => t.DodgyAggregateGradeTonnes),
                    H2OShipped = grouping.Sum(t => t.DodgyAggregateGradeTonnes * t.H2OShipped) / grouping.Sum(t => t.DodgyAggregateGradeTonnes)
                })
                .ToList();
        }
    }
}