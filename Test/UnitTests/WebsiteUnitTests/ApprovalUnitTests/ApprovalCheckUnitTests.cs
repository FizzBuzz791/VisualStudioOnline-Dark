using System.Data;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Snowden.Reconcilor.Bhpbio.Website.Approval;

namespace Snowden.Reconcilor.Bhpbio.UnitTests.WebsiteUnitTests.ApprovalUnitTests
{
    /// <summary>
    /// Summary description for ApprovalCheckUnitTests
    /// </summary>
    [TestClass]
    public class ApprovalCheckUnitTests
    {
        /// <summary>
        ///Gets or sets the test context which provides
        ///information about and functionality for the current test run.
        ///</summary>
        public TestContext TestContext { get; set; }

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

        private const string IsEditableColumnName = "IsEditable";
        private static DataTable GetIsEditableDataTable(bool hasColumn, bool isEditable)
        {
            var dataTable = new DataTable();
            dataTable.Columns.Add("NameColumn");
            if (hasColumn)
            {
                dataTable.Columns.Add(IsEditableColumnName);
                dataTable.Rows.Add("Name", isEditable);
            }
            else
            {
                dataTable.Rows.Add("Name");
            }

            return dataTable;
        }

        [TestMethod]
        public void TestIsEditableHasPermissionAndIsEditable()
        {
            var dataTable = GetIsEditableDataTable(true, true);
            var isEditable = ApprovalCheck.IsEditable(true, dataTable.Rows[0], IsEditableColumnName, true, dataTable);
            Assert.IsTrue(isEditable);
        }

        [TestMethod]
        public void TestIsEditableNoPermissionsAndIsEditable()
        {
            var dataTable = GetIsEditableDataTable(true, true);
            var isEditable = ApprovalCheck.IsEditable(false, dataTable.Rows[0], IsEditableColumnName, false, dataTable);
            Assert.IsFalse(isEditable);
        }

        [TestMethod]
        public void TestIsEditableHasPermissionAndIsNotEditable()
        {
            var dataTable = GetIsEditableDataTable(true, false);
            var isEditable = ApprovalCheck.IsEditable(true, dataTable.Rows[0], IsEditableColumnName, false, dataTable);
            Assert.IsFalse(isEditable);
        }

        [TestMethod]
        public void TestIsEditableHasPermissionAndHasNoEditableColumn()
        {
            var dataTable = GetIsEditableDataTable(false, false);
            var isEditable = ApprovalCheck.IsEditable(true, dataTable.Rows[0], IsEditableColumnName, false, dataTable);
            Assert.IsTrue(isEditable);
        }

        [TestMethod]
        public void TestIsEditableHasPermissionAndIsEditableIsFalse()
        {
            var dataTable = GetIsEditableDataTable(true, false);
            var isEditable = ApprovalCheck.IsEditable(true, dataTable.Rows[0], IsEditableColumnName, true, dataTable);
            Assert.IsFalse(isEditable);
        }
    }
}