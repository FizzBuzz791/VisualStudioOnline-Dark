using System;
using NUnit.Framework;
using Snowden.Reconcilor.Bhpbio.ImportTests.Helpers;
using Snowden.Consulting.IntegrationService.Model;
using Snowden.Reconcilor.Bhpbio.DataStaging.IntegrationTest.Helpers;
using System.Data;
using Snowden.Bcd.ProductConfiguration;
using Snowden.Common.Import.Data;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using Snowden.Reconcilor.Bhpbio.Import;
using System.Reflection;

namespace Snowden.Reconcilor.Bhpbio.ImportTests
{
    [TestFixture]
    public class StratigraphyImportTests
    {
        MessageHandlerConfiguration _config;

        private const string VALID_STRAT_GUID = "a2443171-b363-4f88-a403-3cee9420dd4d";
        private const string VALID_STRAT_DIGBLOCK = "CW-0641-3151-1";

        private const string INVALID_STRAT_GUID = "b2443171-b363-4f88-a403-3cee9420dd4d";
        private const string INVALID_STRAT_DIGBLOCK = "CW-0641-3151-2";

        private DatabaseConfiguration _dbConfig;

        [SetUp]
        public void TestInitalize()
        {
            _config = StagingDataSetupHelper.BuildMessageHandlerConfiguration();
            _dbConfig = StagingTestsHelper.GetDatabaseConfiguration(_config);
        }
        [Test]
        public void Does_A_Valid_StratNum_Message_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesStratNumExist = DoesStratNumExist(_config, "3430");
            Assert.That(doesStratNumExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_STRAT_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_STRAT_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            var stratNum = GetStratNum(_config, digBlockId);

            Assert.That(stratNum, Is.EqualTo("3430"));
        }

        [Test]
        public void Does_A_Null_StratNum_Message_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum-Null-Value.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesStratNumExist = DoesStratNumExist(_config, "3430");
            Assert.That(doesStratNumExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_STRAT_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_STRAT_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            var stratNum = GetStratNum(_config, digBlockId);

            Assert.That(stratNum, Is.Null);
        }

        [Test]
        public void Does_A_Valid_StratNum_Message_Update_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesStratNumExist = DoesStratNumExist(_config, "3430");
            Assert.That(doesStratNumExist, Is.True);

            doesStratNumExist = DoesStratNumExist(_config, "3420");
            Assert.That(doesStratNumExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_STRAT_GUID, _config, arguments);

            // Add existing
            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_STRAT_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            // Now update to from 3430 to 3420
            resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum-Update-Value.xml";

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var stratNum = GetStratNum(_config, digBlockId);

            Assert.That(stratNum, Is.EqualTo("3420"));
        }

        [Test]
        public void Does_A_Null_StratNum_Message_Update_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesStratNumExist = DoesStratNumExist(_config, "3430");
            Assert.That(doesStratNumExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_STRAT_GUID, _config, arguments);

            // Add existing
            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_STRAT_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            // Now update to from 3430 to NULL
            resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-StratNum-Null-Value.xml";

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var stratNum = GetStratNum(_config, digBlockId);

            Assert.That(stratNum, Is.Null);
        }

        [Test]
        public void Does_An_Invalid_StratNum_Message_Raise_A_Validation_Error()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Invalid-StratNum.xml";
            var checkDatesAfter = DateTime.Now;
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            string expectedStratNum = "1111";
            var exists = DoesStratNumExist(_config, expectedStratNum);
            Assert.That(exists, Is.False);

            RemoveExistingRecord(INVALID_STRAT_DIGBLOCK, INVALID_STRAT_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, INVALID_STRAT_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, INVALID_STRAT_GUID);
            Assert.That(digBlockId, Is.Null);

            bool validationMessagesExist = CheckValidationMessageExists(_config, expectedStratNum, INVALID_STRAT_GUID, checkDatesAfter);

            Assert.That(validationMessagesExist, Is.True);

        }

        private void PopulateStagingData(MessageHandlerConfiguration config, string resource, Assembly assembly, string guid)
        {
            StagingDataSetupHelper.SetupDataStagingMessage(config, resource, assembly);

            var stagingBlockId = GetStagingBlockId(config, guid);
            Assert.That(stagingBlockId, Is.Not.Null);
            Assert.That(stagingBlockId.HasValue, Is.True);

            StagingDataSetupHelper.UpdateStagingBlockModelLastModifiedDate(_config, stagingBlockId.Value);
        }

        private void AssertStratNumExists(string blockGuid, string expectedStratNum)
        {
            var blockId = GetStagingBlockId(_config, blockGuid);

            Assert.That (blockId, Is.Not.Null);
            Assert.That(blockId.HasValue, Is.True);

            var dataTable = GetStagingBhpbioStageBlockModels(_config, blockId.Value);

            Assert.That(dataTable.Rows.Count, Is.EqualTo(1));

            Assert.That(dataTable.Rows[0]["StratNum"], Is.EqualTo(expectedStratNum));
        }


        private int? GetStagingBlockId(MessageHandlerConfiguration config, string guid)
        {
            return StagingTestsHelper.GetBlockId(config, guid);
        }

        private DataTable GetStagingBhpbioStageBlockModels(MessageHandlerConfiguration config, int blockId)
        {
            return StagingTestsHelper.GetStagingBhpbioStageBlockModels(config, blockId);
        }

        private bool DoesStratNumExist(MessageHandlerConfiguration config, string expectedStratNum)
        {
            return StagingTestsHelper.DoesStratNumExist(config, expectedStratNum);
        }

        private String GetDigBlockId(MessageHandlerConfiguration config, string guid)
        {
            return StagingDataSetupHelper.GetDigBlockId(config, guid);
        }

        private void RunImportEngineBlockModel(ReadOnlyCollection<string> commandLineArguments)
        {
            Int32 returnCode = ModMain.SetupAndRunImportFromTestHarness(commandLineArguments, ImportTypeEnum.BlockModel);
        }

        private string GetStratNum(MessageHandlerConfiguration config, string digBlockId)
        {
            return StagingDataSetupHelper.GetStratNum(config, digBlockId);
        }

        private bool CheckValidationMessageExists(MessageHandlerConfiguration config, string expectedStratNum, string digblock, DateTime checkDatesAfter)
        {
            return StagingDataSetupHelper.CheckValidationMessageExists(config, expectedStratNum, digblock, checkDatesAfter);
        }

        private static void ClearIntegrationTestStageBlocks(MessageHandlerConfiguration config, List<string> guids)
        {
            StagingTestsHelper.ClearIntegrationTestStageBlocks(config, guids);
        }

        private bool DoesDigBlockExist(MessageHandlerConfiguration config, string digblockId)
        {
            return StagingDataSetupHelper.DoesDigBlockExist(config, digblockId);
        }

        private void RemoveExistingRecord(string digblockId, string guid, MessageHandlerConfiguration config, List<string> arguments)
        {
            bool exists = DoesDigBlockExist(config, digblockId);
            if (exists)
            {
                //Delete the block and process it
                ClearIntegrationTestStageBlocks(_config, new List<string>() { guid });
                //  Process the delete
                RunImportEngineBlockModel(arguments.AsReadOnly());
            }
        }
    }
}
