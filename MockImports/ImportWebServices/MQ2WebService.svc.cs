using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
using MQ2Direct;
using MockImportDAL.SqlDal;
using System.Configuration;

namespace NewService
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "MQ2WebService" in code, svc and config file together.
    public class MQ2WebService : IM_MQ2_DS
    {
        public string ConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["MockDatabase"].ConnectionString;
            }
        }

        #region IM_MQ2_DS Members

        public retrieveHaulageResponse1 retrieveHaulage(retrieveHaulageRequest1 request)
        {
            var response = new retrieveHaulageResponse1();
            var connection = new SqlDalTransaction(ConnectionString);
            try
            {
                var ds = connection.RetrieveHaulage(request.RetrieveHaulageRequest.MineSiteCode,
                    request.RetrieveHaulageRequest.StartDate, request.RetrieveHaulageRequest.EndDate);

                response.RetrieveHaulageResponse = new RetrieveHaulageResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveHaulageResponse = new RetrieveHaulageResponse();
                response.RetrieveHaulageResponse.Status.StatusFlag = false;
                response.RetrieveHaulageResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveProductionMovementsResponse1 retrieveProductionMovements(retrieveProductionMovementsRequest1 request)
        {
            var response = new retrieveProductionMovementsResponse1();
            var connection = new SqlDalTransaction(ConnectionString);
            try
            {
                var ds = connection.RetrieveProductionMovements(request.RetrieveProductionMovementsRequest.MineSiteCode,
                    request.RetrieveProductionMovementsRequest.StartDate, request.RetrieveProductionMovementsRequest.EndDate);

                response.RetrieveProductionMovementsResponse = new RetrieveProductionMovementsResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveProductionMovementsResponse = new RetrieveProductionMovementsResponse();
                response.RetrieveProductionMovementsResponse.Status.StatusFlag = false;
                response.RetrieveProductionMovementsResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveStockpilesResponse1 retrieveStockpiles(retrieveStockpilesRequest1 request)
        {
            var response = new retrieveStockpilesResponse1();
            var connection = new SqlDalStockpile(ConnectionString);
            try
            {
                var ds = connection.RetrieveStockpiles(request.RetrieveStockpilesRequest.MineSiteCode);

                response.RetrieveStockpilesResponse = new RetrieveStockpilesResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveStockpilesResponse = new RetrieveStockpilesResponse();
                response.RetrieveStockpilesResponse.Status.StatusFlag = false;
                response.RetrieveStockpilesResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveStockpileAdjustmentsResponse1 retrieveStockpileAdjustments(retrieveStockpileAdjustmentsRequest1 request)
        {
            var response = new retrieveStockpileAdjustmentsResponse1();
            var connection = new SqlDalStockpileAdjustment(ConnectionString);
            try
            {
                var ds = connection.RetrieveStockpileAdjustments(request.RetrieveStockpileAdjustmentsRequest.MineSiteCode,
                    request.RetrieveStockpileAdjustmentsRequest.StartDate, request.RetrieveStockpileAdjustmentsRequest.EndDate);

                response.RetrieveStockpileAdjustmentsResponse = new RetrieveStockpileAdjustmentsResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveStockpileAdjustmentsResponse = new RetrieveStockpileAdjustmentsResponse();
                response.RetrieveStockpileAdjustmentsResponse.Status.StatusFlag = false;
                response.RetrieveStockpileAdjustmentsResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        #endregion
    }
}
