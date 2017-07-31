using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalStockpileAdjustment : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IStockpileAdjustment
    {
        #region Constructors
        public SqlDalStockpileAdjustment() : base() { }

        public SqlDalStockpileAdjustment(string connectionString) : base(connectionString) { }

        public SqlDalStockpileAdjustment(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalStockpileAdjustment(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveStockpileAdjustments(string mineSiteCode, DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetStockpileAdjustments";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iMineSiteCode", CommandDataType.VarChar, CommandDirection.Input, mineSiteCode);
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Adjustments";
            ds.Tables[1].TableName = "Grades";

            return ds;
        }

        public DataSet RetrievePortBalances(DateTime startDate)
        {
            DataAccess.CommandText = "dbo.GetPortBalances";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables
            ds.Tables[0].TableName = "PortBalance";
            ds.Tables[1].TableName = "PortBalanceGrade";

            return ds;
        }
    }
}
