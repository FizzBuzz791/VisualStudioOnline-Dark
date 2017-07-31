ALTER TABLE BhpbioLocationStockpileConfiguration
ADD PromoteStockpilesFromDate DateTime NULL;
Go

INSERT INTO BhpbioLocationStockpileConfiguration (LocationId, ImageData, PromoteStockpiles, PromoteStockpilesFromDate)
VALUES (12, NULL, 1, '2012-10-01')
