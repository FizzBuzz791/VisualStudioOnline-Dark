using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalModel : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IModel
    {
        #region Constructors
        public SqlDalModel() : base() { }

        public SqlDalModel(string connectionString) : base(connectionString) { }

        public SqlDalModel(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalModel(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion
    }
}
