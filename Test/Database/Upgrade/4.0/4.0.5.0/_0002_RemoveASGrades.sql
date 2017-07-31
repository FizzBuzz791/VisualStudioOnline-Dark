DELETE seg
FROM 
Staging.StageBlockModel sbm 
INNER JOIN Staging.StageBlockModelGrade seg ON seg.BlockModelId = sbm.BlockModelId
WHERE sbm.LumpPercentAsShipped IS NULL
	AND seg.GeometType = 'As-Shipped'