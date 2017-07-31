--To get Recalc to run.

Insert Into DigblockGrade
(Digblock_Id, Grade_Id, Grade_Value)
select Digblock_Id, 7 As Grade_Id, 0 As Grade_Value
From Digblock
Union All
select Digblock_Id, 8 As Grade_Id, 0 As Grade_Value
From Digblock
Union All
select Digblock_Id, 9 As Grade_Id, 0 As Grade_Value
From Digblock

INSERT INTO StockpileBuildComponentGrade
(Stockpile_Id, Build_Id, Component_Id, Grade_Id, Grade_Value)
Select Stockpile_Id, Build_Id, Component_Id, 7 As Grade_Id, 0 As Grade_Value
From StockpileBuildComponent
Union All
Select Stockpile_Id, Build_Id, Component_Id, 8 As Grade_Id, 0 As Grade_Value
From StockpileBuildComponent
Union All
Select Stockpile_Id, Build_Id, Component_Id, 9 As Grade_Id, 0 As Grade_Value
From StockpileBuildComponent

--reset recalc

delete from RecalcL1Queue
delete from RecalcL2Queue
go

declare @Enddate Datetime
Set @Enddate = getdate()

Exec dbo.RecalcL1RaisePeriod '2009-04-01', @Enddate
go
