using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalPolygon : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IPolygon
    {
        #region Constructors
        public SqlDalPolygon() : base() { }

        public SqlDalPolygon(string connectionString) : base(connectionString) { }

        public SqlDalPolygon(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalPolygon(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
