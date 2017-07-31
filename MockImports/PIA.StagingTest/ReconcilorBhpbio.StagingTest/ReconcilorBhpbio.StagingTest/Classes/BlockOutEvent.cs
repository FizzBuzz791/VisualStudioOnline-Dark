using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Linq;
using System.Xml.Linq;

namespace ReconcilorBhpbio.StagingTest
{
    public partial class BlockOutEvent
    {
        public static BlockOutEvent FromFile(string path)
        {
            string data = System.IO.File.ReadAllText(path);
            XDocument xml = XDocument.Parse(data);
            return new BlockOutEvent(xml);
        }

        public BlockOutEvent(XDocument document)
            : this(document.Root)
        {
        }

        public BlockOutEvent(XElement element)
        {
            this.Timestamp = DateTime.Parse(element.Element("Timestamp").Value);
            this.IsReblockOut = Convert.ToBoolean(element.Element("IsReblockOut").Value);
            this.ResponsibleUserName = element.Element("ResponsibleUserName").Value;

            this.SourceModelDetail = new SourceModelDescriptorType(element.Element("SourceModelDetail"));
            
            this.PatternDetail = new PatternType(element.Element("PatternDetail"));
            this.PatternDetail.BlockOut = this;
        }

        public DateTime Timestamp { get; set; }
        public bool IsReblockOut { get; set; }
        public string ResponsibleUserName { get; set; }
        public SourceModelDescriptorType SourceModelDetail { get; set; }
        public PatternType PatternDetail { get; set; }
    }

    public partial class SourceModelDescriptorType
    {
        public SourceModelDescriptorType(XElement element)
        {
            this.ModelFile = element.Element("ModelFile").Value;
            this.ModelType = element.Element("ModelType").Value;
        }

        public string ModelFile { get; set; }
        public string ModelType { get; set; }
    }

    public partial class PatternType
    {
        public PatternType(XElement element)
        {
            this.PatternNumber = element.Element("PatternNumber").Value;
            this.Name = element.Element("Name").Value;
            this.SiteId = element.Element("SiteId").Value;
            this.OrebodyId = element.Element("OrebodyId").Value;
            this.PitId_Log = element.Element("PitId_Log").Value;
            this.PitId_Phy = element.Element("PitId_Phy").Value;
            this.PitId_MQ2 = element.Element("PitId_MQ2").Value;
            this.PushbackId = element.Element("Bench").Value;
            this.Bench = element.Element("Bench").Value;
            this.ExternalLocationID = element.Element("ExternalLocationID").Value;
            this.PatternGUID = element.Element("PatternGUID").Value;
            this.DateCreated = Convert.ToDateTime(element.Element("DateCreated").Value);
            this.DateAccepted = Convert.ToDateTime(element.Element("DateAccepted").Value);
            this.AcceptedByUserName = element.Element("AcceptedByUserName").Value;
            this.ApprovedByUserName = element.Element("ApprovedByUserName").Value;

            this.Blocks = element.Elements("Block").Select(a => new BlockType(a) { Pattern = this }).ToList();
        }

        public BlockOutEvent BlockOut { get; set; } // parent reference
        
        public string PatternNumber { get; set; }
        public string Name { get; set; }
        public string SiteId { get; set; }
        public string OrebodyId { get; set; }
        public string PitId_Log { get; set; }
        public string PitId_Phy { get; set; }
        public string PitId_MQ2 { get; set; }
        public string PushbackId { get; set; }
        public string Bench { get; set; }
        public string ExternalLocationID { get; set; }
        public string PatternGUID { get; set; }
        public DateTime DateCreated { get; set; }
        public DateTime DateAccepted { get; set; }
        public string AcceptedByUserName { get; set; }
        public string ApprovedByUserName { get; set; }

        public List<BlockType> Blocks { get; set; } // XMl "Block"
    }

    public partial class BlockType
    {
        public BlockType(XElement element)
        {
            this.Name = element.Element("Name").Value;
            this.BlockGUID = element.Element("BlockGUID").Value;
            this.BlockNumber = Convert.ToInt32(element.Element("BlockNumber").Value);
            this.GeoType = element.Element("GeoType").Value;
            this.DateBlasted = Convert.ToDateTime(element.Element("DateBlasted").Value);
            this.DateBlocked = Convert.ToDateTime(element.Element("DateBlocked").Value);
            this.Stratigraphy = element.Element("Stratigraphy").Value;
            this.StratNum = element.Element("StratNum").Value;
            this.ChangeState = element.Element("ChangeState").Value;

            if (this.ChangeState.ToUpper() != "DELETE")
            {
                this.Centroid = new MiningPointType(element.Element("Centroid"));
                this.ModelBlocks = element.Elements("ModelBlock").Select(a => new ModelBlockType(a) { Block = this } ).ToList();
                this.PolygonPoints = element.Elements("PolygonPoint").Select(a => new MiningPointType(a) { Block = this }).ToList();
            }
        }

        public PatternType Pattern { get; set; } // parent reference

        public string Name { get; set; }
        public string BlockGUID { get; set; }
        public int BlockNumber { get; set; }
        public string GeoType { get; set; }
        public DateTime DateBlasted { get; set; }
        public DateTime DateBlocked { get; set; }
        public string Stratigraphy { get; set; }
        public string StratNum { get; set; }
        public string ChangeState { get; set; }

        public List<ModelBlockType> ModelBlocks { get; set; } // XML: ModelBlock
        public MiningPointType Centroid { get; set; }
        public List<MiningPointType> PolygonPoints { get; set; } // XML: PolygonPoint

        public string BlockFullName
        {
            get
            {
                return String.Format("{0}-{1}-{2}-{3}", this.Pattern.PitId_MQ2, this.Pattern.Bench, this.Pattern.Name, this.Name);
            }
        }
    }

    public partial class MiningPointType
    {
        public MiningPointType(XElement element)
        {
            this.PointNumber = Convert.ToInt32(element.Element("PointNumber").Value);
            this.Easting = Convert.ToDouble(element.Element("Easting").Value);
            this.Northing = Convert.ToDouble(element.Element("Northing").Value);
            this.ToeRL = Convert.ToDouble(element.Element("ToeRL").Value);
        }
        
        public BlockType Block { get; set; } // parent reference

        public int PointNumber { get; set; }
        public double Easting { get; set; }
        public double Northing { get; set; }
        public double ToeRL { get; set; }
    }

    public partial class ModelBlockType
    {
        public ModelBlockType(XElement element)
        {
            this.ModelType = element.Element("ModelType").Value;
            this.Tonnes = Convert.ToDouble(element.Element("Tonnes").Value);
            this.Volume = Convert.ToDouble(element.Element("Volume").Value);
            this.Density = Convert.ToDouble(element.Element("Density").Value);
            this.Designation = element.Element("Designation").Value;
            this.MaterialCode = element.Element("MaterialCode").Value;
            this.OreType = element.Element("OreType").Value;
            this.LastModifiedUserName = element.Element("LastModifiedUserName").Value;
            this.LastModifiedDateTime = Convert.ToDateTime(element.Element("LastModifiedDateTime").Value);

            this.GradeSet = element.Elements("GradeSet").Select(a => new GradeSetType(a)).ToList();
        }

        public BlockType Block { get; set; } // parent reference

        public string ModelType { get; set; }

        public double Tonnes { get; set; }
        public double Volume { get; set; }
        public double Density { get; set; }

        public string Designation { get; set; }
        public string MaterialCode { get; set; }
        public string OreType { get; set; }

        public string LastModifiedUserName { get; set; }
        public DateTime LastModifiedDateTime { get; set; }

        public List<GradeSetType> GradeSet { get; set; }
    }

    public partial class GradeSetType
    {
        public GradeSetType(XElement element)
        {
            this.GradeSetTypeName = element.Element("GradeSetType").Value;
            this.QualitySet = element.Elements("QualitySet").Select(a => new QualityType(a)).ToList();
        }

        public string GradeSetTypeName { get; set; } // XML: GradeSetType
        public List<QualityType> QualitySet { get; set; }
    }

    public partial class QualityType
    {
        public QualityType(XElement element)
        {
            this.QualityTypeName = element.Element("QualityType").Value;
            this.QualityTypeSplitPercentage = Convert.ToDouble(element.Element("QualityTypeSplitPercentage").Value);
            this.Analytes = element.Elements("Analytes").Select(a => new AnalyteType(a)).ToList();
        }

        public string QualityTypeName { get; set; } //XML: QualityType
        public double QualityTypeSplitPercentage { get; set; }
        public List<AnalyteType> Analytes { get; set; }
    }

    public partial class AnalyteType
    {
        public AnalyteType(XElement element)
        {
            this.AnalyteName = element.Element("AnalyteName").Value;
            this.Value = Convert.ToDouble(element.Element("Value").Value);
        }

        public string AnalyteName { get; set; }
        public double Value { get; set; }
    }

}

    


