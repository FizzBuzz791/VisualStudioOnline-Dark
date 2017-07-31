Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace ReconcilorControls.NotificationParts
    Public NotInheritable Class ApprovalNotificationUI
        Inherits Reconcilor.Core.WebDevelopment.ReconcilorControls.NotificationParts.NotificationUI

        Private _approvalData As ApprovalNotificationData

        Protected Overrides Sub Initialise()
            InstanceData = New ApprovalNotificationData
            'Create a reference on this class
            _approvalData = DirectCast(InstanceData, ApprovalNotificationData)
            _approvalData.Initialise(Resources.Connection, InstanceId)
            SetTypeDetailRefreshQueryString = "'LocationId='+document.getElementById('LocationId').value"
        End Sub


        Protected Overrides Function GenerateDetail() As System.Collections.Generic.IList(Of System.Web.UI.Control)
            Dim controlList As New List(Of Web.UI.Control)
            Dim screen As New Tags.HtmlTableTag
            Dim notificationFilterLayoutBox As New GroupBox
            Dim occurrenceDays As New InputTags.InputTextFormless
            Dim emailMessage As New InputTags.InputTextArea
            Dim sendEmailRegardless As New InputTags.InputCheckBoxFormless
            Dim timingSelection As New InputTags.SelectBoxFormless
            Dim reminderSelection As New InputTags.SelectBoxFormless
            Dim occurrenceTimespan As TimeSpan
            Dim notificationExpiryTimespan As TimeSpan
            Dim notificationExpiryDays As New InputTags.InputTextFormless
            Dim tagSelectBox As New InputTags.SelectBoxFormless()

            With notificationFilterLayoutBox
                .Width = 600
                .Title = "<b>Approval Parameters</b>"
            End With

            With emailMessage
                .ID = "EmailMessage"
                .Cols = 60
                .Rows = 6
                .Value = _approvalData.ApprovalThreshold.EmailTemplate
            End With


            tagSelectBox.ID = "TagGroupId"
            tagSelectBox.DataSource = _approvalData.TagList
            tagSelectBox.DataValueField = "TagGroupId"
            tagSelectBox.DataTextField = "TagGroupId"
            tagSelectBox.DataBind()
            tagSelectBox.Items.Insert(0, New ListItem("(All Tags)", ""))
            If Not _approvalData.TagGroupId Is Nothing Then
                tagSelectBox.Value = _approvalData.TagGroupId
            End If

            With sendEmailRegardless
                .ID = "SendEmailRegardless"
                .Checked = _approvalData.ApprovalThreshold.SendNotificationRegardless
            End With

            With timingSelection
                .ID = "TimingType"
                .Items.Add(New ListItem(Notification.ApprovalValue.ApprovalTimingType.Monthly.ToString, Convert.ToString(Notification.ApprovalValue.ApprovalTimingType.Monthly)))
                .Items.Add(New ListItem(Notification.ApprovalValue.ApprovalTimingType.Quarterly.ToString, Convert.ToString(Notification.ApprovalValue.ApprovalTimingType.Quarterly)))
                If Not InstanceId Is Nothing Then
                    .Value = Convert.ToString(_approvalData.ApprovalThreshold.Timing)
                End If
            End With

            With reminderSelection
                .ID = "ReminderType"
                .Items.Add(New ListItem(Notification.ApprovalValue.ApprovalReminderType.Outstanding.ToString, Convert.ToString(Notification.ApprovalValue.ApprovalReminderType.Outstanding)))
                .Items.Add(New ListItem(Notification.ApprovalValue.ApprovalReminderType.Upcoming.ToString, Convert.ToString(Notification.ApprovalValue.ApprovalReminderType.Upcoming)))
                If Not InstanceId Is Nothing Then
                    .Value = Convert.ToString(_approvalData.ApprovalThreshold.Reminder)
                End If
            End With

            With occurrenceDays
                .ID = "OccurrenceDays"
                .Width = 30
            End With

            With notificationExpiryDays
                .ID = "NotificationExpiryDays"
                .Width = 30
            End With

            With screen
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("Tag:&nbsp;"))
                .AddCell()
                .CurrentCell.Controls.Add(tagSelectBox)
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;Approval Period:&nbsp;"))
                .AddCell()
                .CurrentCell.Controls.Add(timingSelection)
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;Remind When Approval Is&nbsp;"))
                .CurrentCell.Controls.Add(reminderSelection)

                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;&nbsp;within the next or last&nbsp;&nbsp;"))
                .CurrentCell.Controls.Add(occurrenceDays)
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;&nbsp;days&nbsp;&nbsp;"))
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;Expire After&nbsp;"))
                .CurrentCell.Controls.Add(notificationExpiryDays)
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;&nbsp;days&nbsp;&nbsp;"))
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(sendEmailRegardless)
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;Send notification even if approvals have been completed"))
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;Email Message Format:&nbsp;"))
                .CurrentCell.VerticalAlign = VerticalAlign.Top
                .AddCell()
                .CurrentCell.Controls.Add(emailMessage)

                If Not InstanceId Is Nothing Then
                    If _approvalData.ApprovalThreshold.OccurrenceMinutes.HasValue Then
                        occurrenceTimespan = TimeSpan.FromMinutes(_approvalData.ApprovalThreshold.OccurrenceMinutes.Value)
                        occurrenceDays.Value = occurrenceTimespan.TotalDays.ToString
                    End If

                    notificationExpiryTimespan = TimeSpan.FromMinutes(_approvalData.ApprovalThreshold.NotificationExpiryMinutes)
                    notificationExpiryDays.Value = notificationExpiryTimespan.TotalDays.ToString
                End If

            End With

            notificationFilterLayoutBox.Controls.Add(screen)
            controlList.Add(notificationFilterLayoutBox)

            Return controlList
        End Function

        Protected Overrides Function GenerateHeader() As System.Collections.Generic.IList(Of System.Web.UI.Control)

            Dim controlList As New List(Of Web.UI.Control)
            Dim notificationFilterLayoutBox As New GroupBox
            Dim screen As New Tags.HtmlTableTag
            Dim locationControlFilter As New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector

            'Set up the notifications layout box.
            With notificationFilterLayoutBox
                .Width = 600
                .Title = "<b>Approval Filters</b>"
            End With

            With locationControlFilter
                .ID = "LocationId"
                .DalUtility = InstanceData.DalUtility
                .LocationLabelCellWidth = 95
                .LowestLocationTypeDescription = "Pit"
                .LocationId = _approvalData.LocationId
                .OmitInitialChange = True
                .InitialLoad = True
                .OnChange = "javascript:" & GetRefreshTypeDetailJavascript()
            End With

            With screen
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(locationControlFilter)
            End With

            notificationFilterLayoutBox.Controls.Add(screen)

            controlList.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            controlList.Add(notificationFilterLayoutBox)
            controlList.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))

            Return controlList

        End Function


    End Class
End Namespace
