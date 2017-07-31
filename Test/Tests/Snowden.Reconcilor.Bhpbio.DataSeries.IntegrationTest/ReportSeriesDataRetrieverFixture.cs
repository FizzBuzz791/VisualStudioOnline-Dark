using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using pc = Snowden.Bcd.ProductConfiguration;
using Snowden.Consulting.DataSeries.DataAccess.DataTypes;
using System.Collections.Generic;
using System.Linq;
using Snowden.Consulting.DataSeries.Processing;
using System.Reflection;
using System.IO;
using System.Data.SqlClient;

namespace Snowden.Reconcilor.Bhpbio.DataSeries.IntegrationTest
{
    /// <summary>
    /// Fixture to test the BHPB specific data retriever for outlier analysis..
    /// </summary>
    /// <remarks>This fixture is also used to exercise DAL method for series lookup, point storage and other methods required by teh outlier process</remarks>
    [TestClass]
    public class ReportSeriesDataRetrieverFixture
    {
        /// <summary>
        /// Test that the data retriever retrieves the expected points AND also exercises the associated DAL methods for point and series storage
        /// </summary>
        [TestMethod]
        [Ignore]
        public void GetPoints_FullDiscovery_SeriesTypeSAndPointsReturned()
        {
            // ONLY USE THIS TEST FOR SERIES TYPE GENERATION
            
            // the ordinal represents the month
            long ordinal = 1;
                        
            // create a retriever to obtain BHPB specific data poitns
            ReportSeriesDataRetriever retriever = new ReportSeriesDataRetriever();

            // THE Retriever will obtain its own connection string using the product configuration
            //    obsolete:  string connectionString = GetConnectionString("Main", "ReconcilorUI");  retriever.SetConnectionString(connectionString);

            // create a DAL for the DataSeries access
            Snowden.Consulting.DataSeries.DataAccess.SqlServerDataSeriesDataAccessProvider provider = GetProvider();

            // find the group that includes ALL Outlier raw data
            var groups = provider.GetSeriesTypeGroups();
            var group = groups.FirstOrDefault(g => g.Id == Snowden.Consulting.DataSeries.DataAccess.OutlierDetectionDataAccessProvider.OutlierSeriesTypeGroup);
            Assert.IsNotNull(group);

            /// Get all the types of series within this group
            Dictionary<string, SeriesType> seriesTypeById = new Dictionary<string, SeriesType>();
            var seriesTypes = provider.GetSeriesTypesByGroup(Snowden.Consulting.DataSeries.DataAccess.OutlierDetectionDataAccessProvider.OutlierSeriesTypeGroup, null);
            foreach (SeriesType st in seriesTypes)
            {
                seriesTypeById.Add(st.Id, st);
            }

            // clear any points related to these series for the test time period (ordinal.. ie month)
            provider.ClearPoints(null, group.Id, null, ordinal, ordinal, false);


            // tell the retriever to discover new series types
             retriever.DiscoverSeriesTypes = true;
            // use the retriever to obtain points
            var points = retriever.GetPoints(seriesTypeById, ordinal);

            // if new series types were discovered
            if (retriever.LastDiscoveredSeriesTypes != null && retriever.LastDiscoveredSeriesTypes.Count > 0)
            {
                // store them
                provider.AddOrUpdateSeriesTypes(retriever.LastDiscoveredSeriesTypes.Values.ToList());
            }
            
            // now build up a structure of series by series key
            Dictionary<string, Series> seriesByKey = new Dictionary<string, Series>();
            // this is done by looking up the specifiec series that belong to each group
            foreach(var entry in seriesTypeById)
            {
                var seriesList = provider.GetSeriesForSeriesType(entry.Value.Id);
                if (seriesList != null)
                {
                    foreach(var series in seriesList)
                    {
                        seriesByKey[series.SeriesKey] = series;
                    }
                }
            }

            // data structures used to record which series Ids we have prepared points for
            HashSet<int> seriesIdWithPointsAdded = new HashSet<int>();
            // data structure storing generated points to be written
            List<SeriesPoint> pointsToAdd = new List<SeriesPoint>();
            // iterate through each retrieved point
            foreach (var entry in points)
            {
                // get the series key
                string keyOfPoint = entry.Key.SeriesKey;

                // and see if this is an existing series OR a series that must be created
                Series matchingSeries = null;
                if (!seriesByKey.TryGetValue(keyOfPoint, out matchingSeries))
                {
                    // this is a new series... save it to the database
                    matchingSeries = entry.Key;
                    provider.AddOrUpdateSeries(new List<Series>() { matchingSeries });
                    // and add the series to the data structure of known series
                    seriesByKey.Add(matchingSeries.SeriesKey, matchingSeries);
                }

                // if this series has not had a point added
                if (!seriesIdWithPointsAdded.Contains(matchingSeries.Id.Value))
                {
                    // add it to the data structure containing points pending save
                    pointsToAdd.Add(new SeriesPoint() { Ordinal = ordinal, SeriesId = matchingSeries.Id.Value, SeriesKey = matchingSeries.SeriesKey, Value = entry.Value });
                    seriesIdWithPointsAdded.Add(matchingSeries.Id.Value);
                }
            }
            
            // save the points
            provider.AddPoints(pointsToAdd);

            // This test has generated new points and stored them,   creating any new series or series types as needed
        }

        /// <summary>
        /// Test that the data retriever retrieves the expected points AND also exercises the associated DAL methods for point and series storage
        /// </summary>
        [TestMethod]
        [Ignore]
        public void GetPoints_OnlyUseExistingSeriesTypesProvided_ExpectedPointsReturned()
        {
            // ---------------------------------------------
            // This test is destructive so run with care...
            //
            //  Ignored by default
            //
            //  A more general test is to run the outlier detection process using the Reconcilor Engine
            // ---------------------------------------------

            // the ordinal represents the month
            long ordinal = 1;

            // create a retriever to obtain BHPB specific data poitns
            ReportSeriesDataRetriever retriever = new ReportSeriesDataRetriever();
                        
            // create a DAL for the DataSeries access
            Snowden.Consulting.DataSeries.DataAccess.SqlServerDataSeriesDataAccessProvider provider = GetProvider();

            // find the group that includes ALL Outlier raw data
            var groups = provider.GetSeriesTypeGroups();
            var group = groups.FirstOrDefault(g => g.Id == Snowden.Consulting.DataSeries.DataAccess.OutlierDetectionDataAccessProvider.OutlierSeriesTypeGroup);
            Assert.IsNotNull(group);

            /// Get all the types of series within this group
            Dictionary<string, SeriesType> seriesTypeById = new Dictionary<string, SeriesType>();
            var seriesTypes = provider.GetSeriesTypesByGroup(Snowden.Consulting.DataSeries.DataAccess.OutlierDetectionDataAccessProvider.OutlierSeriesTypeGroup, null);
            foreach (SeriesType st in seriesTypes)
            {
                seriesTypeById.Add(st.Id, st);
            }

            // clear any points related to these series for the test time period (ordinal.. ie month)
            provider.ClearPoints(null, group.Id, null, ordinal, ordinal, false);

            
            // use the retriever to obtain points
            var points = retriever.GetPoints(seriesTypeById, ordinal);

            // new series types should NOT have been discovered
            Assert.IsTrue(retriever.LastDiscoveredSeriesTypes == null || retriever.LastDiscoveredSeriesTypes.Count == 0, "Series Types should NOT have been discovered by default");

            Assert.IsTrue(points.Count > 0, "Points should have been generated");

            foreach (var entry in points)
            {
                SeriesType existingType = null;

                // every point should have been for a known series type
                if (!seriesTypeById.TryGetValue(entry.Key.SeriesTypeId, out existingType))
                {
                    Assert.Fail(string.Format("Point provided for unexpected series type: {0}", entry.Key.SeriesTypeId));
                }
            }

        }

        /// <summary>
        /// Test that the data retriever retrieves the expected points AND also exercises the associated DAL methods for point and series storage
        /// </summary>
        [TestMethod]
        public void GetPoints_DataRetrievalTest()
        {
            var provider = GetProvider();

            string connectionString = GetConnectionString("Main", "ReconcilorUI");
            
            // Add queue entries to trigger data retrieval... once data is retrieved outlier processing is automatically triggered
            RunEmbeddedScript("AddDataRetrievalQueueEntries.sql", connectionString);

            // this test requires data pop for Data Series being setup
            Controller controller = new Controller();
            ControlContext context = new ControlContext()
            {
                MaxOrdinal = 79, // this stops the controller from processing queue entries indefinately into the future
                ConnectionString = connectionString
            };
            controller.Initialise(context);
            
            bool moreWork = true;
            // set some maximum limit on processing just in case things go wrong.. the test should complete when all queue entries in range have been processed; however maxLoop is used for a secondary exit in case there is a bug that allows processing to continue forever
            long maxLoop = 200;
            
            int iteration = 0;
            var nextRequest = provider.GetNextPendingQueueEntry(null);
            Assert.IsNotNull(nextRequest);

            // iterate enough times to complete the work
            while (moreWork && iteration < maxLoop)
            {
                iteration++;

                nextRequest = provider.GetNextPendingQueueEntry(null);

                if (nextRequest == null || nextRequest.Ordinal > context.MaxOrdinal)
                {
                    moreWork = false;
                    break;
                }
                controller.ProcessOne();
            }

            Assert.IsFalse(moreWork);
            // At this point all outlier results have been generated and can be verified..

            // this test is used for data generation and to ensure the process completes, however the tests within the Snowden.ConsultingToolkit solution are the ones that verify correctness
        }

        private Consulting.DataSeries.DataAccess.SqlServerDataSeriesDataAccessProvider GetProvider()
        {
            string connectionString = GetConnectionString("Main", "ReconcilorUI");

            return new Consulting.DataSeries.DataAccess.SqlServerDataSeriesDataAccessProvider(connectionString);
        }
        
        /// <summary>
        /// Obtain a connection string from the product config
        /// </summary>
        /// <param name="databaseConfigurationName">database config to lookup</param>
        /// <param name="databaseUserName">database username to lookup</param>
        /// <returns>the generated connection string</returns>
        private string GetConnectionString(string databaseConfigurationName, string databaseUserName)
        {
            var productConfiguration = new pc.ConfigurationManager("../../../ProductConfiguration.xml");

            productConfiguration.Open();

            var databaseConfiguration = productConfiguration.GetDatabaseConfiguration(databaseConfigurationName);

            if (databaseConfiguration == null)
            {
                throw new InvalidOperationException("The Reconcilor database configuration was not found within the product configuration file; please run the Management application to configure settings.");
            }

            return databaseConfiguration.GenerateSqlClientConnectionString(databaseUserName);
        }

        public static void RunEmbeddedScript(string scriptName, string connectionString)
        {
            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(string.Format("Snowden.Reconcilor.Bhpbio.DataSeries.IntegrationTest.Resources.{0}", scriptName)))
            {
                var reader = new StreamReader(stream);
                var script = reader.ReadToEnd();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    var command = connection.CreateCommand();
                    command.CommandText = script;
                    command.CommandType = System.Data.CommandType.Text;

                    command.ExecuteNonQuery();
                }
            }
        }
        
    }
}
