Imports Snowden.Reconcilor.Bhpbio.Notification
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace ReconcilorControls.NotificationParts
    Public NotInheritable Class ApprovalNotificationData
        Inherits Reconcilor.Core.WebDevelopment.ReconcilorControls.NotificationParts.NotificationData

        Private _approvalThreshold As Bhpbio.Notification.ApprovalValue
        Private _tagGroupId As String
        Private _tagList As DataTable
        Private _locationId As Integer?

        Friend Property TagGroupId() As String
            Get
                Return _tagGroupId
            End Get
            Set(ByVal value As String)
                _tagGroupId = value
            End Set
        End Property

        Friend Property TagList() As DataTable
            Get
                Return _tagList
            End Get
            Set(ByVal value As DataTable)
                _tagList = value
            End Set
        End Property

        Friend Property LocationId() As Integer?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Integer?)
                _locationId = value
            End Set
        End Property

        Friend ReadOnly Property ApprovalThreshold() As Bhpbio.Notification.ApprovalValue
            Get
                Return _approvalThreshold
            End Get
        End Property

        Protected Overrides Function SerialiseThresholdData() As String
            Return Core.Notification.SimpleSerialiser.Serialise(_approvalThreshold, GetType(Notification.ApprovalValue))
        End Function

        Public Overrides Sub Initialise(ByVal connection As Common.Database.DataAccessBaseObjects.IDataAccessConnection, ByVal instanceId As Integer?)
            MyBase.Initialise(connection, instanceId)

            SetType("Approval")

            _approvalThreshold = New Bhpbio.Notification.ApprovalValue

        End Sub

        Protected Overrides Function SetDefaultValues() As String

            _approvalThreshold.OccurrenceMinutes = 3600
            _approvalThreshold.SendNotificationRegardless = False
            _approvalThreshold.Timing = Notification.ApprovalValue.ApprovalTimingType.Monthly
            _approvalThreshold.Reminder = Notification.ApprovalValue.ApprovalReminderType.Upcoming

            Return String.Empty
        End Function

        Protected Overrides Sub Save()
            Dim sqlDalNotification As Bhpbio.Notification.SqlDalNotification = Nothing
            MyBase.Save()

            Try
                sqlDalNotification = New Bhpbio.Notification.SqlDalNotification(Connection)
                If _locationId.HasValue Then
                    sqlDalNotification.SaveInstanceApproval(InstanceId.Value, _tagGroupId, _locationId.Value)
                Else
                    sqlDalNotification.SaveInstanceApproval(InstanceId.Value, _tagGroupId, NullValues.Int32)
                End If

            Catch ex As Exception
                Throw
            Finally
                If Not sqlDalNotification Is Nothing Then
                    sqlDalNotification.Dispose()
                    sqlDalNotification = Nothing
                End If
            End Try

        End Sub

        Protected Overrides Sub LoadReferenceData()
            MyBase.LoadReferenceData()
            Dim sqlDalApproval As Bhpbio.Database.SqlDal.SqlDalApproval = Nothing
            Dim locationTypeId As Integer

            Try
                sqlDalApproval = New Bhpbio.Database.SqlDal.SqlDalApproval(Connection)
                If _locationId.HasValue Then
                    locationTypeId = Convert.ToInt32(DalUtility.GetLocation(_locationId.Value).Rows(0)("Location_Type_Id"))
                    TagList = sqlDalApproval.GetBhpbioReportDataTags(NullValues.String, locationTypeId)
                Else
                    TagList = sqlDalApproval.GetBhpbioReportDataTags(NullValues.String, NullValues.Int32)
                End If
            Catch ex As Exception
                Throw
            Finally
                If Not sqlDalApproval Is Nothing Then
                    sqlDalApproval.Dispose()
                    sqlDalApproval = Nothing
                End If
            End Try

        End Sub

        Protected Overrides Function LoadDatabaseValues() As String
            Dim validateMessages As New Text.StringBuilder(MyBase.LoadDatabaseValues())
            Dim bhpbioNotificationDal As SqlDalNotification = Nothing

            _approvalThreshold = DirectCast(Core.Notification.SimpleSerialiser.Deserialise(Threshold, GetType(Bhpbio.Notification.ApprovalValue)), Bhpbio.Notification.ApprovalValue)

            Try
                bhpbioNotificationDal = New SqlDalNotification(Connection)
                With bhpbioNotificationDal.GetInstanceApproval(InstanceId.Value).Rows(0)
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
            Catch
                Throw
            Finally
                If Not bhpbioNotificationDal Is Nothing Then
                    bhpbioNotificationDal.Dispose()
                    bhpbioNotificationDal = Nothing
                End If
            End Try

            Return validateMessages.ToString
        End Function

        Protected Overrides Function LoadRequestValues(ByVal requestData As System.Collections.Generic.IDictionary(Of String, String)) As String
            Dim validateMessages As New Text.StringBuilder(MyBase.LoadRequestValues(requestData))
            Dim filterLocationId As Integer

            If requestData.ContainsKey("LocationId") AndAlso _
                Integer.TryParse(requestData("LocationId"), filterLocationId) Then
                If filterLocationId <= 0 Then
                    _locationId = Nothing
                Else
                    _locationId = filterLocationId
                End If
            Else
                _locationId = Nothing
            End If

            Return validateMessages.ToString

        End Function

        Protected Overrides Function ProcessDataCollection(ByVal parameters As System.Collections.Generic.IDictionary(Of String, String)) As String
            Dim validateMessages As New Text.StringBuilder
            'Dim OccurrenceMinutes As Integer = 0
            'Dim OccurrenceHours As Integer = 0
            Dim OccurrenceDays As Integer = 0
            'Dim NotificationExpiryMinutes As Integer = 0
            'Dim NotificationExpiryHours As Integer = 0
            Dim NotificationExpiryDays As Integer = 0
            Dim tmpLocationId As Integer
            validateMessages.Append(MyBase.ProcessDataCollection(parameters))

            validateMessages.Append(UIWarningPositive("Approval Occurrence Days", parameters("OccurrenceDays"), OccurrenceDays))
            'validateMessages.Append(UIWarningPositiveOrZeroOrBlank("Approval Occurrence Hours", parameters("OccurrenceHours"), OccurrenceHours))
            'validateMessages.Append(UIWarningPositiveOrZeroOrBlank("Approval Occurrence Minutes", parameters("OccurrenceMinutes"), OccurrenceMinutes))


            validateMessages.Append(UIWarningPositive("Notification Expiry Days", parameters("NotificationExpiryDays"), NotificationExpiryDays))
            'validateMessages.Append(UIWarningPositiveOrZeroOrBlank("Notification Expiry Hours", parameters("NotificationExpiryHours"), NotificationExpiryHours))
            'validateMessages.Append(UIWarningPositiveOrZeroOrBlank("Notification Expiry Minutes", parameters("NotificationExpiryMinutes"), NotificationExpiryMinutes))


            'Check that the location id is valid, if one is not supplied
            If parameters.ContainsKey("LocationId") Then
                If Integer.TryParse(parameters("LocationId"), tmpLocationId) Then
                    If tmpLocationId <= 0 Then
                        _locationId = Nothing
                    Else
                        _locationId = tmpLocationId
                        With DalUtility.GetLocation(_locationId.Value)
                            If .Rows.Count > 0 Then
                                _approvalThreshold.Location = DirectCast(.Rows(0)("Name"), String)
                            Else
                                validateMessages.Append("\n - The Location supplied was invalid")
                            End If
                        End With

                    End If
                End If
            End If

            'If at least one value has been specified for the Occurrence
            If (OccurrenceDays > 0) Then
                _approvalThreshold.OccurrenceMinutes = Convert.ToInt32(New TimeSpan(OccurrenceDays, 0, 0, 0).TotalMinutes)
            End If

            If (NotificationExpiryDays > 0) Then
                _approvalThreshold.NotificationExpiryMinutes = Convert.ToInt32(New TimeSpan(NotificationExpiryDays, 0, 0, 0).TotalMinutes)
             End If

            _approvalThreshold.Timing = DirectCast([Enum].Parse(GetType(ApprovalValue.ApprovalTimingType), parameters("TimingType")), ApprovalValue.ApprovalTimingType)
            _approvalThreshold.Reminder = DirectCast([Enum].Parse(GetType(ApprovalValue.ApprovalReminderType), parameters("ReminderType")), ApprovalValue.ApprovalReminderType)
            If parameters("SendEmailRegardless") = "on" Then
                _approvalThreshold.SendNotificationRegardless = True
            Else
                _approvalThreshold.SendNotificationRegardless = False
            End If
            _approvalThreshold.EmailTemplate = parameters("EmailMessage")

            If parameters("TagGroupId") = String.Empty Then
                _tagGroupId = Nothing
            Else
                _tagGroupId = parameters("TagGroupId")
            End If

            _approvalThreshold.ApprovalAttribute = _tagGroupId

            Return validateMessages.ToString
        End Function

    End Class
End Namespace
