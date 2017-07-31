using System;
using Snowden.Consulting.DataSeries.Processing;
using Snowden.Reconcilor.Bhpbio.Engine.Auditor;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;

namespace Snowden.Reconcilor.Bhpbio.Engine
{
    /// <summary>
    /// Agent used to host the generic Data Series Processing functionality within a Reconcilor environment
    /// </summary>
    /// <remarks>This agent raises queue entries in response to Recalc activity, and also hosts the main controller for Data Series Processing</remarks>
	public class DataSeriesProcessingAgent : Common.Engine.Agent
	{
        /// <summary>
        /// The month that represents ordinal 1
        /// </summary>
        private static readonly DateTime _monthRepresentingOrdinal = new DateTime(2009, 04, 01);

	    private string _agentName = "Data Series Processing Agent";

	    protected internal static class Keys
		{
			public const string DatabaseKey = "DatabaseKey";
			public const string DatabaseUser = "DatabaseUser";
			public const string PollingInterval = "PollingIntervalSeconds";
            public const string RecalcHistoryLookbackMinutes = "RecalcHistoryLookbackMinutes";
            public const string AuditTypeGroupName = "AuditTypeGroupName";
		}

        /// <summary>
        /// DAL used to add queue entries in response to recalc history
        /// </summary>
        private IRecalc DalRecalc { get; set; }

	    public string AgentName
	    {
		    get { return _agentName; }
		    set { _agentName = value; }
	    }

	    /// <summary>
	    /// Enter the main execution loop for the agent
	    /// </summary>
	    protected override void Execute()
		{
			AgentAuditor auditor = null;

			try
			{
                String connectionString = GetConnectionString(Keys.DatabaseKey, Keys.DatabaseUser);

                DalRecalc = new SqlDalRecalc(connectionString);
                auditor = new AgentAuditor(connectionString, GetAuditTypeGroupName());

                auditor.TryAddAuditEntry(string.Format("{0} Started", AgentName), string.Format("The {0} has started", AgentName), string.Empty);

				var pollingInterval = GetPollingInterval();
                var recalcHistoryLookbackMinutes = GetRecalcHistoryLookbackMinutes();

                // All work is delegated to a controller
				using (var controller = new Controller())
                { 
                    // provide the controller with a context that informs the controller of the database connection to use, and also any limits on processing
                    ControlContext context = new ControlContext()
                    {
                        QueueEntryType = null, // tell the controller to process any kind of queue entry
                        ConnectionString = GetConnectionString(Keys.DatabaseKey, Keys.DatabaseUser),
                        MaxOrdinal = GetMaxProcessingOrdinal()
                    };
                    controller.Initialise(context);

                    // tell the controller to start processing (the controller will begin its own background thread)
					controller.StartProcessingAsync();

					while (!StopRequested)
					{
                        // if an error has occured
                        if (controller.Error != null)
                        {
                            // throw the controller exception on this thread to report back to the Reconcilor Engine
                            throw (controller.Error);
                        }

                        // the max ordinal represents the max month that can be processed
                        // this could need to be updated (once a month), so check it on each iteration and update when needed
                        long newMaxOrdinal = GetMaxProcessingOrdinal();
                        if (newMaxOrdinal != context.MaxOrdinal)
                        {
                            context.MaxOrdinal = newMaxOrdinal;
                        }

                        // raise any new data processing queue entries required based on recalc history
                        DalRecalc.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory(recalcHistoryLookbackMinutes);

                        // wait the polling interval before the next check
                        Sleep(pollingInterval);
					}

                    // the agent is stopping.. tell the controller to stop too; and wait till it does
					controller.StopProcessing();

					auditor.TryAddAuditEntry(string.Format("{0} Stopped", AgentName), string.Format("The {0} has stopped", AgentName), string.Empty);
				}
			}
			catch (Exception ex)
			{
				if (auditor != null)
				{
					// log the fact that the agent is stopping
					auditor.TryAddAuditEntry(string.Format("{0} Error", AgentName), "An error has occured",
						string.Format("Error: {0}, Stacktrace: {1}", ex.Message, ex.StackTrace));
				}

				// rethrow the exception (back to the Engine)
				throw;
			}
			finally
			{
				if (auditor != null)
				{
					auditor.Dispose();
				}
			}
		}

        #region Private Support Methods

        /// <summary>
        /// Get an ordinal value representing the latest month that can be processed
        /// </summary>
        /// <returns>ordinal value</returns>
        private long GetMaxProcessingOrdinal()
        {
            // calculate the number of months since the month representing ordinal 1
            DateTime current = DateTime.Now;
            DateTime startOfCurrentMonth = new DateTime(current.Year, current.Month, 1);
            int diffMonths = startOfCurrentMonth.Month - _monthRepresentingOrdinal.Month;
            int diffYears = startOfCurrentMonth.Year - _monthRepresentingOrdinal.Year;
            diffMonths = diffMonths + (diffYears * 12);
            
            // the max ordinal is the difference in months  (NOTE: only complete months can be processed)
            return diffMonths;
        }

        private TimeSpan GetPollingInterval()
        {
            const string key = Keys.PollingInterval;

            if (!ConfigurationSettings.ContainsKey(key))
            {
                throw new InvalidOperationException(string.Format("The Polling configuration setting ({0}) is missing from the configuration.", key));
            }

            var value = ConfigurationSettings[key];
            int result;

            if (string.IsNullOrEmpty(value) || !int.TryParse(value, out result))
            {
                throw new InvalidOperationException(string.Format("The Polling configuration setting ({0}) value ({1}) must be a numeric integer.", key, value));
            }

            // time unit is seconds
            return new TimeSpan(0, 0, result);
        }

        private int GetRecalcHistoryLookbackMinutes()
        {
            const string key = Keys.RecalcHistoryLookbackMinutes;

            if (!ConfigurationSettings.ContainsKey(key))
            {
                throw new InvalidOperationException(string.Format("The Recalc History Lookback Minutes configuration setting ({0}) is missing from the configuration.", key));
            }

            var value = ConfigurationSettings[key];
            int result;

            if (string.IsNullOrEmpty(value) || !int.TryParse(value, out result))
            {
                throw new InvalidOperationException(string.Format("The Recalc History Lookback Minutes configuration setting ({0}) value ({1}) must be a numeric integer.", key, value));
            }

            return result;
        }
        private string GetAuditTypeGroupName()
        {
            const string key = Keys.AuditTypeGroupName;

            if (!ConfigurationSettings.ContainsKey(key))
            {
                throw new InvalidOperationException(string.Format("The Audit Type Group Name configuration setting ({0}) is missing from the configuration.", key));
            }

            var value = ConfigurationSettings[key];

            if (string.IsNullOrEmpty(value))
            {
                throw new InvalidOperationException(string.Format("The Audit Type Group Name configuration setting ({0}) value ({1}) must not be blank.", key, value));
            }

            return value;
        }

        #endregion
    }
}
