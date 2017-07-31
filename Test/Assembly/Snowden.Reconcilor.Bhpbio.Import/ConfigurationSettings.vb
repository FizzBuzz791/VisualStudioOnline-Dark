Friend Class ConfigurationSettings
    Private Const _settingServiceUsername As String = "ServiceUsername"
    Private Const _settingServicePassword As String = "ServicePassword"
    Private Const _defaultShiftType As String = "DefaultShift"

    Private _serviceUsername As String
    Private _servicePassword As String
    Private _defaultShift As Char

    Friend ReadOnly Property ServiceUsername() As String
        Get
            Return _serviceUsername
        End Get
    End Property

    Friend ReadOnly Property ServicePassword() As String
        Get
            Return _servicePassword
        End Get
    End Property

    Friend ReadOnly Property DefaultShift() As Char
        Get
            Return _defaultShift
        End Get
    End Property

    Private Sub New(ByVal serviceUsername As String, ByVal servicePassword As String, ByVal defaultShift As Char)
        _serviceUsername = serviceUsername
        _servicePassword = servicePassword
        _defaultShift = defaultShift
    End Sub

    ''' <summary>
    ''' Reads the configuration settings.
    ''' </summary>
    ''' <param name="payloadTarget">The prefix for the payload target.  This can be haulage, weightometer, etc.</param>
    ''' <returns>The actual configuration settings.</returns>
    ''' <remarks>Utilises the app.config for all of its data.</remarks>
    Public Shared Function GetConfigurationSettings() As ConfigurationSettings
        Dim configurationSettings As ConfigurationSettings
        Dim serviceUsername As String
        Dim servicePassword As String
        Dim defaultShift As Char

        'load the username/password for the web service
        serviceUsername = Configuration.ConfigurationManager.AppSettings(_settingServiceUsername)
        servicePassword = Configuration.ConfigurationManager.AppSettings(_settingServicePassword)

        'load the default shift
        defaultShift = Configuration.ConfigurationManager.AppSettings(_defaultShiftType).Chars(0)

        'create the new object based on these settings & return
        configurationSettings = New ConfigurationSettings(serviceUsername, servicePassword, defaultShift)

        Return configurationSettings
    End Function
End Class