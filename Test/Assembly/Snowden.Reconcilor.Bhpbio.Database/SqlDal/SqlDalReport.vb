Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports System.IO
Imports Newtonsoft.Json
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal.JSONConverters

Namespace SqlDal

    Public Class SqlDalReport
        Inherits Core.Database.SqlDal.SqlDalReport
        Implements ISqlDalReport

        Public Property FileSystemRoot As String = Nothing
        Public ReadOnly Property ReportCacheMaxAge As Integer = -1

        Dim _dataTableConverter As BhpbioDataTableConverter = New BhpbioDataTableConverter()
        Dim _dataSetConverter As BhpbioDataSetConverter = New BhpbioDataSetConverter()

#Region " Constructors "
        Public Sub New()
            MyBase.New()
            Randomize()
        End Sub

        Public Sub New(ByVal connectionString As String)
            MyBase.New(connectionString)
            Randomize()

            Dim reportCacheMaxTime As Integer = -1
            Using _dalUtility As New SqlDalUtility(connectionString)
                reportCacheMaxTime = _dalUtility.GetReportCacheTimeoutPeriod
            End Using

            Me._ReportCacheMaxAge = reportCacheMaxTime
        End Sub

        Public Sub New(ByVal databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
            Randomize()

            Dim reportCacheMaxTime As Integer = -1
            Using _dalUtility As New SqlDalUtility(databaseConnection)
                reportCacheMaxTime = _dalUtility.GetReportCacheTimeoutPeriod
            End Using

            Me._ReportCacheMaxAge = reportCacheMaxTime
        End Sub

        Public Sub New(ByVal dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
            Randomize()

            Dim reportCacheMaxTime As Integer = -1
            Using _dalUtility As New SqlDalUtility(dataAccessConnection)
                reportCacheMaxTime = _dalUtility.GetReportCacheTimeoutPeriod
            End Using

            Me._ReportCacheMaxAge = reportCacheMaxTime
        End Sub
#End Region



        Public Function GetBhpbioModelComparisonReport(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal dateBreakdown As String,
         ByVal locationId As Int32, ByVal includeBlockModels As Int16,
         ByVal blockModels As String, ByVal includeActuals As Int16,
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean,
         ByVal tonnes As Int16, ByVal grades As String,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean,
         ByVal lumpFinesBreakdown As Boolean) As DataSet

            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioModelComparisonReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iDateBreakdown", CommandDataType.VarChar, CommandDirection.Input, 31, dateBreakdown)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iIncludeBlockModels", CommandDataType.Bit, CommandDirection.Input, includeBlockModels)
            DataAccess.ParameterCollection.Add("@iBlockModels", CommandDataType.VarChar, CommandDirection.Input, -1, blockModels)
            DataAccess.ParameterCollection.Add("@iIncludeActuals", CommandDataType.Bit, CommandDirection.Input, includeActuals)
            If (includeDesignationMaterialTypeId) Then
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", CommandDataType.Int, CommandDirection.Input, designationMaterialTypeId)
            Else
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", NullValues.Int32)
            End If
            DataAccess.ParameterCollection.Add("@iTonnes", CommandDataType.Bit, CommandDirection.Input, tonnes)
            DataAccess.ParameterCollection.Add("@iGrades", CommandDataType.VarChar, CommandDirection.Input, -1, grades)

            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            DataAccess.ParameterCollection.Add("@iIncludeLumpFinesBreakdown", CommandDataType.Bit, CommandDirection.Input, lumpFinesBreakdown)

            result = DataAccess.ExecuteDataSet()

            result.DataSetName = "Result"
            result.Tables(0).TableName = "Summary"
            result.Tables(1).TableName = "Graph"

            Return result
        End Function

        Public Function GetBhpbioGradeRecoveryReport(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal locationId As Int32, ByVal includeBlockModels As Int16,
         ByVal blockModels As String, ByVal includeActuals As Int16,
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean, ByVal tonnes As Int16,
         ByVal volume As Int16, ByVal grades As String,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean,
         ByVal lumpFinesBreakdown As Boolean) As DataSet

            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioGradeRecoveryReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iIncludeBlockModels", CommandDataType.Bit, CommandDirection.Input, includeBlockModels)
            DataAccess.ParameterCollection.Add("@iBlockModels", CommandDataType.VarChar, CommandDirection.Input, -1, blockModels)
            DataAccess.ParameterCollection.Add("@iIncludeActuals", CommandDataType.Bit, CommandDirection.Input, includeActuals)

            If (includeDesignationMaterialTypeId) Then
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", CommandDataType.Int, CommandDirection.Input, designationMaterialTypeId)
            Else
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", NullValues.Int32)
            End If

            DataAccess.ParameterCollection.Add("@iTonnes", CommandDataType.Bit, CommandDirection.Input, tonnes)
            DataAccess.ParameterCollection.Add("@iVolume", CommandDataType.Bit, CommandDirection.Input, volume)
            DataAccess.ParameterCollection.Add("@iGrades", CommandDataType.VarChar, CommandDirection.Input, -1, grades)

            AddDataInclusionParameters(includeLiveData, includeApprovedData)
            DataAccess.ParameterCollection.Add("@iLumpFinesBreakdown", CommandDataType.VarChar, CommandDirection.Input, -1, lumpFinesBreakdown)

            result = DataAccess.ExecuteDataSet()

            result.DataSetName = "Result"
            result.Tables(0).TableName = "Summary"
            result.Tables(1).TableName = "Graph"

            Return result
        End Function

        Public Function GetBhpbioMovementRecoveryReport(ByVal dateTo As DateTime, ByVal locationId As Int32,
         ByVal comparison1IsActual As Int16, ByVal comparison1BlockModelId As Int32,
         ByVal comparison2IsActual As Int16, ByVal comparison2BlockModelId As Int32,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As DataSet

            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioMovementRecoveryReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iComparison1IsActual", CommandDataType.Bit, CommandDirection.Input, comparison1IsActual)
            DataAccess.ParameterCollection.Add("@iComparison1BlockModelId", CommandDataType.Int, CommandDirection.Input, comparison1BlockModelId)
            DataAccess.ParameterCollection.Add("@iComparison2IsActual", CommandDataType.Bit, CommandDirection.Input, comparison2IsActual)
            DataAccess.ParameterCollection.Add("@iComparison2BlockModelId", CommandDataType.Int, CommandDirection.Input, comparison2BlockModelId)

            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            result = DataAccess.ExecuteDataSet()

            result.DataSetName = "Result"
            result.Tables(0).TableName = "Summary"
            result.Tables(1).TableName = "Graph"

            Return result
        End Function

        Public Function GetBhpbioRecoveryAnalysisReport(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal dateBreakdown As String, ByVal locationId As Int32, ByVal includeBlockModels As Int16,
         ByVal blockModels As String, ByVal includeActuals As Int16,
         ByVal designationMaterialTypeId As Int32, ByVal includeDesignationMaterialTypeId As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As DataSet

            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioRecoveryAnalysisReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iDateBreakdown", CommandDataType.VarChar, CommandDirection.Input, 31, dateBreakdown)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iIncludeBlockModels", CommandDataType.Bit, CommandDirection.Input, includeBlockModels)
            DataAccess.ParameterCollection.Add("@iBlockModels", CommandDataType.VarChar, CommandDirection.Input, blockModels)
            DataAccess.ParameterCollection.Add("@iIncludeActuals", CommandDataType.Bit, CommandDirection.Input, includeActuals)

            If (includeDesignationMaterialTypeId) Then
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", CommandDataType.Int, CommandDirection.Input, designationMaterialTypeId)
            Else
                DataAccess.ParameterCollection.Add("@iDesignationMaterialTypeId", NullValues.Int32)
            End If

            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            result = DataAccess.ExecuteDataSet()

            result.DataSetName = "Result"
            result.Tables(0).TableName = "Summary"
            result.Tables(1).TableName = "Graph"

            Return result
        End Function

        Public Function GetBhpbioPortBalance(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal locationId As Int32) As DataTable _
         Implements Bhpbio.Database.DalBaseObjects.IReport.GetBhpbioPortBalance

            DataAccess.CommandText = "dbo.GetBhpbioPortBalance"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioPortBlending(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal locationId As Int32) As DataTable _
         Implements Bhpbio.Database.DalBaseObjects.IReport.GetBhpbioPortBlending

            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioPortBlending"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

            result = DataAccess.ExecuteDataSet

            result.Tables(0).TableName = "Blending"
            result.Tables(1).TableName = "BlendingGrade"
            result.Tables(2).TableName = "Grade"

            result.Relations.Add("Blending_BlendingGrade",
             result.Tables("Blending").Columns("BhpbioPortBlendingId"),
             result.Tables("BlendingGrade").Columns("BhpbioPortBlendingId"))

            result.Relations.Add("Grade_BlendingGrade",
             result.Tables("Grade").Columns("GradeId"),
             result.Tables("BlendingGrade").Columns("GradeId"))

            Return Snowden.Common.Database.DataHelper.Pivot(result.Relations("Blending_BlendingGrade"),
             result.Relations("Grade_BlendingGrade"), "GradeName", "GradeValue", "OrderNo")
        End Function

        Public Function GetBhpbioShippingNomination(ByVal dateFrom As DateTime, ByVal dateTo As DateTime,
         ByVal locationId As Int32) As DataTable _
            Implements Bhpbio.Database.DalBaseObjects.IReport.GetBhpbioShippingNomination

            DataAccess.CommandText = "dbo.GetBhpbioShippingNomination"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

            Return DataAccess.ExecuteDataTable

        End Function

        Public Function GetBhpbioBlastByBlastReconciliation(ByVal blastLocationId As Int32) As DataSet
            Dim result As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioBlastByBlastReconciliation"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBlastLocationId", CommandDataType.Int, CommandDirection.Input, blastLocationId)

            result = DataAccess.ExecuteDataSet

            result.DataSetName = "Result"
            result.Tables(0).TableName = "SummaryComparison"
            result.Tables(1).TableName = "GradeComparison"

            Return result
        End Function

        Public Function GetBhpbioReportAttributeProperties() As DataTable
            DataAccess.CommandText = "dbo.GetBhpbioReportAttributeProperties"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioReportPatternValidationData(ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As DataTable

            DataAccess.CommandText = "dbo.GetBhpbioReportPatternValidationData"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioBlastblockDataExportReportForExcel(ByVal locationId As Int32, ByVal dateFrom As DateTime,
            ByVal dateTo As DateTime, ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As DataTable

            DataAccess.CommandText = "dbo.GetBhpbioBlastblockDataExportReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iStartMonth", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iEndMonth", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iIncludeLiveData", CommandDataType.Bit, CommandDirection.Input, includeLiveData)
            DataAccess.ParameterCollection.Add("@iIncludeApprovedData", CommandDataType.Bit, CommandDirection.Input, includeApprovedData)

            Return DataAccess.ExecuteDataTable
        End Function
        Public Function GetBhpbioBlastblockbyOreTypeDataExportReportForExcel(ByVal locationId As Int32, ByVal dateFrom As DateTime,
            ByVal dateTo As DateTime, ByVal includeLumpFines As Boolean, ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As DataTable

            DataAccess.CommandText = "dbo.GetBhpbioBlastblockbyOreTypeDataExportReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iStartMonth", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iEndMonth", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iIncludeLumpFines", CommandDataType.Bit, CommandDirection.Input, includeLumpFines)
            DataAccess.ParameterCollection.Add("@iIncludeLiveData", CommandDataType.Bit, CommandDirection.Input, includeLiveData)
            DataAccess.ParameterCollection.Add("@iIncludeApprovedData", CommandDataType.Bit, CommandDirection.Input, includeApprovedData)

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioSampleCoverageReport(ByVal locationId As Int32, ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal groupBy As String) As DataTable
            DataAccess.CommandText = "dbo.GetBhpbioSampleCoverageReport"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
            DataAccess.ParameterCollection.Add("@iGroupBy", CommandDataType.VarChar, CommandDirection.Input, groupBy)

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioWeightometerMovementSummaryForMonth(ByVal month As DateTime) As DataTable Implements IReport.GetBhpbioWeightometerMovementSummaryForMonth
            DataAccess.CommandText = "dbo.GetBhpbioWeightometerMovementSummaryForMonth"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)

            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioHaulageMovementsToCrusher(locationId As Integer, startDate As DateTime, endDate As DateTime, ByVal dateBreakdown As String) As DataTable Implements ISqlDalReport.GetBhpbioHaulageMovementsToCrusher
            DataAccess.CommandText = "dbo.GetBhpbioHaulageMovementsToCrusher"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
            DataAccess.ParameterCollection.Add("@iDateBreakdown", CommandDataType.VarChar, CommandDirection.Input, dateBreakdown)

            Return DataAccess.ExecuteDataTable
        End Function

#Region "Report F-Factor Helper Calls "
        Public Function GetBhpbioReportFactorProperties(ByVal locationId As Int32) As DataTable
            DataAccess.CommandText = "dbo.GetBhpbioReportFactorProperties"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

            Return DataAccess.ExecuteDataTable
        End Function
#End Region

#Region "Report F-Factor Data Calls"

        Private Sub SetupBhpbioReportDataProperties(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean)
            With DataAccess
                With .ParameterCollection
                    .Clear()

                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iDateBreakdown", CommandDataType.VarChar, CommandDirection.Input, 31, dateBreakdown)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iChildLocations", CommandDataType.Bit, CommandDirection.Input, childLocations)
                End With
            End With
        End Sub

        Private Function GetBhpbioReportDataSet() As System.Data.DataSet
            Dim ds As DataSet = Nothing
            Dim fileCache = New ReportFileCache(FileSystemRoot, ReportCacheMaxAge)
            fileCache.Filename = String.Format("{0}.txt", DataAccess.ToSHA1)

            If fileCache.IsCacheFileValid Then
                Try
                    'Need to use the Bhp converters as we need to store column details (name/type)
                    ds = JsonConvert.DeserializeObject(Of DataSet)(File.ReadAllText(fileCache.CacheFilePath), _dataSetConverter, _dataTableConverter)
                Catch ex As Exception
                    ' if reading the cache fails, just proceed as normal
                    Debug.Print("Could not read report cache: " + ex.Message)
                    ds = DataAccess.ExecuteDataSet
                End Try
            Else
                ds = DataAccess.ExecuteDataSet

                Try
                    ' could be that the cache file is not valid because we couldn't create the directory or something
                    ' in this case the file path will be null, so we don't want to bother trying to write the cache file
                    If fileCache.CacheFilePath IsNot Nothing AndAlso Not File.Exists(fileCache.CacheFilePath) Then
                        ds.Serialize(fileCache.CacheFilePathTemp)
                        fileCache.RenameTemp()
                    End If
                Catch ex As Exception
                    ' couldn't write to the cache? Don't want this to affect the report, so just write to the output
                    ' and move on
                    Debug.Print("Could not write to report cache: " + ex.Message)
                End Try

            End If

            If ds.Tables.Count > 0 Then
                ds.Tables(0).TableName = "Value"
                If ds.Tables.Count > 1 Then
                    ds.Tables(1).TableName = "Grade"
                End If
            End If

            Return ds
        End Function


        Public Function GetBhpbioReportDataHubPostCrusherStockpileDelta(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataSitePostCrusherStockpileDelta(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataActualBeneProduct(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualBeneProduct"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()

        End Function

        Public Function GetBhpbioReportDataActualExpitToStockpile(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualExpitToStockpile"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataBenchErrorByLocation(ByVal startDate As Date, ByVal endDate As Date,
                ByVal locationId As Int32,
                ByVal blockModelId1 As Int32, ByVal blockModelId2 As Int32, ByVal minimumTonnes As Double,
                ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean,
                ByVal designationMaterialTypeId As Integer,
                Optional ByVal groupOnSublocations As Boolean = True,
                Optional ByVal summarizeData As Boolean = False,
                Optional ByVal locationGrouping As String = Nothing
            ) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataBenchErrorByLocation"

            With DataAccess
                With .ParameterCollection
                    .Clear()
                    .Add("@DateFrom", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@DateTo", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@LocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@BlockModelId1", CommandDataType.Int, CommandDirection.Input, blockModelId1)
                    .Add("@BlockModelId2", CommandDataType.Int, CommandDirection.Input, blockModelId2)
                    .Add("@MinimumTonnes", CommandDataType.Float, CommandDirection.Input, minimumTonnes)
                    .Add("@GroupOnSublocations", CommandDataType.Bit, CommandDirection.Input, groupOnSublocations)
                    .Add("@SummarizeData", CommandDataType.Bit, CommandDirection.Input, summarizeData)
                    .Add("@DesignationMaterialTypeId", CommandDataType.Int, CommandDirection.Input, designationMaterialTypeId)
                    .Add("@LocationGrouping", CommandDataType.VarChar, CommandDirection.Input, locationGrouping)
                End With
            End With

            AddDataInclusionParameters(includeLiveData, includeApprovedData)
            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataActualDirectFeed(ByVal startDate As Date,
            ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
            ByVal childLocations As Boolean,
            ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualDirectFeed"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()

        End Function

        Public Function GetBhpbioReportDataOreForRail(ByVal startDate As Date, ByVal endDate As Date,
            ByVal dateBreakdown As String, ByVal locationId As Int32, ByVal childLocations As Boolean,
            ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataOreForRail"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataActualMineProduction(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualMineProduction"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataActualM(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualM"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataActualStockpileToCrusher(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataActualStockpileToCrusher"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataPortBlendedAdjustment(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataPortBlendedAdjustment"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataPortOreShipped(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataPortOreShipped"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        Public Function GetBhpbioReportDataPortStockpileDelta(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean,
         ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean) As System.Data.DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataPortStockpileDelta"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        ''' <summary>
        ''' Returns historical data for a period and location. Used by the reporting system.
        ''' </summary>
        Public Function GetBhpbioReportDataHistorical(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdown As String, ByVal locationId As Int32,
         ByVal childLocations As Boolean) As System.Data.DataSet
            DataAccess.CommandText = "dbo.GetBhpbioReportDataHistorical"
            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)
            Return GetBhpbioReportDataSet()
        End Function

        ''' <summary>
        ''' Returns block design data aggregated to the pattern level, and filtered by the blockout date
        ''' </summary>
        Public Function GetBhpbioReportDataBlockModelBlockOuts(ByVal startDate As Date, ByVal endDate As Date, ByVal locationId As Int32, Optional includeChildLocations As Boolean = False, Optional childLocationType As String = "BLAST") As System.Data.DataSet

            If childLocationType Is Nothing Then
                childLocationType = "PIT"
            End If

            DataAccess.CommandText = "dbo.GetBhpbioReportDataBlockModelBlockOuts"
            DataAccess.ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, 250, startDate)
            DataAccess.ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, endDate)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iChildLocations", CommandDataType.Bit, CommandDirection.Input, includeChildLocations)
            DataAccess.ParameterCollection.Add("@iOverrideChildLocationType", CommandDataType.VarChar, CommandDirection.Input, childLocationType)
            Return GetBhpbioReportDataSet()

        End Function

        Public Function GetBhpbioReportDataBlockModel(startDate As Date, endDate As Date, dateBreakdown As String, 
                                                      locationId As Int32, childLocations As Boolean, 
                                                      includeModelDataForInactiveLocations As Boolean, modelName As String, 
                                                      includeLiveData As Boolean, includeApprovedData As Boolean, 
                                                      dataOptions As ReportDataBlockModelOptions) As DataSet

            DataAccess.CommandText = "dbo.GetBhpbioReportDataBlockModel"
            If modelName Is Nothing Then
                modelName = NullValues.String
            End If

            SetupBhpbioReportDataProperties(startDate, endDate, dateBreakdown, locationId, childLocations)

            With DataAccess.ParameterCollection
                .Add("@iBlockModelName", CommandDataType.VarChar, CommandDirection.Input, 250, modelName)
                .Add("@iIncludeInactiveChildLocations", CommandDataType.Bit, CommandDirection.Input, includeModelDataForInactiveLocations)
                .Add("@iIncludeLumpFines", CommandDataType.Bit, CommandDirection.Input, dataOptions.IncludeLumpAndFines)
                .Add("@iHighGradeOnly", CommandDataType.Bit, CommandDirection.Input, dataOptions.HighGradeOnly)
                .Add("@iIncludeResourceClassification", CommandDataType.Bit, CommandDirection.Input, dataOptions.IncludeResourceClassification)
                .Add("@iUseRemainingMaterialAtDateFrom", CommandDataType.Bit, CommandDirection.Input, dataOptions.UseRemainingMaterialAtDateFrom)
                .Add("@iOverrideChildLocationType", CommandDataType.VarChar, CommandDirection.Input, 250, dataOptions.OverrideChildLocationType)
                .Add("@iGeometType", CommandDataType.VarChar, CommandDirection.Input, 63, dataOptions.GeometType)
                .Add("@iLowestStratLevel", CommandDataType.Int, CommandDirection.Input, dataOptions.LowestStratigraphyLevel)
                .Add("@iIncludeWeathering", CommandDataType.Bit, CommandDirection.Input, dataOptions.IncludeWeathering)
            End With

            AddDataInclusionParameters(includeLiveData, includeApprovedData)

            Return GetBhpbioReportDataSet()
        End Function

        ''' <summary>
        ''' Returns raw data based on a tag/CalcId. To be used by the Approval Review screen.
        ''' </summary>
        Public Function GetBhpbioReportDataReview(ByVal tagId As String, ByVal locationId As Int32?,
         ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal productSize As String) As DataTable
            Dim location As Int32

            If locationId.HasValue Then
                location = locationId.Value
            Else
                location = DoNotSetValues.Int32
            End If

            With DataAccess
                .CommandText = "dbo.GetBhpbioReportDataReview"

                With .ParameterCollection
                    .Clear()
                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, location)
                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, 63, tagId)
                    .Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, 5, productSize)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        ''' <summary>
        ''' Returns block model total's for the F1 figures. Used only in the Blast by Blast Recon Report.
        ''' </summary>
        Public Function GetBhpbioReportDataBlockModelTotal(ByVal locationId As Int32, ByVal allBlocks As Boolean) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportDataBlockModelTotal"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iAllBlocks", CommandDataType.Bit, CommandDirection.Input, Convert.ToInt16(allBlocks))
                End With

                Return .ExecuteDataTable
            End With
        End Function

        ''' <summary>
        ''' Returns a breakdown of the design tonnes under the given location by resource classification
        ''' </summary>
        Public Function GetBhpbioResourceClassificationByLocation(ByVal locationId As Int32, blockedDateFrom As DateTime, blockedDateTo As DateTime) As DataTable
            Return GetBhpbioResourceClassificationByLocation(locationId, blockedDateFrom, blockedDateFrom, blockedDateTo)
        End Function

        ''' <summary>
        ''' Returns a breakdown of the design tonnes under the given location by resource classification
        ''' </summary>
        Public Function GetBhpbioResourceClassificationByLocation(ByVal locationId As Int32, locationDateFrom As DateTime) As DataTable
            Return GetBhpbioResourceClassificationByLocation(locationId, locationDateFrom, Nothing, Nothing)
        End Function

        ''' <summary>
        ''' Returns a breakdown of the design tonnes under the given location by resource classification
        ''' </summary>
        Public Function GetBhpbioResourceClassificationByLocation(ByVal locationId As Int32, ByVal locationDateFrom As DateTime, blockedDateFrom As DateTime?, blockedDateTo As DateTime?) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioResourceClassificationByLocation"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iLocationDateFrom", CommandDataType.DateTime, CommandDirection.Input, locationDateFrom)
                    .Add("@iBlockedDateFrom", CommandDataType.DateTime, CommandDirection.Input, blockedDateFrom)
                    .Add("@iBlockedDateTo", CommandDataType.DateTime, CommandDirection.Input, blockedDateTo)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        ''' <summary>
        ''' Added parameters used to specify data inclusion options
        ''' </summary>
        ''' <param name="includeLiveData">if true, live data is to be included</param>
        ''' <param name="includeApprovedData">if true, approved data is to be included</param>
        ''' <remarks>This is a helper method used to initialise parameters for data inclusion</remarks>
        Private Sub AddDataInclusionParameters(ByVal includeLiveData As Boolean, ByVal includeApprovedData As Boolean)
            DataAccess.ParameterCollection.Add("@iIncludeLiveData", CommandDataType.Bit, CommandDirection.Input, includeLiveData)
            DataAccess.ParameterCollection.Add("@iIncludeApprovedData", CommandDataType.Bit, CommandDirection.Input, includeApprovedData)
        End Sub
#End Region

#Region "Core Report Calls"
        Public Function GetPotentialReportDataExceptions() As DataTable
            DataAccess.CommandText = "dbo.GetPotentialReportDataExceptions"
            DataAccess.ParameterCollection.Clear()
            Return DataAccess.ExecuteDataTable
        End Function

        Public Function GetBhpbioReportLocationBreakdownWithNames(ByVal locationId As Int32, ByVal getChildLocations As Boolean, ByVal lowestLocationTypeDescription As String, ByVal dateTime As DateTime) As DataTable

            With DataAccess
                .CommandText = "dbo.GetBhpbioReportLocationBreakdownWithNames"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iGetChildLocations", CommandDataType.Bit, CommandDirection.Input, getChildLocations)
                    .Add("@iLowestLocationTypeDescription", CommandDataType.VarChar, CommandDirection.Input, lowestLocationTypeDescription)
                    .Add("@iDateTime", CommandDataType.DateTime, CommandDirection.Input, dateTime)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioHaulageVsPlantReport(ByVal locationId As Int32?,
         ByVal dateFrom As DateTime?, ByVal dateTo As DateTime?) As DataTable

            With DataAccess
                .CommandText = "dbo.GetBhpbioHaulageVsPlantReport"

                With .ParameterCollection
                    .Clear()
                    .Add("@iFromDate", CommandDataType.DateTime, CommandDirection.Input, dateFrom.GetValueOrDefault(NullValues.DateTime))
                    .Add("@iToDate", CommandDataType.DateTime, CommandDirection.Input, dateTo.GetValueOrDefault(NullValues.DateTime))
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId.GetValueOrDefault(NullValues.Int32))
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioStockpileBalanceReport(ByVal locationId As Int32?,
         ByVal stockpileId As Int32?, ByVal startDate As DateTime?, ByVal startShift As Char?,
         ByVal endDate As DateTime?, ByVal endShift As Char?, ByVal isVisible As Boolean?) As DataTable
            Dim setinalIsVisible As Short

            setinalIsVisible = NullValues.Boolean
            If isVisible.HasValue Then
                setinalIsVisible = Convert.ToInt16(isVisible.Value)
            End If

            With DataAccess
                .CommandText = "dbo.GetBhpbioStockpileBalanceReport"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId.GetValueOrDefault(NullValues.Int32))
                    .Add("@iStockpileId", CommandDataType.Int, CommandDirection.Input, stockpileId.GetValueOrDefault(NullValues.Int32))
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate.GetValueOrDefault(NullValues.DateTime))
                    .Add("@iStartShift", CommandDataType.Char, CommandDirection.Input, startShift.GetValueOrDefault(NullValues.Char))
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate.GetValueOrDefault(NullValues.DateTime))
                    .Add("@iEndShift", CommandDataType.Char, CommandDirection.Input, endShift.GetValueOrDefault(NullValues.Char))
                    .Add("@iIsVisible", CommandDataType.Bit, CommandDirection.Input, setinalIsVisible)
                End With

                Return .ExecuteDataTable
            End With
        End Function
#End Region

        Public Function GetBhpbioSampleStationReportData(locationId As Integer, startDate As Date, endDate As Date, dateBreakdown As String) As DataTable Implements ISqlDalReport.GetBhpbioSampleStationReportData
            With DataAccess
                .CommandText = "dbo.GetBhpbioSampleStationReportData"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iDateBreakdown", CommandDataType.VarChar, CommandDirection.Input, dateBreakdown)
                End With

                Return .ExecuteDataTable()
            End With

        End Function
    End Class

    Public Class ReportDataBlockModelOptions
        Public Property IncludeLumpAndFines As Boolean = True
        Public Property HighGradeOnly As Boolean = True
        Public Property IncludeResourceClassification As Boolean = False
        Public Property UseRemainingMaterialAtDateFrom As Boolean = False
        Public Property OverrideChildLocationType As String = Nothing
        Public Property GeometType As String
        Public Property LowestStratigraphyLevel As Integer = 0
        Public Property IncludeWeathering As Boolean = False
    End Class

    Public Module StringExtensions

        <Runtime.CompilerServices.Extension()>
        Public Function SHA1(input As String) As String
            Using hasher = New Security.Cryptography.SHA1Managed()
                Dim hash = hasher.ComputeHash(Text.Encoding.UTF8.GetBytes(input))
                Return String.Join("", hash.Select(Function(b) b.ToString("x2")).ToArray())
            End Using
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function ToSHA1(dataAccess As Common.Database.SqlDataAccessBaseObjects.SqlDataAccess) As String
            Dim params = dataAccess.ParameterCollection.Where(Function(p) p.Value IsNot Nothing).Select(Function(p) String.Format("{0}:{1}", p.Name, p.Value.ToString)).ToArray
            Dim key = dataAccess.CommandText + "," + String.Join(", ", params)
            Debug.Print(String.Format("ToSHA1 - key: {0}", key))
            Return key.SHA1
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Sub Serialize(ds As DataSet, path As String)
            File.WriteAllText(path, ds.ToJson)
        End Sub

        <Runtime.CompilerServices.Extension()>
        Public Function ToJson(ds As DataSet) As String
            'Need to use the Bhp converters as we need to store column details (name/type)
            Dim _dataTableConverter As BhpbioDataTableConverter = New BhpbioDataTableConverter()
            Dim _dataSetConverter As BhpbioDataSetConverter = New BhpbioDataSetConverter()
            Return JsonConvert.SerializeObject(ds, Formatting.Indented, _dataSetConverter, _dataTableConverter)
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function GetAge(d As Date) As TimeSpan
            Return Date.Now.Subtract(d)
        End Function

    End Module

    Public Class ReportFileCache
        Private Const _directoryName As String = "Cache"
        Private _tempId As Integer = 0

        Public Property Filename As String = Nothing
        Public Property RootDirectory As String = Nothing

        Public Property MaxCacheAge As TimeSpan = TimeSpan.FromMinutes(30)

        ' when this is true the CacheFilePath will always return null, disabling the caching 
        ' this is useful for debugging purposes
        Public Property DisableCaching As Boolean = False

        Private _cachePath As String = Nothing

        Public ReadOnly Property CachePath As String
            Get
                If RootDirectory Is Nothing Then
                    Return Nothing
                End If

                If _cachePath Is Nothing Then
                    _cachePath = Path.Combine(RootDirectory, "Cache")

                    If Not Directory.Exists(_cachePath) Then
                        Directory.CreateDirectory(_cachePath)
                    End If
                End If

                Return _cachePath
            End Get
        End Property

        Public ReadOnly Property CacheFilePath As String
            Get
                If CachePath Is Nothing Or DisableCaching Then
                    Return Nothing
                End If

                Return Path.Combine(CachePath, Filename)
            End Get
        End Property

        Public ReadOnly Property CacheFilePathTemp As String
            Get
                If CacheFilePath Is Nothing Then Return Nothing
                Return String.Format("{0}.{1}.tmp", CacheFilePath, _tempId)
            End Get
        End Property

        Public ReadOnly Property IsCacheFileValid As Boolean
            Get
                Try
                    Return Not DisableCaching AndAlso CacheFilePath IsNot Nothing AndAlso File.Exists(CacheFilePath) AndAlso File.GetLastWriteTime(CacheFilePath).GetAge() <= MaxCacheAge
                Catch ex As Exception
                    Return False
                End Try
            End Get
        End Property

        Public Sub New(_rootDirectory As String)
            RootDirectory = _rootDirectory
            _tempId = CInt(Math.Floor(Rnd() * 10000))
        End Sub

        Public Sub New(_rootDirectory As String, _maxCacheAgeMinutes As Integer?)
            RootDirectory = _rootDirectory
            _tempId = CInt(Math.Floor(Rnd() * 10000))

            If _maxCacheAgeMinutes.HasValue Then
                If _maxCacheAgeMinutes > 0 Then
                    MaxCacheAge = TimeSpan.FromMinutes(_maxCacheAgeMinutes.Value)
                Else
                    DisableCaching = True
                End If
            Else
                DisableCaching = True
            End If

        End Sub

        Public Sub DeleteOldCacheData()
            DeleteOldCacheData(MaxCacheAge + TimeSpan.FromMinutes(15))
        End Sub

        Public Sub DeleteOldCacheData(maxAge As TimeSpan)
            DeleteOldCacheData(Date.Now.Add(-maxAge))
        End Sub

        Public Sub DeleteOldCacheData(beforeDate As DateTime)
            For Each path As String In Directory.GetFiles(CachePath)
                If path.EndsWith(".txt") AndAlso File.GetLastWriteTime(path) <= beforeDate Then
                    File.Delete(path)
                End If
            Next

            ClearOldTempFiles()
        End Sub

        Public Sub ClearCache()
            For Each path As String In Directory.GetFiles(CachePath)
                ' note that since we are deleting everything, we don't want to kill the 
                If path.EndsWith(".txt") Then
                    File.Delete(path)
                End If
            Next
        End Sub
        Public Sub ClearOldTempFiles()
            For Each path As String In Directory.GetFiles(CachePath)
                ' note that since we are deleting everything, we don't want to kill the 
                If path.EndsWith(".tmp") AndAlso File.GetLastWriteTime(path) <= Date.Now.AddHours(-1) Then
                    File.Delete(path)
                End If
            Next
        End Sub

        Public Sub RenameTemp()
            If File.Exists(CacheFilePathTemp) Then
                File.Move(CacheFilePathTemp, CacheFilePath)
            End If
        End Sub


    End Class

End Namespace
