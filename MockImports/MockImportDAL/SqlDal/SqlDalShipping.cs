using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalShipping : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IShipping
    {
        #region Constructors
        public SqlDalShipping() : base() { }

        public SqlDalShipping(string connectionString) : base(connectionString) { }

        public SqlDalShipping(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalShipping(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveShipping(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetShipping";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "ShippingNomination";
            ds.Tables[1].TableName = "ShippingNominationItemHub";
            ds.Tables[2].TableName = "ShippingNominationItemHubGrade";

            return ds;
        }
    }
}
