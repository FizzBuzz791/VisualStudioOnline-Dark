using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Snowden.Common.Database.DataAccessBaseObjects;
using Snowden.Reconcilor.Core.Database.DalBaseObjects;
using Snowden.Reconcilor.Core.Database.SqlDal;

namespace Snowden.Reconcilor.Bhpbio.Engine.Auditor
{
	public class AgentAuditor : IDisposable
	{
		public IEvent DalAudit { get; set; }
		
		public int AuditTypeGroupId { get; private set; }

		public List<string> AuditTypeNames { get; private set; } 

		public AgentAuditor(string connectionString, string auditTypeGroupName)
		{
			DalAudit = new SqlDalEvent(connectionString);

			if (DalAudit == null)
			{
				return;
			}

			AuditTypeGroupId = DalAudit.GetAuditTypeList(NullValues.Int32)
				.AsEnumerable()
				.Where(o => o.Field<string>("Audit_Type_Group_Name") == auditTypeGroupName)
				.Select(o => o.Field<int>("Audit_Type_Group_Id"))
				.FirstOrDefault();

			AuditTypeNames =
				DalAudit.GetAuditTypeList(AuditTypeGroupId).AsEnumerable().Select(o => o.Field<string>("Name")).ToList();
		}

		public bool TryAddAuditEntry(string key, string description, string details)
		{
			if (AuditTypeGroupId <= 0 || DalAudit == null ||
			    DalAudit.DataAccess.DataAccessConnection.Connection.State != ConnectionState.Open ||
			    !AuditTypeNames.Contains(key))
			{
				return false;
			}

			DalAudit.AddAuditHistory(key, AuditTypeGroupId, description, "", details, NullValues.Int32, 1, "127.0.0.1", "localhost");

			return true;
		}

		public void Dispose()
		{
			if (DalAudit != null)
			{
				DalAudit.Dispose();
			}
		}
	}
}
