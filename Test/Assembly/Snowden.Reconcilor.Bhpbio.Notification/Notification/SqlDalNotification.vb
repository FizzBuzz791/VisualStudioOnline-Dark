Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Notification
    Public Class SqlDalNotification
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.SqlDalBase
        Implements IDisposable

        Public Sub New(ByVal dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub


        Public Sub DeleteInstanceApproval(ByVal instanceId As Integer)
            DataAccess.CommandType = CommandObjectType.StoredProcedure
            DataAccess.CommandText = "dbo.DeleteInstanceApproval"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iInstanceId", CommandDataType.Int, CommandDirection.Input, instanceId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Function GetInstanceApproval(ByVal instanceId As Integer) As System.Data.DataTable

            DataAccess.CommandType = CommandObjectType.StoredProcedure
            DataAccess.CommandText = "dbo.GetBhpbioNotificationInstanceApproval"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iInstanceId", CommandDataType.Int, CommandDirection.Input, instanceId)

            Return DataAccess.ExecuteDataTable()
        End Function


        Public Sub SaveInstanceApproval(ByVal instanceId As Integer, ByVal tagGroupId As String, ByVal locationId As Integer)

            DataAccess.CommandType = CommandObjectType.StoredProcedure
            DataAccess.CommandText = "dbo.SaveBhpbioNotificationInstanceApproval"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iInstanceId", CommandDataType.Int, CommandDirection.Input, instanceId)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iTagGroupId", CommandDataType.VarChar, CommandDirection.Input, tagGroupId)

            DataAccess.ExecuteNonQuery()
        End Sub

    End Class
End Namespace
