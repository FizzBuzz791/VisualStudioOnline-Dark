using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using System.Configuration;
using System.Xml.Linq;
using MockImportDAL.SqlDal;

namespace GenerateBlastholesData
{
    class Program
    {
        public static string BlastholesDataFile = @"D:\\Snowden\\WAIO\\'Phase 2' enhancements\\Blastholes Feb 2014.xml";

        public static string ConnectionString = "Data Source=Reconcilor2\\SQL2008R2;Database=ReconcilorImportMockWS;User Id=ReconcilorUI;Password=Vap0rware";

        public static DateTime CurrentDate = new DateTime(2014, 2, 1);//this will be LastModifiedDate in dbo.Blocks and is used to retrieve blocks via web service (i.e. LastModifiedDate between startDate and endDate)
        public static int NoOfRecords = 0;

        static void Main(string[] args)
        {
            Console.WriteLine("-------------------Start---------------------");

            var connection = new SqlDalBlock(ConnectionString);

            XDocument xdoc = XDocument.Load(BlastholesDataFile);

            var blockList = xdoc.Descendants("Block");

            Console.WriteLine(string.Format("Going to process {0} blocks", blockList.Count()));

            foreach (XContainer xBlock in blockList)
            {
                ProcessBlock(xBlock, connection);
                NoOfRecords++;
            }

            connection.Dispose();

            Console.WriteLine("----------Finished processing blocks--------");
            Console.ReadLine();
        }

        public static void ProcessBlock(XContainer xBlock, SqlDalBlock connection)
        {
            Block block = new Block(connection);

            block.number = xBlock.Element("Number").Value;
            block.name = xBlock.Element("Name").Value;
            block.geoType = xBlock.Descendants("GeoType").Count() > 0 ? xBlock.Element("GeoType").Value : null;
            block.mq2PitCode = xBlock.Element("MQ2PitCode").Value;
            block.blockedDate = Convert.ToDateTime(xBlock.Element("BlockedDate").Value);
            block.blastedDate = Convert.ToDateTime(xBlock.Element("BlastedDate").Value);
            if (NoOfRecords == 100)
            {
                //every hundred records increment date by one day: this is such that import only gets a subset of all available data for one month
                CurrentDate = CurrentDate.AddDays(1);
                NoOfRecords = 0;
            }
            block.lastModifiedDate = CurrentDate;

            XContainer xPattern = xBlock.Descendants("Pattern").First<XContainer>();
            block.patternSite = xPattern.Element("Site").Value;
            block.patternOrebody = xPattern.Element("Orebody").Value;
            block.patternPit = xPattern.Element("Pit").Value;
            block.patternBench = xPattern.Element("Bench").Value;
            block.patternNumber = xPattern.Element("Number").Value;

            var modelList = xBlock.Descendants("Model");

            foreach (var xModel in modelList)
            {
                ProcessModel(xModel, ref block);
            }

            ProcessPolygon(xBlock.Descendants("Polygon").First<XContainer>(), ref block);

            block.Save();
        }

        public static void ProcessModel(XContainer xModel, ref Block block)
        {
            Model model = new Model(block.connection);

            XElement elem = xModel.Element("Name");
            model.name = elem != null ? xModel.Element("Name").Value : "STGM";

            model.filename = xModel.Descendants("Filename").Count() > 0 ? xModel.Element("Filename").Value : null;
            model.oreType = xModel.Element("OreType").Value;
            model.volume = Convert.ToSingle(xModel.Element("Volume").Value);
            model.tonnes = Convert.ToSingle(xModel.Element("Tonnes").Value);
            model.density = Convert.ToSingle(xModel.Element("Density").Value);
            model.lastModifiedUser = xModel.Element("LastModifiedUser").Value;
            model.lastModifiedDate = Convert.ToDateTime(xModel.Element("LastModifiedDate").Value);

            var gradeList = xModel.Descendants("Grade");

            foreach (var xGrade in gradeList)
            {
                switch (xGrade.Element("Name").Value.ToUpper())
                {
                    case "FE":
                        model.fe = Convert.ToSingle(xGrade.Element("HeadValue").Value);
                        break;
                    case "P":
                        model.p = Convert.ToSingle(xGrade.Element("HeadValue").Value);
                        break;
                    case "SIO2":
                        model.siO2 = Convert.ToSingle(xGrade.Element("HeadValue").Value);
                        break;
                    case "AL2O3":
                        model.al2O3 = Convert.ToSingle(xGrade.Element("HeadValue").Value);
                        break;
                    case "LOI":
                        model.loi = Convert.ToSingle(xGrade.Element("HeadValue").Value);
                        break;
                    default:
                        break;
                }
            }

            block.models.Add(model);
        }

        public static void ProcessPolygon(XContainer xPolygon, ref Block block)
        {
            XContainer xCentroid = xPolygon.Descendants("Centroid").First<XContainer>();

            block.centroidEasting = Convert.ToSingle(xCentroid.Element("Easting").Value);
            block.centroidNorthing = Convert.ToSingle(xCentroid.Element("Northing").Value);
            block.centroidRl = Convert.ToSingle(xCentroid.Element("RL").Value);

            var pointList = xPolygon.Descendants("Point");

            foreach (var xPoint in pointList)
            {
                Point point = new Point(block.connection);
                point.number = xPoint.Element("Number").Value;
                point.easting = Convert.ToSingle(xPoint.Element("Easting").Value);
                point.northing = Convert.ToSingle(xPoint.Element("Northing").Value);
                point.rl = Convert.ToSingle(xPoint.Element("RL").Value);
                block.points.Add(point);
            }
        }

        public class Block
        {
            public DateTime blastedDate;
            public DateTime blockedDate;
            public string geoType;
            public DateTime lastModifiedDate;
            public string mq2PitCode;
            public string name;
            public string number;

            public string patternBench;
            public string patternNumber;
            public string patternOrebody;
            public string patternPit;
            public string patternSite;

            public Single centroidEasting;
            public Single centroidNorthing;
            public Single centroidRl;

            public List<Model> models = new List<Model>();

            public List<Point> points = new List<Point>();

            public SqlDalBlock connection;

            public Block(SqlDalBlock connection)
            {
                this.connection = connection;
            }

            public void Save()
            {
                if (blastedDate == DateTime.MinValue)
                {
                    blastedDate = blockedDate;
                }

                int polygonId;

                int blockId = connection.InsertBlock(blastedDate, blockedDate, geoType, lastModifiedDate, "Steve", mq2PitCode, name, number,
                    patternBench, patternNumber, patternOrebody, patternPit, patternSite, centroidEasting, centroidNorthing, centroidRl, out polygonId);

                foreach (Point point in this.points)
                {
                    point.Save(polygonId);
                }

                foreach (Model model in this.models)
                {
                    model.Save(blockId);
                }
            }
        }

        public class Model
        {
            public string name;
            public string filename;
            public string oreType;
            public Single volume;
            public Single tonnes;
            public Single density;
            public string lastModifiedUser;
            public DateTime lastModifiedDate;

            public Single fe;
            public Single p;
            public Single siO2;
            public Single al2O3;
            public Single loi;

            private SqlDalBlock connection;

            public Model(SqlDalBlock connection)
            {
                this.connection = connection;
            }

            public void Save(int blockId)
            {
                connection.InsertModel(blockId, name, filename, oreType, volume, tonnes, density, lastModifiedDate, lastModifiedUser, fe, p, siO2, al2O3, loi);
            }
        }

        public class Point
        {
            public string number;
            public Single easting;
            public Single northing;
            public Single rl;

            private SqlDalBlock connection;

            public Point(SqlDalBlock connection)
            {
                this.connection = connection;
            }

            public void Save(int polygonId)
            {
                string sql = string.Format("Insert Into dbo.Points (Number, PolygonId, Easting, Northing, RL) Values({0},{1},{2},{3},{4})",
                    this.number, polygonId, this.easting, this.northing, this.rl);

                connection.ExecuteSql(sql);
            }
        }
    }
}
