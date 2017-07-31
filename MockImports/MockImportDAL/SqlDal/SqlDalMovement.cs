using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalMovement : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IMovement
    {
        #region Constructors
        public SqlDalMovement() : base() { }

        public SqlDalMovement(string connectionString) : base(connectionString) { }

        public SqlDalMovement(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalMovement(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
