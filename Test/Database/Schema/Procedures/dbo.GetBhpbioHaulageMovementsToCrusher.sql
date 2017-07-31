IF OBJECT_ID('dbo.GetBhpbioHaulageMovementsToCrusher') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioHaulageMovementsToCrusher
GO 
  
CREATE PROCEDURE dbo.GetBhpbioHaulageMovementsToCrusher
(
	@iLocationId Int,
	@iStartDate DateTime,
	@iEndDate DateTime,
	@iDateBreakdown Varchar(64)
)
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON 

	Select * From (
		(Select
			b.DateFrom,
			b.DateTo,
			IsNull(pl.Location_Id, s.Stockpile_Id) as LocationId, 
			IsNull(pl.Name, s.Stockpile_Name) as LocationName,
			Case
				When s.Stockpile_Id is not null Then 'Stockpile'
				Else 'Pit'
			End as LocationType,
			0 as Grade_Id,
			'Tonnes' as Grade_Name,
			100 as Grade_Value,
			Sum(Tonnes) as TotalTonnes
		From dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iStartDate, @iEndDate, 1) b
			inner join dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iStartDate ,@iEndDate) lb
				on b.DateFrom >= lb.IncludeStart 
					and b.DateTo <= lb.IncludeEnd
			inner join Haulage h
				on h.Haulage_Date between b.DateFrom and b.DateTo
			inner join Crusher c
				on c.Crusher_Id = h.Destination_Crusher_Id
			inner join CrusherLocation cl
				on cl.Crusher_Id = c.Crusher_Id
					and cl.Location_Id = lb.LocationId
			left join dbo.Stockpile AS s
				ON h.Source_Stockpile_Id = s.Stockpile_Id
			left join dbo.StockpileGroupStockpile AS sgs
				ON sgs.Stockpile_Id = s.Stockpile_Id
			left join dbo.BhpbioStockpileGroupDesignation AS sgd
				ON sgd.StockpileGroupId = sgs.Stockpile_Group_Id
			left join Digblock d
				on d.Digblock_Id = h.Source_Digblock_Id
			left join DigblockLocation dl
				on d.Digblock_Id = dl.Digblock_Id
			left join Location pl
				on pl.Location_Id = dbo.GetParentLocationByLocationType(dl.Location_Id, 'PIT', b.DateFrom)
			left join dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
				on xs.StockpileId = s.Stockpile_Id
		Where Destination_Crusher_Id is not null
			and h.Haulage_State_Id IN ('N', 'A')
			and xs.StockpileId is null
		Group by b.DateFrom, b.DateTo, s.Stockpile_Id, s.Stockpile_Name, pl.Location_Id, pl.Name)
	

		Union All 

		(Select
			b.DateFrom,
			b.DateTo,
			IsNull(pl.Location_Id, s.Stockpile_Id) as LocationId, 
			IsNull(pl.Name, s.Stockpile_Name) as LocationName,
			Case
				When s.Stockpile_Id is not null Then 'Stockpile'
				Else 'Pit'
			End as LocationType,
			g.Grade_Id,
			g.Grade_Name,
			SUM(h.Tonnes * hg.Grade_Value) / NULLIF(SUM(h.Tonnes), 0.0) as Grade_Value,
			Sum(Tonnes) as TotalTonnes
		From dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iStartDate, @iEndDate, 1) b
			inner join dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iStartDate ,@iEndDate) lb
				on b.DateFrom >= lb.IncludeStart 
					and b.DateTo <= lb.IncludeEnd
			inner join Haulage h
				on h.Haulage_Date between b.DateFrom and b.DateTo
			inner join HaulageGrade hg
				on hg.Haulage_Id = h.Haulage_Id
			left join Grade g
				on g.Grade_Id = hg.Grade_Id
			inner join Crusher c
				on c.Crusher_Id = h.Destination_Crusher_Id
			inner join CrusherLocation cl
				on cl.Crusher_Id = c.Crusher_Id
					and cl.Location_Id = lb.LocationId
			left join dbo.Stockpile AS s
				ON h.Source_Stockpile_Id = s.Stockpile_Id
			left join dbo.StockpileGroupStockpile AS sgs
				ON sgs.Stockpile_Id = s.Stockpile_Id
			left join dbo.BhpbioStockpileGroupDesignation AS sgd
				ON sgd.StockpileGroupId = sgs.Stockpile_Group_Id
			left join Digblock d
				on d.Digblock_Id = h.Source_Digblock_Id
			left join DigblockLocation dl
				on d.Digblock_Id = dl.Digblock_Id
			left join Location pl
				on pl.Location_Id = dbo.GetParentLocationByLocationType(dl.Location_Id, 'PIT', b.DateFrom)
			left join dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
				on xs.StockpileId = s.Stockpile_Id
		Where Destination_Crusher_Id is not null
			and h.Haulage_State_Id IN ('N', 'A')
			and xs.StockpileId is null
		Group by b.DateFrom, b.DateTo, s.Stockpile_Id, s.Stockpile_Name, pl.Location_Id, pl.Name, g.Grade_Name, g.Grade_Id
		)
	) a
	Order By DateFrom, LocationName,  Grade_Id

	

END 
GO

GRANT EXECUTE ON dbo.GetBhpbioHaulageMovementsToCrusher TO BhpbioGenericManager
GO
