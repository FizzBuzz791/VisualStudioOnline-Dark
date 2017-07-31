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
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "MaterialTrackerWebService" in code, svc and config file together.
    public class MaterialTrackerWebService : IM_MT_DS
    {
        public string ConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["MockDatabase"].ConnectionString;
            }
        }

        #region IM_MT_DS Members

        public retrievePortBalancesResponse1 retrievePortBalances(retrievePortBalancesRequest1 request)
        {
            var response = new retrievePortBalancesResponse1();
            var connection = new SqlDalStockpileAdjustment(ConnectionString);
            try
            {
                var ds = connection.RetrievePortBalances(request.RetrievePortBalancesRequest.StartDate);

                response.RetrievePortBalancesResponse = new RetrievePortBalancesResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrievePortBalancesResponse = new RetrievePortBalancesResponse();
                response.RetrievePortBalancesResponse.Status.StatusFlag = false;
                response.RetrievePortBalancesResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveShippingResponse1 retrieveShipping(retrieveShippingRequest1 request)
        {
            var response = new retrieveShippingResponse1();
            var connection = new SqlDalShipping(ConnectionString);
            try
            {
                var ds = connection.RetrieveShipping(request.RetrieveShippingRequest.StartDate, request.RetrieveShippingRequest.EndDate);

                response.RetrieveShippingResponse = new RetrieveShippingResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveShippingResponse = new RetrieveShippingResponse();
                response.RetrieveShippingResponse.Status.StatusFlag = false;
                response.RetrieveShippingResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveMETBalancingResponse1 retrieveMETBalancing(retrieveMETBalancingRequest1 request)
        {
            var response = new retrieveMETBalancingResponse1();
            var connection = new SqlDalMETBalancing(ConnectionString);
            try
            {
                DateTime start = request.RetrieveMETBalancingRequest.StartDate;
                DateTime end = request.RetrieveMETBalancingRequest.EndDate;


                var ds = connection.RetrieveMETBalancing(start.Date.AddHours(6), end.Date.AddHours(6));

                response.RetrieveMETBalancingResponse = new RetrieveMETBalancingResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveMETBalancingResponse = new RetrieveMETBalancingResponse();
                response.RetrieveMETBalancingResponse.Status.StatusFlag = false;
                response.RetrieveMETBalancingResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrievePortBlendingResponse1 retrievePortBlending(retrievePortBlendingRequest1 request)
        {
            var response = new retrievePortBlendingResponse1();
            var connection = new SqlDalPortBlendingMovement(ConnectionString);
            try
            {
                var ds = connection.RetrievePortBlending(request.RetrievePortBlendingRequest.StartDate,
                    request.RetrievePortBlendingRequest.EndDate);

                response.RetrievePortBlendingResponse = new RetrievePortBlendingResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrievePortBlendingResponse = new RetrievePortBlendingResponse();
                response.RetrievePortBlendingResponse.Status.StatusFlag = false;
                response.RetrievePortBlendingResponse.Status.StatusMessage = e.Message;
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
