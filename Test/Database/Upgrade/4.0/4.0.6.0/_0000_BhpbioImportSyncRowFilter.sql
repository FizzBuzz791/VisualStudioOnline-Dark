CREATE TABLE dbo.BhpbioImportSyncRowFilterData (
  FilterDataId int IDENTITY,
  ImportSyncRowId bigint NOT NULL,
  Hub varchar(31) NULL,
  Site varchar(31) NULL,
  Pit varchar(31) NULL,
  Bench varchar(31) NULL,
  PatternNumber varchar(31) NULL,
  BlockName varchar(31) NULL,
  TransactionMonth date NULL,
  CONSTRAINT PK_BhpbioImportSyncRowFilterData_FilterDataId PRIMARY KEY CLUSTERED (FilterDataId)
)
ON [PRIMARY]
GO