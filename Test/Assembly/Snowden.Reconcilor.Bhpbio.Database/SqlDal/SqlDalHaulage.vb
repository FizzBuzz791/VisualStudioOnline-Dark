Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects

Namespace SqlDal
    Public Class SqlDalHaulage
        Inherits Reconcilor.Core.Database.SqlDal.SqlDalHaulage
        Implements Reconcilor.Bhpbio.Database.DalBaseObjects.IHaulage

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

        Sub AddOrUpdateBhpbioHaulageLumpFinesGrade( _
            ByVal haulageRawId As Int32, _
            ByVal gradeId As Int16?, _
            ByVal lumpValue As Single?, _
            ByVal finesValue As Single?) _
         Implements DalBaseObjects.IHaulage.AddOrUpdateBhpbioHaulageLumpFinesGrade

            DataAccess.CommandText = "dbo.AddOrUpdateBhpbioHaulageLumpFinesGrade"
            DataAccess.CommandType = CommandObjectType.StoredProcedure

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iHaulageRawId", CommandDataType.Int, CommandDirection.Input, 14, haulageRawId)
            If gradeId.HasValue Then
                DataAccess.ParameterCollection.Add("@iGradeId", CommandDataType.Int, CommandDirection.Input, gradeId.Value)
            End If
            If lumpValue.HasValue Then
                DataAccess.ParameterCollection.Add("@iLumpValue", CommandDataType.Real, CommandDirection.Input, lumpValue.Value)
            End If
            If finesValue.HasValue Then
                DataAccess.ParameterCollection.Add("@iFinesValue", CommandDataType.Real, CommandDirection.Input, finesValue.Value)
            End If

            DataAccess.ExecuteNonQuery()

        End Sub

        Public Overrides Function GetHaulageManagementList(ByVal filterStartDate As Date, _
                 ByVal filterEndDate As Date, _
                 ByVal filterStartShift As String, _
                 ByVal filterEndShift As String, _
                 ByVal filterSource As String, _
                 ByVal filterDestination As String, _
                 ByVal filterTruck As String, _
                 ByVal showHaulageWithApprovedChild As Int16, _
                 ByVal top As Int16, _
                 ByRef countDestinationCrusher As Int32, _
                 ByRef countDestinationMill As Int32, _
                 ByRef countDestinationStockpile As Int32, _
                 ByRef countRecords As Int32, _
                 ByRef countSourceDigblock As Int32, _
                 ByRef countSourceMill As Int32, _
                 ByRef countSourceStockpile As Int32, _
                 ByRef sumTonnes As Double, _
                 ByRef recordLimit As Int32, _
                 ByRef LocationId As Int32, _
                 ByVal notesField As String) As DataTable

            Dim returnTable As DataTable
            With DataAccess
                .CommandText = "GetBhpbioHaulageManagementList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFilter_Source", CommandDataType.VarChar, CommandDirection.Input, 63, filterSource)
                    .Add("@iFilter_Destination", CommandDataType.VarChar, CommandDirection.Input, 63, filterDestination)
                    .Add("@iFilter_Truck", CommandDataType.VarChar, CommandDirection.Input, 255, filterTruck)
                    .Add("@iFilter_Start_Date", CommandDataType.DateTime, CommandDirection.Input, 255, filterStartDate)
                    .Add("@iFilter_Start_Shift", CommandDataType.Char, CommandDirection.Input, 1, filterStartShift)
                    .Add("@iFilter_End_Date", CommandDataType.DateTime, CommandDirection.Input, 255, filterEndDate)
                    .Add("@iFilter_End_Shift", CommandDataType.Char, CommandDirection.Input, 1, filterEndShift)
                    .Add("@iShowHaulageWithApprovedChild", CommandDataType.Bit, CommandDirection.Input, showHaulageWithApprovedChild)
                    .Add("@iTop", CommandDataType.Bit, CommandDirection.Input, top)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                    .Add("@oCountDestinationCrusher", CommandDataType.Int, CommandDirection.Output, countDestinationCrusher)
                    .Add("@oCountDestinationMill", CommandDataType.Int, CommandDirection.Output, countDestinationMill)
                    .Add("@oCountDestinationStockpile", CommandDataType.Int, CommandDirection.Output, countDestinationStockpile)
                    .Add("@oCountRecords", CommandDataType.Int, CommandDirection.Output, countRecords)
                    .Add("@oCountSourceDigblock", CommandDataType.Int, CommandDirection.Output, countSourceDigblock)
                    .Add("@oCountSourceMill", CommandDataType.Int, CommandDirection.Output, countSourceMill)
                    .Add("@oCountSourceStockpile", CommandDataType.Int, CommandDirection.Output, countSourceStockpile)
                    .Add("@oSumTonnes", CommandDataType.Float, CommandDirection.Output, sumTonnes)
                End With

                returnTable = .ExecuteDataTable

                countDestinationCrusher = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationCrusher").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationCrusher").Value))
                countDestinationMill = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationMill").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationMill").Value))
                countDestinationStockpile = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationStockpile").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationStockpile").Value))
                countRecords = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountRecords").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountRecords").Value))
                countSourceDigblock = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceDigblock").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceDigblock").Value))
                countSourceMill = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceMill").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceMill").Value))
                countSourceStockpile = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceStockpile").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceStockpile").Value))
                sumTonnes = Convert.ToDouble(IIf(.ParameterCollection.Item("@oSumTonnes").Value Is DBNull.Value, NullValues.Double, .ParameterCollection.Item("@oSumTonnes").Value))

                Return returnTable
            End With
        End Function

        Function GetBhpbioHaulageCorrectionListFilter(ByVal filterType As String, ByVal locationId As Int32) As DataTable _
            Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageCorrectionListFilter
            With DataAccess
                .CommandText = "GetBhpbioHaulageCorrectionListFilter"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFilterType", CommandDataType.VarChar, CommandDirection.Input, 31, filterType)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Public Overridable Function GetBhpbioHaulageCorrectionList(ByVal filterSource As String, _
             ByVal filterDestination As String, _
             ByVal filterDescription As String, _
             ByVal top As Int16, _
             ByVal recordLimit As Int32, _
             ByVal locationId As Int32) As DataTable Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageCorrectionList

            With DataAccess
                .CommandText = "GetBhpbioHaulageCorrectionList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFilter_Source", CommandDataType.VarChar, CommandDirection.Input, 63, filterSource)
                    .Add("@iFilter_Destination", CommandDataType.VarChar, CommandDirection.Input, 63, filterDestination)
                    .Add("@iFilter_Description", CommandDataType.VarChar, CommandDirection.Input, 255, filterDescription)
                    .Add("@iTop", CommandDataType.Bit, CommandDirection.Input, top)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                Return .ExecuteDataTable
            End With
        End Function

        Function GetBhpbioHaulageErrorCount(ByVal locationId As Int32) As Int32 _
            Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageErrorCount
            With DataAccess
                .CommandText = "GetBhpbioNoHaulageErrors"

                With .ParameterCollection
                    .Clear()
                    .Add("@NoErrors", CommandDataType.Int, CommandDirection.Output, -1)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@NoErrors").Value)
            End With
        End Function

        Function GetBhpbioHaulageErrorCount(ByVal locationId As Int32, month As DateTime) As Int32 _
            Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageErrorCount
            With DataAccess
                .CommandText = "GetBhpbioNoHaulageErrors2" 'TODO Consider just using ONE SP

                With .ParameterCollection
                    .Clear()
                    .Add("@NoErrors", CommandDataType.Int, CommandDirection.Output, -1)
                    .Add("@iMonth", CommandDataType.DateTime, CommandDirection.Input, month)
                    .Add("@iLocationId", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection("@NoErrors").Value)
            End With
        End Function
        Public Overridable Function GetBhpbioHaulageManagementList(ByVal locationId As Int32, ByVal filterStartDate As Date, _
          ByVal filterEndDate As Date, _
          ByVal filterStartShift As String, _
          ByVal filterEndShift As String, _
          ByVal filterSource As String, _
          ByVal filterDestination As String, _
          ByVal filterTruck As String, _
          ByVal showHaulageWithApprovedChild As Int16, _
          ByVal top As Int16, _
          ByRef countDestinationCrusher As Int32, _
          ByRef countDestinationMill As Int32, _
          ByRef countDestinationStockpile As Int32, _
          ByRef countRecords As Int32, _
          ByRef countSourceDigblock As Int32, _
          ByRef countSourceMill As Int32, _
          ByRef countSourceStockpile As Int32, _
          ByRef sumTonnes As Double, _
          ByRef recordLimit As Int32) As DataTable Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageManagementList
            Dim returnTable As DataTable
            With DataAccess
                .CommandText = "GetBhpbioHaulageManagementList"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFilter_Source", CommandDataType.VarChar, CommandDirection.Input, 63, filterSource)
                    .Add("@iFilter_Destination", CommandDataType.VarChar, CommandDirection.Input, 63, filterDestination)
                    .Add("@iFilter_Truck", CommandDataType.VarChar, CommandDirection.Input, 255, filterTruck)
                    .Add("@iFilter_Start_Date", CommandDataType.DateTime, CommandDirection.Input, 255, filterStartDate)
                    .Add("@iFilter_Start_Shift", CommandDataType.Char, CommandDirection.Input, 1, filterStartShift)
                    .Add("@iFilter_End_Date", CommandDataType.DateTime, CommandDirection.Input, 255, filterEndDate)
                    .Add("@iFilter_End_Shift", CommandDataType.Char, CommandDirection.Input, 1, filterEndShift)
                    .Add("@iShowHaulageWithApprovedChild", CommandDataType.Bit, CommandDirection.Input, showHaulageWithApprovedChild)
                    .Add("@iTop", CommandDataType.Bit, CommandDirection.Input, top)
                    .Add("@iRecordLimit", CommandDataType.Int, CommandDirection.Input, recordLimit)
                    .Add("@oCountDestinationCrusher", CommandDataType.Int, CommandDirection.Output, countDestinationCrusher)
                    .Add("@iLocation_Id", CommandDataType.Int, CommandDirection.Input, locationId)
                    .Add("@oCountDestinationMill", CommandDataType.Int, CommandDirection.Output, countDestinationMill)
                    .Add("@oCountDestinationStockpile", CommandDataType.Int, CommandDirection.Output, countDestinationStockpile)
                    .Add("@oCountRecords", CommandDataType.Int, CommandDirection.Output, countRecords)
                    .Add("@oCountSourceDigblock", CommandDataType.Int, CommandDirection.Output, countSourceDigblock)
                    .Add("@oCountSourceMill", CommandDataType.Int, CommandDirection.Output, countSourceMill)
                    .Add("@oCountSourceStockpile", CommandDataType.Int, CommandDirection.Output, countSourceStockpile)
                    .Add("@oSumTonnes", CommandDataType.Float, CommandDirection.Output, sumTonnes)
                End With

                returnTable = .ExecuteDataTable

                countDestinationCrusher = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationCrusher").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationCrusher").Value))
                countDestinationMill = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationMill").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationMill").Value))
                countDestinationStockpile = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountDestinationStockpile").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountDestinationStockpile").Value))
                countRecords = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountRecords").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountRecords").Value))
                countSourceDigblock = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceDigblock").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceDigblock").Value))
                countSourceMill = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceMill").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceMill").Value))
                countSourceStockpile = Convert.ToInt32(IIf(.ParameterCollection.Item("@oCountSourceStockpile").Value Is DBNull.Value, NullValues.Int32, .ParameterCollection.Item("@oCountSourceStockpile").Value))
                sumTonnes = Convert.ToDouble(IIf(.ParameterCollection.Item("@oSumTonnes").Value Is DBNull.Value, NullValues.Double, .ParameterCollection.Item("@oSumTonnes").Value))

                Return returnTable
            End With
        End Function

        Public Overridable Function GetBhpbioHaulageManagementListFilter(ByVal filterType As String, _
          ByVal locationId As Int32) As DataTable Implements Bhpbio.Database.DalBaseObjects.IHaulage.GetBhpbioHaulageManagementListFilter
            With DataAccess
                .CommandText = "GetBhpbioHaulageManagementListFilter"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFilter_Type", CommandDataType.VarChar, CommandDirection.Input, 31, filterType)
                    .Add("@iLocation_Id", CommandDataType.Int, CommandDirection.Input, locationId)
                End With

                Return .ExecuteDataTable
            End With
        End Function
    End Class
End Namespace
