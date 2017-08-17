using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace MQ2Direct
{
    public partial class AdjustmentType
    {
        public AdjustmentType()
        {
            Grade = new Grade[] { };
        }

        public AdjustmentType(DataRow row, DataTable gradeRows)
            : this()
        {
            if (row.IsFieldSpecified("Mine"))
            {
                Location = new Location(row.Field<string>("Mine"));
            }
            if (row.IsFieldSpecified("StockpileName"))
            {
                StockpileID = row.Field<string>("StockpileName");
            }
            if (row.IsFieldSpecified("AdjustmentType"))
            {
                AdjustmentType1 = row.Field<string>("AdjustmentType");
            }
            AdjustmentDateSpecified = row.IsFieldSpecified("AdjustmentDate");
            if (AdjustmentDateSpecified)
            {
                AdjustmentDate = row.Field<DateTime>("AdjustmentDate");
            }
            TonnesSpecified = row.IsFieldSpecified("Tonnes");
            if (TonnesSpecified)
            {
                Tonnes = row.Field<decimal>("Tonnes");
            }
            FinesPercentSpecified = row.IsFieldSpecified("FinesPercent");
            if (FinesPercentSpecified)
            {
                FinesPercent = row.Field<decimal>("FinesPercent");
            }
            LumpPercentSpecified = row.IsFieldSpecified("LumpPercent");
            if (LumpPercentSpecified)
            {
                LumpPercent = row.Field<decimal>("LumpPercent");
            }
            BcmSpecified = row.IsFieldSpecified("BCM");
            if (BcmSpecified)
            {
                Bcm = row.Field<decimal>("BCM");
            }
            LastModifiedTimeSpecified = row.IsFieldSpecified("LastModifiedTime");
            if (LastModifiedTimeSpecified)
            {
                LastModifiedTime = row.Field<DateTime>("LastModifiedTime");
            }
            List<Grade> grades = new List<Grade>();
            foreach (DataRow r in from gradeRow in gradeRows.AsEnumerable()
                                  where Convert.ToInt32(gradeRow["StockpileAdjustmentId"]) == Convert.ToInt32(row["StockpileAdjustmentId"])
                                  select gradeRow)
            {
                grades.Add(new Grade(r));
            }
            if (grades.Count > 0)
            {
                Grade = grades.ToArray();
            }
        }
    }

    public partial class Location
    {
        public Location()
        {
            this.Mine = string.Empty;
        }

        public Location(string mine)
        {
            this.Mine = mine;
        }
    }

    public partial class Grade
    {
        public Grade(System.Data.DataRow r, decimal lumpValueModifier = 0, decimal finesValueModifier = 0, string forGeomeType = null, bool includeLumpAndFines = true)
        {
            if (r.IsFieldSpecified("GradeName"))
            {
                Name = r.Field<string>("GradeName");
            }

            //if (r.IsFieldSpecified("GeometType"))
            //{
            //    GeometType = r.Field<string>("GeometType");
            //}
            //else
            //{
            //    GeometType = forGeomeType;
            //}

            if (r.IsFieldSpecified("SampleValue"))
            {
                SampleValue = (decimal)r.Field<float>("SampleValue");
                SampleValueSpecified = true;
            }
            else
            {
                SampleValueSpecified = false;
            }
            if (r.IsFieldSpecified("HeadValue"))
            {
                HeadValue = r.Field<decimal>("HeadValue");
                HeadValueSpecified = true;
            }
            else
            {
                HeadValueSpecified = false;
            }

            if (includeLumpAndFines)
            {

                if (r.IsFieldSpecified("FinesValue"))
                {
                    FinesValue = r.Field<decimal>("FinesValue") + finesValueModifier;
                    FinesValueSpecified = true;
                }
                else
                {
                    FinesValueSpecified = false;
                }
                if (r.IsFieldSpecified("LumpValue"))
                {
                    LumpValue = r.Field<decimal>("LumpValue") + lumpValueModifier;
                    LumpValueSpecified = true;
                }
                else
                {
                    LumpValueSpecified = false;
                }
            }
        }
        public Grade()
        {
            SampleValueSpecified = false;
            HeadValueSpecified = false;
            FinesValueSpecified = false;
            LumpValueSpecified = false;
        }
    }

    public partial class StockpileType
    {
        public StockpileType() { }

        public StockpileType(DataRow r)
        {
            if (r.IsFieldSpecified("Mine"))
            {
                this.Location = new Location(r.Field<string>("Mine"));
            }
            if (r.IsFieldSpecified("Name"))
            {
                Name = r.Field<string>("Name");
            }
            if (r.IsFieldSpecified("BusinessId"))
            {
                BusinessId = r.Field<string>("BusinessId");
            }
            if (r.IsFieldSpecified("StockpileType"))
            {
                StockpileType1 = r.Field<string>("StockpileType");
            }
            if (r.IsFieldSpecified("Description"))
            {
                Description = r.Field<string>("Description");
            }
            if (r.IsFieldSpecified("OreType"))
            {
                OreType = r.Field<string>("OreType");
            }
            if (r.IsFieldSpecified("Type"))
            {
                Type = r.Field<string>("Type");
            }
            if (r.IsFieldSpecified("Active"))
            {
                Active = r.Field<bool>("Active").ToString();
            }
            StartDateSpecified = r.IsFieldSpecified("StartDate");
            if (StartDateSpecified)
            {
                StartDate = r.Field<DateTime>("StartDate");
            }
            if (r.IsFieldSpecified("ProductSize"))
            {
                ProductSize = r.Field<string>("ProductSize");
            }
        }
    }

    public partial class ProdMovesTransactionType
    {
        public ProdMovesTransactionType()
        {
            Grade = new Grade[] { };
        }

        public ProdMovesTransactionType(DataRow row, DataTable gradeRows)
            : this()
        {
            Location = new Location(row.Field<string>("Mine"));
            TransactionDateSpecified = row.IsFieldSpecified("TransactionDate");
            if (TransactionDateSpecified)
            {
                TransactionDate = row.Field<DateTime>("TransactionDate");
            }
            Source = row.Field<string>("Source");
            SourceType = row.Field<string>("SourceType");
            SourceMineSite = row.Field<string>("SourceMineSite");
            Destination = row.Field<string>("Destination");
            DestinationType = row.Field<string>("DestinationType");
            DestinationMineSite = row.Field<string>("DestinationMineSite");
            Type = row.Field<string>("Type");
            TonnesSpecified = row.IsFieldSpecified("Tonnes");
            if (TonnesSpecified)
            {
                Tonnes = row.Field<decimal>("Tonnes");
            }
            ProductSize = row.Field<string>("ProductSize");
            LastModifiedTimeSpecified = row.IsFieldSpecified("LastModifiedTime");
            if (LastModifiedTimeSpecified)
            {
                LastModifiedTime = row.Field<DateTime>("LastModifiedTime");
            }
            SampleSource = row.Field<string>("SampleSource");
            SampleTonnesSpecified = row.IsFieldSpecified("SampleTonnes");
            if (SampleTonnesSpecified)
            {
                SampleTonnes = row.Field<decimal>("SampleTonnes");
            }
            SampleCountSpecified = row.IsFieldSpecified("SampleCount");
            if (SampleCountSpecified)
            {
                SampleCount = row.Field<Int32>("SampleCount");
            }
            List<Grade> grades = new List<Grade>();
            foreach (DataRow r in from gradeRow in gradeRows.AsEnumerable() where Convert.ToInt32(gradeRow["TransactionId"]) == Convert.ToInt32(row["Id"]) select gradeRow)
            {
                grades.Add(new Grade(r));
            }
            Grade = grades.ToArray();
        }
    }

    public partial class HaulageTransactionType
    {
        public HaulageTransactionType() { }

        public HaulageTransactionType(DataRow haulageRow, DataSet haulageDataSet)
            : this()
        {
            var locname = (from r in haulageDataSet.Tables["Locations"].AsEnumerable()
                           where r.Field<int>("TransactionId") == haulageRow.Field<int>("Id")
                           select r.Field<string>("Mine")).FirstOrDefault();
            Location = new Location(locname);
            TransactionDateSpecified = haulageRow.IsFieldSpecified("TransactionDate");
            if (TransactionDateSpecified)
            {
                TransactionDate = haulageRow.Field<DateTime>("TransactionDate");
            }
            Source = haulageRow.Field<string>("Source");
            SourceMineSite = haulageRow.Field<string>("SourceMineSite");
            DestinationMineSite = haulageRow.Field<string>("DestinationMineSite");
            SourceLocationType = haulageRow.Field<string>("SourceLocationType");
            Destination = haulageRow.Field<string>("Destination");
            DestinationType = haulageRow.Field<string>("DestinationType");
            Type = haulageRow.Field<string>("Type");
            BestTonnesSpecified = haulageRow.IsFieldSpecified("BestTonnes");
            if (BestTonnesSpecified)
            {
                BestTonnes = haulageRow.Field<decimal>("BestTonnes");
            }
            HauledTonnesSpecified = haulageRow.IsFieldSpecified("HauledTonnes");
            if (HauledTonnesSpecified)
            {
                HauledTonnes = haulageRow.Field<decimal>("HauledTonnes");
            }
            AerialSurveyTonnesSpecified = haulageRow.IsFieldSpecified("AerialSurveyTonnes");
            if (AerialSurveyTonnesSpecified)
            {
                AerialSurveyTonnes = haulageRow.Field<decimal>("AerialSurveyTonnes");
            }
            GroundSurveyTonnesSpecified = haulageRow.IsFieldSpecified("GroundSurveyTonnes");
            if (GroundSurveyTonnesSpecified)
            {
                GroundSurveyTonnes = haulageRow.Field<decimal>("GroundSurveyTonnes");
            }
            LumpPercentSpecified = haulageRow.IsFieldSpecified("LumpPercent");
            if (LumpPercentSpecified)
            {
                LumpPercent = haulageRow.Field<decimal>("LumpPercent");
            }
            LastModifiedTimeSpecified = haulageRow.IsFieldSpecified("LastModifiedTime");
            if (LastModifiedTimeSpecified)
            {
                LastModifiedTime = haulageRow.Field<DateTime>("LastModifiedTime");
            }
            List<Grade> grades = new List<Grade>();
            var gradeRows = haulageDataSet.Tables["Grades"];
            var selectedGradeRows = (from gradeRow in gradeRows.Rows.Cast<DataRow>()
                                     where Convert.ToInt32(gradeRow["TransactionId"]) == Convert.ToInt32(haulageRow["Id"])
                                     select gradeRow).ToList();
            foreach (DataRow r in selectedGradeRows)
            {
                grades.Add(new Grade(r));
            }
            Grade = grades.ToArray();
        }
    }

    public partial class RetrieveHaulageResponse
    {
        public RetrieveHaulageResponse()
        {
            Status = new Status();
            Status.StatusFlag = true;
            Status.StatusMessage = string.Empty;
            this.Haulage = new HaulageTransactionType[] { };
        }

        public RetrieveHaulageResponse(DataSet ds) : this()
        {
            if (ds.Tables["Transactions"].Rows.Count > 0)
            {
                List<HaulageTransactionType> haulagelist = new List<HaulageTransactionType>();
                foreach (DataRow row in ds.Tables["Transactions"].Rows)
                {
                    haulagelist.Add(new HaulageTransactionType(row, ds));
                }
                Haulage = haulagelist.ToArray();
            }
        }
    }

    public partial class RetrieveProductionMovementsResponse
    {

        public RetrieveProductionMovementsResponse()
        {
            Status = new Status();
            Status.StatusFlag = true;
            Status.StatusMessage = string.Empty;
            Production = new ProdMovesTransactionType[] { };
        }

        public RetrieveProductionMovementsResponse(DataSet ds)
            : this()
        {
            if (ds.Tables["Transactions"].Rows.Count > 0)
            {
                Status.StatusFlag = true;
                Status.StatusMessage = string.Empty;
                List<ProdMovesTransactionType> productionList = new List<ProdMovesTransactionType>();
                foreach (DataRow r in ds.Tables["Transactions"].Rows)
                {
                    productionList.Add(new ProdMovesTransactionType(r, ds.Tables["Grades"]));
                }
                Production = productionList.ToArray();
            }
        }

    }

    public partial class RetrieveStockpilesResponse
    {
        public RetrieveStockpilesResponse()
        {
            Status = new Status();
            Status.StatusFlag = true;
            Status.StatusMessage = string.Empty;
            Stockpiles = new StockpileType[] { };
        }

        public RetrieveStockpilesResponse(DataSet ds)
            : this()
        {
            if (ds.Tables["Stockpiles"].Rows.Count > 0)
            {
                Status.StatusFlag = true;
                statusField.StatusMessage = string.Empty;
                var stockpileList = new List<StockpileType>();
                foreach (DataRow r in ds.Tables["Stockpiles"].Rows)
                {
                    stockpileList.Add(new StockpileType(r));
                }
                Stockpiles = stockpileList.ToArray();
            }
        }
    }

    public partial class RetrieveStockpileAdjustmentsResponse
    {
        public RetrieveStockpileAdjustmentsResponse()
        {
            Status = new Status();
            Status.StatusFlag = true;
            Status.StatusMessage = string.Empty;
            StockpileAdjustment = new AdjustmentType[] { };
        }

        public RetrieveStockpileAdjustmentsResponse(System.Data.DataSet ds)
            : this()
        {
            if (ds.Tables["Adjustments"].Rows.Count > 0)
            {
                Status.StatusFlag = true;
                Status.StatusMessage = string.Empty;

                List<AdjustmentType> adjustments = new List<AdjustmentType>();
                foreach (DataRow row in ds.Tables["Adjustments"].Rows)
                {
                    adjustments.Add(new AdjustmentType(row, ds.Tables["Grades"]));
                }
                StockpileAdjustment = adjustments.ToArray();
            }
        }
    }

  



    public static class Extensions
    {
        public static bool IsFieldSpecified(this DataRow row, string p)
        {
            return row.Table.Columns.Contains(p) && !row.IsNull(p);
        }
    }
}