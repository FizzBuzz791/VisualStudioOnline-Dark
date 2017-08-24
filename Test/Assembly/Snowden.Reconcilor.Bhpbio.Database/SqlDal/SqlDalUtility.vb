Imports System.Data.SqlClient
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports CommonDataHelper = Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Core
Imports System.Data.SqlTypes

Namespace SqlDal
    Public Class SqlDalUtility
        Inherits Core.Database.SqlDal.SqlDalUtility
        Implements IUtility

#Region " Constructors "
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(connectionString As String)
            MyBase.New(connectionString)
        End Sub

        Public Sub New(databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
        End Sub

        Public Sub New(dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        Public Function IsBhpbioStockpileGroupAdminEditable(stockpileGroup As String) As Boolean _
        Implements IUtility.IsBhpbioStockpileGroupAdminEditable
            With DataAccess
                .CommandText = "dbo.IsStockpileGroupAdminEditable"

                With .ParameterCollection
                    .Clear()
                    .Add("@stockpileGroupId", CommandDataType.VarChar, CommandDirection.Input, 50, stockpileGroup.Trim())
                    .Add("@oReturn", CommandDataType.Bit, CommandDirection.Output, -1)
                End With

                .ExecuteNonQuery()
                Return Convert.ToBoolean(.ParameterCollection.Item("@oReturn").Value)
            End With
        End Function

        Public Function GetBhpbioCustomMessage(messageName As String) As DataTable Implements IUtility.GetBhpbioCustomMessage
            With DataAccess
                .CommandText = "dbo.GetBhpbioCustomMessages"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iName", CommandDataType.VarChar, messageName)
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioCustomMessages() As DataTable Implements IUtility.GetBhpbioCustomMessages
            With DataAccess
                .CommandText = "dbo.GetBhpbioCustomMessages"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Public Sub DeleteBhpbioCustomMessage(name As String) Implements IUtility.DeleteBhpbioCustomMessage
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioCustomMessage"
                With .ParameterCollection
                    .Clear()
                    .Add("@iName", CommandDataType.VarChar, CommandDirection.Input, 63, name)
                End With
                .ExecuteNonQuery()
            End With
        End Sub

        Public Function BhpbioGetBlockedDateForLocation(locationId As Integer, locationDate As DateTime) As DateTime? Implements IUtility.BhpbioGetBlockedDateForLocation
            ' turns out the only way to execute scalar functions is with inline sql
            With DataAccess
                .CommandType = CommandObjectType.InlineSql
                .CommandText = $"Select dbo.BhpbioGetBlockedDateForLocation({locationId}, '{locationDate:yyyy-MM-dd}')"
            End With

            Dim result = DataAccess.ExecuteScalar2()

            If IsDBNull(result) Then
                Return Nothing
            Else
                Return Convert.ToDateTime(result)
            End If

        End Function

        Public Sub AddOrUpdateBhpbioCustomMessage(name As String, updateText As Int16, text As String,
                                                  updateExpirationDate As Int16, expirationDate As DateTime,
                                                  updateIsActive As Int16, isActive As Int16) Implements IUtility.AddOrUpdateBhpbioCustomMessage
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioCustomMessage"
                With .ParameterCollection
                    .Clear()

                    .Add("@iName", CommandDataType.VarChar, CommandDirection.Input, 63, name)
                    .Add("@iUpdateText", CommandDataType.Bit, CommandDirection.Input, updateText)
                    .Add("@iText", CommandDataType.VarChar, CommandDirection.Input, text)
                    .Add("@iUpdateExpirationDate", CommandDataType.Bit, CommandDirection.Input, updateExpirationDate)
                    .Add("@iExpirationDate", CommandDataType.DateTime, CommandDirection.Input, expirationDate)
                    .Add("@iUpdateIsActive", CommandDataType.Bit, CommandDirection.Input, updateIsActive)
                    .Add("@iIsActive", CommandDataType.Bit, CommandDirection.Input, isActive)

                End With
                .ExecuteNonQuery()
            End With

        End Sub

        Public Sub AddOrUpdateBhpbioReportColor(tagId As String, description As String,
          isVisible As Short, color As String, lineStyle As String, markerShape As String) _
          Implements IUtility.AddOrUpdateBhpbioReportColor
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioReportColor"

                With .ParameterCollection
                    .Clear()

                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, 63, tagId)
                    .Add("@iDescription", CommandDataType.VarChar, CommandDirection.Input, 255, description)
                    .Add("@iIsVisible", CommandDataType.Bit, CommandDirection.Input, isVisible)
                    .Add("@iColor", CommandDataType.VarChar, CommandDirection.Input, 255, color)
                    .Add("@iLineStyle", CommandDataType.VarChar, CommandDirection.Input, 50, lineStyle)
                    .Add("@iMarkerShape", CommandDataType.VarChar, CommandDirection.Input, 50, markerShape)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioReportColorList(tagId As String, showVisible As Boolean) _
          As DataTable _
          Implements IUtility.GetBhpbioReportColorList
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportColorList"

                With .ParameterCollection
                    .Clear()
                    .Add("@iTagId", CommandDataType.VarChar, CommandDirection.Input, 63, tagId)
                    .Add("@iShowVisible", CommandDataType.Bit, CommandDirection.Input, showVisible)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function BhpbioGetImportJobLatestActivtyDate(importJobStatusName As String) As DateTime
            Return BhpbioGetImportJobLatestActivtyDate(importJobStatusName, DateTime.Now.AddDays(-7))
        End Function



        Public Function BhpbioGetImportJobLatestActivtyDate(importJobStatusName As String, maximumLookbackDate As DateTime) As DateTime
            With DataAccess
                .CommandText = "dbo.BhpbioGetImportJobLatestActivtyDate"

                With .ParameterCollection
                    .Clear()
                    .Add("@iImportJobStatus", CommandDataType.VarChar, CommandDirection.Input, 63, importJobStatusName)
                    .Add("@iLookBackDate", CommandDataType.DateTime, CommandDirection.Input, maximumLookbackDate)
                End With

                Dim table = .ExecuteDataTable
                Dim field = table.Rows(0)("StatusChangeDate")

                If IsDBNull(field) Then
                    Return maximumLookbackDate
                Else
                    Return Convert.ToDateTime(field)
                End If
            End With
        End Function

        Public Sub AddOrUpdateBhpbioReportThreshold(locationId As Integer, thresholdTypeId As String,
         fieldId As Short, lowThreshold As Double, highThreshold As Double,
         absoluteThreshold As Boolean) _
         Implements IUtility.AddOrUpdateBhpbioReportThreshold
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioReportThreshold"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iThresholdTypeId", CommandDataType.VarChar, CommandDirection.Input, 31, thresholdTypeId)
                    .Add("@iFieldId", CommandDataType.SmallInt, CommandDirection.Input, fieldId)
                    .Add("@iLowThreshold", CommandDataType.Float, CommandDirection.Input, lowThreshold)
                    .Add("@iHighThreshold", CommandDataType.Float, CommandDirection.Input, highThreshold)
                    .Add("@iAbsoluteThreshold", CommandDataType.Bit, CommandDirection.Input, absoluteThreshold)

                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioReportThreshold(locationId As Integer, thresholdTypeId As String,
         fieldId As Short) Implements IUtility.DeleteBhpbioReportThreshold
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioReportThreshold"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iThresholdTypeId", CommandDataType.VarChar, CommandDirection.Input, 31, thresholdTypeId)
                    .Add("@iFieldId", CommandDataType.SmallInt, CommandDirection.Input, fieldId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioReportThresholdList(locationId As Integer, thresholdTypeId As String,
         onlyInherited As Boolean, onlyLocation As Boolean) As DataTable _
         Implements IUtility.GetBhpbioReportThresholdList
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportThresholdList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iThresholdTypeId", CommandDataType.VarChar, CommandDirection.Input, 31, thresholdTypeId)
                    .Add("@iOnlyInherited", CommandDataType.Bit, CommandDirection.Input, onlyInherited)
                    .Add("@iOnlyLocation", CommandDataType.Bit, CommandDirection.Input, onlyLocation)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioReportThresholdTypeList1() As DataTable _
         Implements IUtility.GetBhpbioReportThresholdTypeList
            With DataAccess
                .CommandText = "dbo.GetBhpbioReportThresholdTypeList"

                With .ParameterCollection
                    .Clear()
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioMaterialLookup(materialCategoryId As String, locationTypeId As Int16) As DataTable _
         Implements IUtility.GetBhpbioMaterialLookup
            DataAccess.CommandText = "dbo.GetBhpbioMaterialLookup"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iMaterialCategoryId", CommandDataType.VarChar, CommandDirection.Input, materialCategoryId)
            DataAccess.ParameterCollection.Add("@iLocationTypeId", CommandDataType.TinyInt, CommandDirection.Input, locationTypeId)

            Return DataAccess.ExecuteDataTable()
        End Function

        Public Overridable Function GetBhpMaterialTypeList(isDigblockGroup As Int16,
       isStockpileGroup As Int16,
       locationId As Int32,
       materialCategoryId As String,
       parentMaterialTypeId As Int32) As DataTable Implements IUtility.GetBhpMaterialTypeList

            With DataAccess
                .CommandText = "GetBhpMaterialTypeList"

                With .ParameterCollection
                    .Clear()
                    .Add("@iMaterial_Category_Id", CommandDataType.VarChar, CommandDirection.Input, materialCategoryId)
                    .Add("@iParent_Material_Type_Id", CommandDataType.Int, CommandDirection.Input, parentMaterialTypeId)
                    .Add("@iIs_Digblock_Group", CommandDataType.Bit, CommandDirection.Input, isDigblockGroup)
                    .Add("@iIs_Stockpile_Group", CommandDataType.Bit, CommandDirection.Input, isStockpileGroup)
                    .Add("@iLocation_Id", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Sub GetBhpbioProductionEntity(siteLocationId As Int32, code As String, type As String,
         direction As String, transactionDate As DateTime,
         ByRef returnStockpileId As Int32, ByRef returnCrusherId As String, ByRef returnMillId As String) _
         Implements IUtility.GetBhpbioProductionEntity

            DataAccess.CommandText = "dbo.GetBhpbioProductionEntity"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iSiteLocationId", CommandDataType.Int, CommandDirection.Input, siteLocationId)
            DataAccess.ParameterCollection.Add("@iCode", CommandDataType.VarChar, CommandDirection.Input, 255, code)
            DataAccess.ParameterCollection.Add("@iType", CommandDataType.VarChar, CommandDirection.Input, 255, type)
            DataAccess.ParameterCollection.Add("@iTransactionDate", CommandDataType.DateTime, CommandDirection.Input, transactionDate)
            DataAccess.ParameterCollection.Add("@iDirection", CommandDataType.VarChar, CommandDirection.Input, 255, direction)
            DataAccess.ParameterCollection.Add("@oStockpileId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)
            DataAccess.ParameterCollection.Add("@oCrusherId", CommandDataType.VarChar, CommandDirection.Output, 31, NullValues.String)
            DataAccess.ParameterCollection.Add("@oMillId", CommandDataType.VarChar, CommandDirection.Output, 31, NullValues.String)

            DataAccess.ExecuteNonQuery()

            returnStockpileId = CommonDataHelper.IfDBNull(DataAccess.ParameterCollection("@oStockpileId").Value, NullValues.Int32)
            returnCrusherId = CommonDataHelper.IfDBNull(DataAccess.ParameterCollection("@oCrusherId").Value, NullValues.String)
            returnMillId = CommonDataHelper.IfDBNull(DataAccess.ParameterCollection("@oMillId").Value, NullValues.String)
        End Sub

        Public Sub GetBhpbioProductionWeightometer(sourceStockpileId As Int32, sourceCrusherId As String,
         sourceMillId As String, destinationStockpileId As Int32, destinationCrusherId As String,
         destinationMillId As String, transactionDate As DateTime, sourceType As String,
         destinationType As String, siteLocationId As Int32, ByRef returnWeightometerId As String,
         ByRef returnIsError As Boolean, ByRef returnErrorDescription As String) _
         Implements IUtility.GetBhpbioProductionWeightometer

            DataAccess.CommandText = "dbo.GetBhpbioProductionWeightometer"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iSourceStockpileId", CommandDataType.Int, CommandDirection.Input, sourceStockpileId)
            DataAccess.ParameterCollection.Add("@iSourceCrusherId", CommandDataType.VarChar, CommandDirection.Input, 31, sourceCrusherId)
            DataAccess.ParameterCollection.Add("@iSourceMillId", CommandDataType.VarChar, CommandDirection.Input, 31, sourceMillId)
            DataAccess.ParameterCollection.Add("@iDestinationStockpileId", CommandDataType.Int, CommandDirection.Input, destinationStockpileId)
            DataAccess.ParameterCollection.Add("@iDestinationCrusherId", CommandDataType.VarChar, CommandDirection.Input, 31, destinationCrusherId)
            DataAccess.ParameterCollection.Add("@iDestinationMillId", CommandDataType.VarChar, CommandDirection.Input, 31, destinationMillId)
            DataAccess.ParameterCollection.Add("@iTransactionDate", CommandDataType.DateTime, CommandDirection.Input, transactionDate)
            DataAccess.ParameterCollection.Add("@iSourceType", CommandDataType.VarChar, CommandDirection.Input, 255, sourceType)
            DataAccess.ParameterCollection.Add("@iDestinationType", CommandDataType.VarChar, CommandDirection.Input, 255, destinationType)
            DataAccess.ParameterCollection.Add("@iSiteLocationId", CommandDataType.Int, CommandDirection.Input, siteLocationId)
            DataAccess.ParameterCollection.Add("@oWeightometerId", CommandDataType.VarChar, CommandDirection.Output, 31, NullValues.String)
            DataAccess.ParameterCollection.Add("@oIsError", CommandDataType.Bit, CommandDirection.Output, 0)
            DataAccess.ParameterCollection.Add("@oErrorDescription", CommandDataType.VarChar, CommandDirection.Output, 255, NullValues.String)

            DataAccess.ExecuteNonQuery()

            If DataAccess.ParameterCollection("@oWeightometerId").Value Is DBNull.Value Then
                returnWeightometerId = NullValues.String
            Else
                returnWeightometerId = DirectCast(DataAccess.ParameterCollection("@oWeightometerId").Value, String)
            End If

            returnIsError = DirectCast(DataAccess.ParameterCollection("@oIsError").Value, Boolean)

            If DataAccess.ParameterCollection("@oErrorDescription").Value Is DBNull.Value Then
                returnErrorDescription = NullValues.String
            Else
                returnErrorDescription = DirectCast(DataAccess.ParameterCollection("@oErrorDescription").Value, String)
            End If
        End Sub

        Public Sub AddOrUpdateBhpbioAnalysisVariance(locationId As Integer,
         varianceType As String, percentage As Double, color As String) _
         Implements IUtility.AddOrUpdateBhpbioAnalysisVariance
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioAnalysisVariance"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iVarianceType", CommandDataType.Char, CommandDirection.Input, 1, varianceType)
                    .Add("@iPercentage", CommandDataType.Float, CommandDirection.Input, percentage)
                    .Add("@iColor", CommandDataType.VarChar, CommandDirection.Input, 255, color)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioAnalysisVariance(locationId As Integer,
         varianceType As String) Implements IUtility.DeleteBhpbioAnalysisVariance
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioAnalysisVariance"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iVarianceType", CommandDataType.Char, CommandDirection.Input, 1, varianceType)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioAnalysisVarianceList(locationId As Integer,
          onlyInherited As Boolean, onlyLocation As Boolean) _
         As DataTable _
         Implements IUtility.GetBhpbioAnalysisVarianceList

            Return GetBhpbioAnalysisVarianceList(locationId, DoNotSetValues.Char, onlyInherited, onlyLocation)
        End Function

        Public Function GetBhpbioAnalysisVarianceList(locationId As Integer,
         varianceType As String, onlyInherited As Boolean, onlyLocation As Boolean) _
         As DataTable _
         Implements IUtility.GetBhpbioAnalysisVarianceList
            With DataAccess
                .CommandText = "dbo.GetBhpbioAnalysisVarianceList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iVarianceType", CommandDataType.Char, CommandDirection.Input, 1, varianceType)
                    .Add("@iOnlyInherited", CommandDataType.Bit, CommandDirection.Input, onlyInherited)
                    .Add("@iOnlyLocation", CommandDataType.Bit, CommandDirection.Input, onlyLocation)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function AddBhpbioMetBalancing(siteCode As String, calendarDate As DateTime, startDate As DateTime,
         endDate As DateTime, plantName As String, streamName As String, weightometer As String,
         dryTonnes As Double, wetTonnes As Double, splitCycle As Double, splitPlant As Double,
         productSize As String) As Int32 _
          Implements IUtility.AddBhpbioMetBalancing

            DataAccess.CommandText = "dbo.AddBhpbioMetBalancing"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iSiteCode", CommandDataType.VarChar, CommandDirection.Input, 31, siteCode)
            DataAccess.ParameterCollection.Add("@iCalendarDate", CommandDataType.DateTime, CommandDirection.Input, calendarDate)
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
            DataAccess.ParameterCollection.Add("@iPlantName", CommandDataType.VarChar, CommandDirection.Input, 31, plantName)
            DataAccess.ParameterCollection.Add("@iStreamName", CommandDataType.VarChar, CommandDirection.Input, 31, streamName)
            DataAccess.ParameterCollection.Add("@iWeightometer", CommandDataType.VarChar, CommandDirection.Input, 31, weightometer)
            DataAccess.ParameterCollection.Add("@iDryTonnes", CommandDataType.Float, CommandDirection.Input, dryTonnes)
            DataAccess.ParameterCollection.Add("@iWetTonnes", CommandDataType.Float, CommandDirection.Input, wetTonnes)
            DataAccess.ParameterCollection.Add("@iSplitCycle", CommandDataType.Float, CommandDirection.Input, splitCycle)
            DataAccess.ParameterCollection.Add("@iSplitPlant", CommandDataType.Float, CommandDirection.Input, splitPlant)
            DataAccess.ParameterCollection.Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, 5, productSize)
            DataAccess.ParameterCollection.Add("@oBhpbioMetBalancingId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)

            DataAccess.ExecuteNonQuery()

            Return DirectCast(DataAccess.ParameterCollection("@oBhpbioMetBalancingId").Value, Int32)
        End Function

        Public Sub UpdateBhpbioMetBalancing(bhpbioMetBalancingId As Int32,
         startDate As DateTime, endDate As DateTime,
         weightometer As String, dryTonnes As Double,
         wetTonnes As Double, splitCycle As Double, splitPlant As Double,
         productSize As String) _
         Implements IUtility.UpdateBhpbioMetBalancing

            DataAccess.CommandText = "dbo.UpdateBhpbioMetBalancing"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioMetBalancingId", CommandDataType.Int, CommandDirection.Input, bhpbioMetBalancingId)
            DataAccess.ParameterCollection.Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
            DataAccess.ParameterCollection.Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
            DataAccess.ParameterCollection.Add("@iWeightometer", CommandDataType.VarChar, CommandDirection.Input, 31, weightometer)
            DataAccess.ParameterCollection.Add("@iDryTonnes", CommandDataType.Float, CommandDirection.Input, dryTonnes)
            DataAccess.ParameterCollection.Add("@iWetTonnes", CommandDataType.Float, CommandDirection.Input, wetTonnes)
            DataAccess.ParameterCollection.Add("@iSplitCycle", CommandDataType.Float, CommandDirection.Input, splitCycle)
            DataAccess.ParameterCollection.Add("@iSplitPlant", CommandDataType.Float, CommandDirection.Input, splitPlant)
            DataAccess.ParameterCollection.Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, 5, productSize)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub AddOrUpdateBhpbioMetBalancingGrade(bhpbioMetBalancingId As Int32, gradeId As Short, gradeValue As Double) _
            Implements IUtility.AddOrUpdateBhpbioMetBalancingGrade

            DataAccess.CommandText = "dbo.AddOrUpdateBhpbioMetBalancingGrade"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioMetBalancingId", CommandDataType.Int, CommandDirection.Input, bhpbioMetBalancingId)
            DataAccess.ParameterCollection.Add("@iGradeId", CommandDataType.SmallInt, CommandDirection.Input, gradeId)
            DataAccess.ParameterCollection.Add("@iGradeValue", CommandDataType.Float, CommandDirection.Input, gradeValue)

            DataAccess.ExecuteNonQuery()

        End Sub

        Public Sub DeleteBhpbioMetBalancing(bhpbioMetBalancingId As Int32) _
         Implements IUtility.DeleteBhpbioMetBalancing

            DataAccess.CommandText = "dbo.DeleteBhpbioMetBalancing"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioMetBalancingId", CommandDataType.Int, CommandDirection.Input, bhpbioMetBalancingId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub BhpbioDataExceptionStockpileGroupLocationMissing() Implements IUtility.BhpbioDataExceptionStockpileGroupLocationMissing

            DataAccess.CommandText = "dbo.BhpbioDataExceptionStockpileGroupLocationMissing"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub DeleteBhpbioMaterialTypeLocationAll(materialTypeId As Int32) _
            Implements IUtility.DeleteBhpbioMaterialTypeLocationAll

            DataAccess.CommandText = "dbo.DeleteBhpbioMaterialTypeLocationAll"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iMaterialTypeId", CommandDataType.Int, CommandDirection.Input, materialTypeId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub AddBhpbioMaterialTypeLocation(materialTypeId As Int32, locationId As Int32) _
            Implements IUtility.AddBhpbioMaterialTypeLocation

            DataAccess.CommandText = "dbo.AddBhpbioMaterialTypeLocation"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iMaterialTypeId", CommandDataType.Int, CommandDirection.Input, materialTypeId)
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Function GetBhpbioMaterialTypeLocationList(materialTypeId As Int32) As DataTable _
            Implements IUtility.GetBhpbioMaterialTypeLocationList
            With DataAccess
                .CommandText = "dbo.GetBhpbioMaterialTypeLocationList"
                .CommandType = CommandObjectType.StoredProcedure

                With .ParameterCollection
                    .Clear()
                    .Add("@iMaterialTypeId", CommandDataType.Int, CommandDirection.Input, materialTypeId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioDataExceptionList(dataExceptionTypeId As Int32,
            dataExceptionStatusId As String, locationId As Int32) As DataTable _
            Implements IUtility.GetBhpbioDataExceptionList

            With DataAccess
                .CommandText = "dbo.GetBhpbioDataExceptionList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iDataExceptionTypeId", CommandDataType.Int, CommandDirection.Input, dataExceptionTypeId)
                    .Add("@iDataExceptionStatusId", CommandDataType.VarChar, CommandDirection.Input, 5, dataExceptionStatusId)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                Return .ExecuteDataTable
            End With

        End Function

        ' NOTE: If the arguments for this method chanage, be sure to update the UpdateBhpbioDataExceptionDismissAll method below - it is
        ' important that the filters match, in order for the dismissal to get the correct records
        Public Overridable Function GetBhpbioDataExceptionFilteredList(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                        dateFrom As Nullable(Of DateTime), dateTo As Nullable(Of DateTime),
                                        dataExceptionTypeId As Nullable(Of Integer), descriptionContains As String,
                                        maxDataExceptions As Integer, locationId As Nullable(Of Integer)) As DataTable _
         Implements IUtility.GetBhpbioDataExceptionFilteredList
            With DataAccess
                .CommandText = "GetBhpbioDataExceptionFilteredList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iIncludeActive", CommandDataType.Bit, CommandDirection.Input, IIf(includeActive, 1, 0))
                    .Add("@iIncludeDismissed", CommandDataType.Bit, CommandDirection.Input, IIf(includeDismissed, 1, 0))
                    .Add("@iIncludeResolved", CommandDataType.Bit, CommandDirection.Input, IIf(includeResolved, 1, 0))
                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, IIf(dateFrom Is Nothing, NullValues.DateTime, dateFrom.Value))
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, IIf(dateTo Is Nothing, NullValues.DateTime, dateTo.Value))
                    .Add("@iDataExceptionTypeId", CommandDataType.Int, CommandDirection.Input, IIf(dataExceptionTypeId Is Nothing, NullValues.Int32, dataExceptionTypeId.Value))
                    .Add("@iDescriptionContains", CommandDataType.VarChar, CommandDirection.Input, 250, IIf(descriptionContains Is Nothing, NullValues.String, descriptionContains))
                    .Add("@iMaxRows", CommandDataType.Int, CommandDirection.Input, maxDataExceptions)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, IIf(locationId Is Nothing, NullValues.Int32, locationId))

                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Overridable Function UpdateBhpbioDataExceptionDismissAll(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                dateFrom As Nullable(Of DateTime), dateTo As Nullable(Of DateTime),
                                dataExceptionTypeId As Nullable(Of Integer), descriptionContains As String,
                                maxDataExceptions As Integer, locationId As Nullable(Of Integer)) As DataTable _
                Implements IUtility.UpdateBhpbioDataExceptionDismissAll
            With DataAccess
                .CommandText = "UpdateBhpbioDataExceptionDismissAll"

                With .ParameterCollection
                    .Clear()

                    .Add("@iIncludeActive", CommandDataType.Bit, CommandDirection.Input, IIf(includeActive, 1, 0))
                    .Add("@iIncludeDismissed", CommandDataType.Bit, CommandDirection.Input, IIf(includeDismissed, 1, 0))
                    .Add("@iIncludeResolved", CommandDataType.Bit, CommandDirection.Input, IIf(includeResolved, 1, 0))
                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, IIf(dateFrom Is Nothing, NullValues.DateTime, dateFrom.Value))
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, IIf(dateTo Is Nothing, NullValues.DateTime, dateTo.Value))
                    .Add("@iDataExceptionTypeId", CommandDataType.Int, CommandDirection.Input, IIf(dataExceptionTypeId Is Nothing, NullValues.Int32, dataExceptionTypeId.Value))
                    .Add("@iDescriptionContains", CommandDataType.VarChar, CommandDirection.Input, 250, IIf(descriptionContains Is Nothing, NullValues.String, descriptionContains))
                    .Add("@iMaxRows", CommandDataType.Int, CommandDirection.Input, maxDataExceptions)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, IIf(locationId Is Nothing, NullValues.Int32, locationId))

                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Overridable Function GetBhpbioDataExceptionTypeFilteredList(includeActive As Boolean, includeDismissed As Boolean, includeResolved As Boolean,
                                        dateFrom As Nullable(Of DateTime), dateTo As Nullable(Of DateTime),
                                        dataExceptionTypeId As Nullable(Of Integer), descriptionContains As String, locationId As Nullable(Of Integer)) As DataTable _
            Implements IUtility.GetBhpbioDataExceptionTypeFilteredList
            With DataAccess
                .CommandText = "GetBhpbioDataExceptionTypeFilteredList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iIncludeActive", CommandDataType.Bit, CommandDirection.Input, IIf(includeActive, 1, 0))
                    .Add("@iIncludeDismissed", CommandDataType.Bit, CommandDirection.Input, IIf(includeDismissed, 1, 0))
                    .Add("@iIncludeResolved", CommandDataType.Bit, CommandDirection.Input, IIf(includeResolved, 1, 0))
                    .Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, IIf(dateFrom Is Nothing Or dateFrom.Equals(Date.MinValue), SqlDateTime.MinValue.Value, dateFrom.Value))
                    .Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, IIf(dateTo Is Nothing Or dateTo.Equals(Date.MinValue), SqlDateTime.MinValue.Value, dateTo.Value))
                    .Add("@iDataExceptionTypeId", CommandDataType.Int, CommandDirection.Input, IIf(dataExceptionTypeId Is Nothing, NullValues.Int32, dataExceptionTypeId.Value))
                    .Add("@iDescriptionContains", CommandDataType.VarChar, CommandDirection.Input, 250, IIf(descriptionContains Is Nothing, NullValues.String, descriptionContains))
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, IIf(locationId Is Nothing, NullValues.Int32, locationId))

                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioDataExceptionCount(locationId As Int32) As Int32 _
            Implements IUtility.GetBhpbioDataExceptionCount
            With DataAccess
                .CommandText = "GetBhpbioDataExceptionCount"

                With .ParameterCollection
                    .Clear()
                    .Add("@oNum_Exceptions", CommandDataType.Int, CommandDirection.Output, -1)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@oNum_Exceptions").Value)
            End With
        End Function

        Public Function GetBhpbioDataExceptionCount(locationId As Int32, month As DateTime) As Int32 _
            Implements IUtility.GetBhpbioDataExceptionCount
            With DataAccess
                .CommandText = "GetBhpbioDataExceptionCount2"

                With .ParameterCollection
                    .Clear()
                    .Add("@oNum_Exceptions", CommandDataType.Int, CommandDirection.Output, -1)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@oNum_Exceptions").Value)
            End With
        End Function

        Public Function GetBhpbioLocationRoot() As Integer _
         Implements IUtility.GetBhpbioLocationRoot
            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationRoot"

                With .ParameterCollection
                    .Clear()
                    .Add("@oLocationId", CommandDataType.Int, CommandDirection.Output)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@oLocationId").Value)
            End With
        End Function

        Public Function GetBhpbioLocationListWithOverrideAndDates(locationId As Integer, lowestLocationTypeDescription As String,
                                                                  startDate As DateTime, endDate As DateTime) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationListWithOverrideAndDates"

                With .ParameterCollection
                    .Clear()
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@ilowestLocationTypeDescription", CommandDataType.VarChar, CommandDirection.Input, lowestLocationTypeDescription)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Sub CalcVirtualFlow() _
         Implements IUtility.CalcVirtualFlow
            With DataAccess
                .CommandText = "dbo.CalcVirtualFlow"
                .ParameterCollection.Clear()
                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub AddOrUpdateBhpbioStockpileLocationConfiguration(locationId As Int32,
                imageData As Byte(), promoteStockpiles As Boolean, updateImageData As Boolean, updatePromoteStockpiles As Boolean) Implements IUtility.AddOrUpdateBhpbioStockpileLocationConfiguration
            Dim command As New SqlCommand
            With command
                ' ReSharper disable once VBWarnings::BC40000
                .Connection = DataAccess.Connection
                .Transaction = DataAccess.Transaction
                .CommandText = "dbo.AddOrUpdateBhpbioStockpileLocationConfiguration"
                .CommandType = CommandType.StoredProcedure
                .Parameters.Add("@iLocationId", SqlDbType.Int).Value = locationId
                .Parameters.Add("@iImageData", SqlDbType.VarBinary).Value = imageData
                .Parameters.Add("@iUpdateImageData", SqlDbType.Bit).Value = updateImageData
                .Parameters.Add("@iPromoteStockpiles", SqlDbType.Bit).Value = promoteStockpiles
                .Parameters.Add("@iUpdatePromoteStockpiles", SqlDbType.Bit).Value = updatePromoteStockpiles
                .ExecuteNonQuery()
            End With
        End Sub


        Public Function GetBhpbioStockpileLocationConfiguration(locationId As Int32) As DataTable Implements IUtility.GetBhpbioStockpileLocationConfiguration

            With DataAccess
                .CommandText = "dbo.GetBhpbioStockpileLocationConfiguration"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationId", CommandDataType.Int, locationId)
                Return .ExecuteDataTable()
            End With
        End Function

        Public Overrides Sub TryDeleteLocation(locationId As Int32,
name As String, locationTypeId As Int16,
parentLocationName As String,
ByRef isError As Boolean, ByRef errorMessage As String)

            DataAccess.CommandText = "dbo.BhpbioTryDeleteLocation"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
            DataAccess.ParameterCollection.Add("@iName", CommandDataType.VarChar, CommandDirection.Input, 31, name)
            DataAccess.ParameterCollection.Add("@iLocationTypeId", CommandDataType.TinyInt, CommandDirection.Input, 31, locationTypeId)
            DataAccess.ParameterCollection.Add("@iParentLocationName", CommandDataType.VarChar, CommandDirection.Input, 31, parentLocationName)
            DataAccess.ParameterCollection.Add("@oIsError", CommandDataType.Bit, CommandDirection.Output, 0)
            DataAccess.ParameterCollection.Add("@oErrorMessage", CommandDataType.VarChar, CommandDirection.Output, -1, "")

            DataAccess.ExecuteNonQuery()

            isError = DirectCast(DataAccess.ParameterCollection("@oIsError").Value, Boolean)
            If DataAccess.ParameterCollection("@oErrorMessage").Value Is DBNull.Value Then
                errorMessage = NullValues.String
            Else
                errorMessage = DirectCast(DataAccess.ParameterCollection("@oErrorMessage").Value, String)
            End If
        End Sub

        Public Function GetBhpbioLocationListWithOverride(locationId As Int32, getChildLocations As Int16, locationDate As Date) As DataTable Implements IUtility.GetBhpbioLocationListWithOverride
            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationListWithOverride"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iGetChildLocations", CommandDataType.Bit, CommandDirection.Input, getChildLocations)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, locationDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, locationDate.AddMonths(1).AddDays(-1))
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioPitListWithBlockCounts(locationId As Int32, monthDate As Date) As DataTable
            Return GetBhpbioPitListWithBlockCounts(locationId, monthDate, monthDate.AddMonths(1).AddDays(-1))
        End Function

        Public Function GetBhpbioPitListWithBlockCounts(locationId As Int32, startDate As Date, endDate As Date) As DataTable
            With DataAccess
                .CommandText = "dbo.GetBhpbioPitListWithBlockCounts"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, endDate)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioLocationParentHeirarchyWithOverride(locationId As Int32, locationDate As Date) As DataTable Implements IUtility.GetBhpbioLocationParentHeirarchyWithOverride
            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationParentHeirarchyWithOverride"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, locationDate)
                    .Add("@iEndDate", CommandDataType.DateTime, CommandDirection.Input, locationDate.AddMonths(1).AddDays(-1))
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioLocationNameWithOverride(locationId As Int32,
 startDate As Date,
 endDate As Date) As DataTable Implements IUtility.GetBhpbioLocationNameWithOverride

            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationNameWithOverride"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iDateStart", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iDateEnd", CommandDataType.DateTime, CommandDirection.Input, endDate)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioLocationChildrenNameWithOverride(locationId As Int32,
startDate As Date,
endDate As Date) As DataTable Implements IUtility.GetBhpbioLocationChildrenNameWithOverride

            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationChildrenNameWithOverride"

                With .ParameterCollection
                    .Clear()

                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iDateStart", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iDateEnd", CommandDataType.DateTime, CommandDirection.Input, endDate)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioImportLocationCodeList(importParameterId As Integer?, locationId As Integer?) As DataTable Implements IUtility.GetBhpbioImportLocationCodeList
            With DataAccess
                .CommandText = "dbo.GetBhpbioImportLocationCodeList"

                With .ParameterCollection
                    .Clear()

                    If importParameterId.HasValue Then
                        .Add("@iImportParameterId", CommandDataType.Int, CommandDirection.Input, importParameterId.Value)
                    End If

                    If locationId.HasValue Then
                        .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId.Value)
                    End If
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Sub UpdateBhpbioLocationDate() _
         Implements IUtility.UpdateBhpbioLocationDate

            With DataAccess
                .CommandText = "dbo.UpdateBhpbioLocationDate"
                .ParameterCollection.Clear()
                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub UpdateBhpbioStockpileLocationDate() _
          Implements IUtility.UpdateBhpbioStockpileLocationDate

            With DataAccess
                .CommandText = "dbo.UpdateBhpbioStockpileLocationDate"
                .ParameterCollection.Clear()
                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub CorrectBhpbioProductionWeightometerAndDestinationAssignments() _
              Implements IUtility.CorrectBhpbioProductionWeightometerAndDestinationAssignments

            With DataAccess
                .CommandText = "dbo.CorrectBhpbioProductionWeightometerAndDestinationAssignments"
                .ParameterCollection.Clear()
                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioDefaultLumpFinesList(locationId As Int32?,
            locationTypeId As Int32?) As DataTable _
            Implements IUtility.GetBhpbioDefaultLumpFinesList

            With DataAccess
                .CommandText = "dbo.GetBhpbioDefaultLumpFinesList"

                With .ParameterCollection
                    .Clear()
                    If locationId.HasValue Then
                        .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId.Value)
                    End If
                    If locationTypeId.HasValue Then
                        .Add("@iLocationTypeId", CommandDataType.Int, CommandDirection.Input, locationTypeId.Value)
                    End If
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function CheckUpdateSiteMapList() As DataTable _
            Implements IUtility.CheckUpdateSiteMapList

            With DataAccess
                .CommandText = "dbo.GetBhpbioSiteMaps"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioDefaultLumpFinesRecord(bhpbioDefaultLumpFinesId As Int32) As DataTable _
            Implements IUtility.GetBhpbioDefaultLumpFinesRecord
            With DataAccess
                .CommandText = "dbo.GetBhpbioDefaultLumpFinesRecord"

                With .ParameterCollection
                    .Clear()
                    .Add("@iBhpbioDefaultLumpFinesId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultLumpFinesId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Function AddOrUpdateBhpbioLumpFinesRecord(bhpbioDefaultLumpFinesId As Integer?, locationId As Integer,
            startDate As Date, lumpPercent As Decimal, validateOnly As Boolean) As DataTable _
              Implements IUtility.AddOrUpdateBhpbioLumpFinesRecord

            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioLumpFinesRecord"
                With .ParameterCollection
                    .Clear()
                    If Not bhpbioDefaultLumpFinesId Is Nothing Then
                        .Add("@iBhpbioDefaultLumpFinesId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultLumpFinesId)
                    End If
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@iStartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iLumpPercent", CommandDataType.Decimal, CommandDirection.Input, lumpPercent)
                    .Add("@iValidateOnly", CommandDataType.Bit, CommandDirection.Input, validateOnly)
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub DeleteBhpbioLumpFinesRecord(bhpbioDefaultLumpFinesId As Integer) _
              Implements IUtility.DeleteBhpbioLumpFinesRecord

            With DataAccess
                .CommandText = "dbo.DeleteBhpbioLumpFinesRecord"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iBhpbioDefaultLumpFinesId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultLumpFinesId)
                .ExecuteNonQuery()
            End With
        End Sub

        Public Sub DeleteBhpbioProductTypeRecord(bhpbioDefaultProductTypeId As Integer) _
              Implements IUtility.DeleteBhpbioProductTypeRecord

            With DataAccess
                .CommandText = "dbo.DeleteBhpbioProductTypeLocation"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultProductTypeId)
                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetGradeObjectsList(gradeVisibility As Short, numericFormat As String) As Dictionary(Of String, Grade) _
            Implements IUtility.GetGradeObjectsList

            Dim gradeRow As DataRow
            Dim gradeData As DataTable

            gradeData = GetGradeList(NullValues.Int16)

            Dim gradeDictionary As New Dictionary(Of String, Grade)

            For Each gradeRow In gradeData.Rows
                gradeDictionary.Add(gradeRow("Grade_Name").ToString, New Grade(gradeRow, numericFormat))
            Next

            Return gradeDictionary

        End Function

        Public Function GetReportCacheTimeoutPeriod() As Integer
            Dim defaultCacheMinutes = 30
            Dim cache = defaultCacheMinutes

            Try

                If Not Integer.TryParse(GetSystemSetting("BHPBIO_REPORT_CACHE_TIMEOUT_PERIOD"), cache) Then
                    cache = defaultCacheMinutes
                End If

            Catch ex As Exception
                Return defaultCacheMinutes
            End Try

            Return cache
        End Function

        Public Sub UpdateBhpbioMissingSampleDataException(dateFrom As Date, dateTo As Date) _
            Implements IUtility.UpdateBhpbioMissingSampleDataException

            With DataAccess
                .CommandText = "dbo.UpdateBhpbioMissingSampleDataException"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iDateFrom", CommandDataType.DateTime, CommandDirection.Input, dateFrom)
                .ParameterCollection.Add("@iDateTo", CommandDataType.DateTime, CommandDirection.Input, dateTo)
                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Log the receipt of a message
        ''' </summary>
        ''' <param name="receivedDateTime">date and time of receipt</param>
        ''' <param name="messageTimestamp">timestamp from the message</param>
        ''' <param name="messageBody">the content of the message</param>
        ''' <param name="messageType">the type of message</param>
        ''' <param name="dataKey">a key portion of data from the message</param>
        ''' <remarks>Typically used to log integration messages</remarks>
        Public Sub LogMessage(receivedDateTime As Date, messageTimestamp As Nullable(Of Date), messageBody As String, messageType As String, dataKey As String) _
            Implements IUtility.LogMessage

            ' the code sql library does not handle ntext parameters .. so use ADO.Net directly

            Dim sqlConnection = DirectCast(DataAccess.DataAccessConnection.Connection, SqlConnection)

            Dim responsibleForConnection = False

            If Not sqlConnection.State = ConnectionState.Open Then
                ' if the connection is not yet open, open it now
                sqlConnection.Open()
                responsibleForConnection = True
            End If

            Try
                Dim sqlCommand = sqlConnection.CreateCommand()
                sqlCommand.CommandType = CommandType.StoredProcedure
                sqlCommand.CommandText = "Staging.LogMessage"
                sqlCommand.Parameters.AddWithValue("@iReceivedDateTime", receivedDateTime)
                If messageTimestamp.HasValue Then
                    sqlCommand.Parameters.AddWithValue("@iMessageTimestamp", messageTimestamp.Value)
                End If
                sqlCommand.Parameters.AddWithValue("@iMessageBody", messageBody)
                sqlCommand.Parameters.AddWithValue("@iMessageType", messageType)
                sqlCommand.Parameters.AddWithValue("@iDataKey", dataKey)
                sqlCommand.ExecuteNonQuery()

            Finally
                ' close the connection if this method opened it
                If responsibleForConnection AndAlso sqlConnection.State = ConnectionState.Open Then
                    sqlConnection.Close()
                End If
            End Try


        End Sub
        Public Function GetBhpbioProductTypeList() As DataTable _
          Implements IUtility.GetBhpbioProductTypeList

            With DataAccess
                .CommandText = "dbo.GetBhpbioProductTypeLocations"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioDepositList(bhpbioLocationId As Integer) As DataTable _
          Implements IUtility.GetBhpbioDepositList
            With DataAccess
                .CommandText = "dbo.GetBhpbioDeposits"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, bhpbioLocationId)
                Return PitTable(.ExecuteDataSet())
            End With
        End Function

        Public Function GetDepositPits(locationGroupId As Integer?, parentSiteId As Integer?) As DataSet _
          Implements IUtility.GetDepositPits
            With DataAccess
                .CommandText = "dbo.GetBhpbioDepositPits"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationGroupId", CommandDataType.Int, CommandDirection.Input, locationGroupId)
                .ParameterCollection.Add("@parentSiteId", CommandDataType.Int, CommandDirection.Input, parentSiteId)
                Return .ExecuteDataSet()
            End With
        End Function

        Sub AddOrUpdateBhpbioLocationGroup(bhpbioDefaultDepositId As Integer?, siteId As Integer, name As String, pitList As String) _
            Implements IUtility.AddOrUpdateBhpbioLocationGroup
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioLocationGroup"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationGroupId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultDepositId)
                .ParameterCollection.Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, siteId)
                .ParameterCollection.Add("@iName", CommandDataType.VarChar, CommandDirection.Input, name)
                .ParameterCollection.Add("@iLocationIds", CommandDataType.VarChar, CommandDirection.Input, pitList)
                .ParameterCollection.Add("@iLocationGroupTypeName", CommandDataType.VarChar, CommandDirection.Input, "DEPOSIT")
                .ExecuteNonQuery()
            End With
        End Sub

        Sub DeleteDeposit(locationGroupId As Integer) _
            Implements IUtility.DeleteDeposit
            With DataAccess
                .CommandText = "dbo.BhpbioDeleteLocationGroup"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iLocationGroupId", CommandDataType.Int, CommandDirection.Input, locationGroupId)
                .ExecuteNonQuery()
            End With
        End Sub

        Private Function PitTable(ByRef dataSet As DataSet) As DataTable
            'Workload of this func should ideally take place in SP, but too much effort
            Dim dt As DataTable
            dt = New DataTable()
            dt.Columns.Add("Name")
            dt.Columns.Add("Pits")
            dt.Columns.Add("LocationGroupId")


            Dim row As DataRow
            For Each row In dataSet.Tables(2).Rows
                Dim dr As DataRow
                dr = dt.NewRow
                'Sum all that names of pits which are related to this locationgroupid
                Dim locationGroupId As Integer
                locationGroupId = CType(row("LocationGroupId"), Integer)

                dr.ItemArray = {row("Name"), PitList(locationGroupId, dataSet.Tables(1), dataSet.Tables(0)), locationGroupId}
                dt.Rows.Add(dr)
            Next
            Return dt
        End Function

        Private Function PitList(locationGroupId As Integer, ByRef locationGroupLocations As DataTable, ByRef locations As DataTable) As String
            'Workload of this func should ideally take place in SP, but too much effort
            Dim locationGroupLocation = locationGroupLocations.Select().Where(Function(c) CType(c.Item("LocationGroupId"), Integer).Equals(locationGroupId))
            Dim pits = From gl In locationGroupLocation Join l In locations.Select()
                          On gl.Item("LocationId") Equals l.Item("Location_Id")
                       Select CType(l.Item("Name"), String)

            Return String.Join(",", pits.ToArray())
        End Function
        Public Function GetBhpbioProductTypesWithLocationIds() As DataTable Implements IUtility.GetBhpbioProductTypesWithLocationIds

            With DataAccess
                .CommandText = "dbo.GetBhpbioProductTypesWithLocationIds"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioLocationGroupsWithLocationIds() As DataTable

            With DataAccess
                .CommandText = "dbo.GetBhpbioLocationGroupsWithLocationIds"
                .ParameterCollection.Clear()
                Return .ExecuteDataTable
            End With
        End Function

        Public Function GetBhpbioProductTypeLocation(bhpbioDefaultProductTypeId As Integer) As DataTable _
            Implements IUtility.GetBhpbioProductTypeLocation

            With DataAccess
                .CommandText = "dbo.GetBhpbioProductTypeLocations"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultProductTypeId)
                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub AddOrUpdateProductTypeRecord(bhpbioDefaultProductTypeId As Integer?,
           code As String, description As String, productSize As String,
           hubs As ArrayList) _
            Implements IUtility.AddOrUpdateProductTypeRecord

            With DataAccess
                .CommandText = "dbo.SaveBhpbioProductTypeLocations"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultProductTypeId)
                .ParameterCollection.Add("@iCode", CommandDataType.VarChar, CommandDirection.Input, code)
                .ParameterCollection.Add("@iDescription", CommandDataType.VarChar, CommandDirection.Input, description)
                .ParameterCollection.Add("@iProductSize", CommandDataType.VarChar, CommandDirection.Input, productSize)
                '.ParameterCollection.Add("@iLocationId", CommandDataType.VarChar, CommandDirection.Input, Hubs)
                .ParameterCollection.Add("@oProductTypeId", CommandDataType.Int, CommandDirection.Output, 0)
                .ExecuteNonQuery()

                BhpbioDefaultProductTypeId = CommonDataHelper.IfDBNull(DataAccess.ParameterCollection("@oProductTypeId").Value, NullValues.Int32)

                For Each s As String In Hubs
                    .CommandText = "dbo.AddBhpbioProductTypeLocation"
                    .ParameterCollection.Clear()
                    .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, bhpbioDefaultProductTypeId)
                    .ParameterCollection.Add("@iLocationId", CommandDataType.VarChar, CommandDirection.Input, s)
                    .ExecuteNonQuery()
                Next


            End With
        End Sub

        Public Function GetBhpbioAttributeProperties() As DataTable _
            Implements IUtility.GetBhpbioAttributeProperties
            DataAccess.CommandText = "dbo.GetBhpbioReportAttributeProperties"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()

            Return DataAccess.ExecuteDataTable
        End Function

        Public Sub UpdateBhpbioImportSyncRowFilterData(importJobId As Integer) Implements IUtility.UpdateBhpbioImportSyncRowFilterData
            With DataAccess
                .CommandText = "dbo.BhpbioUpdateImportSyncRowFilterData"
                .CommandType = CommandObjectType.StoredProcedure
                With .ParameterCollection
                    .Clear()
                    .Add("@iImportJobId", CommandDataType.BigInt, CommandDirection.Input, importJobId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

#Region "Sample Stations"
        Public Function GetBhpbioSampleStationList(locationId As Integer, productSize As String) As DataTable Implements IUtility.GetBhpbioSampleStationList
            With DataAccess
                .CommandText = "dbo.GetBhpbioSampleStationList"
                .CommandType = CommandObjectType.StoredProcedure
                With .ParameterCollection
                    .Clear()
                    .Add("@LocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@ProductSize", CommandDataType.VarChar, CommandDirection.Input, productSize)
                End With

                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub DeleteBhpbioSampleStation(sampleStationId As Integer) Implements IUtility.DeleteBhpbioSampleStation
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioSampleStation"
                With .ParameterCollection
                    .Clear()
                    .Add("@Id", CommandDataType.Int, CommandDirection.Input, sampleStationId)
                End With

                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetWeightometerListWithLocations() As DataTable Implements IUtility.GetWeightometerListWithLocations
            With DataAccess
                .CommandText = "dbo.GetWeightometerListWithLocations"
                .ParameterCollection.Clear()

                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub AddOrUpdateBhpbioSampleStation(sampleStationId As Integer?, name As String, description As String, locationId As Integer, weightometerId As String, productSize As String) Implements IUtility.AddOrUpdateBhpbioSampleStation
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioSampleStation"
                With .ParameterCollection
                    .Clear()
                    .Add("@Id", CommandDataType.Int, CommandDirection.Input, sampleStationId)
                    .Add("@Location_Id", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@Weightometer_Id", CommandDataType.VarChar, CommandDirection.Input, weightometerId)
                    .Add("@Name", CommandDataType.VarChar, CommandDirection.Input, name)
                    .Add("@Description", CommandDataType.VarChar, CommandDirection.Input, description)
                    .Add("@ProductSize", CommandDataType.VarChar, CommandDirection.Input, productSize)
                End With
                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioSampleStation(sampleStationId As Integer) As DataTable Implements IUtility.GetBhpbioSampleStation
            With DataAccess
                .CommandText = "dbo.GetBhpbioSampleStation"
                With .ParameterCollection
                    .Clear()
                    .Add("@Id", CommandDataType.Int, CommandDirection.Input, sampleStationId)
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        Public Function GetBhpbioSampleStationTargetsForSampleStation(sampleStationId As Integer) As DataTable Implements IUtility.GetBhpbioSampleStationTargetsForSampleStation
            With DataAccess
                .CommandText = "dbo.GetBhpbioSampleStationTargetsForSampleStation"
                With .ParameterCollection
                    .Clear()
                    .Add("@SampleStationId", CommandDataType.Int, CommandDirection.Input, sampleStationId)
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub AddOrUpdateBhpbioSampleStationTarget(targetId As Integer?, sampleStationId As Integer, startDate As Date, coverageTarget As Decimal, coverageWarning As Decimal, ratioTarget As Integer, ratioWarning As Integer) Implements IUtility.AddOrUpdateBhpbioSampleStationTarget
            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioSampleStationTarget"
                With .ParameterCollection
                    .Clear()
                    .Add("@Id", CommandDataType.Int, CommandDirection.Input, targetId)
                    .Add("@SampleStation_Id", CommandDataType.Int, CommandDirection.Input, sampleStationId)
                    .Add("@StartDate", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@CoverageTarget", CommandDataType.Decimal, CommandDirection.Input, coverageTarget)
                    .Add("@CoverageWarning", CommandDataType.Decimal, CommandDirection.Input, coverageWarning)
                    .Add("@RatioTarget", CommandDataType.Int, CommandDirection.Input, ratioTarget)
                    .Add("@RatioWarning", CommandDataType.Int, CommandDirection.Input, ratioWarning)
                End With
                .ExecuteNonQuery()
            End With
        End Sub

        Public Function GetBhpbioSampleStationTarget(sampleStationTargetId As Integer) As DataTable Implements IUtility.GetBhpbioSampleStationTarget
            With DataAccess
                .CommandText = "dbo.GetBhpbioSampleStationTarget"
                With .ParameterCollection
                    .Clear()
                    .Add("@TargetId", CommandDataType.Int, CommandDirection.Input, sampleStationTargetId)
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        Public Sub DeleteBhpbioSampleStationTarget(targetId As Integer) Implements IUtility.DeleteBhpbioSampleStationTarget
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioSampleStationTarget"
                With .ParameterCollection
                    .Clear()
                    .Add("@Id", CommandDataType.Int, CommandDirection.Input, targetId)
                End With
                .ExecuteNonQuery()
            End With
        End Sub
#End Region

        Public Function GetBhpbioStratigraphyHierarchyList() As DataTable Implements IUtility.GetBhpbioStratigraphyHierarchyList
            'Public Function GetBhpbioSampleStationList(locationId As Integer, productSize As String) As DataTable Implements IUtility.GetBhpbioSampleStationList
            With DataAccess
                .CommandText = "dbo.GetBhpbioStratigraphyHierarchyList"
                .CommandType = CommandObjectType.StoredProcedure
                With .ParameterCollection
                    .Clear()
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        Public Function GetWeatheringList() As DataTable Implements IUtility.GetWeatheringList
            With DataAccess
                .CommandText = "dbo.GetBhpbioWeatheringList"
                With .ParameterCollection
                    .Clear()
                End With
                Return .ExecuteDataTable()
            End With
        End Function


        Public Function GetBhpbioStratigraphyHierarchyTypeList() As DataTable Implements IUtility.GetBhpbioStratigraphyHierarchyTypeList

            With DataAccess
                .CommandText = "dbo.GetBhpbioStratigraphyHierarchyTypeList"
                .CommandType = CommandObjectType.StoredProcedure
                With .ParameterCollection
                    .Clear()
                End With

                Return .ExecuteDataTable()
            End With
        End Function
    End Class
End Namespace