Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper

Namespace SqlDal
    Public Class SqlDalDepletion
        Inherits Reconcilor.Core.Database.SqlDal.SqlDalDepletion
        Implements IDepletion

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

        Public Overrides Function GetDigblockPolygonWithinRange(ByVal maxX As Double, _
            ByVal minX As Double, _
            ByVal maxY As Double, _
            ByVal minY As Double, _
            ByVal z As Double, _
            ByVal digblockId As String) As System.Data.DataTable

            With DataAccess
                .CommandText = "GetBHPBIODigblockPolygonWithinRangeAndBench"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblock_Id", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@iMaxX", CommandDataType.Float, CommandDirection.Input, maxX)
                    .Add("@iMinX", CommandDataType.Float, CommandDirection.Input, minX)
                    .Add("@iMaxY", CommandDataType.Float, CommandDirection.Input, maxY)
                    .Add("@iMinY", CommandDataType.Float, CommandDirection.Input, minY)
                    .Add("@iZ", CommandDataType.Int, CommandDirection.Input, Convert.ToInt32(z))
                End With

                Return .ExecuteDataTable
            End With
        End Function

    End Class
End Namespace
