Imports Snowden.Reconcilor.Bhpbio.Engine
Imports engineBhp = Snowden.Reconcilor.Bhpbio.Engine

Namespace Extensibility
    Public Class EngineDependencyFactories
        Inherits Snowden.Reconcilor.Core.Engine.Extensibility.DependencyFactories

        ''' <summary>
        ''' Configures the agents specific to BHP and  uses the base factory to configure core agents
        ''' </summary>
        ''' <param name="factory">agent factory to be configured</param>
        Protected Overrides Sub ConfigureAgentFactory(ByVal factory As Snowden.Common.Engine.Extensibility.AgentFactory)
            MyBase.ConfigureAgentFactory(factory)

            factory.Register("Purge", GetType(engineBhp.PurgeAgent))
            factory.Register("DataSeriesProcessing", GetType(DataSeriesProcessingAgent))
            factory.Register("BulkApproval", GetType(BulkApprovalAgent))

        End Sub
    End Class
End Namespace
