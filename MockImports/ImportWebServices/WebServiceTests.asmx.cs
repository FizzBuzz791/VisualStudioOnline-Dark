using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;

namespace WebApplication1
{
    /// <summary>
    /// Summary description for WebServiceTests
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    // [System.Web.Script.Services.ScriptService]
    public class WebServiceTests : System.Web.Services.WebService
    {

        [WebMethod]
        public string TestMethod()
        {
            var svc = new NewService.MQ2WebService();
            var response = svc.retrieveStockpileAdjustments(new MQ2Direct.retrieveStockpileAdjustmentsRequest1(new MQ2Direct.RetrieveStockpileAdjustmentsRequest { MineSiteCode = "18" , StartDate = new DateTime(2013, 07, 01), EndDate = new DateTime(2013, 07, 07) }));
            return response.RetrieveStockpileAdjustmentsResponse.StockpileAdjustment[0].AdjustmentDate.ToString();
            //return response.RetrieveStockpileAdjustmentsResponse.StockpileAdjustment.ToString();
        }
    }
}
