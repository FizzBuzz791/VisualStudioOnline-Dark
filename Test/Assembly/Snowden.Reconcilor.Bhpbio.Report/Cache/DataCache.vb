Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.ComponentModel
Imports System.Threading

Namespace Cache
    ''' <summary>
    ''' Abstract class to where data can be stored for subquential calls of the same parameters.
    ''' </summary>
    ''' <remarks>Must inherit and override in the AquireFromDatabase Call</remarks>
    Public MustInherit Class DataCache
        Implements IDisposable

        Private Class DataRetrievalWork
            Public LocationId As Integer
            Public Result As DataSet

            Public StartDate As DateTime
            Public EndDate As DateTime
            Public DateBreakdownText As String
            Public Err As Exception
            Public WaitObject As AutoResetEvent

        End Class

#Region "Properties"
        Private _cache As DataSet
        Private _disposed As Boolean
        Private _requestParameter As DataRequest
        Private _session As Types.ReportSession

        ''' <summary>
        ''' Holds the report session with all the active connections. 
        ''' </summary>
        ''' <remarks>Required by the data cache.</remarks>
        Protected Property Session() As Types.ReportSession
            Get
                Return _session
            End Get
            Set(ByVal value As Types.ReportSession)
                _session = value
            End Set
        End Property

        Public Property RequestParameter() As DataRequest
            Get
                Return _requestParameter
            End Get
            Set(ByVal value As Types.DataRequest)
                ' If the data has not changed don't clear the cache.
                If Not value Is Nothing And Not _requestParameter Is Nothing Then
                    If Not (DataRequest.Equal(value, _requestParameter)) Then
                        If Not _cache Is Nothing Then
                            _cache.Dispose()
                            _cache = Nothing
                        End If
                        _requestParameter = value
                    End If
                Else
                    If Not _cache Is Nothing Then
                        _cache.Dispose()
                        _cache = Nothing
                    End If
                    _requestParameter = value
                End If
            End Set
        End Property

        Protected Property Cache() As DataSet
            Get
                Return _cache
            End Get
            Set(ByVal value As DataSet)
                _cache = value
            End Set
        End Property
#End Region

        Protected Sub New()
        End Sub

        Protected Sub New(ByVal session As Types.ReportSession)
            _session = session
        End Sub

#Region " Destructors "
        Public Sub Dispose() Implements IDisposable.Dispose
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If (Not _disposed) Then
                If (disposing) Then
                    If (Not _cache Is Nothing) Then
                        _cache.Dispose()
                        _cache = Nothing
                    End If

                End If
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub
#End Region

        ' Force the cache to clear
        Public Sub ClearCache()
            Cache = Nothing
        End Sub

        ' Public Interfaces
        Public Function RetrieveData() As DataSet
            Dim returnSet As DataSet = Nothing
            If Not Cache Is Nothing Then
                returnSet = Cache
            ElseIf Not _requestParameter Is Nothing Then
                Cache = AcquireData(_requestParameter.StartDate, _requestParameter.EndDate,
               _requestParameter.DateBreakdown, _requestParameter.LocationId,
               _requestParameter.ChildLocations)
                returnSet = Cache
            Else
                Throw New InvalidOperationException("A request for data before the calculation parameters have been set up was made.")
            End If

            Return returnSet
        End Function

        Private Function AcquireContributingDataSet(ByRef contribResult As DataRetrievalWork, ByRef session As ReportSession) As Boolean

            Using threadReportContext As New ReportThreadContext(session.DalConnectionText)
                contribResult.Result = AcquireFromDatabase(contribResult.StartDate, contribResult.EndDate, contribResult.DateBreakdownText, contribResult.LocationId, False)
            End Using

            Return True
        End Function

        Private Function HandleContributingDataSetRetrievalComplete(ByRef contribResult As DataRetrievalWork, ByVal e As RunWorkerCompletedEventArgs) As Boolean
            If (Not e.Error Is Nothing) Then
                contribResult.Err = e.Error
            End If

            contribResult.WaitObject.Set()

            Return True
        End Function

        ' Public Interfaces
        Public Function AcquireData(ByVal startDate As DateTime,
         ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown,
         ByVal locationId As Nullable(Of Int32), ByVal childLocations As Boolean) As DataSet
            Dim dateBreakdownText As String
            Dim rawData As DataSet = Nothing
            Dim dalLocationId As Int32

            If Session Is Nothing Then
                Throw New InvalidOperationException("The session object must be set up before requesting report data.")
            End If

            dateBreakdownText = ReportSession.ConvertReportBreakdown(dateBreakdown)

            If locationId Is Nothing Then
                dalLocationId = NullValues.Int32
            Else
                dalLocationId = locationId.Value
            End If

            If Not Session.NoData Then
                ' For product type based queries where the product location on the session is the top level location (WAIO)
                If (Not Session.SelectedProductType Is Nothing AndAlso
                    Not Session.SelectedProductType.LocationIds Is Nothing AndAlso
                    Not Session.SelectedProductType.LocationIds.Count = 0 AndAlso
                    Session.RequestParameter.LocationId = ProductType.DefaultTopLevelLocationId) Then

                    ' It is neccessary to retrieve data for each hub, one at a time, and keep the results in seperate tables
                    Dim hubIndex As Integer = 1

                    ' Define the contributing datasets required
                    Dim contributingDataSets As New List(Of DataRetrievalWork)
                    For Each contributingLocationId As Integer In Session.SelectedProductType.LocationIds
                        Dim contribResult As DataRetrievalWork = New DataRetrievalWork()
                        contribResult.LocationId = contributingLocationId
                        contribResult.StartDate = startDate
                        contribResult.EndDate = endDate
                        contribResult.DateBreakdownText = dateBreakdownText
                        contribResult.WaitObject = New AutoResetEvent(False)
                        contributingDataSets.Add(contribResult)
                    Next

                    ' use a background worker for each result
                    Dim workers As New List(Of BackgroundWorker)
                    For Each contributingResult As DataRetrievalWork In contributingDataSets
                        AcquireContributingDataSet(contributingResult, Session)

                        ' Removed Multi-threading as per WREC-2475 (BHPBIO: D232 / D242)
                        'Dim worker As New BackgroundWorker()
                        'workers.Add(worker)

                        'AddHandler worker.DoWork, Function(sender, e) (AcquireContributingDataSet(contributingResult, Session))
                        'AddHandler worker.RunWorkerCompleted, Function(ByVal sender As Object, ByVal e As RunWorkerCompletedEventArgs) (HandleContributingDataSetRetrievalComplete(contributingResult, e))

                        '' start the work
                        'worker.RunWorkerAsync(contributingResult)
                    Next

                    For Each contributingResult As DataRetrievalWork In contributingDataSets

                        ' Removed Multi-threading as per WREC-2475 (BHPBIO: D232 / D242)
                        ' wait for the result
                        'contributingResult.WaitObject.WaitOne()

                        ' if an error then rethrow
                        If (Not contributingResult.Err Is Nothing) Then
                            Throw contributingResult.Err
                        End If

                        If (rawData Is Nothing) Then

                            If Session.SelectedProductType.LocationIds.Count > 1 Then
                                ' we still need to reset the location ids for the first dataset, if there is more than one
                                ' location
                                If childLocations Then
                                    ResetLocationIds(contributingResult.Result, contributingResult.LocationId, overWriteNull:=True)
                                Else
                                    ResetLocationIds(contributingResult.Result, ProductType.DefaultTopLevelLocationId, overWriteNull:=False)
                                End If

                            End If

                            ' if this is the first contributing data set.. use it as the result data set
                            rawData = contributingResult.Result

                        Else
                            ' otherwise this is a subsequent data set
                            ' these results must be combined with the already retrieved results but kept in seperate tables
                            hubIndex = hubIndex + 1
                            For Each table As DataTable In contributingResult.Result.Tables
                                ' rename the table to have a suffix (making it unique) so that it can coexist with the data already retreived
                                table.TableName = String.Format("{0}{1}", table.TableName, hubIndex)

                                ' if we are getting child locations for this query, then we need to reset the location
                                ' column to contain the right information, if not getting children we need to set the location_id to the
                                ' parent location_id (usually WAIO), but we only want to do this if the value in the field
                                ' is not null - we don't want to overwrite non null values, as some upsteam code might depend on it
                                '
                                ' This code is used by *every* calculation, so it is important to consider all scenarios
                                ' when modifing it
                                '
                                If childLocations Then
                                    ResetLocationIds(table, contributingResult.LocationId, overWriteNull:=True)
                                Else
                                    ResetLocationIds(table, ProductType.DefaultTopLevelLocationId, overWriteNull:=False)
                                End If

                            Next
                            ' add this dataset (for the current hub) to the existing dataset
                            rawData.Merge(contributingResult.Result)
                        End If
                    Next
                Else
                    ' This is either not a product type based retrieval; or it is but only a single hub is being selected
                    rawData = AcquireFromDatabase(startDate, endDate, dateBreakdownText, dalLocationId, childLocations)
                End If
            Else
                rawData = CreateStubRawData()
            End If

            Return rawData
        End Function

        Private Sub ResetLocationIds(ByRef ds As DataSet, locationId As Integer, overWriteNull As Boolean)
            For Each table As DataTable In ds.Tables
                ResetLocationIds(table, locationId, overWriteNull)
            Next
        End Sub

        Private Sub ResetLocationIds(ByRef table As DataTable, locationId As Integer, overWriteNull As Boolean)
            If (table.Columns.Contains(CalculationResultRecord.ColumnNameLocationId)) Then
                ' replace any Location Id values that represent the hub itself, to the upper WAIO level.. this allows later aggregation
                For Each dr As DataRow In table.Rows
                    Dim rowLocationId = dr(CalculationResultRecord.ColumnNameLocationId)

                    If overWriteNull Then
                        dr(CalculationResultRecord.ColumnNameLocationId) = locationId
                    ElseIf Not overWriteNull And dr.HasValue(CalculationResultRecord.ColumnNameLocationId) Then
                        dr(CalculationResultRecord.ColumnNameLocationId) = locationId
                    End If

                Next

            End If
        End Sub

        Public Sub SetProperties(ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal dateBreakdown As Types.ReportBreakdown, _
         ByVal locationId As Int32, ByVal childLocations As Boolean)
            RequestParameter = New DataRequest(locationId, startDate, endDate, dateBreakdown, _
                                            childLocations)
        End Sub

        ' Internal Interfaces
        Protected Overridable Function AcquireFromDatabase(ByVal startDate As DateTime, _
         ByVal endDate As DateTime, ByVal dateBreakdownText As String, _
         ByVal locationId As Int32, ByVal childLocations As Boolean) As DataSet
            Return New DataSet
        End Function

        Private Shared Function CreateStubRawData() As DataSet
            CreateStubRawData = New DataSet()
            CreateStubRawData.Tables.Add(New DataTable("Value"))
            CreateStubRawData.Tables.Add(New DataTable("Grade"))
        End Function
    End Class
End Namespace
