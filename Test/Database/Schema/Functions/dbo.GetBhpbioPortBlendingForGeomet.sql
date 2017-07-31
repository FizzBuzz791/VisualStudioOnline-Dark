IF OBJECT_ID('dbo.GetBhpbioPortBlendingForGeomet') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioPortBlendingForGeomet
Go 

CREATE FUNCTION dbo.GetBhpbioPortBlendingForGeomet(@iDateFrom Datetime, @iDateTo Datetime)
RETURNS @PortBlending table (
	[BhpbioPortBlendingId] int,
	[SourceHubLocationId] int,
	[DestinationHubLocationId] int,
	[LoadSiteLocationId] int,
	[StartDate] datetime,
	[EndDate] datetime,
	[SourceProductSize] varchar(32),
	[DestinationProductSize] varchar(32),
	[SourceProduct] varchar(32),
	[DestinationProduct] varchar(32),
	[Tonnes] FLOAT,
	[GeometMovementType] varchar(32)
)
BEGIN

	Insert Into @PortBlending
		select 
			*,
			CASE 
				WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'LUMP' And DestinationProductSize = 'FINES' THEN 'I'
				WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'FINES' And DestinationProductSize = 'LUMP' THEN 'NI'
				WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize = DestinationProductSize THEN 'NI'
				WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize <> DestinationProductSize THEN 'MIX'
				ELSE 'UNKNOWN'
			END 
		from dbo.BhpbioPortBlending
		where sourceproductsize is not null
			and destinationproductsize is not null
			and StartDate >= @iDateFrom
			and EndDate <= DateAdd(second, -1, DateAdd(DAY, 1, @iDateTo))

	Insert Into @PortBlending
		Select 
			BhpbioPortBlendingId,
			SourceHubLocationId,
			SourceHubLocationId as DestinationHubLocationId,
			LoadSiteLocationId,
			StartDate,
			EndDate,
			SourceProductSize,
			DestinationProductSize,
			SourceProduct,
			DestinationProduct,
			Tonnes,
			'I' as GeometMovementType
		From @PortBlending pb
		Where pb.GeometMovementType = 'MIX'

	Insert Into @PortBlending
		Select 
			BhpbioPortBlendingId,
			SourceHubLocationId,
			DestinationHubLocationId,
			LoadSiteLocationId,
			StartDate,
			EndDate,
			DestinationProductSize as SourceProductSize,
			DestinationProductSize,
			SourceProduct,
			DestinationProduct,
			Tonnes,
			'NI' as GeometMovementType
		From @PortBlending pb
		Where pb.GeometMovementType = 'MIX'

	delete from @PortBlending
	where GeometMovementType = 'MIX'

	update @PortBlending
		set GeometMovementType = (CASE 
			WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'LUMP' And DestinationProductSize = 'FINES' THEN 'I'
			WHEN SourceHubLocationId = DestinationHubLocationId AND SourceProductSize = 'FINES' And DestinationProductSize = 'LUMP' THEN 'NI'
			WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize = DestinationProductSize THEN 'NI'
			WHEN SourceHubLocationId <> DestinationHubLocationId AND SourceProductSize <> DestinationProductSize THEN 'MIX'
			ELSE 'UNKNOWN'
		END)

	RETURN
END
GO

--select * from dbo.GetBhpbioReportHighGrade()