Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IRecalc
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Overloads Function GetRecalcLogicHistoryTransactionLevel0( _
         ByVal startDate As DateTime, ByVal startShift As String, _
         ByVal endDate As DateTime, ByVal endShift As String, _
         ByVal source As String, _
         ByVal destination As String, _
         ByVal transactionType As String, _
         ByVal includeGrades As Int16, _
         ByVal sourceType As String) As DataTable

        ''' <summary>
        ''' Adds queue entries to the Data Series Processing queue as required based on recalc history
        ''' </summary>
        ''' <param name="lookbackMinutes">A lookback minutes value indicating how far back in recalc history to look</param>
        Sub AddBhpbioDataRetrievalQueueEntriesForRecalcHistory(ByVal lookbackMinutes As Integer)

    End Interface
End Namespace

