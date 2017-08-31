using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.Report.Constants;
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
            const double tonnesOne = 100;
            const double tonnesTwo = 2;
            const double volumeOne = 3;
            const double volumeTwo = 4;
            const double dodgyAggregateGradeTonnesOne = 5;
            const double dodgyAggregateGradeTonnesTwo = 6;
            const bool dodgyAggregateEnabledOne = true;
            const bool dodgyAggregateEnabledTwo = false;
            const double feOne = 7;
            const double feTwo = 8;
            const double pOne = 9;
            const double pTwo = 10;
            const double sio2One = 11;
            const double sio2Two = 12;
            const double al2O3One = 13;
            const double al2O3Two = 14;
            const double loiOne = 15;
            const double loiTwo = 16;
            const double densityOne = 17;
            const double densityTwo = 18;
            const double ultrafinesOne = 19;
            const double ultrafinesTwo = 20;
            const double h2OOne = 21;
            const double h2OTwo = 22;
            const double h2ODroppedOne = 23;
            const double h2ODroppedTwo = 24;
            const double h2OShippedOne = 25;
            const double h2OShippedTwo = 26;
            const int locationOne = 27;
            const int locationTwo = 28;

            _sut.Add(new CalculationResultRecord
            {
                CalendarDate = calendarDateOne,
                DateFrom = datefromOne,
                DateTo = dateToOne,
                ResourceClassification = "Unclass",
                ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL,
                Tonnes = tonnesOne,
                Volume = volumeOne,
                DodgyAggregateGradeTonnes = dodgyAggregateGradeTonnesOne,
                DodgyAggregateEnabled = dodgyAggregateEnabledOne,
                Fe = feOne,
                P = pOne,
                SiO2 = sio2One,
                Al2O3 = al2O3One,
                Loi = loiOne,
                Density = densityOne,
                UltraFines = ultrafinesOne,
                H2O = h2OOne,
                H2ODropped = h2ODroppedOne,
                H2OShipped = h2OShippedOne,
                LocationId = locationOne
            });
            _sut.Add(new CalculationResultRecord
            {
                CalendarDate = calendarDateTwo,
                DateFrom = dateFromTwo,
                DateTo = dateToTwo,
                ResourceClassification = "Unclass",
                ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL,
                Tonnes = tonnesTwo,
                Volume = volumeTwo,
                DodgyAggregateGradeTonnes = dodgyAggregateGradeTonnesTwo,
                DodgyAggregateEnabled = dodgyAggregateEnabledTwo,
                Fe = feTwo,
                P = pTwo,
                SiO2 = sio2Two,
                Al2O3 = al2O3Two,
                Loi = loiTwo,
                Density = densityTwo,
                UltraFines = ultrafinesTwo,
                H2O = h2OTwo,
                H2ODropped = h2ODroppedTwo,
                H2OShipped = h2OShippedTwo,
                LocationId = locationTwo
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