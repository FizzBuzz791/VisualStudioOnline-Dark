using System;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects;
using Snowden.Reconcilor.Bhpbio.Database.Dtos;
using Snowden.Reconcilor.Bhpbio.Database.SqlDal;

namespace Snowden.Reconcilor.Bhpbio.DalTests.Purging
{
    /// <summary>
    /// Summary description for PurgeDalUnitTests
    /// </summary>
    [TestClass]
    public class PurgeDalUnitTests
    {
        internal static class Constants
        {
            public const string ConnectionStringFormat = @"Data Source={0};Initial Catalog={1};Integrated Security=true;Trusted_Connection=true;";
        }

        /// <summary>
        ///Gets or sets the test context which provides
        ///information about and functionality for the current test run.
        ///</summary>
        public TestContext TestContext { get; set; }

        public string ConnectionString { get; private set; }

        public IPurge PurgeDal { get; private set; }

        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        // Use TestInitialize to run code before running each test 
        // [TestInitialize()]
        // public void MyTestInitialize() { }
        //
        // Use TestCleanup to run code after each test has run
        // [TestCleanup()]
        // public void MyTestCleanup() { }
        //
        #endregion

        [TestInitialize]
        public void TestInitialize() 
        {
            this.ConnectionString = string.Format(Constants.ConnectionStringFormat, @"Reconcilor1\SQL2005", @"ReconcilorBHPBIOArchiving");
            this.PurgeDal = new SqlDalPurge(this.ConnectionString);
        }

        [TestCleanup]
        public void TestCleanup()
        {
            this.ConnectionString = null;
            this.PurgeDal.Dispose();
        }

        /// <summary>
        /// Process a single purge request through all its various states, and then 
        /// marking record as cancelled after the test is done.
        /// </summary>
        /// <remarks>
        /// The issue with this test at the moment is that it is not repeatable (ie it leaves the data in a different state than it started)..\
        /// ... it was useful during development but a different approach (mock DAL for example) would be needed for a repeatable test
        /// </remarks>
        [TestMethod]
        [Ignore]
        public void ProcessPurgeRequestWorkFlow()
        {
            const int alex = 119;
            const int phil = 1533;
            var latestDate = this.PurgeDal.GetLatestPurgeMonth();
            var request = new PurgeRequest
                              {
                                  Month = new DateTime(DateTime.Today.Year, DateTime.Today.Month,1).AddMonths(1),
                                  RequestingUser = new PurgeUser
                                                       {
                                                           Id = alex,
                                                           FirstName = "Alex",
                                                           LastName = "Wong"
                                                       },
                                   Status = PurgeRequestState.Requested
                              };

            Assert.IsTrue(latestDate == null || latestDate.Value < request.Month);

            int id;
            Assert.IsTrue(this.PurgeDal.AddPurgeRequest(request.Month,request.RequestingUser.Id, out id));
            request.Id = id;
            Assert.IsTrue(request.Id > 0);
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, true,true).ToList().Any(o => o.Id == request.Id));
            Assert.IsTrue(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsTrue(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));

            // Get Purge Requests Ready for Approval i.e. requested
            var requests = this.PurgeDal.GetPurgeRequests(true, null, true).ToList();
            Assert.IsNotNull(requests);
            Assert.IsTrue(requests.Count != 0);
            Assert.IsTrue(requests.All(o => o.Status == request.Status));
            var requestedItem = requests.SingleOrDefault(o => o.Id == request.Id);
            Assert.IsNotNull(requestedItem);
            Assert.AreEqual(request.Month, requestedItem.Month);
            // validate requesting user
            Assert.AreEqual(request.RequestingUser.Id, requestedItem.RequestingUser.Id);
            Assert.AreEqual(request.RequestingUser.FirstName, requestedItem.RequestingUser.FirstName);
            Assert.AreEqual(request.RequestingUser.LastName, requestedItem.RequestingUser.LastName);

            // Approve Request
            Assert.IsTrue(this.PurgeDal.UpdatePurgeRequests(new[]{request.Id},PurgeRequestState.Approved, phil));
            Assert.IsTrue(this.PurgeDal.GetPurgeRequests(null, true, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsTrue(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));

            // Get Purge Requests Ready For Purging i.e. approved
            var approvedRequests = this.PurgeDal.GetPurgeRequests(null, true, true).ToList();
            Assert.IsNotNull(approvedRequests);
            Assert.IsTrue(approvedRequests.Count != 0);
            Assert.IsTrue(approvedRequests.All(o => o.Status == PurgeRequestState.Approved));
            var approvedRequest = approvedRequests.SingleOrDefault(o => o.Id == request.Id);
            Assert.IsNotNull(approvedRequest);
            // validate approving user
            Assert.IsNotNull(approvedRequest.ApprovingUser);
            Assert.AreEqual(approvedRequest.ApprovingUser.Id,phil);
            Assert.AreEqual(approvedRequest.ApprovingUser.FirstName,"Phil");
            Assert.AreEqual(approvedRequest.ApprovingUser.LastName,"Pettit");

            // get approving user
            request.ApprovingUser = approvedRequest.ApprovingUser;

            // Initiate Request
            Assert.IsTrue(this.PurgeDal.UpdatePurgeRequests(new[] { request.Id }, PurgeRequestState.Initiated, null));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, true, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsTrue(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));

            // Completed Request
            Assert.IsTrue(this.PurgeDal.UpdatePurgeRequests(new[] { request.Id }, PurgeRequestState.Completed, null));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, true, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));

            // Failed Request
            Assert.IsTrue(this.PurgeDal.UpdatePurgeRequests(new[] { request.Id }, PurgeRequestState.Failed, null));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, true, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));

            // Cancel Request 
            Assert.IsTrue(this.PurgeDal.UpdatePurgeRequests(new[] { request.Id }, PurgeRequestState.Cancelled, null));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, true, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(true, null, true).ToList().Any(o => o.Id == request.Id));
            Assert.IsFalse(this.PurgeDal.GetPurgeRequests(null, null, true).ToList().Any(o => o.Id == request.Id));
        }
    }
}
