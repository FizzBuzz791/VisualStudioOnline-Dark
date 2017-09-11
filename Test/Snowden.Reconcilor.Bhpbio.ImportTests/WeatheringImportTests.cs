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
    public class WeatheringImportTests
    {
        MessageHandlerConfiguration _config;

        private const string VALID_GUID = "a2443171-b363-4f88-a403-3cee9420dd4d";
        private const string VALID_STRAT_DIGBLOCK = "CW-0641-3151-1";

        private const string INVALID_GUID = "b2443171-b363-4f88-a403-3cee9420dd4d";
        private const string INVALID_STRAT_DIGBLOCK = "CW-0641-3151-2";

        private DatabaseConfiguration _dbConfig;

        [SetUp]
        public void TestInitalize()
        {
            _config = StagingDataSetupHelper.BuildMessageHandlerConfiguration();
            _dbConfig = StagingTestsHelper.GetDatabaseConfiguration(_config);
        }

        [Test]
        public void Does_A_Valid_Weathering_Message_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Weathering.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesWeatheringExist = DoesWeatheringExist(_config, 1);
            Assert.That(doesWeatheringExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            var Weathering = GetWeathering(_config, digBlockId);

            Assert.That(Weathering, Is.EqualTo(1));
        }

        [Test]
        public void Does_A_Null_Weathering_Message_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Null-Values.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesWeatheringExist = DoesWeatheringExist(_config, 1);
            Assert.That(doesWeatheringExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            var Weathering = GetWeathering(_config, digBlockId);

            Assert.That(Weathering, Is.Null);
        }

        [Test]
        public void Does_A_Valid_Weathering_Message_Update_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Weathering.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesWeatheringExist = DoesWeatheringExist(_config, 1);
            Assert.That(doesWeatheringExist, Is.True);

            doesWeatheringExist = DoesWeatheringExist(_config, 2);
            Assert.That(doesWeatheringExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_GUID, _config, arguments);

            // Add existing
            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            // Now update to from 3430 to 3420
            resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Weathering-Update-Value.xml";

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var Weathering = GetWeathering(_config, digBlockId);

            Assert.That(Weathering, Is.EqualTo(2));
        }

        [Test]
        public void Does_A_Null_Weathering_Message_Update_Get_Processed()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Weathering.xml";
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            bool doesWeatheringExist = DoesWeatheringExist(_config, 1);
            Assert.That(doesWeatheringExist, Is.True);

            RemoveExistingRecord(VALID_STRAT_DIGBLOCK, VALID_GUID, _config, arguments);

            // Add existing
            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, VALID_GUID);
            Assert.That(digBlockId, Is.Not.Null);
            Assert.That(digBlockId, Is.EqualTo(VALID_STRAT_DIGBLOCK));

            // Now update to from 3430 to NULL
            resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Valid-Null-Values.xml";

            PopulateStagingData(_config, resource, this.GetType().Assembly, VALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var Weathering = GetWeathering(_config, digBlockId);

            Assert.That(Weathering, Is.Null);
        }

        [Test]
        public void Does_An_Invalid_Weathering_Message_Raise_A_Validation_Error()
        {
            string resource = "Snowden.Reconcilor.Bhpbio.ImportTests.Resources.Staging-Import-Invalid-Weathering.xml";
            var checkDatesAfter = DateTime.Now;
            List<string> arguments = new List<string>();

            arguments.Add("/ImportName:Blocks");
            arguments.Add($@"/DestinationConnection:Server={_dbConfig.ServerInstance}; Database={_dbConfig.Name}; Integrated Security = SSPI;");
            arguments.Add(@"@Site:AREAC");
            arguments.Add(@"@Pit:CW");
            arguments.Add(@"@Bench:0641");

            int expectedWeathering = 99;
            var exists = DoesWeatheringExist(_config, expectedWeathering);
            Assert.That(exists, Is.False);

            RemoveExistingRecord(INVALID_STRAT_DIGBLOCK, INVALID_GUID, _config, arguments);

            PopulateStagingData(_config, resource, this.GetType().Assembly, INVALID_GUID);

            RunImportEngineBlockModel(arguments.AsReadOnly());

            var digBlockId = GetDigBlockId(_config, INVALID_GUID);
            Assert.That(digBlockId, Is.Null);

            bool validationMessagesExist = CheckValidationMessageExists(_config, expectedWeathering, INVALID_GUID, checkDatesAfter);

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
        private void AssertWeatheringExists(string blockGuid, int weathering)
        {
            var blockId = GetStagingBlockId(_config, blockGuid);

            Assert.That(blockId, Is.Not.Null);
            Assert.That(blockId.HasValue, Is.True);

            var dataTable = GetStagingBhpbioStageBlockModels(_config, blockId.Value);

            Assert.That(dataTable.Rows.Count, Is.EqualTo(1));

            Assert.That(dataTable.Rows[0]["Weathering"], Is.EqualTo(weathering));
        }


        private int? GetStagingBlockId(MessageHandlerConfiguration config, string guid)
        {
            return StagingTestsHelper.GetBlockId(config, guid);
        }

        private DataTable GetStagingBhpbioStageBlockModels(MessageHandlerConfiguration config, int blockId)
        {
            return StagingTestsHelper.GetStagingBhpbioStageBlockModels(config, blockId);
        }

        private bool DoesWeatheringExist(MessageHandlerConfiguration config, int weathering)
        {
            return StagingTestsHelper.DoesWeatheringExist(config, weathering);
        }

        private String GetDigBlockId(MessageHandlerConfiguration config, string guid)
        {
            return StagingDataSetupHelper.GetDigBlockId(config, guid);
        }

        private void RunImportEngineBlockModel(ReadOnlyCollection<string> commandLineArguments)
        {
            Int32 returnCode = ModMain.SetupAndRunImportFromTestHarness(commandLineArguments, ImportTypeEnum.BlockModel);
            Assert.That(returnCode, Is.EqualTo(0));
        }

        private int? GetWeathering(MessageHandlerConfiguration config, string digBlockId)
        {
            return StagingDataSetupHelper.GetWeathering(config, digBlockId);
        }

        private bool CheckValidationMessageExists(MessageHandlerConfiguration config, int expectedWeathering, string digblock, DateTime checkDatesAfter)
        {
            string weatheringString = expectedWeathering.ToString();
            string userMessage = "Weathering does not exist";
            string internalMessage = $"Weathering {expectedWeathering} does not exist";
            return StagingDataSetupHelper.CheckValidationMessageExists(config, weatheringString, digblock, checkDatesAfter, userMessage, internalMessage);
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
            //Delete the Staging block 
            ClearIntegrationTestStageBlocks(_config, new List<string>() { guid });
            //  Process the delete
            RunImportEngineBlockModel(arguments.AsReadOnly());
        }
    }
}