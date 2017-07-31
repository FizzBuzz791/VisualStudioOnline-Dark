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
    class Program
    {
        static ReconcilorDataContext db = new ReconcilorDataContext();

        static void Main(string[] args)
        {


            Console.WriteLine(@"
-----------------------------------------------------------------------------------------
This test tool has been superceded due to a change in the integration mechanism used for P&IA.

Please use the Snowden.Reconcilor.BHPBIO.DataStaging.IntegrationTestConsole tool instead.

This can be found within the main solution.
-----------------------------------------------------------------------------------------");


            Console.ReadKey();
            return;


            // move into the set directory as the message list, so that the path referenecs work properly
            Directory.SetCurrentDirectory(Path.GetDirectoryName(Settings.Default.MessageListPath));

            db.Connection.Open(); // need to open manually, because we are using transactions
            
            // each line in the message file should be a filename for an xml file containing a single BlockOut message
            // We process and commit each message one by one
            foreach (string path in GetMessageList())
            {
                if (!File.Exists(path))
                {
                    Console.WriteLine("ERROR: Could not find '{0}'", path);
                    continue;
                }

                Console.WriteLine("Processing message '{0}'", path);
                ProcessMessage(path);
                Console.Write("\n");
            }
        }

        static void ProcessMessage(string path)
        {
            if (!File.Exists(Settings.Default.MessageListPath))
            {
                throw new Exception(String.Format("Could not find XML message at '{0}'", path));
            }

            var blockOut = BlockOutEvent.FromFile(path);

            using (db.Transaction = db.Connection.BeginTransaction())
            {

                ClearExistingData(blockOut);

                foreach (var block in blockOut.PatternDetail.Blocks)
                {
                    if (block.IsInsert)
                    {
                        // inserting is a simple case - we just need to create the objects and add them. See inside the 
                        // ToStageBlock method to see how the mapping happens between the XML BlockType and the Db StageBlock
                        // objects
                        db.StageBlocks.InsertOnSubmit(block.ToStageBlock());
                        Console.WriteLine("Inserting '{0}' ({1})", block.BlockFullName, block.BlockGUID);
                    }
                    else if (block.IsUpdate)
                    {
                        // Updates are a bit more complicated than inserts - we need to update the top level block
                        // record. We can't just delete an recreate it, because there might be other model records
                        // that have come in through the ReconInsertUpdate import that are dependent on it.
                        //
                        // Any models, grades and points that are getting updated would have been deleted in a 
                        // previous phase, so we don't need to worry about updating them - just creating them 
                        // again
                        var stageBlock = db.StageBlocks.GetByGUID(block.BlockGUID);
                        stageBlock.UpdateFromBlock(block);
                        stageBlock.StageBlockPoints.AddRange(block.GetStageBlockPoints());
                        stageBlock.StageBlockModels.AddRange(block.GetStageBlockModels());

                        Console.WriteLine("Updating '{0}' ({1})", block.BlockFullName, block.BlockGUID);
                    }
                    else if (block.IsDelete)
                    {
                        // actually the block is already deleted, but we print this out anyway
                        // for information
                        Console.WriteLine("Deleting '{0}' ({1})", block.BlockFullName, block.BlockGUID);
                    }

                    // once the block has been dealt with we need to create the relevant ChangedDataEntry. One of these
                    // needs to be created for each Block, along with a bunch of related Notes
                    db.ChangedDataEntries.InsertOnSubmit(block.GetChangedDataEntry());
                }

                db.SubmitChanges();
                db.Transaction.Commit();
            }

        }

        static void ClearExistingData(BlockOutEvent blockOut)
        {
            foreach (var block in blockOut.PatternDetail.Blocks)
            {
                var stageBlock = db.StageBlocks.GetByGUID(block.BlockGUID);

                if (block.IsInsert || block.IsDelete)
                {
                    // for blocks that are getting created or deleted, we just remove everything from the tables
                    // with that GUID. In production we would probably want to throw an exception for trying to insert
                    // a block that already exists, but in testing it makes things much easier just to clear everything
                    // out
                    db.StageBlocks.DeleteOnSubmitWithChildren(stageBlock);
                }
                else if (block.IsUpdate)
                {
                    // for updates we need to delete everything but the parent block records, as there will be
                    // other model dependent on it
                    // 
                    // start with the points as these are the easiest to get rid of
                    db.StageBlockPoints.DeleteAllOnSubmit(stageBlock.StageBlockPoints);

                    // now we want to get delete the model records (and their grades), but only those that are contained in the 
                    // xml, there might be others that come through the legacy interface that we need to work with
                    foreach (var modelBlock in block.ModelBlocks)
                    {
                        var stageModelBlock = db.StageBlockModels.FirstOrDefault(mb => 
                                mb.BlockExternalSystemId == block.BlockGUID &&
                                mb.BlockModelName == modelBlock.ModelType &&
                                mb.MaterialTypeName == modelBlock.OreType);

                        if (stageModelBlock != null)
                        {
                            db.StageBlockModelGrades.DeleteAllOnSubmit(stageModelBlock.StageBlockModelGrades);
                            db.StageBlockModels.DeleteOnSubmit(stageModelBlock);
                        }
                    }
                }
            }

            db.SubmitChanges();
        }

        static string[] GetMessageList()
        {
            if (!File.Exists(Settings.Default.MessageListPath))
            {
                throw new Exception(String.Format("Message list file does not exist at '{0}'", Settings.Default.MessageListPath));
            }
               
            // each line of the file is the path of a message, except lines that start with '#'
            // or blank lines
            return File.ReadAllLines(Settings.Default.MessageListPath).Where(f => !String.IsNullOrEmpty(f) && !f.Trim().StartsWith("#")).ToArray();
        }
    }


}
