using System;
using System.Text;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Data;
using System.IO;
using System.Data.SqlClient;
using System.Configuration;
using System.Linq;
using System.Collections;

namespace Snowden.Reconcilor.Bhpbio.DalTests.Procedures
{
    /// <summary>
    /// Test Fixtue for the GetBhpbioReportDataBlockModel procedure
    /// </summary>
    [TestClass]
    public class GetBhpbioReportDataBlockModelFixture
    {
        private const string _productConfigurationPathKeyName = "ProductConfigurationPath";

        private const string _procedureForActualResults = "GetBhpbioReportDataBlockModel";
        private const string _procedureForExpectedResults = "GetBhpbioReportDataBlockModelOld";

        private const string _defaultDatabaseConfigurationName = "Main";
        private const string _defaultDatabaseUserName = "ReconcilorUI";


        public GetBhpbioReportDataBlockModelFixture()
        {
            //
            // TODO: Add constructor logic here
            //
        }

        private TestContext testContextInstance;

        /// <summary>
        ///Gets or sets the test context which provides
        ///information about and functionality for the current test run.
        ///</summary>
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

        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
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

        /// <summary>
        /// This test verifies that multiple versions of the stored procedure produce equivalent results
        /// </summary>
        [TestMethod]
        public void VerifyStoredProcedureVersionsProduceEquivalentResults()
        {

            // NOTE: Before running this test:
            //  .. ensure an old version of the stored procedure has been deployed to the database with the name defined in: _procedureForExpectedResults
            //  .. ensure the App.Config file has an AppSetting for the ProductConfigurationPath.. the relative path level may need to be adjusted

            var liveFlagValues = new bool[] { true, false };
            var approvedFlagvalues = new bool[] { true, false };
            var blockModelValues = new string[] { "Grade Control", "Mining", "Geology", null };
            var includeChildLocationValues = new bool[] { true, false };
            var includeInactiveChildLocationValues = new bool[] { true, false };
            var includeLumpFinesValues = new bool[] { true, false };
            var highGradeOnlyValues = new bool[] { true, false };
            var includeResourceClassificationValues = new bool[] { true, false };

            var startDate = new DateTime(2015, 01, 01);
            var endDate = new DateTime(2015, 03, 31);
            string dateBreakdown = "MONTH";

            var locationId = 8;

            foreach(var liveFlag in liveFlagValues)
            {
                foreach (var approvedFlag in approvedFlagvalues)
                {
                    if (!(liveFlag || approvedFlag))
                    {
                        continue; // don't test when both live and approve are false
                    }

                    foreach(var blockModel in blockModelValues)
                    {
                        foreach (var includeChildLocations in includeChildLocationValues)
                        {

                            foreach (var includeInactive in includeInactiveChildLocationValues)
                            {
                                foreach (var includeLumpFines in includeLumpFinesValues)
                                {
                                    foreach (var includeHighGradeOnly in highGradeOnlyValues)
                                    {
                                        foreach (var includeResourceClassification in includeResourceClassificationValues)
                                        {
                                            AssertActualMatchesExpected(startDate, endDate, dateBreakdown, locationId, includeChildLocations, blockModel, includeInactive, includeLumpFines, includeHighGradeOnly, includeResourceClassification, liveFlag, approvedFlag);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        private void AssertActualMatchesExpected(DateTime startDate, DateTime endDate, string dateBreakdown, int locationId, bool childLocations,
            string blockModelName, bool includeInactiveChildLocations, bool includeLumpFines, bool highGradeOnly, bool includeResourceClassification, bool includeLiveData, bool includeApprovedData)
        {
            var connectionString = GetConnectionString(_defaultDatabaseConfigurationName, _defaultDatabaseUserName);
            var connection = new SqlConnection(connectionString);

            var optionsText = string.Format("Options: startDate: {0}, endDate: {1}, dateBreakdown:{2}, locationId: {3}, childLocations: {4}, blockModelName: {5}, includeInactiveChildLocations: {6}, includeLumpFines: {7}, highGradeOnly: {8}, includeResourceClassification: {9}, includeLiveData: {10}, includeApprovedData: {11}",
                startDate, endDate, (dateBreakdown == null) ? "null" : dateBreakdown, locationId, childLocations, (blockModelName == null) ? "null" : blockModelName, includeInactiveChildLocations, includeLumpFines, highGradeOnly, includeResourceClassification, includeLiveData, includeApprovedData);

            System.Diagnostics.Debug.WriteLine(string.Format("About to test: {0}", optionsText));

            var actual = ExecuteProcedure(connection, _procedureForActualResults, startDate, endDate,
                dateBreakdown, locationId, childLocations, blockModelName, includeInactiveChildLocations, includeLumpFines, highGradeOnly, includeResourceClassification, includeLiveData, includeApprovedData);

            var expected = ExecuteProcedure(connection, _procedureForExpectedResults, startDate, endDate,
                dateBreakdown, locationId, childLocations, blockModelName, includeInactiveChildLocations, includeLumpFines, highGradeOnly, includeResourceClassification, includeLiveData, includeApprovedData);

            var message = string.Format("DataSet did not match expected for {0}", optionsText);

            AssertDataSetsAreEqual(expected, actual, "DataSet did not match the expected result");

            System.Diagnostics.Debug.WriteLine(string.Format("Success: {0}", optionsText));
        }
        

        private DataSet ExecuteProcedure(SqlConnection connection, string procedureName, 
            DateTime startDate, DateTime endDate, string dateBreakdown, int locationId, bool childLocations,
            string blockModelName, bool includeInactiveChildLocations, bool includeLumpFines, bool highGradeOnly, bool includeResourceClassification,
            bool includeLiveData, bool includeApprovedData)
        {
            var command = connection.CreateCommand();
            command.CommandText = procedureName;
            command.CommandType = CommandType.StoredProcedure;
            command.CommandTimeout = 900000;

            command.Parameters.AddWithValue("@iDateFrom", startDate);
            command.Parameters.AddWithValue("@iDateTo", endDate);

            if (dateBreakdown == null)
            {
                command.Parameters.AddWithValue("@iDateBreakdown", DBNull.Value);
            }
            else
            {
                command.Parameters.AddWithValue("@iDateBreakdown", dateBreakdown);
            }
            
            command.Parameters.AddWithValue("@iLocationId", locationId);
            command.Parameters.AddWithValue("@iChildLocations", childLocations);
            
            if (blockModelName == null)
            {
                command.Parameters.AddWithValue("@iBlockModelName", DBNull.Value);
            }
            else
            {
                command.Parameters.AddWithValue("@iBlockModelName", blockModelName);
            }
            
            command.Parameters.AddWithValue("@iIncludeLiveData", includeLiveData);
            command.Parameters.AddWithValue("@iIncludeApprovedData", includeApprovedData);
            command.Parameters.AddWithValue("@iIncludeInactiveChildLocations", includeInactiveChildLocations);
            command.Parameters.AddWithValue("@iIncludeLumpFines", includeLumpFines);
            command.Parameters.AddWithValue("@iHighGradeOnly", highGradeOnly);
            command.Parameters.AddWithValue("@iIncludeResourceClassification", includeResourceClassification);
            
            var adapter = new SqlDataAdapter(command);
            var dataSet = new DataSet();

            adapter.Fill(dataSet);
            
            return dataSet;
        }

        private void AssertDataSetsAreEqual(DataSet expected, DataSet actual, string message)
        {
            if (expected == null && actual == null)
            {
                return;
            }

            if (expected == null || actual == null)
            {
                Assert.Fail("One of the datasets was null");
            }

            Assert.AreEqual(expected.Tables.Count, actual.Tables.Count,"Unexpected number of dataset tables");

            int tableIndex = 0;
            foreach(DataTable table in expected.Tables)
            {
                DataTable actualTable = actual.Tables[tableIndex];
                
                if (actualTable == null)
                {
                    Assert.Fail("actual table did not exist in dataset");
                }
                else
                {
                    // make sure all rows are the same
                    Assert.AreEqual(table.Rows.Count, actualTable.Rows.Count,string.Format("Table {0} did not have the expected row count", table.TableName));

                    var actualRowEnumerator = actualTable.Rows.GetEnumerator();
                    int rowCount = 0;

                    foreach(DataRow row in table.Rows)
                    {
                        rowCount++;
                        Assert.IsTrue(actualRowEnumerator.MoveNext(), "Unable to move to actual row");

                        var actualColumnEnumerator = actualTable.Columns.GetEnumerator();

                        foreach(DataColumn column in row.Table.Columns)
                        {
                            actualColumnEnumerator.MoveNext();

                            var v1 = row[column];
                            var v2 = (actualRowEnumerator.Current as DataRow)[actualColumnEnumerator.Current as DataColumn];

                            Assert.AreEqual(column.ColumnName, (actualColumnEnumerator.Current as DataColumn).ColumnName, "Unmatched columns");
                            string msg = string.Format("Values not matched in table {0} at row {1} column {2}", actualTable.TableName, rowCount, column.ColumnName);

                            if (column.DataType == typeof(double) && v1 != System.DBNull.Value)
                            {
                                Assert.IsTrue(Math.Abs(Convert.ToDouble(v1) - Convert.ToDouble(v2)) < 10e-6, msg);
                            }
                            else
                            {
                                Assert.IsTrue(v1.ToString() == v2.ToString(), msg);
                            }
                        }
                    }
                }
                tableIndex++;
            }

            // if here all tables, rows and columns are equal
        }

        private string GetConnectionString(string databaseConfigurationName, string databaseUserName)
        {
            var productConfiguration = new Bcd.ProductConfiguration.ConfigurationManager(ConfigurationManager.AppSettings[_productConfigurationPathKeyName]);
            productConfiguration.Open();

            var databaseConfiguration = productConfiguration.GetDatabaseConfiguration(databaseConfigurationName);

            if (databaseConfiguration == null)
            {
                throw new InvalidOperationException("The Reconcilor database configuration was not found within the product configuration file; please run the Management application to configure settings.");
            }

            var connectionString = databaseConfiguration.GenerateSqlClientConnectionString(databaseUserName);

            return connectionString;
        }
    }
}
