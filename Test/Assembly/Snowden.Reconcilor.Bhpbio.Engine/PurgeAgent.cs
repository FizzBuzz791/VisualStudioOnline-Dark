using System;
using System.Data;
using System.Globalization;
using System.Linq;
using Snowden.Common.Database.DataAccessBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.Dtos;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;
using Snowden.Reconcilor.Core.Database.SqlDal;
using Snowden.Reconcilor.Core.Database.DalBaseObjects;
using System.Text;

namespace Snowden.Reconcilor.Bhpbio.Engine
{
    public class PurgeAgent : Snowden.Common.Engine.Agent
    {
        protected internal static class Keys
        {
            public const string DatabaseKey = "DatabaseKey";
            public const string DatabaseUser = "DatabaseUser";
            public const string TimeFrom = "TimeFrom";
            public const string TimeTo = "TimeTo";
            public const string PollingInterval = "PollingIntervalMinutes";
        }

        private TimeSpan GetPollingInterval()
        {
            const string key = Keys.PollingInterval;
            if (!ConfigurationSettings.ContainsKey(key))
            {
                const string format = "The Polling configuration setting ({0}) is missing from the configuration.";
                throw new InvalidOperationException(string.Format(format, key));
            }
            
            var value = ConfigurationSettings[key];
            int result;
            if (string.IsNullOrEmpty(value) || !int.TryParse(value, out result))
            {
                const string format = "The Polling configuration setting ({0}) value ({1}) must be a numeric integer.";
                throw new InvalidOperationException(string.Format(format, key, value));
            }

            // time unit is minutes
            return new TimeSpan(0, result, 0);
        }

        protected override void Execute()
        {
            PurgeAuditor purgeAuditor = null;

            try
            {
                // obtain an auditor for logging
                purgeAuditor = new PurgeAuditor(GetAuditor());

                purgeAuditor.TryAddAuditEntry("Purge Agent Started", "The Purge Agent has started", string.Empty);

                var pollingInterval = GetPollingInterval();
                while (!this.StopRequested)
                {
                    var timeFrom = GetTimeFrom();
                    var timeTo = GetTimeTo();
                    var timestamp = DateTime.Now;
                    if (timeTo < timeFrom)
                    {
                        timeTo.AddDays(1);
                    }

                    if (timestamp >= timeFrom && timestamp <= timeTo)
                    {
                        // get a new auditor for the purge process itself
                        using(var auditor = new PurgeAuditor(GetAuditor()))
                        {
                            // perform the purge
                            Purge(auditor);
                        }
                    }
                    Sleep(pollingInterval);
                }
            }
            catch (Exception ex)
            {
                // log the fact that the purge agent has failed
                StringBuilder errorMessage = new StringBuilder();
                errorMessage.Append(string.Format("Error: {0}, Stacktrace: {1}", ex.Message, ex.StackTrace));

                // log the fact that the agent is stopping
                purgeAuditor.TryAddAuditEntry("Purge Agent Error", "An error has occured", errorMessage.ToString());
                
                // rethrow the exception
                throw;
            }
            finally
            {
                // dispose of the auditor
                if (purgeAuditor != null)
                {
                    // log the fact that the agent is stopping
                    purgeAuditor.TryAddAuditEntry("Purge Agent Stopped", "The Purge Agent has stopped", string.Empty);

                    purgeAuditor.Dispose();
                }
            }
        }

        /// <summary>
        /// Gets the connection string.
        /// </summary>
        /// <returns></returns>
        private string GetConnectionString()
        {
            return GetConnectionString(Keys.DatabaseKey, Keys.DatabaseUser);
        }

        private IPurge GetDal()
        {
            return new SqlDalPurge(GetConnectionString());
        }

        /// <summary>
        /// Gets the auditor.
        /// </summary>
        /// <returns></returns>
        private Core.Database.DalBaseObjects.IEvent GetAuditor()
        {
            return new Core.Database.SqlDal.SqlDalEvent(GetConnectionString());
        }

        /// <summary>
        /// Begins the purging process
        /// </summary>
        /// <param name="auditor">The auditor.</param>
        private void Purge(PurgeAuditor auditor)
        {
            try
            {
                var dal = GetDal();
                var requests = (from o in dal.GetPurgeRequests(false, true, true)
                        orderby o.Month descending , o.Id descending
                        select o).ToList();

                var primaryRequest = requests.FirstOrDefault();
                if (primaryRequest == null)
                {
                    return;
                }
                var cancelledRequests = requests.Skip(1).Select(o => o.Id).ToList();
                try
                {
                    // prepare record state
                    dal.UpdatePurgeRequests(new[] {primaryRequest.Id}, PurgeRequestState.Initiated, null);
                    
                    auditor.TryAddAuditEntry(PurgeAuditor.PurgeState.Initiated, "Request Initiated",
                        string.Format("Purge request {0} completed at {1}", primaryRequest.Id, DateTime.Now));

                    if (cancelledRequests.Count() != 0)
                    {
                        // cancel all other requests which are prior to the primary request
                        // the primary request will cover these cancelled requests
                        dal.UpdatePurgeRequests(cancelledRequests, PurgeRequestState.Cancelled, null);
                        
                        auditor.TryAddAuditEntry(PurgeAuditor.PurgeState.Cancelled, "Request Cancelled",
                            string.Format("Purge request{0} {1} cancelled at {2}", cancelledRequests.Count() == 1 ? "" : "s",
                            string.Join(",", cancelledRequests.Select(o => o.ToString()).ToArray()), DateTime.Now));
                    }
                    // archive
                    dal.PurgeData(primaryRequest.Id);
                    // change record state to completed to signify success
                    dal.UpdatePurgeRequests(new[] {primaryRequest.Id}, PurgeRequestState.Completed, null);
                    // audit state change
                    auditor.TryAddAuditEntry(PurgeAuditor.PurgeState.Completed, "Request Completed",
                        string.Format("Purge request {0} completed at {1}", primaryRequest.Id, DateTime.Now));

                   



                }
                catch (Exception)
                {
                    // change record state to failure
                    dal.UpdatePurgeRequests(new[] { primaryRequest.Id }, PurgeRequestState.Failed, null);
                    auditor.TryAddAuditEntry(PurgeAuditor.PurgeState.Failed, "Request Failed",
                        string.Format("Purge request {0} failed at {1}", primaryRequest.Id, DateTime.Now));
                    throw;
                }
            }
            catch (Exception ex)
            {
                if (auditor.TryAddAuditEntry(PurgeAuditor.PurgeState.Failed,"Purge request encountered catastrophic error",ex.StackTrace))
                {
                    throw;
                }
            }
        }
        

        /// <summary>
        /// Gets the time from.
        /// </summary>
        /// <returns></returns>
        private DateTime GetTimeFrom()
        {
           return GetDateTime(Keys.TimeFrom); 
        }

        private DateTime GetTimeTo()
        {
            return GetDateTime(Keys.TimeTo);
        }


        /// <summary>
        /// Gets the date time.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <returns></returns>
        private DateTime GetDateTime(string key)
        {
            if (!ConfigurationSettings.ContainsKey(key))
            {
                const string format = "The Configuration setting ({0}) is missing from the configuration.";
                throw new InvalidOperationException(string.Format(format, key));
            }
            var value = ConfigurationSettings[key];
            var result = ParseDateTime(value);
            if (result == null)
            {
                const string format = "The Configuration setting ({0}) value ({1}) must be in the 24-hour format like 13:00";
                throw new InvalidOperationException(string.Format(format, key, value));
            }
            return result.Value;
        }

        /// <summary>
        /// Parses the date time.
        /// </summary>
        /// <param name="text">The text.</param>
        /// <returns></returns>
        private static DateTime? ParseDateTime(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return null;
            }
            var info = CultureInfo.GetCultureInfo("en-au");
            DateTime result;
            // by taking only the hour, it grabs the current day as well
            if (DateTime.TryParseExact(text, "HH:mm", info, DateTimeStyles.None, out result))
            {
                return result;
            }
            return null;
        }

        internal sealed class PurgeAuditor : IDisposable
        {
            public enum PurgeState
            {
                Initiated,
                Completed,
                Failed,
                Requested,
                Approved,
                Cancelled,
                Obsolete
            }
            
            public PurgeAuditor(Core.Database.DalBaseObjects.IEvent auditor)
            {
                this.BaseAuditor = auditor;
                if (auditor != null)
                {
                    var p = from o in auditor.GetAuditTypeList(NullValues.Int32).AsEnumerable()
                            where o.Field<string>("Audit_Type_Group_Name") == "Purge"
                            select o.Field<int>("Audit_Type_Group_Id");
                    this.PurgeAuditTypeGroupId = p.FirstOrDefault();
                }

            }
            public Core.Database.DalBaseObjects.IEvent BaseAuditor { get; private set; }
            public int PurgeAuditTypeGroupId { get; private set; }
            public bool TryAddAuditEntry(PurgeState state,string description, string details)
            {
                return this.TryAddAuditEntry("Purge " + state, description, details);
            }

            public bool TryAddAuditEntry(string key, string description, string details)
            {
                if (this.PurgeAuditTypeGroupId > 0 && this.BaseAuditor != null && this.BaseAuditor.DataAccess.DataAccessConnection.Connection.State == ConnectionState.Open)
                {
                    this.BaseAuditor.AddAuditHistory(key, this.PurgeAuditTypeGroupId, description, "", details, NullValues.Int32, 1, "127.0.0.1", "localhost");
                    return true;
                }
                return false;
            }
            


            public void Dispose()
            {
                if (this.BaseAuditor != null)
                {
                    this.BaseAuditor.Dispose();
                    this.BaseAuditor = null;
                    this.PurgeAuditTypeGroupId = 0;
                }
            }
        }
    }
}
