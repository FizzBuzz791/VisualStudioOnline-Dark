using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalMETBalancing : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IMETBalancing
    {
         #region Constructors
        public SqlDalMETBalancing() : base() { }

        public SqlDalMETBalancing(string connectionString) : base(connectionString) { }

        public SqlDalMETBalancing(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalMETBalancing(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveMETBalancing(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetMETBalancing";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "MetBalancing";
            ds.Tables[1].TableName = "MetBalancingGrades";

            return ds;
        }
    }
}
