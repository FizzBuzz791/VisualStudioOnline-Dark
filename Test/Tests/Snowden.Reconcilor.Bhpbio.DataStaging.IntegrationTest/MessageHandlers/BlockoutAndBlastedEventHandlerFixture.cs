using System;
using System.Text;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Snowden.Reconcilor.Bhpbio.DataStaging.MessageHandlers;
using Snowden.Consulting.IntegrationService.Model;
using System.Reflection;
using System.IO;
using Snowden.Bcd.ProductConfiguration;
using System.Data.SqlClient;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;

namespace Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.MessageHandlers
{
    /// <summary>
    /// Summary description for BlockoutAndBlastedEventHandlerFixture
    /// </summary>
    [TestClass]
    public class BlockoutAndBlastedEventHandlerFixture
    {
        public BlockoutAndBlastedEventHandlerFixture()
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
        /// Test a normal series of messages for a Pattern / Flitch
        /// </summary>
        [TestMethod]
        public void Process_IntegrationTest()
        {
            MessageHandlerConfiguration config = BuildMessageHandlerConfiguration();

            BlockoutAndBlastedEventHandler handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);

            // process the initial create
            Message message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_IntegrationTesting.xml");
            handler.Process(message);
        }

        /// <summary>
        /// Test a normal series of messages for a Pattern / Flitch
        /// </summary>
        [TestMethod]
        public void Process_NormalCycle_BlockDataPeristedAsExpected()
        {
            MessageHandlerConfiguration config = BuildMessageHandlerConfiguration();

            ClearIntegrationTestStageBlocks(config, new List<string>()
            {
                "a2443171-b363-4f88-a403-3cee9420dd4d",
                "8f4d3ae2-0f58-4efc-91e0-aa54d91c7094",
                "5aa36434-bb74-4d69-8a3f-bfea410d6273",
                "9a4d3ae2-0f58-4efc-91e0-aa54d91c7094"
            });

            BlockoutAndBlastedEventHandler handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);

            // process the initial create
            Message message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario1_M1_BlocksCreated.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>() { 
                {"a2443171-b363-4f88-a403-3cee9420dd4d", 52077.009m},
                {"8f4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12144.415m},
                {"5aa36434-bb74-4d69-8a3f-bfea410d6273", 2021.543m},
            } );

            // process the create update delete
            message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario1_M2_BlocksCreatedUpdatedDeleted.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>() { 
                {"8f4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12144.415m}, // unchanged block
                {"5aa36434-bb74-4d69-8a3f-bfea410d6273", 3022.543m}, // updated block
                {"9a4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12150.415m}, // new block
            },
            new List<string>() { 
                "a2443171-b363-4f88-a403-3cee9420dd4d" // deleted block.. this block should NOT exist
            }
            );

            
            // process an out of sequence update
            message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario1_M3_OutOfSequenceUpdate.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>() { 
                {"8f4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12144.415m}, // no change as message is ignored due to out of sequence
                {"5aa36434-bb74-4d69-8a3f-bfea410d6273", 3022.543m}, // no change as message is ignored due to out of sequence
                {"9a4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12150.415m}, // no change as message is ignored due to out of sequence
            });

            // process a no change message
            message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario1_M4_BlocksNoChange.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>() { 
                {"8f4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12144.415m}, // no change as block is UNCHANGED
                {"5aa36434-bb74-4d69-8a3f-bfea410d6273", 3022.543m}, // no change as block is UNCHANGED
                {"9a4d3ae2-0f58-4efc-91e0-aa54d91c7094", 12150.415m}, // no change as block is UNCHANGED
            });

        }

        /// <summary>
        /// Test receipt of a delete before a create
        /// </summary>
        [TestMethod]
        public void Process_OutOfSequenceDeleteAndCreate_BlockIsNeverCreated()
        {
            MessageHandlerConfiguration config = BuildMessageHandlerConfiguration();
            ClearIntegrationTestStageBlocks(config, new List<string>()
            {
                "af1743ff-4c38-f846-abc2-051de605dd90"
            });
            
            BlockoutAndBlastedEventHandler handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);

            // process the initial create
            Message message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario2_M1_OutofSequenceDelete.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>() { 
                // no blocks should exist as this message was a delete
            },
            new List<string>() { 
                "b3543171-b363-4f88-a403-3cee9420dd4d" // this block should NOT exist
            });

            // process the create
            message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario2_M2_BlocksCreated.xml");
            handler.Process(message);

            AssertStageBlocksExistWithGUIDsAndGCTonnes(config, new Dictionary<string, decimal>()
            {
                // still no blocks should exist due to the earlier received delete message
            },
            new List<string>() { 
                "b3543171-b363-4f88-a403-3cee9420dd4d" // this block should STILL NOT exist even though an ADD was received
            });
        }

        /// <summary>
        /// This method is for ad-hoc testing... update BlockoutAndBlastedEvent_AdhocMessageTest.xml first
        /// </summary>
        [TestMethod]
        public void Process_Scenario3_AsShippedAsDroppedMessageProcessedAsExpected()
        {
            string blockGuid = "5E09371F-9E24-684E-E053-211BF40AE5B1";

            MessageHandlerConfiguration config = BuildMessageHandlerConfiguration();

            ClearIntegrationTestStageBlocks(config, new List<string>()
            {
                blockGuid
            });

            BlockoutAndBlastedEventHandler handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);

            // process the initial create
            Message message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_Scenario3_M2_BlocksCreatedAShippedAsDropped.xml");
            handler.Process(message);

            // check that the as-dropped and as-shipped lump percent have been specified correctly
            AssertLumpPercentagesAsExpected(config, blockGuid, "Grade Control", "W", expectedLumpPercentAsDropped: 43.475, expectedLumpPercentAsShipped: 51.0);
            
            // check Fe grades
            AssertGradeValuesAsExpected(config, blockGuid, "Grade Control", "W", "FE", "As-Dropped",expectedGradeValue: 52.78, expectedLumpValue: 56.334, expectedFinesValue: 50.046);
            AssertGradeValuesAsExpected(config, blockGuid, "Grade Control", "W", "FE", "As-Shipped", expectedGradeValue: 52.78, expectedLumpValue: 57.176, expectedFinesValue: 50.154);

            // check Ultrafines values
            AssertGradeValuesAsExpected(config, blockGuid, "Grade Control", "W", "ULTRAFINES", "As-Dropped", expectedGradeValue: 8.05, expectedLumpValue: 0, expectedFinesValue: 18.51);
            AssertGradeValuesAsExpected(config, blockGuid, "Grade Control", "W", "ULTRAFINES", "As-Shipped", expectedGradeValue: 8.8, expectedLumpValue: 0, expectedFinesValue: 17.25);
        }
        
        /// <summary>
        /// This method is for ad-hoc testing... update BlockoutAndBlastedEvent_AdhocMessageTest.xml first
        /// </summary>
        [TestMethod]
        public void Process_AdhocMessage_MessageIsProcessedAsExpected()
        {
            MessageHandlerConfiguration config = BuildMessageHandlerConfiguration();

            BlockoutAndBlastedEventHandler handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);

            // process the initial create
            Message message = new Message();
            message.MessageBody = LoadEmbeddedResourceString("Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Resources.BlockoutAndBlastedEvent_AdhocMessageTest.xml");
            handler.Process(message);

            // this is an ad-hoc test method... results should be manually inspected
        }
        
        private string BuildConnectionString(MessageHandlerConfiguration configuration)
        {
            string productConfigurationPath = configuration.InitialisationData["ProductionConfigurationPath"].Value;
            string productUserName = configuration.InitialisationData["ProductUser"].Value;

            ConfigurationManager prodConfig = new ConfigurationManager(productConfigurationPath);
            prodConfig.Open();

            string databaseName = configuration.InitialisationData["Database"].Value;
            
            // obtain and open a database connection string
            DatabaseConfiguration dbConfig = prodConfig.GetDatabaseConfiguration(databaseName);

            return dbConfig.GenerateSqlClientConnectionString(productUserName);
        }

        private void AssertLumpPercentagesAsExpected(MessageHandlerConfiguration config, string blockGuid, string model, string oreType, double? expectedLumpPercentAsDropped, double? expectedLumpPercentAsShipped)
        {
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    IBhpbioBlock dal = new SqlDalBhpbioBlock(conn);


                    // remove any trace of the deletion to allow tests to be rerun
                    var gradeValuesCommand = conn.CreateCommand();
                    gradeValuesCommand.CommandType = System.Data.CommandType.Text;
                    gradeValuesCommand.CommandText = @"
SELECT sbm.LumpPercentAsDropped, sbm.LumpPercentAsShipped
FROM Staging.StageBlock sb 
INNER JOIN Staging.StageBlockModel sbm ON sbm.BlockId = sb.BlockId
WHERE sb.BlockExternalSystemId = @externalSystemId
AND sbm.BlockModelName= @modelName
AND sbm.MaterialTypeName = @materialTypeName
";

                    gradeValuesCommand.Parameters.AddWithValue("@externalSystemId", blockGuid);
                    gradeValuesCommand.Parameters.AddWithValue("@modelName", model);
                    gradeValuesCommand.Parameters.AddWithValue("@materialTypeName", oreType);

                    bool recordFound = false;
                    double? lumpPercentAsDroppedValue = null;
                    double? lumpPercentAsShippedValue = null;

                    using (var reader = gradeValuesCommand.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            recordFound = true;
                            if (!reader.IsDBNull(0))
                            {
                                string dt = reader.GetDataTypeName(0);
                                lumpPercentAsDroppedValue = (double)reader.GetDecimal(0);
                            }

                            if (!reader.IsDBNull(1))
                            {
                                lumpPercentAsShippedValue = (double)reader.GetDecimal(1);
                            }
                        }
                    }


                    string recordDescription = string.Format("Model: {0}, MaterialType: {1}, BlockExternalSystemId: {2}", model, oreType, blockGuid);

                    Assert.IsTrue(recordFound, string.Format("A matching record was not found. {0}", recordDescription));

                    AssertValuesEqualWithinTolerance(expectedLumpPercentAsDropped, lumpPercentAsDroppedValue, string.Format("{0} - {1}", "Lump Percent As Dropped", recordDescription));
                    AssertValuesEqualWithinTolerance(expectedLumpPercentAsShipped, lumpPercentAsShippedValue, string.Format("{0} - {1}", "Lump Percent As Shipped", recordDescription));
                }
                catch (Exception ex)
                {
                    throw ex;
                }
            }
        }

        private void AssertGradeValuesAsExpected(MessageHandlerConfiguration config, string blockGuid, string model, string oreType, string gradeName, string geometType, double? expectedGradeValue, double? expectedLumpValue, double? expectedFinesValue)
        {
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    IBhpbioBlock dal = new SqlDalBhpbioBlock(conn);


                    // remove any trace of the deletion to allow tests to be rerun
                    var gradeValuesCommand = conn.CreateCommand();
                    gradeValuesCommand.CommandType = System.Data.CommandType.Text;
                    gradeValuesCommand.CommandText = @"
SELECT sbmg.GradeValue, sbmg.LumpValue, sbmg.FinesValue, sbm.LumpPercentAsDropped, sbm.LumpPercentAsShipped
FROM Staging.StageBlock sb 
INNER JOIN Staging.StageBlockModel sbm ON sbm.BlockId = sb.BlockId
INNER JOIN Staging.StageBlockModelGrade sbmg ON sbmg.BlockModelId = sbm.BlockModelId
WHERE sb.BlockExternalSystemId = @externalSystemId
AND sbm.BlockModelName= @modelName
AND sbm.MaterialTypeName = @materialTypeName
AND sbmg.GradeName = @gradeName
AND sbmg.GeometType = @geometType";

                    gradeValuesCommand.Parameters.AddWithValue("@externalSystemId", blockGuid);
                    gradeValuesCommand.Parameters.AddWithValue("@modelName", model);
                    gradeValuesCommand.Parameters.AddWithValue("@materialTypeName", oreType);
                    gradeValuesCommand.Parameters.AddWithValue("@gradeName", gradeName);
                    gradeValuesCommand.Parameters.AddWithValue("@geometType", geometType);

                    bool recordFound = false;
                    double? gradeValue = null;
                    double? lumpValue = null;
                    double? finesValue = null;

                    using (var reader = gradeValuesCommand.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            recordFound = true;
                        }

                        if (!reader.IsDBNull(0))
                        {
                            gradeValue = reader.GetDouble(0);
                        }

                        if (!reader.IsDBNull(1))
                        {
                            lumpValue = reader.GetDouble(1);
                        }

                        if (!reader.IsDBNull(2))
                        {
                            finesValue = reader.GetDouble(2);
                        }

                    }


                    string recordDescription = string.Format("Model: {0}, MaterialType: {1}, GradeName: {2}, GeometType: {3}, BlockExternalSystemId: {4}", model, oreType, gradeName, geometType, blockGuid);

                    Assert.IsTrue(recordFound, string.Format("A matching record was not found. {0}", recordDescription));

                    AssertValuesEqualWithinTolerance(expectedGradeValue, gradeValue, string.Format("{0} - {1}", "GradeValue", recordDescription));
                    AssertValuesEqualWithinTolerance(expectedLumpValue, lumpValue, string.Format("{0} - {1}", "LumpValue", recordDescription));
                    AssertValuesEqualWithinTolerance(expectedFinesValue, finesValue, string.Format("{0} - {1}", "FinesValue", recordDescription));
                }
                catch (Exception ex)
                {
                    throw ex;
                }
            }
        }

        private void AssertValuesEqualWithinTolerance(double? expectedValue, double? actualValue, string description)
        {

            if (expectedValue == null)
            {
                Assert.IsNull(actualValue, string.Format("A null value was expected. {0}", description));
            }
            else
            {
                double tolerance = 0.01;
                Assert.IsNotNull(actualValue, string.Format("A non-null value was expected. {0}", description));
                var diff = Math.Abs(expectedValue.Value - actualValue.Value);
                Assert.IsTrue(diff <= tolerance, string.Format("Actual value differs from expected by more than tolerance. expected: {0}, actual: {1} - {2}", expectedValue, actualValue, description));
            }

        }

        /// <summary>
        /// Clear all integration testing stage blocks
        /// </summary>
        /// <param name="config">config used to connect to the database</param>
        private void ClearIntegrationTestStageBlocks(MessageHandlerConfiguration config, List<string> guids)
        {
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    IBhpbioBlock dal = new SqlDalBhpbioBlock(conn);

                    foreach (string guid in guids)
                    {
                        // delete from StageBlock
                        dal.DeleteBhpbioStageBlock(DateTime.Now, guid);

                        // remove any trace of the deletion to allow tests to be rerun
                        var deleteFromStageBlockDeletion = conn.CreateCommand();
                        deleteFromStageBlockDeletion.CommandType = System.Data.CommandType.Text;
                        deleteFromStageBlockDeletion.CommandText = "DELETE FROM Staging.StageBlockDeletion WHERE BlockExternalSystemId = @BlockExternalSystemId";
                        deleteFromStageBlockDeletion.Parameters.AddWithValue("@BlockExternalSystemId", guid);

                        deleteFromStageBlockDeletion.ExecuteNonQuery();
                    }

                    conn.Close();
                }
                finally
                {
                    if (conn.State == System.Data.ConnectionState.Open)
                    {
                        conn.Close();
                    }
                }
            }
        }

        /// <summary>
        /// Assert that the only integration testing Blocks in StageBlock are those with the GUIDs specified
        /// </summary>
        /// <param name="config">config value to be used</param>
        /// <param name="assertNoOthers">if true, this method will assert that there are no other integration test blocks in StageBlock</param>
        /// <param name="guidTonnes">A dictionary of Block GUIDs with corresponding expected tonnes values</param>
        /// <param name="guidsToEnsureDoNotExist">a list of guids to ensure no longer exist in StageBlock</param>
        private void AssertStageBlocksExistWithGUIDsAndGCTonnes(MessageHandlerConfiguration config, Dictionary<string, decimal> guidTonnes, List<string> guidsToEnsureDoNotExist = null)
        {
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    IBhpbioBlock dal = new SqlDalBhpbioBlock(conn);

                    foreach (var entry in guidTonnes)
                    {
                        // remove any trace of the deletion to allow tests to be rerun
                        var countMatchingBlocks = conn.CreateCommand();
                        countMatchingBlocks.CommandType = System.Data.CommandType.Text;
                        countMatchingBlocks.CommandText = @"
SELECT COUNT(*) 
FROM Staging.StageBlock sb 
INNER JOIN Staging.StageBlockModel sbm 
    ON sbm.BlockId = sb.BlockId
WHERE sb.BlockExternalSystemId = @BlockExternalSystemId and sbm.OpeningTonnes = @ExpectedTonnes AND sbm.BlockModelName like @BlockModelName";

                        countMatchingBlocks.Parameters.AddWithValue("@BlockExternalSystemId", entry.Key);
                        countMatchingBlocks.Parameters.AddWithValue("@ExpectedTonnes", entry.Value);
                        countMatchingBlocks.Parameters.AddWithValue("@BlockModelName", "GRADE CONTROL");

                        object result = countMatchingBlocks.ExecuteScalar();

                        Assert.IsNotNull(result);
                        Assert.AreEqual(1, result, string.Format("An entry was not found for Block {0} with Tonnes {1}", entry.Key, entry.Value));

                    }

                    if (guidsToEnsureDoNotExist != null)
                    {
                        foreach (string guid in guidsToEnsureDoNotExist)
                        {
                            // make sure guids expected to have been removed really do not exist
                            var countMatchingBlocks = conn.CreateCommand();
                            countMatchingBlocks.CommandType = System.Data.CommandType.Text;
                            countMatchingBlocks.CommandText = @"
SELECT COUNT(*) 
FROM Staging.StageBlock sb 
WHERE sb.BlockExternalSystemId = @BlockExternalSystemId";

                            countMatchingBlocks.Parameters.AddWithValue("@BlockExternalSystemId", guid);

                            object result = countMatchingBlocks.ExecuteScalar();
                            Assert.IsNotNull(result);
                            Assert.AreEqual(0, result, string.Format("An entry was found for a Block {0} that was expected to have been removed", guid));
                        }
                    }

                    conn.Close();
                }
                finally
                {
                    if (conn.State == System.Data.ConnectionState.Open)
                    {
                        conn.Close();
                    }
                }
            }
        }

        private MessageHandlerConfiguration BuildMessageHandlerConfiguration()
        {
            MessageHandlerConfiguration config = new MessageHandlerConfiguration();
            //config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductionConfigurationPath", Value = @"..\..\..\..\ProductConfiguration.xml" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductionConfigurationPath", Value = @"..\..\..\ProductConfiguration.xml" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "Database", Value = @"Main" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductUser", Value = @"ReconcilorUI" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceSearchValues", Value = "\"http://www.snowden.com/Blastholes/v1.0\"|BlockOutAndBlastedEvent |BlockOutAndBlastedEvent>" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceReplaceValues", Value = "\"\"|BlockOutAndBlastedEventType |BlockOutAndBlastedEventType>" });

            return config;
        }

        /// <summary>
        /// Read an embedded resource string
        /// </summary>
        /// <param name="embeddedResourcePath">path to the embedded resource</param>
        /// <returns>message body</returns>
        private string LoadEmbeddedResourceString(string embeddedResourcePath)
        {
            string result = null;
            var assembly = typeof(BlockoutAndBlastedEventHandlerFixture).Assembly;
            var resourceName = embeddedResourcePath;

            using (Stream stream = assembly.GetManifestResourceStream(resourceName))
            {
                using (StreamReader reader = new StreamReader(stream))
                {
                    result = reader.ReadToEnd();
                }
            }
            return result; 
        }
    }
}
