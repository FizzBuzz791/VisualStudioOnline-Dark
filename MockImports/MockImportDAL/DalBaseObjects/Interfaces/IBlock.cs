using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface IBlock : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrieveReconciliationBlocks(DateTime startDate, DateTime endDate);

        DataSet RetrieveReconciliationDeletedBlocks(DateTime startDate, DateTime endDate);

        DataSet RetrieveReconciliationMovements(DateTime startDate, DateTime endDate);
    }
}
