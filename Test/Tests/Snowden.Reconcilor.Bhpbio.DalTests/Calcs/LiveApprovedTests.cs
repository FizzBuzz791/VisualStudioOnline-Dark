using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;

using Snowden.Reconcilor.Bhpbio.Report;
using Snowden.Reconcilor.Bhpbio.Report.Types;

using Calc = Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.Calc;
using Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions;
using System.Data;
using Snowden.Bcd;
using Snowden.Bcd.ProductConfiguration;


namespace Snowden.Tests
{
    /// <summary>
    /// Summary description for CalcTests
    /// </summary>
    [TestClass]
    public class LiveApprovedTests
    {

        // change this date to whatever you want, and then run the tests for this class
        //
        // Note: the tests here do NOT unapproved and approve the data, you need to do this manually
        // in order for the test to complete successfully
        private static DateTime MONTH_TO_TEST = DateTime.Parse("2015-06-01");
        private static bool TEST_H2O_GRADES = false;

        // a difference of more than this will cause the test to fail
        private static double TONNES_ERROR_THRESHOLD = 10.0; 
        private static double GRADE_ERROR_THRESHOLD = 0.009;

        private static ReportSession _session = null;
        private static DateTime _dateFrom;
        private static DateTime _dateTo;
        private static int _locationId = -1;
        private static DataTable _waioLiveData = null;
        private static DataTable _waioApprovedData = null;

        public LiveApprovedTests()
        {
        }
 
         //Use ClassInitialize to run code before running the first test in the class
         [ClassInitialize()]
         public static void Initialize(TestContext testContext) 
         {
             _session = new ReportSession();
             _session.SetupDal(GetConnectionString());
             _session.Context = ReportContext.LiveOnly;
             
             
             _locationId = 1;
             SetParamters(false);
             _session.IncludeProductSizeBreakdown = true;
             _waioLiveData = GetData(ReportContext.LiveOnly);
             _waioApprovedData = GetData(ReportContext.Standard);

             // back to the default values
             _locationId = -1;

         }

         public static ConfigurationManager GetProductConfiguration()
         {
             return new Snowden.Bcd.ProductConfiguration.ConfigurationManager("../../../../ProductConfiguration.xml");
         }

         public static string GetConnectionString()
         {
             ConfigurationManager config = GetProductConfiguration();
             config.Open();
             return config.GetDatabaseConfiguration("Main").GenerateSqlClientConnectionString("ReconcilorUI");
         }

         public static void SetParamters(bool includeChildren)
         {
             if (_locationId == -1)
             {
                 _locationId = 4;
             }

             _dateFrom = MONTH_TO_TEST;
             _dateTo = _dateFrom.AddMonths(1).AddDays(-1);
             _session.IncludeProductSizeBreakdown = false;
             _session.CalculationParameters(_dateFrom, _dateTo, ReportBreakdown.Monthly, _locationId, includeChildren);
         }

         [TestMethod]
         public void Compare_Live_And_Approved_Data_AreaC()
         {
             _locationId = 6;
             Compare_Live_And_Approved_Data();
         }

         [TestMethod]
         public void Compare_Live_And_Approved_Data_NJV()
         {
             _locationId = 8;
             Compare_Live_And_Approved_Data();
         }

         [TestMethod]
         public void Compare_Live_And_Approved_Data_Yandi()
         {
             _locationId = 2;
             Compare_Live_And_Approved_Data();
         }

         [TestMethod]
         public void Compare_Live_And_Approved_Data_Yarrie()
         {
             _locationId = 4;
             Compare_Live_And_Approved_Data();
         }

         [TestMethod]
         public void Compare_Live_And_Approved_Data_Jimblebar()
         {
             _locationId = 133098;
             Compare_Live_And_Approved_Data();
         }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F1()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F1Factor");
        }
        
        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F15()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F15Factor");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F2()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F2Factor");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25Factor");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_OFR()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25OreForRail");
        }
        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_MMRE()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25MiningModelOreForRailEquivalent");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_MMCE()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25MiningModelCrusherEquivalent");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_PC()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25PostCrusherStockpileDelta");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_SPC()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25SitePostCrusherStockpileDelta");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F25_HPC()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F25HubPostCrusherStockpileDelta");
        }

        [TestMethod]
        public void Compare_Live_And_Approved_WAIO_Calculation_F3()
        {
            Compare_Live_And_Approved_WAIO_Calculation("F3Factor");
        }

        public void Compare_Live_And_Approved_WAIO_Calculation(string reportTagId)
        {
            var attributes = GetAttributes(includeVolume: true, includeMoisture: TEST_H2O_GRADES); 

            var rows1 = _waioLiveData.AsEnumerable().Where(r => r["ReportTagId"].ToString() == reportTagId).ToList();
            var rows2 = _waioApprovedData.AsEnumerable().Where(r => r["ReportTagId"].ToString() == reportTagId).ToList();

            Assert.IsFalse(rows1.Count == 0, "No values with that reportTagId (" + reportTagId + ")");

            CompareDataTables(rows1, rows2, attributes);
        }

        public void Compare_Live_And_Approved_Data()
        {
            var attributes = GetAttributes(includeVolume: false, includeMoisture: TEST_H2O_GRADES); 

            SetParamters(false);

            var liveData = GetData(ReportContext.LiveOnly);
            var approvedData = GetData(ReportContext.Standard);
            CompareDataTables(liveData, approvedData, attributes);
        }

        public string[] GetAttributes(bool includeVolume, bool includeMoisture)
        {
            var attributes = new List<string> { "Tonnes", "Fe", "P", "SiO2", "Al2O3", "LOI", };

            if(includeVolume) 
            {
                attributes.Add("Volume");
                attributes.Add("Density");
            }

            if (includeMoisture)
            {
                attributes.Add("H2O");
                attributes.Add("H2O-As-Dropped");
                attributes.Add("H2O-As-Shipped");
            }

            return attributes.ToArray();
        }

        //[TestMethod]
        //public void Compare_Live_And_Approved_Data_With_Children()
        //{
        //    var attributes = new string[] { "Tonnes", "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O", "H2O-As-Dropped", "H2O-As-Shipped" };

        //    SetParamters(true);
        //    var liveData = GetData(ReportContext.LiveOnly);
            
        //    SetParamters(true);
        //    var approvedData = GetData(ReportContext.Standard);

        //    CompareDataTables(liveData, approvedData, attributes);

        //}


        //[TestMethod]
        //public void Compare_Live_And_Approved_Data_With_Children_Volumes()
        //{
        //    var attributes = new string[] { "Tonnes", "Volume", "Density" };

        //    SetParamters(true);
        //    var liveData = GetData(ReportContext.LiveOnly);

        //    SetParamters(true);
        //    var approvedData = GetData(ReportContext.Standard);

        //    CompareDataTables(liveData, approvedData, attributes);

        //}

        public void CompareDataTables(DataTable table1, DataTable table2, string[] attributes)
        {
            CompareDataTables(table1.AsEnumerable(), table2.AsEnumerable(), attributes);
        }

        public void CompareDataTables(IEnumerable<DataRow> rows1, IEnumerable<DataRow> rows2, string[] attributes)
        {

            var data1 = rows1
                .Where(r => Convert.IsDBNull(r["PresentationValid"]) ? false : Convert.ToBoolean(r["PresentationValid"]))
                .OrderBy(r => r["DateFrom"])
                .ThenBy(r => r["LocationId"])
                .ThenBy(r => r["ReportTagId"])
                .ThenBy(r => r["ProductSize"])
                .ToList();

            var data2 = rows2
                .Where(r => Convert.IsDBNull(r["PresentationValid"]) ? false : Convert.ToBoolean(r["PresentationValid"]))
                .OrderBy(r => r["DateFrom"])
                .ThenBy(r => r["LocationId"])
                .ThenBy(r => r["ReportTagId"])
                .ThenBy(r => r["ProductSize"])
                .ToList();

            Assert.AreEqual(data1.Count, data2.Count, "Tables have a different number of rows");

            for (int i = 0; i < data1.Count; i++)
            {
                var row1 = data1[i];
                var row2 = data2[i];

                Assert.AreEqual(row1["DateFrom"], row2["DateFrom"]);
                Assert.AreEqual(row1["LocationId"], row2["LocationId"]);
                Assert.AreEqual(row1["ReportTagId"], row2["ReportTagId"]);
                Assert.AreEqual(row1["ProductSize"], row2["ProductSize"]);

                foreach (string attribute in attributes)
                {
                    var msg = String.Format("Attribute '{0}' doesn't match ('{1}', '{2}') Date:{3}, Location: {4} Tag:{5} ({6})", attribute, row1[attribute], row2[attribute], row1["DateFrom"], row1["LocationId"], row1["ReportTagId"], row1["ProductSize"]);

                    if (row1[attribute].GetType() == typeof(double) && row2[attribute].GetType() == typeof(double))
                    {
                        double delta = (attribute == "Tonnes" || attribute == "Volume") ? TONNES_ERROR_THRESHOLD : GRADE_ERROR_THRESHOLD;
                        Assert.AreEqual(Convert.ToDouble(row1[attribute]), Convert.ToDouble(row2[attribute]), delta, msg);
                    }
                    else
                    {
                        Assert.AreEqual(row1[attribute], row2[attribute], msg);
                    }
                    

                }
            }
        }


        public static DataTable GetData(ReportContext context)
        {
            _session.Context = context;
            return ReconciliationDataExportReport.GetF1F2F3AllLocationsReconciliationReportData(
                _session,
                _session.RequestParameter.LocationId.Value,
                _session.RequestParameter.StartDate,
                _session.RequestParameter.EndDate,
                "MONTH",
                _session.RequestParameter.ChildLocations
            );

        }


    }
}
