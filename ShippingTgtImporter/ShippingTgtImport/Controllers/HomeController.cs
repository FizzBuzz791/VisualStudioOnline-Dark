using Excel;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.OleDb;
using System.IO;
using System.Reflection;
using System.Text;
using System.Data.SqlTypes;
using Helpers;
using System.Data.SqlClient;


namespace ShippingTgtImport.Controllers
{
    public class ProductTypeClass
    {
        private string productTypeCode;
        public string ProductTypeCode
        {
            get { return productTypeCode; }
            set { productTypeCode = value; }
        }

        private string productTypeID;
        public string ProductTypeID
        {
            get { return productTypeID; }
            set { productTypeID = value; }
        }
    }
    public class HomeController : BaseController
    {
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }


        [HttpPost]
        public ActionResult Importexcel()
        {
            if (Request.Files["FileUpload1"].ContentLength > 0)
            {
                string extension = System.IO.Path.GetExtension(Request.Files["FileUpload1"].FileName);
                string path1 = string.Format("{0}/{1}", Server.MapPath("~/Uploads"), Path.GetFileName(Request.Files["FileUpload1"].FileName));

                ////Save the file
                if (System.IO.File.Exists(path1))
                    System.IO.File.Delete(path1);
                Request.Files["FileUpload1"].SaveAs(path1);


                FileStream stream = System.IO.File.Open(path1, FileMode.Open, FileAccess.Read);
                DataTable result = new DataTable();
                if (extension == ".xlsx")
                {
                    //Reading from a OpenXml Excel file (2007 format; *.xlsx)
                    IExcelDataReader excelReader = ExcelReaderFactory.CreateOpenXmlReader(stream);
                    result = excelReader.AsDataSet().Tables[0];
                }
                else if (extension == ".xls")
                {
                    //Reading from a binary Excel file ('97-2003 format; *.xls)
                    IExcelDataReader excelReader = ExcelReaderFactory.CreateBinaryReader(stream);
                    result = excelReader.AsDataSet().Tables[2];
                }
                else
                {
                    Danger("Wrong File Format", true);
                    return View("Index");
                }

                int ShippingTargetID = 0;

                DataTable grades = GetGrades();
                StringBuilder sb = new StringBuilder();

                var prodtypes = GetProductTypeIds();
                result.Rows.RemoveAt(0);
                result.Columns[4].ColumnName = "Fe";
                result.Columns[5].ColumnName = "P";
                result.Columns[6].ColumnName = "SIO2";
                result.Columns[7].ColumnName = "AL2O3";
                result.Columns[8].ColumnName = "LOI";
                result.Columns[9].ColumnName = "H2O";
                result.Columns[10].ColumnName = "Undersize";
                result.Columns[11].ColumnName = "Oversize";

                sb.Append("Declare @oShippingTargetPeriodId INT " +Environment.NewLine);
                //sb.Append("Declare @iProductTypeId INT ");
                //sb.Append("Declare @iEffectiveFromDateTime Datetime ");

                foreach (DataRow dr in result.Rows)
                {
                    if (dr[3].ToString().Contains("Upper"))
                    {

                        if (Request["chkSQL"] != null) // Generates file instead
                        {

                            //sb.Append(" set @iProductTypeId = (select producttypeid from BhpbioProductType where ProductTypeCode = '" + dr[2] + "')");
                            //sb.Append(" set @iEffectiveFromDateTime ='" + DateTime.Parse(dr[0].ToString()) + "'");
                            sb.Append(" IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = '" + dr[2] + "')) AND EffectiveFromDateTime = convert(datetime, '" + Convert.ToDateTime(dr[0].ToString()).ToString("dd/MM/yyyy") + "', 103)) "+ Environment.NewLine +" BEGIN " +Environment.NewLine);
                            //sb.Append("INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = '" + dr[2] + "')), '" + DateTime.Parse(dr[0].ToString()) + "', 740, GetDate() ) SET @oShippingTargetPeriodId = SCOPE_IDENTITY() END ");
                            sb.Append( Environment.NewLine+ "  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) "+Environment.NewLine+"     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = '" + dr[2] + "')), convert(datetime, '" + Convert.ToDateTime(dr[0].ToString()).ToString("dd/MM/yyyy") + "', 103), 740, GetDate() ) "+Environment.NewLine+"     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() "+Environment.NewLine+" END " + Environment.NewLine);

                            //sb.Append(" set @iProductTypeId = (select producttypeid from BhpbioProductType where ProductTypeCode = '" + dr[2] + "')");
                            //sb.Append(" set @iEffectiveFromDateTime ='" + DateTime.Parse(dr[0].ToString()) + "'");
                            //sb.Append(" IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = @iProductTypeId AND EffectiveFromDateTime = @iEffectiveFromDateTime) BEGIN ");
                            //sb.Append("INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) VALUES (@iProductTypeId, @iEffectiveFromDateTime, 740, GetDate() ) SET @oShippingTargetPeriodId = SCOPE_IDENTITY() END ");

                            var values = result.Select("Column3 = '" + dr[2].ToString() + "' and Column1='" + dr[0].ToString() + "'");
                            foreach (DataRow drgrade in grades.Rows)
                            {

                                double upper = 0;
                                double target = 0;
                                double lower = 0;


                                AddUpdateSQL(sb, Int32.Parse(drgrade[0].ToString()), Convert.ToDouble(values[0][drgrade["Grade_Name"].ToString()]), Convert.ToDouble(values[1][drgrade["Grade_Name"].ToString()]), Convert.ToDouble(values[2][drgrade["Grade_Name"].ToString()]));
                            }
                            //Insert Oversize and Undersize
                            AddUpdateSQL(sb, -1, Convert.ToDouble(values[0]["Oversize"]), Convert.ToDouble(values[1]["Oversize"]), 0);
                            AddUpdateSQL(sb, -2, Convert.ToDouble(values[0]["Undersize"]), Convert.ToDouble(values[1]["Undersize"]), 0);

                            //AddUpdateSQL(sb, -1, Convert.ToDouble(values[0]["Undersize"]), Convert.ToDouble(values[0]["Oversize"]), 0);
                            //AddUpdateSQL(sb, -2, Convert.ToDouble(values[1]["Undersize"]), Convert.ToDouble(values[1]["Oversize"]), 0);

                            sb.Append(" SET @oShippingTargetPeriodId = NULL ");
                            //System.IO.File.WriteAllText(Server.MapPath("~/Uploads/Output.sql"), sb.ToString());
                        }
                        else // inserts into DB
                        {
                            // insert shipping target, to get ID
                            SqlCommand cmd = new SqlCommand();
                            SqlConnection conn = new System.Data.SqlClient.SqlConnection(ConfigurationManager.ConnectionStrings["conn"].ToString());
                            cmd.CommandType = System.Data.CommandType.StoredProcedure;
                            SqlParameter outputIdParam = new SqlParameter("@oShippingTargetPeriodId", SqlDbType.Int);
                            cmd.CommandText = "dbo.AddBhpbioShippingTarget";
                            cmd.Parameters.AddWithValue("@iProductTypeId", Convert.ToInt32(prodtypes.Find(x => x.ProductTypeCode == dr[2].ToString()).ProductTypeID));
                            cmd.Parameters.AddWithValue("@iEffectiveFromDateTime", DateTime.Parse(dr[0].ToString()));
                            cmd.Parameters.AddWithValue("@iUserId", 740);
                            //SqlParameter outPutParameter = new SqlParameter();
                            //outPutParameter.ParameterName = "oShippingTargetPeriodId";
                            outputIdParam.SqlDbType = System.Data.SqlDbType.Int;
                            outputIdParam.Direction = System.Data.ParameterDirection.Output;
                            cmd.Parameters.Add(outputIdParam);
                            cmd.Connection = conn;
                            conn.Open();
                            cmd.ExecuteNonQuery();
                            ShippingTargetID = Convert.ToInt32(outputIdParam.Value);
                            conn.Close();

                            /////////////////////////
                            // Gets rows and add values
                            var values = result.Select("Column3 = '" + dr[2].ToString() + "' and Column1='" + dr[0].ToString() + "'");
                            foreach (DataRow drgrade in grades.Rows)
                            {

                                double upper = 0;
                                double target = 0;
                                double lower = 0;

                                AddUpdate(ShippingTargetID, Int32.Parse(drgrade[0].ToString()), Convert.ToDouble(values[0][drgrade["Grade_Name"].ToString()]), Convert.ToDouble(values[1][drgrade["Grade_Name"].ToString()]), Convert.ToDouble(values[2][drgrade["Grade_Name"].ToString()]));
                            }
                            //Insert Oversize and Undersize
                            AddUpdate(ShippingTargetID, -1, Convert.ToDouble(values[0]["Undersize"]), Convert.ToDouble(values[0]["Oversize"]), 0);
                            AddUpdate(ShippingTargetID, -2, Convert.ToDouble(values[1]["Undersize"]), Convert.ToDouble(values[1]["Oversize"]), 0);
                        }

                    }
                }

                if (Request["chkSQL"] != null)
                {
                    System.IO.File.WriteAllText(Server.MapPath("~/Uploads/Output.sql"), sb.ToString());
                    Success("SQL File exported to the 'Uploads' folder ", true);
                }
                else
                {
                    Success("Shipping Targets imported!", true);
                }
                
                
                string.Format("{0}/{1}", Server.MapPath("~/Uploads"), Path.GetFileName(Request.Files["FileUpload1"].FileName));

            }
            

            return View("Index");

        }

        private void AddUpdate(int id, int attributeid, double upper, double target, double lower)
        {
            SqlCommand cmd = new SqlCommand();
            SqlConnection conn = new System.Data.SqlClient.SqlConnection(ConfigurationManager.ConnectionStrings["conn"].ToString());
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.CommandText = "dbo.AddOrUpdateBhpbioShippingTargetValue";
            cmd.Parameters.AddWithValue("@iShippingTargetPeriodId", id);
            cmd.Parameters.AddWithValue("@iAttributeId", attributeid);
            cmd.Parameters.AddWithValue("@iUpperControl", upper);
            cmd.Parameters.AddWithValue("@iTarget", target);
            cmd.Parameters.AddWithValue("@iLowerControl", lower);
            cmd.Connection = conn;
            conn.Open();
            cmd.ExecuteNonQuery();
            conn.Close();
        }
        private void AddUpdateSQL(StringBuilder sb, int attributeid, double upper, double target, double lower)
        {

            sb.Append( Environment.NewLine+ " IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) "+Environment.NewLine+" BEGIN " + Environment.NewLine);



            sb.Append("    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId ="+ attributeid + ") "+Environment.NewLine+" BEGIN "+Environment.NewLine+"     UPDATE BhpbioShippingTargetPeriodValue" +Environment.NewLine);
            sb.Append("     SET UpperControl = "+upper+", ");
            sb.Append("[Target] = "+target+", ");
            sb.Append("LowerControl = " + lower + Environment.NewLine+ "     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = "+ attributeid + " "+Environment.NewLine+" END "+Environment.NewLine+" ELSE "+Environment.NewLine+" BEGIN " + Environment.NewLine);
            sb.Append( "    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) ");
            sb.Append(Environment.NewLine+ "     VALUES (@oShippingTargetPeriodId, "+attributeid+" , "+upper+", "+target+", "+lower+") END "+Environment.NewLine+" END ");





            //sb.Append(" IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =" + attributeid + ") BEGIN UPDATE BhpbioShippingTargetPeriodValue");
            //sb.Append(" SET UpperControl = " + upper + ", ");
            //sb.Append("[Target] = " + target + ", ");
            //sb.Append("LowerControl = " + lower + " WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = " + attributeid + " END ELSE BEGIN ");
            //sb.Append("INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) ");
            //sb.Append(" VALUES (@oShippingTargetPeriodId, " + attributeid + " , " + upper + ", " + target + ", " + lower + ") END  ");
        }

        private DataTable GetGrades()
        {
            DataTable table = new DataTable();
            using (var con = new SqlConnection(ConfigurationManager.ConnectionStrings["conn"].ConnectionString))
            using (var cmd = new SqlCommand("select * from grade where is_visible =1", con))
            using (var da = new SqlDataAdapter(cmd))
            {
                cmd.CommandType = CommandType.Text;
                da.Fill(table);
            }
            return table;
        }


        private List<ProductTypeClass> GetProductTypeIds()
        {
            DataTable table = new DataTable();
            using (var con = new SqlConnection(ConfigurationManager.ConnectionStrings["conn"].ConnectionString))
            using (var cmd = new SqlCommand("select * from BhpbioProductType", con))
            using (var da = new SqlDataAdapter(cmd))
            {
                cmd.CommandType = CommandType.Text;
                da.Fill(table);
            }
            List<ProductTypeClass> productTypes = new List<ProductTypeClass>();
            foreach (DataRow dr in table.Rows)
            {
                ProductTypeClass objProductTypeClass = new ProductTypeClass();
                objProductTypeClass.ProductTypeCode = dr["ProductTypeCode"].ToString();
                objProductTypeClass.ProductTypeID = dr["ProductTypeId"].ToString();
                productTypes.Add(objProductTypeClass);
            }
            return productTypes;
        }


    }
}