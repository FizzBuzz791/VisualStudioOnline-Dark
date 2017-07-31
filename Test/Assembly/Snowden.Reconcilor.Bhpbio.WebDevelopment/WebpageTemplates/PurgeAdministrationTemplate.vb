Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace WebpageTemplates
    Public Class PurgeAdministrationTemplate
        Inherits ReconcilorAjaxPage

        Public Class AuditTypes
            Public Const PurgeRequested As String = "Purge Requested"
            Public Const PurgeApproved As String = "Purge Approved"
            Public Const PurgeCancelled As String = "Purge Cancelled"
            Public Const PurgeInitiated As String = "Purge Failed"
            Public Const PurgeCompleted As String = "Purge Completed"
            Public Const PurgeFailed As String = "Purge Failed"
            Public Const AuditTypeGroupId As Integer = 6
            Private Sub New()

            End Sub
        End Class

        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)
            MyBase.OnInit(e)
            EventLogAuditTypeGroupId = AuditTypes.AuditTypeGroupId
        End Sub

        Protected Overrides Sub HandlePageSecurity()
            If Not Resources.UserSecurity.HasAccess("PURGE_DATA") Then
                MyBase.ReportAccessDenied()
            End If
            MyBase.HandlePageSecurity()
        End Sub

        Private _isDisposed As Boolean
        Protected Property IsDisposed() As Boolean
            Get
                Return _isDisposed
            End Get
            Private Set(ByVal value As Boolean)
                _isDisposed = value
            End Set
        End Property


        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If Not IsDisposed Then
                    If Not DalPurge Is Nothing Then
                        DalPurge.Dispose()
                        DalPurge = Nothing
                    End If
                    If Not DalUtility Is Nothing Then
                        DalUtility.Dispose()
                        DalUtility = Nothing
                    End If
                    IsDisposed = True
                End If
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub


        Private _dalPurge As IPurge
        Protected Property DalPurge() As IPurge
            Get
                Return _dalPurge
            End Get
            Private Set(ByVal value As IPurge)
                _dalPurge = value
            End Set
        End Property

        Private _dalUtility As IUtility
        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Private Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property


        Protected Overrides Sub SetupDalObjects()
            If DalPurge Is Nothing Then
                DalPurge = New Database.SqlDal.SqlDalPurge(Resources.Connection)
            End If
            If DalUtility Is Nothing Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
            MyBase.SetupDalObjects()
        End Sub

        Protected Function GetQuarters() As IDictionary(Of DateTime, String)
            Dim lastPurgedDate As Nullable(Of DateTime) = DalPurge.GetLatestPurgeMonth()
            Dim entry As KeyValuePair(Of DateTime, String)
            If lastPurgedDate.HasValue Then
                ' get next quarter since the last purged date belongs to the quarter already purged
                entry = GetNextQuarterEntry(lastPurgedDate.Value)
            Else
                ' get quarter where the system start date falls upon
                ' an exception will be thrown if no setting is found in the system
                entry = GetQuarterEntry(GetSystemStartDate())
            End If
            Dim dictionary As New Dictionary(Of DateTime, String)
            While entry.Key <= DateTime.Today
                dictionary.Add(entry.Key, entry.Value)
                entry = GetNextQuarterEntry(entry.Key)
            End While
            Return dictionary
        End Function

        Protected Function GetSystemStartDate() As DateTime
            Const key As String = "SYSTEM_START_DATE"
            Dim setting As String = Me.DalUtility.GetSystemSetting(key)
            Dim result As DateTime
            If Not DateTime.TryParse(setting, result) Then
                Throw New InvalidOperationException("Cannot Retrieve System Start Date")
            End If
            Return result
        End Function

        Private Function GetQuarterEntry(ByVal value As DateTime) As KeyValuePair(Of DateTime, String)
            Dim month As Integer = value.Month
            Select Case month
                Case 1, 2, 3
                    Return New KeyValuePair(Of DateTime, String)(New DateTime(value.Year, 3, 31), String.Format("{0} 3rd Quarter", value.Year - 1))
                Case 4, 5, 6
                    Return New KeyValuePair(Of DateTime, String)(New DateTime(value.Year, 6, 30), String.Format("{0} 4th Quarter", value.Year - 1))
                Case 7, 8, 9
                    Return New KeyValuePair(Of DateTime, String)(New DateTime(value.Year, 9, 30), String.Format("{0} 1st Quarter", value.Year))
                Case 10, 11, 12
                    Return New KeyValuePair(Of DateTime, String)(New DateTime(value.Year, 12, 31), String.Format("{0} 2nd Quarter", value.Year))
                Case Else
                    Throw New ArgumentException()
            End Select
        End Function

        Private Function GetNextQuarterEntry(ByVal value As DateTime) As KeyValuePair(Of DateTime, String)
            Dim month As Integer = value.Month
            Select Case month
                Case 1, 2, 3
                    Return GetQuarterEntry(New DateTime(value.Year, 4, 1))
                Case 4, 5, 6
                    Return GetQuarterEntry(New DateTime(value.Year, 7, 1))
                Case 7, 8, 9
                    Return GetQuarterEntry(New DateTime(value.Year, 10, 1))
                Case 10, 11, 12
                    Return GetQuarterEntry(New DateTime(value.Year + 1, 1, 1))
                Case Else
                    Throw New ArgumentException()
            End Select
        End Function

        Protected Function GetPurgeableMonths() As IEnumerable(Of DateTime)
            Dim list As New List(Of DateTime)
            Dim startDate As Nullable(Of DateTime) = DalPurge.GetLatestPurgeMonth()
            If Not startDate.HasValue Then
                startDate = GetSystemStartDate()
            Else
                ' skip a month ahead
                startDate = startDate.Value.AddMonths(1)
            End If
            If startDate.HasValue Then
                Dim endDate As Nullable(Of DateTime) = DalPurge.GetLatestPurgeableMonth()
                If endDate.HasValue Then
                    If startDate.Value > endDate.Value Then
                        startDate = endDate
                    End If
                    Dim currentMonth As DateTime = New DateTime(startDate.Value.Year, startDate.Value.Month, 1)
                    While currentMonth <= endDate.Value
                        list.Add(currentMonth)
                        currentMonth = currentMonth.AddMonths(1)
                    End While
                End If
            End If
            list.Reverse()
            Return list
        End Function

        Protected Function GetPurgeableQuarters() As IEnumerable(Of DateTime)
            Dim list As New List(Of DateTime)
            Dim startDate As Nullable(Of DateTime) = DalPurge.GetLatestPurgeMonth()
            If Not startDate.HasValue Then
                startDate = GetSystemStartDate()
            Else
                ' skip a month ahead
                startDate = startDate.Value.AddMonths(1)
            End If
            If startDate.HasValue Then
                Dim endDate As Nullable(Of DateTime) = DalPurge.GetLatestPurgeableMonth()
                If endDate.HasValue AndAlso endDate.Value >= startDate.Value Then
                    Dim currentMonth As DateTime = New DateTime(startDate.Value.Year, startDate.Value.Month, 1)

                    While currentMonth <= endDate.Value
                        Dim quarterMonth As DateTime = GetQuarterEntry(currentMonth).Key

                        ' if the current month is the last in the quarter AND the list does not already contain the quarter month then add it now
                        If (currentMonth.Year = quarterMonth.Year And currentMonth.Month = quarterMonth.Month And Not list.Contains(quarterMonth)) Then
                            list.Add(quarterMonth)
                        End If
                        currentMonth = currentMonth.AddMonths(1)
                    End While
                End If
            End If
            list.Reverse()
            Return list
        End Function
    End Class
End Namespace
