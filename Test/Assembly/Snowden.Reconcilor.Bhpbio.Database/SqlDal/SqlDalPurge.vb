Imports System.Linq
Imports System.Runtime.InteropServices
Imports Snowden.Reconcilor.Bhpbio.Database.Dtos
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalPurge
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.SqlDalBase
        Implements IPurge

        ''' <summary>
        ''' Constant used to control the timeout for the purge operation
        ''' </summary>
        Private Const PurgeTimeoutSeconds As Integer = 1800

#Region " Constructors "
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(ByVal connectionString As String)
            MyBase.New(connectionString)
        End Sub

        Public Sub New(ByVal databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
        End Sub

        Public Sub New(ByVal dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        

        ''' <summary>
        ''' Checks whether a month has been purged or not
        ''' </summary>
        ''' <param name="month">the Month to be checked</param>
        ''' <returns>true if purged, false otherwise</returns>
        Public Function IsMonthPurged(ByVal month As DateTime) As Boolean Implements IPurge.IsMonthPurged
            Dim isPurged As Boolean = False
            Dim monthToCheck As DateTime = New DateTime(month.Year, month.Month, 1)
            Dim latestPurgedMonth As Nullable(Of DateTime) = GetLatestPurgeMonth()

            Return latestPurgedMonth.HasValue AndAlso latestPurgedMonth.Value >= monthToCheck
        End Function

        ''' <summary>
        ''' Purges data
        ''' </summary>
        ''' <param name="request">The purge request to perform</param>
        Public Sub PurgeData(ByVal request As Integer) Implements IPurge.PurgeData

            Dim originalTimeout = DataAccess.CommandTimeout
            Try
                With DataAccess
                    ' remove the timeout
                    .CommandTimeout = PurgeTimeoutSeconds
                    .CommandText = "dbo.PurgeBhpbioData"
                    With .ParameterCollection
                        .Clear()
                        .Add("@iRequest", CommandDataType.Int, CommandDirection.Input, request)
                    End With
                    .ExecuteNonQuery()
                End With
            Finally
                ' reset the timeout on the command
                DataAccess.CommandTimeout = originalTimeout
            End Try
        End Sub

        ''' <summary>
        ''' Gets the latest purge month.
        ''' </summary>
        ''' <returns></returns>
        Public Function GetLatestPurgeMonth() As Nullable(Of DateTime) Implements IPurge.GetLatestPurgeMonth
            With DataAccess
                .CommandText = "dbo.GetBhpbioLatestPurgedMonth"

                With .ParameterCollection

                    .Clear()
                    .Add("@oLatestPurgedMonth", CommandDataType.DateTime, CommandDirection.Output, New Nullable(Of DateTime))
                End With

                .ExecuteNonQuery()
                Dim objValue As Object = .ParameterCollection.Item("@oLatestPurgedMonth").Value
                Dim value As Nullable(Of DateTime)
                If Convert.IsDBNull(objValue) Then
                    value = Nothing
                Else
                    value = DirectCast(objValue, DateTime)
                    value = New DateTime(value.Value.Year, value.Value.Month, 1)
                End If

                Return value

            End With
        End Function

        ''' <summary>
        ''' Gets the latest purgeable month.
        ''' This function returns the latest month that can be chosen to be purged.
        ''' </summary>
        ''' <returns></returns>
        Public Function GetLatestPurgeableMonth() As Nullable(Of DateTime) Implements IPurge.GetLatestPurgeableMonth
            With DataAccess
                .CommandText = "dbo.GetBhpbioLatestPurgeableMonth"

                With .ParameterCollection
                    .Clear()
                    .Add("@oMonth", CommandDataType.DateTime, CommandDirection.Output, New Nullable(Of DateTime))
                End With
                .ExecuteNonQuery()
                Dim objValue As Object = .ParameterCollection.Item("@oMonth").Value
                Dim value As Nullable(Of DateTime)
                If Convert.IsDBNull(objValue) Then
                    value = Nothing
                Else
                    value = DirectCast(objValue, DateTime)
                    value = New DateTime(value.Value.Year, value.Value.Month, 1)
                End If

                Return value
            End With
        End Function

        ''' <summary>
        ''' Adds the purge request.
        ''' </summary>
        ''' <param name="month">The month.</param>
        ''' <param name="userId">The user id.</param>
        ''' <returns></returns>
        Public Function AddPurgeRequest(ByVal month As DateTime, ByVal userId As Integer, <Out()> ByRef id As Integer) As Boolean Implements IPurge.AddPurgeRequest
            id = 0
            Dim monthToSubmit As DateTime = New DateTime(month.Year, month.Month, 1)
            If IsMonthPurged(monthToSubmit) Then
                Return False
            End If
            With DataAccess
                .CommandText = "dbo.AddBhpbioPurgeRequest"
                With .ParameterCollection
                    .Clear()
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, monthToSubmit)
                    .Add("@iRequestingUserId", CommandDataType.Int, CommandDirection.Input, userId)
                    .Add("@oPurgeRequestId", CommandDataType.Int, CommandDirection.Output, Nothing)
                End With

                .ExecuteNonQuery()
                Dim objValue As Object = .ParameterCollection.Item("@oPurgeRequestId").Value
                If Not Convert.IsDBNull(objValue) AndAlso DirectCast(objValue, Integer) > 0 Then
                    id = DirectCast(objValue, Integer)
                End If
                Return id > 0

            End With
        End Function


        ''' <summary>
        ''' Updates the purge requests.
        ''' </summary>
        ''' <param name="requests">The requests.</param>
        ''' <param name="state">The state.</param>
        ''' <param name="approvingUser">The approving user.</param>
        ''' <returns></returns>
        Public Function UpdatePurgeRequests(ByVal requests As IEnumerable(Of Integer), ByVal state As PurgeRequestState, _
                                            ByVal approvingUser As Nullable(Of Integer)) As Boolean Implements IPurge.UpdatePurgeRequests

            If requests Is Nothing OrElse requests.Count() = 0 Then Return False
            If state = PurgeRequestState.Approved AndAlso approvingUser < 1 Then Return False

            Dim keys As String
            If requests.Count = 1 Then
                keys = requests(0).ToString
            Else
                keys = String.Join(",", requests.Distinct().Select(Function(o) o.ToString()).ToArray())
            End If

            With DataAccess
                .CommandText = "dbo.UpdateBhpbioPurgeRequests"

                With .ParameterCollection
                    .Clear()
                    .Add("@iIds", CommandDataType.VarChar, CommandDirection.Input, keys)
                    .Add("@iPurgeRequestStatusId", CommandDataType.Int, CommandDirection.Input, CType(state, Integer))
                    .Add("@iApprovingUserId", CommandDataType.Int, CommandDirection.Input, approvingUser)
                End With
                .ExecuteNonQuery()
                Return True
            End With
        End Function


        ''' <summary>
        ''' Gets the purge requests.
        ''' </summary>
        ''' <param name="readyForApproval">The ready for approval.</param>
        ''' <param name="readyForPurging">The ready for purging.</param>
        ''' <param name="latestRequestPerMonthOnly">If true, only the latest request for each month will be returned</param>
        ''' <returns>The set of requests meeting the criteria</returns>
        Public Function GetPurgeRequests(ByVal readyForApproval As Nullable(Of Boolean), _
                                         ByVal readyForPurging As Nullable(Of Boolean), _
                                         ByVal latestRequestPerMonthOnly As Boolean) As IEnumerable(Of PurgeRequest) Implements IPurge.GetPurgeRequests
            With DataAccess
                .CommandText = "dbo.GetBhpbioPurgeRequests"

                With .ParameterCollection
                    .Clear()
                    .Add("@iIsReadyForApproval", CommandDataType.Bit, CommandDirection.Input, readyForApproval)
                    .Add("@iIsReadyForPurging", CommandDataType.Bit, CommandDirection.Input, readyForPurging)
                    .Add("@iOnlyLatestForEachMonth", CommandDataType.Bit, CommandDirection.Input, latestRequestPerMonthOnly)
                End With

                Dim list As New List(Of PurgeRequest)

                Using reader As IDataReader = .ExecuteDataReader
                    While reader.Read
                        Dim item As New PurgeRequest
                        With item
                            .Id = reader.GetInt32(reader.GetOrdinal("Id"))
                            .IsReadyForApproval = reader.GetBoolean(reader.GetOrdinal("IsReadyForApproval"))
                            .IsReadyForPurging = reader.GetBoolean(reader.GetOrdinal("IsReadyForPurging"))
                            .Month = reader.GetDateTime(reader.GetOrdinal("Month"))
                            .Status = DirectCast(reader.GetInt16(reader.GetOrdinal("Status")), PurgeRequestState)
                            .Timestamp = reader.GetDateTime(reader.GetOrdinal("Timestamp"))

                            .RequestingUser = New PurgeUser
                            With .RequestingUser
                                .Id = reader.GetInt32(reader.GetOrdinal("RequestingUserId"))
                                .FirstName = reader.GetString(reader.GetOrdinal("RequestingUserFirstName"))
                                .LastName = reader.GetString(reader.GetOrdinal("RequestingUserLastName"))
                            End With

                            If Not reader.IsDBNull(reader.GetOrdinal("ApprovingUserId")) Then
                                .ApprovingUser = New PurgeUser
                                With .ApprovingUser
                                    .Id = reader.GetInt32(reader.GetOrdinal("ApprovingUserId"))
                                    .FirstName = reader.GetString(reader.GetOrdinal("ApprovingUserFirstName"))
                                    .LastName = reader.GetString(reader.GetOrdinal("ApprovingUserLastName"))
                                End With
                            End If
                        End With
                        list.Add(item)
                    End While
                End Using

                Return list
            End With
        End Function
    End Class
End Namespace