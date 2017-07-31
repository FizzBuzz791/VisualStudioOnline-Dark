Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalDigblock
        Inherits Snowden.Reconcilor.Core.Database.SqlDal.SqlDalDigblock
        Implements IDigblock

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

        Public Function GetBhpbioReconciliationMovements(ByVal locationId As Int32) As DataTable _
        Implements IDigblock.GetBhpbioReconciliationMovements
            With DataAccess
                .CommandText = "dbo.GetBhpbioReconciliationMovements"
                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetDigblockModelBlockGradeOverPeriod(ByVal locationId As Int32, _
         ByVal blockModelId As Int32, ByVal gradeId As Int32) As DataTable Implements IDigblock.GetDigblockModelBlockGradeOverPeriod
            With DataAccess
                .CommandText = "dbo.GetBhpbioDigblockModelBlockGradeOverPeriod"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iBlockModelId", CommandDataType.Int, CommandDirection.Input, blockModelId)
                    .Add("@iGradeID", CommandDataType.Int, CommandDirection.Input, gradeID)
                End With
                Try
                    Return .ExecuteDataTable
                Catch ex As Exception
                    Throw
                End Try
            End With

        End Function

        Public Function GetDigblockHaulageGradeOverRange(ByVal locationId As Int32, _
         ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal gradeId As Int32) As DataTable Implements IDigblock.GetDigblockHaulageGradeOverRange
            With DataAccess
                .CommandText = "dbo.GetBhpbioDigblockHaulageGradeOverRange"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iGradeID", CommandDataType.Int, CommandDirection.Input, gradeId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Overridable Function GetDigblockReconciledGradeOverPeriod(ByVal locationId As Int32, _
         ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal gradeId As Int32) As DataTable Implements IDigblock.GetDigblockReconciledGradeOverPeriod
            With DataAccess
                .CommandText = "dbo.GetBhpbioDigblockReconciledGradeOverPeriod"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iGradeID", CommandDataType.Int, CommandDirection.Input, gradeId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioDigblockPolygonList(ByVal locationId As Int32, _
         ByVal materialCategoryId As String, ByVal rootMaterialTypeId As Int32) As DataTable _
         Implements Bhpbio.Database.DalBaseObjects.IDigblock.GetBhpbioDigblockPolygonList

            DataAccess.CommandText = "dbo.GetBhpbioDigblockPolygonList"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iMaterialCategoryId", CommandDataType.VarChar, CommandDirection.Input, 31, materialCategoryId)
            DataAccess.ParameterCollection.Add("@iRootMaterialTypeId", CommandDataType.Int, CommandDirection.Input, rootMaterialTypeId)

            Return DataAccess.ExecuteDataTable()
        End Function

        Public Overridable Function GetBhpbioDigblockDetailList(ByVal digblockId As String, ByVal includeBlockModels As Int16, _
                                                                ByVal includeMinePlans As Int16, ByVal gradeVisibility As Int16, _
                                                                Optional ByVal includeLumpFines As Int16 = 0) As DataTable
            With DataAccess
                .CommandText = "GetBhpbioDigblockDetailList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDigblock_Id", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
                    .Add("@iIncludeBlockModels", CommandDataType.Bit, CommandDirection.Input, includeBlockModels)
                    .Add("@iIncludeMinePlans", CommandDataType.Bit, CommandDirection.Input, includeMinePlans)
                    .Add("@iGrade_Visibility", CommandDataType.Bit, CommandDirection.Input, gradeVisibility)
                    .Add("@iIncludeLumpFines", CommandDataType.Bit, CommandDirection.Input, includeLumpFines)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function DoesBhpbioDigblockNotesExist(ByVal digblockNotesField As String, ByVal digblockNotes As String) As Boolean _
        Implements Bhpbio.Database.DalBaseObjects.IDigblock.DoesBhpbioDigblockNotesExist
            Dim exists As Boolean = False
            With DataAccess
                .CommandText = "Select dbo.DoesBhpbioDigblockNotesExist('" + digblockNotesField + "','" + digblockNotes + "')"
                .CommandType = CommandObjectType.InlineSql
                .ParameterCollection.Clear()
                exists = Convert.ToBoolean(IIf(Convert.ToInt16(.ExecuteScalar2()) = 1, True, False))
                .CommandType = CommandObjectType.StoredProcedure
            End With
            Return exists

        End Function

        Public Function GetBhpbioDigblockFieldNotes(ByVal digblockId As String, ByVal digblockNotesField As String) As String _
         Implements Bhpbio.Database.DalBaseObjects.IDigblock.GetBhpbioDigblockFieldNotes
            Dim notes As String = ""

            DataAccess.CommandText = "dbo.GetBhpbioDigblockFieldNotes"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
            DataAccess.ParameterCollection.Add("@iDigblockFieldId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockNotesField)
            DataAccess.ParameterCollection.Add("@oNotes", CommandDataType.VarChar, CommandDirection.Output, 1023, notes)

            DataAccess.ExecuteNonQuery()
            notes = Convert.ToString(IIf(DataAccess.ParameterCollection("@oNotes").Value Is DBNull.Value, NullValues.String, DataAccess.ParameterCollection("@oNotes").Value))
            Return notes
        End Function

        Public Function DoesBhpbioDigblockHaulageExist(digblockId As String) As Boolean _
            Implements IDigblock.DoesBhpbioDigblockHaulageExist
            Dim exists As Boolean
            With DataAccess
                .CommandText = "Select dbo.DoesBhpbioDigblockHaulageExist('" + digblockId + "')"
                .CommandType = CommandObjectType.InlineSql
                .ParameterCollection.Clear()
                exists = Convert.ToBoolean(Convert.ToInt16(.ExecuteScalar2()) = 1)
                .CommandType = CommandObjectType.StoredProcedure
            End With
            Return exists
        End Function

        Public Function DoesBhpbioDigblockAssociationsExist(ByVal digblockId As String) As Boolean _
         Implements Bhpbio.Database.DalBaseObjects.IDigblock.DoesBhpbioDigblockAssociationsExist
            Dim exists As Boolean = False
            With DataAccess
                .CommandText = "Select dbo.DoesBhpbioDigblockAssociationsExist('" + digblockId + "')"
                .CommandType = CommandObjectType.InlineSql
                .ParameterCollection.Clear()
                exists = Convert.ToBoolean(IIf(Convert.ToInt16(.ExecuteScalar2()) = 1, True, False))
                .CommandType = CommandObjectType.StoredProcedure
            End With
            Return exists

        End Function

        Public Sub ResolveBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String) Implements IDigblock.ResolveBhpbioDataExceptionDigblockHasHaulage
            DataAccess.CommandText = "dbo.ResolveBhpbioDataExceptionDigblockHasHaulage"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)
            
            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub DeleteBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String) Implements IDigblock.DeleteBhpbioDataExceptionDigblockHasHaulage
            DataAccess.CommandText = "dbo.DeleteBhpbioDataExceptionDigblockHasHaulage"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub AddOrActivateBhpbioDataExceptionDigblockHasHaulage(ByVal digblockId As String) Implements IDigblock.AddOrActivateBhpbioDataExceptionDigblockHasHaulage
            DataAccess.CommandText = "dbo.AddOrActivateBhpbioDataExceptionDigblockHasHaulage"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDigblockId", CommandDataType.VarChar, CommandDirection.Input, 31, digblockId)

            DataAccess.ExecuteNonQuery()
        End Sub


        Function GetBhpbioResourceClassificationData(ByVal digblock As String) As DataTable _
       Implements IDigblock.GetBhpbioResourceClassificationData

            'trocar 
            DataAccess.CommandText = "Staging.GetBhpbioResourceClassificationData"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iDigblock", CommandDataType.VarChar, CommandDirection.Input, digblock)

            Return DataAccess.ExecuteDataTable()
        End Function
    End Class
End Namespace
