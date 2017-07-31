-- ONLY RUN THIS SCRIPT IF REQUIRED
--
-- this will delete all existing Resource Classification data in the system
-- which is required to run the import script, it will apparently not run
-- correctly if there is other data already there for the locations being
-- imported
--

--DELETE FROM [dbo].[ModelBlockPartialValue]
--WHERE Model_Block_Partial_Field_Id LIKE 'Res%'
--GO

--DELETE FROM BhpbioSummaryEntryFieldValue
--GO
---- staging data
--DELETE FROM Staging.[StageBlockModelResourceClassification]
--GO
