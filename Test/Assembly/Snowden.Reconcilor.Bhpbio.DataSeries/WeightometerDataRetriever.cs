using Snowden.Consulting.DataSeries.Processing;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Snowden.Consulting.DataSeries.DataAccess.DataTypes;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using System.Data;

namespace Snowden.Reconcilor.Bhpbio.DataSeries
{
    /// <summary>
    /// Data retriever for weightometer data
    /// </summary>
    public class WeightometerDataRetriever : IPointRetriever
    {
        /// <summary>
        /// Connection string used by this data retriever
        /// </summary>
        private string _connectionString = null;

        public List<KeyValuePair<Series, double>> GetPoints(Dictionary<string, SeriesType> seriesTypesById, long ordinal)
        {
            if (_connectionString == null)
            {
                _connectionString = DataRetrieverCommon.ObtainConnectionStringFromConfiguration();
            }

            DateTime month = DataRetrieverCommon.GetMonthForOrdinal(ordinal);

            IReport reportDAL = new SqlDalReport(_connectionString);

            List<KeyValuePair<Series, double>> results = new List<KeyValuePair<Series, double>>();

            // Get a datatable containing a summary by weightometer and month
            var summaryTable = reportDAL.GetBhpbioWeightometerMovementSummaryForMonth(month);

            if (summaryTable != null)
            {
                foreach (DataRow row in summaryTable.Rows)
                {
                    string productSize = row["ProductSize"] as String;
                    int locationId = (int)row["LocationId"];
                    string locationType = row["LocationType"] as string;
                    string weightometerId = row["WeightometerId"] as string;
                    string attribute = row["Attribute"] as string;

                    if ((row["Value"] ?? DBNull.Value) != DBNull.Value)
                    {
                        double value = (double)row["Value"];

                        string seriesKeyAttributeComponent = null;
                        string seriesKeySuffix = null;

                        // there is enough data to generate a point
                        if (attribute == "Tonnes")
                        {
                            // tonnes
                            seriesKeyAttributeComponent = "Tonnes";
                        }
                        else if (DataRetrieverCommon.gradesExpectedToHaveDedicatedSeries.Contains(attribute))
                        {
                            // a specific grade
                            seriesKeyAttributeComponent = attribute;
                        }
                        else
                        {
                            // a grade
                            seriesKeyAttributeComponent = "Grade";
                            seriesKeySuffix = string.Format("_{0}", attribute);
                        }

                        string seriesTypeKey = string.Format("Weightometer_{0}_PS", seriesKeyAttributeComponent);
                        string seriesKey = string.Format("{0}_{1}{2}", seriesTypeKey, weightometerId, seriesKeySuffix);

                        // make sure this is a series being output
                        SeriesType seriesType = null;

                        if (seriesTypesById.TryGetValue(seriesTypeKey, out seriesType))
                        {
                            Series series = new Series()
                            {
                                SeriesKey = seriesKey,
                                SeriesTypeId = seriesType.Id,
                                Attributes = new List<IAttribute>()
                                {
                                    new Attribute<String>() { Name="WeightometerId", Value=weightometerId },
                                    new Attribute<String>() { Name="LocationType", Value=locationType },
                                    new Attribute<Int32>() {Name="LocationId", Value=locationId },
                                    new Attribute<string>() {Name="ProductSize", Value=productSize }
                                }
                            };

                            if (seriesKeyAttributeComponent != "Tonnes")
                            {
                                series.Attributes.Add(new Attribute<string>() { Name = "Grade", Value = attribute });
                            }

                            results.Add(new KeyValuePair<Series, double>(series, value));
                        }
                    }
                }
            }
            return results;
        }
    }
}
