using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface IShipping : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrieveShipping(DateTime startDate, DateTime endDate);
    }
}
