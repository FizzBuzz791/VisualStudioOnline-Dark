using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalStockpile : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IStockpile
    {
        #region Constructors
        public SqlDalStockpile() : base() { }

        public SqlDalStockpile(string connectionString) : base(connectionString) { }

        public SqlDalStockpile(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalStockpile(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveStockpiles(string mineSiteCode)
        {
            DataAccess.CommandText = "dbo.GetStockpiles";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iMineSiteCode", CommandDataType.VarChar, CommandDirection.Input, mineSiteCode);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Stockpiles";

            return ds;
        }
    }
}
