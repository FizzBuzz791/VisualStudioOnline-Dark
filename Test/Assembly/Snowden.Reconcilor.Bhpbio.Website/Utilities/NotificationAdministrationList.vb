Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.IO
Imports Snowden.Common

Namespace Utilities
    Public NotInheritable Class NotificationAdministrationList
        Inherits Core.Website.Utilities.NotificationAdministrationList

        Private _locationId As Integer

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            _locationId = RequestAsInt32("LocationId")
            If _locationId <= 0 Then
                _locationId = NullValues.Int32
            End If

        End Sub

        Protected Overrides Sub CreateNotificationListTable()
            Dim useColumns() As String = {"InstanceName", "TypeName", "OwnerUserName", "Location", "Active", "Actions"}

            NotificationListTable = New ReconcilorControls.ReconcilorTable(NotificationListData, useColumns)
            NotificationListTable.DataBind()
            NotificationListTable.Width = 735

            'Rename the header columns.
            With NotificationListTable.Columns
                With .Item("InstanceName")
                    .HeaderText = "Notification Name"
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 150
                End With
                With .Item("TypeName")
                    .HeaderText = "Notification Type"
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 200
                End With
                With .Item("Actions")
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 90
                End With
                With .Item("Active")
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 35
                End With
                With .Item("Location")
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 85
                End With
                With .Item("OwnerUserName")
                    .HeaderText = "Owner"
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                    .Width = 175
                End With
            End With
        End Sub

        Protected Overrides Sub CreateNotificationListData()
            MyBase.CreateNotificationListData()
            Dim notificationInLocation As Boolean

            NotificationListData.Columns.Add("Location", GetType(String), Nothing)

            For notificationInstanceIndex As Integer = 0 To NotificationListData.Rows.Count - 1

                NotificationListData(notificationInstanceIndex)("Location") = IsNotificationInLocation(Convert.ToInt32(NotificationListData(notificationInstanceIndex)("InstanceId")), _locationId, notificationInLocation)

                If Not notificationInLocation Then
                    NotificationListData(notificationInstanceIndex).Delete()
                End If
            Next

            NotificationListData.AcceptChanges()

        End Sub

        'Returns a null string if the notification instance is not in the location provided, Returns the name of the location if it is
        Private Function IsNotificationInLocation(ByVal notificationInstanceId As Int32, ByVal locationId As Int32, ByRef inLocation As Boolean) As String
            Dim locationName As String = Nothing
            Dim notificationInstance As DataTable
            Dim notificationTypeName As String
            Dim notificationLocationId As Int32 = NullValues.Int32

            'Set up default values to return.
            inLocation = False
            locationName = "N/A"
            notificationInstance = DalNotification.GetInstance(notificationInstanceId).Tables("Instance")
            notificationTypeName = DirectCast(notificationInstance.Rows(0)("TypeName"), String)

            Select Case notificationTypeName.ToLower
                Case "haulage"
                    'Determine if the notification type has a location assigned with it
                    notificationLocationId = Snowden.Common.Database.DataHelper. _
                        IfDBNull(DalNotification.GetInstanceHaulage(notificationInstanceId).Rows(0)("LocationId"), NullValues.Int32)
                Case "import"
                    inLocation = True
                Case "negative stockpile"
                    notificationLocationId = Snowden.Common.Database.DataHelper. _
                        IfDBNull(DalNotification.GetInstanceNegativeStockpile(notificationInstanceId).Rows(0)("LocationId"), NullValues.Int32)
                Case "inconsistent crusher deliveries"
                    notificationLocationId = Snowden.Common.Database.DataHelper. _
                        IfDBNull(DalNotification.GetInstanceCrusher(notificationInstanceId).Rows(0)("LocationId"), NullValues.Int32)
                Case "inconsistent plant deliveries"
                    notificationLocationId = Snowden.Common.Database.DataHelper. _
                        IfDBNull(DalNotification.GetInstancePlant(notificationInstanceId).Rows(0)("LocationId"), NullValues.Int32)
                Case "recalc"
                    inLocation = True
                Case Else
                    inLocation = True
            End Select

            'Get the location name if possible
            If notificationLocationId <> NullValues.Int32 Then
                locationName = Snowden.Common.Database.DataHelper. _
        IfDBNull(DalUtility.GetLocation(notificationLocationId).Rows(0)("Name"), "-")
            End If
            'If either the notification location or the actual location to filter by is null then, deem it in the location and show it.
            If notificationLocationId = NullValues.Int32 _
                Or locationId = NullValues.Int32 Then
                inLocation = True
            ElseIf DalUtility.GetLocationParentHeirarchy(notificationLocationId).Select("Location_Id = " + locationId.ToString).Length > 0 Then
                inLocation = True
            End If

            Return locationName
        End Function

    End Class
End Namespace
