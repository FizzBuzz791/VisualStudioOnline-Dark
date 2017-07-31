using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;
using Snowden.Common.Database.SqlDataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalGrade : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IGrade
    {
        #region Constructors
        public SqlDalGrade() : base() { }

        public SqlDalGrade(string connectionString) : base(connectionString) { }

        public SqlDalGrade(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalGrade(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }

       

        #endregion
    }
}
