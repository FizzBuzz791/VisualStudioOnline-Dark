Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace SqlDal

    Public Class SqlDalRecalc
        Inherits Core.Database.SqlDal.SqlDalRecalc
        Implements Bhpbio.Database.DalBaseObjects.IRecalc

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

        Public Overridable Overloads Function GetRecalcLogicHistoryTransactionLevel0( _
         ByVal startDate As DateTime, ByVal startShift As String, _
         ByVal endDate As DateTime, ByVal endShift As String, _
         ByVal source As String, _
         ByVal destination As String, _
         ByVal transactionType As String, _
         ByVal includeGrades As Int16, _
         ByVal sourceType As String) As DataTable _
         Implements IRecalc.GetRecalcLogicHistoryTransactionLevel0
            With DataAccess
                .CommandText = "dbo.GetBhpbioRecalcLogicHistoryTransactionLevel0"

                With .ParameterCollection
                    .Clear()

                    .Add("@iFrom_Date", CommandDataType.DateTime, CommandDirection.Input, startDate)
                    .Add("@iFrom_Shift", CommandDataType.Char, CommandDirection.Input, 1, startShift)
                    .Add("@iTo_Date", CommandDataType.DateTime, CommandDirection.Input, endDate)
                    .Add("@iTo_Shift", CommandDataType.Char, CommandDirection.Input, 1, endShift)
                    .Add("@iSource", CommandDataType.VarChar, CommandDirection.Input, 31, source)
                    .Add("@iDestination", CommandDataType.VarChar, CommandDirection.Input, 31, destination)
                    .Add("@iTransaction_Type", CommandDataType.VarChar, CommandDirection.Input, 31, transactionType)
                    .Add("@iInclude_Grades", CommandDataType.Bit, CommandDirection.Input, includeGrades)
                    .Add("@iSource_Type", CommandDataType.VarChar, CommandDirection.Input, 31, sourceType)
                End With

                Return .ExecuteDataTable
            End With
        End Function


        ''' <summary>
        ''' Adds queue entries to the Data Series Processing queue as required based on recalc history
        ''' </summary>
        ''' <param name="lookbackMinutes">A lookback minutes value indicating how far back in recalc history to look</param>
        Public Sub AddBhpbioDataRetrievalQueueEntriesForRecalcHistory(ByVal lookbackMinutes As Integer) Implements IRecalc.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory
            With DataAccess
                .CommandText = "dbo.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory"

                With .ParameterCollection
                    .Clear()

                    .Add("@iHistoryLookbackMinutes", CommandDataType.Int, CommandDirection.Input, lookbackMinutes)
                End With

                .ExecuteNonQuery()
            End With
        End Sub
    End Class
End Namespace

