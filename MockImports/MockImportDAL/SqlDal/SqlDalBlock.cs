using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using Snowden.Common.Database.DataAccessBaseObjects;

namespace MockImportDAL.SqlDal
{
    public class SqlDalBlock : SqlDalBaseReplacement, MockImportDAL.DalBaseObjects.Interfaces.IBlock
    {
        #region Constructors
        public SqlDalBlock() : base() { }

        public SqlDalBlock(string connectionString) : base(connectionString) { }

        public SqlDalBlock(IDbConnection databaseConnection) : base(databaseConnection) { }

        public SqlDalBlock(IDataAccessConnection dataAccessConnection) : base(dataAccessConnection) { }
        #endregion

        public DataSet RetrieveReconciliationBlocks(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetReconciliationBlocks";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Blocks";
            ds.Tables[1].TableName = "Patterns";
            ds.Tables[2].TableName = "Models";
            ds.Tables[3].TableName = "Grades";
            ds.Tables[4].TableName = "Points";
            ds.Tables[5].TableName = "Polygons";

            return ds;
        }

        public DataSet RetrieveReconciliationDeletedBlocks(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetReconciliationDeletedBlocks";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Blocks";
            ds.Tables[1].TableName = "Patterns";

            return ds;
        }

        public DataSet RetrieveReconciliationMovements(DateTime startDate, DateTime endDate)
        {
            DataAccess.CommandText = "dbo.GetReconciliationMovements";

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate);
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate);

            DataSet ds = DataAccess.ExecuteDataSet();

            // Rename tables.
            ds.Tables[0].TableName = "Blocks";
            ds.Tables[1].TableName = "Patterns";
            ds.Tables[2].TableName = "Movements";

            return ds;
        }

        public int InsertBlock(DateTime blastedDate, DateTime blockedDate, string geoType, DateTime lastModifedDate, string lastModifiedUser,
            string mq2PitCode, string name, string number, string patternBench, string patternNumber, string patternOrebody, string patternPit,
            string patternSite, Single centroidEasting, Single centroidNorthing, Single centroidRl, out int polygonId)
        {
            DataAccess.CommandText = "dbo.InsertBlock";
            DataAccess.CommandType = CommandObjectType.StoredProcedure;

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@BlastedDate", blastedDate);
            DataAccess.ParameterCollection.Add("@BlockedDate", blockedDate);
            DataAccess.ParameterCollection.Add("@GeoType", geoType);
            DataAccess.ParameterCollection.Add("@LastModifiedDate", lastModifedDate);
            DataAccess.ParameterCollection.Add("@LastModifiedUser", lastModifiedUser);
            DataAccess.ParameterCollection.Add("@Mq2PitCode", mq2PitCode);
            DataAccess.ParameterCollection.Add("@Name", name);
            DataAccess.ParameterCollection.Add("@Number", number);

            DataAccess.ParameterCollection.Add("@PatternSite", patternSite);
	        DataAccess.ParameterCollection.Add("@PatternOrebody", patternOrebody);
	        DataAccess.ParameterCollection.Add("@PatternPit", patternPit);
	        DataAccess.ParameterCollection.Add("@PatternBench", patternBench);
	        DataAccess.ParameterCollection.Add("@PatternNumber", patternNumber);
	        DataAccess.ParameterCollection.Add("@CentroidEasting", centroidEasting);
	        DataAccess.ParameterCollection.Add("@CentroidNorthing", centroidNorthing);
            DataAccess.ParameterCollection.Add("@CentroidRL", centroidRl);

            DataAccess.ParameterCollection.Add("@oBlockId", CommandDataType.Int, CommandDirection.Output, null);
            DataAccess.ParameterCollection.Add("@oPolygonId", CommandDataType.Int, CommandDirection.Output, null);

            DataAccess.ExecuteNonQuery();

            polygonId = (int)DataAccess.ParameterCollection["@oPolygonId"].Value;
            return (int)DataAccess.ParameterCollection["@oBlockId"].Value;
        }

        public void InsertModel(int blockId, string modelName, string modelFilename, string oreType, Single volume, Single tonnes, Single density,
            DateTime lastModifedDate, string lastModifiedUser, Single feGradeValue, Single pGradeValue, Single siO2GradeValue, Single al2O3GradeValue, Single LoiGradeValue)
        {
            DataAccess.CommandText = "dbo.InsertModel";
            DataAccess.CommandType = CommandObjectType.StoredProcedure;

            DataAccess.ParameterCollection.Clear();
            DataAccess.ParameterCollection.Add("@BlockId", blockId);
	        DataAccess.ParameterCollection.Add("@Name", modelName);
	        DataAccess.ParameterCollection.Add("@Filename", modelFilename);
	        DataAccess.ParameterCollection.Add("@OreType", oreType);
	        DataAccess.ParameterCollection.Add("@Volume", volume);
	        DataAccess.ParameterCollection.Add("@Tonnes", tonnes);
	        DataAccess.ParameterCollection.Add("@Density", density);
            if (lastModifedDate != DateTime.MinValue)
            {
                DataAccess.ParameterCollection.Add("@LastModifiedDate", lastModifedDate);
            }
	        DataAccess.ParameterCollection.Add("@LastModifiedUser", lastModifiedUser);
	        DataAccess.ParameterCollection.Add("@FeGradeValue", feGradeValue);
	        DataAccess.ParameterCollection.Add("@PGradeValue", pGradeValue);
	        DataAccess.ParameterCollection.Add("@SiO2GradeValue", siO2GradeValue);
	        DataAccess.ParameterCollection.Add("@Al2O3GradeValue", al2O3GradeValue);
            DataAccess.ParameterCollection.Add("@LoiGradeValue", LoiGradeValue);

            DataAccess.ExecuteNonQuery();
        }

        public void ExecuteSql(string sql)
        {
            DataAccess.CommandType = CommandObjectType.InlineSql;
            DataAccess.ParameterCollection.Clear();
            DataAccess.CommandText = sql;
            DataAccess.ExecuteScalar2();
        }
    }
}
