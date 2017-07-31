Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper

Namespace SqlDal
    Public Class SqlDalStockpile
        Inherits Reconcilor.Core.Database.SqlDal.SqlDalStockpile
        Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile

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

        Public Overridable Overloads Function GetStockpileList(ByVal groupByStockpileGroups As Int16, _
           ByVal stockpileGroupId As String, _
           ByVal stockpileName As String, _
           ByVal isVisible As Int16, _
           ByVal materialTypeId As Int32, _
           ByVal sortType As Int32, _
           ByVal includeGrades As Int16, _
           ByVal startDate As DateTime, _
           ByVal endDate As DateTime, _
           ByVal locationId As Int32, _
           ByVal recordLimit As Int32, _
           ByVal gradeVisibility As Int16, _
           ByVal transactionStartDate As DateTime, _
           ByVal transactionEndDate As DateTime) As DataTable Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile.GetStockpileList

            With DataAccess
                .CommandText = "dbo.GetBhpbioStockpileList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iGroup_By_Stockpile_Groups", CommandDataType.Bit, CommandDirection.Input, groupByStockpileGroups)
                    .Add("@iStockpile_Group_Id", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileGroupId)
                    .Add("@iStockpile_Name", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileName)
                    .Add("@iIs_Visible", CommandDataType.Bit, CommandDirection.Input, isVisible)
                    .Add("@iMaterial_Type_Id", CommandDataType.Int, CommandDirection.Input, materialTypeId)
                    .Add("@iSort_Type", CommandDataType.Int, CommandDirection.Input, sortType)
                    .Add("@iInclude_Grades", CommandDataType.Bit, CommandDirection.Input, includeGrades)
                    .Add("@iFilterStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iFilterEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                    .Add("@iGrade_Visibility", CommandDataType.Bit, CommandDirection.Input, gradeVisibility)
                    .Add("@iTransactionStartDate", CommandDataType.DateTime, CommandDirection.Input, transactionStartDate)
                    .Add("@iTransactionEndDate", CommandDataType.DateTime, CommandDirection.Input, transactionEndDate)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Overridable Overloads Function GetStockpileListByGroups(ByVal groupByStockpileGroups As Int16, _
           ByVal stockpileGroupId As String, _
           ByVal stockpileName As String, _
           ByVal isVisible As Int16, _
           ByVal materialTypeId As Int32, _
           ByVal sortType As Int32, _
           ByVal includeGrades As Int16, _
           ByVal startDate As DateTime, _
           ByVal endDate As DateTime, _
           ByVal locationId As Int32, _
           ByVal recordLimit As Int32, _
           ByVal gradeVisibility As Int16, _
           ByVal transactionStartDate As DateTime, _
           ByVal transactionEndDate As DateTime, _
           ByVal stockpileGroupsXml As String, _
           ByVal includeLocationsBelow As Boolean) As DataTable Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile.GetStockpileListByGroups

            With DataAccess
                .CommandText = "dbo.GetBhpbioStockpileListByGroups"

                With .ParameterCollection
                    .Clear()

                    .Add("@iGroup_By_Stockpile_Groups", CommandDataType.Bit, CommandDirection.Input, groupByStockpileGroups)
                    .Add("@iStockpile_Group_Id", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileGroupId)
                    .Add("@iStockpile_Name", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileName)
                    .Add("@iIs_Visible", CommandDataType.Bit, CommandDirection.Input, isVisible)
                    .Add("@iMaterial_Type_Id", CommandDataType.Int, CommandDirection.Input, materialTypeId)
                    .Add("@iSort_Type", CommandDataType.Int, CommandDirection.Input, sortType)
                    .Add("@iInclude_Grades", CommandDataType.Bit, CommandDirection.Input, includeGrades)
                    .Add("@iFilterStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iFilterEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                    .Add("@iGrade_Visibility", CommandDataType.Bit, CommandDirection.Input, gradeVisibility)
                    .Add("@iTransactionStartDate", CommandDataType.DateTime, CommandDirection.Input, transactionStartDate)
                    .Add("@iTransactionEndDate", CommandDataType.DateTime, CommandDirection.Input, transactionEndDate)
                    .Add("@iStockpileGroupsXml", CommandDataType.VarChar, CommandDirection.Input, stockpileGroupsXml)
                    .Add("@iIncludeLocationsBelow", CommandDataType.Bit, CommandDirection.Input, includeLocationsBelow)
                End With


                Return .ExecuteDataTable
            End With
        End Function

        Sub AddBhpbioStockpileDeletionState(ByVal stockpileName As String) Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile.AddBhpbioStockpileDeletionState
            With DataAccess
                .CommandText = "dbo.AddBhpbioStockpileDeletionState"
                With .ParameterCollection
                    .Clear()
                    .Add("@iStockpileName", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileName)
                End With
                .ExecuteNonQuery()
            End With
        End Sub

        Sub ClearBhpbioStockpileDeletionState(ByVal stockpileName As String, ByRef previousDeletionState As Boolean, ByRef matchingStockpileId As Integer) Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IStockpile.ClearBhpbioStockpileDeletionState
            With DataAccess
                .CommandText = "dbo.ClearBhpbioStockpileDeletionState"
                With .ParameterCollection
                    .Clear()
                    .Add("@iStockpileName", CommandDataType.VarChar, CommandDirection.Input, 31, stockpileName)
                    .Add("@oPreviousDeletionState", CommandDataType.Bit, CommandDirection.Output, 0)
                    .Add("@oMatchingStockpileId", CommandDataType.Int, CommandDirection.Output, 0)
                End With

                .ExecuteNonQuery()

                previousDeletionState = DirectCast(.ParameterCollection("@oPreviousDeletionState").Value, Boolean)

                If .ParameterCollection("@oMatchingStockpileId").Value Is DBNull.Value Then
                    matchingStockpileId = NullValues.Int32
                Else
                    matchingStockpileId = DirectCast(.ParameterCollection("@oMatchingStockpileId").Value, Integer)
                End If

            End With
        End Sub
    End Class
End Namespace
