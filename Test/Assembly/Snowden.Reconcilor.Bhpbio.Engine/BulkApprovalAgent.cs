using Snowden.Common.Database.DataAccessBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using System;
using System.Data;
using System.Linq;
using System.Text;

namespace Snowden.Reconcilor.Bhpbio.Engine
{
    public class BulkApprovalAgent : Common.Engine.Agent
    {
        protected internal static class Keys
        {
            public const string DatabaseKey = "DatabaseKey";
            public const string DatabaseUser = "DatabaseUser";
            public const string PollingInterval = "PollingIntervalSeconds";
        }

        protected override void Execute()
        {
            BulkApprovalAuditor auditor = null;
            try
            {
                string connectionString = GetConnectionString(Keys.DatabaseKey, Keys.DatabaseUser);
                auditor = new BulkApprovalAuditor(new Core.Database.SqlDal.SqlDalEvent(connectionString));
                auditor.TryAddAuditEntry("Bulk Approval Agent Started", "The Bulk Approval Agent has started", string.Empty);

                IApproval dal = new SqlDalApproval(connectionString);
                TimeSpan pollingInterval = GetPollingInterval();
                while (!StopRequested)
                {
                    DataTable queuedApprovals = dal.GetBhpbioQueuedBulkApproval();
                    DataRow queuedJob = queuedApprovals.Select().SingleOrDefault();

                    if (queuedJob != null)
                    {
                        //Technically it would be totally fine to just pass the Id to the approval function and let it pull the params itself,
                        //however I want this function independent.
                        dal.StartBhpbioBulkApproval(
                            (int)queuedJob["Id"],
                            (bool)queuedJob["Approval"],
                            (int)queuedJob["UserId"],
                            (int)queuedJob["LocationId"],
                            (DateTime)queuedJob["EarliestMonth"],
                            (DateTime)queuedJob["LatestMonth"],
                            (int)queuedJob["TopLevelLocationTypeId"],
                            (int)queuedJob["LowestLevelLocationTypeId"]);
                    }

                    Sleep(pollingInterval);
                }
            }
            catch(Exception ex)
            {
                StringBuilder errorMessage = new StringBuilder();
                errorMessage.Append(string.Format($"Error: {ex.Message}, Stacktrace: {ex.StackTrace}"));

                // log the fact that the agent is stopping
                auditor?.TryAddAuditEntry("Bulk Approval Agent Error", "An error has occured", errorMessage.ToString());

                // rethrow the exception
                throw;
            }
            finally
            {
                if (auditor != null)
                {
                    // log the fact that the agent is stopping
                    auditor.TryAddAuditEntry("Bulk Approval Agent Stopped", "The Bulk Approval Agent has stopped", string.Empty);

                    auditor.Dispose();
                }
            }
        }

        private TimeSpan GetPollingInterval()
        {
            const string key = Keys.PollingInterval;

            if (!ConfigurationSettings.ContainsKey(key))
            {
                throw new InvalidOperationException(string.Format($"The Polling configuration setting ({key}) is missing from the configuration."));
            }

            string value = ConfigurationSettings[key];
            int result;

            if (string.IsNullOrEmpty(value) || !int.TryParse(value, out result))
            {
                throw new InvalidOperationException(string.Format($"The Polling configuration setting ({key}) value ({value}) must be a numeric integer."));
            }

            // time unit is seconds
            return new TimeSpan(0, 0, result);
        }

        internal sealed class BulkApprovalAuditor : IDisposable
        {
            public enum BulkApprovalState
            {
                Queuing,
                Pending,
                Completed,
                Failed
            }

            public BulkApprovalAuditor(Core.Database.DalBaseObjects.IEvent auditor)
            {
                BaseAuditor = auditor;
                if (auditor != null)
                {
                    EnumerableRowCollection<int> p = auditor.GetAuditTypeList(NullValues.Int32)
                        .AsEnumerable()
                        .Where(o => o.Field<string>("Audit_Type_Group_Name") == "BulkApprove")
                        .Select(o => o.Field<int>("Audit_Type_Group_Id"));
                    BulkApproveTypeGroupId = p.FirstOrDefault();
                }

            }

            public Core.Database.DalBaseObjects.IEvent BaseAuditor { get; private set; }
            public int BulkApproveTypeGroupId { get; private set; }

            public bool TryAddAuditEntry(BulkApprovalState state, string description, string details)
            {
                return TryAddAuditEntry($"BulkApprove {state}", description, details);
            }

            public bool TryAddAuditEntry(string key, string description, string details)
            {
                if (BulkApproveTypeGroupId > 0 && BaseAuditor != null && BaseAuditor.DataAccess.DataAccessConnection.Connection.State == ConnectionState.Open)
                {
                    BaseAuditor.AddAuditHistory(key, BulkApproveTypeGroupId, description, string.Empty, details, NullValues.Int32, 1, "127.0.0.1", "localhost");
                    return true;
                }
                return false;
            }

            public void Dispose()
            {
                if (BaseAuditor != null)
                {
                    BaseAuditor.Dispose();
                    BaseAuditor = null;
                    BulkApproveTypeGroupId = 0;
                }
            }
        }
    }
}