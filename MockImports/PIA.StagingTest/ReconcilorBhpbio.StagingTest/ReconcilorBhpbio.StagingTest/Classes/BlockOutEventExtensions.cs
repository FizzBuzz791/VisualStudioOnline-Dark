using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

using System.IO;
using System.Data.Linq;
using ReconcilorBhpbio.StagingTest.Properties;
using ReconcilorBhpbio.StagingTest.Database;

namespace ReconcilorBhpbio.StagingTest
{

    public partial class BlockOutEvent
    {
        public string ChangeTypeId
        {
            get
            {
                return this.IsReblockOut ? "BLOCKOUT" : "REBLOCKOUT";
            }
        }
    }

    public partial class BlockType
    {
        public bool IsDelete
        {
            get
            {
                return this.ChangeState.ToUpper() == "DELETE";
            }
        }

        public bool IsInsert
        {
            get
            {
                return this.ChangeState.ToUpper() == "INSERT";
            }
        }

        public bool IsUpdate
        {
            get
            {
                return this.ChangeState.ToUpper() == "UPDATE";
            }
        }

        public StageBlock ToStageBlock()
        {

            var stageBlock = new StageBlock
            {
                BlockExternalSystemId = this.BlockGUID,
                BlockNumber = this.BlockNumber.ToString(),
                BlockName = this.Name,
                BlockFullName = this.BlockFullName,
                LithologyTypeName = this.GeoType,
                BlockedDate = this.DateBlocked,
                BlastedDate = this.DateBlasted,
                Site = this.Pattern.SiteId,
                Orebody = this.Pattern.OrebodyId,
                Pit = this.Pattern.PitId_Log,
                Bench = this.Pattern.Bench,
                PatternNumber = this.Pattern.PatternNumber,
                AlternativePitCode = this.Pattern.PitId_MQ2,
                CentroidX = this.Centroid.Easting,
                CentroidY = this.Centroid.Northing,
                CentroidZ = this.Centroid.ToeRL,
                LastMessageTimestamp = this.Pattern.BlockOut.Timestamp,

                StageBlockPoints = this.GetStageBlockPoints().ToEntitySet(),
                StageBlockModels = this.GetStageBlockModels().ToEntitySet()
            };

            return stageBlock;
        }

        public IEnumerable<StageBlockPoint> GetStageBlockPoints()
        {
            return this.PolygonPoints.Select(p => p.ToStageBlockPoint());
        }

        public IEnumerable<StageBlockModel> GetStageBlockModels()
        {
            return this.ModelBlocks.Select(m => m.ToStageBlockModel());
        }

        public ChangedDataEntry GetChangedDataEntry(bool includeChangeType = false)
        {
            var result = new ChangedDataEntry
            {
                ChangeAppliedDateTime = DateTime.Now,
                MessageTimestamp = this.Pattern.BlockOut.Timestamp,
                ChangeTypeId = "StageBlock",
                ChangedDataEntryRelatedKeyValues = new EntitySet<ChangedDataEntryRelatedKeyValue> {
                        new ChangedDataEntryRelatedKeyValue {  ChangeKeyId = "Site", TextValue = this.Pattern.SiteId },
                        new ChangedDataEntryRelatedKeyValue {  ChangeKeyId = "Pit", TextValue = this.Pattern.PitId_MQ2 },
                        new ChangedDataEntryRelatedKeyValue {  ChangeKeyId = "Bench", TextValue = this.Pattern.Bench },
                        new ChangedDataEntryRelatedKeyValue {  ChangeKeyId = "ExternalSystemId", TextValue = this.BlockGUID }
                    }
            };

            if (includeChangeType)
            {
                // this won't be coming through in production, but I think it is pretty useful for debugging, so we have the option of
                // adding it
                result.ChangedDataEntryRelatedKeyValues.Add(new ChangedDataEntryRelatedKeyValue
                {
                    ChangeKeyId = "_ChangeType",
                    TextValue = this.ChangeState.ToUpper()
                });
            }

            return result;
        }

    }

    public partial class MiningPointType
    {
        public StageBlockPoint ToStageBlockPoint()
        {
            return new StageBlockPoint
            {
                Number = this.PointNumber,
                BlockExternalSystemId = this.Block.BlockGUID,
                X = this.Easting,
                Y = this.Northing,
                Z = this.ToeRL
            };
        }
    }

    public partial class ModelBlockType
    {
        public StageBlockModel ToStageBlockModel()
        {
            return new StageBlockModel
            {
                BlockModelName = this.ModelType,
                MaterialTypeName = this.OreType,
                BlockExternalSystemId = this.Block.BlockGUID,

                OpeningVolume = this.Volume,
                OpeningDensity = this.Density,
                OpeningTonnes = this.Tonnes,

                LastModifiedUser = this.LastModifiedUserName,
                LastModifiedDate = this.LastModifiedDateTime,
                LumpPercent = (decimal?)this.LumpPercent,
                ModelFilename = this.Block.Pattern.BlockOut.SourceModelDetail.ModelFile,

                StageBlockModelGrades = this.GetStageBlockGrades().ToEntitySet()

            };
        }

        public GradeSetType InSituGrades
        {
            get
            {
                return this.GetGradeSetByType("in-situ");
            }
        }

        public GradeSetType AsShippedGrades
        {
            get
            {
                return this.GetGradeSetByType("as-shipped");
            }
        }

        public GradeSetType AsDroppedGrades
        {
            get
            {
                return this.GetGradeSetByType("as-dropped");
            }
        }

        public double? LumpPercent
        {
            get
            {
                if (this.AsShippedGrades != null && this.AsShippedGrades.HasQualityType("lump"))
                {
                    return this.AsShippedGrades.QualityTypeByName("Lump").QualityTypeSplitPercentage;
                }
                else
                {
                    return null;
                }

            }
        }

        public GradeSetType GetGradeSetByType(string gradeSetTypeName)
        {
            return this.GradeSet.FirstOrDefault(gs => gs.GradeSetTypeName.ToUpper() == gradeSetTypeName.ToUpper());
        }

        public List<StageBlockModelGrade> GetStageBlockGrades()
        {
            var result = new List<StageBlockModelGrade>();
            var gradeList = new string[] { "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O", "AD_H2O" };

            foreach (var grade in gradeList)
            {
                var gradeObject = this.InSituGrades.GetGradeValue("Head", grade);

                // just skip grades if they don't exist - don't insert a null record for this testing
                if (gradeObject == null)
                    continue;

                var blockGrade = new StageBlockModelGrade
                {
                    BlockExternalSystemId = this.Block.BlockGUID,
                    GradeName = grade,
                    GradeValue = gradeObject.Value
                };

                if (this.AsShippedGrades != null)
                {
                    blockGrade.LumpValue = this.AsShippedGrades.GetGradeValue("Lump", grade);
                    blockGrade.FinesValue = this.AsShippedGrades.GetGradeValue("Fines", grade);
                }

                result.Add(blockGrade);
            }

            return result;
        }
    }

    public partial class GradeSetType
    {

        // custom methods
        public bool HasQualityType(string qualityTypeName)
        {
            return this.QualitySet.Exists(q => q.QualityTypeName.ToUpper() == qualityTypeName.ToUpper());
        }

        public QualityType QualityTypeByName(string qualityTypeName)
        {
            return this.QualitySet.First(q => q.QualityTypeName.ToUpper() == qualityTypeName.ToUpper());
        }

        public List<AnalyteType> GradesFor(string qualityTypeName)
        {
            return this.QualityTypeByName(qualityTypeName).Analytes;
        }

        public AnalyteType GetGrade(string qualityTypeName, string gradeName)
        {
            if (this.HasQualityType(qualityTypeName))
            {
                return this.GradesFor(qualityTypeName).FirstOrDefault(g => g.AnalyteName.ToUpper() == gradeName.ToUpper());
            }
            else
            {
                return null;
            }
        }

        public double? GetGradeValue(string qualityTypeName, string gradeName)
        {
            var g = this.GetGrade(qualityTypeName, gradeName);
            return (g == null) ? null : (double?)g.Value;
        }


    }

    public static class EntityExtensions
    {
        // update a db stageblock record to match the XML block record. Don't worry about the
        // grades and so on, they will be updated separately
        public static StageBlock UpdateFromBlock(this StageBlock stageBlock, BlockType block)
        {
            if (stageBlock.BlockExternalSystemId != block.BlockGUID)
            {
                throw new Exception("Cannot update block - GUIDS do not match");
            }

            stageBlock.BlockNumber = block.BlockNumber.ToString();
            stageBlock.BlockName = block.Name;
            stageBlock.BlockFullName = block.BlockFullName;
            stageBlock.LithologyTypeName = block.GeoType;
            stageBlock.BlockedDate = block.DateBlocked;
            stageBlock.BlastedDate = block.DateBlasted;
            stageBlock.Site = block.Pattern.SiteId;
            stageBlock.Orebody = block.Pattern.OrebodyId;
            stageBlock.Pit = block.Pattern.PitId_Log;
            stageBlock.Bench = block.Pattern.Bench;
            stageBlock.PatternNumber = block.Pattern.PatternNumber;
            stageBlock.AlternativePitCode = block.Pattern.PitId_MQ2;
            stageBlock.CentroidX = block.Centroid.Easting;
            stageBlock.CentroidY = block.Centroid.Northing;
            stageBlock.CentroidZ = block.Centroid.ToeRL;
            stageBlock.LastMessageTimestamp = block.Pattern.BlockOut.Timestamp;

            return stageBlock;
        }

        public static StageBlock GetByGUID(this Table<StageBlock> table, string blockGUID)
        {
            return table.FirstOrDefault(b => b.BlockExternalSystemId.ToUpper() == blockGUID.ToUpper());
        }

        public static void DeleteOnSubmitWithChildren(this Table<StageBlock> table, StageBlock block)
        {
            var db = (ReconcilorDataContext)table.Context;

            if (block != null && db != null)
            {
                foreach (var m in block.StageBlockModels)
                {
                    db.StageBlockModelGrades.DeleteAllOnSubmit(m.StageBlockModelGrades);
                }

                db.StageBlockPoints.DeleteAllOnSubmit(block.StageBlockPoints);
                db.StageBlockModels.DeleteAllOnSubmit(block.StageBlockModels);
                db.StageBlocks.DeleteOnSubmit(block);
            }
        }

        public static EntitySet<T> ToEntitySet<T>(this IEnumerable<T> source) where T : class
        {
            var es = new EntitySet<T>();
            es.AddRange(source);
            return es;
        }
    }
}
