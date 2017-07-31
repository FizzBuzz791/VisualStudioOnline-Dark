UPDATE se
SET se.Volume = NULL
FROM BhpbioSummaryEntry se
INNER JOIN BhpbioSummaryEntryType ste ON ste.SummaryEntryTypeId= se.SummaryEntryTypeId
WHERE se.GeometType IN ('As-Dropped', 'As-Shipped')
AND Volume Is NOT NULL
AND ste.AssociatedBlockModelId IS NOT NULL
GO