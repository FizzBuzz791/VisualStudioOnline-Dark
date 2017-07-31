using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalLocation : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.ILocation
    {
        #region Constructors
        public SqlDalLocation() : base() { }

        public SqlDalLocation(string connectionString) : base(connectionString) { }

        public SqlDalLocation(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalLocation(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
