using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalTransaction : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.ITransaction
    {
        #region Constructors
        public SqlDalTransaction() : base() { }

        public SqlDalTransaction(string connectionString) : base(connectionString) { }

        public SqlDalTransaction(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalTransaction(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveHaulage(string mineSiteCode, DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetHaulage";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iMineSiteCode", CommandDataType.VarChar, CommandDirection.Input, mineSiteCode);
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Transactions";
            ds.Tables[1].TableName = "Locations";
            ds.Tables[2].TableName = "Grades";

            return ds;
        }

        public DataSet RetrieveProductionMovements(string mineSiteCode, DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetProductionMovements";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iMineSiteCode", CommandDataType.VarChar, CommandDirection.Input, mineSiteCode);
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Transactions";
            ds.Tables[1].TableName = "Grades";

            return ds;
        }
    }
}
