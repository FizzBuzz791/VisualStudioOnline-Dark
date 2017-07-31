using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalPoint : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IPoint
    {
        #region Constructors
        public SqlDalPoint() : base() { }

        public SqlDalPoint(string connectionString) : base(connectionString) { }

        public SqlDalPoint(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalPoint(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
