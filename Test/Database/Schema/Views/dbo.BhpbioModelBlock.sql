--
-- At WAIO there is a special model, know as the Grade Control with STGM model. This model
-- has no actual records associated with it in the Model data tables, although there is a 
-- record for it in dbo.BlockModel. 
--
-- The data for this model is the same as the Grade Control model, but any blocks that don't
-- have STGM data are excluded. This view returns the ModelBlock table with the appropriate set
-- of Model Blocks for the GC w STGM model. NOTE that this means that the same Model Block Ids
-- will be in the table more than once, with different Block Model Ids
--
-- Previously this generation of the 'Virtual' model was done in each procedure that needed it
-- but it is much better to extract this into a view, than can be used more universally
--
IF Object_Id('dbo.BhpbioModelBlock') IS NOT NULL
	DROP VIEW dbo.BhpbioModelBlock
GO

CREATE VIEW [dbo].[BhpbioModelBlock]
AS

SELECT 
	mb.Model_Block_Id,
	bm.Block_Model_Id,
	mb.X,
	mb.Y,
	mb.Z,
	mb.Code,
	mb.X_Inc,
	mb.Y_Inc,
	mb.Z_inc
FROM ModelBlock mb
	INNER JOIN BlockModel bm
		ON mb.Block_Model_Id = (Case When bm.Block_Model_Type_Id = 1 Then 1 Else bm.Block_Model_Id End)
	LEFT JOIN ModelBlock mbs
		ON mbs.Code = mb.Code
			and mbs.Block_Model_Id = 4 -- STGM
WHERE bm.Block_Model_Id <> 5 -- GC w/ STGM
	-- if it is the GC w STGM model, then we only want to return the record
	-- if there is a corresponding STGM record
	OR (bm.Block_Model_Id = 5 And mbs.Model_Block_Id Is Not Null)






