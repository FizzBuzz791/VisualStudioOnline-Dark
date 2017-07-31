Imports RecCore = Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Core

Namespace Notification
    Public Class UiAssistant
        Implements IDisposable

        'This class is intended to have a very limited life.
        'It will simply allow the UI portion of Reconcilor access to notification instances.

        Private _factory As RecCore.Extensibility.DependencyFactories
        Private _dalNotification As RecCore.Notification.SqlDalNotification
        Private _notificationInstances As IList(Of Core.Notification.IInstance)
        Private _dalUtility As RecCore.Database.DalBaseObjects.IUtility
        Private _sqlDalSecurityLocation As Bhpbio.Database.SqlDal.SqlDalSecurityLocation
        Private disposedValue As Boolean = False        ' To detect redundant calls

        Public Sub New(ByVal factory As RecCore.Extensibility.DependencyFactories, _
                       ByVal connection As Common.Database.DataAccessBaseObjects.IDataAccessConnection)
            _factory = factory
            _dalNotification = New RecCore.Notification.SqlDalNotification(connection)
            _dalUtility = New RecCore.Database.SqlDal.SqlDalUtility(connection)
            _sqlDalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(connection)
            Initialise()
        End Sub

        Private Sub Initialise()
            _notificationInstances = New List(Of Core.Notification.IInstance)
            For Each notificationInstance As DataRow In _dalNotification.GetInstances().Rows
                _notificationInstances.Add(_factory.NotificationFactory.Create(DirectCast(notificationInstance("TypeName"), String), _
                                                    DirectCast(notificationInstance("InstanceId"), Integer), _
                                                    _dalNotification.DataAccess.DataAccessConnection, _dalNotification))
                _notificationInstances(_notificationInstances.Count - 1).Load()
            Next
        End Sub

        ''' <summary>
        ''' Returns an IDictionary collection of strings containing HTML formatted text indicating the 
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetNotificationSimpleUiMessages(ByVal userId As Integer) As IEnumerable(Of String)
            Dim uiMessages As New List(Of String)
            Dim locationEnabledNotification As ILocationQueryable
            Dim message As String = Nothing

            For Each notificationInstance In _notificationInstances
                locationEnabledNotification = TryCast(notificationInstance, ILocationQueryable)

                If Not locationEnabledNotification Is Nothing Then
                    If locationEnabledNotification.LocationId.HasValue Then
                        If _sqlDalSecurityLocation.IsBhpbioUserInLocation(userId, locationEnabledNotification.LocationId) Then
                            message = notificationInstance.GetSimpleUiMessage()
                        End If
                    Else
                        message = notificationInstance.GetSimpleUiMessage()
                    End If
                Else
                    message = notificationInstance.GetSimpleUiMessage()
                End If

                If Not message Is Nothing AndAlso message <> String.Empty Then
                    uiMessages.Add(message)
                End If

            Next

            Return uiMessages
        End Function

        ' IDisposable
        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If Not Me.disposedValue Then
                If disposing Then
                    If Not _dalNotification Is Nothing Then
                        _dalNotification.Dispose()
                        _dalNotification = Nothing
                    End If
                    If Not _dalUtility Is Nothing Then
                        _dalUtility.Dispose()
                        _dalUtility = Nothing
                    End If
                    If Not _sqlDalSecurityLocation Is Nothing Then
                        _sqlDalSecurityLocation.Dispose()
                        _sqlDalSecurityLocation = Nothing
                    End If
                End If

                _factory = Nothing

            End If
            Me.disposedValue = True
        End Sub

#Region " IDisposable Support "
        ' This code added by Visual Basic to correctly implement the disposable pattern.
        Public Sub Dispose() Implements IDisposable.Dispose
            ' Do not change this code.  Put cleanup code in Dispose(ByVal disposing As Boolean) above.
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub
#End Region

    End Class
End Namespace
