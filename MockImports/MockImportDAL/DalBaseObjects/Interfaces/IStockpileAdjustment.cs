﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;

namespace MockImportDAL.DalBaseObjects.Interfaces
{
    public interface IStockpileAdjustment : Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal
    {
        DataSet RetrieveStockpileAdjustments(string mineSiteCode, DateTime startDate, DateTime endDate);

        DataSet RetrievePortBalances(DateTime startDate);
    }
}
