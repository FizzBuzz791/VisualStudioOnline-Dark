Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

''' <summary>
''' A Report Context that applies to a single thread only
''' </summary>
''' <remarks>This is used to provide each thread with it's own SqlReportDal</remarks>
Public Class ReportThreadContext
    Implements IDisposable

    <ThreadStatic()> _
    Private Shared _current As ReportThreadContext = Nothing

    ''' <summary>
    ''' The reprot Dal instance appropriate for this thread
    ''' </summary>
    Private _dalReport As SqlDalReport = Nothing

    ''' <summary>
    ''' Gets the current context for this thread
    ''' </summary>
    ''' <value>the value of the current context</value>
    ''' <returns>the current context</returns>
    ''' <remarks>Used to make thread specific objects available to report code</remarks>
    Public Shared Property Current() As ReportThreadContext
        Get
            Return _current
        End Get
        Set(ByVal value As ReportThreadContext)
            _current = value
        End Set
    End Property

    ''' <summary>
    ''' Gets or sets the DalReport to be used for this context
    ''' </summary>
    ''' <value>Gets the dal report to be used</value>
    ''' <returns>A SqlDalReport instance</returns>
    Property DalReport() As SqlDalReport
        Get
            Return _dalReport
        End Get
        Set(ByVal value As SqlDalReport)
            _dalReport = value
        End Set
    End Property

    ''' <summary>
    ''' Constructor that accepts a database connection string used for creating dals
    ''' </summary>
    ''' <param name="connectionString">The connection string to be used to create DAL instances</param>
    Public Sub New(ByRef connectionString As String)
        ' this context is automatically the current for the thread
        Current = Me
        _dalReport = New SqlDalReport(connectionString)
    End Sub

    Public Sub New(ByRef session As Types.ReportSession)
        ' this context is automatically the current for the thread
        Current = Me
        _dalReport = New SqlDalReport(session.DalConnectionText)
        _dalReport.FileSystemRoot = session.FileSystemRoot
    End Sub

    ''' <summary>
    ''' Dispose of this thread context and any dependents
    ''' </summary>
    Public Sub Dispose() Implements IDisposable.Dispose
        ' this context is no longer current for the thread
        Current = Nothing

        If (Not DalReport Is Nothing) Then
            DalReport.Dispose()
            DalReport = Nothing
        End If
    End Sub

End Class
