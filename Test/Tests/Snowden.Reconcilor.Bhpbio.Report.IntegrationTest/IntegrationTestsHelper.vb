Imports pc = Snowden.Bcd.ProductConfiguration
Public Module IntegrationTestsHelper

    Public Const DEFAULT_DATABASE_CONFIGURATION_NAME As String = "Main"
    Public Const DEFAULT_DATABASE_USER_NAME As String = "ReconcilorUI"

    Public Function GetConnectionString(ByVal databaseConfigurationName As String, ByVal databaseUserName As String) As String

        ' Read the product configuration based on the file path in the configuration file
        Dim productConfiguration As New pc.ConfigurationManager("../../../../ProductConfiguration.xml")
        ' open the configuration
        productConfiguration.Open()

        Dim connectionString As String

        Dim databaseConfiguration As pc.DatabaseConfiguration
        databaseConfiguration = productConfiguration.GetDatabaseConfiguration(databaseConfigurationName)

        If databaseConfiguration Is Nothing Then
            Throw New InvalidOperationException("The Reconcilor database configuration was Not found within the product configuration file; please run the Management application to configure settings.")
        End If

        connectionString = databaseConfiguration.GenerateSqlClientConnectionString(databaseUserName)

        Return connectionString

    End Function

    Public Function CreateReportSession() As Types.ReportSession
        Return CreateReportSession(DEFAULT_DATABASE_CONFIGURATION_NAME, DEFAULT_DATABASE_USER_NAME)
    End Function

    Public Function CreateReportSession(ByVal databaseConfigurationName As String, ByVal databaseUserName As String) As Types.ReportSession
        Dim session As New Types.ReportSession
        Dim connectionString As String = GetConnectionString(databaseConfigurationName, databaseUserName)  ' connection string to the test database

        session.SetupDal(connectionString)

        Return session
    End Function
End Module
