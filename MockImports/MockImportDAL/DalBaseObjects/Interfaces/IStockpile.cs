using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface IStockpile : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrieveStockpiles(string mineSiteCode);
    }
}
