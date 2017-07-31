-- add approved month to location index to improve its usefulness
DROP INDEX BhpbioApprovalData.IX_BhpbioApprovalData_LocationId
CREATE NONCLUSTERED INDEX IX_BhpbioApprovalData_LocationId ON BhpbioApprovalData (LocationId, ApprovedMonth)