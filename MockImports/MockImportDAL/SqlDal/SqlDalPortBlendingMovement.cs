using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalPortBlendingMovement : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IPortBlendingMovement
    {
        #region Constructors
        public SqlDalPortBlendingMovement() : base() { }

        public SqlDalPortBlendingMovement(string connectionString) : base(connectionString) { }

        public SqlDalPortBlendingMovement(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalPortBlendingMovement(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrievePortBlending(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetPortBlending";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "PortBlending";
            ds.Tables[1].TableName = "PortBlendingGrade";

            return ds;
        }
    }
}
