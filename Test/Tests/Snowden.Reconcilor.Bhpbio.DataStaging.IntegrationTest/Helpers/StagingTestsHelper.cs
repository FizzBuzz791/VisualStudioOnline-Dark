using Snowden.Bcd.ProductConfiguration;
using Snowden.Consulting.IntegrationService.Model;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.MessageHandlers;
using Snowden.Reconcilor.Bhpbio.Import;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Helpers
{
    public static class StagingTestsHelper
    {
        public static void ClearIntegrationTestStageBlocks(MessageHandlerConfiguration config, List<string> guids)
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

        public static string BuildConnectionString(MessageHandlerConfiguration configuration)
        {
            string productUserName = configuration.InitialisationData["ProductUser"].Value;
            var dbConfig = GetDatabaseConfiguration(configuration);

            return dbConfig.GenerateSqlClientConnectionString(productUserName);
        }

        public static DatabaseConfiguration GetDatabaseConfiguration(MessageHandlerConfiguration configuration)
        { 
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            string productConfigurationPath = configuration.InitialisationData["ProductionConfigurationPath"].Value;

            ConfigurationManager prodConfig = new ConfigurationManager(productConfigurationPath);
            prodConfig.Open();

            string databaseName = configuration.InitialisationData["Database"].Value;

            // obtain and open a database connection string
            DatabaseConfiguration dbConfig = prodConfig.GetDatabaseConfiguration(databaseName);

            return dbConfig;
        }

        /// <summary>
        /// Read an embedded resource string
        /// </summary>
        /// <param name="embeddedResourcePath">path to the embedded resource</param>
        /// <returns>message body</returns>
        public static string LoadEmbeddedResourceString(Assembly assembly, string embeddedResourcePath)
        {
            string result = null;
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

        public static int? GetBlockId(MessageHandlerConfiguration config, string guid)
        {
            int? blockId = null;
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	BlockId
                                  FROM	[Staging].[BhpbioStageBlockModel]
                                WHERE	BlockExternalSystemId = @BlockExternalSystemId";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@BlockExternalSystemId", guid);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        blockId = (int)returnValue;
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

            return blockId;
        }

        public static DataTable GetStagingBhpbioStageBlockModels(MessageHandlerConfiguration config, int blockId)
        {
            DataTable dt = new DataTable();
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	*
                                  FROM	[Staging].[BhpbioStageBlockModel]
                                WHERE	BlockId = @BlockId";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@BlockId", blockId);

                    var dataAdapter = new SqlDataAdapter(command);
                    dataAdapter.Fill(dt);


                    conn.Close();
                    dataAdapter.Dispose();
                }
                finally
                {
                    if (conn.State == System.Data.ConnectionState.Open)
                    {
                        conn.Close();
                    }
                }
            }

            return dt;
        }

        public static bool DoesStratNumExist(MessageHandlerConfiguration config, string expectedStratNum)
        {
            string connectionString = BuildConnectionString(config);

            int stratNumCount = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    String sql = @"SELECT	count(1)
                                   FROM[dbo].[BhpbioStratigraphyHierarchy]
                                   WHERE StratNum = @StratNum";

                    var command = conn.CreateCommand();

                    command.CommandType = CommandType.Text;
                    command.CommandText = sql;
                    command.Parameters.AddWithValue("@StratNum", expectedStratNum);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        stratNumCount = (int)returnValue;
                    }

                    conn.Close();

                }
                finally
                {
                    if (conn.State.Equals(ConnectionState.Open))
                    {
                        conn.Close();
                    }
                }
            }

            return (stratNumCount.Equals(1));
        }
        public static bool DoesWeatheringExist(MessageHandlerConfiguration config, int expectedWeatheringDisplayValue)
        {
            string connectionString = BuildConnectionString(config);

            int weatheringCount = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    String sql = @"SELECT	count(1)
                                   FROM[dbo].[BhpbioWeathering]
                                   WHERE DisplayValue = @DisplayValue";

                    var command = conn.CreateCommand();

                    command.CommandType = CommandType.Text;
                    command.CommandText = sql;
                    command.Parameters.AddWithValue("@DisplayValue", expectedWeatheringDisplayValue);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        weatheringCount = (int)returnValue;
                    }

                    conn.Close();

                }
                finally
                {
                    if (conn.State.Equals(ConnectionState.Open))
                    {
                        conn.Close();
                    }
                }
            }

            return (weatheringCount.Equals(1));
        }
    }
}
