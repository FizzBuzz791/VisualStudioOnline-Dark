using Snowden.Consulting.IntegrationService.Model;
using Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Helpers;
using Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.MessageHandlers;
using Snowden.Reconcilor.Bhpbio.DataStaging.MessageHandlers;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Snowden.Reconcilor.Bhpbio.ImportTests.Helpers
{
    public static class StagingDataSetupHelper
    {
        public static void SetupDataStagingMessage (MessageHandlerConfiguration config, string embeddedResourcePath, Assembly assembly)
        {
            BlockoutAndBlastedEventHandler handler;
            Message message;

            ClearIntegrationTestStageBlocks(config, new List<string>()
            {
                "a2443171-b363-4f88-a403-3cee9420dd4d",
                "b2443171-b363-4f88-a403-3cee9420dd4d"
            });

            handler = new BlockoutAndBlastedEventHandler();
            handler.Initialise(config);
            message = new Message
            {
                MessageBody = LoadEmbeddedResourceString(assembly, embeddedResourcePath)
            };
            handler.Process(message);
        }

        public static MessageHandlerConfiguration BuildMessageHandlerConfiguration()
        {
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);

            MessageHandlerConfiguration config = new MessageHandlerConfiguration();
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductionConfigurationPath", Value = @"..\..\..\ProductConfiguration.xml" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "Database", Value = @"Main" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "ProductUser", Value = @"ReconcilorUI" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceSearchValues", Value = "\"http://www.snowden.com/Blastholes/v1.0\"|BlockOutAndBlastedEvent |BlockOutAndBlastedEvent>" });
            config.InitialisationData.Add(new InitialisationDataNameValuePairConfiguration() { Name = "StringReplaceReplaceValues", Value = "\"\"|BlockOutAndBlastedEventType |BlockOutAndBlastedEventType>" });

            return config;
        }

        private static string LoadEmbeddedResourceString(Assembly assembly, string embeddedResourcePath)
        {
            return StagingTestsHelper.LoadEmbeddedResourceString(assembly, embeddedResourcePath);
        }

        internal static string GetDigBlockId(MessageHandlerConfiguration config, string guid)
        {
            string blockId = null;
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	Digblock_Id
                                FROM	[dbo].[DigblockNotes]
                                WHERE	[Digblock_Field_Id] = 'BlockExternalSystemId'
                                and		Notes = @BlockGuid";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@BlockGuid", guid);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        blockId = returnValue.ToString();
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

        internal static string GetStratNum(MessageHandlerConfiguration config, string digblockId)
        {
            string stratNum = null;
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	Notes
                                FROM	[dbo].[DigblockNotes]
                                WHERE	[Digblock_Field_Id] = 'StratNum'
                                and		Digblock_Id = @Digblock_Id";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@Digblock_Id", digblockId);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        stratNum = returnValue.ToString();
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

            return stratNum;
        }

        internal static int? GetWeathering(MessageHandlerConfiguration config, string digblockId)
        {
            int? weathering = null;
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	Notes
                                FROM	[dbo].[DigblockNotes]
                                WHERE	[Digblock_Field_Id] = 'Weathering'
                                and		Digblock_Id = @Digblock_Id";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@Digblock_Id", digblockId);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        int value;
                        if (int.TryParse(returnValue.ToString(), out value))
                        {
                            weathering = value;
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

            return weathering;
        }

        public static void UpdateStagingBlockModelLastModifiedDate(MessageHandlerConfiguration config, int blockId)
        {
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"UPDATE	[Staging].[StageBlockModel]
                                    SET LastModifiedDate = GetDate()
                                WHERE	BlockId = @BlockId
                                AND     BlockModelName = 'Grade Control'";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@BlockId", blockId);

                    var returnValue = command.ExecuteNonQuery();

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

        internal static bool CheckValidationMessageExists(MessageHandlerConfiguration config, string expectedStratNum, string guid, DateTime checkDatesAfter, string userMessage, string internalMessage)
        {
            int count = 0;
            string connectionString = BuildConnectionString(config);
            string xmlPath = $@"BlockModelSource/BlastModelBlockWithPointAndGrade/BlockExternalSystemId[.=""{guid}""]";
            

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = $@"select	count(1)
                                from	ImportSyncRow inner join ImportSyncQueue on ImportSyncRow.ImportSyncRowId = ImportSyncQueue.ImportSyncRowId
		                                inner join ImportSyncValidate on ImportSyncQueue.ImportSyncQueueId = ImportSyncValidate.ImportSyncQueueId
                                where	ImportSyncRow.ImportId = 1
                                and		ImportSyncRow.SourceRow.exist('{xmlPath}') = 1
                                and     (ImportSyncQueue.LastProcessedDateTime >= @CheckDatesAfter or
                                        ImportSyncQueue.InitialComparedDateTime >= @CheckDatesAfter)
                                and     IsCurrent = 1
                                and     ImportSyncValidate.UserMessage = @UserMessage
                                and     ImportSyncValidate.InternalMessage = @InternalMessage";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@UserMessage", userMessage);
                    command.Parameters.AddWithValue("@InternalMessage", internalMessage);
                    command.Parameters.AddWithValue("@CheckDatesAfter", checkDatesAfter);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        count = (int)returnValue;
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

                return (count > 0);
            }
        }

        internal static bool DoesDigBlockExist(MessageHandlerConfiguration config, string digblockId)
        {
            int count = 0;
            string connectionString = BuildConnectionString(config);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                try
                {
                    conn.Open();

                    var sql = @"SELECT	count(1)
                                FROM	[dbo].[Digblock]
                                WHERE	Digblock_Id = @Digblock_Id";

                    var command = conn.CreateCommand();
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandText = sql;

                    command.Parameters.AddWithValue("@Digblock_Id", digblockId);

                    var returnValue = command.ExecuteScalar();

                    if (returnValue != null)
                    {
                        count = (int)returnValue;
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

            return (count == 1);
        }

        private static string BuildConnectionString(MessageHandlerConfiguration configuration)
        {
            return StagingTestsHelper.BuildConnectionString(configuration);
        }

        public static void ClearIntegrationTestStageBlocks(MessageHandlerConfiguration config, List<string> guids)
        {
            StagingTestsHelper.ClearIntegrationTestStageBlocks(config, guids);
        }
    }
}
