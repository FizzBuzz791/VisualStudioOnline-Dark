Imports Snowden.Reconcilor.Bhpbio.Report.Types

''' <summary>
''' Encapsulates the context information for background retrieval
''' </summary>
Public Class BackgroundCacheRetrievalContext

    Public Delegate Sub BackgroundCacheRetrievalDelegate(obj As Object)

    Public Property Session As ReportSession

    Public Property BackgroundRetrievalSub As BackgroundCacheRetrievalDelegate

    Public Property Err As Exception

    Public Sub New(session As ReportSession, ByRef workSub As BackgroundCacheRetrievalDelegate)
        Me.Session = session
        Me.BackgroundRetrievalSub = workSub
    End Sub

End Class
