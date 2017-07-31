using Snowden.Consulting.DataSeries.DataAccess.DataTypes;
using Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions;
using Snowden.Reconcilor.Bhpbio.Report.Types;
using BhpbDal = Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Snowden.Consulting.DataSeries.Processing;
using System.ComponentModel;
using System.Threading;
using Snowden.Consulting.DataSeries.DataAccess;

namespace Snowden.Reconcilor.Bhpbio.DataSeries
{
    /// <summary>
    /// Implementation of a series data retriever suited for integration with DataSeries analysis components (including outlier detection)
    /// </summary>
    /// <remarks>Work in progress: currently sufficient to test DAL methods</remarks>
    public class ReportSeriesDataRetriever : IPointRetriever
    {
        #region Private Types

        /// <summary>
        /// Defines a set of work for the retriever
        /// </summary>
        private class WorkDefinition
        {
            public int LocationId { get; set; }

            public bool IncludeChildLocations { get; set; }

            public DataTable ResultDataTable { get; set; }

            public List<KeyValuePair<Series, double>> ResultSeriesPoints {get;set;}

            public AutoResetEvent DoneEvent { get; set; }

            public Exception Error { get; set; }
        }

        #endregion

        /// <summary>
        /// Flag used to control whether mutlithreaded operation is allowed
        /// </summary>
        private const bool _allowMultiThreaded = true;

        /// <summary>
        /// Maximum allowed concurrent workers
        /// </summary>
        private const int _maxInProgressConcurrent = 4;
        
        /// <summary>
        /// Connection string used by this data retriever
        /// </summary>
        private string _connectionString;

        /// <summary>
        /// If true, this retriever can be used to discover new series types rather than fill points for provided series types
        /// </summary>
        public bool DiscoverSeriesTypes { get; set; }

        /// <summary>
        /// Gets a data structure containing the series types discovered on the last retrieval organised by Id
        /// </summary>
        public Dictionary<string, SeriesType> LastDiscoveredSeriesTypes { get; private set; }

        /// <summary>
        /// Represents the WAIO Location Type Hierarchy
        /// </summary>
        private static readonly List<string> _locationTypeHierarchy = new List<string>() { "PIT", "SITE", "HUB", "COMPANY", "WAIO" };

        /// <summary>
        /// Default Constructor
        /// </summary>
        public ReportSeriesDataRetriever()
        {
            LastDiscoveredSeriesTypes = null;
        }

        /// <summary>
        /// Set the connections string for this retriever
        /// </summary>
        /// <param name="connectionString">the connection string for this retriever</param>
        /// <remarks>If this method is used, the retriever will not obtain the connection string using the product configuration which is the default behaviour</remarks>
        public void SetConnectionString(string connectionString)
        {
            _connectionString = connectionString;
        }

        
        /// <summary>
        /// Get Points for the specified series types and ordinal
        /// </summary>
        /// <param name="seriesTypes">the set of series types</param>
        /// <param name="ordinal">the ordinal value (time or other sequential reference) to obtain points for</param>
        /// <returns>A structure containing the point for each series</returns>
        public List<KeyValuePair<Series, double>> GetPoints(Dictionary<string, SeriesType> seriesTypeById, long ordinal)
        {
            if (_connectionString == null)
            {
                _connectionString = DataRetrieverCommon.ObtainConnectionStringFromConfiguration();
            }

            LastDiscoveredSeriesTypes = null;

            // create a structure to represent the series types discovered in this run
            Dictionary<string, SeriesType> discoveredSeriesTypes = new Dictionary<string, SeriesType>();

            // create a data structure for results
            List<KeyValuePair<Series, double>> valuesPerSeries = new List<KeyValuePair<Series, double>>();
            Dictionary<int, string> locationTypeById = new Dictionary<int, string>();

            // create a report session
            ReportSession session = CreateSession(_connectionString);
            
            DateTime monthForOrdinal = DataRetrieverCommon.GetMonthForOrdinal(ordinal);
            DateTime endMonth = monthForOrdinal.AddMonths(1).AddSeconds(-1);
            BhpbDal.SqlDalUtility utilityDal = new BhpbDal.SqlDalUtility(_connectionString);

            // data is required for:
            // Each Pit
            // Each Site
            // Each Hub
            // WAIO
            
            // get the Id of the WAIO level
            int topLevelLocationId = utilityDal.GetBhpbioLocationRoot();
            locationTypeById.Add(topLevelLocationId, "WAIO");

            // get the Id of the Hubs
            var hubDataTable = utilityDal.GetBhpbioLocationChildrenNameWithOverride(topLevelLocationId, monthForOrdinal, endMonth);
            List<int> hubLocationIds = DataRetrieverCommon.ExtractLocationIdsFromDataTable(hubDataTable,"Location_Id");
            List<int> siteLocationIds = new List<int>();

            // get the Id of the sites of each hub
            foreach (int hubLocationId in hubLocationIds)
            {
                locationTypeById.Add(hubLocationId, "HUB");

                var siteDataTable = utilityDal.GetBhpbioLocationChildrenNameWithOverride(hubLocationId, monthForOrdinal, endMonth);
                var newIds = DataRetrieverCommon.ExtractLocationIdsFromDataTable(siteDataTable, "Location_Id");

                if (newIds != null && newIds.Count > 0)
                {
                    siteLocationIds.AddRange(newIds);
                }
            }

            // get the Id of the Pits at each site
            foreach (int siteLocationId in siteLocationIds)
            {
                locationTypeById.Add(siteLocationId, "SITE");

                var siteDataTable = utilityDal.GetBhpbioLocationChildrenNameWithOverride(siteLocationId, monthForOrdinal, endMonth);
                var newIds = DataRetrieverCommon.ExtractLocationIdsFromDataTable(siteDataTable, "Location_Id");

                if (newIds != null && newIds.Count > 0)
                {
                    foreach (int id in newIds)
                    {
                        locationTypeById.Add(id, "PIT");
                    }
                }
            }

            List<BackgroundWorker> workers = new List<BackgroundWorker>();
            List<WorkDefinition> workDefinitions = new List<WorkDefinition>();

            // setup a work definition to request data by site for all pits
            foreach (int siteLocationid in siteLocationIds)
            {
                workDefinitions.Add(new WorkDefinition() { IncludeChildLocations = true, LocationId = siteLocationid });
            }

            // setup a work definition to request data by hub level for all sites
            foreach (int hubLocationid in hubLocationIds)
            {
                workDefinitions.Add(new WorkDefinition() { IncludeChildLocations = true, LocationId = hubLocationid });
            }

            // setup a work definition to request data at WAIO level for all hubs
            workDefinitions.Add(new WorkDefinition() { IncludeChildLocations = true, LocationId = topLevelLocationId });
            // setup a work definition to request data at WAIO level for WAIO
            workDefinitions.Add(new WorkDefinition() { IncludeChildLocations = false, LocationId = topLevelLocationId });

            bool multiThreaded = _allowMultiThreaded && !DiscoverSeriesTypes; // work mutlithreaded unless discovering series types

            // do the work using background workers
            foreach (var workDefinition in workDefinitions)
            {
                // define a function for the work.
                DoWorkEventHandler workFunction = (o, e) =>
                {
                    // each worker must have its own session
                    using (var sessionForWorker = CreateSession(_connectionString))
                    {
                        // do the actual work and store the results in the work definition
                        workDefinition.ResultDataTable = ValidationApprovalData.GetValidationData(sessionForWorker, monthForOrdinal, monthForOrdinal.AddMonths(1).AddDays(-1), workDefinition.LocationId, childLocations: workDefinition.IncludeChildLocations, calcId: null, includeDensityCalculations: true, includeMoistureCalculations: true);
                        int? excludeLocationId = null;

                        if (workDefinition.IncludeChildLocations == true)
                        {
                            excludeLocationId = workDefinition.LocationId;
                        }

                        workDefinition.ResultSeriesPoints = ExtractAndMatchPoints(workDefinition.ResultDataTable, seriesTypeById, discoveredSeriesTypes, CalculationResultRecord.GradeNames, locationTypeById, excludeLocationId);
                    }
                };

                if (multiThreaded)
                {
                    // count how many workers working concurrently
                    int working = workDefinitions.Count(w => w.DoneEvent != null);

                    // more working than allowed concurrently
                    if (working > _maxInProgressConcurrent)
                    {
                        // wait for one to finish
                        var doneEvent = workDefinitions.Select(w => w.DoneEvent).Where(e=>e!=null).FirstOrDefault();
                        if (doneEvent != null)
                        {
                            bool done = doneEvent.WaitOne(DataRetrieverCommon.ThreadWaitTimeout);

                            if (!done)
                            {
                                throw new TimeoutException("Timeout waiting on ReportSeriesDataRetriever worker thread (working >= max concurrent)");
                            }
                        }
                    }

                    // start work using a new background worker
                    BackgroundWorker worker = new BackgroundWorker();
                    worker.DoWork += workFunction;
                    workDefinition.DoneEvent = new AutoResetEvent(false);
                    workers.Add(worker);
                    worker.RunWorkerCompleted += (o, e) =>
                    {
                        workDefinition.Error = e.Error;
                        // flag the work as done regardless of success / failure in case anything is monitoring the event
                        workDefinition.DoneEvent.Set();
                        // set the reference to null (no need for anything external (that hasn't already referenced this event) to wait on this event 
                        workDefinition.DoneEvent = null;
                    };
                    worker.RunWorkerAsync();
                }
                else
                {
                    // just work on this thread
                    workFunction(this, new DoWorkEventArgs(null));
                }
            }

            // wait for all work to complete
            foreach (var workDefinition in workDefinitions)
            {
                if (workDefinition.DoneEvent != null)
                {
                    bool done = workDefinition.DoneEvent.WaitOne(DataRetrieverCommon.ThreadWaitTimeout);

                    if (!done)
                    {
                        throw new TimeoutException("Timeout waiting on ReportSeriesDataRetriever worker thread");
                    }
                }
            }

            var failCount = workDefinitions.Count(w => w.Error != null);
            if (failCount > 0)
            {
                var firstFail = workDefinitions.First(w => w.Error != null);
                // workers failed
                throw new ApplicationException(string.Format("Data retrieval failed for one or more locations ({0}). First: {1}",failCount, firstFail.LocationId), firstFail.Error);
            }

            // collate the results
            foreach (var workDefinition in workDefinitions)
            {
                if (workDefinition.ResultSeriesPoints != null)
                {
                    valuesPerSeries.AddRange(workDefinition.ResultSeriesPoints);
                }
            }
            
            LastDiscoveredSeriesTypes = discoveredSeriesTypes;

            return valuesPerSeries;
        }
        
        private ReportSession CreateSession(string connectionString)
        {
            return new ReportSession(connectionString)
            {
                Context = ReportContext.ApprovalListing, // set the context to approval listing .. this combines live and approved data
                IncludeProductSizeBreakdown = true,
                IncludeModelDataForInactiveLocations = true,
            };
        }

        /// <summary>
        /// Extract points from a datetable, match results to series type and add values per series
        /// </summary>
        /// <param name="calculationResults">results of a calculation</param>
        /// <param name="seriesTypeById">dictionary of series type by calculation key</param>
        /// <param name="discoveredSeriesTypeById">dictionary of series types discovered during processing</param>
        /// <param name="excludeLocationId">a location ID to be excluded from matching</param>
        /// <returns>A list of values by series type</returns>
        private List<KeyValuePair<Series, double>>  ExtractAndMatchPoints(DataTable calculationResults, Dictionary<string, SeriesType> seriesTypeById, Dictionary<string, SeriesType> discoveredSeriesTypeById, IEnumerable<string> gradeList, Dictionary<int, string> locationTypeById, int? excludeLocationId)
        {
            List<KeyValuePair<Series, double>> valuesBySeriesType = new List<KeyValuePair<Series, double>>();

            if (calculationResults != null)
            {
                foreach (DataRow row in calculationResults.Rows)
                {
                    double? tonnesValueGenerated = null;
                    bool presentationValid = false;

                    if ((row["PresentationValid"] ?? DBNull.Value) != DBNull.Value)
                    {
                        presentationValid = (bool)row["PresentationValid"];
                    }

                    if (!presentationValid)
                    {
                        // not a valid row for processing
                        continue;
                    }

                    string locationType = GetLocationTypeForRow(row, locationTypeById);

                    // if can't get location type skip this row
                    if (string.IsNullOrEmpty(locationType))
                    {
                        // skip to next row
                        continue;
                    }

                    string productSize = row["ProductSize"] as String;
                    bool byProductSize = (!string.IsNullOrEmpty(productSize));


                    string tagId = row["CalcId"] as String;

                    // work out if this calc Id is a factor
                    bool isFactor = (tagId != null && tagId.Contains("Factor"));

                    int? materialTypeId = null;

                    if (!row.IsNull("MaterialTypeId"))
                    {
                        materialTypeId = (int)row["MaterialTypeId"];
                    }
                    bool byMaterialTypeId = (materialTypeId != null);
                    string attributeLabel = "Tonnes";
                    int locationId = (int)row["LocationId"];

                    if (excludeLocationId != null && excludeLocationId == locationId)
                    {
                        // skip to the next row
                        continue;
                    }

                    string productSizeLabel = null;
                    string materialTypeLabel = null;

                    if (byMaterialTypeId && byProductSize)
                    {
                        productSizeLabel = (byProductSize) ? ", Product Size" : string.Empty;
                        materialTypeLabel = " and Material Type";
                    }
                    else
                    {
                        productSizeLabel = (byProductSize) ? " and Product Size" : string.Empty;
                        materialTypeLabel = (byMaterialTypeId) ? " and Material Type" : string.Empty;
                    }

                    // first extract tonnes data
                    string seriesTypeKey = BuildSeriesTypeKey(tagId, byProductSize, attributeLabel, byMaterialTypeId);
                    SeriesType seriesType = null;

                    // try to get the series type
                    if (!seriesTypeById.TryGetValue(seriesTypeKey, out seriesType))
                    {
                        if (DiscoverSeriesTypes)
                        {
                            discoveredSeriesTypeById.TryGetValue(seriesTypeKey, out seriesType);
                        }
                    }

                    if (seriesType == null && DiscoverSeriesTypes)
                    {
                        // if no such series type exists yet.. create a new one
                        seriesType = new SeriesType()
                        {
                            Attributes = new List<IAttribute>()
                             {
                                 new Attribute<Boolean>() { Name = "ByProductSize", Value=byProductSize },
                                 new Attribute<Boolean>() { Name = "ByMaterialType", Value=byMaterialTypeId },
                                 new Attribute<Boolean>() { Name = "ByGrade", Value=false},
                                 new Attribute<string>() {Name ="CalculationId", Value = tagId },
                                 new Attribute<string>() {Name ="Attribute", Value = attributeLabel}
                             },
                            Id = seriesTypeKey,
                            Name = string.Format("{0} {1} by location{2}{3}", tagId, attributeLabel, productSizeLabel, materialTypeLabel),
                            IsActive = true,
                            IsDependant = false
                        };

                        discoveredSeriesTypeById.Add(seriesTypeKey, seriesType);
                    }

                    if (seriesType != null && seriesType.Attributes != null && locationType != null)
                    {
                        // make sure the location type associated with the series type is appropriate for the data row
                        string locationTypeUpper = locationType.ToUpper();
                        string locationTypeOfSeriesType = AttributeHelper.GetStringValueOrDefault(seriesType.Attributes, "LocationType", string.Empty).ToUpper();
                        int indexOfLocationTypeInHierarchy = _locationTypeHierarchy.IndexOf(locationTypeUpper);
                        
                        if (!(
                            locationTypeOfSeriesType == locationType // exact match
                            || (locationTypeOfSeriesType == "PIT AND ABOVE" && indexOfLocationTypeInHierarchy  >= 0)
                            || (locationTypeOfSeriesType == "SITE AND ABOVE" && indexOfLocationTypeInHierarchy >= 1)
                            || (locationTypeOfSeriesType == "HUB AND ABOVE" && indexOfLocationTypeInHierarchy >= 2)
                            ))
                        {
                            // the location type of the data row is not appropriate for the location type of the series type
                            // skip this row altogether.. this prevents such results as generating an MPEE series for each Pit for example (this only occurs where the report logic for some reason spits out results an unexpected levels of the location hierarchy)
                            continue;
                        }

                    }

                    if (seriesType != null)
                    {
                        string seriesKey = BuildSeriesKey(locationType, tagId, byProductSize, attributeLabel, productSize, locationId, byMaterialTypeId, materialTypeId);

                        if (!string.IsNullOrEmpty(seriesKey))
                        {
                            double? value = GetValueForSeriesRowAndTonnes(row);

                            // store the result if there is a value and 
                            //  the value is non-zero ; or
                            //  the value is not for a factor regardless of whether it is zero or not
                            if (value != null && (value != 0 || !isFactor))
                            {
                                Series series = new Series()
                                {
                                    SeriesTypeId = seriesType.Id,
                                    SeriesKey = seriesKey,
                                    Attributes = new List<IAttribute>()
                                        {
                                            new Attribute<int>() { Name = "LocationId", Value =  locationId},
                                            new Attribute<string>() { Name = "LocationType", Value =  locationType}
                                        }
                                };

                                if (byProductSize)
                                {
                                    series.Attributes.Add(new Attribute<string>() { Name = "ProductSize", Value = productSize });
                                }

                                if (byMaterialTypeId && materialTypeId != null)
                                {
                                    series.Attributes.Add(new Attribute<int>() { Name = "MaterialTypeId", Value = materialTypeId.Value });
                                }

                                valuesBySeriesType.Add(new KeyValuePair<Series, double>(series, value.Value));
                                tonnesValueGenerated = value.Value;
                            }
                        }
                    }

                    // only store grades where Tonnes is non-zero
                    if ((tonnesValueGenerated ?? 0) != 0)
                    {
                        // then extract grade data
                        foreach (string grade in gradeList)
                        {
                            bool generalGradeSeries = false;

                            attributeLabel = grade;
                            seriesTypeKey = BuildSeriesTypeKey(tagId, byProductSize, attributeLabel, byMaterialTypeId);
                            seriesType = null;

                            if (!seriesTypeById.TryGetValue(seriesTypeKey, out seriesType))
                            {
                                if (DiscoverSeriesTypes)
                                {
                                    discoveredSeriesTypeById.TryGetValue(seriesTypeKey, out seriesType);
                                }
                                if (seriesType == null)
                                {
                                    if (!DataRetrieverCommon.gradesExpectedToHaveDedicatedSeries.Contains(grade))
                                    {
                                        generalGradeSeries = true;
                                        attributeLabel = "Grade";
                                        // no match.. try with a general grade key  (some grades, like Fe are expected to have their own series types)
                                        seriesTypeKey = BuildSeriesTypeKey(tagId, byProductSize, attributeLabel, byMaterialTypeId);
                                        if (!seriesTypeById.TryGetValue(seriesTypeKey, out seriesType))
                                        {
                                            if (DiscoverSeriesTypes)
                                            {
                                                discoveredSeriesTypeById.TryGetValue(seriesTypeKey, out seriesType);
                                            }
                                        }
                                    }
                                }
                            }

                            if (seriesType == null && DiscoverSeriesTypes)
                            {
                                // if no such series type
                                seriesType = new SeriesType()
                                {
                                    Attributes = new List<IAttribute>()
                                {
                                    new Attribute<bool>() { Name = "ByProductSize", Value=byProductSize },
                                    new Attribute<bool>() { Name = "ByMaterialType", Value=byMaterialTypeId },
                                    new Attribute<bool>() { Name = "ByGrade", Value=generalGradeSeries },
                                    new Attribute<string>() {Name ="CalculationId", Value = tagId },
                                    new Attribute<string>() {Name ="Attribute", Value = attributeLabel}
                                },
                                    Id = seriesTypeKey,
                                    Name = string.Format("{0} {1} by location{2}{3}", tagId, attributeLabel, productSizeLabel, materialTypeLabel),
                                    IsActive = true,
                                    IsDependant = false
                                };

                                if (!generalGradeSeries)
                                {
                                    seriesType.Attributes.Add(new Attribute<string>() { Name = "Grade", Value = grade });
                                }

                                discoveredSeriesTypeById.Add(seriesTypeKey, seriesType);
                            }

                            if (seriesType != null)
                            {
                                string seriesKey = BuildSeriesKey(locationType, tagId, byProductSize, grade, productSize, locationId, byMaterialTypeId, materialTypeId);

                                if (!string.IsNullOrEmpty(seriesKey))
                                {
                                    double? value = GetValueForSeriesRowAndGrade(row, grade);

                                    if (value != null)
                                    {
                                        // Density values must be uninverted before storage
                                        // Even Density factor values must be uninverted (for the reason why refer to the comments on method F1F2F3ReportEngine.InvertDensityForDisplay)
                                        if (value != 0 && grade.ToUpper() == "DENSITY")
                                        {
                                            // uninvert the value
                                            value = 1 / value;
                                        }

                                        Series series = new Series()
                                        {
                                            SeriesTypeId = seriesType.Id,
                                            SeriesKey = seriesKey,
                                            Attributes = new List<IAttribute>()
                                            {
                                                new Attribute<int>() { Name = "LocationId", Value =  locationId},
                                                new Attribute<string>() { Name="LocationType", Value =locationType },
                                                new Attribute<string>() { Name = "Grade", Value =  grade}
                                            }
                                        };

                                        if (byProductSize)
                                        {
                                            series.Attributes.Add(new Attribute<string>() { Name = "ProductSize", Value = productSize });
                                        }
                                        if (byMaterialTypeId && materialTypeId != null)
                                        {
                                            series.Attributes.Add(new Attribute<int>() { Name = "MaterialTypeId", Value = materialTypeId.Value });
                                        }

                                        valuesBySeriesType.Add(new KeyValuePair<Series, double>(series, value.Value));
                                    }
                                }
                            }
                        }
                    }
                }
            }

            return valuesBySeriesType;
        }

        /// <summary>
        /// Build a key representing a series type
        /// </summary>
        /// <param name="tagId">the calculation identifier</param>
        /// <param name="byProductSize">boolean indicating whether this series type breaks down by Product Type or not</param>
        /// <param name="attributeLabel">A label for the attribute (Tonnes, Grade etc)</param>
        /// <param name="byMaterialType">If true, by material type</param>
        /// <returns>A key representing the type of series</returns>
        private string BuildSeriesTypeKey(string tagId, bool byProductSize, string attributeLabel, bool byMaterialType)
        {
            return string.Format("{0}_{1}{2}{3}", tagId, attributeLabel, (byProductSize)?"_PS":string.Empty, (byMaterialType) ? "_MT" : string.Empty);
        }

        /// <summary>
        /// Build a key representing a specific series
        /// </summary>
        /// <param name="locationType">the type of location</param>
        /// <param name="tagId">the calculation identifier</param>
        /// <param name="byProductSize">boolean indicating whether this series type breaks down by Product Type or not</param>
        /// <param name="attributeLabel">A label for the attribute (Tonnes, Grade etc)</param>
        /// <param name="productSize">The product size this series is related to</param>
        /// <param name="locationId">The product size this series is related to</param>
        /// <returns>string representing the series key</returns>
        private string BuildSeriesKey(string locationType, string tagId, bool byProductSize, string attributeLabel, string productSize, int locationId, bool byMaterialType, int? materialTypeId)
        {
            return string.Format("{0}_{1}_{2}{3}{4}{5}{6}_{7}", locationType, tagId, attributeLabel, (byProductSize) ? "_PS" : string.Empty, (byMaterialType) ? "_MT" : string.Empty, (byProductSize)? string.Concat("_", productSize):string.Empty, (byMaterialType) ? string.Concat("_", materialTypeId.Value.ToString()) : string.Empty, locationId);
        }

        /// <summary>
        /// Determine the location type for each row by dictionary lookup
        /// </summary>
        /// <param name="row">the row used for the lookup</param>
        /// <param name="locationTypeById">a dictionary of location types by Id</param>
        /// <returns>string represenation of location type</returns>
        private string GetLocationTypeForRow(DataRow row, Dictionary<int, string> locationTypeById)
        {
            string locationType = null;

            if ((row["LocationId"] ?? DBNull.Value) != DBNull.Value)
            {
                int locationTypeId = (int)row["LocationId"];

                locationTypeById.TryGetValue(locationTypeId, out locationType);
            }

            return locationType;
        }

        /// <summary>
        /// Get a tonnes value from a calculation row
        /// </summary>
        /// <param name="row">row to extract tonnes data from</param>
        /// <returns>tonnes value</returns>
        private double? GetValueForSeriesRowAndTonnes(DataRow row)
        {
            double? value = null;

            if (row != null && (row["Tonnes"] ?? DBNull.Value) != DBNull.Value)
            {
                value = (double)row["Tonnes"];
            }

            return value;
        }

        /// <summary>
        /// Get a grade value from a calculation row for a given grade record
        /// </summary>
        /// <param name="row">row to extract data from</param>
        /// <param name="gradeName">grade specifying which data to extract</param>
        /// <returns>value for a grade</returns>
        private double? GetValueForSeriesRowAndGrade(DataRow row, string gradeName)
        {
            double? value = null;

            if (row != null && (row[gradeName] ?? DBNull.Value) != DBNull.Value)
            {
                value = (double)row[gradeName];
            }

            return value;
        }
        
    }
}
