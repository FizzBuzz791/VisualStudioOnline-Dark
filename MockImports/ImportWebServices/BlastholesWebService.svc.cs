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
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "BlastholesWebService" in code, svc and config file together.
    public class BlastholesWebService : IM_Blastholes_DS
    {
        public string ConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["MockDatabase"].ConnectionString;
            }
        }

        #region IM_Blastholes_DS Members

        public retrieveReconciliationBlocksResponse1 retrieveReconciliationBlocks(retrieveReconciliationBlocksRequest1 request)
        {
            var response = new retrieveReconciliationBlocksResponse1();
            var connection = new SqlDalBlock(ConnectionString);
            try
            {
                var ds = connection.RetrieveReconciliationBlocks(
                    request.RetrieveReconciliationBlocksRequest.StartDate, request.RetrieveReconciliationBlocksRequest.EndDate);

                response.RetrieveReconciliationBlocksResponse = new RetrieveReconciliationBlocksResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveReconciliationBlocksResponse = new RetrieveReconciliationBlocksResponse();
                response.RetrieveReconciliationBlocksResponse.Status.StatusFlag = false;
                response.RetrieveReconciliationBlocksResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveReconciliationDeletedBlocksResponse1 retrieveReconciliationDeletedBlocks(retrieveReconciliationDeletedBlocksRequest1 request)
        {
            var response = new retrieveReconciliationDeletedBlocksResponse1();
            var connection = new SqlDalBlock(ConnectionString);
            try
            {
                var ds = connection.RetrieveReconciliationDeletedBlocks(
                    request.RetrieveReconciliationDeletedBlocksRequest.StartDate, request.RetrieveReconciliationDeletedBlocksRequest.EndDate);

                response.RetrieveReconciliationDeletedBlocksResponse = new RetrieveReconciliationDeletedBlocksResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveReconciliationDeletedBlocksResponse = new RetrieveReconciliationDeletedBlocksResponse();
                response.RetrieveReconciliationDeletedBlocksResponse.Status.StatusFlag = false;
                response.RetrieveReconciliationDeletedBlocksResponse.Status.StatusMessage = e.Message;
                return response;
            }
            finally
            {
                connection.Dispose();
            }
        }

        public retrieveReconciliationMovementsResponse1 retrieveReconciliationMovements(retrieveReconciliationMovementsRequest1 request)
        {
            var response = new retrieveReconciliationMovementsResponse1();
            var connection = new SqlDalBlock(ConnectionString);
            try
            {
                var ds = connection.RetrieveReconciliationMovements(
                    request.RetrieveReconciliationMovementsRequest.StartDate, request.RetrieveReconciliationMovementsRequest.EndDate);

                response.RetrieveReconciliationMovementsResponse = new RetrieveReconciliationMovementsResponse(ds);

                return response;
            }
            catch (Exception e)
            {
                response.RetrieveReconciliationMovementsResponse = new RetrieveReconciliationMovementsResponse();
                response.RetrieveReconciliationMovementsResponse.Status.StatusFlag = false;
                response.RetrieveReconciliationMovementsResponse.Status.StatusMessage = e.Message;
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
