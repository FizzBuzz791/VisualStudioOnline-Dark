Imports System.Runtime.InteropServices
Imports Snowden.Reconcilor.Bhpbio.Database.Dtos
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects

    ''' <summary>
    ''' Interface used to perform Purge operations
    ''' </summary>
    Public Interface IPurge
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        ''' <summary>
        ''' Checks whether a month has been purged or not
        ''' </summary>
        ''' <param name="month">the Month to be checked</param>
        ''' <returns>true if purged, false otherwise</returns>
        Function IsMonthPurged(ByVal month As DateTime) As Boolean

        '''' <summary>
        '''' Gets the latest month that has been purged
        '''' </summary>
        '''' <returns>A date time if a purge has occured, null otherwise</returns>
        Function GetLatestPurgeMonth() As Nullable(Of DateTime)

        ''' <summary>
        ''' Adds the purge request.
        ''' </summary>
        ''' <param name="month">The month.</param>
        ''' <param name="userId">The user id.</param>
        ''' <returns></returns>
        Function AddPurgeRequest(ByVal month As DateTime, ByVal userId As Integer, <Out()> ByRef id As Integer) As Boolean

        ''' <summary>
        ''' Gets the purge requests.
        ''' </summary>
        ''' <param name="readyForApproval">The ready for approval.</param>
        ''' <param name="readyForPurging">The ready for purging.</param>
        ''' <param name="latestRequestPerMonthOnly">If true, only the latest request for each month will be returned</param>
        ''' <returns>The set of purge requests that meet the criteria</returns>
        Function GetPurgeRequests(ByVal readyForApproval As Nullable(Of Boolean), _
                                         ByVal readyForPurging As Nullable(Of Boolean), _
                                         ByVal latestRequestPerMonthOnly As Boolean) As IEnumerable(Of PurgeRequest)

        ''' <summary>
        ''' Updates the purge requests.
        ''' </summary>
        ''' <param name="requests">The requests.</param>
        ''' <param name="state">The state.</param>
        ''' <param name="approvingUser">The approving user.</param>
        Function UpdatePurgeRequests(ByVal requests As IEnumerable(Of Integer), ByVal state As PurgeRequestState, ByVal approvingUser As Nullable(Of Integer)) As Boolean

        ''' <summary>
        ''' Gets the latest purgeable month.
        ''' This function returns the latest month that can be chosen to be purged. 
        ''' </summary>
        ''' <returns></returns>
        Function GetLatestPurgeableMonth() As Nullable(Of DateTime)


        ''' <summary>
        ''' Purge data as specified by a purge request
        ''' </summary>
        ''' <param name="request">Identifies the request to perform.</param>
        Sub PurgeData(ByVal request As Integer)

    End Interface
End Namespace
