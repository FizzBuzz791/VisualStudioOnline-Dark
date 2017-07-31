using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;

using Snowden.Reconcilor.Bhpbio.Report;
using Snowden.Reconcilor.Bhpbio.Report.Types;

using Calc = Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.Calc;

namespace Snowden.Tests
{
    /// <summary>
    /// Summary description for CalcTests
    /// </summary>
    [TestClass]
    public class CalcTests
    {
        private static ReportSession _session = null;
        private static string _connectionString = @"Data Source=RECONCILOR1\SQL2005;Initial Catalog=ReconcilorBhpbioV64;User Id=ReconcilorUI;Password=Vap0rware;";

        public CalcTests()
        {
        }

        #region Useless Properties
        private TestContext testContextInstance;
        public TestContext TestContext
        {
            get
            {
                return testContextInstance;
            }
            set
            {
                testContextInstance = value;
            }
        }
        #endregion

        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //

        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        // Use TestInitialize to run code before running each test 
        // [TestInitialize()]
        // public void MyTestInitialize() { }
        //
        // Use TestCleanup to run code after each test has run
        // [TestCleanup()]
        // public void MyTestCleanup() { }
        //
        #endregion

         //Use ClassInitialize to run code before running the first test in the class
         [ClassInitialize()]
         public static void MyClassInitialize(TestContext testContext) 
         {
             _session = new ReportSession();
             _session.SetupDal(_connectionString);
             _session.Context = ReportContext.LiveOnly;

             var dateFrom = new DateTime(2013, 1, 1);
             var dateTo = new DateTime(2013, 03, 31);
             var locationId = 8;

             _session.IncludeProductSizeBreakdown = false;
             _session.CalculationParameters(dateFrom, dateTo, ReportBreakdown.Monthly, locationId, false);

         }

        [TestMethod]
        public void ShortTermGeology_Calc_Test()
        {
            Test_Calculation(Calc.CalcType.ModelShortTermGeology);
        }

        [TestMethod]
        public void F15_Calc_Test()
        {
            Test_Calculation(Calc.CalcType.F15);
        }

        public CalculationResult Test_Calculation(Calc.CalcType calcType)
        {
            var result = Calc.Calculation.Create(calcType, _session).Calculate();
            Assert.IsTrue(result.Count > 0, "No Results");
            Assert.IsNotNull(result[0].Tonnes, "No tonnes data for first result");
            Assert.IsNotNull(result[0].Fe, "No Fe data for first result");
            
            return result;
        }
    }
}
