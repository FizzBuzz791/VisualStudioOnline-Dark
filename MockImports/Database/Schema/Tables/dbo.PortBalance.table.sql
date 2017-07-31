CREATE TABLE [dbo].[PortBalance]
(
	PortBalanceId int not null identity(1,1),
	Hub varchar(31) null,
	BalanceDate smalldatetime null,
	Tonnes decimal(18,4),
	SourceProduct varchar(30) null,
	TargetProduct varchar(30) null,
	ProductSize varchar(5) null,

CONSTRAINT [PK_PortBalance] PRIMARY KEY CLUSTERED
(
	PortBalanceId ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO