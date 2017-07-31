using Snowden.Consulting.DataSeries.Processing;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Snowden.Consulting.DataSeries.DataAccess.DataTypes;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using System.Data;
using System.ComponentModel;
using System.Threading;

namespace Snowden.Reconcilor.Bhpbio.DataSeries
{
    /// <summary>
    /// Retriever used to obtain Ore vs Non Ore ratios
    /// </summary>
    public class HaulageToOreVsNonOreDataRetriever : IPointRetriever
    {
        #region Private Types

        /// <summary>
        /// Defines a set of work for the retriever
        /// </summary>
        private class WorkDefinition
        {
            public int LocationId { get; set; }

            public DataTable ResultDataTable { get; set; }


            public List<KeyValuePair<Series, double>> ResultSeriesPoints { get; set; }

            public AutoResetEvent DoneEvent { get; private set; } 

            public Exception Error { get; set; }

            public WorkDefinition()
            {
                DoneEvent = new AutoResetEvent(false);
            }
        }

        #endregion

        /// <summary>
        /// Connection string used by this data retriever
        /// </summary>
        private string _connectionString = null;

        

        /// <summary>
        /// Get Points for the specified series types and ordinal
        /// </summary>
        /// <param name="seriesTypes">the set of series types</param>
        /// <param name="ordinal">the ordinal value (time or other sequential reference) to obtain points for</param>
        /// <returns>A structure containing the point for each series</returns>
        public List<KeyValuePair<Series, double>> GetPoints(Dictionary<string, SeriesType> seriesTypesById, long ordinal)
        {
            if (_connectionString == null)
            {
                _connectionString = DataRetrieverCommon.ObtainConnectionStringFromConfiguration();
            }

            DateTime month = DataRetrieverCommon.GetMonthForOrdinal(ordinal);

            SqlDalUtility utilityDal = new SqlDalUtility(_connectionString);

            List<KeyValuePair<Series, double>> results = new List<KeyValuePair<Series, double>>();

            // get site location Ids
            int topLevelLocationId = utilityDal.GetBhpbioLocationRoot();
            // get the Id of the Hubs
            var hubDataTable = utilityDal.GetBhpbioLocationChildrenNameWithOverride(topLevelLocationId, month, month);
            List<int> hubLocationIds = DataRetrieverCommon.ExtractLocationIdsFromDataTable(hubDataTable,"Location_Id");
            List<int> siteLocationIds = new List<int>();

            // get the Id of the sites of each hub
            foreach (int hubLocationId in hubLocationIds)
            {
                var siteDataTable = utilityDal.GetBhpbioLocationChildrenNameWithOverride(hubLocationId, month, month);
                var newIds = DataRetrieverCommon.ExtractLocationIdsFromDataTable(siteDataTable, "Location_Id");
                if (newIds != null && newIds.Count > 0)
                {
                    siteLocationIds.AddRange(newIds);
                }
            }

            List<WorkDefinition> workDefinitions = new List<WorkDefinition>();
            
            string seriesTypeKey = "HaulageToOreVsNonOre_Tonnes";
            SeriesType seriesType = null;

            if (seriesTypesById.TryGetValue(seriesTypeKey, out seriesType))
            {
                List<BackgroundWorker> workers = new List<BackgroundWorker>();
                foreach (int siteId in siteLocationIds)
                {
                    WorkDefinition definition = new WorkDefinition() { LocationId = siteId };
                    workDefinitions.Add(definition);
                }

                // do the work using background workers
                foreach (var workDefinition in workDefinitions)
                {
                    BackgroundWorker worker = new BackgroundWorker();

                    DoWorkEventHandler workFunction = (o, e) =>
                    {
                        // each worker must use it's own DAL
                        using (SqlDalApproval approvalDALForWorker = new SqlDalApproval(_connectionString))
                        {
                            // do the actual work and store the results in the work definition
                            workDefinition.ResultDataTable = approvalDALForWorker.GetBhpbioApprovalOtherMaterial(workDefinition.LocationId, month, true);
                            workDefinition.ResultSeriesPoints = ProcessSiteResultTable(workDefinition.ResultDataTable, seriesType);
                        }
                    };

                    // start work using the background worker
                    worker.DoWork += workFunction;
                    workers.Add(worker);
                    worker.RunWorkerCompleted += (o, e) =>
                    {
                        workDefinition.Error = e.Error;
                        // mark the work as done regardless of success fail
                        workDefinition.DoneEvent.Set();
                    };
                    worker.RunWorkerAsync();
                }

                // wait for all workers to complete
                foreach (var workDefinition in workDefinitions)
                {
                    bool done = workDefinition.DoneEvent.WaitOne(DataRetrieverCommon.ThreadWaitTimeout);

                    if (!done)
                    {
                        throw new TimeoutException("Timeout waiting on HaulageToOreVsNonOreDataRetriever worker thread");
                    }
                }

                var failCount = workDefinitions.Count(w => w.Error != null);
                if (failCount > 0)
                {
                    var firstFail = workDefinitions.First(w => w.Error != null);
                    // workers failed
                    throw new ApplicationException(string.Format("Data retrieval failed for one or more locations ({0}). First: {1}", failCount, firstFail.LocationId), firstFail.Error);
                }

                // collate results
                foreach (WorkDefinition workDef in workDefinitions)
                {
                    if (workDef.ResultSeriesPoints != null)
                    {
                        results.AddRange(workDef.ResultSeriesPoints);
                    }
                }
            }
            
            return results;
        }

        /// <summary>
        /// Process the datatable results for a single site
        /// </summary>
        /// <param name="summaryTable">table containing results</param>
        /// <param name="seriesType">the series type each result series belongs to</param>
        /// <returns>Points organised by series</returns>
        private List<KeyValuePair<Series, double>>  ProcessSiteResultTable(DataTable summaryTable, SeriesType seriesType)
        {
            List<KeyValuePair<Series, double>> siteResults = new List<KeyValuePair<Series, double>>();

            Dictionary<string, double> totalHaulageBySeriesKey = new Dictionary<string, double>();
            Dictionary<string, double> totalHauledToNonOreBySeriesKey = new Dictionary<string, double>();


            foreach (DataRow row in summaryTable.Rows)
            {
                if ((row["HaulageTotal"] ?? DBNull.Value) != DBNull.Value)
                {
                    double haulageTotal = (double)row["HaulageTotal"];
                    double hauledToNonOreStockpile = (double)row["HauledToNonOreStockpile"];
                    string locationType = row["LocationType"] as string;
                    int locationId = (int)row["LocationId"];
                    string materialName = row["MaterialName"] as string;

                    // build a series key
                    string seriesKey = string.Format("{0}_{1}", seriesType.Id, locationId);
                    if (materialName == "Total Ore")
                    {
                        totalHaulageBySeriesKey[seriesKey] = haulageTotal;
                        totalHauledToNonOreBySeriesKey[seriesKey] = hauledToNonOreStockpile;
                    }
                    else if (materialName == "Total Non-Ore")
                    {
                        double totalHauled = 0;
                        if (totalHaulageBySeriesKey.TryGetValue(seriesKey, out totalHauled))
                        {
                            totalHauled = totalHauled + haulageTotal;
                            double totalToNonOre = totalHauledToNonOreBySeriesKey[seriesKey];
                            totalToNonOre += hauledToNonOreStockpile;

                            double totalToOre = totalHauled - totalToNonOre;

                            if (totalToNonOre > 0)
                            {
                                double ratio = totalToOre / totalToNonOre;

                                Series series = new Series()
                                {
                                    SeriesKey = seriesKey,
                                    SeriesTypeId = seriesType.Id,
                                    Attributes = new List<IAttribute>()
                                            {
                                                new Attribute<string>() { Name="LocationType", Value=locationType },
                                                new Attribute<Int32>() { Name="LocationId", Value=locationId },
                                                new Attribute<string>() {Name="ProductSize", Value=Report.Types.CalculationResult.ProductSizeTotal }
                                            }
                                };

                                siteResults.Add(new KeyValuePair<Series, double>(series, ratio));
                            }
                        }
                    }
                }
            }

            return siteResults;
        }
    }
}
