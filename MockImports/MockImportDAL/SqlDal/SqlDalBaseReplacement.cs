using Snowden.Common.Database.DataAccessBaseObjects;
using Snowden.Common.Database.SqlDataAccessBaseObjects;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;

namespace MockImportDAL
{
    public abstract class SqlDalBaseReplacement : DataAccessLayerBase<SqlDataAccess>, IDisposable, ISqlDal
    {

        private SqlDataAccess _dataAccess = new SqlDataAccess();
        private bool _disposed = false;

        protected SqlDalBaseReplacement()
        {

        }

        

        protected SqlDalBaseReplacement(string connectionString)
        {
            DataAccess.ConnectionString = connectionString;
        }
        protected SqlDalBaseReplacement(IDbConnection databaseConnection)
        {
            DataAccess.DatabaseConnection= databaseConnection;
        }
        protected SqlDalBaseReplacement(IDataAccessConnection dataAccessConnection)
        {
            DataAccess.DataAccessConnection = dataAccessConnection;
        }

        public override SqlDataAccess DataAccess
        {
            get
            {
                return _dataAccess;
            }
        }

        SqlDataAccess ISqlDal.DataAccess
        {
            get
            {
                return DataAccess;
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed) {
                if (disposing) {
                    //Clean up managed Resources ie: Objects
                    if (_dataAccess != null) {
                        _dataAccess.Dispose();
                        _dataAccess = null;
                    }
                }

                //Clean up unmanaged resources ie: Pointers & Handles				
            }
            _disposed = true;
        }

        void ISqlDal.Dispose()
        {
            Dispose();
        }

        void ISqlDal.Dispose(bool disposing)
        {
            Dispose(disposing);
        }
    }
}
