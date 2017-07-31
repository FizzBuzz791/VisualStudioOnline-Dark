using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface IPortBlendingMovement : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrievePortBlending(DateTime startDate, DateTime endDate);
    }
}
