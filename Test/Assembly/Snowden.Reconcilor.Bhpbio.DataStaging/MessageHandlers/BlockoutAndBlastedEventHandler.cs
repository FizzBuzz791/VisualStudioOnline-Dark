using Snowden.Bcd.ProductConfiguration;
using Snowden.Consulting.IntegrationService.Model;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Transactions;
using System.Xml;
using System.Xml.Serialization;
using ProductConfiguration = Snowden.Bcd.ProductConfiguration;

namespace Snowden.Reconcilor.Bhpbio.DataStaging.MessageHandlers
{
    /// <summary>
    /// Handler for the Block out and Blasted event
    /// </summary>
    public class BlockoutAndBlastedEventHandler : IMessageHandler
    {
        private const string _ACTION_ADDED = "Added";
        private const string _ACTION_UPDATED = "Updated";
        private const string _ACTION_DELETED = "Deleted";

        private const string _GRADE_SET_INSITU = "IN-SITU";
        private const string _GRADE_SET_ASDROPPED = "AS-DROPPED";
        private const string _GRADE_SET_ASSHIPPED = "AS-SHIPPED";
        private const string _GRADE_SET_GEOMET_TYPE_NA = "NA";

        private const string _QUALITY_TYPE_LUMP = "LUMP";
        private const string _QUALITY_TYPE_FINES = "FINES";
        private const string _QUALITY_TYPE_ULTRAFINES = "ULTRAFINES";
        private const string _QUALITY_TYPE_HEAD = "HEAD";
        private const string _ANALYTE_ULTRAFINES = "ULTRAFINES";

        private const string GRADE_CONTROL_MODEL_NAME = "Grade Control";

        /// <summary>
        /// Constant used to define the configuration key used to specify the Product Configuration File
        /// </summary>
        private const string PRODUCT_CONFIGURATION_FILE_PATH_KEY = "ProductionConfigurationPath";

        /// <summary>
        /// Constant used to define the configuration key used to specify search values for string replacement
        /// </summary>
        private const string STRING_REPLACE_SEARCH_VALUES_KEY = "StringReplaceSearchValues";

        /// <summary>
        /// Constant used to define the configuration key used to specify replacement values for string replacement
        /// </summary>
        private const string STRING_REPLACE_REPLACEMENT_VALUES_KEY = "StringReplaceReplaceValues";

        /// <summary>
        /// Constant used to define the configuration key used to specify the Product User (needed for SQL connection string building)
        /// </summary>
        private const string PRODUCT_USER_KEY = "ProductUser";

        /// <summary>
        /// The key used to lookup the database name in the configuration
        /// </summary>
        private const string DATABASE_KEY = "Database";

        /// <summary>
        /// The maximum length allowed for a pattern number
        /// </summary>
        private const int _MAX_PATTERN_NUMBER_LENGTH = 4;


        /// <summary>
        /// The Reconcilor Product Configuration used to obtain database connection and other details
        /// </summary>
        private ProductConfiguration.ConfigurationManager _config = null;

        /// <summary>
        /// The name of the product user
        /// </summary>
        private string _productUserName;

        /// <summary>
        /// The set of string replace search values
        /// </summary>
        private List<string> _stringReplaceSearchValues = null;

        /// <summary>
        /// The set of string replace replace values
        /// </summary>
        private List<string> _stringReplaceReplaceValues = null;

        /// <summary>
        /// The connection string to be used for database operations
        /// </summary>
        private string _connectionString = null;

        /// <summary>
        /// Initialise the handler based on supplied configuration
        /// </summary>
        /// <param name="configuration">configuration data for this handler</param>
        public void Initialise(MessageHandlerConfiguration configuration)
        {
            if (configuration == null)
            {
                throw new ArgumentNullException("configuration");
            }

            string productConfigurationPath = configuration.InitialisationData[PRODUCT_CONFIGURATION_FILE_PATH_KEY].Value;
            if (!Path.IsPathRooted(productConfigurationPath)) 
            {
                productConfigurationPath = Path.Combine(Directory.GetCurrentDirectory(), productConfigurationPath);
            }

            if (!File.Exists(productConfigurationPath))
            {
                throw new ConfigurationErrorsException("The configuration for the BlockoutAndBlastedEventHandler does not specify an existing file");
            }

            _productUserName = configuration.InitialisationData[PRODUCT_USER_KEY].Value;
            if (string.IsNullOrEmpty(_productUserName))
            {
                throw new ConfigurationErrorsException("Handler configuration must specify a product user");
            }

            _config = new ProductConfiguration.ConfigurationManager(productConfigurationPath);
            _config.Open();

            string databaseName = configuration.InitialisationData[DATABASE_KEY].Value;
            if (string.IsNullOrEmpty(databaseName))
            {
                throw new ConfigurationErrorsException("Handler configuration must specify a database name");
            }

            // obtain and open a database connection string
            DatabaseConfiguration dbConfig = _config.GetDatabaseConfiguration(databaseName);
            if (dbConfig == null)
            {
                throw new ConfigurationErrorsException("The referenced product configuration did not have a definition for the specified database name");
            }

            _connectionString = dbConfig.GenerateSqlClientConnectionString(_productUserName);
            

            var searchValuesConfig = configuration.InitialisationData[STRING_REPLACE_SEARCH_VALUES_KEY];
            if (searchValuesConfig != null && searchValuesConfig.Value != null)
            {
                _stringReplaceSearchValues = searchValuesConfig.Value
                                                    .Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries)
                                                    .Select(s=>s.Trim())
                                                    .ToList();
            }

            var replaceValuesConfig = configuration.InitialisationData[STRING_REPLACE_REPLACEMENT_VALUES_KEY];
            if (replaceValuesConfig != null && replaceValuesConfig.Value != null)
            {
                _stringReplaceReplaceValues = replaceValuesConfig.Value
                                                    .Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries)
                                                    .Select(s => s.Replace("\r\n",string.Empty).Trim())
                                                    .ToList();
            }

            if (_stringReplaceSearchValues != null)
            {
                if (_stringReplaceReplaceValues == null || _stringReplaceReplaceValues.Count != _stringReplaceSearchValues.Count)
                {
                    throw new ConfigurationErrorsException("The count of search values must match the count of replace values");
                }
            }
        }

        /// <summary>
        /// Obtain metadata from this message useful for logging and troubleshooting
        /// </summary>
        /// <param name="message">the message from which diagnostic information is to be retrieved</param>
        /// <returns>metadata for the message</returns>
        public MessageMetadata ObtainMessageBodyMetadata(Message message)
        {
            MessageMetadata metadata = new MessageMetadata();

            return metadata;
        }

        /// <summary>
        /// Log a message
        /// </summary>
        /// <param name="messageBody">the text of the message</param>
        /// <param name="message">the actual message object</param>
        private void LogMessage(Message message, BlockOutAndBlastedEventType messageEvent)
        {

            DateTime? messageTimestamp = null;
            string dataKey = null;

            if (messageEvent != null)
            {
                messageTimestamp = messageEvent.Timestamp;

                if (messageEvent.PatternDetails != null) 
                {
                    dataKey = messageEvent.PatternDetails.PatternGUID;
                }
            }

            // create the connection in a using block to ensure that it is closed properly and released back to the pool
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                // try to open the connection
                connection.Open();

                Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility utilityDal = new Bhpbio.Database.SqlDal.SqlDalUtility(connection);
                utilityDal.LogMessage(DateTime.Now, messageTimestamp, message.MessageBody, typeof(BlockOutAndBlastedEventType).Name, dataKey);
            }
        }
        /// <summary>
        /// Process the message
        /// </summary>
        /// <param name="message">Blockout and Blasted event to be processed</param>
        /// <remarks>
        /// This method will throw exceptions back to the calling process.
        /// This method requires a transaction scope and will create one if one does not already exist
        /// </remarks>
        public void Process(Message message)
        {
            if (message == null)
            {
                throw new ArgumentNullException("message");
            }

            if (string.IsNullOrEmpty(message.MessageBody))
            {
                throw new ArgumentException("The message must have a non-empty body", "message");
            }

            // extract the body from the message performing any pre-processing required
            string processedMessageBody = ExtractAndPreProcessMessageBody(message);

            BlockOutAndBlastedEventType blockOutAndBlastedEvent = null;

            try
            {
                // deserialise the event
                blockOutAndBlastedEvent = DeserialiseEvent(processedMessageBody);    
            }
            finally
            {
                // log the message to the database whether or not it was deserialised
                LogMessage(message, blockOutAndBlastedEvent);
            }
            
            // perform some basic sense checking on the message
            PerformBasicEventValidation(blockOutAndBlastedEvent);

            // start a transaction scope
            using (TransactionScope scope = new TransactionScope(TransactionScopeOption.Required))
            {
                // create the connection in a using block to ensure that it is closed properly and released back to the pool
                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    // try to open the connection
                    connection.Open();

                    // provide the connection to the DAL
                    IBhpbioBlock bhpbioImportDal = new Bhpbio.Database.SqlDal.SqlDalBhpbioBlock(connection);
                    
                    // obtain the timestamp used to compare the contents of this message against what is already in staging
                    DateTime timestamp = blockOutAndBlastedEvent.Timestamp;

                    // process Block deletes first
                    foreach (BlockType block in blockOutAndBlastedEvent.PatternDetails.Block
                                .Where<BlockType>((b)=> { return ((b.ChangeState ?? string.Empty).ToUpper() == _ACTION_DELETED.ToUpper());}))
                    {
                        // delete the Block (and all model data) if it exists.. otherwise need to record the delete
                        PerformBlockDelete(bhpbioImportDal, timestamp, block);
                    }

                    // process every Block that is an Add or Update
                    foreach (BlockType block in blockOutAndBlastedEvent.PatternDetails.Block
                                .Where<BlockType>((b) => { return (
                                                                string.IsNullOrEmpty(b.ChangeState)
                                                                || (b.ChangeState ?? string.Empty).ToUpper() == _ACTION_UPDATED.ToUpper()
                                                                || (b.ChangeState ?? string.Empty).ToUpper() == _ACTION_ADDED.ToUpper());
                                }))
                    {
                        PerformBlockAddOrUpdate(blockOutAndBlastedEvent, bhpbioImportDal, timestamp, block);
                    }
                }

                // complete the scope
                scope.Complete();
            }
        }

        /// <summary>
        /// Add or update the Block
        /// </summary>
        /// <param name="blockOutAndBlastedEvent">the event containing information for the block out or re-block out</param>
        /// <param name="bhpbioImportDal">the dal used to perform database work</param>
        /// <param name="timestamp">the timestamp of the message</param>
        /// <param name="block">data pertaining to the block to be added or updated</param>
        private void PerformBlockAddOrUpdate(BlockOutAndBlastedEventType blockOutAndBlastedEvent, IBhpbioBlock bhpbioImportDal, DateTime timestamp, BlockType block)
        {
            // add or update the Block ONLY if this is the latest
            bool isLatest = false;
            int? blockId = null;

            bhpbioImportDal.AddOrUpdateBhpbioStageBlockIfLatest(timestamp,
                                block.BlockGUID,
                                block.Name,
                                block.BlockNumber,
                                block.GeoType,
                                block.FlitchGUID,
                                blockOutAndBlastedEvent.PatternDetails.PatternGUID,
                                (blockOutAndBlastedEvent.PatternDetails.SiteId ?? string.Empty).ToUpper(),
                                blockOutAndBlastedEvent.PatternDetails.OrebodyId,
                                blockOutAndBlastedEvent.PatternDetails.PitId_Log,
                                blockOutAndBlastedEvent.PatternDetails.PitId_MQ2,
                                blockOutAndBlastedEvent.PatternDetails.Bench,
                                blockOutAndBlastedEvent.PatternDetails.PatternNumber,
                                block.DateBlocked,
                                block.Centroid.Easting,
                                block.Centroid.Northing,
                                block.Centroid.ToeRL,
                                ref blockId,
                                ref isLatest
                                );

            if (isLatest)
            {
                Debug.Assert(blockId != null, "The block Id must be specified by the DAL when it is determined that the timestamp is the latest for the Block");

                // replace the polygon block points
                ReplaceStagingBlockPoints(bhpbioImportDal, timestamp, block, blockId.Value);

                if (block.ModelBlock != null)
                {
                    HashSet<string> modelTypesForBlock = new HashSet<string>();

                    // add or update each Model Block
                    foreach (ModelBlockType modelBlock in block.ModelBlock)
                    {
                        string modelType = ConvertToTitleCase(modelBlock.ModelType);

                        if (!modelTypesForBlock.Contains(modelType))
                        {
                            // delete all pre-existing model blocks for this Block of the specified model type
                            bhpbioImportDal.DeleteBhpbioStageBlockModels(
                                blockId.Value,
                                modelType);

                            modelTypesForBlock.Add(modelType);
                        }

                        int? modelBlockId = null;
                        decimal? lumpPercentAsShipped = null;
                        decimal? lumpPercentAsDropped = null;
                        decimal? ultrafinesPercentAsDropped = null;
                        decimal? ultrafinesPercentAsShipped = null;

                        QualityType qualitySetInSituRom = null, 
                            qualitySetAsShippedLump = null, 
                            qualitySetAsShippedFines = null, 
                            qualitySetAsDroppedLump = null, 
                            qualitySetAsDroppedFines = null,
                            qualitySetAsDroppedUltrafines = null,
                            qualitySetAsShippedUltrafines = null;

                        string modelFileName = null;
                        modelFileName = GetModelFilename(blockOutAndBlastedEvent, modelBlock.ModelType);

                        string stratNum = null;
                        stratNum = GetStratNum(block, modelBlock.ModelType);

                        ExtractGradeSetsAndQualityTypes(modelBlock,
                            ref qualitySetInSituRom,
                            ref qualitySetAsDroppedLump,
                            ref qualitySetAsDroppedFines,
                            ref qualitySetAsShippedLump,
                            ref qualitySetAsShippedFines,
                            ref qualitySetAsDroppedUltrafines,
                            ref qualitySetAsShippedUltrafines);

                        lumpPercentAsShipped = (qualitySetAsShippedLump != null) ? (decimal?)qualitySetAsShippedLump.QualityTypeSplitPercentage : null;
                        lumpPercentAsDropped = (qualitySetAsDroppedLump != null) ? (decimal?)qualitySetAsDroppedLump.QualityTypeSplitPercentage : null;
                        ultrafinesPercentAsShipped = (qualitySetAsShippedUltrafines != null) ? (decimal?)qualitySetAsShippedUltrafines.QualityTypeSplitPercentage : null;
                        ultrafinesPercentAsDropped = (qualitySetAsDroppedUltrafines != null) ? (decimal?)qualitySetAsDroppedUltrafines.QualityTypeSplitPercentage : null;

                        AddAnalytesForUltrafines(lumpPercentAsDropped, ultrafinesPercentAsDropped, qualitySetAsDroppedFines, qualitySetAsDroppedLump);
                        AddAnalytesForUltrafines(lumpPercentAsShipped, ultrafinesPercentAsShipped, qualitySetAsShippedFines, qualitySetAsShippedLump);
                        
                        // add or update the model block
                        bhpbioImportDal.AddBhpbioStageBlockModel(
                            modelType,
                            blockId.Value,
                            modelBlock.OreType,
                            modelBlock.Volume,
                            modelBlock.Tonnes,
                            modelBlock.Density,
                            modelBlock.LastModifiedUserName,
                            modelBlock.LastModifiedDateTime,
                            modelFileName,
                            lumpPercentAsShipped,
                            lumpPercentAsDropped,
                            stratNum,
                            ref modelBlockId);

                        if (qualitySetInSituRom != null)
                        {
                            // write out the grades
                            foreach (var grade in qualitySetInSituRom.Analytes)
                            {
                                // in-situ / no geomet
                                AddModelBlockGrade(bhpbioImportDal, _GRADE_SET_GEOMET_TYPE_NA, modelBlockId.Value, grade.AnalyteName, grade, null, null);

                                // store both As-Dropped and As-Shipped
                                AddModelBlockGrade(bhpbioImportDal, _GRADE_SET_ASDROPPED, modelBlockId.Value, grade.AnalyteName, grade, qualitySetAsDroppedFines, qualitySetAsDroppedLump);
                                AddModelBlockGrade(bhpbioImportDal, _GRADE_SET_ASSHIPPED, modelBlockId.Value, grade.AnalyteName, grade, qualitySetAsShippedFines, qualitySetAsShippedLump);
                            }

                            // add the Ultrafines grades
                            if (ultrafinesPercentAsDropped != null && lumpPercentAsDropped != null)
                            {
                                var asDroppedUltrafinesPercentOfTotalMaterial = ultrafinesPercentAsDropped.Value * lumpPercentAsDropped.Value / (decimal)100.0;
                                AddModelBlockGrade(bhpbioImportDal, _GRADE_SET_ASDROPPED, modelBlockId.Value, _ANALYTE_ULTRAFINES, new AnalyteType() { AnalyteName = _ANALYTE_ULTRAFINES, Value = (double)asDroppedUltrafinesPercentOfTotalMaterial }, qualitySetAsDroppedFines, qualitySetAsDroppedLump);
                            }

                            if (ultrafinesPercentAsShipped != null && lumpPercentAsShipped != null)
                            {
                                var asShippedUltrafinesPercentOfTotalMaterial = ultrafinesPercentAsShipped.Value * lumpPercentAsShipped.Value / (decimal)100.0;
                                AddModelBlockGrade(bhpbioImportDal, _GRADE_SET_ASSHIPPED, modelBlockId.Value, _ANALYTE_ULTRAFINES, new AnalyteType() { AnalyteName = _ANALYTE_ULTRAFINES, Value = (double)asShippedUltrafinesPercentOfTotalMaterial }, qualitySetAsShippedFines, qualitySetAsShippedLump);
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Add a grade for Ultrafines based on provided percentages
        /// </summary>
        /// <param name="lumpPercent">the lump percent</param>
        /// <param name="ultrafinesPercent">the percent of ultrafines in fines</param>
        /// <param name="qualitySetFines">The set of fines grades to be added</param>
        /// <param name="qualitySetLump">The set of lump grades to be added</param>
        private void AddAnalytesForUltrafines(decimal? lumpPercent, decimal? ultrafinesPercent, QualityType qualitySetFines, QualityType qualitySetLump)
        {
            if (ultrafinesPercent != null)
            {
                if (qualitySetFines != null && qualitySetFines.Analytes != null)
                {
                    // add ultrafines percentage as a percentage within the as dropped fines
                    qualitySetFines.Analytes.Add(new AnalyteType() { AnalyteName = _ANALYTE_ULTRAFINES, Value = (double)ultrafinesPercent });
                }
                if (qualitySetLump != null && qualitySetLump.Analytes != null)
                {
                    qualitySetLump.Analytes.Add(new AnalyteType() { AnalyteName = _ANALYTE_ULTRAFINES, Value = 0 });
                }
            }
        }

        /// <summary>
        /// Converts text to title case
        /// </summary>
        /// <param name="text">the text to be converted</param>
        /// <returns>the titlecase text</returns>
        private static string ConvertToTitleCase(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            StringBuilder titleCase = new StringBuilder();

            string[] parts = text.Split(new char[] { ' ' });

            int index = 0;
            foreach (string part in parts)
            {
                if (index > 0)
                {
                    titleCase.Append(" ");
                }

                if (!string.IsNullOrEmpty(part))
                {
                    titleCase.Append(part.First().ToString().ToUpper());

                    if (part.Length > 1)
                    {
                        titleCase.Append(part.Substring(1).ToLower());
                    }
                }
                index++;
            }

            return titleCase.ToString();
        }

        /// <summary>
        /// Extract the Quality Set data relevant for obtaining grade data
        /// </summary>
        /// <param name="modelBlock">the model block whose quality sets are to be obtained</param>
        /// <param name="qualitySetInSituRom">the quality set containing in situ rom analytes</param>
        /// <param name="qualitySetAsDroppedLump">the quality set containing as dropped lump analytes</param>
        /// <param name="qualitySetAsDroppedFines">the quality set containing as dropped fines analytes</param>
        /// <param name="qualitySetAsShippedLump">the quality set containing as shipped lump analytes</param>
        /// <param name="qualitySetAsShippedFines">the quality set containing as shipped fines analytes</param>
        /// <param name="qualitySetAsDroppedUltrafines">the quality set containing as dropped ultrafines split percentage</param>
        /// <param name="qualitySetAsShippedUltrafines">the quality set containing as shipped ultrafines split percentage</param>
        private void ExtractGradeSetsAndQualityTypes(ModelBlockType modelBlock,
            ref QualityType qualitySetInSituRom,
            ref QualityType qualitySetAsDroppedLump,
            ref QualityType qualitySetAsDroppedFines,
            ref QualityType qualitySetAsShippedLump,
            ref QualityType qualitySetAsShippedFines,
            ref QualityType qualitySetAsDroppedUltrafines,
            ref QualityType qualitySetAsShippedUltrafines
            )
        {
            qualitySetInSituRom = null;
            qualitySetAsDroppedLump = null;
            qualitySetAsDroppedFines = null;
            qualitySetAsShippedLump = null;
            qualitySetAsShippedFines = null;

            if (modelBlock.GradeSet != null)
            {
                // get the As-Shipped grade set
                GradeSetType gradeSetAsShipped = modelBlock.GradeSet.FirstOrDefault(gs => string.Compare(gs.GradeSetType1, _GRADE_SET_ASSHIPPED, ignoreCase: true) == 0);

                // get the As-Dropped grade set
                GradeSetType gradeSetAsDropped = modelBlock.GradeSet.FirstOrDefault(gs => string.Compare(gs.GradeSetType1, _GRADE_SET_ASDROPPED, ignoreCase: true) == 0);

                // get the In-Situ grade set
                GradeSetType gradeSetInSitu = modelBlock.GradeSet.FirstOrDefault(gs => string.Compare(gs.GradeSetType1, _GRADE_SET_INSITU, ignoreCase: true) == 0);

                if (gradeSetInSitu != null && gradeSetInSitu.QualitySet != null)
                {
                    qualitySetInSituRom = gradeSetInSitu.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_HEAD, ignoreCase: true) == 0);
                }

                if (gradeSetAsShipped != null && gradeSetAsDropped.QualitySet != null)
                {
                    qualitySetAsDroppedLump = gradeSetAsDropped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_LUMP, ignoreCase: true) == 0);
                    qualitySetAsDroppedFines = gradeSetAsDropped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_FINES, ignoreCase: true) == 0);
                    qualitySetAsDroppedUltrafines = gradeSetAsDropped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_ULTRAFINES, ignoreCase: true) == 0);
                }

                if (gradeSetAsShipped != null && gradeSetAsShipped.QualitySet != null)
                {
                    qualitySetAsShippedLump = gradeSetAsShipped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_LUMP, ignoreCase: true) == 0);
                    qualitySetAsShippedFines = gradeSetAsShipped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_FINES, ignoreCase: true) == 0);
                    qualitySetAsShippedUltrafines = gradeSetAsShipped.QualitySet.FirstOrDefault(qs => string.Compare(qs.QualityType1, _QUALITY_TYPE_ULTRAFINES, ignoreCase: true) == 0);
                }
            }
        }

        /// <summary>
        /// Extract the model file name information relevant for the specified model type from the event
        /// </summary>
        /// <param name="blockOutAndBlastedEvent">the event containing the full set of data</param>
        /// <param name="modelType">the model type</param>
        /// <returns>the filename</returns>
        private static string GetModelFilename(BlockOutAndBlastedEventType blockOutAndBlastedEvent, string modelType)
        {
            string modelFileName = null;

            if (blockOutAndBlastedEvent.SourceModelDetail != null)
            {
                // this should be a list
                SourceModelDescriptorType modelDescriptor = blockOutAndBlastedEvent.SourceModelDetail;

                if (modelDescriptor.ModelType == modelType)
                {
                    modelFileName = modelDescriptor.ModelFile;
                }
            }

            return modelFileName;
        }

        private static string GetStratNum(BlockType block, string modelType)
        {
            string stratNum = null;
            if (modelType.ToUpper() == GRADE_CONTROL_MODEL_NAME.ToUpper())
            {
                stratNum = block.StratNum.ToString();
            }

            return stratNum;
        }

        /// <summary>
        /// Replace point data for the specified block
        /// </summary>
        /// <param name="bhpbioImportDal">dal used to perform the update</param>
        /// <param name="timestamp">the timestamp for the update</param>
        /// <param name="block">block contain point data for the update</param>
        /// <param name="blockId">the internal Id of the Block</param>
        private static void ReplaceStagingBlockPoints(IBhpbioBlock bhpbioImportDal, DateTime timestamp, BlockType block, int blockId)
        {
            // delete current points
            bhpbioImportDal.DeleteBhpbioStageBlockPoints(blockId);

            // if points are specified
            if (block.PolygonPoint != null)
            {
                // add each one, one by one
                foreach (MiningPointType point in block.PolygonPoint)
                {
                    bhpbioImportDal.AddBhpbioStageBlockPoint(blockId, point.Easting, point.Northing, point.ToeRL, point.PointNumber);
                }
            }
        }

        /// <summary>
        /// Delete data for a Block
        /// </summary>
        /// <param name="bhpbioImportDal">Dal used to perform the delete</param>
        /// <param name="timestamp">the timestamp for this message</param>
        /// <param name="block">the Block to be deleted</param>
        private static void PerformBlockDelete(IBhpbioBlock bhpbioImportDal, DateTime timestamp, BlockType block)
        {
            bhpbioImportDal.DeleteBhpbioStageBlock(timestamp, block.BlockGUID);
        }

        /// <summary>
        /// Perform basic validation of the message
        /// </summary>
        /// <param name="blockOutAndBlastedEvent">the event to be validated</param>
        private static void PerformBasicEventValidation(BlockOutAndBlastedEventType blockOutAndBlastedEvent)
        {
            if (blockOutAndBlastedEvent.PatternDetails == null)
            {
                throw new InvalidOperationException("Message cannot be processed without PatternDetail");
            }

            if (string.IsNullOrEmpty(blockOutAndBlastedEvent.PatternDetails.PatternGUID))
            {
                throw new InvalidOperationException("Message cannot be processed without a PatternGUID");
            }

            if (string.IsNullOrEmpty(blockOutAndBlastedEvent.PatternDetails.PatternNumber))
            {
                throw new InvalidOperationException("Message cannot be processed without a PatternNumber");
            }

            if (blockOutAndBlastedEvent.PatternDetails.PatternNumber.Length > _MAX_PATTERN_NUMBER_LENGTH)
            {
                throw new InvalidOperationException(string.Format("Message cannot be processed with a PatternNumber: {0} exceeding allowed length: {1}", blockOutAndBlastedEvent.PatternDetails.PatternNumber, _MAX_PATTERN_NUMBER_LENGTH));
            }

            if (string.IsNullOrEmpty(blockOutAndBlastedEvent.PatternDetails.PitId_MQ2))
            {
                throw new InvalidOperationException("Message cannot be processed without a PitId_MQ2");
            }

            if (string.IsNullOrEmpty(blockOutAndBlastedEvent.PatternDetails.PitId_Log))
            {
                throw new InvalidOperationException("Message cannot be processed without a PitId_Log");
            }

            if (string.IsNullOrEmpty(blockOutAndBlastedEvent.PatternDetails.Bench))
            {
                throw new InvalidOperationException("Message cannot be processed without a Bench");
            }

            if (blockOutAndBlastedEvent.PatternDetails.Block == null)
            {
                throw new InvalidOperationException("Message cannot be processed without a set of Blocks within PatternDetail");
            }
        }

        /// <summary>
        /// Deserialise xml data into an object graph for processing
        /// </summary>
        /// <param name="messageBody">the messageBody to be deserialised</param>
        /// <returns></returns>
        private static BlockOutAndBlastedEventType DeserialiseEvent(string messageBody)
        {
            // deserialise the message
            XmlSerializer serializer = new XmlSerializer(typeof(BlockOutAndBlastedEventType));
            StringReader stringReader = new StringReader(messageBody);

            BlockOutAndBlastedEventType blockOutAndBlastedEvent = serializer.Deserialize(stringReader) as BlockOutAndBlastedEventType;

            // optionally replace the namespaces
            if (blockOutAndBlastedEvent == null)
            {
                throw new InvalidOperationException("Cannot process invalid message");
            }

            blockOutAndBlastedEvent.Timestamp = blockOutAndBlastedEvent.Timestamp.ToLocalTime();

            return blockOutAndBlastedEvent;
        }

        /// <summary>
        /// Extract the message body and perform pre-processing including any configured string replacements
        /// </summary>
        /// <param name="message">the message whose message body is to be extracted</param>
        /// <returns>the extracted and pre-processed message body text</returns>
        private string ExtractAndPreProcessMessageBody(Message message)
        {
            string messageBody = message.MessageBody;

            // perform any search and replace operations
            // this relies of a configured set of search values and replace values
            if (_stringReplaceSearchValues != null && _stringReplaceReplaceValues != null)
            {
                if (_stringReplaceSearchValues.Count != _stringReplaceReplaceValues.Count)
                {
                    throw new InvalidOperationException("Mismatched definition of search and repalce values");
                }

                int index = 0;
                foreach (string searchValue in _stringReplaceSearchValues)
                {
                    string replaceValue = _stringReplaceReplaceValues[index];
                    messageBody = messageBody.Replace(searchValue, replaceValue);
                    index++;
                }
            }
            return messageBody;
        }

        /// <summary>
        /// Add a model block grade record
        /// </summary>
        /// <param name="dal">the DAL to be used for the add</param>
        /// <param name="geometType">The source of geomet data</param>
        /// <param name="modelBlockId">the Id of the model block that new grades are to be associated with</param>
        /// <param name="analyteName">the name of the analyte</param>
        /// <param name="romAnalyteValue">the rom value</param>
        /// <param name="finesSource">source quality set for fines values</param>
        /// <param name="lumpSource">source quality set for lump values</param>
        private void AddModelBlockGrade(IBhpbioBlock dal, string geometType, int modelBlockId, string analyteName, AnalyteType romAnalyteValue, QualityType finesSource, QualityType lumpSource)
        {
            string lookupName = (romAnalyteValue != null) ? romAnalyteValue.AnalyteName : analyteName;
            AnalyteType finesAnalyte = (finesSource != null && finesSource.Analytes != null) ? finesSource.Analytes.FirstOrDefault(a=>a.AnalyteName == lookupName) : null;
            AnalyteType lumpAnalyte = (lumpSource != null && lumpSource.Analytes != null) ? lumpSource.Analytes.FirstOrDefault(a=>a.AnalyteName == lookupName) : null;

            double? romValue = (romAnalyteValue != null) ? (double?)romAnalyteValue.Value : null;
            double? finesValue = (finesAnalyte != null) ? (double?)finesAnalyte.Value : null;
            double? lumpValue = (lumpAnalyte != null) ? (double?)lumpAnalyte.Value : null;

            dal.AddBhpbioStageBlockModelGrade(modelBlockId, geometType, analyteName, romValue, lumpValue, finesValue);
        }
        
        /// <summary>
        /// Dispose of this handler and release any resources
        /// </summary>
        public void Dispose()
        {
        }
    }
}

