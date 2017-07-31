Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Public Class ImportQueueRequest
    Private Const _defaultPriority As Int16 = 11

    Public Shared Sub QueueImportRequests(ByVal queueRequests As IList(Of BlockQueueRequest), _
     ByVal importDal As Snowden.Common.Import.Database.IImportManager)
        Dim importJobDal As Snowden.Common.Import.Database.IImportJobManager
        Dim importBHPJobDal As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IImportManager
        Dim importId As Int16
        Dim importParameter As DataRow()
        Dim importSiteParameterId As Int32
        Dim importPitParameterId As Int32
        Dim importJobId As Int32
        Dim request As BlockQueueRequest

        'create the DAL, set the connection
        importJobDal = New Snowden.Common.Import.Database.ImportJobManager
        importBHPJobDal = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalImportManager

        Try
            importJobDal.DataAccess.DataAccessConnection = importDal.DataAccess.DataAccessConnection
            importBHPJobDal.DataAccess.DataAccessConnection = importDal.DataAccess.DataAccessConnection

            'identify the block import / bench parameter id
            importId = importDal.GetImportIdFromName("Blocks")

            importParameter = importDal.GetImportParameters(importId).Select("ParameterName = 'Site'")
            importSiteParameterId = DirectCast(importParameter(0)("ImportParameterId"), Int32)
            importParameter = Nothing

            importParameter = importDal.GetImportParameters(importId).Select("ParameterName = 'Pit'")
            importPitParameterId = DirectCast(importParameter(0)("ImportParameterId"), Int32)
            importParameter = Nothing

            'for each bench create a new import job
            For Each request In queueRequests
                If Not importBHPJobDal.DoesQueuedBlocksJobExist(importId, request.Site, request.Pit, NullValues.String) Then
                    importJobId = importJobDal.AddImportJob(importId, _defaultPriority)
                    importJobDal.UpdateImportJobParameter(importJobId, importSiteParameterId, request.Site)
                    importJobDal.UpdateImportJobParameter(importJobId, importPitParameterId, request.Pit)
                    importJobDal.UpdateImportJobStatus(importJobId, GetImportJobStatusId(importDal, "QUEUED"), 1)
                End If
            Next
        Finally
            If Not importJobDal Is Nothing Then
                importJobDal.Dispose()
                importJobDal = Nothing
            End If
        End Try
    End Sub

    Private Shared Function GetImportJobStatusId( _
     ByVal managerDal As Snowden.Common.Import.Database.IImportManager, ByVal jobStatus As String) As Int16
        Return DirectCast(managerDal.GetImportStatusList(jobStatus)(0)("ImportJobStatusId"), Int16)
    End Function
End Class

Public Class BlockQueueRequest
    Public Site As String
    Public Pit As String

    Public Overrides Function Equals(ByVal obj As Object) As Boolean
        Dim request As BlockQueueRequest

        If TypeOf obj Is BlockQueueRequest Then
            request = DirectCast(obj, BlockQueueRequest)

            If request.Site = Me.Site _
             AndAlso request.Pit = Me.Pit Then
                Return True
            Else
                Return False
            End If
        Else
            Return False
        End If
    End Function
End Class
