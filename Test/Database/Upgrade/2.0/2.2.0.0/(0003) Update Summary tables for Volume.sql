-- WREC-275: Now we have to summarize volume, we will need a field for it in the main entry table
-- it could also go in as a grade, but it is best to be consistent with the way it works in the live 
-- data
Alter Table dbo.BhpbioSummaryEntry
Add Volume Float Null
Go