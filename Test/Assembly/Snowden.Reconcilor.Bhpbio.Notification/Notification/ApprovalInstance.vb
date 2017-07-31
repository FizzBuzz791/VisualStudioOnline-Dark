Imports Snowden.Reconcilor.Core.Notification.Comparer
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects

Namespace Notification
    Public Class ApprovalInstance
        Inherits Reconcilor.Core.Notification.Instance(Of Bhpbio.Notification.ApprovalValue)
        Implements ILocationQueryable

        Private _locationId As Integer?
        Private _tagGroupId As String

        Public ReadOnly Property LocationId() As Integer? Implements ILocationQueryable.LocationId
            Get
                Return _locationId
            End Get
        End Property

        Public Overrides Sub Load()
            MyBase.Load()
            Dim bhpbioNotificationDal As SqlDalNotification = Nothing

            Try
                bhpbioNotificationDal = New SqlDalNotification(Connection)
                Dim instanceApproval = bhpbioNotificationDal.GetInstanceApproval(InstanceId)

                If (instanceApproval.Rows.Count > 0) Then
                    With bhpbioNotificationDal.GetInstanceApproval(InstanceId).Rows(0)
                        If .Item("LocationId") Is DBNull.Value Then
                            _locationId = Nothing
                        Else
                            _locationId = Convert.ToInt32(.Item("LocationId"))
                        End If
                        If .Item("TagGroupId") Is DBNull.Value Then
                            _tagGroupId = Nothing
                        Else
                            _tagGroupId = DirectCast(.Item("TagGroupId"), String)
                        End If
                    End With
                End If
            Catch
                Throw
            Finally
                If Not bhpbioNotificationDal Is Nothing Then
                    bhpbioNotificationDal.Dispose()
                    bhpbioNotificationDal = Nothing
                End If
            End Try

        End Sub

        Public Overrides Sub Save()
            MyBase.Save()
        End Sub

        Protected Overrides Function GetNotifier() As Core.Notification.INotifier(Of ApprovalValue)
            Return New ApprovalNotifier
        End Function

        Protected Overrides Function GetUiNotifier() As Core.Notification.IUiNotifier(Of ApprovalValue)
            Return New ApprovalUiNotifier
        End Function

        Private Function GetMonthToCheck(ByVal type As ApprovalValue.ApprovalReminderType, ByVal monthToGet As DateTime) As DateTime
            If type = ApprovalValue.ApprovalReminderType.Outstanding Then
                'Get the last day of the previous month
                Return monthToGet.AddDays(-(monthToGet.Day + 1))
            ElseIf type = ApprovalValue.ApprovalReminderType.Upcoming Then
                'Get the last day of this month
                Return monthToGet.AddMonths(1).AddDays(-(monthToGet.Day + 1))
            End If
        End Function

        Private Function GetQuarterToCheck(ByVal type As ApprovalValue.ApprovalReminderType, ByVal monthToGet As DateTime) As DateTime
            Dim quarterLastDate As DateTime

            If New Integer() {7, 8, 9}.Contains(Month(monthToGet)) Then
                quarterLastDate = New DateTime(Now.Year, 9, 30)
            ElseIf New Integer() {10, 11, 12}.Contains(Month(monthToGet)) Then
                quarterLastDate = New DateTime(Now.Year, 12, 31)
            ElseIf New Integer() {1, 2, 3}.Contains(Month(monthToGet)) Then
                quarterLastDate = New DateTime(Now.Year, 3, 31)
            ElseIf New Integer() {4, 5, 6}.Contains(Month(monthToGet)) Then
                quarterLastDate = New DateTime(Now.Year, 6, 30)
            End If

            If type = ApprovalValue.ApprovalReminderType.Outstanding Then
                'Get the last day of the previous quarter, otherwise the current date is fine.
                quarterLastDate = quarterLastDate.AddMonths(-3)
            End If

            Return quarterLastDate

        End Function

        Private Function GetMonthsToCheck(ByVal monthToGet As DateTime) As IList(Of DateTime)
            Dim monthList As New List(Of DateTime)

            If New Integer() {7, 8, 9}.Contains(Month(monthToGet)) Then
                monthList.Add(New DateTime(Now.Year, 7, 1))
                monthList.Add(New DateTime(Now.Year, 8, 1))
                monthList.Add(New DateTime(Now.Year, 9, 1))
            ElseIf New Integer() {10, 11, 12}.Contains(Month(monthToGet)) Then
                monthList.Add(New DateTime(Now.Year, 10, 1))
                monthList.Add(New DateTime(Now.Year, 11, 1))
                monthList.Add(New DateTime(Now.Year, 12, 1))
            ElseIf New Integer() {1, 2, 3}.Contains(Month(monthToGet)) Then
                monthList.Add(New DateTime(Now.Year, 1, 1))
                monthList.Add(New DateTime(Now.Year, 2, 1))
                monthList.Add(New DateTime(Now.Year, 3, 1))
            ElseIf New Integer() {4, 5, 6}.Contains(Month(monthToGet)) Then
                monthList.Add(New DateTime(Now.Year, 4, 1))
                monthList.Add(New DateTime(Now.Year, 5, 1))
                monthList.Add(New DateTime(Now.Year, 6, 1))
            End If
            Return monthList
        End Function

        Protected Overrides Function GetSample() As ApprovalValue
            Dim isApproved As Boolean
            Dim dalApproval As Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalApproval
            Dim result As New ApprovalValue

            Dim locationQuery As String
            Dim tagGroupIdQuery As String

            dalApproval = New Snowden.Reconcilor.Bhpbio.Database.SqlDal.SqlDalApproval(Connection)

            If LocationId.HasValue Then
                locationQuery = String.Format("And LocationId = {0}", LocationId.Value)
            Else
                locationQuery = String.Empty
            End If

            If Not _tagGroupId Is Nothing AndAlso _tagGroupId <> String.Empty Then
                tagGroupIdQuery = String.Format("And TagGroupId = '{0}'", LocationId.Value)
            Else
                tagGroupIdQuery = String.Empty
            End If

            'Go and get the samples, etc.
            If Threshold.Timing = ApprovalValue.ApprovalTimingType.Monthly Then
                isApproved = dalApproval.GetBhpbioApprovalData(GetMonthToCheck(Threshold.Reminder, Now)).Tables(0).Select(String.Format("Approved = 0 {0} {1}", locationQuery, tagGroupIdQuery)).Length = 0

                If isApproved Then
                    result.OccurredTime = GetMonthToCheck(Threshold.Reminder, Now)
                    result.OccurrenceMinutes = 0
                Else
                    result.OccurrenceMinutes = (Now - GetMonthToCheck(Threshold.Reminder, Now)).TotalMinutes
                End If
            Else
                isApproved = True
                For Each m As DateTime In GetMonthsToCheck(Now)
                    If dalApproval.GetBhpbioApprovalData(GetMonthToCheck(Threshold.Reminder, Now)).Tables(0).Select(String.Format("Approved = 0 {0} {1}", locationQuery, tagGroupIdQuery)).Length > 0 Then
                        isApproved = False
                    End If
                Next
                If isApproved Then
                    result.OccurredTime = GetQuarterToCheck(Threshold.Reminder, Now)
                    result.OccurrenceMinutes = 0
                Else
                    result.OccurrenceMinutes = (Now - GetQuarterToCheck(Threshold.Reminder, Now)).TotalMinutes
                End If
            End If



            Return result
        End Function

        Protected Overrides Function GetSampleThresholdState(ByVal value As ApprovalValue, ByVal threshold As ApprovalValue) As Core.Notification.ThresholdState
            Dim approvedThresholdState As Core.Notification.ThresholdState
            Dim minutesSinceDatePassed As Integer

            If Not value Is Nothing Then
                If value.OccurrenceMinutes.HasValue Then
                    If threshold.Timing = ApprovalValue.ApprovalTimingType.Monthly Then
                        minutesSinceDatePassed = (Now - GetMonthToCheck(threshold.Reminder, Now)).TotalMinutes
                        value.CalculatedExpiryDate = GetMonthToCheck(threshold.Reminder, Now).AddMinutes(threshold.NotificationExpiryMinutes)
                        value.CalculatedApprovalDate = GetMonthToCheck(threshold.Reminder, Now)
                    ElseIf threshold.Timing = ApprovalValue.ApprovalTimingType.Quarterly Then
                        minutesSinceDatePassed = (Now - GetQuarterToCheck(threshold.Reminder, Now)).TotalMinutes
                        value.CalculatedExpiryDate = GetQuarterToCheck(threshold.Reminder, Now).AddMinutes(threshold.NotificationExpiryMinutes)
                        value.CalculatedApprovalDate = GetQuarterToCheck(threshold.Reminder, Now)
                    End If


                    If minutesSinceDatePassed <= threshold.NotificationExpiryMinutes Then
                        If threshold.Reminder = ApprovalValue.ApprovalReminderType.Outstanding Then
                            approvedThresholdState = SimpleThresholdComparer(value.OccurrenceMinutes, threshold.OccurrenceMinutes, True)
                        ElseIf threshold.Reminder = ApprovalValue.ApprovalReminderType.Upcoming Then
                            approvedThresholdState = SimpleThresholdComparer(Math.Abs(value.OccurrenceMinutes.Value), threshold.OccurrenceMinutes, False)
                        End If

                        'Send it anyway...
                        If threshold.SendNotificationRegardless AndAlso value.OccurredTime.HasValue Then
                            If threshold.Reminder = ApprovalValue.ApprovalReminderType.Outstanding Then
                                approvedThresholdState = SimpleThresholdComparer(Convert.ToInt32((Now - value.OccurredTime).Value.TotalMinutes), threshold.OccurrenceMinutes, True)
                            ElseIf threshold.Reminder = ApprovalValue.ApprovalReminderType.Upcoming Then
                                approvedThresholdState = SimpleThresholdComparer(Convert.ToInt32((value.OccurredTime - Now).Value.TotalMinutes), threshold.OccurrenceMinutes, False)
                            End If
                        End If
                    End If
                Else
                    'If we dont' have a previous value set it to good. Just the nature of the notification type.
                    Return Core.Notification.ThresholdState.PositiveThreshold
                End If
            Else
                Return Core.Notification.ThresholdState.PositiveThreshold
            End If

            Return approvedThresholdState
        End Function

        Protected Overrides Function GetSampleTrendState(ByVal previous As ApprovalValue, ByVal current As ApprovalValue) As Core.Notification.TrendState
            'Trend is not really relative in this case. So we won't use it
            'This is perfectly acceptable for the model.
            Return ThresholdTrendComparer(GetSampleThresholdState(previous, Threshold), GetSampleThresholdState(current, Threshold))
        End Function
    End Class

End Namespace
