using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface ITransaction : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrieveHaulage(string mineSiteCode, DateTime startDate, DateTime endDate);

        DataSet RetrieveProductionMovements(string mineSiteCode, DateTime startDate, DateTime endDate);
    }
}
