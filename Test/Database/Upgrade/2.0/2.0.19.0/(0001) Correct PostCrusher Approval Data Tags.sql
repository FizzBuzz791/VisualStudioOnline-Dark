DELETE BAD
FROM BhpbioApprovalData BAD
INNER JOIN BhpbioApprovalData BAD2
	ON BAD.LocationId = BAD2.LocationId
	AND BAD.ApprovedMonth = BAD2.ApprovedMonth
WHERE BAD.TagId = 'F3PostCrusherStockpileDelta'
AND BAD2.TagId = 'F25PostCrusherStockpileDelta'

UPDATE BhpbioApprovalData
SET TagId = 'F25PostCrusherStockpileDelta'
WHERE TagId = 'F3PostCrusherStockpileDelta'

DELETE 
FROM BhpbioReportDataTags
WHERE TagId = 'F3PostCrusherStockpileDelta'
