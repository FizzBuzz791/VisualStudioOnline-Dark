
Alter Table dbo.BhpbioPortBalance
Drop Constraint UQ_BhpbioPortBalance_Candidate
Go

Alter Table dbo.BhpbioPortBalance
Add Constraint UQ_BhpbioPortBalance_Candidate Unique NonClustered (HubLocationId, BalanceDate, [Product], ProductSize)
Go
