Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Import.Database
Imports IImportManager = Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IImportManager

Namespace SqlDal
    Public Class SqlDalImportManager
        Inherits ImportManager
        Implements IImportManager

        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub

        Function GetImportsRunningQueuedCount() As Int32 _
            Implements IImportManager.GetImportsRunningQueuedCount
            With DataAccess
                .CommandText = "GetBhpbioImportsRunningQueuedCount"

                With .ParameterCollection
                    .Clear()
                    .Add("@oNumImportsRunning", CommandDataType.Int, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@oNumImportsRunning").Value)
            End With
        End Function

        Function DoesQueuedBlocksJobExist(importId As Integer, site As String, pit As String, bench As String) As Boolean _
            Implements IImportManager.DoesQueuedBlocksJobExist

            With DataAccess
                .CommandText = "DoesBhpbioQueuedBlocksJobExist"

                With .ParameterCollection
                    .Clear()
                    .Add("@iImportId", CommandDataType.Int, CommandDirection.Input, importId)
                    .Add("@iSite", CommandDataType.VarChar, CommandDirection.Input, site)
                    .Add("@iPit", CommandDataType.VarChar, CommandDirection.Input, pit)
                    .Add("@iBench", CommandDataType.VarChar, CommandDirection.Input, bench)
                    .Add("@oExists", CommandDataType.Bit, CommandDirection.Output, Nothing)
                End With

                .ExecuteNonQuery()

                Return Convert.ToBoolean(.ParameterCollection("@oExists").Value)
            End With
        End Function

        Public Function GetBhpbioBlockImportSyncRowsForLocation(importId As Int16, _
            isCurrent As Int16, iSite As String, iPit As String, iBench As String) As IDataReader _
            Implements IImportManager.GetBhpbioBlockImportSyncRowsForLocation

            DataAccess.CommandText = "GetBhpbioBlockImportSyncRowsForLocation"
            DataAccess.ParameterCollection.Clear()

            DataAccess.ParameterCollection.Add("@iImportId", CommandDataType.SmallInt, CommandDirection.Input, importId)
            DataAccess.ParameterCollection.Add("@iIsCurrent", CommandDataType.Bit, isCurrent)
            DataAccess.ParameterCollection.Add("@iSite", CommandDataType.VarChar, iSite)
            DataAccess.ParameterCollection.Add("@iPit", CommandDataType.VarChar, iPit)
            DataAccess.ParameterCollection.Add("@iBench", CommandDataType.VarChar, iBench)
            Return DataAccess.ExecuteDataReader()

        End Function

        Public Function GetBhpbioNextSyncQueueEntryForLocation(orderNo As Long, importId As Int16, _
            iSite As String, iPit As String, iBench As String) As DataTable _
            Implements IImportManager.GetBhpbioNextSyncQueueEntryForLocation

            DataAccess.CommandText = "GetBhpbioNextSyncQueueEntryForLocation"
            DataAccess.ParameterCollection.Clear()

            DataAccess.ParameterCollection.Add("@iOrderNo", CommandDataType.BigInt, CommandDirection.Input, orderNo)
            DataAccess.ParameterCollection.Add("@iImportId", CommandDataType.SmallInt, CommandDirection.Input, importId)
            DataAccess.ParameterCollection.Add("@iSite", CommandDataType.VarChar, iSite)
            DataAccess.ParameterCollection.Add("@iPit", CommandDataType.VarChar, iPit)
            DataAccess.ParameterCollection.Add("@iBench", CommandDataType.VarChar, iBench)
            Return DataAccess.ExecuteDataTable

        End Function

        Public Function GetBhpbioImportList(validationFromDate As DateTime, month As Integer, year As Integer, locationId As Integer,
                                            useMonthLocation As Boolean, Optional ByVal isActive As Boolean = True) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioImportList"
                .CommandType = CommandObjectType.StoredProcedure
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iValidationFromDate", CommandDataType.DateTime, CommandDirection.Input, validationFromDate)
                .ParameterCollection.Add("@iMonth", CommandDataType.Int, CommandDirection.Input, month)
                .ParameterCollection.Add("@iYear", CommandDataType.Int, CommandDirection.Input, year)
                .ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                .ParameterCollection.Add("@iUseMonthLocation", CommandDataType.Bit, CommandDirection.Input, useMonthLocation)
                .ParameterCollection.Add("@iActive", CommandDataType.Bit, CommandDirection.Input, isActive)

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioImportSyncValidateGrouping(importId As Int16, validationFromDate As Date, _
            month As Integer, year As Integer, locationId As Integer, locationName As String, locationType As String, _
            useMonthLocation As Boolean) As DataTable

            With DataAccess
                .CommandText = "dbo.GetBhpbioImportSyncValidateGrouping"
                .ParameterCollection.Clear()
                With .ParameterCollection
                    .Add("@iImportId", CommandDataType.SmallInt, importId)
                    .Add("@iValidationFromDate", CommandDataType.DateTime, validationFromDate)
                    .Add("@iMonth", CommandDataType.Int, CommandDirection.Input, month)
                    .Add("@iYear", CommandDataType.Int, CommandDirection.Input, year)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iLocationName", CommandDataType.VarChar, CommandDirection.Input, locationName)
                    .Add("@iLocationType", CommandDataType.VarChar, CommandDirection.Input, locationType)
                    .Add("@iUseMonthLocation", CommandDataType.Bit, CommandDirection.Input, useMonthLocation)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioImportExceptionGrouping(importId As Int16, validationFromDate As Date) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioImportExceptionGrouping"
                .ParameterCollection.Clear()
                With .ParameterCollection
                    .Add("@iImportId", CommandDataType.SmallInt, importId)
                    .Add("@iValidationFromDate", CommandDataType.DateTime, validationFromDate)
                End With
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioImportSyncValidateRecords(userMessage As String, importId As Int16, page As Int32, _
            pageSize As Int32, validationDateFrom As Date, month As Integer, year As Integer, locationId As Integer, _
            locationName As String, locationType As String, useMonthLocation As Boolean) As DataSet

            Dim result As DataSet

            DataAccess.CommandType = CommandObjectType.StoredProcedure
            DataAccess.CommandText = "dbo.GetBhpbioImportSyncValidateRecords"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iImportId", CommandDataType.SmallInt, importId)
            DataAccess.ParameterCollection.Add("@iUserMessage", CommandDataType.VarChar, -1, userMessage)
            DataAccess.ParameterCollection.Add("@iPage", CommandDataType.Int, page)
            DataAccess.ParameterCollection.Add("@iPageSize", CommandDataType.Int, pageSize)
            DataAccess.ParameterCollection.Add("@iValidationFromDate", CommandDataType.DateTime, validationDateFrom)
            DataAccess.ParameterCollection.Add("@iMonth", CommandDataType.Int, CommandDirection.Input, month)
            DataAccess.ParameterCollection.Add("@iYear", CommandDataType.Int, CommandDirection.Input, year)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iLocationName", CommandDataType.VarChar, CommandDirection.Input, locationName)
            DataAccess.ParameterCollection.Add("@iLocationType", CommandDataType.VarChar, CommandDirection.Input, locationType)
            DataAccess.ParameterCollection.Add("@iUseMonthLocation", CommandDataType.Bit, CommandDirection.Input, useMonthLocation)

            result = DataAccess.ExecuteDataSet()
            result.Tables(0).TableName = "Result"
            result.Tables(1).TableName = "LastPage"

            Return result
        End Function


        Public Function GetBhpbioImportExceptionRecords(userMessage As String, importId As Int16, page As Int32, pageSize As Int32, validationDateFrom As Date) As DataSet

            Dim result As DataSet

            DataAccess.CommandType = CommandObjectType.StoredProcedure
            DataAccess.CommandText = "dbo.GetBhpbioImportExceptionRecords"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iImportId", CommandDataType.SmallInt, importId)
            DataAccess.ParameterCollection.Add("@iUserMessage", CommandDataType.VarChar, -1, userMessage)
            DataAccess.ParameterCollection.Add("@iPage", CommandDataType.Int, page)
            DataAccess.ParameterCollection.Add("@iPageSize", CommandDataType.Int, pageSize)
            DataAccess.ParameterCollection.Add("@iValidationFromDate", CommandDataType.DateTime, validationDateFrom)

            result = DataAccess.ExecuteDataSet()
            result.Tables(0).TableName = "Result"
            result.Tables(1).TableName = "LastPage"

            Return result
        End Function

        Public Function GetLookbackImportErrorsCount(validationFromDate As DateTime) As DataTable

            With DataAccess
                .CommandText = "dbo.GetBhpbioImportErrorCount"
                .CommandType = CommandObjectType.StoredProcedure
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iValidationFromDate", CommandDataType.DateTime, CommandDirection.Input, validationFromDate)
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBlockModelResourceClassification(Optional ByVal blockModelResourceClassificationId As Integer = -1) As DataTable _
            Implements IImportManager.GetBlockModelResourceClassification
            With DataAccess
                .CommandText = "Staging.GetBlockModelResourceClassification"
                .CommandType = CommandObjectType.StoredProcedure
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iBlockModelResourceClassificationId", CommandDataType.Int, CommandDirection.Input, blockModelResourceClassificationId)
                Return .ExecuteDataTable
            End With
        End Function
        Public Sub DeleteBlockModelResourceClassification(blockModelId As Integer, resourceClassification As String) _
        Implements IImportManager.DeleteBlockModelResourceClassification
            With DataAccess
                .CommandText = "Staging.DeleteBlockModelResourceClassification"

                With .ParameterCollection
                    .Clear()

                    .Add("@iBlockModelId", CommandDataType.Int, CommandDirection.Input, 31, blockModelId)
                    .Add("@iResourceClassification", CommandDataType.VarChar, CommandDirection.Input, resourceClassification)
                End With
                .ExecuteNonQuery()
            End With
        End Sub
        Public Sub AddUpdateBlockModelResourceClassification(blockModelId As Integer, resourceClassification As String, percentage As Double) _
       Implements IImportManager.AddUpdateBlockModelResourceClassification
            With DataAccess
                .CommandText = "Staging.AddUpdateBlockModelResourceClassification"

                With .ParameterCollection
                    .Clear()

                    .Add("@iBlockModelId", CommandDataType.Int, CommandDirection.Input, 31, blockModelId)
                    .Add("@iResourceClassification", CommandDataType.VarChar, CommandDirection.Input, resourceClassification)
                    .Add("@iPercentage", CommandDataType.Float, CommandDirection.Input, percentage)
                End With
                .ExecuteNonQuery()
            End With
        End Sub
    End Class
End Namespace