Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace SqlDal
    Public Class SqlDalSecurityLocation
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.SqlDalBase
        Implements Bhpbio.Database.DalBaseObjects.ISecurityLocation

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

        Public Function GetBhpbioUserLocation(ByVal userId As Int32) As Int32 _
         Implements DalBaseObjects.ISecurityLocation.GetBhpbioUserLocation
            DataAccess.CommandText = "dbo.GetBhpbioUserLocation"
            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, -1, userId)
            DataAccess.ParameterCollection.Add("@oLocationId", CommandDataType.Int, CommandDirection.Output, -1)
            DataAccess.ExecuteNonQuery()

            Return Snowden.Common.Database.DataHelper.IfDBNull(DataAccess.ParameterCollection.Item("@oLocationId").Value, NullValues.Int32)
        End Function

        Public Function IsBhpbioUserInLocation(ByVal userId As Int32, ByVal locationId As Int32) As Boolean _
         Implements DalBaseObjects.ISecurityLocation.IsBhpbioUserInLocation
            With DataAccess
                .CommandText = "dbo.IsBhpbioUserInLocation"

                With .ParameterCollection
                    .Clear()

                    .Add("@iUserId", CommandDataType.Int, CommandDirection.Input, -1, userId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@oIsInLocation", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oIsInLocation").Value)
            End With
        End Function

        Public Sub SetDigblockTreeUserDefaults(ByVal locationId As Int32, ByVal userId As Int32) _
         Implements DalBaseObjects.ISecurityLocation.SetDigblockTreeUserDefaults

            DataAccess.CommandText = "dbo.SetDigblockTreeUserDefaults"
            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
            DataAccess.ExecuteNonQuery()
        End Sub

        Public Function IsDigblockTreeUserSettingAvailable(ByVal userId As Int32) As Boolean _
         Implements DalBaseObjects.ISecurityLocation.IsDigblockTreeUserSettingAvailable

            DataAccess.CommandText = "dbo.IsDigblockTreeUserSettingAvailable"
            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
            DataAccess.ParameterCollection.Add("@oSettingAvailable", CommandDataType.Bit, CommandDirection.Output, -1)
            DataAccess.ExecuteNonQuery()

            Return Convert.ToBoolean(DataAccess.ParameterCollection.Item("@oSettingAvailable").Value)
        End Function

        Public Function GetBhpbioUserLocationList(ByVal userId As Integer) As DataTable Implements DalBaseObjects.ISecurityLocation.GetBhpbioUserLocationList
            DataAccess.CommandText = "dbo.GetBhpbioUserLocationList"
            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, -1, userId)
            Return DataAccess.ExecuteDataTable()
        End Function
    End Class
End Namespace
