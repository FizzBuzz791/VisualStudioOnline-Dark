Namespace Types
    ''' <summary>
    ''' Contains the result of a given calculation.
    ''' Also supplies shared functions for the conversion between datatables and calculationResult.
    ''' </summary>
    ''' <remarks>CalculationResult will contain one to many CalculationDate</remarks>
    <DebuggerDisplayAttribute("CalcId:{_calcId}, TagId:{_tagId}, Records: {Count}")> _
    Public Class CalculationResult
        Inherits ObjectModel.Collection(Of CalculationResultRecord)
        Implements IDisposable

        Public Const ProductSizeTotal As String = "TOTAL"

#Region "Properties"
        Private _disposed As Boolean
        Private _tagId As String
        Private _calcId As String
        Private _description As String
        Private _inError As Boolean
        Private _errorMessage As String
        Private _parentResults As New ObjectModel.Collection(Of CalculationResult)
        Private _calculationType As CalculationResultType
        Private _tags As New ObjectModel.Collection(Of CalculationResultTag)

        Public Property GeometType As GeometTypeSelection = GeometTypeSelection.NA

        Public ReadOnly Property PresentationValid As Boolean
            Get
                If Tags Is Nothing Then
                    Return False
                End If

                Dim tag = Tags.FirstOrDefault(Function(t) t.TagId = "PresentationValid")
                If tag Is Nothing Then
                    Return False
                Else
                    Return Convert.ToBoolean(tag.Value)
                End If
            End Get
        End Property


        Public Property CalcId() As String
            Get
                Return _calcId
            End Get
            Set(ByVal value As String)
                _calcId = value
            End Set
        End Property

        ''' <summary>
        ''' Remove any result rows that are ResourceClassification related
        ''' </summary>
        Public Sub RemoveResourceClassificationRows()
            Dim index As Integer = 0
            Dim rowIndexesToRemove = New List(Of Integer)
            For Each dr In Me
                If Not String.IsNullOrEmpty(dr.ResourceClassification) Then
                    ' maintain a list of row indexes to remove... (in reverse order)
                    rowIndexesToRemove.Insert(0, index)
                End If
                index = index + 1
            Next

            For Each i As Integer In rowIndexesToRemove
                Me.RemoveAt(i)
            Next
        End Sub

        Public Property TagId() As String
            Get
                Return _tagId
            End Get
            Set(ByVal value As String)
                _tagId = value
            End Set
        End Property

        Public Property CalculationType() As CalculationResultType
            Get
                Return _calculationType
            End Get
            Set(ByVal value As CalculationResultType)
                _calculationType = value
            End Set
        End Property

        Public ReadOnly Property ParentResults() As ObjectModel.Collection(Of CalculationResult)
            Get
                Return _parentResults
            End Get
        End Property

        Public Property Description() As String
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Public Property InError() As Boolean
            Get
                Return _inError
            End Get
            Set(ByVal value As Boolean)
                _inError = value
            End Set
        End Property

        Public Property ErrorMessage() As String
            Get
                Return _errorMessage
            End Get
            Set(ByVal value As String)
                _errorMessage = value
            End Set
        End Property

#Region "Result Collections"
        Public ReadOnly Property CalendarDateCollection() As IEnumerable(Of DateTime)
            Get
                Return From m In Me Group By m.CalendarDate Into Group Select CalendarDate
            End Get
        End Property

        Public ReadOnly Property MaterialTypeIdCollection() As IEnumerable(Of Int32?)
            Get
                Return From m In Me Group By m.MaterialTypeId Into Group Select MaterialTypeId
            End Get
        End Property

        Public ReadOnly Property LocationIdCollection() As IEnumerable(Of Int32?)
            Get
                Return From m In Me Group By m.LocationId Into Group Select LocationId
            End Get
        End Property

        Public ReadOnly Property ProductSizeCollection() As IEnumerable(Of String)
            Get
                Return From m In Me Group By m.ProductSize Into Group Select ProductSize
            End Get
        End Property

        Public ReadOnly Property ResourceClassificationCollection() As IEnumerable(Of String)
            Get
                Return From m In Me Group By m.ResourceClassification Into Group Select ResourceClassification
            End Get
        End Property

        Public ReadOnly Property IncludesResourceClassificationData As Boolean
            Get
                Return ResourceClassificationCollection.Where(Function(r) Not String.IsNullOrEmpty(r)).Count > 0
            End Get
        End Property

#End Region

        Private Shared Function GroupedOnDateTime(ByVal used As Boolean, ByVal value As DateTime, ByVal forcedReportTimeBreakdown As ReportBreakdown?) As DateTime
            If used Then
                If (Not forcedReportTimeBreakdown Is Nothing) Then

                    Return Data.DateBreakdown.FindStartOfBreakdownPeriod(value, forcedReportTimeBreakdown.Value)
                Else
                    Return value
                End If
            Else
                Return Nothing
            End If

        End Function

        Private Shared Function GroupedOnInt(ByVal used As Boolean, ByVal value As Int32?) As Int32?
            If used Then
                Return value
            Else
                Return Nothing
            End If
        End Function

        Private Shared Function GroupedOnString(ByVal used As Boolean, ByVal value As String) As String
            If used Then
                Return value
            Else
                Return Nothing
            End If
        End Function


        Private Shared Function GroupedOnBoolean(ByVal used As Boolean, ByVal value As Boolean?) As Boolean?
            If used Then
                Return value
            Else
                Return Nothing
            End If
        End Function

        Public Function AggregateRecords(ByVal onDate As Boolean,
                                            ByVal onMaterialTypeId As Boolean,
                                            ByVal onLocationId As Boolean,
                                            ByVal onProductSize As Boolean,
                                            Optional ByVal useSpecificH2OGradeWeighting As Boolean = True
                                         ) As IEnumerable(Of CalculationResultRecord)
            Return AggregateRecords(onDate, onMaterialTypeId, onLocationId, onProductSize, CType(Nothing, ReportBreakdown?), useSpecificH2OGradeWeighting)
        End Function



        Public Function AggregateRecords(ByVal onDate As Boolean, ByVal onMaterialTypeId As Boolean,
                                                  ByVal onLocationId As Boolean,
                                                  ByVal onProductSize As Boolean,
                                                  ByVal forcedReportTimeBreakdown As ReportBreakdown?,
                                                  Optional ByVal useSpecificH2OGradeWeighting As Boolean = True) As IEnumerable(Of CalculationResultRecord)

            Dim aggregatedRecords As IEnumerable(Of CalculationResultRecord)
            Dim arrayList = ToArray()
            Dim onResourceClassification = True

            'note - this only appears to support Tonnes based aggregations... not sure what a ratio record would do??

            ' Dodgy Aggregate tonnes is used here for aggregation, as it will either
            ' equal tonnes if dodgy aggregate is turned off, or equal the absolute sum tonnes that we want to aggregate by.
            ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
            '
            ' Note that the counts for the moisture (And Density) grades are done differently! When weighting the other grades a missing
            ' value counts the same as a zero, unless the Fe is missing as well, for H2O the weighting is based whether
            ' the grade is present for each individual record. This is required because some calculations don't have these 
            ' grades
            aggregatedRecords = (From t In arrayList
                                 Group By CalendarDate = GroupedOnDateTime(onDate, t.CalendarDate, forcedReportTimeBreakdown),
                                    LocationId = GroupedOnInt(onLocationId, t.LocationId),
                                    MaterialType = GroupedOnInt(onMaterialTypeId, t.MaterialTypeId),
                                    ProductSize = t.ProductSize,
                                    ResourceClassification = GroupedOnString(onResourceClassification, t.ResourceClassification)
                                 Into Tonnes = Sum(t.Tonnes),
                                    Volume = Sum(t.Volume),
                                    DodgyAggregateGradeTonnes = Sum(t.DodgyAggregateGradeTonnes),
                                    H2OGradeTonnes = Sum(Convert.ToDouble(IIf(t.H2O Is Nothing, 0.0, t.DodgyAggregateGradeTonnes))),
                                    UltrafinesGradeTonnes = Sum(Convert.ToDouble(IIf(t.UltraFines Is Nothing, 0.0, t.DodgyAggregateGradeTonnes))),
                                    DateFrom = Min(t.DateFrom),
                                    DateTo = Max(t.DateTo),
                                    DodgyAggregateEnabled = Max(t.DodgyAggregateEnabled),
                                    Fe = Sum(t.DodgyAggregateGradeTonnes * t.Fe), FeCnt = Sum(Convert.ToInt32(IIf(t.Fe Is Nothing, 0, 1))),
                                    P = Sum(t.DodgyAggregateGradeTonnes * t.P), PCnt = Sum(Convert.ToInt32(IIf(t.Fe Is Nothing, 0, 1))),
                                    SiO2 = Sum(t.DodgyAggregateGradeTonnes * t.SiO2), SiO2Cnt = Sum(Convert.ToInt32(IIf(t.Fe Is Nothing, 0, 1))),
                                    Al2O3 = Sum(t.DodgyAggregateGradeTonnes * t.Al2O3), Al2O3Cnt = Sum(Convert.ToInt32(IIf(t.Fe Is Nothing, 0, 1))),
                                    LOI = Sum(t.DodgyAggregateGradeTonnes * t.Loi), LOICnt = Sum(Convert.ToInt32(IIf(t.Fe Is Nothing, 0, 1))),
                                    Ultrafines = Sum(t.DodgyAggregateGradeTonnes * t.UltraFines), UltrafinesCnt = Sum(Convert.ToInt32(IIf(t.UltraFines Is Nothing, 0, 1))),
                                    Density = Sum(t.DodgyAggregateGradeTonnes * t.Density), DensityCnt = Sum(Convert.ToInt32(IIf(t.Density Is Nothing, 0, 1))),
                                    H2O = Sum(t.DodgyAggregateGradeTonnes * t.H2O), H2OCnt = Sum(Convert.ToInt32(IIf(t.H2O Is Nothing, 0, 1))),
                                    H2ODropped = Sum(t.DodgyAggregateGradeTonnes * t.H2ODropped), H2ODroppedCnt = Sum(Convert.ToInt32(IIf(t.H2O Is Nothing, 0, 1))),
                                    H2OShipped = Sum(t.DodgyAggregateGradeTonnes * t.H2OShipped), H2OShippedCnt = Sum(Convert.ToInt32(IIf(t.H2O Is Nothing, 0, 1)))
                                 Order By CalendarDate
                                 Select New CalculationResultRecord(Nothing) With {
                                    .CalendarDate = CalendarDate, .MaterialTypeId = MaterialType,
                                    .LocationId = LocationId, .DateFrom = DateFrom, .DateTo = DateTo,
                                    .ProductSize = ProductSize,
                                    .ResourceClassification = ResourceClassification,
                                    .Tonnes = Tonnes,
                                    .Volume = Volume,
                                    .DodgyAggregateGradeTonnes = DodgyAggregateGradeTonnes,
                                    .DodgyAggregateEnabled = DodgyAggregateEnabled,
                                    .Fe = MassWeight(Fe, DodgyAggregateGradeTonnes, FeCnt),
                                    .P = MassWeight(P, DodgyAggregateGradeTonnes, PCnt),
                                    .SiO2 = MassWeight(SiO2, DodgyAggregateGradeTonnes, SiO2Cnt),
                                    .Al2O3 = MassWeight(Al2O3, DodgyAggregateGradeTonnes, Al2O3Cnt),
                                    .Loi = MassWeight(LOI, DodgyAggregateGradeTonnes, LOICnt),
                                    .Density = MassWeight(Density, DodgyAggregateGradeTonnes, DensityCnt),
                                    .UltraFines = MassWeight(Ultrafines, UltrafinesGradeTonnes, UltrafinesCnt),
                                    .H2O = MassWeight(H2O, DirectCast(IIf(useSpecificH2OGradeWeighting, H2OGradeTonnes, DodgyAggregateGradeTonnes), Double), H2OCnt),
                                    .H2ODropped = MassWeight(H2ODropped, DirectCast(IIf(useSpecificH2OGradeWeighting, H2OGradeTonnes, DodgyAggregateGradeTonnes), Double), H2ODroppedCnt),
                                    .H2OShipped = MassWeight(H2OShipped, DirectCast(IIf(useSpecificH2OGradeWeighting, H2OGradeTonnes, DodgyAggregateGradeTonnes), Double), H2OShippedCnt)
                                })

            If onProductSize = False Then
                aggregatedRecords = aggregatedRecords.Where(Function(r) r.ProductSize.ToUpper = ProductSizeTotal)
            End If

            Return aggregatedRecords
        End Function


        'Public Function AggregateFilterRecords(ByVal onMaterialTypeId As Boolean, _
        ' ByVal onLocationId As Boolean, ByVal onProductSize As Boolean, ByVal dateFilter As DateTime, ByVal locationIdFilter As Int32?) As IEnumerable(Of CalculationResultRecord)
        '    Return AggregateFilterRecords(onMaterialTypeId, onLocationId, onProductSize, dateFilter, locationIdFilter, CType(Nothing, ReportBreakdown?))
        'End Function

        Public Function AggregateFilterRecords(ByVal onMaterialTypeId As Boolean,
         ByVal onLocationId As Boolean,
         ByVal onProductSize As Boolean,
         ByVal dateFilter As DateTime,
         ByVal locationIdFilter As Int32?,
         ByVal aggregateToDateBreakdown As ReportBreakdown?) As IEnumerable(Of CalculationResultRecord)

            Dim aggregatedRecords = AggregateRecords(True, onMaterialTypeId, onLocationId, onProductSize, aggregateToDateBreakdown)

            Dim filteredRecords As IEnumerable(Of CalculationResultRecord)
            filteredRecords = aggregatedRecords.Where(Function(t) t.CalendarDate = dateFilter _
                                                          And NullableIntEqual(t.LocationId, locationIdFilter))

            Return filteredRecords
        End Function


        Public ReadOnly Property AggregatedDateLocationMaterial(ByVal calDate As DateTime,
         ByVal location As Int32?, ByVal materialTypeId As Int32?, ByVal productSize As String) As CalculationResultRecord
            Get
                Dim aggregatedFilteredRecords As IEnumerable(Of CalculationResultRecord)
                Dim aggregatedRecord As CalculationResultRecord = Nothing

                aggregatedFilteredRecords = From t In AggregateRecords(True, True, True, True)
                                            Where t.CalendarDate = calDate _
                                                And NullableIntEqual(location, t.LocationId) _
                                                And NullableIntEqual(materialTypeId, t.MaterialTypeId) _
                                                And productSize = t.ProductSize
                                            Select t

                If aggregatedFilteredRecords.Count < 1 Then
                    aggregatedRecord = Nothing
                ElseIf aggregatedFilteredRecords.Count = 1 Then
                    aggregatedRecord = aggregatedFilteredRecords.First()
                Else
                    Throw New ArgumentException("Invalid data causes the date has more than one record.")
                End If

                If Not aggregatedRecord Is Nothing Then
                    aggregatedRecord.RecalculateDensity()
                End If

                Return aggregatedRecord
            End Get
        End Property

        Private Shared Function MassWeight(ByVal gradeTonnes As Double?, ByVal totalTonnes As Double?, ByVal count As Int32) As Double?
            MassWeight = Nothing
            If count > 0 AndAlso Not gradeTonnes Is Nothing AndAlso Not totalTonnes Is Nothing Then
                If totalTonnes <> 0 Then
                    MassWeight = gradeTonnes / totalTonnes
                Else
                    MassWeight = 0
                End If
            End If
        End Function

        Public ReadOnly Property AggregatedDateLocation(ByVal calDate As DateTime, ByVal location As Int32?, ByVal productSize As String) As CalculationResultRecord
            Get
                Dim aggregatedFilteredRecords As IEnumerable(Of CalculationResultRecord)
                Dim aggregatedRecord As CalculationResultRecord = Nothing
                Dim aggregatedRecords As IEnumerable(Of CalculationResultRecord) = AggregateRecords(True, False, True, True)

                aggregatedFilteredRecords = From t In aggregatedRecords
                                            Where (t.CalendarDate = calDate) _
                                            And ((location.HasValue And t.LocationId.HasValue AndAlso location.Value = t.LocationId.Value) _
                                                 Or (Not location.HasValue And Not t.LocationId.HasValue)) _
                                            And (productSize = t.ProductSize)
                                            Select t

                If aggregatedFilteredRecords.Count < 1 Then
                    aggregatedRecord = Nothing
                ElseIf aggregatedFilteredRecords.Count = 1 Then
                    aggregatedRecord = aggregatedFilteredRecords.First()
                Else
                    Throw New InvalidOperationException("Invalid data causes the date has more than one record.")
                End If

                If Not aggregatedRecord Is Nothing Then
                    aggregatedRecord.RecalculateDensity()
                End If

                Return aggregatedRecord
            End Get
        End Property

        Public ReadOnly Property Tags() As ObjectModel.Collection(Of CalculationResultTag)
            Get
                Return _tags
            End Get
        End Property
#End Region

#Region "Constructors"
        Public Sub New()
            CalculationType = CalculationResultType.Tonnes
        End Sub

        Public Sub New(ByVal resultType As CalculationResultType)
            CalculationType = resultType
        End Sub

        ''' <summary>
        ''' Creates and fills out the structure the the calculations.
        ''' </summary>
        Public Sub New(ByVal valueRows As DataRow(), ByVal gradeRows As DataRow())
            Me.New(valueRows, gradeRows, Nothing, Nothing, Nothing)
        End Sub

        ''' <summary>
        ''' Creates and fills out the structure the the calculations with dates.
        ''' </summary>
        Public Sub New(ByVal valueRows As DataRow(), ByVal gradeRows As DataRow(),
         ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal interval As Types.ReportBreakdown)
            Me.New()
            MergeInRows(valueRows, gradeRows, startDate, endDate, interval)
        End Sub

        ''' <summary>
        ''' Add's the rows into the calculation result.
        ''' </summary>
        Public Sub MergeInRows(ByVal tableSet As DataSet,
         ByVal startDate As DateTime?, ByVal endDate As DateTime?, ByVal interval As Types.ReportBreakdown?)
            Dim values As DataTable = tableSet.Tables("Value")
            Dim grades As DataTable = tableSet.Tables("Grade")

            If values Is Nothing Then
                Throw New ArgumentException("Data set must contain the Values table.")
            End If

            If grades Is Nothing Then
                MergeInRows(values.Select(), Nothing, startDate, endDate, interval)
            Else
                MergeInRows(values.Select(), grades.Select(), startDate, endDate, interval)
            End If
        End Sub

        ''' <summary>
        ''' Add's the rows into the calculation result.
        ''' </summary>
        Public Sub MergeInRows(ByVal valueRows As DataRow(), ByVal gradeRows As DataRow(),
         ByVal startDate As DateTime?, ByVal endDate As DateTime?, ByVal interval As Types.ReportBreakdown?)
            Dim row As DataRow
            Dim record As CalculationResultRecord
            Dim existing As CalculationResultRecord
            Dim existingRecordFound As Boolean

            ' organise the gradeRows by date and location... 
            ' ...this prevents the lookup operations required by the merge getting exponentially more costly as the time span covered by the report increases
            Dim gradeRowStore As Dictionary(Of String, List(Of DataRow)) = BuildDataRowLookupByDateAndLocationStore(gradeRows)

            'add in the row provided
            For Each row In valueRows
                ' build a lookup key for the row
                Dim key As String = BuildDataRowLookupByDateAndLocationStoreKey(row)

                ' try to obtain matching grade rows
                Dim rowListForKey As List(Of DataRow) = Nothing
                If Not gradeRowStore.TryGetValue(key, rowListForKey) Then
                    ' if none are found create an empty list
                    rowListForKey = New List(Of DataRow)()
                End If

                ' create the row, but provide only the releated rows potentially needed for the merge
                record = New CalculationResultRecord(Me, row, rowListForKey)
                Add(record)
            Next

            'for any "gaps" in the data provided add the new requested records 
            'note that the gaps are only "date based" ... can extend later if required however
            'the only immediate need is to aggregate based on dates
            If Not startDate Is Nothing And Not endDate Is Nothing And Not interval Is Nothing Then
                For Each record In GetRecordsForPeriod(startDate.Value, endDate.Value, interval.Value)
                    existingRecordFound = False
                    For Each existing In Me
                        If existing.DateFrom = record.DateFrom And existing.DateTo = record.DateTo _
                         And ((existing.LocationId Is Nothing And record.LocationId Is Nothing) OrElse (existing.LocationId = record.LocationId)) _
                         And ((existing.MaterialTypeId Is Nothing And record.MaterialTypeId Is Nothing) OrElse (existing.MaterialTypeId = record.MaterialTypeId)) _
                         And ((existing.ProductSize Is Nothing And record.ProductSize Is Nothing) OrElse (existing.ProductSize = record.ProductSize)) _
                         And existing.CalendarDate = record.CalendarDate Then
                            existingRecordFound = True
                            Exit For
                        End If
                    Next

                    If Not existingRecordFound Then
                        Add(record)
                    End If
                Next
            End If
        End Sub

        ''' <summary>
        ''' Returns blank records for the dates.
        ''' </summary>
        Private Function GetRecordsForPeriod(ByVal startDate As DateTime, ByVal endDate As DateTime,
         ByVal dateBreakdown As Types.ReportBreakdown) As Generic.List(Of CalculationResultRecord)
            Dim list As New Generic.List(Of CalculationResultRecord)
            Dim currentDate As DateTime = startDate
            Dim endPeriodDate As DateTime
            Dim nextDate As DateTime
            Dim interval As DateInterval
            Dim intervalStep As Integer
            Dim runRange As Boolean = False

            If dateBreakdown = ReportBreakdown.Monthly Then
                runRange = True
                interval = DateInterval.Month
                intervalStep = 1
            ElseIf dateBreakdown = ReportBreakdown.CalendarQuarter Then
                runRange = True
                interval = DateInterval.Quarter
                intervalStep = 1
            ElseIf dateBreakdown = ReportBreakdown.Yearly Then
                runRange = True
                interval = DateInterval.Year
                intervalStep = 1
                currentDate = New DateTime(currentDate.Year, 1, 1)
            End If

            If runRange Then
                While currentDate <= endDate
                    nextDate = DateAdd(interval, intervalStep, currentDate)
                    endPeriodDate = DateAdd(DateInterval.Day, -1, nextDate)
                    list.Add(New CalculationResultRecord(Me, currentDate, endPeriodDate))
                    currentDate = nextDate
                End While
            Else
                list.Add(New CalculationResultRecord(Me, startDate, endDate))
            End If

            Return list
        End Function
#End Region

#Region "Destructors "
        Public Sub Dispose() Implements IDisposable.Dispose
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If (Not _disposed) Then
                If (disposing) Then
                    'Clean up managed Resources ie: Objects

                    If (Not _parentResults Is Nothing) Then
                        For Each result In _parentResults
                            result.Dispose()
                        Next
                        _parentResults = Nothing
                    End If

                    _tags = Nothing
                End If
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub
#End Region

#Region "Operations"
        Public Shared Function ApplyRatio(ByVal left As CalculationResult, ByVal right As CalculationResult) As CalculationResult
            Dim dateList As IEnumerable(Of Date) = left.CalendarDateCollection.Union(right.CalendarDateCollection).Distinct()
            Dim materialTypeIdList As IEnumerable(Of Int32?) = left.MaterialTypeIdCollection.Union(right.MaterialTypeIdCollection).Distinct()
            Dim locationIdList As IEnumerable(Of Int32?) = left.LocationIdCollection.Union(right.LocationIdCollection).Distinct()
            Dim productSizeList As IEnumerable(Of String) = left.ProductSizeCollection.Union(right.ProductSizeCollection).Distinct()
            Dim resouceList = left.ResourceClassificationCollection.Union(right.ResourceClassificationCollection).Distinct()

            Dim leftRecord As CalculationResultRecord = Nothing
            Dim rightRecord As CalculationResultRecord = Nothing
            Dim result As New CalculationResult()

            Dim preAggregatedLeft As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(left)
            Dim preAggregatedRight As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(right)

            For Each material In materialTypeIdList
                For Each location In locationIdList
                    For Each calendarDate In dateList
                        For Each productSize In productSizeList
                            For Each resouceClassification In resouceList
                                Dim lookupKey As String = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, material, productSize, resouceClassification)

                                preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                                preAggregatedRight.TryGetValue(lookupKey, rightRecord)

                                If Not leftRecord Is Nothing Or Not rightRecord Is Nothing Then
                                    result.Add(leftRecord * rightRecord)
                                End If

                                leftRecord = Nothing
                                rightRecord = Nothing
                            Next
                        Next
                    Next
                Next
            Next

            ' Correct parent link.
            For Each record In result
                record.Parent = result
            Next

            CalculationResult.CloneHeaders(result, left)

            Return result
        End Function

        Public Shared Function Divide(ByVal left As CalculationResult, ByVal right As CalculationResult, ByVal breakdownFactorByMaterialType As Boolean, ByVal calcId As String) As CalculationResult

            Dim dateList As IEnumerable(Of Date) = left.CalendarDateCollection.Union(right.CalendarDateCollection).Distinct()
            Dim locationIdList As IEnumerable(Of Int32?) = left.LocationIdCollection.Union(right.LocationIdCollection).Distinct()
            Dim productSizeList As IEnumerable(Of String) = left.ProductSizeCollection.Union(right.ProductSizeCollection).Distinct()
            Dim materialTypeIdList As IEnumerable(Of Int32?) = left.MaterialTypeIdCollection.Union(right.MaterialTypeIdCollection).Distinct()
            Dim resouceList = left.ResourceClassificationCollection.Union(right.ResourceClassificationCollection).Distinct()

            Dim result As New CalculationResult()
            Dim leftRecord As CalculationResultRecord = Nothing
            Dim rightRecord As CalculationResultRecord = Nothing
            Dim lookupKey As String

            Dim byMaterialType As Boolean = False

            If breakdownFactorByMaterialType AndAlso calcId.Contains("Factor") Then
                byMaterialType = True
            End If

            Dim preAggregatedLeft As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(left, False, True, True)
            Dim preAggregatedRight As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(right, False, True, True)

            Dim preAggregatedLeftWithMaterialType As Dictionary(Of String, CalculationResultRecord) = Nothing
            Dim preAggregatedRightWithMaterialType As Dictionary(Of String, CalculationResultRecord) = Nothing

            If byMaterialType Then
                preAggregatedLeftWithMaterialType = BuildRecordLookupByMainAggregationFieldsStore(left, True, True, True)
                preAggregatedRightWithMaterialType = BuildRecordLookupByMainAggregationFieldsStore(right, True, True, True)
            End If

            If breakdownFactorByMaterialType AndAlso calcId.Contains("Factor") Then
                ' iterate through material types and location types
                For Each location In locationIdList
                    For Each calendarDate In dateList
                        For Each productSize In productSizeList
                            For Each materialType In materialTypeIdList
                                For Each resouceClassification In resouceList
                                    If materialType Is Nothing Then
                                        ' this will be the total (aggregation) for all material types (i.e. when material type is null)
                                        lookupKey = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, Nothing, productSize, resouceClassification)

                                        preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                                        preAggregatedRight.TryGetValue(lookupKey, rightRecord)
                                    Else
                                        lookupKey = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, materialType, productSize, resouceClassification)

                                        preAggregatedLeftWithMaterialType.TryGetValue(lookupKey, leftRecord)
                                        preAggregatedRightWithMaterialType.TryGetValue(lookupKey, rightRecord)
                                    End If

                                    If Not leftRecord Is Nothing And Not rightRecord Is Nothing Then
                                        result.Add(leftRecord / rightRecord)
                                    End If

                                    leftRecord = Nothing
                                    rightRecord = Nothing
                                Next
                            Next
                        Next
                    Next
                Next
            Else
                For Each location In locationIdList
                    For Each calendarDate In dateList
                        For Each productSize In productSizeList
                            For Each resouceClassification In resouceList
                                lookupKey = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, Nothing, productSize, resouceClassification)

                                preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                                preAggregatedRight.TryGetValue(lookupKey, rightRecord)

                                If Not leftRecord Is Nothing Or Not rightRecord Is Nothing Then
                                    result.Add(leftRecord / rightRecord)
                                End If

                                leftRecord = Nothing
                                rightRecord = Nothing
                            Next
                        Next
                    Next
                Next
            End If

            ' Correct parent link.
            For Each record In result
                record.Parent = result
            Next

            Return result
        End Function

        Public Shared Function Difference(ByVal left As CalculationResult, ByVal right As CalculationResult) As CalculationResult
            Dim dateList As IEnumerable(Of Date) = left.CalendarDateCollection.Union(right.CalendarDateCollection).Distinct()
            Dim locationIdList As IEnumerable(Of Int32?) = left.LocationIdCollection.Union(right.LocationIdCollection).Distinct()
            Dim productSizeList As IEnumerable(Of String) = left.ProductSizeCollection.Union(right.ProductSizeCollection).Distinct()
            Dim resouceList = left.ResourceClassificationCollection.Union(right.ResourceClassificationCollection).Distinct()

            Dim leftRecord As CalculationResultRecord = Nothing
            Dim rightRecord As CalculationResultRecord = Nothing
            Dim result As New CalculationResult()

            Dim preAggregatedLeft As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(left, False, True, True)
            Dim preAggregatedRight As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(right, False, True, True)

            For Each location In locationIdList
                For Each calendarDate In dateList
                    For Each productSize In productSizeList
                        For Each resouceClassification In resouceList
                            Dim lookupKey As String = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, Nothing, productSize, resouceClassification)

                            preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                            preAggregatedRight.TryGetValue(lookupKey, rightRecord)

                            If Not leftRecord Is Nothing Or Not rightRecord Is Nothing Then
                                result.Add(CalculationResultRecord.Difference(leftRecord, rightRecord))
                            End If
                        Next
                    Next
                Next
            Next

            ' Correct parent link.
            For Each record In result
                record.Parent = result
            Next

            Return result
        End Function

        Public Shared Function Addition(ByVal left As CalculationResult, ByVal right As CalculationResult) As CalculationResult
            Dim dateList As IEnumerable(Of Date) = left.CalendarDateCollection.Union(right.CalendarDateCollection).Distinct()
            Dim materialTypeIdList As IEnumerable(Of Int32?) = left.MaterialTypeIdCollection.Union(right.MaterialTypeIdCollection).Distinct()
            Dim locationIdList As IEnumerable(Of Int32?) = left.LocationIdCollection.Union(right.LocationIdCollection).Distinct()
            Dim productSizeList As IEnumerable(Of String) = left.ProductSizeCollection.Union(right.ProductSizeCollection).Distinct()
            Dim resouceList = left.ResourceClassificationCollection.Union(right.ResourceClassificationCollection).Distinct()

            Dim leftRecord As CalculationResultRecord = Nothing
            Dim rightRecord As CalculationResultRecord = Nothing
            Dim result As New CalculationResult()

            Dim preAggregatedLeft As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(left)
            Dim preAggregatedRight As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(right)

            For Each material In materialTypeIdList
                For Each location In locationIdList
                    For Each calendarDate In dateList
                        For Each productSize In productSizeList
                            For Each resouceClassification In resouceList

                                Dim lookupKey As String = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, material, productSize, resouceClassification)

                                preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                                preAggregatedRight.TryGetValue(lookupKey, rightRecord)

                                If Not leftRecord Is Nothing Or Not rightRecord Is Nothing Then
                                    result.Add(leftRecord + rightRecord)
                                End If

                                leftRecord = Nothing
                                rightRecord = Nothing
                            Next
                        Next
                    Next
                Next
            Next

            ' Correct parent link.
            For Each record In result
                record.Parent = result
            Next

            Return result
        End Function

        Public Shared Function Subtract(ByVal left As CalculationResult, ByVal right As CalculationResult) As CalculationResult
            Dim dateList As IEnumerable(Of Date) = left.CalendarDateCollection.Union(right.CalendarDateCollection).Distinct()
            Dim materialTypeIdList As IEnumerable(Of Int32?) = left.MaterialTypeIdCollection.Union(right.MaterialTypeIdCollection).Distinct()
            Dim locationIdList As IEnumerable(Of Int32?) = left.LocationIdCollection.Union(right.LocationIdCollection).Distinct()
            Dim productSizeList As IEnumerable(Of String) = left.ProductSizeCollection.Union(right.ProductSizeCollection).Distinct()
            Dim resouceList = left.ResourceClassificationCollection.Union(right.ResourceClassificationCollection).Distinct()

            Dim leftRecord As CalculationResultRecord = Nothing
            Dim rightRecord As CalculationResultRecord = Nothing
            Dim result As New CalculationResult()

            'if left or right contains boolean
            If left.ContainsNullGrades() Or right.ContainsNullGrades() Then
                left.AggregateByDateLocation()
                right.AggregateByDateLocation()
            End If

            Dim preAggregatedLeft As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(left)
            Dim preAggregatedRight As Dictionary(Of String, CalculationResultRecord) = BuildRecordLookupByMainAggregationFieldsStore(right)

            'combine records
            'left.AggregateByDateLocation()
            ' = left.AggregateRecords(True, False, True, True)
            For Each location In locationIdList
                For Each calendarDate In dateList
                    For Each material In materialTypeIdList
                        For Each productSize In productSizeList
                            For Each resouceClassification In resouceList

                                Dim lookupKey As String = BuildRecordLookupByMainAggregationFieldsStoreKey(calendarDate, location, material, productSize, resouceClassification)

                                preAggregatedLeft.TryGetValue(lookupKey, leftRecord)
                                preAggregatedRight.TryGetValue(lookupKey, rightRecord)

                                If Not leftRecord Is Nothing Or Not rightRecord Is Nothing Then
                                    result.Add(leftRecord - rightRecord)
                                End If

                                leftRecord = Nothing
                                rightRecord = Nothing
                            Next
                        Next
                    Next
                Next
            Next

            ' Correct parent link.
            For Each record In result
                record.Parent = result
            Next

            Return result
        End Function

        ' Copy data from one row to another
        ' The flags provided to this function allow copying selectively such that identifying information, time information, values, or other columns can be copied independantly
        Public Shared Sub CopyDataRow(ByRef fromDataRow As DataRow, ByRef toDataRow As DataRow, ByVal includeIdentifyingColumns As Boolean, ByVal includeTimeBasedColumns As Boolean, ByVal includeValueColums As Boolean, ByVal includeOtherColumns As Boolean)

            Dim identifyingColumnNames As New HashSet(Of String)()
            Dim timeBasedColumnNames As New HashSet(Of String)()
            Dim valueColumnNames As New HashSet(Of String)()

            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameProductSize)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameMaterialType)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameLocationId)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameSortKey)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameRootCalcId)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameCalculationDepth)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameType)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameTagId)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameReportTagId)
            identifyingColumnNames.Add(CalculationResultRecord.ColumnNameRootCalculationId)
            identifyingColumnNames.Add("Attribute")

            timeBasedColumnNames.Add(CalculationResultRecord.ColumnNameDateCal)
            timeBasedColumnNames.Add(CalculationResultRecord.ColumnNameDateFrom)
            timeBasedColumnNames.Add(CalculationResultRecord.ColumnNameDateTo)
            timeBasedColumnNames.Add("DateText")

            For Each gradeName As String In CalculationResultRecord.GradeNames
                valueColumnNames.Add(gradeName)
                valueColumnNames.Add(gradeName + "Difference")
            Next
            valueColumnNames.Add("Tonnes")
            valueColumnNames.Add("FactorTonnes")
            valueColumnNames.Add("TonnesDifference")
            valueColumnNames.Add("Volume")
            valueColumnNames.Add("VolumeDifference")
            valueColumnNames.Add("Tonnes")
            valueColumnNames.Add("DodgyAggregateGradeTonnes")
            valueColumnNames.Add("AttributeValue")
            valueColumnNames.Add("AttributeValueDifference")

            For Each column As DataColumn In fromDataRow.Table.Columns
                ' Default to include (if including other columns)
                Dim include As Boolean = includeOtherColumns

                ' override if in either the identifying, time-based on value column sets
                If identifyingColumnNames.Contains(column.ColumnName) Then
                    include = includeIdentifyingColumns
                ElseIf timeBasedColumnNames.Contains(column.ColumnName) Then
                    include = includeTimeBasedColumns
                ElseIf valueColumnNames.Contains(column.ColumnName) Then
                    include = includeValueColums
                End If

                If include Then
                    toDataRow(column.ColumnName) = fromDataRow(column.ColumnName)
                End If
            Next

        End Sub

        ' This procedure is used to ensure that all data series have values back to the earliest reporting period in the data
        Public Shared Sub FillInDataTableMissingLeadingDataPoints(ByRef data As DataTable)

            Dim periods As New HashSet(Of Date)()

            ' a store of the first record encountered per reporting period
            Dim firstRecordPerPeriod As New Dictionary(Of Date, DataRow)

            ' a store of the earliest reporting date for each encountered row key (ie series)
            Dim earliestPeriodByRowKey As New Dictionary(Of String, Date)()

            ' a store of the first row found for each row key
            Dim earliestRowByRowKey As New Dictionary(Of String, DataRow)()

            ' a store of the index of the first row encountered by row key
            Dim earliestIndexByRowKey As New Dictionary(Of String, Integer)()

            ' an index variable for row counting ... this is neccessary for determining the positions at which rows are to be inserted
            Dim index As Integer = 1

            ' Determine what key identifying columns should go into the row key (data series key)
            Dim potentialKeyColumns As New List(Of String)()
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameProductSize)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameMaterialType)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameLocationId)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameSortKey)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameRootCalcId)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameCalculationDepth)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameType)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameTagId)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameReportTagId)
            potentialKeyColumns.Add(CalculationResultRecord.ColumnNameRootCalculationId)
            potentialKeyColumns.Add("Attribute")

            Dim keyColumns As New List(Of String)()
            For Each columnName As String In potentialKeyColumns
                If data.Columns.Contains(columnName) Then
                    keyColumns.Add(columnName)
                End If
            Next
            ' iterate through the data table and obtain the earliest reporting period
            For Each row As DataRow In data.Rows
                Dim rowKeyBuilder As New System.Text.StringBuilder()

                For Each columnName As String In keyColumns
                    If (Not (row(columnName) Is Nothing OrElse row(columnName) Is DBNull.Value)) Then
                        rowKeyBuilder.Append(row(columnName).ToString())
                        rowKeyBuilder.Append("__")
                    End If
                Next

                Dim rowKey As String = rowKeyBuilder.ToString()
                Dim rowDateTime As DateTime = CDate(row("CalendarDate"))

                periods.Add(rowDateTime) '  Try to add to the periods HashSet, this will only actuall add where the DateTime is not already stored...  (this is as quick as doing a lookup and then an add.. which is what happens internally to the HashSet anyway)

                If Not firstRecordPerPeriod.ContainsKey(rowDateTime) Then
                    firstRecordPerPeriod.Add(rowDateTime, row)
                End If

                ' work out whether this is the earliest period seen for this particular key
                Dim earliestPeriodForThisRowKey As Date
                Dim thisIsEarliestPeriodForRowKey As Boolean = True
                If earliestPeriodByRowKey.TryGetValue(rowKey, earliestPeriodForThisRowKey) Then
                    If earliestPeriodForThisRowKey < rowDateTime Then
                        thisIsEarliestPeriodForRowKey = False
                    End If
                End If

                ' this is the earliest period encountered so far for this row key
                If thisIsEarliestPeriodForRowKey Then
                    earliestPeriodForThisRowKey = rowDateTime
                    earliestPeriodByRowKey(rowKey) = rowDateTime
                    earliestRowByRowKey(rowKey) = row
                    earliestIndexByRowKey(rowKey) = index
                End If

                index = index + 1
            Next

            ' keep track of a row modified... with each row we add it is neccessary increment this offset so that any future 
            ' adds are at an index position that takes this add into accout
            Dim rowPositionModifier As Integer = 0

            ' create an ordered set of period
            Dim orderedPeriods As New List(Of Date)(periods.OrderBy(Function(d) d))

            ' iterate through all rowKeys
            For Each rowKeyDatePair As KeyValuePair(Of String, Date) In earliestPeriodByRowKey

                ' iterate through all ordered periods while the period is earlier than the earliest period already in the data for this row key
                For Each period As Date In orderedPeriods
                    If period >= rowKeyDatePair.Value Then
                        ' nothing more to date... the rowKey (series) already has data
                        Exit For
                    End If

                    ' otherwise a record must be generated for this rowkey and date

                    ' grab the earliest row of this type... 
                    Dim earliestDataRowForRowKey As DataRow = earliestRowByRowKey(rowKeyDatePair.Key)
                    Dim earliestDataRowIndex As Integer = earliestIndexByRowKey(rowKeyDatePair.Key)

                    ' make a row for the new record
                    Dim newDataRow As DataRow = earliestDataRowForRowKey.Table.NewRow()

                    Dim rowToClonePeriodInformationFrom = firstRecordPerPeriod(period)
                    ' Copy time based columns from the row associated with the data point for which the rowKey (series) has no value
                    CalculationResult.CopyDataRow(rowToClonePeriodInformationFrom, newDataRow, includeIdentifyingColumns:=False, includeTimeBasedColumns:=True, includeValueColums:=False, includeOtherColumns:=False)
                    ' Copy identifying and OTHER columns (excluding values and time-based information) from the earliest row for this data set
                    CalculationResult.CopyDataRow(earliestDataRowForRowKey, newDataRow, includeIdentifyingColumns:=True, includeTimeBasedColumns:=False, includeValueColums:=False, includeOtherColumns:=True)

                    ' insert the copied row
                    earliestDataRowForRowKey.Table.Rows.InsertAt(newDataRow, (earliestDataRowIndex - 1) + rowPositionModifier)

                    ' and update the row position modifier so that future inserts are at position + 1
                    rowPositionModifier = rowPositionModifier + 1
                Next
            Next

            ' Now all series should have data points back to the earliest period in the set... the records will have no values..
        End Sub
#End Region

#Region "Data Lookup Support Functions"

        ''' <summary>
        ''' For a given row, determine an appropriate key for looking up related data in a lookup store
        ''' </summary>
        ''' <param name="row">DataRow for which a key is to be determined</param>
        ''' <returns>the lookup key</returns>
        Private Shared Function BuildDataRowLookupByDateAndLocationStoreKey(ByVal row As DataRow) As String
            Dim key As String = "{{NotDefined}}"

            ' build a lookup key for the row
            Dim dateFrom As DateTime = DateTime.MinValue
            Dim locationId As Integer = Integer.MinValue
            DateTime.TryParse(row(CalculationResultRecord.ColumnNameDateCal).ToString(), dateFrom)
            Int32.TryParse(row(CalculationResultRecord.ColumnNameLocationId).ToString(), locationId)

            key = String.Format("{0:ddMMyyyy}_{1}", dateFrom, locationId)

            Return key
        End Function

        ''' <summary>
        ''' Build a data structure that supports quick lookup of data rows by DateFrom and Location
        ''' </summary>
        ''' <param name="dataRows">The data rows on which to build a lookup store</param>
        ''' <returns>A structure that supports lookup based on dateFrom_locationId keys</returns>
        Private Shared Function BuildDataRowLookupByDateAndLocationStore(ByVal dataRows As DataRow()) As Dictionary(Of String, List(Of DataRow))
            Dim gradeRowStore As New Dictionary(Of String, List(Of DataRow))

            ' organise the gradeRows by date and location... 
            ' ...this prevents the lookup operations required by the merge getting exponentially more costly as the time span covered by the report increases
            If Not dataRows Is Nothing Then
                If dataRows.Length > 0 Then
                    ' ensure the required columns are present..
                    If (dataRows(0).Table.Columns.Contains(CalculationResultRecord.ColumnNameDateCal) _
                        AndAlso dataRows(0).Table.Columns.Contains(CalculationResultRecord.ColumnNameLocationId)) Then

                        For Each row In dataRows
                            Dim key As String = BuildDataRowLookupByDateAndLocationStoreKey(row)

                            Dim rowListForKey As List(Of DataRow) = Nothing

                            If Not gradeRowStore.TryGetValue(key, rowListForKey) Then
                                ' this is the first time this key has been seen
                                ' create a list for this data and add it to the store
                                rowListForKey = New List(Of DataRow)()
                                gradeRowStore.Add(key, rowListForKey)
                            End If

                            ' add the row to the list associated with this key
                            rowListForKey.Add(row)
                        Next
                    End If

                End If
            End If

            Return gradeRowStore
        End Function

        ''' <summary>
        ''' Build a data structure that enables lookup of calculation records by lookup key
        ''' </summary>
        ''' <param name="result">the calculation result whose data should be added to the store</param>
        ''' <param name="onMaterialTypeId">if true, material type id will be part of the lookup key</param>
        ''' <param name="onLocationId">if true, location id will be part of the lookup key</param>
        ''' <param name="onProductSize">if true, product size will be part of the lookup key</param>
        ''' <returns>the dictionary data structure to be used for lookup</returns>
        Private Shared Function BuildRecordLookupByMainAggregationFieldsStore(ByVal result As CalculationResult,
                                            Optional ByVal onMaterialTypeId As Boolean = True,
                                            Optional ByVal onLocationId As Boolean = True,
                                            Optional ByVal onProductSize As Boolean = True) As Dictionary(Of String, CalculationResultRecord)
            ' pre-aggregate to avoid aggregation on each loop
            Dim preAggregated As List(Of CalculationResultRecord) = result.AggregateRecords(True, onMaterialTypeId, onLocationId, onProductSize).ToList()
            Dim store As New Dictionary(Of String, CalculationResultRecord)

            For Each record In preAggregated


                Dim key As String = BuildRecordLookupByMainAggregationFieldsStoreKey(record, onMaterialTypeId, onLocationId, onProductSize)

                Dim existingRecord As CalculationResultRecord = Nothing

                store.TryGetValue(key, existingRecord)

                If Not existingRecord Is Nothing Then
                    Throw New ArgumentException("Invalid data detected.  Aggregate has more than one record.")
                End If

                ' Ensure density has been recalculated for the aggregate record before adding to the store
                ' This occurs in other Aggregate operations such as AggregatedDateLocationMaterial (which this store is intended to replace)... and so is required here also
                record.RecalculateDensity()

                store.Add(key, record)
            Next

            Return store

        End Function



        ''' <summary>
        ''' Build a lookup key suitable for obtaining calculation records from a lookup store
        ''' </summary>
        ''' <param name="record">the record, whose attributes will be inspected to build the lookup key</param>
        ''' <param name="onMaterialTypeId">if true, material type id will be part of the lookup key</param>
        ''' <param name="onLocationId">if true, location id will be part of the lookup key</param>
        ''' <param name="onProductSize">if true, product size will be part of the lookup key</param>
        ''' <returns>string representing the lookup key</returns>
        Private Shared Function BuildRecordLookupByMainAggregationFieldsStoreKey(ByVal record As CalculationResultRecord,
                                            Optional ByVal onMaterialTypeId As Boolean = True,
                                            Optional ByVal onLocationId As Boolean = True,
                                            Optional ByVal onProductSize As Boolean = True) As String
            Dim key As String = "{{Undefined}}"

            Dim locationId As Integer? = Nothing
            Dim materialTypeId As Integer? = Nothing
            Dim productSize As String = Nothing

            If onMaterialTypeId Then
                materialTypeId = record.MaterialTypeId
            End If

            If onLocationId Then
                locationId = record.LocationId
            End If

            If onProductSize Then
                productSize = record.ProductSize
            End If

            key = BuildRecordLookupByMainAggregationFieldsStoreKey(record.CalendarDate, locationId, materialTypeId, productSize, record.ResourceClassification)

            Return key
        End Function

        ''' <summary>
        ''' Build a lookup key suitable for obtaining calculation records from a lookup store
        ''' </summary>
        ''' <param name="calDate">the date to be included in the lookup key</param>
        ''' <param name="locationId">the Location Id to be included in the lookup key</param>
        ''' <param name="materialTypeId">the material type Id to be included in the lookup key</param>
        ''' <param name="productSize">the product size to be included in the lookup key</param>
        ''' <returns>string representing the lookup key</returns>
        Private Shared Function BuildRecordLookupByMainAggregationFieldsStoreKey(ByVal calDate As Date, ByVal locationId As Integer?, ByVal materialTypeId As Integer?, ByVal productSize As String, ByVal resourceClassification As String) As String
            Dim key As String = "{{Undefined}}"

            key = String.Format("{0:ddMMyyyy}_{1}_{2}_{3}_{4}", calDate, locationId, materialTypeId, productSize, resourceClassification)

            Return key
        End Function

#End Region

#Region "Class Functions"

        Public Sub AggregateByDateLocation()
            Dim fil As IEnumerable(Of CalculationResultRecord) = AggregateRecords(True, False, True, True)
            Me.Clear()
            For Each thing In fil
                Me.Add(thing)
            Next
        End Sub

        Public Function ContainsNullGrades() As Boolean
            Dim hasNull As Boolean = False
            For Each thing In Me
                If (thing.Fe Is Nothing) AndAlso (Not thing.Tonnes Is Nothing AndAlso thing.Tonnes <> 0) Then
                    hasNull = True
                End If
            Next
            Return hasNull
        End Function

        ''' <summary>
        ''' Deep copy of the object.
        ''' </summary>
        Public Function Clone() As CalculationResult
            Clone = Me.CloneData()
            CloneHeaders(Clone, Me)
        End Function

        ''' <summary>
        ''' Deep copy of just the object data.
        ''' </summary>
        Public Function CloneData() As CalculationResult
            Dim record As CalculationResultRecord
            Dim tag As CalculationResultTag
            CloneData = New CalculationResult()
            For Each record In Me
                CloneData.Add(record.Clone(CloneData))
            Next
            For Each tag In Tags
                CloneData.Tags.Add(tag.Clone())
            Next
        End Function

        Public Shared Sub CloneHeaders(ByVal dest As CalculationResult, ByVal source As CalculationResult)
            dest.TagId = source.TagId
            dest.CalcId = source.CalcId
            dest.InError = source.InError
            dest.Description = source.Description
        End Sub

        ''' <summary>
        ''' Returns a calculation set of all calculation results, including parents used in this result.
        ''' </summary>
        Public ReadOnly Property GetAllCalculations() As CalculationSet
            Get
                Dim calcSet As New CalculationSet()
                Dim parent As CalculationResult

                calcSet.Add(Me)

                For Each parent In ParentResults
                    calcSet.Merge(parent.GetAllCalculations())
                Next

                Return calcSet
            End Get
        End Property

        ''' <summary>
        ''' Returns a list of parents and their depths in this result, including the root result.
        ''' </summary>
        Public ReadOnly Property GetAllResults() As ObjectModel.Collection(Of CalculationResultDepth)
            Get
                Dim list As New ObjectModel.Collection(Of CalculationResultDepth)
                list.Add(New CalculationResultDepth(0, Me))
                GetParentDepths(1, list)
                Return list
            End Get
        End Property

        ''' <summary>
        ''' Returns a list of parents and their depths in this result.
        ''' </summary>
        Public ReadOnly Property GetParents() As ObjectModel.Collection(Of CalculationResultDepth)
            Get
                Dim list As New ObjectModel.Collection(Of CalculationResultDepth)
                GetParentDepths(1, list)
                Return list
            End Get
        End Property

        ''' <summary>
        ''' To be used only by GetParents().
        ''' </summary>
        Public Sub GetParentDepths(ByVal depth As Integer, ByVal list As ObjectModel.Collection(Of CalculationResultDepth))
            Dim parent As CalculationResult
            For Each parent In ParentResults
                list.Add(New CalculationResultDepth(depth, parent))
                parent.GetParentDepths(depth + 1, list)
            Next
        End Sub

        Public Function RemoveAllParents() As CalculationResult
            _parentResults = New ObjectModel.Collection(Of CalculationResult)
            Return Me
        End Function

        Public Function WithProductSize(ByVal productSize As String) As CalculationResult
            Dim resultsToRemove = Me.Where(Function(r) r.ProductSize <> productSize).ToList

            For Each result In resultsToRemove
                Me.Remove(result)
            Next

            Return Me
        End Function

        ''' <summary>
        ''' Returns the first result matching the calc id.
        ''' </summary>
        Public Function GetFirstCalcId(ByVal requestedCalcId As String) As CalculationResult
            Dim calcSet As CalculationSet = GetAllCalculations()
            Dim result As CalculationResult
            Dim matchedResult As CalculationResult = Nothing

            For Each result In calcSet
                If matchedResult Is Nothing AndAlso
                 Not result.CalcId Is Nothing AndAlso
                 result.CalcId.ToUpper() = requestedCalcId.ToUpper() Then
                    matchedResult = result
                End If
            Next

            Return matchedResult
        End Function

        ''' <summary>
        ''' Returns a Calculation set of all items matching that calc id.
        ''' </summary>
        Public Function GetCalcById(ByVal requestedCalcId As String) As CalculationSet
            Dim calcSet As CalculationSet = GetAllCalculations()
            Dim returnSet As New CalculationSet
            Dim result As CalculationResult

            For Each result In calcSet
                If Not result.CalcId Is Nothing AndAlso result.CalcId.ToUpper() = requestedCalcId.ToUpper() Then
                    returnSet.Add(result)
                End If
            Next

            Return returnSet
        End Function

        ''' <summary>
        ''' Replaces any calc id's descriptions found with the description provided.
        ''' </summary>
        Public Sub ReplaceDescription(ByVal calcId As String, ByVal description As String)
            Dim result As CalculationResult

            For Each result In GetCalcById(calcId)
                result.Description = description
            Next
        End Sub

        ''' <summary>
        ''' Prefix's this calclulation and all the parents Tag id with the string provided.
        ''' </summary>
        Public Sub PrefixTagId(ByVal prefixed As String)
            Dim result As CalculationResult
            Dim tagSet As CalculationSet = GetAllCalculations()

            For Each result In tagSet
                result.TagId = prefixed & result.TagId
            Next
        End Sub

        ''' <summary>
        ''' Returns a copy of the result containing all records belonging to the supplied material type.
        ''' </summary>
        Public Function GetMaterialTypeResult(ByVal materialTypeId As Int32?) As CalculationResult
            Dim materialResult As CalculationResult = Clone()
            Dim record As CalculationResultRecord
            ' delete all records which are not of the given materialTypeId
            For Each record In materialResult.ToArray()
                If Not NullableIntEqual(materialTypeId, record.MaterialTypeId) Then
                    materialResult.Remove(record)
                End If
            Next
            Return materialResult
        End Function

        ''' <summary>
        ''' Change all records to the newly supplied material type.
        ''' </summary>
        Public Sub UpdateMaterialType(ByVal newMaterialTypeId As Int32?)
            Dim record As CalculationResultRecord
            Dim result As CalculationResult
            ' Update each record.
            For Each result In GetAllCalculations()
                For Each record In result.ToArray()
                    record.MaterialTypeId = newMaterialTypeId
                Next
            Next
        End Sub

        ''' <summary>
        ''' Change any records of the old material type to the newly supplied material type.
        ''' </summary>
        Public Sub UpdateMaterialType(ByVal oldMaterialTypeId As Int32?, ByVal newMaterialTypeId As Int32?)
            Dim record As CalculationResultRecord
            Dim result As CalculationResult
            ' Update each record.
            For Each result In GetAllCalculations()
                For Each record In result.ToArray()
                    If NullableIntEqual(oldMaterialTypeId, record.MaterialTypeId) Then
                        record.MaterialTypeId = newMaterialTypeId
                    End If
                Next
            Next
        End Sub

        ''' <summary>
        ''' Strips out all the dates between the range.
        ''' </summary>
        Public Sub StripDateRange(ByVal startDate As DateTime, ByVal endDate As DateTime,
         ByVal parseParents As Boolean)
            Dim parentResult As CalculationResult
            Dim deleteRecords As CalculationResultRecord()
            Dim deleteTags As New Generic.List(Of CalculationResultTag)
            Dim tag As CalculationResultTag
            Dim deleteableTags As New List(Of DateTime?)

            deleteRecords = (From rec In ToArray()
                             Where rec.DateFrom >= startDate And rec.DateTo <= endDate
                             Select rec).ToArray()

            ' For any records being deleted which have a datefrom of the calendar date, 
            ' it(means) we can delete the tags.
            For Each record In deleteRecords
                If record.DateFrom = record.CalendarDate AndAlso
                 Not deleteableTags.Contains(record.CalendarDate) Then
                    deleteableTags.Add(record.CalendarDate)
                End If
            Next

            For Each tag In Tags
                If tag.CalendarDate.HasValue AndAlso
                 deleteableTags.Contains(tag.CalendarDate) Then
                    deleteTags.Add(tag)
                End If
            Next

            DeleteRecordAndTags(deleteRecords, deleteTags)

            If parseParents Then
                For Each parentResult In ParentResults
                    parentResult.StripDateRange(startDate, endDate, parseParents)
                Next
            End If
        End Sub

        ''' <summary>
        ''' Strips out all the dates execpt for the one provided.
        ''' </summary>
        ''' <param name="calendarDate">Keep all records relating to this date.</param>
        ''' <remarks>Used to get a subset of the data.</remarks>
        Public Sub StripDateExcept(ByVal calendarDate As DateTime)
            Dim parentResult As CalculationResult
            Dim deleteRecords As CalculationResultRecord()
            Dim deleteTags As New Generic.List(Of CalculationResultTag)
            Dim tag As CalculationResultTag

            deleteRecords = (From rec In ToArray()
                             Where rec.CalendarDate <> calendarDate
                             Select rec).ToArray()

            For Each tag In Tags
                If tag.CalendarDate.HasValue AndAlso tag.CalendarDate <> calendarDate Then
                    deleteTags.Add(tag)
                End If
            Next

            DeleteRecordAndTags(deleteRecords, deleteTags)

            For Each parentResult In ParentResults
                parentResult.StripDateExcept(calendarDate)
            Next
        End Sub

        ''' <summary>
        ''' Deletes the records and tags in the list.
        ''' </summary>
        Private Sub DeleteRecordAndTags(ByVal records As CalculationResultRecord(),
         ByVal deleteTags As Generic.List(Of CalculationResultTag))

            For Each record In records
                Remove(record)
            Next

            For Each tag In deleteTags
                Tags.Remove(tag)
            Next
        End Sub
#End Region

#Region "ToDataTable Functions"

        ''' <summary>
        ''' Dumps the results to a datatable with no aggregation - this is not used by the reports, but it good for testing
        ''' </summary>
        Public Function ToDataTable() As DataTable
            Dim result As DataTable = Nothing

            For Each record In Me
                If result Is Nothing Then
                    result = record.ToDataTable(False)
                Else
                    result.Merge(record.ToDataTable(False))
                End If
            Next

            Return result
        End Function

        ''' <summary>
        ''' Returns the table stub needed for ToDataTable conversions.
        ''' </summary>
        Private Shared Function GetDataTableStub() As DataTable
            Dim table As New DataTable

            ' Add required columns
            table.Columns.Add(New DataColumn("TagId", GetType(String), ""))
            table.Columns.Add(New DataColumn(CalculationResultRecord.ColumnNameReportTagId, GetType(String), ""))
            table.Columns.Add(New DataColumn("CalcId", GetType(String), ""))
            table.Columns.Add(New DataColumn("Description", GetType(String), ""))
            table.Columns.Add(New DataColumn("Type", GetType(CalculationResultType), ""))
            table.Columns.Add(New DataColumn("CalculationDepth", GetType(Int32), ""))
            table.Columns.Add(New DataColumn("InError", GetType(Boolean), ""))
            table.Columns.Add(New DataColumn("ErrorMessage", GetType(String), ""))
            table.Columns.Add(New DataColumn(CalculationResultRecord.ColumnNameProductSize, GetType(String), ""))
            table.Columns.Add(New DataColumn(CalculationResultRecord.ColumnNameSortKey, GetType(String), ""))

            Return table
        End Function

        Private Shared Function NullableIntEqual(ByVal l As Int32?, ByVal r As Int32?) As Boolean
            Return (l.HasValue AndAlso r.HasValue AndAlso l.Value = r.Value) Or
             (Not l.HasValue And Not r.HasValue)
        End Function

        Public Function ToDataTable(ByVal includeParents As Boolean,
         ByVal normalizedData As Boolean, ByVal maintainLocations As Boolean,
         ByVal breakdownMeasureByMaterialType As Boolean,
         ByVal excludeProductSizeBreakdown As Boolean) As DataTable
            Return ToDataTable(includeParents, normalizedData, maintainLocations, breakdownMeasureByMaterialType, excludeProductSizeBreakdown, CType(Nothing, ReportBreakdown?), False)
        End Function

        Public Function ToDataTable(ByVal includeParents As Boolean,
            ByVal normalizedData As Boolean, ByVal maintainLocations As Boolean,
            ByVal breakdownMeasureByMaterialType As Boolean,
            ByVal excludeProductSizeBreakdown As Boolean,
            ByVal aggregateToDateBreakdown As ReportBreakdown?,
            ByVal breakdownFactorByMaterialType As Boolean) As DataTable

            'TODO: Use ByVal parameters As Types.DataRequest to get non parsed dates. 
            Dim table = GetDataTableStub()
            Dim result As CalculationResultDepth
            Dim results As ObjectModel.Collection(Of CalculationResultDepth)
            Dim aggregatedRecords As CalculationResultRecord()
            Dim materialRecords As CalculationResultRecord() = Nothing
            Dim calendarDate As DateTime
            Dim locationId As Int32?

            If Not includeParents Then
                results = New ObjectModel.Collection(Of CalculationResultDepth)
                results.Add(New CalculationResultDepth(0, Me))
            Else
                results = GetAllResults()
            End If

            Dim dateLocationGroup = From dl In AggregateRecords(True, False, maintainLocations, True, aggregateToDateBreakdown)
                                    Group By calDate = dl.CalendarDate, location = dl.LocationId Into Group
                                    Order By calDate, location
                                    Select New With {.calendarDate = calDate, .locationId = location}

            For Each dateLocation In dateLocationGroup
                calendarDate = dateLocation.calendarDate
                locationId = dateLocation.locationId

                For Each result In results
                    If breakdownFactorByMaterialType AndAlso CalcId.Contains("Factor") Then
                        ' it is assumed that the record with MaterialType = null is the aggregated factor record: see the Divide method
                        aggregatedRecords = result.Result.Where(Function(t) t.MaterialTypeId Is Nothing).ToArray()
                    Else
                        aggregatedRecords = result.Result.AggregateFilterRecords(False, maintainLocations, True, calendarDate, locationId, aggregateToDateBreakdown).ToArray()
                    End If

                    If aggregatedRecords.Count = 0 Then
                        aggregatedRecords = New CalculationResultRecord() _
                         {New CalculationResultRecord(Nothing) With
                         {.LocationId = locationId, .CalendarDate = calendarDate, .DateFrom = calendarDate, .DateTo = calendarDate}}
                    End If

                    If breakdownMeasureByMaterialType Then
                        materialRecords = result.Result.AggregateFilterRecords(True, maintainLocations, True, calendarDate, locationId, aggregateToDateBreakdown).ToArray()
                        materialRecords = materialRecords.Where(Function(t) Not t.MaterialTypeId Is Nothing).ToArray()
                    End If

                    ' density has to be treated as a special case, and recalculated after it is aggregated. This is because it is possible to
                    ' have records with zero tonnes, but volume, and we want these to be included in the aggregate calculation
                    '
                    ' We don't have to check if the result is a factor or not, becausethe density recalculation is also valid for factors
                    ' ie. F1[Density] = F1[Tonnes] / F1[Volume], just as if it was a normal density values
                    For Each r In aggregatedRecords
                        r.RecalculateDensity()
                    Next

                    result.Result.ToDataTableParseRows(aggregatedRecords.ToArray(), table, result.Depth, normalizedData, excludeProductSizeBreakdown)

                    If breakdownMeasureByMaterialType Then
                        result.Result.ToDataTableParseRows(materialRecords.ToArray(), table, result.Depth, normalizedData, excludeProductSizeBreakdown)
                    End If
                Next
            Next

            Return table
        End Function

        ' Adds new CalculationResultRecords giving the RC totals. We do this here instead of in the SQL because 
        ' it seemed easier this way. If there is no RC data in the table, then this method will do nothing.
        '
        ' TODO: add a way to make sure this is only run once, so we don't get mulitple totals
        Public Sub AddResourceClassificationTotals()

            ' if there are no non-null values in the RC column then we just return, otherwise the
            ' values can get doubled up
            If Not IncludesResourceClassificationData Then
                Return
            End If

            For Each calenderDate In Me.CalendarDateCollection
                For Each locationId In Me.LocationIdCollection
                    For Each materialTypeId In Me.MaterialTypeIdCollection
                        For Each productSize In Me.ProductSizeCollection

                            Dim rows = Me.Where(Function(r) r.CalendarDate = r.CalendarDate AndAlso
                                                    r.LocationId.ToString = locationId.ToString AndAlso
                                                    r.MaterialTypeId.ToString = materialTypeId.ToString AndAlso
                                                    r.ProductSize = productSize)

                            If rows.Count = 0 Then Continue For
                            Dim totalsRow = rows.Sum

                            If totalsRow IsNot Nothing Then
                                ' we need to set this to null manually - if there are mulitple RC types in the table this will happen manually
                                ' BUT if there is a single RC, then it won't get nulled out, and the totals row will just get re-aggregated 
                                ' back into that type, giving incorrect figures
                                '
                                ' To test this just check a location with no RC data (so that 100 % of the data is under unknown %)
                                totalsRow.ResourceClassification = Nothing

                                Me.Add(totalsRow)
                            End If
                        Next
                    Next
                Next
            Next

        End Sub


        ''' <summary>
        ''' Created an equivalent calculation result that has been aggregated using options the perform the minimum amount of aggregation
        ''' </summary>
        Public Function ToAggregatedClone(ByVal applySpecialH2OGradeWeightingLogic As Boolean) As CalculationResult
            ' make a new result.. copying over property values
            Dim cr As New CalculationResult(Me.CalculationType)
            cr.CalcId = Me.CalcId
            cr.TagId = Me.TagId
            cr.Description = Me.Description
            cr.InError = Me.InError
            cr.ErrorMessage = Me.ErrorMessage

            ' then get a set of aggregate records
            Dim aggregatedRecords As IEnumerable(Of CalculationResultRecord) = AggregateRecords(onDate:=True, onMaterialTypeId:=True, onLocationId:=True, onProductSize:=True, useSpecificH2OGradeWeighting:=applySpecialH2OGradeWeightingLogic)
            ' and add the aggregate records as the calculation results records for the cloned results
            For Each r As CalculationResultRecord In aggregatedRecords
                ' reset the dodgy aggregate tonnes back to the tonnes value.. this is neccessary to address issues around stockpile deltas
                r.DodgyAggregateGradeTonnes = r.Tonnes
                cr.Add(r)
            Next

            Return cr
        End Function

        ''' <summary>
        ''' Parse the rows in normalized data into a data table. To be used only from ToDataTable.
        ''' </summary>
        Public Sub ToDataTableParseRows(ByVal records As CalculationResultRecord(),
         ByVal table As DataTable, ByVal depth As Int32,
         ByVal normalizedData As Boolean,
         ByVal excludeProductSizeBreakdown As Boolean)
            Dim record As CalculationResultRecord
            Dim row As DataRow
            Dim recordTable As DataTable
            Dim locationTable As DataTable

            ' Used to do run this if records were 0: locationTable.Merge(New CalculationResultRecord(Nothing).ToDataTable(normalizedData))
            ' Now switched to not add any rows at all.
            If CalculationType = CalculationResultType.Hidden Then
                records = New CalculationResultRecord() {New CalculationResultRecord(Nothing)}
            End If

            If Not records.Count = 0 Then
                locationTable = table.Clone()

                For Each record In records
                    ' unless excluding this row
                    If (Not excludeProductSizeBreakdown Or record.ProductSize Is Nothing Or record.ProductSize = ProductSizeTotal) Then
                        ' transform it and then add to the location table
                        recordTable = record.ToDataTable(normalizedData)
                        CalculationResultTag.AddTagsToRecord(Tags, recordTable, record)
                        locationTable.Merge(recordTable)
                    End If
                Next

                For Each row In locationTable.Rows

                    Dim tagIdForRow As String = TagId
                    Dim reportTagIdForRow As String = TagId

                    ' modify the TagId to represent the product size if needed for this row
                    ' the original tagId is retained in the ReportTagId column
                    Dim productSizeObject As Object = row(CalculationResultRecord.ColumnNameProductSize)
                    If productSizeObject Is Nothing OrElse String.IsNullOrEmpty(productSizeObject.ToString) Then
                        productSizeObject = CalculationResult.ProductSizeTotal
                    End If

                    row(CalculationResultRecord.ColumnNameProductSize) = productSizeObject.ToString()

                    If (Not productSizeObject.ToString() = ProductSizeTotal) Then
                        If (Not tagIdForRow.EndsWith(productSizeObject.ToString())) Then
                            tagIdForRow = tagIdForRow & productSizeObject.ToString()
                        End If
                    End If

                    row("TagId") = IIf(tagIdForRow Is Nothing, DBNull.Value, tagIdForRow)
                    row("ReportTagId") = IIf(reportTagIdForRow Is Nothing, DBNull.Value, reportTagIdForRow)
                    row("CalcId") = IIf(CalcId Is Nothing, DBNull.Value, CalcId)
                    row("Description") = IIf(Description Is Nothing, DBNull.Value, Description)
                    row("InError") = InError
                    row("ErrorMessage") = ErrorMessage
                    row("CalculationDepth") = depth
                    row("Type") = CalculationType

                    If Description IsNot Nothing AndAlso row.AsString("ProductSize") <> "TOTAL" Then
                        If GeometType = GeometTypeSelection.AsDropped Then
                            row("Description") = String.Format("{0} (AD)", Description)
                        ElseIf GeometType = GeometTypeSelection.AsShipped Then
                            row("Description") = String.Format("{0} (AS)", Description)
                        End If
                    End If
                Next

                table.Merge(locationTable)
                locationTable.Dispose()
            End If
        End Sub
#End Region

#Region "ToCalculationResult Overloaded"

        Public Shared Function ToCalculationResult(ByVal ds As DataSet) As CalculationResult
            Return ToCalculationResult(ds, Nothing, Nothing, Nothing)
        End Function

        Public Shared Function ToCalculationResult(ByVal values As DataRow(), ByVal grades As DataRow()) As CalculationResult
            Return ToCalculationResult(values, grades, Nothing, Nothing, Nothing)
        End Function

        Public Shared Function ToCalculationResult(ByVal rows As DataRow()) As CalculationResult
            Return ToCalculationResult(rows, Nothing, Nothing, Nothing, Nothing)
        End Function

        Public Shared Function ToCalculationResult(ByVal ds As DataSet,
         ByVal startDate As DateTime, ByVal endDate As DateTime,
         ByVal interval As ReportBreakdown, Optional ByVal filterQuery As String = Nothing) As CalculationResult
            Dim result As CalculationResult
            Dim values As DataTable = ds.Tables("Value")
            Dim grades As DataTable = ds.Tables("Grade")

            If values Is Nothing Then
                Throw New ArgumentException("Data set must contain the Values table.")
            End If

            If grades Is Nothing Then
                result = ToCalculationResult(values.Select(filterQuery), Nothing, startDate, endDate, interval)
            Else
                result = ToCalculationResult(values.Select(filterQuery), grades.Select(filterQuery), startDate, endDate, interval)
            End If

            ' now that the calculationresult has been created, check whether the dataset has other tables with data to be added in
            ' ... this is used in product type based reporting where the results of multiple hubs are merged in transparently
            Dim extraResultsMergedIn As Boolean = False
            Dim index As Integer
            For index = 1 To ds.Tables.Count
                Dim extraValues As DataTable = ds.Tables(String.Format("Value{0}", index))
                Dim extraGrades As DataTable = ds.Tables(String.Format("Grade{0}", index))

                If Not extraValues Is Nothing Then
                    extraResultsMergedIn = True
                    If extraGrades Is Nothing Then
                        result.MergeInRows(extraValues.Select(filterQuery), Nothing, startDate, endDate, interval)
                    Else
                        result.MergeInRows(extraValues.Select(filterQuery), extraGrades.Select(filterQuery), startDate, endDate, interval)
                    End If
                End If
            Next

            If (extraResultsMergedIn) Then
                ' the results should be aggregated as the data from multiple tables has been added in to the one set of results
                ' when aggregating in this way, do not apply special H2O Grade Weighting logic (ignoring 0 values) as the database procedures would not have done so 
                ' if the results were retrieved directly at the parent location level

                ' first make the dodgy aggregate tonnes are positive for the aggregation (for grade weighting)
                For Each resultRow As CalculationResultRecord In result
                    If (Not resultRow.DodgyAggregateGradeTonnes Is Nothing) Then
                        resultRow.DodgyAggregateGradeTonnes = Math.Abs(resultRow.DodgyAggregateGradeTonnes.Value)
                    End If
                Next
                result = result.ToAggregatedClone(applySpecialH2OGradeWeightingLogic:=False)
            End If

            Return result
        End Function

        ''' <summary>
        ''' Primary function to convert data rows to the report object model. Often used on Database calls to format into calculation model.
        ''' </summary>
        Public Shared Function ToCalculationResult(
         ByVal valueRows As DataRow(), ByVal gradeRows As DataRow(),
         ByVal startDate As DateTime, ByVal endDate As DateTime,
         ByVal interval As ReportBreakdown) As CalculationResult
            Return New CalculationResult(valueRows, gradeRows, startDate, endDate, interval)
        End Function
#End Region

    End Class

    Module CalculationResultRecordExtensions
        <Runtime.CompilerServices.Extension()>
        Public Function Sum(calculationResults As IEnumerable(Of CalculationResultRecord)) As CalculationResultRecord
            Dim i = 0
            Dim totalResult As CalculationResultRecord = Nothing

            For Each row In calculationResults
                If Not row.Tonnes.HasValue Then Continue For

                If i = 0 Then
                    totalResult = calculationResults.First.Clone
                Else
                    totalResult += row
                End If

                i += 1
            Next

            Return totalResult
        End Function
    End Module

End Namespace
