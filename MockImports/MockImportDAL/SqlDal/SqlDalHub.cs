using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalHub : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IHub
    {
        #region Constructors
        public SqlDalHub() : base() { }

        public SqlDalHub(string connectionString) : base(connectionString) { }

        public SqlDalHub(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalHub(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
