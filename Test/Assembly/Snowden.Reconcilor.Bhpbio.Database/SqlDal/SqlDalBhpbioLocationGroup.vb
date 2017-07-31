Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalBhpbioLocationGroup
        Inherits Common.Database.SqlDataAccessBaseObjects.SqlDalBase
        Implements Bhpbio.Database.DalBaseObjects.IBhpbioLocationGroup

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

        Public Function GetBhpbioLocationGroup(locationGroupId As Integer) As DataTable _
            Implements DalBaseObjects.IBhpbioLocationGroup.GetBhpbioLocationGroup
            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationGroup"
                .CommandType = CommandObjectType.StoredProcedure

                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationGroupId", CommandDataType.Int, CommandDirection.Input, locationGroupId)
                Return .ExecuteDataTable()
            End With
        End Function
    End Class
End Namespace
