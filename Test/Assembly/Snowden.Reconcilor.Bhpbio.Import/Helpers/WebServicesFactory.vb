Imports Snowden.Reconcilor.Bhpbio.Import.MQ2Service
Imports Snowden.Reconcilor.Bhpbio.Import.BlastholesService
Imports Snowden.Reconcilor.Bhpbio.Import.MaterialTrackerService

Public Class WebServicesFactory

    Private Sub New()
        'prevent instantiation
    End Sub

    Public Shared Function CreateBlastholesWebServiceClient() As BlastholesService.IM_Blastholes_DS
        Dim blastholesClient As BlastholesService.IM_Blastholes_DS

        blastholesClient = New M_Blastholes_DSClient("BasicHttpBinding_IM_Blastholes_DS")

        Return blastholesClient
    End Function

    Public Shared Function CreateMaterialTrackerWebServiceClient() As MaterialTrackerService.IM_MT_DS
        Dim mtClient As MaterialTrackerService.IM_MT_DS

        mtClient = New M_MT_DSClient("BasicHttpBinding_IM_MT_DS")

        Return mtClient
    End Function

    Public Shared Function CreateMQ2WebServiceClient() As MQ2Service.IM_MQ2_DS
        Dim mq2Client As MQ2Service.IM_MQ2_DS

        mq2Client = New M_MQ2_DSClient("BasicHttpBinding_IM_MQ2_DS") 'need to check what is the endpointConfigurationName; also do we authenticate?: _settings.ServiceUsername, _settings.ServicePassword

        Return mq2Client
    End Function

End Class
