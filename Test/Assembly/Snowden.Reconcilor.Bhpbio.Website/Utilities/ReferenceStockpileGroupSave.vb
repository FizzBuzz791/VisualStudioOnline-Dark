Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class ReferenceStockpileGroupSave
        Inherits Snowden.Reconcilor.Core.Website.Utilities.ReferenceStockpileGroupSave

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Dim dal = DirectCast(DalUtility, IUtility)

            dal.BhpbioDataExceptionStockpileGroupLocationMissing()
        End Sub

        Protected Overrides Function CanEditStockpileGroup(stockpileGroupId As String) As Boolean
            Dim dal = DirectCast(DalUtility, IUtility)

            ' IsAdmin, can always Edit
            '
            ' The ADMIN_USER role is actually only about being able to edit users, but it has been used elsewhere in the 
            ' application as a proxy for REC_ADMIN, and is set up exactly the same way, so I don't really see a problem with
            ' it being used that way for simplicity
            '
            If (Resources.UserSecurity.HasAccess("ADMIN_USER")) Then
                Return True
            Else
                ' Not Admin - will only be editable by these users if it NOT flaged as being an
                ' admin only table
                Return (Not dal.IsBhpbioStockpileGroupAdminEditable(stockpileGroupId))
            End If

        End Function
    End Class
End Namespace
