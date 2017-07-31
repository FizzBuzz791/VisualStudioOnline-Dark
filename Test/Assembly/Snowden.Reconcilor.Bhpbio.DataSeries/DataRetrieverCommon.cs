using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;

namespace Snowden.Reconcilor.Bhpbio.DataSeries
{
    /// <summary>
    /// Defines common constants and methods
    /// </summary>
    public static class DataRetrieverCommon
    {
        #region Private Constants

        internal const string _productConfigurationPathSettingName = "ProductConfigurationPath";
        internal const string _productConfigurationDatabaseName = "Main";
        internal const string _productConfigurationDatabaseUser = "ReconcilorImport";

        #endregion

        #region Public Constants

        /// <summary>
        /// Timeout used to stop waiting for worker threads in extreme cases
        /// </summary>
        public const int ThreadWaitTimeout = 900000;  // 900000 = 15 minutes

        #endregion

        /// <summary>
        /// A list of grades expected to have dedicated series
        /// </summary>
        internal static readonly string[] gradesExpectedToHaveDedicatedSeries = new string[] { "Fe" };

        /// <summary>
        /// Get a connection string based on configuration data
        /// </summary>
        /// <returns></returns>
        internal static string ObtainConnectionStringFromConfiguration()
        {
            // get the connection string based on the product config
            string productConfigurationPath = System.Configuration.ConfigurationManager.AppSettings.Get(_productConfigurationPathSettingName);
            var config = new Bcd.ProductConfiguration.ConfigurationManager(productConfigurationPath);
            config.Open();
            return config.GetDatabaseConfiguration(_productConfigurationDatabaseName).GenerateSqlClientConnectionString(_productConfigurationDatabaseUser);
        }

        /// <summary>
        /// Convert the ordinal value to a month
        /// </summary>
        /// <param name="ordinal">ordinal value representing the time</param>
        /// <returns>the calculated DateTime</returns>
        internal static DateTime GetMonthForOrdinal(long ordinal)
        {
            return new DateTime(2009, 04, 01).AddMonths((int)ordinal - 1);
        }

        /// <summary>
        /// Extract a set of location Ids from a datatable
        /// </summary>
        /// <param name="dataTable">The datatable to extract frm</param>
        /// <param name="locationIdColumn">name of the location Id column</param>
        /// <returns>List of identifiers</returns>
        internal static List<int> ExtractLocationIdsFromDataTable(DataTable dataTable, string locationIdColumn)
        {
            List<int> ids = new List<int>();

            if (dataTable != null)
            {
                foreach (DataRow row in dataTable.Rows)
                {
                    ids.Add((int)row[locationIdColumn]);
                }
            }
            return ids;
        }
    }
}
