using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalPattern : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IPattern
    {
         #region Constructors
        public SqlDalPattern() : base() { }

        public SqlDalPattern(string connectionString) : base(connectionString) { }

        public SqlDalPattern(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalPattern(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
   }
}
