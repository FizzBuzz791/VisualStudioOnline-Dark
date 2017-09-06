Imports Snowden.Reconcilor.Bhpbio.Report.Enums
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc

    Public MustInherit Class Calculation
        Implements ICalculation

        Public Shared RecoveryFactors As String() = New String() {"RFGM", "RFMM", "RFSTM"}

#Region "Properties"
        Private _session As Types.ReportSession
        Private _result As New CalculationResult(CalculationResultType.Tonnes)
        Private _calculations As New ObjectModel.Collection(Of CalculationOperation)
        Private _disposed As Boolean
        Private _canLoadHistoricData As Boolean
        Private _rootCalculationId As String = Nothing
        Private _parentCalculationId As String = Nothing
        Private _breakdownFactorByMaterialType As Boolean = False

        Private Shared _calcIds As Dictionary(Of String, Calc.CalcType) = Nothing
        Private Shared _lockObject As Object = New Object()

        Protected ReadOnly Property Session() As Types.ReportSession
            Get
                Return _session
            End Get
        End Property

        Protected ReadOnly Property Result() As CalculationResult
            Get
                Return _result
            End Get
        End Property

        Protected ReadOnly Property Calculations() As ObjectModel.Collection(Of CalculationOperation)
            Get
                Return _calculations
            End Get
        End Property

        Protected WriteOnly Property CanLoadHistoricData() As Boolean
            Set(ByVal value As Boolean)
                _canLoadHistoricData = value
            End Set
        End Property

        Public Property RootCalculationId() As String
            Get
                Return _rootCalculationId
            End Get
            Set(ByVal value As String)
                _rootCalculationId = value
            End Set
        End Property

        Public Property ParentCalculationId() As String
            Get
                Return _parentCalculationId
            End Get
            Set(ByVal value As String)
                _parentCalculationId = value
            End Set
        End Property

        Public Property BreakdownFactorByMaterialType() As Boolean
            Get
                Return _breakdownFactorByMaterialType
            End Get
            Set(ByVal value As Boolean)
                _breakdownFactorByMaterialType = value
            End Set
        End Property

        Protected MustOverride ReadOnly Property CalcId() As String

        Protected MustOverride ReadOnly Property Description() As String

        Protected MustOverride ReadOnly Property ResultType() As CalculationResultType
#End Region

#Region " Destructors "
        Public Sub Dispose() Implements IDisposable.Dispose
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Sub Dispose(ByVal disposing As Boolean)
            If (Not _disposed) Then
                If (disposing) Then
                    'Clean up managed Resources ie: Objects

                    If (Not _result Is Nothing) Then
                        _result.Dispose()
                        _result = Nothing
                    End If

                    If (Not _calculations Is Nothing) Then
                        For Each calculation As CalculationOperation In _calculations
                            If Not calculation Is Nothing Then
                                calculation.Dispose()
                            End If
                        Next
                        _calculations = Nothing
                    End If

                End If

                'Clean up unmanaged resources ie: Pointers & Handles				
            End If

            _disposed = True
        End Sub

        Protected Overrides Sub Finalize()
            Dispose(False)
            MyBase.Finalize()
        End Sub
#End Region

        Protected Sub New()
            'prevent direct instantiation
        End Sub

        Public Overridable Sub Initialise(ByVal session As Types.ReportSession) Implements ICalculation.Initialise
            _session = session

            'this is an "opt-in" service that child calculations can turn on as required
            _canLoadHistoricData = False
        End Sub


        Public Shared Function GetCalcTypeFromString(calcTypeId As String) As Calc.CalcType

            SyncLock (_lockObject)

                ' amazingly the CalculationIds in the classes, and passed from the UI, DON'T match
                ' the names used in the CalcType enum, so the conversion is not simple
                If (_calcIds Is Nothing) Then
                    _calcIds = New Dictionary(Of String, Calc.CalcType)

                    '
                    ' loop through every calc type in the enum, get the type, and then use reflection
                    ' to get the value of the CalculationId constant (which all the classes have, but can't be on
                    ' the base class due to the way .net inheritence works). 
                    '
                    ' We build a dictonary of these values that is used to look up the CalcType for a given
                    ' calculationId string
                    '
                    For Each c As Calc.CalcType In Calc.CalcType.GetValues(GetType(Calc.CalcType))
                        Try
                            Dim calculationType = Calc.Calculation.GetConcreteType(c)
                            Dim calculationId = calculationType.GetField("CalculationId").GetValue(calculationType).ToString()

                            If Not _calcIds.ContainsKey(calculationId) Then
                                _calcIds.Add(calculationId, c)
                            End If
                        Catch ex As NotSupportedException
                            ' if the calculation type is not known we will get some exceptions, just ignore these. If the
                            ' calculation is not in the dictonary later, we just return null
                        End Try
                    Next
                End If

                If _calcIds.ContainsKey(calcTypeId) Then
                    Return _calcIds(calcTypeId)
                Else
                    Throw New NotSupportedException(String.Format("CalculationId '{0}' couldn't be converted to CalcType", calcTypeId))
                End If
            End SyncLock

        End Function

        ''' <summary>
        ''' Function to get a cache from base data. To be used when calculation does not merrit new calc class.
        ''' </summary>
        Protected Function GetCacheCalcResult(ByVal cache As Cache.DataCache, ByVal id As String, _
         ByVal description As String) As CalculationResult
            Dim result As CalculationResult

            Try
                result = Types.CalculationResult.ToCalculationResult(cache.RetrieveData(),
                 Session.RequestParameter.StartDate, Session.RequestParameter.EndDate, Session.RequestParameter.DateBreakdown)
            Catch ex As Exception
                result = New CalculationResult(CalculationResultType.Tonnes)
                result.InError = True
                result.ErrorMessage = ex.Message
            End Try
            result.CalcId = id
            result.TagId = id
            result.Description = description

            Return result
        End Function

        Public Overridable Function Calculate() As CalculationResult Implements ICalculation.Calculate
            Try
                If (_session.RequestParameter.DateBreakdown = ReportBreakdown.None _
                 Or _session.RequestParameter.DateBreakdown = ReportBreakdown.Yearly) _
                 And _session.UseHistorical _
                 And _session.RequestParameter.StartDate < _session.GetSystemStartDate() _
                 And _session.RequestParameter.EndDate >= Session.GetSystemStartDate() Then
                    'this is a very complicated area that we're walking into here!
                    'the problem is this:
                    '- the underlying stored procedures will return aggregated data only to the date breakdown requested
                    '- the report model does not support further aggregation of data (except on grade records, by design)
                    'if you need to support this then you will need to aggregate the records manually afterwards

                    Throw New NotSupportedException("The calculation model cannot natively support the use of historic data where" & _
                     " no date breakdown or a yearly date breakdown is supplied whilst spanning both real and historic data.")
                End If

                'where the calculations are *defined*
                SetupOperation()

                'internal call that actually performs the calculation
                CalculateAnswer()

                'if supported and requested for the instance...
                'replace the results with the historic data set's version
                'this in itself will perform the required date checks to see if the date range is valid
                If _canLoadHistoricData And _session.UseHistorical Then
                    MergeInHistoricalData()
                End If

                'local only - performs post calculation events (like zero-ing out null grades for ratios)
                PostCalculate()

                'not sure what this does  :)
                ProcessTags()
            Catch ex As Exception
                If Result Is Nothing Then
                    _result = New CalculationResult(CalculationResultType.Tonnes)
                End If
                Result.InError = True
                Result.ErrorMessage = ex.Message
                CopyProperties()


                Throw
            End Try

            Return Result
        End Function

        Protected Sub CopyProperties()
            If Not Result Is Nothing Then
                Result.CalcId = CalcId
                Result.TagId = CalcId
                Result.Description = Description
                Result.CalculationType = ResultType
            End If
        End Sub

        Private Sub CalculateAnswer()
            Dim operation As CalculationOperation
            Dim calcResultRecord As CalculationResultRecord
            Dim validCalculations As IEnumerable(Of CalculationOperation)

            ' Dodgy Aggregate is the name given to the client general rule that regardless of the calculation being performed, 
            ' mass average the grades using the absolute value of the tonnes.
            ' So where as a negative number or a subtract equation would normally remove a grade - proper practice
            ' in this situation the number will be made positive for the purpose of mass averaging the grade across the results.
            ' The field dodgy aggregate tonnes will be made to either equal the final result when not dodgy aggregate = false, or
            ' the aggregated result of the absolute values when dodgy aggregate = true.
            ' this allows us to use the dodgy aggregate tonnes in many situations without having to put in special case clauses as to when to use it.
            ' -- Written by David Conti
            Dim dodgyAggregateEnabled As Boolean?

            dodgyAggregateEnabled = False

            ' Perform each step.
            For Each operation In Calculations
                If operation.CalcStep = CalculationStep.Assign Then
                    _result = operation.Calculation.CloneData()
                    For Each calcResultRecord In Result
                        calcResultRecord.DodgyAggregateGradeTonnes = calcResultRecord.Tonnes
                        ' As we have just created the data, we need to turn the dodgy aggregate flag on in the record.
                        If dodgyAggregateEnabled Then
                            calcResultRecord.DodgyAggregateEnabled = True
                        End If
                    Next
                ElseIf operation.CalcStep = CalculationStep.Addition Then
                    _result = CalculationResult.PerformCalculation(Result, operation.Calculation, CalculationType.Addition)
                ElseIf operation.CalcStep = CalculationStep.Subtract Then
                    _result = CalculationResult.PerformCalculation(Result, operation.Calculation, CalculationType.Subtraction)
                ElseIf operation.CalcStep = CalculationStep.Divide Or operation.CalcStep = CalculationStep.Ratio Then
                    _result = CalculationResult.PerformCalculation(Result, operation.Calculation, CalculationType.Division, BreakdownFactorByMaterialType, CalcId)
                ElseIf operation.CalcStep = CalculationStep.AggregateDateLocation Then
                    _result.AggregateByDateLocation()
                ElseIf operation.CalcStep = CalculationStep.BeginDodgyTonnesAggregation Then
                    ' Begin dodgy aggregate will set all the records to have the aggregate enabled
                    ' and set the initial tonnes to be used.
                    For Each calcResultRecord In Result
                        calcResultRecord.DodgyAggregateGradeTonnes = calcResultRecord.Tonnes
                        calcResultRecord.DodgyAggregateEnabled = True
                    Next
                    dodgyAggregateEnabled = True
                ElseIf operation.CalcStep = CalculationStep.EndDodgyTonnesAggregation Then
                    ' End dodgy aggregate disables the dodgy aggregate in each record
                    ' and sets the tonnes back to the final result, incase further calculations are required without dodgy aggregate.
                    For Each calcResultRecord In Result
                        calcResultRecord.DodgyAggregateGradeTonnes = calcResultRecord.Tonnes
                        calcResultRecord.DodgyAggregateEnabled = False
                    Next
                    dodgyAggregateEnabled = False
                End If

            Next

            ' The Begin and End Dodgy Aggregate steps don't contain calculations so remove them from the calc list before the copy occurs.
            ' Otherwise a null reference exception occurs.
            While Calculations.Where(Function(t) t.CalcStep = CalculationStep.BeginDodgyTonnesAggregation _
                                         Or t.CalcStep = CalculationStep.EndDodgyTonnesAggregation).Count > 0
                Calculations.Remove(Calculations.Where(Function(t) t.CalcStep = CalculationStep.BeginDodgyTonnesAggregation _
                                         Or t.CalcStep = CalculationStep.EndDodgyTonnesAggregation).First)
            End While

            ' Copy the steps into parent results. If there was only one step (Assign) then dont bother keeping history.
            validCalculations = Calculations.Where(Function(t) Not t.Calculation Is Nothing AndAlso _
                t.Calculation.CalculationType <> CalculationResultType.Hidden)
            If validCalculations.Count > 1 Then
                For Each visibleCalc In validCalculations
                    Result.ParentResults.Add(visibleCalc.Calculation)
                Next
            End If

            CopyProperties()
        End Sub

        Private Sub MergeInHistoricalData()
            Dim historicalData As DataSet
            Dim systemStartDate As DateTime = Session.GetSystemStartDate()
            Dim startDate As DateTime = Session.RequestParameter.StartDate
            Dim historicalEndDate As DateTime = DateAdd(DateInterval.Day, -1, systemStartDate)

            If startDate < systemStartDate Then
                historicalData = Session.GetCacheHistorical().GetHistoricalData(CalcId)

                Result.StripDateRange(startDate, historicalEndDate, False)
                Result.MergeInRows(historicalData, _
                 Session.RequestParameter.StartDate, Session.RequestParameter.EndDate, Session.RequestParameter.DateBreakdown)
            End If
        End Sub

        Protected Overridable Sub ProcessTags()
        End Sub

        Private Sub PostCalculate()
            Dim record As CalculationResultRecord

            If Result.CalculationType = CalculationResultType.Ratio Then
                For Each record In Result
                    record.ZeroOutNullGrades()
                Next
            End If
        End Sub

        Protected MustOverride Sub SetupOperation()

        Protected Shared Function ZeroIfNull(ByVal value As Double?) As Double
            ZeroIfNull = 0
            If value.HasValue Then
                ZeroIfNull = value.Value
            End If
        End Function

        'note - these two factory classes shouldn't be here...
        ' but save the refactoring for when we actually "abstract" and "mock" stuff properly 

        <DebuggerStepThrough()>
        Public Shared Function GetConcreteType(ByVal calculationType As CalcType) As Type
            Select Case calculationType
                Case Calc.CalcType.BeneProduct
                    Return GetType(BeneProduct)
                Case Calc.CalcType.BeneRatio
                    Return GetType(BeneRatio)
                Case Calc.CalcType.ExPitToOreStockpile
                    Return GetType(ExpitToOreStockpile)
                Case Calc.CalcType.F0
                    Return GetType(F0)
                Case Calc.CalcType.F05
                    Return GetType(F05)
                Case Calc.CalcType.F1
                    Return GetType(F1)
                Case Calc.CalcType.F15
                    Return GetType(F15)
                Case Calc.CalcType.F2
                    Return GetType(F2)
                Case Calc.CalcType.F25
                    Return GetType(F25)
                Case Calc.CalcType.F3
                    Return GetType(F3)
                Case Calc.CalcType.F2Density
                    Return GetType(F2Density)
                Case Calc.CalcType.HubPostCrusherStockpileDelta
                    Return GetType(HubPostCrusherStockpileDelta)
                Case Calc.CalcType.ActualMined
                    Return GetType(ActualMined)
                Case Calc.CalcType.MineProductionActuals
                    Return GetType(MineProductionActuals)
                Case Calc.CalcType.MineProductionExpitEquivalent
                    Return GetType(MineProductionExpitEquivalent)
                Case Calc.CalcType.MiningModelCrusherEquivalent
                    Return GetType(MiningModelCrusherEquivalent)
                Case Calc.CalcType.MiningModelShippingEquivalent
                    Return GetType(MiningModelShippingEquivalent)
                Case Calc.CalcType.MiningModelOreForRailEquivalent
                    Return GetType(MiningModelOreForRailEquivalent)
                Case Calc.CalcType.ModelGeology
                    Return GetType(ModelGeology)
                Case Calc.CalcType.ModelShortTermGeology
                    Return GetType(ModelShortTermGeology)
                Case Calc.CalcType.ModelGradeControl
                    Return GetType(ModelGradeControl)
                Case Calc.CalcType.ModelGradeControlSTGM
                    Return GetType(ModelGradeControlSTGM)
                Case Calc.CalcType.ModelMining
                    Return GetType(ModelMining)
                Case Calc.CalcType.PortBlendedAdjustment
                    Return GetType(PortBlendedAdjustment)
                Case Calc.CalcType.PortOreShipped
                    Return GetType(PortOreShipped)
                Case Calc.CalcType.PortStockpileDelta
                    Return GetType(PortStockpileDelta)
                Case Calc.CalcType.PostCrusherStockpileDelta
                    Return GetType(PostCrusherStockpileDelta)
                Case CalcType.RFGM
                    Return GetType(RFGM)
                Case CalcType.RFMM
                    Return GetType(RFMM)
                Case CalcType.RFSTM
                    Return GetType(RFSTM)
                Case Calc.CalcType.SitePostCrusherStockpileDelta
                    Return GetType(SitePostCrusherStockpileDelta)
                Case Calc.CalcType.StockpileToCrusher
                    Return GetType(StockpileToCrusher)
                Case Calc.CalcType.OreForRail
                    Return GetType(OreForRail)
                Case Calc.CalcType.DirectFeed
                    Return GetType(DirectFeed)
                Case Calc.CalcType.RecoveryFactorMoisture
                    Return GetType(RecoveryFactorMoisture)
                Case Calc.CalcType.RecoveryFactorDensity
                    Return GetType(RecoveryFactorDensity)
                Case Calc.CalcType.ModelMiningBene
                    Throw New NotSupportedException("ModelMiningBene can only be used as an Optional Calc Type. It cannot be instantiated.")
                Case Else
                    Throw New NotSupportedException("Calculation type is not supported.")
            End Select
        End Function

        Public Shared Function Create(ByVal calculationType As CalcType) As ICalculation
            Return CType(System.Activator.CreateInstance(GetConcreteType(calculationType)), ICalculation)
        End Function

        <DebuggerStepThrough()>
        Public Shared Function Create(ByVal calculationTypeId As String, ByVal session As Types.ReportSession) As ICalculation
            Return Create(GetCalcTypeFromString(calculationTypeId), session)
        End Function

        <DebuggerStepThrough()> _
        Public Shared Function Create(ByVal calculationType As CalcType, ByVal session As Types.ReportSession) As ICalculation
            Return Create(calculationType, session, Nothing)
        End Function

        <DebuggerStepThrough()> _
        Public Shared Function Create(ByVal calculationType As CalcType, ByVal session As Types.ReportSession, ByRef parentCalculation As Calculation) As ICalculation
            Dim result As ICalculation

            result = CType(System.Activator.CreateInstance(GetConcreteType(calculationType)), ICalculation)
            result.Initialise(session)

            If Not parentCalculation Is Nothing AndAlso TypeOf result Is Calculation Then
                Dim calc As Calculation = CType(result, Calculation)
                calc.ParentCalculationId = parentCalculation.CalcId
                calc.RootCalculationId = IIf(parentCalculation.RootCalculationId Is Nothing, parentCalculation.CalcId, parentCalculation.RootCalculationId).ToString
            End If

            Return result
        End Function
    End Class
End Namespace

