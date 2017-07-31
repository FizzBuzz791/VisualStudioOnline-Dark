EXEC( 'ALTER AUTHORIZATION ON SCHEMA::Staging TO [dbo]' );
GO
GRANT EXECUTE ON Staging.DeleteRequiredImportJobs TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetChangedDataEntrySummaryForImportChangeTrigger TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetImportChangeTriggerRelatedKeyValueMappings TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetImportChangeTriggers TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.InsertRequiredImportJob TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.PivotTable TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.PurgeChangedDataRegister TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.LogMessage TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetBhpbioStagingModelBlocks TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetBhpbioStagingBlockId TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.GetBhpbioStagingBlockHoldingPitCode TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.DeleteBhpbioStageBlockPoints TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.DeleteBhpbioStageBlockModels TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.DeleteBhpbioStageBlock TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.AddOrUpdateBhpbioStageBlockIfLatest TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.AddBhpbioStageBlockPoint TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.AddBhpbioStageBlockModelGrade TO BhpbioGenericManager
GO
GRANT EXECUTE ON Staging.AddBhpbioStageBlockModel TO BhpbioGenericManager
GO