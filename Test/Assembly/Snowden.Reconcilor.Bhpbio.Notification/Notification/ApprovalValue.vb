Imports System.Xml.Serialization
Namespace Notification
    Public Class ApprovalValue
        Implements IXmlSerializable

        Private _occurrenceMinutes As Int32?
        Private _reminder As ApprovalReminderType
        Private _stillSendNotification As Boolean
        Private _timing As ApprovalTimingType
        Private _occurredTime As DateTime?
        Private _sendNotificationRegardless As Boolean
        Private _emailTemplate As String
        Private _location As String
        Private _approvalAttribute As String
        Private _notificationExpiryMinutes As Int32
        Private _calculatedExpiryDate As DateTime
        Private _calculatedApprovalDate As DateTime

        Public Property CalculatedApprovalDate() As DateTime
            Get
                Return _calculatedApprovalDate
            End Get
            Set(ByVal value As DateTime)
                _calculatedApprovalDate = value
            End Set
        End Property

        Public Property CalculatedExpiryDate() As DateTime
            Get
                Return _calculatedExpiryDate
            End Get
            Set(ByVal value As DateTime)
                _calculatedExpiryDate = value
            End Set
        End Property

        Public Property NotificationExpiryMinutes() As Int32
            Get
                Return _notificationExpiryMinutes
            End Get
            Set(ByVal value As Int32)
                _notificationExpiryMinutes = value
            End Set
        End Property

        Public Property Location() As String
            Get
                Return _location
            End Get
            Set(ByVal value As String)
                _location = value
            End Set
        End Property

        Public Property ApprovalAttribute() As String
            Get
                Return _approvalAttribute
            End Get
            Set(ByVal value As String)
                _approvalAttribute = value
            End Set
        End Property

        Public Property EmailTemplate() As String
            Get
                Return _emailTemplate
            End Get
            Set(ByVal value As String)
                _emailTemplate = value
            End Set
        End Property

        Public Property Reminder() As ApprovalReminderType
            Get
                Return _reminder
            End Get
            Set(ByVal value As ApprovalReminderType)
                _reminder = value
            End Set
        End Property

        Public Property Timing() As ApprovalTimingType
            Get
                Return _timing
            End Get
            Set(ByVal value As ApprovalTimingType)
                _timing = value
            End Set
        End Property

        Public Property OccurrenceMinutes() As Int32?
            Get
                Return _occurrenceMinutes
            End Get
            Set(ByVal value As Int32?)
                _occurrenceMinutes = value
            End Set
        End Property

        Public Property OccurredTime() As DateTime?
            Get
                Return _occurredTime
            End Get
            Set(ByVal value As DateTime?)
                _occurredTime = value
            End Set
        End Property

        Public Property SendNotificationRegardless() As Boolean
            Get
                Return _sendNotificationRegardless
            End Get
            Set(ByVal value As Boolean)
                _sendNotificationRegardless = value
            End Set
        End Property

        Public Function GetSchema() As System.Xml.Schema.XmlSchema Implements System.Xml.Serialization.IXmlSerializable.GetSchema
            Return Nothing
        End Function

        Public Sub ReadXml(ByVal reader As System.Xml.XmlReader) Implements System.Xml.Serialization.IXmlSerializable.ReadXml
            If reader.GetAttribute("OccurenceMinutes") = String.Empty Then
                _occurrenceMinutes = Nothing
            Else
                _occurrenceMinutes = Convert.ToInt32(reader.GetAttribute("OccurenceMinutes"))
            End If
            If reader.GetAttribute("OccurredTime") = String.Empty Then
                _occurredTime = Nothing
            Else
                _occurredTime = Convert.ToDateTime(reader.GetAttribute("OccurredTime"))
            End If
            If reader.GetAttribute("Reminder") = String.Empty Then
                _reminder = ApprovalReminderType.Outstanding
            Else
                _reminder = [Enum].Parse(GetType(ApprovalReminderType), reader.GetAttribute("Reminder"))
            End If

            If reader.GetAttribute("Timing") = String.Empty Then
                _timing = ApprovalTimingType.Monthly
            Else
                _timing = [Enum].Parse(GetType(ApprovalReminderType), reader.GetAttribute("Timing"))
            End If

            If reader.GetAttribute("SendNotificationRegardless") = String.Empty Then
                _sendNotificationRegardless = False
            Else
                _sendNotificationRegardless = Convert.ToBoolean(reader.GetAttribute("SendNotificationRegardless"))
            End If

            _emailTemplate = reader.GetAttribute("EmailTemplate")
            _location = reader.GetAttribute("Location")
            _notificationExpiryMinutes = Convert.ToInt32(reader.GetAttribute("NotificationExpiryMinutes"))
            _approvalAttribute = reader.GetAttribute("ApprovalAttribute")

        End Sub

        Public Sub WriteXml(ByVal writer As System.Xml.XmlWriter) Implements System.Xml.Serialization.IXmlSerializable.WriteXml

            If OccurrenceMinutes.HasValue Then
                writer.WriteAttributeString("OccurenceMinutes", _occurrenceMinutes.ToString())
            End If
            If OccurredTime.HasValue Then
                writer.WriteAttributeString("OccurredTime", _occurredTime.ToString())
            End If

            writer.WriteAttributeString("SendNotificationRegardless", _sendNotificationRegardless.ToString())
            writer.WriteAttributeString("Reminder", Convert.ToString(_reminder))
            writer.WriteAttributeString("Timing", Convert.ToString(_timing))
            writer.WriteAttributeString("EmailTemplate", _emailTemplate)
            writer.WriteAttributeString("Location", _location)
            writer.WriteAttributeString("ApprovalAttribute", _approvalAttribute)
            writer.WriteAttributeString("NotificationExpiryMinutes", _notificationExpiryMinutes.ToString)

        End Sub

        Public Overrides Function ToString() As String
            Return MyBase.ToString()
        End Function

        Public Enum ApprovalReminderType
            Upcoming
            Outstanding
        End Enum

        Public Enum ApprovalTimingType
            Monthly
            Quarterly
        End Enum
    End Class
End Namespace
